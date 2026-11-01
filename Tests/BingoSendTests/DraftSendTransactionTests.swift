import Foundation
import XCTest
@testable import BingoSend

final class DraftSendTransactionTests: XCTestCase {
    @MainActor
    func testRepeatedTriggerCommitsDuringPreflightWithoutEditingOrSending() async throws {
        let editor = TestEditor("测试正文发送。")
        editor.schedule(after: 0.1) { editor.state = SendEditorState(text: "测试正文发送发送。") }
        let result = try await editor.sender.run(editor, removeKeyword: "发送")
        XCTAssertEqual(result, .inputResumed)
        XCTAssertTrue(editor.events.isEmpty)
        XCTAssertEqual(editor.state.text, "测试正文发送发送。")
    }

    @MainActor
    func testCaretMovementBeforeFirstEditDefersWithoutGlobalFailure() async throws {
        let editor = TestEditor("测试正文发送。")
        editor.schedule(after: 0.1) {
            editor.state = SendEditorState(text: editor.state.text, selection: NSRange(location: 2, length: 0))
        }
        let result = try await editor.sender.run(editor, removeKeyword: "发送")
        XCTAssertEqual(result, .inputResumed)
        XCTAssertTrue(editor.events.isEmpty)
    }

    @MainActor
    func testDelayedSelectionAndDeletionAreAcknowledgedBeforeOneSend() async throws {
        let editor = TestEditor("检查 👨‍👩‍👧‍👦。发送发送。")
        editor.selectionDelay = 0.35
        editor.deletionDelay = 0.5
        let result = try await editor.sender.run(editor, removeKeyword: "发送")
        XCTAssertEqual(result, .posted)
        XCTAssertEqual(editor.events, [.select, .delete, .send])
        XCTAssertEqual(editor.sentTexts, ["检查 👨‍👩‍👧‍👦。发送"])
        XCTAssertGreaterThanOrEqual(editor.time, 1.1)
    }

    @MainActor
    func testMissingDeletionAcknowledgementNeverDeletesTwiceOrSends() async throws {
        let editor = TestEditor("测试正文发送。")
        editor.deletionDelay = 10
        do {
            _ = try await editor.sender.run(editor, removeKeyword: "发送")
            XCTFail("Unconfirmed deletion must stop the transaction")
        } catch {
            assertInterrupted(error)
        }
        XCTAssertEqual(editor.events, [.select, .delete])
        XCTAssertEqual(editor.state.text, editor.originalText)
        XCTAssertEqual(editor.state.selection, NSRange(location: 4, length: 3))
        XCTAssertTrue(editor.sentTexts.isEmpty)
        XCTAssertGreaterThanOrEqual(editor.time, 1.25)
    }

    @MainActor
    func testFurtherDictationAfterSelectionDefersOnlyWithIntactBodyAndEndCaret() async throws {
        let editor = TestEditor("测试正文发送。")
        editor.selectionDelay = 0.2
        editor.onSelection = {
            editor.schedule(after: 0.05) { editor.state = SendEditorState(text: "测试正文发送发送。") }
        }
        let result = try await editor.sender.run(editor, removeKeyword: "发送")
        XCTAssertEqual(result, .inputResumed)
        XCTAssertEqual(editor.events, [.select])
        XCTAssertEqual(editor.state.text, "测试正文发送发送。")
        XCTAssertTrue(editor.sentTexts.isEmpty)
    }

    @MainActor
    func testChangedBodyAfterSelectionCannotBeAutomaticallyRetried() async throws {
        let editor = TestEditor("测试正文发送。")
        editor.selectionDelay = 0.2
        editor.onSelection = {
            editor.schedule(after: 0.05) { editor.state = SendEditorState(text: "正文已被改变发送。") }
        }
        do {
            _ = try await editor.sender.run(editor, removeKeyword: "发送")
            XCTFail("An uncertain change to the body must stop")
        } catch {
            assertInterrupted(error)
        }
        XCTAssertEqual(editor.events, [.select])
        XCTAssertEqual(editor.state.text, "正文已被改变发送。")
    }

