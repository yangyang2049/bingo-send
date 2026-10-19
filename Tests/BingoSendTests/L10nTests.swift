import XCTest
@testable import BingoSend

final class L10nTests: XCTestCase {
    func testUnsupportedOrEmptyPreferredLanguagesDefaultToEnglish() {
        for languages in [[], ["fr-FR"], ["ja-JP", "de-DE"], [""], ["ar-ZH"]] {
            XCTAssertEqual(L10n.language(for: languages), .english)
        }
    }

    func testEnglishRegionalAndNormalizedTagsResolveToEnglish() {
        for tag in ["en", "en-US", "en-GB", "EN_us", " en-AU "] {
            XCTAssertEqual(L10n.language(for: [tag]), .english, tag)
        }
    }

    func testAllChineseScriptsAndRegionsUseSimplifiedChineseCopy() {
        for tag in ["zh", "zh-Hans", "zh-CN", "zh-SG", "zh-Hant", "zh-TW", "zh-HK", "ZH_hant_MO"] {
            XCTAssertEqual(L10n.language(for: [tag]), .simplifiedChinese, tag)
        }
    }

    func testFirstSupportedPreferredLanguageWins() {
        XCTAssertEqual(L10n.language(for: ["en-US", "zh-Hans"]), .english)
        XCTAssertEqual(L10n.language(for: ["zh-Hant", "en-GB"]), .simplifiedChinese)
        XCTAssertEqual(L10n.language(for: ["fr-FR", "zh-CN", "en-US"]), .simplifiedChinese)
        XCTAssertEqual(L10n.language(for: ["ja-JP", "en-GB", "zh-CN"]), .english)
    }

    func testTextUsesRequestedCopyWithoutChangingUserContent() {
        let zh = "识别到 Bingo：正文 👨‍👩‍👧‍👦 cafe\u{301}"
        let en = "Detected Bingo: draft 👨‍👩‍👧‍👦 cafe\u{301}"
        XCTAssertEqual(L10n.text(zh: zh, en: en, preferredLanguages: ["zh-Hans-CN"]), zh)
        XCTAssertEqual(L10n.text(zh: zh, en: en, preferredLanguages: ["en-US"]), en)
        XCTAssertEqual(L10n.text(zh: zh, en: en, preferredLanguages: ["ko-KR"]), en)
    }
}
