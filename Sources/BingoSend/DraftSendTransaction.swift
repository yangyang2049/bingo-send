import Foundation
import ApplicationServices
import BingoCore

struct SendEditorState: Equatable {
    let text: String
    let selection: NSRange

    init(text: String, selection: NSRange? = nil) {
        self.text = text
        self.selection = selection ?? NSRange(location: text.utf16.count, length: 0)
    }
}

enum SendAttemptResult: Equatable {
    case posted
    /// No deletion or send event was attempted. Observe verified newer input afresh.
    case inputResumed
}

/// The native adapter validates the original process, focus and page on every
/// read/validation. Tests substitute an editor with asynchronous acknowledgements.
@MainActor
protocol DraftSendSession {
    var originalText: String { get }
    func validate(_ expected: SendEditorState, phase: SendPhase) throws
    func readRemovalState() throws -> SendEditorState
    func canSetSelection() throws -> Bool
    func setSelection(_ range: NSRange) throws
    func extendSelectionLeft() throws
    func deleteSelection() throws
    func postSend() throws
}

@MainActor
struct SendClock {
    var now: () -> TimeInterval
    var sleep: (TimeInterval) async throws -> Void

    static var continuous: Self {
        Self(now: { ProcessInfo.processInfo.systemUptime }, sleep: {
            try await Task.sleep(nanoseconds: UInt64($0 * 1_000_000_000))
        })
    }
}

/// One verified edit transaction. Resumed input can be observed afresh before
/// deletion, with an extra intact-body/caret check after selecting a suffix.
/// After deletion, uncertainty always stops the attempt; no rollback, second
/// Backspace or unverified Return is ever posted.
@MainActor
struct DraftSendTransaction {
    var clock: SendClock = .continuous
    private let preflightInterval: TimeInterval = 0.25
    private let acknowledgementTimeout: TimeInterval = 1
    private let pollInterval: TimeInterval = 0.025

    func run(_ session: any DraftSendSession, removeKeyword: String?) async throws -> SendAttemptResult {
        var mayHaveModifiedDraft = false
        var deletionAttempted = false
        do {
            let original = SendEditorState(text: session.originalText)
            let phase: SendPhase = removeKeyword == nil ? .beforeSend : .beforeRemoval
            // Dictation can commit another word after the trigger engine fires.
            // Catch that update while the draft and selection are still untouched.
            try await confirmQuietInput(session, expected: original, phase: phase)
            let expected: SendEditorState
            if let keyword = removeKeyword {
                expected = try await removeSuffix(session, original: original, keyword: keyword,
                    mayHaveModifiedDraft: &mayHaveModifiedDraft, deletionAttempted: &deletionAttempted)
            } else {
                expected = original
            }
            try Task.checkCancellation()
            try session.validate(expected, phase: .beforeSend)
            try session.postSend()
            return .posted
        } catch {
            if !mayHaveModifiedDraft, isNewInput(error) { return .inputResumed }
            if !deletionAttempted, isNewInput(error), let keyword = removeKeyword,
               canResumeAfterSelection(session, keyword: keyword) {
                return .inputResumed
            }
            if mayHaveModifiedDraft {
                let cause = error is CancellationError
                    ? L10n.text(zh: "移除口令操作已取消。", en: "Trigger removal was cancelled.")
                    : error.localizedDescription
                throw AccessibilityFailure.removalInterrupted(cause: cause)
            }
            throw error
        }
    }

    private func canResumeAfterSelection(_ session: any DraftSendSession, keyword: String) -> Bool {
        guard let body = TriggerText.removingSuffix(from: session.originalText, keyword: keyword),
              let actual = try? session.readRemovalState(),
              !sameText(actual.text, session.originalText),
              actual.text.utf16.prefix(body.utf16.count).elementsEqual(body.utf16),
              actual.selection == NSRange(location: actual.text.utf16.count, length: 0) else { return false }
        // Only our selection was attempted, never a deletion. Do not undo it or
        // replace text; verify the intact prefix and the user's newer end caret.
        do {
            try Task.checkCancellation()
            try session.validate(actual, phase: .beforeRemoval)
            return true
        } catch {
            return false
        }
    }

    private func isNewInput(_ error: Error) -> Bool {
        guard let failure = error as? AccessibilityFailure,
              case let .sendFailure(_, reason) = failure else { return false }
        switch reason {
        case .text, .cursor: return true
        default: return false
        }
    }

    private func confirmQuietInput(_ session: any DraftSendSession, expected: SendEditorState,
                                   phase: SendPhase) async throws {
        let deadline = clock.now() + preflightInterval
        while true {
            try Task.checkCancellation()
            try session.validate(expected, phase: phase)
            let remaining = deadline - clock.now()
            guard remaining > 0 else { return }
            try await clock.sleep(min(pollInterval, remaining))
        }
    }

