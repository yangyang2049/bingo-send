import Foundation
import XCTest
@testable import BingoSend

final class PreferencesTests: XCTestCase {
    func testOldPreferencesKeepUserConfigurationAndDefaultToKeepingKeyword() throws {
        let old = Data(#"{"keyword":"提交","stabilityDelay":2.2,"detectOnly":false,"rules":[{"id":"7226FA78-EF16-4B2D-8097-D3C83F96DFAF","name":"Custom Agent","bundleIdentifier":"example.agent","enabled":true,"shortcut":"commandReturn","allowSingleLine":true,"restrictToWeb":true,"domainText":"chat.example.com"}]}"#.utf8)
        let preferences = try JSONDecoder().decode(Preferences.self, from: old)
        XCTAssertEqual(preferences.keyword, "提交")
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
        preferences.keyword = "Submit"
        let restored = try JSONDecoder().decode(Preferences.self,
            from: JSONEncoder().encode(preferences))
        XCTAssertEqual(restored, preferences)
    }

    func testFreshInstallRequiresOptInForAppsAndRemoval() {
        let preferences = Preferences()
        XCTAssertTrue(preferences.detectOnly)
        XCTAssertFalse(preferences.removeTriggerBeforeSend)
        XCTAssertEqual(preferences.keyword, "Bingo")
        XCTAssertTrue(preferences.rules.allSatisfy { !$0.enabled })
    }
}
