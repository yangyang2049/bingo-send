# Bingo Send 1.2.0

[English](RELEASE_NOTES_1.2.0.md) | [简体中文](RELEASE_NOTES_1.2.0.zh-CN.md)

This update adds opt-in app and website setup presets, a menu of common keywords, optional final-keyword removal, a black-and-white app icon, and an English/Simplified Chinese interface. By default, a new message ends with your one active keyword, the text settles, and Bingo Send triggers the configured shortcut while preserving the entire message and keyword. Removal is a separate opt-in mode.

## Changes

- Add 13 setup presets in one searchable list: Codex / ChatGPT, Claude / Claude Code, Gemini, Grok, Cursor, HuggingChat, DeepSeek / DeepSeek Harness, ZCode, Kimi, Kimi Code, WorkBuddy, Qoder CN, and TRAE CN. They fill in scope settings; they are not compatibility certifications. Known installed native apps are offered directly, and other desktop apps can be selected manually. Terminal CLI tools are outside this preset coverage.
- Let web presets use a browser you select from installed browsers, preview and merge allowed domains without replacing existing entries, and enable that browser rule. All allowed sites in one browser share its configured send shortcut.
- Follow the system’s preferred language with English or Simplified Chinese UI; use English for other languages.
- Choose one active keyword from Bingo, Submit, Send, 发送, 提交, 完成, 确认, 确定, or enter a custom keyword. Keyword matching remains case-insensitive.
- Add **Remove final keyword before sending**, off by default. It removes only the matched final keyword and punctuation or whitespace after it; earlier body text, punctuation, and keyword occurrences are preserved. The app verifies the edited draft and context before sending. If support or verification fails, it stops and pauses without sending; an interrupted edit may leave a changed draft or selection for the user to inspect, without automatic restoration over newer input.
- Start fresh installations with every app disabled, detection-only mode on, and sending paused. Existing saved preferences are preserved without migration; every launch still starts paused.
- Use a black rounded-square icon with a white paper plane.
- Render icons into an `NSBitmapImageRep` with exact physical pixel dimensions instead of using `NSImage.lockFocus()`, whose backing scale can produce incorrectly sized PNGs on Retina displays.
- Check the filenames and physical dimensions of all 10 standard macOS icon variants: 16, 32, 128, 256, and 512 points, each at 1× and 2×. The build also converts the generated ICNS back to an iconset and validates all variants again before signing.
- Refuse to package a release app containing local-only test tooling. The local test editor is not part of the app or repository.
- Add an app-specific Accessibility reset fallback for stale permission entries after replacing an ad-hoc-signed build. See [permission troubleshooting](USER_GUIDE.md#troubleshooting).

## Installation and permission

Requires macOS 13 or later. Download `BingoSend-1.2.0-macOS-universal.dmg`, drag Bingo Send into Applications, and open it. The package includes Apple Silicon and Intel architectures; Intel hardware and the minimum macOS version still need physical-device testing.

This package is ad-hoc signed and **not Apple notarized**. If macOS blocks opening, follow [Apple's normal System Settings procedure](https://support.apple.com/102445). Accessibility permission must be enabled manually for the current installed app. Replacing the app may leave a stale authorization entry; follow the user guide if the system switch is on but the app reports that it is unauthorized.

Each launch starts paused. Confirm Accessibility authorization, opt in to your app or browser scope, choose one keyword, and try detection-only mode with a new message before enabling actual sending. Optional removal defaults to off for new installations and older saved configurations without that setting. Test it separately after keep mode works; detection-only mode never edits. No Codex installation or Skill is required. See the [user guide](USER_GUIDE.md#app-and-website-presets) for the preset list and controls.

## Verification status and limitations

Version 1.2.0 (build 10) passed 53 unit tests (45 core and 8 app tests), a universal arm64/x86_64 build, all 10 icon-variant checks, strict ad-hoc signature verification, and ZIP/DMG packaging checks. The app extracted from the ZIP and the app on the mounted DMG matched the build; no local-only test editor was included. The installed app came from the verified ZIP.

The installed English interface was checked in Settings, the unified preset list, keyword-removal preview, the web preset setup dialog, and Help. Simplified Chinese Settings and the unified list were checked using the system language preference. The actual automatic-send results below belong to build 9, before the UI-only localization changes; those send tests have not been repeated on build 10.

The earlier 1.2.0 build 9 passed 47 unit tests, the universal build, ad-hoc signature integrity verification, and packaging checks. Both optional removal and default keep mode passed actual send tests in an independent, local-only WKWebView editor, with automatic sending confirmed by the user. The removal test recorded one send and cleared the input; the earlier Bingo remained and the final keyword was removed. The following keep-mode test increased the send count to two, cleared the input, and preserved the complete `保留模式测试 Bingo。`, including the keyword and final Chinese period. The local test editor is not distributed with the app or repository.

Version 1.1.0 keep mode was tested successfully with a local WKWebView editor and the user's Codex app. The new local removal test does not establish removal support in Codex or another AI app. The 13 setup presets do not expand the set of verified AI editors. Other apps and websites still require individual validation; their input fields must expose readable text and caret information through Accessibility, and removal additionally needs editing support. See the [compatibility record](COMPATIBILITY.md).

Bingo Send does not record audio, make network requests, or save chat text. It cannot stop your input method's recording session.
