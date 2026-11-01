import Foundation
import XCTest
@testable import BingoCore

final class TriggerMatcherTests: XCTestCase {
    func testChineseEmojiAndUTF16KeywordRange() throws {
        let text = "帮我看看 👨‍👩‍👧‍👦 的页面， Bingo。  "
        let match = try XCTUnwrap(TriggerMatcher.match(text: text, keyword: "Bingo"))
        XCTAssertEqual((text as NSString).substring(with: match.keywordRange), "Bingo")
        XCTAssertEqual(match.keywordRange.location, ("帮我看看 👨‍👩‍👧‍👦 的页面， " as NSString).length)
        XCTAssertEqual(match.keywordRange.length, 5)
    }

    func testCaseAndTrailingChineseEnglishPunctuation() throws {
        let text = "Please review, bInGo!。？\n"
        let match = try XCTUnwrap(TriggerMatcher.match(text: text, keyword: "Bingo"))
        XCTAssertEqual((text as NSString).substring(with: match.keywordRange), "bInGo")
    }

    func testOnlyFinalKeywordMatches() {
        XCTAssertNil(TriggerMatcher.match(text: "Bingo 帮我检查页面", keyword: "Bingo"))
        XCTAssertNil(TriggerMatcher.match(text: "请讨论 Bingo 的含义", keyword: "Bingo"))
        XCTAssertNil(TriggerMatcher.match(text: "帮我检查 Bingo later", keyword: "Bingo"))
    }

    func testEnglishWordBoundaries() throws {
        for text in ["Review myBingo", "Review 2Bingo", "Review _Bingo", "Review BingoBingo"] {
            XCTAssertNil(TriggerMatcher.match(text: text, keyword: "Bingo"), text)
        }
        let text = "检查页面Bingo"
        let match = try XCTUnwrap(TriggerMatcher.match(text: text, keyword: "Bingo"))
        XCTAssertEqual((text as NSString).substring(with: match.keywordRange), "Bingo")
    }

    func testCustomChineseKeyword() throws {
        let text = "帮我处理页面，确定。"
        let match = try XCTUnwrap(TriggerMatcher.match(text: text, keyword: "确定"))
        XCTAssertEqual((text as NSString).substring(with: match.keywordRange), "确定")
    }

    func testEmptyOrPunctuationOnlyBodyDoesNotSend() {
        for text in ["", "Bingo", "Bingo。", "  Bingo！", "，： Bingo。", "\n Bingo"] {
            XCTAssertNil(TriggerMatcher.match(text: text, keyword: "Bingo"), text)
        }
        XCTAssertNil(TriggerMatcher.match(text: "正文", keyword: "  "))
    }

    func testKeywordRangeExcludesBodyFormattingAndSentencePunctuation() throws {
        let text = "第一行 ✅\n第二行。\nBingo。"
        let match = try XCTUnwrap(TriggerMatcher.match(text: text, keyword: "Bingo"))
        XCTAssertEqual((text as NSString).substring(with: match.keywordRange), "Bingo")
        XCTAssertEqual(match.keywordRange.location, ("第一行 ✅\n第二行。\n" as NSString).length)
        let punctuated = "Done! Bingo."
        let second = try XCTUnwrap(TriggerMatcher.match(text: punctuated, keyword: "Bingo"))
        XCTAssertEqual((punctuated as NSString).substring(with: second.keywordRange), "Bingo")
    }
}

final class TriggerEngineTests: XCTestCase {
    private func draft(_ text: String, target: String = "field-a", atEnd: Bool = true) -> DraftSnapshot {
        DraftSnapshot(targetID: target, text: text, caretAtEnd: atEnd)
    }

    func testInitialSnapshotIsBaselineEvenIfItContainsKeyword() {
        var engine = TriggerEngine()
        let existing = draft("已有草稿 Bingo")
        XCTAssertNil(engine.observe(existing, now: 0, keywords: ["Bingo"], delay: 0.8))
        XCTAssertNil(engine.observe(existing, now: 10, keywords: ["Bingo"], delay: 0.8))
    }

