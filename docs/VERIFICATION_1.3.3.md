# 1.3.3 build 14 local fix — 2026-11-01

Historical snapshot: superseded by the user's requested failure policy and clean
installation in [1.3.4](VERIFICATION_1.3.4.md). The global-pause behavior below is
not the current behavior.

## Observed failure

The user reproduced the interruption by speaking the Chinese send keyword twice
while dictation continued. The installed 1.3.2 UI recorded an edit-confirmation
timeout: expected selection `15:0`, actual `15:3`, text state `original`. This
establishes that deletion had not been acknowledged; it does not establish whether
the editor ignored the key or exposed a delayed Accessibility update.

## Changes and safety boundary

- Check the unchanged full draft and end caret for another 250 ms after the
  configured trigger-stability wait, before making any selection or edit.
- If input resumes before selection, abandon only that attempt and observe the
  newer text with a fresh stability wait. An unchanged draft cannot retry itself.
- If only suffix selection was attempted, renewed input can defer only after a
  second context/readback check confirms the exact original body prefix survives,
  the new draft differs, and its caret is at the end with no selection. No
  selection rollback or text replacement is attempted.
- After a deletion attempt, all uncertain states still stop and pause. Never
  repeat Backspace, roll back text, replace the full draft or send unverified text.
- Await each exact edit result for up to one monotonic second, accepting only
  old/new text and range combinations for that edit. The previous 12-iteration
  loop could exhaust its polls after approximately 165 ms even though its nominal
  deadline was 250 ms. Context, full text and range checks remain in place.
- Show the concrete error beside the red pause message.
- Repeated keywords keep the existing suffix rule: only the final matched
  keyword and its following punctuation/whitespace are removed.

## Completed checks

- `swift test`: **95 passed, zero failures** (61 BingoCore, 34 BingoSend). Includes
  16 transaction regressions and three baseline/rearming regressions for resumed
  input, repeated Chinese triggers, delayed selection/deletion, ignored AX
  selection, cancellation, focus changes, and preserving newer input. Unconfirmed
  deletion is explicitly checked to produce only one Backspace and no Return.
- `./build.sh`: native arm64 production build passed; all 10 icon representations
  validated before/after ICNS conversion; ad-hoc signature verified.
- `git diff --check`: passed.
- Started the separate build-directory app and confirmed v1.3.3, paused launch,
  and preserved keywords, 0.8-second setting, removal option and enabled targets.
- Copied the same signed build to `/Applications/Bingo Send.app`; strict signature
  verification passed. Previous source, app and preferences are backed up in a local backup folder outside the repository.
- Full command output is outside the repository in
  `/tmp/bingo-send-race-final-tests.log` and `/tmp/bingo-send-race-final-build.log`.

## Pending native verification / next task

The new ad-hoc signature did not inherit the old Accessibility grant. Installed
v1.3.3 currently reports untrusted access and starts paused. The user must regrant
it before actual send tests can proceed. No TCC reset or automated grant was used.

A separate, local-only WKWebView QA editor is prepared outside the repository at
`/tmp/bingo-send-race-qa/Bingo Race QA.app`. It uses the already-enabled local QA
target identifier and can delay an acknowledged deletion by 450 ms. Next: test
ordinary removal, repeated triggers, the delayed-deletion case and keep mode;
then have the user retry continuous dictation in Codex. Unit tests and shortcut
posting alone are not third-party delivery or speech-input verification.

No Intel hardware, macOS 13 runtime, universal package or store/public release
validation was performed for this local repair.
