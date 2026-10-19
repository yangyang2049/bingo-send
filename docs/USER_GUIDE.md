English | [简体中文](USER_GUIDE.zh-CN.md)

# User Guide

Keep using Doubao or another input method. Say your chosen keyword, **Bingo** by default, at the end of your message. Once the text appears in the input field and remains stable, Bingo Send detects the keyword, reads back and verifies the current draft, and triggers the target app’s send shortcut. **By default, the entire message and keyword are sent unchanged.** Optional keyword removal is described below.

For example, in default keep mode: enter `Please check this page, Bingo.` → send the complete `Please check this page, Bingo.`

Requires macOS 13 or later. Building from source requires Swift 5.9 or later; there are no third-party dependencies. Before downloading an installer, check the architecture and signing/notarization status listed in its Release.

## Quick start

The app’s current interface uses Chinese labels; their English meanings are given below. macOS permission labels and locations may vary with the system language and version.

1. Move `Bingo Send.app` to its intended long-term location, such as Applications, and open it. If macOS blocks the first launch, use the standard macOS process to allow it in System Settings.
2. Click **Authorize…** (`去授权…`) in Bingo Send, then manually enable Bingo Send in **System Settings → Privacy & Security → Accessibility**. This permission lets the app read the focused input field and caret state, and issue the send keystroke.
3. Open **App presets** (`应用预设`), or **Add from common presets…** (`从常用预设添加…`) under **Enabled apps** (`启用范围`). Choose an installed desktop app or a website's browser setup, and check its send shortcut: `Return`, `⌘ Return`, or `⌃ Return`. You can also use **Add app manually…** (`手动添加应用…`) and select a `.app`.
4. For a web-based AI service, choose an installed browser in the preset dialog and review the merged allowed domains before adding it. If configuring manually, enable **Restrict by website domain** (`按网页域名限制`) and enter domains one per line, without `https://` or a path. Examples such as `chat.deepseek.com` and `huggingface.co` are setup suggestions, not verified compatibility claims.
5. In settings, use **Choose a common keyword** (`选择常用口令`) or enter a custom **Final keyword** (`句尾口令`). Leave **Detect only, do not send** (`只检测，不发送`) on, then turn on **Enable keyword sending** (`启用口令发送`). Switch to the target input field, enter a **new** test message such as `Hello, Bingo.` if Bingo is selected, and leave the caret at the end. A successful detection produces a sound and a status entry; the text remains unchanged.
6. Once detection works, leave **Remove final keyword before sending** (`发送前移除句尾口令`) off, turn off **Detect only, do not send**, enter another unimportant new message, and check whether the target app actually sends it. Test each app or website separately. If you want removal mode, enable and test it separately afterward.

Fresh installations start with every app disabled and detection-only mode on. Presets are added only when you choose them. Existing saved keywords, app rules, detection-only settings, and shortcuts are retained without migration or replacement. The app starts paused every time it launches. The paper-plane icon in the menu bar lets you open settings, enable, pause, or quit it.

## App and website presets

The **App presets** tab includes 13 entries, searchable by name and filterable by the **International** (`国外`) or **China** (`国内`) groups. They help fill in app and website scope; they do not certify editor compatibility or install other software.

| Preset | Available setup |
| --- | --- |
| Codex / ChatGPT | Installed Codex desktop app; `chatgpt.com` |
| Claude / Claude Code | `claude.ai`; manually select a desktop app |
| Gemini | `gemini.google.com` |
| Grok | `grok.com` |
| Cursor | `cursor.com` cloud agent; manually select a desktop app |
| HuggingChat | `huggingface.co` for HuggingChat |
| DeepSeek / DeepSeek Harness | Installed Harness desktop app; `chat.deepseek.com` |
| ZCode（智谱） | Manually select a desktop app |
| Kimi | `www.kimi.com`, `www.kimi.ai`; manually select a desktop app |
| Kimi Code | Manually select a desktop app |
| WorkBuddy | Installed desktop app |
| Qoder CN | Installed China-edition desktop app; manually select other editions |
| TRAE CN | Installed China-edition desktop app; manually select other editions |

