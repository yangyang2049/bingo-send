import Foundation
import XCTest
import BingoCore
@testable import BingoSend

final class PreferencesTests: XCTestCase {
    func testOldPreferencesKeepUserConfigurationAndDefaultToKeepingKeyword() throws {
        let old = Data(#"{"keyword":"提交","stabilityDelay":2.2,"detectOnly":false,"rules":[{"id":"7226FA78-EF16-4B2D-8097-D3C83F96DFAF","name":"Custom Agent","bundleIdentifier":"example.agent","enabled":true,"shortcut":"commandReturn","allowSingleLine":true,"restrictToWeb":true,"domainText":"chat.example.com"}]}"#.utf8)
        let preferences = try JSONDecoder().decode(Preferences.self, from: old)
        // One saved keyword stays exactly one keyword: no invented triggers.
        XCTAssertEqual(preferences.keywords, ["提交"])
        XCTAssertEqual(preferences.stabilityDelay, 2.2)
        XCTAssertFalse(preferences.detectOnly)
        XCTAssertFalse(preferences.removeTriggerBeforeSend)
        let rule = try XCTUnwrap(preferences.rules.first)
        XCTAssertTrue(rule.enabled)
        XCTAssertEqual(rule.shortcut, .commandReturn)
        XCTAssertEqual(rule.domainText, "chat.example.com")
        XCTAssertTrue(rule.allowSingleLine)
    }

    func testRemovalOptionRoundTripsWithoutChangingExistingRules() throws {
        var preferences = Preferences()
        preferences.removeTriggerBeforeSend = true
        preferences.keywords = ["Submit"]
        let restored = try JSONDecoder().decode(Preferences.self,
            from: JSONEncoder().encode(preferences))
        XCTAssertEqual(restored, preferences)
    }

    func testFreshInstallRequiresOptInForAppsAndRemoval() {
        let preferences = Preferences()
        XCTAssertTrue(preferences.detectOnly)
        XCTAssertFalse(preferences.removeTriggerBeforeSend)
        XCTAssertEqual(preferences.keywords.count, 3)
        XCTAssertTrue(TriggerMatcher.isValidKeywordList(preferences.keywords))
        XCTAssertTrue(preferences.rules.allSatisfy { !$0.enabled })
    }

    func testKeywordListRoundTripsAndStaysPrimarySourceOfTruth() throws {
        var preferences = Preferences()
        preferences.keywords = ["Bingo", "Send", "发送"]
        let data = try JSONEncoder().encode(preferences)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        // The legacy single `keyword` is still written for older builds.
        XCTAssertEqual(object["keyword"] as? String, "Bingo")
        XCTAssertEqual(object["keywords"] as? [String], ["Bingo", "Send", "发送"])
        XCTAssertEqual(try JSONDecoder().decode(Preferences.self, from: data).keywords,
            ["Bingo", "Send", "发送"])
    }

    func testSavedKeywordListIsPreferredOverLegacyKeyword() throws {
        let mixed = Data(#"{"keyword":"Bingo","keywords":["Bingo","Send","发送"],"stabilityDelay":1,"detectOnly":true,"rules":[]}"#.utf8)
        XCTAssertEqual(try JSONDecoder().decode(Preferences.self, from: mixed).keywords,
            ["Bingo", "Send", "发送"])
    }
}