    func testWholeDictationCommitWaitsForStableTextAndEmitsOnce() throws {
        var engine = TriggerEngine()
        XCTAssertNil(engine.observe(draft(""), now: 0, keywords: ["Bingo"], delay: 0.8))
        let spoken = draft("帮我检查页面，Bingo。")
        XCTAssertNil(engine.observe(spoken, now: 1, keywords: ["Bingo"], delay: 0.8))
        XCTAssertNil(engine.observe(spoken, now: 1.5, keywords: ["Bingo"], delay: 0.8))
        let action = try XCTUnwrap(engine.observe(spoken, now: 2, keywords: ["Bingo"], delay: 0.8))
        XCTAssertEqual(action.snapshot, spoken)
        XCTAssertEqual(action.snapshot.text, "帮我检查页面，Bingo。")
        XCTAssertEqual((action.snapshot.text as NSString).substring(with: action.match.keywordRange), "Bingo")
        XCTAssertNil(engine.observe(spoken, now: 3, keywords: ["Bingo"], delay: 0.8))
        XCTAssertNil(engine.observe(spoken, now: 30, keywords: ["Bingo"], delay: 0.8))
    }

    func testIncrementalCommitAndPunctuationResetStabilityTimer() {
        var engine = TriggerEngine()
        _ = engine.observe(draft(""), now: 0, keywords: ["Bingo"], delay: 1)
        _ = engine.observe(draft("请检查"), now: 1, keywords: ["Bingo"], delay: 1)
        _ = engine.observe(draft("请检查 Bi"), now: 2, keywords: ["Bingo"], delay: 1)
        _ = engine.observe(draft("请检查 Bingo"), now: 3, keywords: ["Bingo"], delay: 1)
        _ = engine.observe(draft("请检查 Bingo。"), now: 3.5, keywords: ["Bingo"], delay: 1)
        XCTAssertNil(engine.observe(draft("请检查 Bingo。"), now: 4, keywords: ["Bingo"], delay: 1))
        XCTAssertNotNil(engine.observe(draft("请检查 Bingo。"), now: 4.6, keywords: ["Bingo"], delay: 1))
    }

    func testTypingAfterKeywordCancelsCandidate() {
        var engine = TriggerEngine()
        _ = engine.observe(draft(""), now: 0, keywords: ["Bingo"], delay: 1)
        _ = engine.observe(draft("请检查 Bingo"), now: 1, keywords: ["Bingo"], delay: 1)
        let continued = draft("请检查 Bingo 的含义")
        _ = engine.observe(continued, now: 1.2, keywords: ["Bingo"], delay: 1)
        XCTAssertNil(engine.observe(continued, now: 5, keywords: ["Bingo"], delay: 1))
    }

    func testSwitchingFieldsCancelsPendingAndBaselinesNewField() {
        var engine = TriggerEngine()
        _ = engine.observe(draft(""), now: 0, keywords: ["Bingo"], delay: 1)
        _ = engine.observe(draft("正文 Bingo"), now: 1, keywords: ["Bingo"], delay: 1)
        let newField = draft("另一个已有草稿 Bingo", target: "field-b")
        XCTAssertNil(engine.observe(newField, now: 2, keywords: ["Bingo"], delay: 1))
        XCTAssertNil(engine.observe(newField, now: 5, keywords: ["Bingo"], delay: 1))
    }

    func testLeavingCaretEndCancelsUntilNextTextEdit() {
        var engine = TriggerEngine()
        _ = engine.observe(draft(""), now: 0, keywords: ["Bingo"], delay: 1)
        _ = engine.observe(draft("正文 Bingo"), now: 1, keywords: ["Bingo"], delay: 1)
        XCTAssertNil(engine.observe(draft("正文 Bingo", atEnd: false), now: 1.5, keywords: ["Bingo"], delay: 1))
        XCTAssertNil(engine.observe(draft("正文 Bingo"), now: 4, keywords: ["Bingo"], delay: 1))
        XCTAssertNil(engine.observe(draft("新正文 Bingo"), now: 5, keywords: ["Bingo"], delay: 1))
        XCTAssertNotNil(engine.observe(draft("新正文 Bingo"), now: 7, keywords: ["Bingo"], delay: 1))
    }

