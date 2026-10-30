import Foundation
import XCTest
@testable import BingoCore

final class KeywordListTests: XCTestCase {
    func testListValidationAllowsOneToThreeKeywordsAndIgnoresEmptyRows() {
        XCTAssertTrue(TriggerMatcher.isValidKeywordList(["Bingo"]))
        XCTAssertTrue(TriggerMatcher.isValidKeywordList(["Bingo", "Send", "发送"]))
        XCTAssertTrue(TriggerMatcher.isValidKeywordList(["Bingo", "", "  ", "Send"]))
        XCTAssertFalse(TriggerMatcher.isValidKeywordList([]))
        XCTAssertFalse(TriggerMatcher.isValidKeywordList(["", "   "]))
        XCTAssertFalse(TriggerMatcher.isValidKeywordList(["Bingo", "Send", "发送", "提交"]))
        XCTAssertFalse(TriggerMatcher.isValidKeywordList(["Bingo", "确定。"]))
        XCTAssertFalse(TriggerMatcher.isValidKeywordList(["Bingo\nSubmit"]))
    }

    func testNormalizationTrimsDropsInvalidDeduplicatesAndCapsAtThree() {
        XCTAssertEqual(TriggerMatcher.normalizedKeywords(["  Bingo ", "", "bingo", " send "]),
            ["Bingo", "send"])
        XCTAssertEqual(TriggerMatcher.normalizedKeywords(["Bingo", "确定。", "Send"]), ["Bingo", "Send"])
        XCTAssertEqual(TriggerMatcher.normalizedKeywords(["A", "B", "C", "D"]), ["A", "B", "C"])
        XCTAssertEqual(TriggerMatcher.normalizedKeywords(["", "  "]), [])
        XCTAssertEqual(TriggerMatcher.maximumKeywordCount, 3)
    }

    func testAnyConfiguredKeywordEndsTheMessage() throws {
        let keywords = ["Bingo", "Send", "发送"]
        for keyword in keywords {
            let text = "帮我检查这个页面，\(keyword)。"
            let match = try XCTUnwrap(TriggerMatcher.match(text: text, keywords: keywords), keyword)
            XCTAssertEqual(match.keyword, keyword)
            XCTAssertEqual((text as NSString).substring(with: match.keywordRange), keyword)
            XCTAssertEqual(TriggerText.removingSuffix(from: text, keyword: match.keyword), "帮我检查这个页面，")
        }
        XCTAssertNil(TriggerMatcher.match(text: "Review this page.", keywords: keywords))
        XCTAssertNil(TriggerMatcher.match(text: "Review this Submit.", keywords: keywords))
    }

    func testMixedLanguageListMatchesEitherScript() throws {
        let keywords = ["Bingo", "Send", "发送"]
        let english = try XCTUnwrap(TriggerMatcher.match(text: "Done, SEND!", keywords: keywords))
        XCTAssertEqual(english.keyword, "Send")
        let chinese = try XCTUnwrap(TriggerMatcher.match(text: "做完了，发送。", keywords: keywords))
        XCTAssertEqual(chinese.keyword, "发送")
        // Chinese text may precede an English keyword.
        let mixed = try XCTUnwrap(TriggerMatcher.match(text: "检查页面Bingo", keywords: keywords))
        XCTAssertEqual(mixed.keyword, "Bingo")
    }

    func testLongestKeywordWinsWhenSeveralMatchTheSuffix() throws {
        // "Send" also matches at the end of "Bingo Send"; the longer keyword must
        // win so removal never leaves a stray "Bingo".
        let keywords = ["Bingo", "Bingo Send"]
        let text = "帮我检查，Bingo Send。"
        let match = try XCTUnwrap(TriggerMatcher.match(text: text, keywords: keywords))
        XCTAssertEqual(match.keyword, "Bingo Send")
        XCTAssertEqual(TriggerText.removingSuffix(from: text, keyword: match.keyword), "帮我检查，")
    }

    func testKeywordOrderDoesNotAffectMatching() throws {
        let text = "帮我检查，发送。"
        for keywords in [["发送", "Bingo"], ["Bingo", "发送"]] {
            let match = try XCTUnwrap(TriggerMatcher.match(text: text, keywords: keywords))
            XCTAssertEqual(match.keyword, "发送")
        }
    }

    func testEngineSendsOncePerEditForAnyKeyword() throws {
        let keywords = ["Bingo", "Send", "发送"]
        var engine = TriggerEngine()
        let draft = DraftSnapshot(targetID: "field-a", text: "", caretAtEnd: true)
        _ = engine.observe(draft, now: 0, keywords: keywords, delay: 1)

        let spoken = DraftSnapshot(targetID: "field-a", text: "检查页面，发送。", caretAtEnd: true)
        _ = engine.observe(spoken, now: 1, keywords: keywords, delay: 1)
        let action = try XCTUnwrap(engine.observe(spoken, now: 2, keywords: keywords, delay: 1))
        XCTAssertEqual(action.match.keyword, "发送")
        XCTAssertNil(engine.observe(spoken, now: 3, keywords: keywords, delay: 1))

        let second = DraftSnapshot(targetID: "field-a", text: "New message, Bingo.", caretAtEnd: true)
        _ = engine.observe(second, now: 4, keywords: keywords, delay: 1)
        XCTAssertNotNil(engine.observe(second, now: 5, keywords: keywords, delay: 1))
    }

    func testKeywordPackDefaultsFollowInterfaceLanguage() {
        XCTAssertEqual(KeywordCatalog.defaultPack(forSimplifiedChinese: false), ["Bingo", "Submit", "Send"])
        XCTAssertEqual(KeywordCatalog.defaultPack(forSimplifiedChinese: true), ["发送", "提交", "完成"])
        for keyword in KeywordCatalog.englishPack + KeywordCatalog.chinesePack + KeywordCatalog.mixedPack {
            XCTAssertTrue(TriggerMatcher.isValidKeyword(keyword), keyword)
        }
        XCTAssertEqual(KeywordCatalog.englishPack.count, TriggerMatcher.maximumKeywordCount)
        XCTAssertEqual(KeywordCatalog.chinesePack.count, TriggerMatcher.maximumKeywordCount)
        XCTAssertEqual(KeywordCatalog.mixedPack.count, TriggerMatcher.maximumKeywordCount)
    }
}