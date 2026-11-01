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

    @MainActor
    func testUncertainEditFailureKeepsAutomaticModeAndSavedPreferences() throws {
        try Self.withAutomaticModel { model in
            let saved = model.preferences
            let error = AccessibilityFailure.removalInterrupted(cause: "Test edit confirmation timeout")
            model.recordSendFailure(error,
                snapshot: DraftSnapshot(targetID: "editor-a", text: "测试正文发送发送。", caretAtEnd: true),
                removalKeyword: "发送", appName: "Test editor")
            XCTAssertTrue(model.isEnabled)
            XCTAssertEqual(model.runMode, .automatic)
            XCTAssertEqual(model.runState, .automatic)
            XCTAssertEqual(model.preferences, saved)
            XCTAssertEqual(model.sendFailureMessage, error.localizedDescription)
        }
    }

    @MainActor
    func testRepeatedFailuresNeverSwitchTheSelectedModeToPaused() throws {
        try Self.withAutomaticModel { model in
            for index in 0..<50 {
                model.recordSendFailure(AccessibilityFailure.sendFailure(phase: .beforeSend, reason: .focus),
                    snapshot: DraftSnapshot(targetID: "editor-a", text: "新内容\(index)发送。", caretAtEnd: true),
                    removalKeyword: "发送", appName: "Test editor")
                XCTAssertTrue(model.isEnabled)
                XCTAssertEqual(model.runMode, .automatic)
            }
        }
    }

    @MainActor
    func testFailureReportingDoesNotResumeAManuallyPausedSession() throws {
        try Self.withAutomaticModel { model in
            model.runMode = .paused
            model.recordSendFailure(AccessibilityFailure.textUnavailable,
                snapshot: DraftSnapshot(targetID: "editor-a", text: "测试正文发送。", caretAtEnd: true),
                removalKeyword: "发送", appName: "Test editor")
            XCTAssertFalse(model.isEnabled)
            XCTAssertEqual(model.runMode, .paused)
        }
    }

    @MainActor
    private static func withAutomaticModel(_ body: (AppModel) throws -> Void) throws {
        let name = "io.local.bingosend.tests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let model = AppModel(defaults: defaults, startsTimer: false,
            trustReader: { true }, promptRequester: {}, settingsOpener: {})
        model.preferences.keywords = ["发送"]
        model.preferences.rules = [ApplicationRule(name: "Test editor", bundleIdentifier: "example.test")]
        model.preferences.removeTriggerBeforeSend = true
        model.runMode = .automatic
        try body(model)
    }
}