    func testARealTextEditCanArmAnotherSend() {
        var engine = TriggerEngine()
        _ = engine.observe(draft(""), now: 0, keywords: ["Bingo"], delay: 1)
        _ = engine.observe(draft("第一条 Bingo"), now: 1, keywords: ["Bingo"], delay: 1)
        XCTAssertNotNil(engine.observe(draft("第一条 Bingo"), now: 2, keywords: ["Bingo"], delay: 1))
        _ = engine.observe(draft(""), now: 3, keywords: ["Bingo"], delay: 1)
        _ = engine.observe(draft("第二条 Bingo"), now: 4, keywords: ["Bingo"], delay: 1)
        XCTAssertNotNil(engine.observe(draft("第二条 Bingo"), now: 5, keywords: ["Bingo"], delay: 1))
    }

    func testResetBaselinesFocusReturn() {
        var engine = TriggerEngine()
        _ = engine.observe(draft(""), now: 0, keywords: ["Bingo"], delay: 1)
        _ = engine.observe(draft("正文 Bingo"), now: 1, keywords: ["Bingo"], delay: 1)
        engine.reset()
        XCTAssertNil(engine.observe(draft("正文 Bingo"), now: 10, keywords: ["Bingo"], delay: 1))
        XCTAssertNil(engine.observe(draft("正文 Bingo"), now: 20, keywords: ["Bingo"], delay: 1))
    }

    func testSuspendRetainsBaselineForAWholeDictationCommitOnReturn() throws {
        var engine = TriggerEngine()
        _ = engine.observe(draft(""), now: 0, keywords: ["Bingo"], delay: 1)
        engine.suspend()
        let committed = draft("浮层结束后上屏的正文，Bingo。")
        XCTAssertNil(engine.observe(committed, now: 10, keywords: ["Bingo"], delay: 1))
        XCTAssertNil(engine.observe(committed, now: 10.5, keywords: ["Bingo"], delay: 1))
        let action = try XCTUnwrap(engine.observe(committed, now: 11, keywords: ["Bingo"], delay: 1))
        XCTAssertEqual(action.snapshot.text, "浮层结束后上屏的正文，Bingo。")
        XCTAssertEqual((action.snapshot.text as NSString).substring(with: action.match.keywordRange), "Bingo")
    }

    func testSendActionPreservesCompleteOriginalDraftIncludingKeywordAndFormatting() throws {
        var engine = TriggerEngine()
        _ = engine.observe(draft(""), now: 0, keywords: ["Bingo"], delay: 1)
        let original = "请检查 👨‍👩‍👧‍👦 的页面。\n保留这行格式， bInGo！  \n"
        _ = engine.observe(draft(original), now: 1, keywords: ["Bingo"], delay: 1)
        let action = try XCTUnwrap(engine.observe(draft(original), now: 2, keywords: ["Bingo"], delay: 1))
        XCTAssertEqual(action.snapshot.text, original)
        XCTAssertEqual((action.snapshot.text as NSString).substring(with: action.match.keywordRange), "bInGo")
    }

    func testSuspendReturningToUnchangedBaselineDoesNotSend() {
        var engine = TriggerEngine()
        let existing = draft("原先已有的草稿 Bingo")
        _ = engine.observe(existing, now: 0, keywords: ["Bingo"], delay: 1)
        engine.suspend()
        XCTAssertNil(engine.observe(existing, now: 10, keywords: ["Bingo"], delay: 1))
        XCTAssertNil(engine.observe(existing, now: 20, keywords: ["Bingo"], delay: 1))
        // A different field continues to establish its own baseline.
        let other = draft("另一个字段的新正文 Bingo", target: "field-b")
        XCTAssertNil(engine.observe(other, now: 21, keywords: ["Bingo"], delay: 1))
        XCTAssertNil(engine.observe(other, now: 30, keywords: ["Bingo"], delay: 1))
    }

