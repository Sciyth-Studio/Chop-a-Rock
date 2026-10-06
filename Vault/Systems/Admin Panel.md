---
description: The admin panel (2026-10-04) — one place for dev/admin commands; who counts as admin and how to add a command.
type: system
---
# Admin panel

The user asked for one place to keep every admin command, including future weather events and spawning.

- **Who is admin:** everyone in Studio, plus the UserIds in `AdminConfig.UserIds` on live servers (empty for now, so live servers have no admins). `AdminService` sets the player attribute `IsAdmin` and **checks admin rights again on every command**; the client attribute only shows the UI.
- **Opening it:** an "Admin" TopbarPlus icon (only shown to admins) toggles `StarterGui.AdminPanel`. That's a red-header copy of the Settings panel at the top right, non-modal, with one button per command built from the hidden `List.CommandTemplate`.
- **Shortcuts:** Ctrl+Shift + the command's `Shortcut` key (C cash, P Rok, G geode, M master — also applies to geode cracks, H next hatch is a Secret, Backspace reset), handled by `AdminController`.
- **Adding a command:** add `{ Id, Label, Shortcut? }` to `AdminConfig.Commands` and a handler with the same `Id` in `AdminService`'s `handlers`. The handler calls the owning service's public method (e.g. `RockService:ForceNextMaster`). Commands act on the caller only.
- Everything goes through one packet, `AdminRun(commandId)`. The old `Dev*` packets and `DevController` were removed.

Related: [[Code Output Rules]]
