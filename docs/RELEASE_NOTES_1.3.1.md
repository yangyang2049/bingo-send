# Bingo Send 1.3.1 (build 12) preview

2026-10-30. Includes the unreleased 1.3.0 multi-keyword feature.

- Configure up to 3 final keywords with English, Chinese, or mixed quick sets. Existing keywords are preserved.
- Replace the enable/detect-only switches with one choice: **Paused / Test detection / Auto send** in Settings and the menu bar.
- Show the effective mode and permission, keyword, or app-scope blocks. Pause is always available.
- Detection tests play a sound without editing or sending. Removal is inactive while testing.
- The local preview follows detection mode and clears stale results when its inputs or settings change. It does not certify editor compatibility.
- Include the app name in send-failure results. Explain that an unavailable model or disabled send button in the target app can prevent sending.
- Preserve settings and start paused on every launch. Enter new text after changing mode or settings.

## Manual checks before release

After upgrading, verify Accessibility permission yourself if macOS requests it. Confirm that the target app has an available model and a working manual send button. Use harmless new messages, with the caret at the end and no selection.

1. Verify saved keywords, app rules, delay, shortcut, and removal settings; the app starts paused.
2. Choose Test detection: the sound occurs, the complete draft remains, and no message is sent.
3. Choose Auto send with removal off: verify one actual message including the final keyword.
4. Enable removal and enter a new message with an earlier keyword and a final one: only the final suffix is removed; verify one actual send.
5. Repeat detection, keep, and removal tests separately in Codex and DeepSeek Harness.
6. For ZCode, first restore its own ability to send manually; unavailable models or a disabled send button block a meaningful send test.
7. Pause and enter new text: no detection sound, edits, or send.
8. Check a preview, then change the sample, keywords, removal, or mode: the old result clears. Detection previews never remove the suffix.
9. Quit and relaunch: paused, settings retained, no processing of existing drafts.

The user's successful Codex and DeepSeek reports concerned 1.3.0, not this preview. Version 1.3.1 per-app send regression remains a user test. A posted shortcut is not proof of delivery. No target-app restrictions are bypassed and no automatic resend has been added.

Packages are ad-hoc signed and not Apple notarized. Universal packaging does not establish physical Intel or minimum-macOS runtime support. See the [Chinese checklist](RELEASE_NOTES_1.3.1.zh-CN.md) for detailed expected results.