    func testSuspendCancelsExistingCandidateEvenAfterReturningToSameText() {
        var engine = TriggerEngine()
        _ = engine.observe(draft(""), now: 0, keywords: ["Bingo"], delay: 1)
        let pending = draft("待发正文 Bingo")
        _ = engine.observe(pending, now: 1, keywords: ["Bingo"], delay: 1)
        engine.suspend()
        XCTAssertNil(engine.observe(pending, now: 5, keywords: ["Bingo"], delay: 1))
        XCTAssertNil(engine.observe(pending, now: 20, keywords: ["Bingo"], delay: 1))
    }

    func testChangedKeywordCancelsPendingCandidate() {
        var engine = TriggerEngine()
        _ = engine.observe(draft(""), now: 0, keywords: ["Bingo"], delay: 1)
        _ = engine.observe(draft("正文 Bingo"), now: 1, keywords: ["Bingo"], delay: 1)
        XCTAssertNil(engine.observe(draft("正文 Bingo"), now: 3, keywords: ["确定"], delay: 1))
        XCTAssertNil(engine.observe(draft("正文 Bingo"), now: 4, keywords: ["Bingo"], delay: 1))
    }

    func testClockMovingBackwardCancelsPendingCandidate() {
        var engine = TriggerEngine()
        _ = engine.observe(draft(""), now: 9, keywords: ["Bingo"], delay: 1)
        _ = engine.observe(draft("正文 Bingo"), now: 10, keywords: ["Bingo"], delay: 1)
        XCTAssertNil(engine.observe(draft("正文 Bingo"), now: 8, keywords: ["Bingo"], delay: 1))
        XCTAssertNil(engine.observe(draft("正文 Bingo"), now: 20, keywords: ["Bingo"], delay: 1))
    }

    func testResumedInputDuringSendRearmsOnlyTheNewerDraft() throws {
        var engine = TriggerEngine()
        _ = engine.observe(draft(""), now: 0, keywords: ["发送"], delay: 0.8)
        let first = draft("测试正文发送。")
        _ = engine.observe(first, now: 1, keywords: ["发送"], delay: 0.8)
        XCTAssertNotNil(engine.observe(first, now: 2, keywords: ["发送"], delay: 0.8))
        engine.resumeAfterInputChange(from: first)
        let newer = draft("测试正文发送发送。")
        XCTAssertNil(engine.observe(newer, now: 2.2, keywords: ["发送"], delay: 0.8))
        XCTAssertNil(engine.observe(newer, now: 2.5, keywords: ["发送"], delay: 0.8))
        let action = try XCTUnwrap(engine.observe(newer, now: 3.1, keywords: ["发送"], delay: 0.8))
        XCTAssertEqual(action.snapshot, newer)
        XCTAssertNil(engine.observe(newer, now: 10, keywords: ["发送"], delay: 0.8))
    }

    func testResumedAttemptDoesNotRetryTheSameUnchangedDraft() {
        var engine = TriggerEngine()
        let original = draft("测试正文发送。")
        engine.resumeAfterInputChange(from: original)
        XCTAssertNil(engine.observe(original, now: 1, keywords: ["发送"], delay: 0.8))
        XCTAssertNil(engine.observe(original, now: 10, keywords: ["发送"], delay: 0.8))
    }

    func testContinuationAfterAbandonedAttemptDoesNotSendAMiddleKeyword() {
        var engine = TriggerEngine()
        engine.resumeAfterInputChange(from: draft("测试正文发送。"))
        let continued = draft("测试正文发送的含义")
        XCTAssertNil(engine.observe(continued, now: 1, keywords: ["发送"], delay: 0.8))
        XCTAssertNil(engine.observe(continued, now: 10, keywords: ["发送"], delay: 0.8))
    }

