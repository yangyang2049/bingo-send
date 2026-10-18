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
        XCTAssertNil(engine.observe(existing, now: 0, keyword: "Bingo", delay: 0.8))
        XCTAssertNil(engine.observe(existing, now: 10, keyword: "Bingo", delay: 0.8))
    }

    func testWholeDictationCommitWaitsForStableTextAndEmitsOnce() throws {
        var engine = TriggerEngine()
        XCTAssertNil(engine.observe(draft(""), now: 0, keyword: "Bingo", delay: 0.8))
        let spoken = draft("帮我检查页面，Bingo。")
        XCTAssertNil(engine.observe(spoken, now: 1, keyword: "Bingo", delay: 0.8))
        XCTAssertNil(engine.observe(spoken, now: 1.5, keyword: "Bingo", delay: 0.8))
        let action = try XCTUnwrap(engine.observe(spoken, now: 2, keyword: "Bingo", delay: 0.8))
        XCTAssertEqual(action.snapshot, spoken)
        XCTAssertEqual(action.snapshot.text, "帮我检查页面，Bingo。")
        XCTAssertEqual((action.snapshot.text as NSString).substring(with: action.match.keywordRange), "Bingo")
        XCTAssertNil(engine.observe(spoken, now: 3, keyword: "Bingo", delay: 0.8))
        XCTAssertNil(engine.observe(spoken, now: 30, keyword: "Bingo", delay: 0.8))
    }

    func testIncrementalCommitAndPunctuationResetStabilityTimer() {
        var engine = TriggerEngine()
        _ = engine.observe(draft(""), now: 0, keyword: "Bingo", delay: 1)
        _ = engine.observe(draft("请检查"), now: 1, keyword: "Bingo", delay: 1)
        _ = engine.observe(draft("请检查 Bi"), now: 2, keyword: "Bingo", delay: 1)
        _ = engine.observe(draft("请检查 Bingo"), now: 3, keyword: "Bingo", delay: 1)
        _ = engine.observe(draft("请检查 Bingo。"), now: 3.5, keyword: "Bingo", delay: 1)
        XCTAssertNil(engine.observe(draft("请检查 Bingo。"), now: 4, keyword: "Bingo", delay: 1))
        XCTAssertNotNil(engine.observe(draft("请检查 Bingo。"), now: 4.6, keyword: "Bingo", delay: 1))
    }

    func testTypingAfterKeywordCancelsCandidate() {
        var engine = TriggerEngine()
        _ = engine.observe(draft(""), now: 0, keyword: "Bingo", delay: 1)
        _ = engine.observe(draft("请检查 Bingo"), now: 1, keyword: "Bingo", delay: 1)
        let continued = draft("请检查 Bingo 的含义")
        _ = engine.observe(continued, now: 1.2, keyword: "Bingo", delay: 1)
        XCTAssertNil(engine.observe(continued, now: 5, keyword: "Bingo", delay: 1))
    }

    func testSwitchingFieldsCancelsPendingAndBaselinesNewField() {
        var engine = TriggerEngine()
        _ = engine.observe(draft(""), now: 0, keyword: "Bingo", delay: 1)
        _ = engine.observe(draft("正文 Bingo"), now: 1, keyword: "Bingo", delay: 1)
        let newField = draft("另一个已有草稿 Bingo", target: "field-b")
        XCTAssertNil(engine.observe(newField, now: 2, keyword: "Bingo", delay: 1))
        XCTAssertNil(engine.observe(newField, now: 5, keyword: "Bingo", delay: 1))
    }

    func testLeavingCaretEndCancelsUntilNextTextEdit() {
        var engine = TriggerEngine()
        _ = engine.observe(draft(""), now: 0, keyword: "Bingo", delay: 1)
        _ = engine.observe(draft("正文 Bingo"), now: 1, keyword: "Bingo", delay: 1)
        XCTAssertNil(engine.observe(draft("正文 Bingo", atEnd: false), now: 1.5, keyword: "Bingo", delay: 1))
        XCTAssertNil(engine.observe(draft("正文 Bingo"), now: 4, keyword: "Bingo", delay: 1))
        XCTAssertNil(engine.observe(draft("新正文 Bingo"), now: 5, keyword: "Bingo", delay: 1))
        XCTAssertNotNil(engine.observe(draft("新正文 Bingo"), now: 7, keyword: "Bingo", delay: 1))
    }

    func testARealTextEditCanArmAnotherSend() {
        var engine = TriggerEngine()
        _ = engine.observe(draft(""), now: 0, keyword: "Bingo", delay: 1)
        _ = engine.observe(draft("第一条 Bingo"), now: 1, keyword: "Bingo", delay: 1)
        XCTAssertNotNil(engine.observe(draft("第一条 Bingo"), now: 2, keyword: "Bingo", delay: 1))
        _ = engine.observe(draft(""), now: 3, keyword: "Bingo", delay: 1)
        _ = engine.observe(draft("第二条 Bingo"), now: 4, keyword: "Bingo", delay: 1)
        XCTAssertNotNil(engine.observe(draft("第二条 Bingo"), now: 5, keyword: "Bingo", delay: 1))
    }

    func testResetBaselinesFocusReturn() {
        var engine = TriggerEngine()
        _ = engine.observe(draft(""), now: 0, keyword: "Bingo", delay: 1)
        _ = engine.observe(draft("正文 Bingo"), now: 1, keyword: "Bingo", delay: 1)
        engine.reset()
        XCTAssertNil(engine.observe(draft("正文 Bingo"), now: 10, keyword: "Bingo", delay: 1))
        XCTAssertNil(engine.observe(draft("正文 Bingo"), now: 20, keyword: "Bingo", delay: 1))
    }

    func testSuspendRetainsBaselineForAWholeDictationCommitOnReturn() throws {
        var engine = TriggerEngine()
        _ = engine.observe(draft(""), now: 0, keyword: "Bingo", delay: 1)
        engine.suspend()
        let committed = draft("浮层结束后上屏的正文，Bingo。")
        XCTAssertNil(engine.observe(committed, now: 10, keyword: "Bingo", delay: 1))
        XCTAssertNil(engine.observe(committed, now: 10.5, keyword: "Bingo", delay: 1))
        let action = try XCTUnwrap(engine.observe(committed, now: 11, keyword: "Bingo", delay: 1))
        XCTAssertEqual(action.snapshot.text, "浮层结束后上屏的正文，Bingo。")
        XCTAssertEqual((action.snapshot.text as NSString).substring(with: action.match.keywordRange), "Bingo")
    }

    func testSendActionPreservesCompleteOriginalDraftIncludingKeywordAndFormatting() throws {
        var engine = TriggerEngine()
        _ = engine.observe(draft(""), now: 0, keyword: "Bingo", delay: 1)
        let original = "请检查 👨‍👩‍👧‍👦 的页面。\n保留这行格式， bInGo！  \n"
        _ = engine.observe(draft(original), now: 1, keyword: "Bingo", delay: 1)
        let action = try XCTUnwrap(engine.observe(draft(original), now: 2, keyword: "Bingo", delay: 1))
        XCTAssertEqual(action.snapshot.text, original)
        XCTAssertEqual((action.snapshot.text as NSString).substring(with: action.match.keywordRange), "bInGo")
    }

    func testSuspendReturningToUnchangedBaselineDoesNotSend() {
        var engine = TriggerEngine()
        let existing = draft("原先已有的草稿 Bingo")
        _ = engine.observe(existing, now: 0, keyword: "Bingo", delay: 1)
        engine.suspend()
        XCTAssertNil(engine.observe(existing, now: 10, keyword: "Bingo", delay: 1))
        XCTAssertNil(engine.observe(existing, now: 20, keyword: "Bingo", delay: 1))
        // A different field continues to establish its own baseline.
        let other = draft("另一个字段的新正文 Bingo", target: "field-b")
        XCTAssertNil(engine.observe(other, now: 21, keyword: "Bingo", delay: 1))
        XCTAssertNil(engine.observe(other, now: 30, keyword: "Bingo", delay: 1))
    }

    func testSuspendCancelsExistingCandidateEvenAfterReturningToSameText() {
        var engine = TriggerEngine()
        _ = engine.observe(draft(""), now: 0, keyword: "Bingo", delay: 1)
        let pending = draft("待发正文 Bingo")
        _ = engine.observe(pending, now: 1, keyword: "Bingo", delay: 1)
        engine.suspend()
        XCTAssertNil(engine.observe(pending, now: 5, keyword: "Bingo", delay: 1))
        XCTAssertNil(engine.observe(pending, now: 20, keyword: "Bingo", delay: 1))
    }

    func testChangedKeywordCancelsPendingCandidate() {
        var engine = TriggerEngine()
        _ = engine.observe(draft(""), now: 0, keyword: "Bingo", delay: 1)
        _ = engine.observe(draft("正文 Bingo"), now: 1, keyword: "Bingo", delay: 1)
        XCTAssertNil(engine.observe(draft("正文 Bingo"), now: 3, keyword: "确定", delay: 1))
        XCTAssertNil(engine.observe(draft("正文 Bingo"), now: 4, keyword: "Bingo", delay: 1))
    }

    func testClockMovingBackwardCancelsPendingCandidate() {
        var engine = TriggerEngine()
        _ = engine.observe(draft(""), now: 9, keyword: "Bingo", delay: 1)
        _ = engine.observe(draft("正文 Bingo"), now: 10, keyword: "Bingo", delay: 1)
        XCTAssertNil(engine.observe(draft("正文 Bingo"), now: 8, keyword: "Bingo", delay: 1))
        XCTAssertNil(engine.observe(draft("正文 Bingo"), now: 20, keyword: "Bingo", delay: 1))
    }
}