For native presets, **Add…** (`添加…`) lists matching installed apps when their bundle identifiers are known. Choose a desktop app, review its enabled state and shortcut in the configuration sheet, then click **Save** (`保存`). If no installed app is found, use **Choose desktop app manually…** (`手动选择桌面应用…`). A preset does not download the app. Terminal versions of Claude Code, Kimi Code, or other CLI tools are outside this preset coverage.

For web presets, choose **Web · choose browser…** (`网页版 · 选择浏览器…`), select an installed browser, review the new hosts and combined allowed list, then click **Add to enabled apps** (`添加到启用范围`). The preset adds and deduplicates its domains while preserving existing entries, turns on domain restriction, and enables that browser rule. You choose a send shortcut in the same dialog; all allowed sites in that browser share it. Adding another preset to the same browser keeps existing domains but can change that shared shortcut. Domain checks operate on hosts and subdomains, not individual URL paths. If no browser is detected, install one or add it manually in settings.

## Supported input fields

Native apps, Electron apps, and browser websites can be added to the list, but not every input field will work. WorkBuddy, DeepSeek, Hugging Face, and other agents need individual verification.

The input field must expose readable text (`AXValue`) and caret/selection state through macOS Accessibility so the app can confirm that the caret is at the end. Default keep mode requires no writable Accessibility attributes and leaves the draft and selection unchanged. Optional removal additionally needs editor support for Accessibility editing; keep-mode success does not establish removal support. By default, only multiline text fields are recognized. If a chat input really is a single-line control, enable **Allow single-line input fields** (`允许单行输入框`) in that app’s configuration. Custom-drawn editors, some web editors, and browser windows whose current domain cannot be determined may not work.

The tool processes only the currently focused input field in an enabled app. Recognized browsers require an allowed domain or its subdomain to match. For an unrecognized browser, manually enable **Restrict by website domain**. Switching apps, input fields, settings, or caret positions cancels a pending trigger. An existing draft is treated only as the initial baseline when you enter an input field; it will not be sent immediately. Enter new text to trigger detection.

When a speech-input overlay briefly takes focus, the app cancels the pending send and keeps the previous input state in memory for up to 3 minutes. After you return to the same input field, only newly committed or edited text is checked for the keyword again. After more than 3 minutes away, a new baseline is established.

## Keyword and Doubao input

- The default keyword is `Bingo`. Choose `Bingo`, `Submit`, `Send`, `发送`, `提交`, `完成`, `确认`, or `确定` from **Choose a common keyword**, or type a custom keyword containing letters or numbers, up to 40 characters, with no final punctuation or line breaks. Only one keyword is active at a time; selecting a suggestion replaces the active keyword, and `BINGO` matches `Bingo` without needing a second entry.
- Only the complete keyword at the end of the message matches. English matching is case-insensitive, and trailing whitespace and punctuation are allowed. A message containing only the keyword does not trigger sending.
- The caret must be at the end with no selected text. The default stability delay is 1 second, adjustable from 0.5 to 3 seconds. Increase it if text arrives incrementally and slowly.
- Before sending, the tool reads back the entire draft, focused input field, and end-of-text caret. In default keep mode, after confirming the content is unchanged, it issues the configured shortcut to the original target app; the keyword, punctuation, and all other text remain unchanged. Optional removal verifies the edited result before issuing the shortcut.

Doubao must first commit the text to the target input field. Bingo Send **cannot stop Doubao’s recording**, and text alone cannot tell it whether recording has ended. If Doubao commits text only after you manually stop recording, the keyword can trigger only after that. If it commits continuously, continuing to speak after the keyword may cause an early send. Test this behavior with the stability delay.

## Optional keyword removal

**Remove final keyword before sending** (`发送前移除句尾口令`) is off by default. An older saved configuration without this setting also defaults to off. Leave it off to keep the complete draft and keyword unchanged.

If you turn it on, the app removes only the matched final keyword and all punctuation or whitespace after that keyword. Earlier body text, punctuation, whitespace, and keyword occurrences in the middle are preserved. For example, `检查 Bingo 的用法，Bingo。` becomes `检查 Bingo 的用法，`; the earlier Bingo and the comma before the final keyword remain.

