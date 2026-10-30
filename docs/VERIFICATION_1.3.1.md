# 1.3.1 preview verification — 2026-10-30

- `swift test`: 69 tests (58 core + 11 app), zero failures; final test/build logs contain no compiler warnings or errors. The initial summary counted the core suite only; this total includes both XCTest bundles.
- `./build.sh --universal`: arm64 + x86_64, ad-hoc signature verified; 10 icon variants validated before and after ICNS conversion.
- `./scripts/package-release.sh`: version 1.3.1 / build 12 ZIP, DMG, and SHA256SUMS created. Both checksums passed. Extracted ZIP signature and executable matched the installed build.
- Installed at `/Applications/Bingo Send.app`; previous installed application backed up locally outside tracked source. Saved preference-data SHA-256 unchanged across replacement and launch. No real-user settings were toggled for automated tests.
- Native UI inspection: version 1.3.1, initial Paused state, separate Test detection / Auto send choices, saved Bingo and 发送 keywords and existing app rules retained. Missing Accessibility permission disables starting and gives an explicit grant instruction. User must grant it in System Settings.
- Native local-preview check: matched Bingo, preview removed only the final suffix; editing the sample cleared the prior result. This check did not send a message or validate another app.
- Mode/block and relaunch regressions use isolated test preferences. Real-user Accessibility settings were not reset or changed.
- Per-app 1.3.1 detection/keep/removal sending, permission regrant, Intel hardware, and minimum-macOS runtime: **not executed**. Follow the release-note checklist before publishing a stable release.
- ZCode was observed with no ready model and its own Send button disabled; its actual send regression remains pending. Earlier successful Codex / DeepSeek reports were user observations on 1.3.0.

Packages are not Apple notarized. No public stable release is claimed by this record.
