<p align="center">
  <img src="assets/hero.svg" alt="Bingo Send — say it, send it" width="100%">
</p>

<p align="center"><strong>Keep your favorite input method. End your message with “Bingo” to send it.</strong></p>

<p align="center">
  <a href="https://github.com/yangyang2049/bingo-send/releases/latest"><img src="https://img.shields.io/github/v/release/yangyang2049/bingo-send?style=flat-square&color=126E6B" alt="Latest release"></a>
  <a href="https://github.com/yangyang2049/bingo-send/actions/workflows/ci.yml"><img src="https://github.com/yangyang2049/bingo-send/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="docs/COMPATIBILITY.md"><img src="https://img.shields.io/badge/target-macOS%2013%2B-333333?style=flat-square&logo=apple&logoColor=white" alt="Targets macOS 13 and later"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-22a06b?style=flat-square" alt="MIT license"></a>
</p>

<p align="center">
  <a href="https://github.com/yangyang2049/bingo-send/releases/download/v1.1.1/BingoSend-1.1.1-macOS-universal.dmg"><img src="https://img.shields.io/badge/Download_for_macOS-1.1.1-126E6B?style=for-the-badge&logo=apple&logoColor=white" alt="Download Bingo Send 1.1.1 for macOS"></a>
</p>

<p align="center">
  <strong>English</strong> · <a href="README.zh-CN.md">简体中文</a> · <a href="docs/USER_GUIDE.md">User guide</a> · <a href="https://github.com/yangyang2049/bingo-send/releases/latest">All downloads</a>
</p>

Bingo Send is a standalone macOS menu bar app. It watches the focused editor in apps you enable, waits for text to settle, then triggers the configured send shortcut. **Your entire message, including Bingo, stays unchanged.** No Skill or AI agent is needed.

```text
“Review this page, Bingo.” → text settles → sends “Review this page, Bingo.”
```

## Start in three steps

1. **Install.** Open the [universal DMG](https://github.com/yangyang2049/bingo-send/releases/download/v1.1.1/BingoSend-1.1.1-macOS-universal.dmg), drag Bingo Send into Applications, and open it. The package contains Apple Silicon and Intel binaries.
2. **Authorize and choose an app.** Grant Accessibility permission in System Settings yourself. Enable your target app and check its shortcut; Codex defaults to **Return**. Configure allowed domains for browsers.
3. **Try, then enable sending.** Turn on keyword sending with the default detection-only mode. After a successful detection, turn off detection-only mode to send messages. **Every launch starts paused.**

The app interface is currently **Chinese**. See the [English guide](docs/USER_GUIDE.md) for the corresponding controls.

## Small app, focused job

- **Your input method:** works on text after dictation, typing, or pasting.
- **Your keyword:** customizable suffix; English case, trailing spaces, and punctuation are handled. Stabilization delay: 0.5–3 seconds.
- **Your apps:** explicit app allowlist, domain restrictions, and Return / ⌘ Return / ⌃ Return shortcuts.
- **Local processing:** no recording, networking, saved drafts, text edits, selection changes, or clipboard access. [Privacy →](docs/PRIVACY.md)

## Compatibility

**Codex was user-tested successfully with 1.1.0.** Version 1.1.1 retains that sending logic and passed build, signature, and packaging checks. Other apps and websites—including WorkBuddy, DeepSeek, and Hugging Face—**still need separate validation**. An allowlist entry is not a compatibility guarantee. [Compatibility details →](docs/COMPATIBILITY.md)

<details>
<summary>Before you install: permissions and limitations</summary>

- Packages are **ad-hoc signed, not Apple notarized**. If macOS blocks opening, follow [Apple’s instructions](https://support.apple.com/102445). Accessibility access requires your manual approval.
- The project targets **macOS 13+**; the minimum OS and **Intel runtime have not been tested on physical devices**.
- Editors must expose readable Accessibility text and caret information. The caret must be at the end, with no selection.
- Known browsers require domain restrictions. For an unrecognized browser, enable “按网页域名限制” manually.
- Bingo Send **cannot stop your input method’s recording session**. It acts only after text appears; adjust the delay for continuous transcription.

</details>

## Build and contribute

Requires macOS and Swift 5.9+ (Xcode or Command Line Tools). No external dependencies.

```sh
swift test
./build.sh
# Universal build and release packages:
./build.sh --universal
./scripts/package-release.sh
```

Output: `build/Bingo Send.app`; packages: `dist/`.

[Contributing](CONTRIBUTING.md) · [Release guide](docs/RELEASING.md) · [Report an issue](https://github.com/yangyang2049/bingo-send/issues/new/choose)

Licensed under [MIT](LICENSE). Independent project; not affiliated with the input methods or AI products mentioned.
