English | [简体中文](COMPATIBILITY.zh-CN.md)

# Compatibility Record

Recorded on 2026-10-19. The project’s minimum deployment target is macOS 13. Success on one version does not establish compatibility with every OS version, similarly named product, or input field.

| Environment | Result | What was verified |
| --- | --- | --- |
| Codex desktop, `com.openai.codex`, Apple Silicon | Passed a user test in keep mode | Version 1.1.0; Doubao input; Bingo at the end of newly entered text; Return; the complete message and keyword were sent automatically without changes |
| Independent local WKWebView test editor, Apple Silicon | Passed | Version 1.1.0; two complete messages containing Chinese, emoji, English, and the keyword were submitted automatically |
| Version 1.1.1 | 28 tests, native/universal builds, signing, and packaging checks passed | Both architectures target macOS 13.0 or later; apps extracted from the ZIP and mounted DMG matched the build; a new installation defaults Codex to Return; the send implementation is unchanged from 1.1.0 |
| Version 1.2.0, build 10 | 53 tests, universal build, icon/signature checks, and packaging checks passed | 45 core and 8 app tests; arm64/x86_64; 10 icon variants; ZIP-extracted and mounted-DMG apps matched the build and excluded local-only test tooling |
| Installed build 10, Apple Silicon | English and Simplified Chinese UI checked | Installed from the verified ZIP; English Settings, unified preset list, removal preview, web preset dialog, and Help; Chinese Settings and unified list followed the system language |
| Version 1.2.0, build 9 | 47 unit tests, universal build, signature integrity, and packaging checks passed | Automated/build verification; actual local runtime results are listed separately below |
| Independent local-only WKWebView test editor, Apple Silicon | Keep mode and optional removal passed in 1.2.0, build 9 | User confirmed automatic sending in both tests; removal retained an earlier Bingo and stripped the final keyword, then keep mode sent the complete `保留模式测试 Bingo。`; counter reached 2 and input was empty; editor is not included in the app or repository |
| WorkBuddy | Unverified | A setup preset includes the installed app's identifier; AX text and caret access and the send shortcut still need individual verification |
| DeepSeek website | Unverified | `chat.deepseek.com` is a configuration example only |
| Hugging Face website | Unverified | `huggingface.co` is a configuration example only |
| Safari, Chrome, Edge, and other browsers | Actual sending unverified | Built-in browser identifiers do not establish compatibility with every web editor |
| Intel Mac; minimum supported OS, macOS 13 | Device verification pending | Including an x86_64 binary does not mean it has passed regression testing on an Intel Mac |

Actual automatic sending in both modes was verified on build 9, before the UI-only localization changes. Those send tests have not been repeated on build 10; its automated, packaging, and interface results are recorded separately.

## Keep mode and removal mode

Historical keep-mode tests verify only reading a draft and issuing the send shortcut without editing it. Both default keep mode and optional **Remove final keyword before sending** passed actual 1.2.0 (build 9) send tests in the local-only WKWebView editor listed above. This does not establish removal support in Codex or any other AI app. Removal needs Accessibility editing support and must be tested separately in each editor. Detection-only mode does not exercise editing.

Removal is off by default, including when an older saved configuration has no removal setting. It removes only the matched final keyword and following punctuation or whitespace, then verifies the resulting draft and context before sending. If the editor is unsupported or verification fails, the app pauses without sending. An interruption after an edit can leave the draft or selection changed; the user must inspect the input before retrying. Old text is not restored automatically over potentially newer input.

## Setup presets are not test results

Version 1.2.0 offers 13 opt-in presets: Codex / ChatGPT, Claude / Claude Code, Gemini, Grok, Cursor, HuggingChat, DeepSeek / DeepSeek Harness, ZCode, Kimi, Kimi Code, WorkBuddy, Qoder CN, and TRAE CN. These fill in known native-app identifiers or suggested editor hosts; see the [preset setup table](USER_GUIDE.md#app-and-website-presets). Known product hosts and installed app identifiers establish configuration targets, not successful Accessibility reads or sending.

Only the historical Codex desktop result listed above is verified for a real AI app. Other native apps and all preset websites still need separate tests. The Claude Code and Kimi Code names do not include compatibility with terminal CLI editors, and a verified native-app identifier does not cover other editions automatically.

Web presets let the user choose an installed browser and add domains to its existing allowlist. All allowed sites in one browser share its send shortcut; domain checks apply to hosts and subdomains, not individual URL paths. Test each site in the chosen browser, even if another site in that browser works. Fresh installations enable no apps until the user chooses a setup; existing saved settings are retained.

## Verifying a new app

1. Choose an app or website preset, or add and enable the target `.app` manually. Check whether it sends with Return, Command-Return, or Control-Return.
2. For web presets, choose an installed browser and review the merged allowed domains and shared send shortcut. For an unrecognized browser added manually, enable **Restrict by website domain**.
3. Enable the main switch. First use **Detect only, do not send** to verify newly entered text, with the caret at the end and no text selected.
4. With optional removal off, turn off detection-only mode. Use another non-sensitive new test message to check actual sending, and verify the entire received message including the active keyword. If you want removal, enable it and run another separate test: confirm that only the final keyword and following delimiters were removed, while the earlier body and punctuation are preserved.
5. In an Issue, report macOS, chip, Bingo Send and target app versions, the send shortcut, and the fixed status message. Include which speech input method you use and whether it commits text continuously. Real conversations are not needed.

The app requires readable `AXValue` and `AXSelectedTextRange` attributes. A draft already present when entering an input field is treated only as a baseline and is not sent immediately. If the control, caret, or restricted page URL cannot be read, the app stops processing that field instead of guessing.
