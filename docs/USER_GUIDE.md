English | [简体中文](USER_GUIDE.zh-CN.md)

# User Guide

Keep using Doubao or another input method. Say **Bingo** at the end of your message. Once the text appears in the input field and remains stable, Bingo Send detects the keyword, reads back and verifies the current draft, and triggers the target app’s send shortcut. **The entire message, including Bingo, is sent unchanged.**

For example: enter `Please check this page, Bingo.` → send the complete `Please check this page, Bingo.`

Requires macOS 13 or later. Building from source requires Swift 5.9 or later; there are no third-party dependencies. Before downloading an installer, check the architecture and signing/notarization status listed in its Release.

## Quick start

The app’s current interface uses Chinese labels; their English meanings are given below. macOS permission labels and locations may vary with the system language and version.

1. Move `Bingo Send.app` to its intended long-term location, such as Applications, and open it. If macOS blocks the first launch, use the standard macOS process to allow it in System Settings.
2. Click **Authorize…** (`去授权…`) in Bingo Send, then manually enable Bingo Send in **System Settings → Privacy & Security → Accessibility**. This permission lets the app read the focused input field and caret state, and issue the send keystroke.
3. Enable the target app under **Enabled apps** (`启用范围`). To add another app, use **Add app or browser…** (`添加应用或浏览器…`) and select its `.app`. Use the configuration button beside the app to check its send shortcut: `Return`, `⌘ Return`, or `⌃ Return`.
4. For a web-based AI service, add your browser, make sure **Restrict by website domain** (`按网页域名限制`) is enabled, and enter the allowed website domains, one per line. Examples: `chat.deepseek.com` and `huggingface.co`. Do not include `https://` or a path. These are configuration examples, not verified compatibility claims.
5. Leave **Detect only, do not send** (`只检测，不发送`) on, then turn on **Enable keyword sending** (`启用口令发送`). Switch to the target input field, enter a **new** test message such as `Hello, Bingo.`, and leave the caret at the end. A successful detection produces a sound and a status entry; the text remains unchanged.
6. Once detection works, turn off **Detect only, do not send**, enter another unimportant new message, and check whether the target app actually sends it. Test each app or website separately.

Detection-only mode is the default on first use. The app starts paused every time it launches. The paper-plane icon in the menu bar lets you open settings, enable, pause, or quit it.

## Supported input fields

Native apps, Electron apps, and browser websites can be added to the list, but not every input field will work. WorkBuddy, DeepSeek, Hugging Face, and other agents need individual verification.

The input field must expose readable text (`AXValue`) and caret/selection state through macOS Accessibility so the app can confirm that the caret is at the end. No writable Accessibility attributes are required. Bingo Send does not select text, delete text, or modify the draft. By default, only multiline text fields are recognized. If a chat input really is a single-line control, enable **Allow single-line input fields** (`允许单行输入框`) in that app’s configuration. Custom-drawn editors, some web editors, and browser windows whose current domain cannot be determined may not work.

The tool processes only the currently focused input field in an enabled app. Recognized browsers require an allowed domain or its subdomain to match. For an unrecognized browser, manually enable **Restrict by website domain**. Switching apps, input fields, settings, or caret positions cancels a pending trigger. An existing draft is treated only as the initial baseline when you enter an input field; it will not be sent immediately. Enter new text to trigger detection.

When a speech-input overlay briefly takes focus, the app cancels the pending send and keeps the previous input state in memory for up to 3 minutes. After you return to the same input field, only newly committed or edited text is checked for the keyword again. After more than 3 minutes away, a new baseline is established.

## Keyword and Doubao input

- The default keyword is `Bingo`. You can change it to another keyword containing letters or numbers, up to 40 characters.
- Only the complete keyword at the end of the message matches. English matching is case-insensitive, and trailing whitespace and punctuation are allowed. A message containing only the keyword does not trigger sending.
- The caret must be at the end with no selected text. The default stability delay is 1 second, adjustable from 0.5 to 3 seconds. Increase it if text arrives incrementally and slowly.
- Before sending, the tool reads back the entire draft, focused input field, and end-of-text caret. After confirming that the content is unchanged, it issues the configured send shortcut to the original target app. The keyword, punctuation, and all other text remain unchanged.

Doubao must first commit the text to the target input field. Bingo Send **cannot stop Doubao’s recording**, and text alone cannot tell it whether recording has ended. If Doubao commits text only after you manually stop recording, the keyword can trigger only after that. If it commits continuously, continuing to speak after the keyword may cause an early send. Test this behavior with the stability delay.

## Troubleshooting

**The keyword was detected, but the message was not sent.**

First check that **Detect only, do not send** is off. Then check the app’s send shortcut, the chat input’s state, and the browser domain settings. A status saying that the send keystroke was issued means only that the keystroke was issued. Network conditions, the send button’s state, or shortcut configuration can still prevent the target app from sending. Check the actual result in the target app.

**Where can I see why an action was canceled or failed?**

**Latest result** (`最近一次结果`) at the top of the window preserves the latest action result. Failure messages identify causes such as a change in focus, draft text, or caret position. They do not include the draft text.

After a failure, pause the tool and check the original draft before following the status guidance. If the tool cannot confirm the complete draft, focus, and caret are still as expected, it will not send. Do not treat a failure status as proof that a message was sent.

**The keyword is never detected.**

Check Accessibility authorization, the main switch, and the target app’s enabled state. Then enter a new message in the target input field. Let the text appear, clear any selection, and leave the caret at the end. Check the current status and **Latest result** at the top. If the input field does not expose the required Accessibility capabilities, this version stops processing that field.

**The system Accessibility switch is on, but Bingo Send still says it is unauthorized.**

Rebuilding or replacing the app changes its local signature. An old entry may still look enabled in System Settings while the new app is unauthorized. Quit Bingo Send, manually remove the old Bingo Send entry from the system Accessibility list, add the current `Bingo Send.app`, and enable its permission. Then reopen the tool. Add the current version from its long-term installation location, such as Applications. This does not require clearing your keyword or app list.

**Does success in “Try keyword” mean the target app works?**

**Try keyword** (`试用口令`) only checks keyword matching and previews the complete message, including Bingo. It does not read other apps or send messages. Use detection-only mode to verify that the target input can be read, then separately verify actual sending in that app.

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
