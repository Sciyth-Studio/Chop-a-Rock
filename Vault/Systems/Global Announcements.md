---
description: Admin "Global Message" sends a gold notification to every live server via MessagingService (2026-10-28; local path playtested, cross-server not yet).
type: system
updated: 2026-10-28
---
# Global announcements

Asked for 2026-10-28: send a notification-style message to every server from the [[Admin Panel]].

- **Sending:** Events tab, `Global Message` (Text row, bar alias `announce <text>`). Up to `AnnouncementConfig.MaxLength` (200) characters; one message per server every `CooldownSeconds` (5 s). The admin gets an `Admin:` notification saying whether it went out.
- **Flow:** `AnnouncementService:Send` trims, filters the text with `TextService` (`PublicChat` → `GetNonChatStringForBroadcastAsync`; required for text other players see), shows it in this server, then `MessagingService:PublishAsync` on topic `AdminAnnouncement` with `{ Text, JobId }`. Every server subscribes in `Start` and shows incoming messages to all its players, skipping its own `JobId`. If publishing fails the message was still shown locally and the admin is told.
- **Display:** notification kind `Announcement`: `Gold` text style, held 8 s (`NotificationConfig.KindHoldSeconds`), and listed in `UnmutedKinds`, so it shows even with the Notifications setting off or during the tutorial.
- Players who join after a message don't see it; nothing is stored.
- `AdminRun` arguments may now be up to `AdminConfig.MaxArgumentLength` (200, was a hardcoded 64).
- **First test failed (2026-10-28):** Rojo dropped the `MaxArgumentLength = 200` edit to `AdminConfig`, so `AdminService` compared against nil and errored on every command. Resynced by the append-newline trick in [[Studio Live Editing vs Rojo]]; after that Studio Play showed the gold message and "message sent to every server".
- **Studio:** MessagingService needs the published place with API access; one Studio server only proves the local path. Test cross-server with two Team Test / live servers.
