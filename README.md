# Bingo Send

**Keep your input method. End a message with “Bingo” to send it.**

Bingo Send is a standalone macOS menu bar app. Once dictated or typed text settles, it detects a final keyword, checks the focused editor and caret, and posts the configured send shortcut. **The entire draft, including Bingo, is preserved.**

**English** · [简体中文](README.zh-CN.md) · [GitHub](https://github.com/yangyang2049/bingo-send) · [User guide](docs/USER_GUIDE.md) · [Compatibility](docs/COMPATIBILITY.md) · [Privacy](docs/PRIVACY.md)

## Install

Download the [1.1.1 universal DMG](https://github.com/yangyang2049/bingo-send/releases/download/v1.1.1/BingoSend-1.1.1-macOS-universal.dmg), or find the latest version in [Releases](https://github.com/yangyang2049/bingo-send/releases/latest). Drag Bingo Send into Applications and open it. A universal build includes Apple Silicon and Intel binaries. No Codex, Skill, Xcode, or command-line tools are required to use the app.

Grant Accessibility permission in System Settings, enable the target app, and check its send shortcut. Codex defaults to Return. Test with the default detection-only mode, then disable it for actual sending. The app starts paused on every launch.

Current packages are ad-hoc signed and are not Apple notarized. See [Apple’s opening instructions](https://support.apple.com/102445) if Gatekeeper blocks launch. Accessibility permission always requires the user’s own action.

## Scope

- Custom final keyword, case-insensitive English matching, trailing punctuation supported.
- Adjustable stabilization delay, 0.5–3 seconds.
- App allowlist and configurable Return / Command-Return / Control-Return.
- Known browsers enforce domain restrictions. Enable “按网页域名限制” manually for unrecognized browsers.
- No recording, networking, stored drafts, text edits, selection changes, or clipboard access.

Version 1.1.0 was confirmed working in Codex by a user. Version 1.1.1 retains its core sending logic and has passed build, signature, and packaging checks. Other apps and websites require separate validation. The target editor must expose readable Accessibility text and caret information. The package targets macOS 13+, but the minimum OS version and Intel runtime still need physical-device verification.

Input methods remain responsible for dictation. Bingo Send cannot end their recording sessions. Typed and pasted text can also trigger sending. The app interface is currently in Chinese. Project documentation is available in English and Simplified Chinese; app localization can be contributed in a future update.

## Build

Requires macOS and Swift 5.9+ from Xcode or Command Line Tools. No external dependencies.

```sh
swift test
./build.sh
# Or build both architectures and package:
./build.sh --universal
./scripts/package-release.sh
```

Output: `build/Bingo Send.app` and packages in `dist/`. See [release instructions](docs/RELEASING.md) for signing, notarization, and the manually dispatched draft-release workflow.

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) and avoid sharing private drafts. Licensed under [MIT](LICENSE). Independent project; not affiliated with the input methods or AI products mentioned here.
