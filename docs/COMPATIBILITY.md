English | [简体中文](COMPATIBILITY.zh-CN.md)

# Compatibility Record

Recorded on 2026-10-19. The project’s minimum deployment target is macOS 13. Success on one version does not establish compatibility with every OS version, similarly named product, or input field.

| Environment | Result | What was verified |
| --- | --- | --- |
| Codex desktop, `com.openai.codex`, Apple Silicon | Passed a user test | Version 1.1.0; Doubao input; Bingo at the end of newly entered text; Return; the complete message and keyword were sent automatically without changes |
| Independent local WKWebView test editor, Apple Silicon | Passed | Version 1.1.0; two complete messages containing Chinese, emoji, English, and the keyword were submitted automatically |
| Version 1.1.1 | 28 tests, native/universal builds, signing, and packaging checks passed | Both architectures target macOS 13.0 or later; apps extracted from the ZIP and mounted DMG matched the build; a new installation defaults Codex to Return; the send implementation is unchanged from 1.1.0 |
| WorkBuddy | Unverified | App identifier, AX text and caret access, and send shortcut need individual verification |
| DeepSeek website | Unverified | `chat.deepseek.com` is a configuration example only |
| Hugging Face website | Unverified | `huggingface.co` is a configuration example only |
| Safari, Chrome, Edge, and other browsers | Actual sending unverified | Built-in browser identifiers do not establish compatibility with every web editor |
| Intel Mac; minimum supported OS, macOS 13 | Device verification pending | Including an x86_64 binary does not mean it has passed regression testing on an Intel Mac |

## Verifying a new app

1. Add and enable the target `.app` in settings. Check whether it sends with Return, Command-Return, or Control-Return.
2. Configure allowed domains for browsers. For an unrecognized browser, manually enable **Restrict by website domain** (`按网页域名限制`).
3. Enable the main switch. First use **Detect only, do not send** (`只检测，不发送`) to verify newly entered text, with the caret at the end and no text selected.
4. Turn off detection-only mode. Use another non-sensitive new test message to check actual sending, and verify the entire received message including Bingo.
5. In an Issue, report macOS, chip, Bingo Send and target app versions, the send shortcut, and the fixed status message. Include which speech input method you use and whether it commits text continuously. Real conversations are not needed.

The app requires readable `AXValue` and `AXSelectedTextRange` attributes. A draft already present when entering an input field is treated only as a baseline and is not sent immediately. If the control, caret, or restricted page URL cannot be read, the app stops processing that field instead of guessing.
