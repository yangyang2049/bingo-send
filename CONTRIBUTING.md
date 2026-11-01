# Contributing to Bingo Send

**English** · [简体中文](CONTRIBUTING.zh-CN.md)

Compatibility reports, bug fixes, documentation improvements, and Pull Requests are welcome. Small changes can be submitted directly. For changes to permissions, draft handling, networking, or trigger rules, explain the use case first.

## Local checks

```sh
swift test
./build.sh
```

If you change packaging scripts, also run `./scripts/package-release.sh` and inspect the ZIP, DMG, signature, and checksum files. Accessibility or sending-flow changes require an actual send test in a separate local test editor. Unit tests cannot establish compatibility with third-party apps.

## Behavior to preserve

- Process only apps explicitly enabled by the user. When domain restrictions are enabled, validate the page before reading the draft.
- Default to detection-only mode and start paused on every launch. Check focus, the full draft, caret, and selection before sending.
- Default keep mode preserves the full draft, keyword, and selection. Optional removal may edit only the verified final keyword suffix; recheck focus, text, and selection before every edit and before sending. Never use the clipboard or overwrite the entire draft. If interrupted, stop and ask the user to inspect the draft; do not roll back over newer input.
- Do not log drafts, page URLs, or window titles. Do not add telemetry or upload input content.
- Stop when editor state or context cannot be read or confirmed. Do not loosen checks to work around a failure.

Continued dictation before deletion may abandon the current attempt without
disabling Auto send. After suffix selection, this requires verified newer text,
an intact original body prefix and an unselected end caret in the same context.
Once Backspace has been attempted, an uncertain result stops that transaction,
while keeping the selected run mode. Reject both the failed original draft and
its possible delayed deletion result until new text is entered. Never retry a
deletion or restore an older draft. See the local
[1.3.4 verification record](docs/VERIFICATION_1.3.4.md).

Rebuilding changes an ad-hoc signature and may require removing the old Accessibility entry and adding the current app. Test a separate copy instead of replacing the version currently in use.

Follow the [compatibility reporting guide](docs/COMPATIBILITY.md) when submitting results. Redact chats, account information, and personal details from screenshots. Do not upload certificates, keys, signing credentials, or local settings.
