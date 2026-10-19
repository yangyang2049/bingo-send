<p align="center">
  <img src="assets/hero.svg" alt="Bingo Send — say it, send it" width="100%">
</p>

<p align="center"><strong>Keep your favorite input method. End your message with “Bingo” to send it.</strong></p>

<p align="center">
  <a href="https://github.com/yangyang2049/bingo-send/releases/latest"><img src="https://img.shields.io/github/v/release/yangyang2049/bingo-send?style=flat-square&color=111111" alt="Latest release"></a>
  <a href="https://github.com/yangyang2049/bingo-send/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/yangyang2049/bingo-send/ci.yml?branch=main&style=flat-square&color=111111&labelColor=333333" alt="CI"></a>
  <a href="docs/COMPATIBILITY.md"><img src="https://img.shields.io/badge/target-macOS%2013%2B-333333?style=flat-square&logo=apple&logoColor=white" alt="Targets macOS 13 and later"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-333333?style=flat-square" alt="MIT license"></a>
</p>

<p align="center">
  <a href="https://github.com/yangyang2049/bingo-send/releases/download/v1.2.0/BingoSend-1.2.0-macOS-universal.dmg"><img src="https://img.shields.io/badge/Download_for_macOS-1.2.0-111111?style=for-the-badge&logo=apple&logoColor=white" alt="Download Bingo Send 1.2.0 for macOS"></a>
</p>

<p align="center">
  <strong>English</strong> · <a href="README.zh-CN.md">简体中文</a> · <a href="docs/USER_GUIDE.md">User guide</a> · <a href="https://github.com/yangyang2049/bingo-send/releases/latest">All downloads</a>
</p>

Bingo Send is a standalone macOS menu bar app. It watches the focused editor in apps you enable, waits for text to settle, then triggers the configured send shortcut. **By default, your entire message and keyword stay unchanged.** You can optionally remove the final keyword before sending. No Skill or AI agent is needed.

```text
“Review this page, Bingo.” → text settles → sends “Review this page, Bingo.”
```

## Start in three steps

1. **Install.** Open the [universal DMG](https://github.com/yangyang2049/bingo-send/releases/download/v1.2.0/BingoSend-1.2.0-macOS-universal.dmg), drag Bingo Send into Applications, and open it. The package contains Apple Silicon and Intel binaries.
2. **Authorize and choose your setup.** Grant Accessibility permission in System Settings yourself. Choose an app or website from **App presets** (`应用预设`), or add an app manually. For a website, select your browser and review the allowed domains and send shortcut; Codex defaults to **Return**.
3. **Choose a keyword and try it.** Select one preset keyword or enter your own. Turn on keyword sending with detection-only mode, test a new message, then turn off detection-only mode for actual sending. **Fresh installs start with every app disabled and detection-only on; every launch starts paused.** Existing saved settings are preserved.

The app interface is currently **Chinese**. See the [English guide](docs/USER_GUIDE.md) for the corresponding controls.

## Small app, focused job

- **Your input method:** works on text after dictation, typing, or pasting.
- **Your keyword:** choose Bingo, Submit, Send, 发送, 提交, 完成, 确认, 确定, or a custom suffix. One keyword is active at a time; English matching is case-insensitive and trailing spaces or punctuation are allowed. Stabilization delay: 0.5–3 seconds.
- **Keep or remove:** keep the keyword by default, or opt in to **Remove final keyword before sending** (`发送前移除句尾口令`). Removal edits the focused draft and requires editor support; verify it separately in each app.
- **Your setup:** 13 opt-in app and website presets, plus manual app selection. Web presets preserve existing allowed domains; all enabled sites in one browser share its Return / ⌘ Return / ⌃ Return shortcut.
- **Your scope:** explicit app allowlist and browser domain restrictions. Presets help configure scope; each editor still needs its own detection and send test.
- **Local processing:** no recording, networking, saved drafts, or clipboard access. Default keep mode leaves text and selection untouched; optional removal edits only the matched final keyword and following punctuation or whitespace. [Privacy →](docs/PRIVACY.md)

## Compatibility

**Codex was user-tested successfully with 1.1.0 in keep mode.** Version 1.2.0 adds setup presets, keyword choices, optional removal, and a new icon; see its [release notes](docs/RELEASE_NOTES_1.2.0.md) for verification status. Other apps and websites—including Claude, Gemini, Grok, WorkBuddy, DeepSeek, Kimi, and HuggingChat—**still need separate validation**. Keep mode and removal mode need separate tests. A preset or allowlist entry is not a compatibility guarantee. Terminal CLI tools are outside the preset coverage. [Compatibility details →](docs/COMPATIBILITY.md)

<details>
<summary>Before you install: permissions and limitations</summary>

- Packages are **ad-hoc signed, not Apple notarized**. If macOS blocks opening, follow [Apple’s instructions](https://support.apple.com/102445). Accessibility access requires your manual approval.
- The project targets **macOS 13+**; the minimum OS and **Intel runtime have not been tested on physical devices**.
- Editors must expose readable Accessibility text and caret information. The caret must be at the end, with no selection.
- Optional keyword removal also requires editing support. If verification fails, sending stops; an interrupted removal may leave the draft or selection changed. Check the target input before trying again.
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
