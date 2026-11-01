# Bingo Send 1.3.4

2026-11-01 · macOS 13+ · Apple Silicon and Intel universal package

## Changes

- A failed send stops only that attempt. Auto send stays selected even after
  repeated failures, so later new input can continue.
- The same failed draft and its possible delayed deletion result are not retried
  automatically. No repeated deletion or rollback overwrites newer input.
- Continued input before deletion waits afresh. Selecting a suffix is checked
  against the intact body, current caret and original context before proceeding.
- Improve acknowledgement of asynchronous editor updates and show the specific
  reason when an attempt is skipped.
- Includes up to three final keywords, Paused / Test detection / Auto send, and
  the first-launch Accessibility permission guidance from the 1.3.x previews.

Every launch still starts paused. Default keep mode preserves the entire draft
and keyword; optional removal deletes only the final matched keyword and its
following punctuation or whitespace. Earlier duplicate keywords remain in the
body. The app cannot stop an input method's recording session.

## Verification

- 104 automated tests pass (67 core, 37 app), including repeated failures,
  delayed edit results, cancellation and focus changes.
- Universal production build and strict ad-hoc signature verification passed.
- The ZIP and read-only mounted DMG contain the same signed executable as the
  installed app used for the user's authorization and normal-use confirmation.
- The user confirmed the clean-install native prompt, personally granted access,
  and reported normal use. Additional local-editor removal/delay/failure and
  continuous-dictation tests were not completed, at the user's request.
- Intel hardware and the minimum macOS version have not been runtime-tested.

## Install or upgrade

Open the DMG and drag Bingo Send into Applications, or extract the ZIP. Quit the
old version before replacing it. Grant Accessibility access yourself in System
Settings, choose the target apps, then select a run mode. If the old grant is
stale, remove and re-add the current Bingo Send entry in Accessibility settings.

Packages are **ad-hoc signed and not notarized by Apple**. A changed ad-hoc
signature can require authorization again. See the [user guide](USER_GUIDE.md)
and [verification record](VERIFICATION_1.3.4.md). Checksums accompany the release.
