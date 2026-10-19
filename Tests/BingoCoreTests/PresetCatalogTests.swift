import Foundation
import XCTest
@testable import BingoCore

final class PresetCatalogTests: XCTestCase {
    func testCustomKeywordValidationDoesNotAcceptUnmatchableTrailingPunctuation() {
        for keyword in ["Bingo!", "确定。", "Done?", "\n", "Bingo\nSubmit", "Bingo\rSubmit", "!!!", String(repeating: "a", count: 41)] {
            XCTAssertFalse(TriggerMatcher.isValidKeyword(keyword), keyword)
        }
        for keyword in KeywordCatalog.presets + ["  Custom Keyword  ", "Bingo+", "确定发送"] {
            XCTAssertTrue(TriggerMatcher.isValidKeyword(keyword), keyword)
        }
    }

    func testPresetIdentityAndPerPresetTargetsAreUnique() {
        let presets = AgentCatalog.presets
        XCTAssertEqual(Set(presets.map(\.id)).count, presets.count)
        for preset in presets {
            XCTAssertFalse(preset.id.isEmpty)
            XCTAssertFalse(preset.name.isEmpty)
            XCTAssertFalse(preset.detailZh.isEmpty, preset.id)
            XCTAssertFalse(preset.detailEn.isEmpty, preset.id)
            XCTAssertEqual(Set(preset.nativeBundleIDs).count, preset.nativeBundleIDs.count, preset.id)
            XCTAssertEqual(Set(preset.webHosts).count, preset.webHosts.count, preset.id)
        }
    }

    func testPresetDisplayOrderIsStable() {
        XCTAssertEqual(AgentCatalog.presets.map(\.id), [
            "codex-chatgpt", "claude", "gemini", "grok", "cursor", "huggingchat",
            "deepseek", "zcode", "kimi", "kimi-code", "workbuddy", "qoder-cn", "trae-cn"
        ])
    }

    func testWebTargetsUseExplicitOfficialEditorHosts() {
        let expected: [String: [String]] = [
            "codex-chatgpt": ["chatgpt.com"],
            "claude": ["claude.ai"],
            "gemini": ["gemini.google.com"],
            "grok": ["grok.com"],
            "cursor": ["cursor.com"],
            "huggingchat": ["huggingface.co"],
            "deepseek": ["chat.deepseek.com"],
            "kimi": ["www.kimi.com", "www.kimi.ai"]
        ]
        for preset in AgentCatalog.presets {
            XCTAssertEqual(preset.webHosts, expected[preset.id] ?? [], preset.id)
            for host in preset.webHosts {
                XCTAssertTrue(WebScope.allows(URL(string: "https://\(host)/"), hosts: [host]), host)
                XCTAssertFalse(WebScope.allows(URL(string: "https://\(host).example.org/"), hosts: [host]), host)
                XCTAssertFalse(WebScope.allows(URL(string: "https://example.org/?next=\(host)"), hosts: [host]), host)
            }
        }
        // The broad X social feed and model API endpoints are not chat presets.
        let hosts = AgentCatalog.presets.flatMap(\.webHosts)
        XCTAssertFalse(hosts.contains("x.com"))
        XCTAssertFalse(hosts.contains(where: { $0.hasPrefix("api.") }))
        XCTAssertFalse(hosts.contains("google.com"))
        XCTAssertFalse(hosts.contains("deepseek.com"))
    }

    func testMergingPreservesCustomHostsAndDoesNotBroadenSubdomains() {
        let merged = PresetDomains.merging(
            existing: " My.Chat.Example.com, CHAT.DEEPSEEK.COM；custom.example.net.\n",
            hosts: ["chat.deepseek.com", "gemini.google.com", " GEMINI.GOOGLE.COM. "]
        )
        XCTAssertEqual(merged, "my.chat.example.com\nchat.deepseek.com\ncustom.example.net\ngemini.google.com")
        let hosts = merged.components(separatedBy: "\n")
        for parent in ["example.com", "deepseek.com", "google.com"] {
            XCTAssertFalse(WebScope.allows(URL(string: "https://\(parent)/"), hosts: hosts), parent)
        }
    }

    func testAddingSeveralPresetsIsAdditiveAndIdempotent() throws {
        let deepseek = try XCTUnwrap(AgentCatalog.presets.first { $0.id == "deepseek" })
        let claude = try XCTUnwrap(AgentCatalog.presets.first { $0.id == "claude" })
        let first = PresetDomains.merging(existing: "custom.example.com", hosts: deepseek.webHosts)
        let second = PresetDomains.merging(existing: first, hosts: claude.webHosts)
        let third = PresetDomains.merging(existing: second, hosts: deepseek.webHosts + claude.webHosts)
        XCTAssertEqual(third, "custom.example.com\nchat.deepseek.com\nclaude.ai")
        XCTAssertEqual(PresetDomains.merging(existing: third, hosts: []), third)
    }

    func testMalformedExistingEntriesArePreservedWithoutGrantingAccess() {
        let merged = PresetDomains.merging(
            existing: "https://evil.example;*.example.org;user@example.net",
            hosts: ["chat.deepseek.com"]
        )
        let hosts = merged.components(separatedBy: "\n")
        XCTAssertTrue(merged.contains("https://evil.example"))
        XCTAssertFalse(WebScope.allows(URL(string: "https://evil.example"), hosts: hosts))
        XCTAssertFalse(WebScope.allows(URL(string: "https://anything.example.org"), hosts: hosts))
        XCTAssertFalse(WebScope.allows(URL(string: "https://example.net"), hosts: hosts))
        XCTAssertTrue(WebScope.allows(URL(string: "https://chat.deepseek.com"), hosts: hosts))
    }

    func testEveryKeywordRequiresBodyAndOnlyMatchesAtTheSuffix() throws {
        XCTAssertEqual(Set(KeywordCatalog.presets.map { $0.lowercased() }).count, KeywordCatalog.presets.count)
        XCTAssertEqual(KeywordCatalog.presets.first, "Bingo")
        for keyword in KeywordCatalog.presets {
            let text = "帮我检查这个页面，\(keyword)。\n"
            let match = try XCTUnwrap(TriggerMatcher.match(text: text, keyword: keyword), keyword)
            XCTAssertEqual((text as NSString).substring(with: match.keywordRange), keyword)
            XCTAssertNil(TriggerMatcher.match(text: "\(keyword)。", keyword: keyword), keyword)
            XCTAssertNil(TriggerMatcher.match(text: "正文 \(keyword) 后面还有内容", keyword: keyword), keyword)
        }
        XCTAssertNotNil(TriggerMatcher.match(text: "Review this BINGO!", keyword: "Bingo"))
        XCTAssertNil(TriggerMatcher.match(text: "Review this Submit.", keyword: "Bingo"))
        XCTAssertNil(TriggerMatcher.match(text: "Review this mySubmit.", keyword: "Submit"))
    }
}