    @MainActor
    func testResumedInputWithNonemptySelectionCannotBeAutomaticallyRetried() async throws {
        let editor = TestEditor("测试正文发送。")
        editor.selectionDelay = 0.2
        editor.onSelection = {
            editor.schedule(after: 0.05) {
                editor.state = SendEditorState(text: "测试正文发送发送。", selection: NSRange(location: 4, length: 2))
            }
        }
        do {
            _ = try await editor.sender.run(editor, removeKeyword: "发送")
            XCTFail("A newer draft with an uncertain selection must stop")
        } catch {
            assertInterrupted(error)
        }
        XCTAssertEqual(editor.events, [.select])
        XCTAssertTrue(editor.sentTexts.isEmpty)
    }

    @MainActor
    func testFurtherDictationWhileDeletionIsPendingIsNotOverwrittenOrSent() async throws {
        let editor = TestEditor("测试正文发送。")
        editor.deletionDelay = 0.5
        editor.onDeletion = {
            editor.schedule(after: 0.05) { editor.state = SendEditorState(text: "测试正文发送发送。") }
        }
        do {
            _ = try await editor.sender.run(editor, removeKeyword: "发送")
            XCTFail("A newer draft must stop an uncertain edit")
        } catch {
            assertInterrupted(error)
        }
        XCTAssertEqual(editor.events, [.select, .delete])
        XCTAssertEqual(editor.state.text, "测试正文发送发送。")
        XCTAssertTrue(editor.sentTexts.isEmpty)
    }

    @MainActor
    func testContextChangeIsNeverTreatedAsResumedInput() async throws {
        let editor = TestEditor("测试正文发送。")
        editor.schedule(after: 0.1) {
            editor.failure = .sendFailure(phase: .beforeRemoval, reason: .foregroundApplication)
        }
        do {
            _ = try await editor.sender.run(editor, removeKeyword: "发送")
            XCTFail("A changed app must stop the attempt")
        } catch {
            guard case .sendFailure(_, .foregroundApplication) = error as? AccessibilityFailure else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertTrue(editor.events.isEmpty)
    }

    @MainActor
    func testContextChangeAfterDeletionStopsBeforeReturn() async throws {
        let editor = TestEditor("测试正文发送。")
        editor.onDeletion = { editor.failure = .sendFailure(phase: .beforeRemoval, reason: .focus) }
        do {
            _ = try await editor.sender.run(editor, removeKeyword: "发送")
            XCTFail("Focus must still be checked after the edit")
        } catch {
            assertInterrupted(error)
        }
        XCTAssertEqual(editor.events, [.select, .delete])
        XCTAssertTrue(editor.sentTexts.isEmpty)
    }

    @MainActor
    func testKeyboardFallbackVerifiesEachSelectedGrapheme() async throws {
        let editor = TestEditor("保留正文。发送。\n")
        editor.selectionSettable = false
        let result = try await editor.sender.run(editor, removeKeyword: "发送")
        XCTAssertEqual(result, .posted)
        XCTAssertEqual(editor.events, [.extend, .extend, .extend, .extend, .delete, .send])
        XCTAssertEqual(editor.sentTexts, ["保留正文。"])
    }

    @MainActor
    func testIgnoredAXSelectionFallsBackOnlyFromOriginalCaret() async throws {
        let editor = TestEditor("测试正文发送。")
        editor.ignoresSelection = true
        let result = try await editor.sender.run(editor, removeKeyword: "发送")
        XCTAssertEqual(result, .posted)
        XCTAssertEqual(editor.events, [.select, .extend, .extend, .extend, .delete, .send])
        XCTAssertEqual(editor.sentTexts, ["测试正文"])
    }

    @MainActor
    func testKeepModePreservesBothTriggersAndNeverEdits() async throws {
        let editor = TestEditor("第一行。\n正文发送发送。")
        let result = try await editor.sender.run(editor, removeKeyword: nil)
        XCTAssertEqual(result, .posted)
        XCTAssertEqual(editor.events, [.send])
        XCTAssertEqual(editor.sentTexts, [editor.originalText])
    }

    @MainActor
    func testKeepModeAlsoDefersWhenNewTextArrives() async throws {
        let editor = TestEditor("测试正文发送。")
        editor.schedule(after: 0.1) { editor.state = SendEditorState(text: "测试正文发送的含义") }
        let result = try await editor.sender.run(editor, removeKeyword: nil)
        XCTAssertEqual(result, .inputResumed)
        XCTAssertTrue(editor.events.isEmpty)
    }

    @MainActor
    func testCancellationBeforeEditsPostsNothing() async throws {
        let editor = TestEditor("测试正文发送。")
        editor.cancelOnSleep = true
        do {
            _ = try await editor.sender.run(editor, removeKeyword: "发送")
            XCTFail("Cancellation must stop the attempt")
        } catch is CancellationError {
        }
        XCTAssertTrue(editor.events.isEmpty)
    }

    @MainActor
    func testCancellationAfterSelectionNeverDeletesOrSends() async throws {
        let editor = TestEditor("测试正文发送。")
        editor.selectionDelay = 0.2
        editor.onSelection = { editor.cancelOnSleep = true }
        do {
            _ = try await editor.sender.run(editor, removeKeyword: "发送")
            XCTFail("Cancellation after a possible mutation must stop")
        } catch {
            assertInterrupted(error)
        }
        XCTAssertEqual(editor.events, [.select])
        XCTAssertTrue(editor.sentTexts.isEmpty)
    }

    private func assertInterrupted(_ error: Error, file: StaticString = #filePath, line: UInt = #line) {
        guard case .removalInterrupted = error as? AccessibilityFailure else {
            return XCTFail("Expected a possible-edit interruption, got \(error)", file: file, line: line)
        }
    }
}

@MainActor
private final class TestEditor: DraftSendSession {
    enum Event: Equatable { case select, extend, delete, send }
    let originalText: String
    var state: SendEditorState
    var time: TimeInterval = 0
    var selectionDelay: TimeInterval = 0
    var deletionDelay: TimeInterval = 0
    var selectionSettable = true
    var ignoresSelection = false
    var cancelOnSleep = false
    var failure: AccessibilityFailure?
    var events: [Event] = []
    var sentTexts: [String] = []
    var onSelection: (() -> Void)?
    var onDeletion: (() -> Void)?
    private var updates: [(at: TimeInterval, apply: () -> Void)] = []

