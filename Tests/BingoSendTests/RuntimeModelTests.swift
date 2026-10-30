import Foundation
import XCTest
import BingoCore
@testable import BingoSend

final class RuntimeModelTests: XCTestCase {
    func testRelaunchPausesWithoutReplacingSavedConfiguration() async throws {
        try await MainActor.run {
            let name = "io.local.bingosend.tests.\(UUID().uuidString)"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
            defer { defaults.removePersistentDomain(forName: name) }
            var saved = Preferences()
            saved.keywords = ["Bingo", "发送"]
            saved.detectOnly = false
            saved.removeTriggerBeforeSend = true
            saved.rules = [ApplicationRule(name: "Test app", bundleIdentifier: "example.test")]
            let data = try JSONEncoder().encode(saved)
            defaults.set(data, forKey: "bingoPreferencesV1")
            let model = AppModel(defaults: defaults, startsTimer: false)
            XCTAssertEqual(model.runMode, .paused)
            XCTAssertEqual(model.runState, .paused)
            XCTAssertEqual(model.preferences, saved)
            model.isEnabled = true
            XCTAssertEqual(model.runMode, .automatic)
            model.runMode = .paused
            XCTAssertFalse(model.isEnabled)
            XCTAssertFalse(model.preferences.detectOnly)
            XCTAssertEqual(defaults.data(forKey: "bingoPreferencesV1"), data)
        }
    }
}
