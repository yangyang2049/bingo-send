import XCTest
@testable import BingoCore

final class RunModeTests: XCTestCase {
    func testPausedOverridesEitherSavedBehavior() {
        for detectOnly in [false, true] {
            XCTAssertEqual(RunMode(isEnabled: false, detectOnly: detectOnly), .paused)
        }
    }

    func testListeningHasExactlyOneBehavior() {
        XCTAssertEqual(RunMode(isEnabled: true, detectOnly: true), .testing)
        XCTAssertEqual(RunMode(isEnabled: true, detectOnly: false), .automatic)
    }

    func testPauseRemainsAvailableWithoutPermissionOrValidSettings() {
        XCTAssertEqual(RunState.resolve(mode: .paused, trusted: false,
            validKeywords: false, hasEnabledApps: false), .paused)
    }

    func testRunningModesExposeBlocksInsteadOfLookingReady() {
        for mode in [RunMode.testing, .automatic] {
            XCTAssertEqual(RunState.resolve(mode: mode, trusted: false,
                validKeywords: true, hasEnabledApps: true), .needsPermission)
            XCTAssertEqual(RunState.resolve(mode: mode, trusted: true,
                validKeywords: false, hasEnabledApps: true), .invalidKeywords)
            XCTAssertEqual(RunState.resolve(mode: mode, trusted: true,
                validKeywords: true, hasEnabledApps: false), .noEnabledApps)
        }
    }

    func testReadyModesNeverConflateTestingWithSending() {
        XCTAssertEqual(RunState.resolve(mode: .testing, trusted: true,
            validKeywords: true, hasEnabledApps: true), .testing)
        XCTAssertEqual(RunState.resolve(mode: .automatic, trusted: true,
            validKeywords: true, hasEnabledApps: true), .automatic)
    }
}
