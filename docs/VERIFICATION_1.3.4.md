# 1.3.4 build 15 verification — 2026-11-01

## User-requested change

After the 1.3.3 local installation, the user reported granting Accessibility but
the running app still reported untrusted access. The user requested a clean
uninstall/reinstall with the first-launch permission flow, and explicitly asked
that occasional or repeated send failures no longer pause automatic mode.

## Failure behavior

- Failed transactions stop without posting unverified Return or another
  Backspace. They no longer change the selected run mode, even after repeated
  failures. The notice says the attempt was skipped, with the specific reason.
- The original failed draft and its possible delayed deletion result are ignored
  for that editor until new text is entered. Focus/configuration resets preserve
  this session-only guard, preventing a late edit acknowledgement from triggering
  another send when an earlier duplicate keyword remains in the body.
- Keep editor identity across focus switches with a bounded 32-editor cache.
  Neither this cache nor failed-draft text is written to disk or logged.
- Manual pause and paused startup remain available. Permission loss still blocks
  access; keeping Auto send selected does not bypass an OS permission check.
- Retain 1.3.3's preflight, verified selection-only deferral, bounded edit waits,
  strict full-text/caret/context checks, and single-deletion rule.

## Completed automated checks

- `swift test`: **104 passed, zero failures** (67 BingoCore, 37 BingoSend), no
  compiler warnings. New regressions cover 50 consecutive failures without a
  mode change, preserving manual pause/preferences, suppressing old/delayed
  draft states across reset/focus changes, and allowing genuine new input and
  other editors to continue.
- `./build.sh --universal`: arm64 and x86_64 release builds passed; all 10 icon
  representations validated before/after ICNS conversion; ad-hoc signature
  verified. This binary is final before the clean-install permission flow.
- Full logs: `/tmp/bingo-send-1.3.4-tests.log` and
  `/tmp/bingo-send-1.3.4-build.log` (outside the repository).

## Completed clean installation and authorization

- Backed up the previous installed app, current source and app-specific runtime
  data in a local backup folder outside the repository.
- Cleared Bingo Send's preferences plus 27 old isolated test-preference remnants;
  checked app-specific cache/state locations. Other apps' data was not changed.
- `tccutil reset Accessibility io.local.bingosend` succeeded. No other app's
  Accessibility grant was reset, and no automated grant was performed.
- Installed the final 1.3.4/build 15 universal app. Strict signature verification
  passed, and its executable matched the built executable, SHA-256
  `81fa02b3a494956c5cab012479b0138aec2beb1412d0be7396804a444da4b6c8`.
  The preferences domain was absent immediately before first launch.
- The first-launch UI showed paused mode, default Chinese keywords, all targets
  disabled, removal off, a 1.0-second delay and the newly requested permission.
- **The user confirmed seeing the new native prompt and personally granting
  access.** The app then showed the authorized controls and running automatic
  mode. Its visible records included shortcut posting to Codex and DeepSeek.
  Those records alone are not delivery receipts.

## Native-test scope and user-requested stop

The local-only WKWebView QA editor was prepared with repeated-trigger input,
450 ms delayed deletion, and ignored-deletion cases. Its automatic-send matrix
was **not completed**: automation did not make that editor the real foreground
app, and Bingo Send continued to report Chrome as the observed application.
No fixture-send result or continuous-dictation removal pass is claimed.

The user then explicitly reported that configuration was complete and normal
use worked, and instructed testing to stop. No more tests were run. The QA
window was closed, its temporary app rule was removed, and the removal option
was restored to the user's pre-QA off setting. Automatic mode, the user's
Codex/DeepSeek targets, keywords and 1.0-second delay were preserved. The app
was not rebuilt, re-signed or reinstalled after the successful grant.

User-confirmed normal usability is recorded separately from the unexecuted
removal/delay/failure matrix. No further native UI testing was performed.

## Release recheck

The user subsequently requested a final recheck and GitHub publication.

- Repeated `swift test`: **104 passed**, zero failures and no compiler warnings.
- Packaged the already-installed, authorized app using
  `./scripts/package-release.sh --app "/Applications/Bingo Send.app"`; no rebuild,
  re-sign, launch or permission reset was needed.
- Both ZIP and read-only mounted DMG passed version/build, strict signature,
  arm64/x86_64 and identical-executable checks. Their executable SHA-256 matches
  the clean-install record above. Neither package contains local test tooling.
- ZIP SHA-256: `bc0b373630e84df40890230eeb85844613b0c3b73c5e120bbfecfb49874d026f`.
- DMG SHA-256: `d81c461d415fb05687139d02e325b95ba6daa0e9d90f9246f2284622f4da1847`.
- `SHA256SUMS.txt` was verified against both complete package files.
- Reviewed the final diff, kept full logs outside the repository, removed private
  local backup paths from public documentation and updated bilingual download
  links/release notes for 1.3.4.

The additional native UI tests remain stopped at the user's request. Notarization,
Intel hardware and minimum-macOS runtime testing are not included.
