English | [简体中文](PRIVACY.zh-CN.md)

# Privacy

Bingo Send does not record audio, call speech-recognition services, make network requests, send telemetry, or write draft text to files or UserDefaults. Data processing by your speech input method, target app, or GitHub itself is outside the scope of this tool.

## Runtime processing

When enabled, the app checks the foreground app approximately every 0.25 seconds. Only in enabled apps does it read the currently focused input field’s text, caret/selection state, and control availability. For browser pages, it may also read the page URL to establish the current page context. Recognized browsers require an allowed domain match. If the URL cannot be determined or does not match, processing stops before the draft is read. For unrecognized browsers, manually enable **Restrict by website domain** (`按网页域名限制`).

The complete text and page context are used only in memory for keyword matching, duplicate prevention, and verification before sending. When focus briefly moves away, the previous input state may be retained for up to 3 minutes to accommodate speech-input overlays. It is not restored from disk after the app stops or restarts. The Accessibility permission granted by macOS is broader than the app’s internal allowlist; this project’s code enforces the allowlist.

To send, the app issues Return, Command-Return, or Control-Return to the original target app. The default keep mode does not rewrite the draft, delete the keyword, or change the selection. The optional **Remove final keyword before sending** (`发送前移除句尾口令`) setting is off by default. If enabled, it uses Accessibility editing to remove only the matched final keyword and the punctuation or whitespace after it. Earlier body text, punctuation, and keyword occurrences in the middle remain unchanged. This mode can change the focused draft and its selection; it verifies the draft, focus, caret, and page context and reads back the edited result before sending. Neither mode reads or writes the clipboard, and detection-only mode does not edit or send.

If the editor cannot support or verify the edit, or the context changes, removal stops and no send shortcut is issued. An interruption after an edit may leave the draft or selection changed. The app pauses for the user to inspect the original input; it does not automatically restore text over potentially newer input.

## Locally stored settings

The UserDefaults domain is `io.local.bingosend`, with the key `bingoPreferencesV1`. It stores configuration such as your active keyword, delay, detection mode, optional keyword-removal preference, app names and identifiers, send shortcuts, and allowed website domains. The keyword itself is saved as a user setting; chat drafts are not saved. Upgrading retains existing saved settings, and an older configuration without the removal preference defaults to keep mode.

Window status messages show only the time, the app name from configuration, and fixed error messages. Some errors include numeric ranges or system error codes. They do not include chat text, page URLs, or window titles. Status messages are not written to disk as a history log.

## Permissions and removal

Accessibility is used to read input fields and issue keystrokes, and to edit the focused draft only when optional keyword removal is enabled. The app does not obtain permission automatically, modify the system authorization database, or request microphone or screen-recording permission. The names and locations of macOS permission controls may vary with the system language and version.

Quit the app to stop detection. To uninstall, delete the app and remove its Accessibility authorization in System Settings. To clear local settings, quit first, then run:

```sh
defaults delete io.local.bingosend
```

When reporting an issue, provide only a non-sensitive test sentence, version information, and status messages. Do not include real conversations, credentials, UserDefaults exports, or browsing history.