    func testFailedDraftAndDelayedDeletionResultNeverRearmEachOther() {
        var engine = TriggerEngine()
        let original = draft("测试正文发送发送。")
        let edited = draft("测试正文发送")
        engine.recordFailedAttempt(original, possibleEditedText: edited.text)
        for (time, snapshot) in [(1.0, original), (3.0, original), (4.0, edited),
                                 (6.0, edited), (7.0, original), (9.0, original)] {
            XCTAssertNil(engine.observe(snapshot, now: time, keywords: ["发送"], delay: 0.8))
        }
    }

    func testFailureGuardSurvivesResetAndFocusSwitch() {
        var engine = TriggerEngine()
        let original = draft("测试正文发送发送。")
        let edited = draft("测试正文发送")
        engine.recordFailedAttempt(original, possibleEditedText: edited.text)
        _ = engine.observe(original, now: 1, keywords: ["发送"], delay: 0.8)
        engine.reset()
        _ = engine.observe(draft("", target: "field-b"), now: 2, keywords: ["发送"], delay: 0.8)
        XCTAssertNil(engine.observe(edited, now: 3, keywords: ["发送"], delay: 0.8))
        XCTAssertNil(engine.observe(edited, now: 5, keywords: ["发送"], delay: 0.8))
    }

    func testNewInputAfterFailureStillSendsOnceAfterAFreshWait() {
        var engine = TriggerEngine()
        let original = draft("测试正文发送发送。")
        engine.recordFailedAttempt(original, possibleEditedText: "测试正文发送")
        _ = engine.observe(original, now: 1, keywords: ["发送"], delay: 0.8)
        let newer = draft("重新输入的一条消息发送。")
        XCTAssertNil(engine.observe(newer, now: 2, keywords: ["发送"], delay: 0.8))
        XCTAssertNil(engine.observe(newer, now: 2.5, keywords: ["发送"], delay: 0.8))
        XCTAssertNotNil(engine.observe(newer, now: 3, keywords: ["发送"], delay: 0.8))
        XCTAssertNil(engine.observe(newer, now: 10, keywords: ["发送"], delay: 0.8))
    }

    func testFailureInOneEditorDoesNotBlockNewInputInAnotherEditor() {
        var engine = TriggerEngine()
        engine.recordFailedAttempt(draft("失败的正文发送。"), possibleEditedText: "失败的正文")
        _ = engine.observe(draft("", target: "field-b"), now: 1, keywords: ["发送"], delay: 0.8)
        let other = draft("另一个输入框的新消息发送。", target: "field-b")
        XCTAssertNil(engine.observe(other, now: 2, keywords: ["发送"], delay: 0.8))
        XCTAssertNotNil(engine.observe(other, now: 3, keywords: ["发送"], delay: 0.8))
    }

    func testKeepModeFailureDoesNotRetryItsUnchangedDraft() {
        var engine = TriggerEngine()
        let original = draft("保留完整正文发送。")
        engine.recordFailedAttempt(original, possibleEditedText: nil)
        XCTAssertNil(engine.observe(original, now: 1, keywords: ["发送"], delay: 0.8))
        XCTAssertNil(engine.observe(original, now: 10, keywords: ["发送"], delay: 0.8))
    }

    func testFirstUnreadablePostFailureDraftBecomesBaseline() {
        var engine = TriggerEngine()
        engine.recordFailedAttempt(draft("测试正文发送。"), possibleEditedText: "测试正文")
        let changedDuringFailure = draft("错误处理期间已变化的正文发送。")
        XCTAssertNil(engine.observe(changedDuringFailure, now: 1, keywords: ["发送"], delay: 0.8))
        XCTAssertNil(engine.observe(changedDuringFailure, now: 10, keywords: ["发送"], delay: 0.8))
    }
}