    private func removeSuffix(_ session: any DraftSendSession, original: SendEditorState,
                              keyword: String, mayHaveModifiedDraft: inout Bool,
                              deletionAttempted: inout Bool) async throws -> SendEditorState {
        guard let body = TriggerText.removingSuffix(from: original.text, keyword: keyword) else {
            throw AccessibilityFailure.sendFailure(phase: .beforeRemoval, reason: .triggerNotMatched)
        }
        let suffixRange = NSRange(location: body.utf16.count,
            length: original.text.utf16.count - body.utf16.count)
        let selected = SendEditorState(text: original.text, selection: suffixRange)
        var needsKeyboardSelection = true
        try Task.checkCancellation()
        try session.validate(original, phase: .beforeRemoval)
        if try session.canSetSelection() {
            try Task.checkCancellation()
            try session.validate(original, phase: .beforeRemoval)
            mayHaveModifiedDraft = true
            do {
                try session.setSelection(suffixRange)
                try await waitForEdit(session, previous: original, expected: selected)
                needsKeyboardSelection = false
            } catch {
                guard permitsSelectionFallback(error) else { throw error }
                // A claimed AX success may be ignored. Fall back only if both
                // text and caret are still exactly the untouched original state.
                try Task.checkCancellation()
                try session.validate(original, phase: .beforeRemoval)
            }
        }
        if needsKeyboardSelection {
            try await selectWithKeyboard(session, original: original, suffixRange: suffixRange,
                mayHaveModifiedDraft: &mayHaveModifiedDraft)
        }

        try Task.checkCancellation()
        try session.validate(selected, phase: .beforeRemoval)
        mayHaveModifiedDraft = true
        deletionAttempted = true
        try session.deleteSelection()
        let expected = SendEditorState(text: body)
        try await waitForEdit(session, previous: selected, expected: expected)
        try Task.checkCancellation()
        return expected
    }

    private func permitsSelectionFallback(_ error: Error) -> Bool {
        guard let failure = error as? AccessibilityFailure,
              case let .sendFailure(_, reason) = failure else { return false }
        switch reason {
        case .editTimeout: return true
        case let .axWrite(attribute, code):
            return attribute == kAXSelectedTextRangeAttribute as String
                && [AXError.attributeUnsupported, .notImplemented].contains { Int($0.rawValue) == code }
        default: return false
        }
    }

    private func selectWithKeyboard(_ session: any DraftSendSession, original: SendEditorState,
                                    suffixRange: NSRange, mayHaveModifiedDraft: inout Bool) async throws {
        guard let suffix = Range(suffixRange, in: original.text),
              original.text.indices.contains(suffix.lowerBound), original.text[suffix].count <= 64 else {
            throw AccessibilityFailure.sendFailure(phase: .beforeRemoval, reason: .triggerRemovalUnsupported)
        }
        var start = original.text.endIndex
        var previous = original
        while start > suffix.lowerBound {
            let next = original.text.index(before: start)
            guard next >= suffix.lowerBound else {
                throw AccessibilityFailure.sendFailure(phase: .beforeRemoval, reason: .triggerRemovalUnsupported)
            }
            let selected = SendEditorState(text: original.text,
                selection: NSRange(next..<original.text.endIndex, in: original.text))
            try Task.checkCancellation()
            try session.validate(previous, phase: .beforeRemoval)
            mayHaveModifiedDraft = true
            try session.extendSelectionLeft()
            try await waitForEdit(session, previous: previous, expected: selected)
            previous = selected
            start = next
        }
    }

    private func waitForEdit(_ session: any DraftSendSession, previous: SendEditorState,
                             expected: SendEditorState) async throws {
        let deadline = clock.now() + acknowledgementTimeout
        while true {
            try Task.checkCancellation()
            let actual = try session.readRemovalState()
            if sameText(actual.text, expected.text), actual.selection == expected.selection {
                try session.validate(expected, phase: .beforeRemoval)
                return
            }
            // AX text and range arrive through separate IPC reads. Permit only
            // old/new combinations of this one edit, never arbitrary new input.
            guard sameText(actual.text, previous.text) || sameText(actual.text, expected.text) else {
                throw AccessibilityFailure.sendFailure(phase: .beforeRemoval, reason: .text)
            }
            guard actual.selection == previous.selection || actual.selection == expected.selection else {
                throw AccessibilityFailure.sendFailure(phase: .beforeRemoval,
                    reason: .cursor(expected: expected.selection, actual: actual.selection))
            }
            let remaining = deadline - clock.now()
            guard remaining > 0 else {
                let textState: RemovalTextState = sameText(actual.text, expected.text)
                    ? (sameText(actual.text, previous.text) ? .unchanged : .expected) : .original
                throw AccessibilityFailure.sendFailure(phase: .beforeRemoval,
                    reason: .editTimeout(expected: expected.selection, actual: actual.selection, textState: textState))
            }
            try await clock.sleep(min(pollInterval, remaining))
        }
    }

    private func sameText(_ lhs: String, _ rhs: String) -> Bool {
        lhs.utf16.elementsEqual(rhs.utf16)
    }
}
