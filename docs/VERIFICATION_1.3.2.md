# 1.3.2 build 13 verification — 2026-10-30

## Automated and package checks

- `swift test`: **76 passed, zero failures** — 58 BingoCore tests plus 18 BingoSend tests. The latter include seven isolated permission-onboarding regressions. Final test and build logs contain no compiler warnings or errors.
- `./build.sh --universal`: arm64 and x86_64; all 10 icon variants validated before/after ICNS conversion; ad-hoc signature verified.
- DMG/ZIP/SHA256SUMS produced from the final fixed build. Both package checksums passed. Installed, built, and ZIP-extracted executables are identical (SHA-256 `d2ca8d58b5842eb0313fc36dedca0aa3f5306c5b0a5dfbb50a650975d6bf3c52`). A read-only mount also confirmed the DMG version, signature, and identical executable. The binary was not rebuilt or re-signed during real permission QA.
- ZIP SHA-256: `ab9c8c3cdb14057cab901b199eced0ce18c93df9f3ab9b9621b2c363450be8df`.
- DMG SHA-256: `a2d6e50192b0073dad6c572f0f8b10b6f77b9ddf74bcd0f127aa56a0b8cd4fe3`.

## Actual clean-install flow

1. Backed up the previous application and local settings. Removed app-specific preferences/test remnants and replaced the installed application. Reset only `io.local.bingosend` Accessibility permission; retained source/Git and other apps' permissions.
2. Installed the fixed 1.3.2/build 13 application. Its first window showed the pending initial request, paused state, default Chinese keywords, and no enabled target apps.
3. **The user confirmed seeing the automatic macOS permission prompt and personally completing authorization.** No automation clicked the grant toggle.
4. Live UI then showed authorization success, removed the primary grant controls, and added the collapsed Permissions & diagnostics entry at the bottom.
5. The Choose target apps action actually scrolled the native grouped Form to the app list. Enabling targets made the run modes selectable. Authorized diagnostics expanded and exposed working Refresh permission status and Open System Settings actions.
6. Opened System Settings from diagnostics and closed that window: Bingo Send's main window and process remained available.
7. The user configured Codex / DeepSeek Harness / ZCode and explicitly reported successful real sending. Bingo's visible last-result records also showed shortcut posting to Codex and DeepSeek; those records alone are not delivery receipts.

## Boundaries

- A local-only QA editor was prepared and temporarily added, but its full detection/keep/removal/pause matrix was **not executed**. The user requested that UI automation stop because changing focus interrupted their ongoing input; their real-app send tests are recorded as user-confirmed results, not autonomous fixture results. The helper is outside production source and release packages.
- Closing the Bingo main window then reopening through Finder, full app relaunch, and revocation/regrant on the user's real grant were not independently exercised in this round. Isolated tests cover repeat presentation, relaunch marker persistence, revocation, and preferences-reset logic. No further TCC reset was performed after the user authorized this fixed build.
- Focus or configuration changes intentionally cancel pending sending. Do not operate the UI while validating continuous dictation into another app.
- No Intel hardware or minimum-macOS physical runtime verification. Packages remain ad-hoc signed and not Apple notarized.

Count correction: the earlier 1.3.1 summary reported the 58-test core suite alone; its full run also contained 11 app tests, for 69 in total. This record reports both suites explicitly.
