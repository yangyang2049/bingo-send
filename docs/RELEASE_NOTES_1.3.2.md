# Bingo Send 1.3.2 (build 13) preview

- On the first main-window presentation, request native Accessibility permission once if access is absent. Do not also open System Settings at the same time. Keep an explicit Settings fallback if the OS prompt does not appear.
- Check actual permission continuously. Once granted, move the entry into a collapsed **Permissions & diagnostics** section at the bottom. Show the primary grant guidance again if permission is lost.
- Explain the next setup step after authorization and add a direct link to the target-app list. Apps remain opt-in; permission does not start sending. Every launch starts paused.
- Keep the first-check marker separate from actual trust. Reopening preserves the marker; a complete preferences/TCC reset restarts onboarding. Already-authorized installs do not manufacture a redundant prompt.

Automated permission checks inject the trust reader, prompt requester, and settings opener and use isolated preferences. Real installation QA must verify that macOS actually displays the native prompt and that the form scroll action works. A local-only editor fixture checks detection, keep, removal, and pause without submitting messages to external chats. See the separate verification record for executed and pending items.

Packages remain ad-hoc signed and not Apple notarized. A changed signature can require reauthorization. Physical Intel and minimum-macOS runtime support have not been verified in this round.
