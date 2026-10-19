import XCTest
@testable import BingoCore

final class TriggerTextTests: XCTestCase {
    func testRemovesFinalKeywordAndFollowingDictationPunctuation() {
        XCTAssertEqual(TriggerText.removingSuffix(from: "Please review, bInGo!。？\n", keyword: "Bingo"),
            "Please review, ")
    }

    func testPreservesPunctuationAndWhitespaceBeforeKeywordExactly() throws {
        let prefix = "First line;\r\n第二行。  \t"
        let result = try XCTUnwrap(TriggerText.removingSuffix(from: prefix + "Bingo。  \n", keyword: "Bingo"))
        XCTAssertTrue(result.utf16.elementsEqual(prefix.utf16))
    }

    func testPreservesCodeAndEarlierKeyword() {
        let prefix = "Discuss Bingo.\n```swift\nprint(\"Bingo\");\n```\n"
        XCTAssertEqual(TriggerText.removingSuffix(from: prefix + "Bingo!", keyword: "Bingo"), prefix)
    }

    func testPreservesEmojiAndDecomposedUnicodePrefix() throws {
        let prefix = "检查 👨‍👩‍👧‍👦 与 cafe\u{301}。 "
        let result = try XCTUnwrap(TriggerText.removingSuffix(from: prefix + "Bingo。", keyword: "Bingo"))
        XCTAssertTrue(result.utf16.elementsEqual(prefix.utf16))
    }

    func testChineseTextMayDirectlyPrecedeEnglishKeyword() {
        XCTAssertEqual(TriggerText.removingSuffix(from: "检查页面Bingo。", keyword: "Bingo"), "检查页面")
    }

    func testCustomChineseAndWhitespacePaddedKeyword() {
        XCTAssertEqual(TriggerText.removingSuffix(from: "请处理页面，确定。", keyword: " 确定\n"), "请处理页面，")
    }

    func testMiddleKeywordAndEnglishIdentifierAreNotRemoved() {
        for text in ["Bingo 帮我检查", "请讨论 Bingo 的含义", "Review myBingo", "Review _Bingo", "Review Bingo later"] {
            XCTAssertNil(TriggerText.removingSuffix(from: text, keyword: "Bingo"), text)
        }
    }

    func testOnlyKeywordOrPunctuationBodyDoesNotProduceSendableText() {
        for text in ["", "Bingo", " Bingo。", "，： Bingo!\n"] {
            XCTAssertNil(TriggerText.removingSuffix(from: text, keyword: "Bingo"), text)
        }
        XCTAssertNil(TriggerText.removingSuffix(from: "正文 Bingo", keyword: " \n"))
    }

    func testTrailingEmojiIsNotDiscardedAsPunctuation() {
        XCTAssertNil(TriggerText.removingSuffix(from: "正文 Bingo 👋", keyword: "Bingo"))
    }
}