    var sender: DraftSendTransaction {
        DraftSendTransaction(clock: SendClock(now: { self.time }, sleep: {
            if self.cancelOnSleep { throw CancellationError() }
            self.time += $0
            self.applyUpdates()
        }))
    }

    init(_ text: String) {
        originalText = text
        state = SendEditorState(text: text)
    }

    func schedule(after delay: TimeInterval, _ update: @escaping () -> Void) {
        updates.append((time + delay, update))
    }

    private func applyUpdates() {
        let ready = updates.filter { $0.at <= time }
        updates.removeAll { $0.at <= time }
        for update in ready { update.apply() }
    }

    func validate(_ expected: SendEditorState, phase: SendPhase) throws {
        applyUpdates()
        if let failure { throw failure }
        guard state.text.utf16.elementsEqual(expected.text.utf16) else {
            throw AccessibilityFailure.sendFailure(phase: phase, reason: .text)
        }
        guard state.selection == expected.selection else {
            throw AccessibilityFailure.sendFailure(phase: phase,
                reason: .cursor(expected: expected.selection, actual: state.selection))
        }
    }

    func readRemovalState() throws -> SendEditorState {
        applyUpdates()
        if let failure { throw failure }
        return state
    }

    func canSetSelection() throws -> Bool { selectionSettable }

    func setSelection(_ range: NSRange) throws {
        events.append(.select)
        if !ignoresSelection {
            schedule(after: selectionDelay) { self.state = SendEditorState(text: self.state.text, selection: range) }
        }
        onSelection?()
    }

    func extendSelectionLeft() throws {
        events.append(.extend)
        let start = String.Index(utf16Offset: state.selection.location, in: state.text)
        let next = state.text.index(before: start)
        let end = String.Index(utf16Offset: NSMaxRange(state.selection), in: state.text)
        state = SendEditorState(text: state.text, selection: NSRange(next..<end, in: state.text))
    }

    func deleteSelection() throws {
        events.append(.delete)
        let expected = SendEditorState(text: (state.text as NSString).replacingCharacters(in: state.selection, with: ""))
        schedule(after: deletionDelay) { self.state = expected }
        onDeletion?()
    }

    func postSend() throws {
        events.append(.send)
        sentTexts.append(state.text)
    }
}