Removal changes the focused draft and may change its selection. The app checks the original draft and context, performs the edit only if the editor supports it, then reads back and verifies the remaining text, focus, caret, and page context before issuing the send shortcut. Detection-only mode never edits, even when this toggle is on, so test actual removal with an unimportant new message after detection succeeds.

If the editor cannot support or verify the edit, or the context changes, the app stops and pauses without sending. An interruption after an edit can leave the draft or selection changed. Inspect the original input before retrying; the app does not automatically restore old text over potentially newer input. Verify keep mode and removal mode independently for each app or website. Neither mode uses the clipboard.

## Troubleshooting

**The keyword was detected, but the message was not sent.**

First check that **Detect only, do not send** is off. Then check the app’s send shortcut, the chat input’s state, and the browser domain settings. A status saying that the send keystroke was issued means only that the keystroke was issued. Network conditions, the send button’s state, or shortcut configuration can still prevent the target app from sending. Check the actual result in the target app.

**Where can I see why an action was canceled or failed?**

**Latest result** (`最近一次结果`) at the top of the window preserves the latest action result. Failure messages identify causes such as a change in focus, draft text, or caret position. They do not include the draft text.

After a failure, pause the tool and check the original draft before following the status guidance. If removal was enabled, the draft or selection may already have changed. If the tool cannot confirm the expected draft, focus, and caret, it will not send. Do not treat a failure status as proof that a message was sent.

**The keyword is never detected.**

Check Accessibility authorization, the main switch, and the target app’s enabled state. Then enter a new message in the target input field. Let the text appear, clear any selection, and leave the caret at the end. Check the current status and **Latest result** at the top. If the input field does not expose the required Accessibility capabilities, this version stops processing that field.

**The system Accessibility switch is on, but Bingo Send still says it is unauthorized.**

Rebuilding or replacing an ad-hoc-signed app can change its local signature. An old entry may still look enabled in System Settings while the current app is unauthorized.

1. Quit Bingo Send completely.
2. In **System Settings → Privacy & Security → Accessibility**, remove the old Bingo Send entry, then add and enable the current `Bingo Send.app` from its long-term location, such as `/Applications/Bingo Send.app`.
3. Reopen Bingo Send and check its authorization status.

If the old entry cannot be removed, or the old signature still appears to be in use, you can optionally reset only Bingo Send's Accessibility grant. Quit the app first, then run this command in Terminal:

```sh
tccutil reset Accessibility io.local.bingosend
```

This revokes Bingo Send's Accessibility permission, so it must be granted again; it does not reset other apps' grants or erase the saved keyword and app list. Reopen Bingo Send, click **Authorize…** (`去授权…`), then manually enable the current app in the system Accessibility list. Every launch starts paused; turn on **Enable keyword sending** only after authorization is confirmed.

**Does success in “Try keyword” mean the target app works?**

**Try keyword** (`试用口令`) only checks keyword matching and shows a local preview. It does not read or edit other apps or send messages. Use detection-only mode to verify that the target input can be read, then separately verify actual keep-mode or removal-mode sending in that app.

**Does Bingo Send record audio, connect to the internet, or save chats?**

Bingo Send does not record audio, connect to the internet, or save draft text. At runtime, it briefly processes text from allowed input fields in memory only. Settings such as the app list, keyword, and delay are stored locally in `UserDefaults` under `io.local.bingosend`. Your chosen input method remains responsible for speech recognition and its data processing.

## Building and verification

See the project [README](../README.md) for build instructions and the [compatibility record](COMPATIBILITY.md) for verified environments.

## Stopping and uninstalling

To pause, turn off **Enable keyword sending** from the menu bar. To stop completely, choose **Quit Bingo Send** (`退出 Bingo Send`). Closing only the settings window leaves the menu bar app running.

To uninstall, quit the app and delete `Bingo Send.app`. You can also remove its system Accessibility entry. To clear the saved keyword and app list as well, quit first, then run:

```sh
defaults delete io.local.bingosend
```

The app does not add a login item. After the app is deleted, it will not continue running.
