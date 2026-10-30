import Foundation
import XCTest
import BingoCore
@testable import BingoSend

final class PermissionOnboardingTests: XCTestCase {
    @MainActor
    private static func withDefaults(_ body: (UserDefaults) throws -> Void) throws {
        let name = "io.local.bingosend.tests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        try body(defaults)
    }

    func testFreshUntrustedLaunchRequestsOnceWithoutAlsoOpeningSettings() async throws {
        try await MainActor.run {
            try Self.withDefaults { defaults in
                var prompts = 0
                var settings = 0
                let model = AppModel(defaults: defaults, startsTimer: false,
                    trustReader: { false }, promptRequester: { prompts += 1 },
                    settingsOpener: { settings += 1 })
                model.requestInitialPermissionIfNeeded()
                model.requestInitialPermissionIfNeeded()
                XCTAssertEqual(prompts, 1)
                XCTAssertEqual(settings, 0)
                XCTAssertTrue(model.isPermissionRequestPending)
                XCTAssertFalse(model.isTrusted)
                XCTAssertEqual(model.runMode, .paused)
                XCTAssertTrue(model.preferences.rules.allSatisfy { !$0.enabled })
            }
        }
    }

    func testFreshAlreadyTrustedLaunchDoesNotPrompt() async throws {
        try await MainActor.run {
            try Self.withDefaults { defaults in
                var prompts = 0
                var settings = 0
                let model = AppModel(defaults: defaults, startsTimer: false,
                    trustReader: { true }, promptRequester: { prompts += 1 },
                    settingsOpener: { settings += 1 })
                model.requestInitialPermissionIfNeeded()
                XCTAssertTrue(model.isTrusted)
                XCTAssertFalse(model.isPermissionRequestPending)
                XCTAssertEqual(prompts, 0)
                XCTAssertEqual(settings, 0)
                XCTAssertFalse(model.isEnabled)
            }
        }
    }

    func testRelaunchAfterDecliningDoesNotRepeatPromptOrReplacePreferences() async throws {
        try await MainActor.run {
            try Self.withDefaults { defaults in
                var prompts = 0
                let first = AppModel(defaults: defaults, startsTimer: false,
                    trustReader: { false }, promptRequester: { prompts += 1 }, settingsOpener: {})
                first.preferences.keywords = ["Bingo", "发送"]
                first.requestInitialPermissionIfNeeded()
                let relaunched = AppModel(defaults: defaults, startsTimer: false,
                    trustReader: { false }, promptRequester: { prompts += 1 }, settingsOpener: {})
                relaunched.requestInitialPermissionIfNeeded()
                XCTAssertEqual(prompts, 1)
                XCTAssertEqual(relaunched.preferences.keywords, ["Bingo", "发送"])
                XCTAssertFalse(relaunched.isPermissionRequestPending)
                XCTAssertFalse(relaunched.isEnabled)
            }
        }
    }

    func testPermissionGrantRefreshesWhilePausedWithoutOptingIntoApps() async throws {
        try await MainActor.run {
            try Self.withDefaults { defaults in
                var trusted = false
                let model = AppModel(defaults: defaults, startsTimer: false,
                    trustReader: { trusted }, promptRequester: {}, settingsOpener: {})
                model.requestInitialPermissionIfNeeded()
                let before = model.preferences
                trusted = true
                XCTAssertTrue(model.refreshPermission())
                XCTAssertTrue(model.isTrusted)
                XCTAssertFalse(model.isPermissionRequestPending)
                XCTAssertEqual(model.preferences, before)
                XCTAssertEqual(model.runMode, .paused)
                XCTAssertFalse(model.canStart) // The user still needs to choose an app.
            }
        }
    }

    func testRevocationBlocksRunningModeWithoutRepeatingInitialPrompt() async throws {
        try await MainActor.run {
            try Self.withDefaults { defaults in
                var trusted = true
                var prompts = 0
                let model = AppModel(defaults: defaults, startsTimer: false,
                    trustReader: { trusted }, promptRequester: { prompts += 1 }, settingsOpener: {})
                model.requestInitialPermissionIfNeeded()
                model.preferences.rules = [ApplicationRule(name: "Test", bundleIdentifier: "example.test")]
                model.runMode = .automatic
                trusted = false
                model.refreshPermission()
                XCTAssertEqual(model.runState, .needsPermission)
                XCTAssertFalse(model.canStart)
                model.requestInitialPermissionIfNeeded()
                XCTAssertEqual(prompts, 0)
                model.runMode = .paused
                XCTAssertEqual(model.runMode, .paused)
            }
        }
    }

    func testExplicitSettingsFallbackNeverCreatesASecondNativePrompt() async throws {
        try await MainActor.run {
            try Self.withDefaults { defaults in
                var prompts = 0
                var settings = 0
                let model = AppModel(defaults: defaults, startsTimer: false,
                    trustReader: { false }, promptRequester: { prompts += 1 },
                    settingsOpener: { settings += 1 })
                model.requestInitialPermissionIfNeeded()
                model.openPermissionSettings()
                XCTAssertEqual(prompts, 1)
                XCTAssertEqual(settings, 1)
                XCTAssertTrue(model.isPermissionRequestPending)
            }
        }
    }

    func testClearingPreferencesMakesNextInstallRequestAgain() async throws {
        try await MainActor.run {
            try Self.withDefaults { defaults in
                var prompts = 0
                let first = AppModel(defaults: defaults, startsTimer: false,
                    trustReader: { false }, promptRequester: { prompts += 1 }, settingsOpener: {})
                first.requestInitialPermissionIfNeeded()
                defaults.removeObject(forKey: "bingoPermissionOnboardingHandledV1")
                let reinstalled = AppModel(defaults: defaults, startsTimer: false,
                    trustReader: { false }, promptRequester: { prompts += 1 }, settingsOpener: {})
                reinstalled.requestInitialPermissionIfNeeded()
                reinstalled.requestInitialPermissionIfNeeded()
                XCTAssertEqual(prompts, 2)
                XCTAssertFalse(reinstalled.isEnabled)
            }
        }
    }
}
