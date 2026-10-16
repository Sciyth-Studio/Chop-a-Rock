---
description: The admin panel (2026-10-04, tabbed rebuild 2026-10-08) — presets, warps, value commands; who counts as admin and how to add a command.
type: system
updated: 2026-10-08
---
# Admin panel

The user asked for one place to keep every admin command, including future weather events and spawning. On 2026-10-08 they said reaching a point in the game to test one feature took too long, so it was rebuilt around presets, warps and commands that take a value (phase 1 of the plan; phases 2 and 3 are in [[To Do]]).

- **Who is admin:** everyone in Studio, plus the UserIds in `AdminConfig.UserIds` on live servers (since 2026-10-15: 467512659 = the user, 169380679 = co-dev, added so Team Test, which runs on a live server where `IsStudio()` is false, has the panel; remove or keep deliberately before public release). `AdminService` sets the player attribute `IsAdmin` and **checks admin rights again on every command**; the client attribute only shows the UI.
- **Opening it:** an "Admin" TopbarPlus icon (only shown to admins) toggles `StarterGui.AdminPanel` (red header, non-modal, top right). The panel is 600 wide and fills the screen height minus 16px margins (`Size` 0,600 by 1,-32), capped at 760 by a `UISizeConstraint`; a fixed 760 ran off the bottom of an 818px Studio viewport. Tabs come from `AdminConfig.Tabs`: Presets, Move, Stats, Roks, Chop, Weather, Debug. `List` is a ScrollingFrame. The `Tabs` grid is 4 columns (`CellSize` 0.25,-9 by 44) since the Weather tab made 7 tabs; 3 columns pushed Debug onto a third row over the first command.
- **Row kinds** (`Kind` in `AdminConfig.Commands`): `Button` (cloned from `CommandTemplate`), `Number` (`NumberTemplate`: an `Input` TextBox plus `Run`; Enter also runs), `Choice` (`ChoiceTemplate`: `Prev` / `Value` / `Next` cycler plus `Run`). Rows are named by command Id (`Preset_<Id>` and `Warp_<Label>` for those), so tests can click `AdminPanel.Panel.List.<Name>`.
- **Numbers** are parsed on the server (`AdminService/Arguments`): commas and spaces are ignored, and `k`, `m`, `b`, `t` suffixes work (`1.5m`). Ranges are checked per command.
- **Presets** (`AdminConfig.Presets`) wipe the save (like Reset) and then set cash, level or strength, rebirths, arm tier, slots, geodes, Roks (placed on pedestals in unlock order) and optionally a complete Index. Drafts: Fresh Start, Pre-Rebirth, Rebirth Ready, Desert, Late Game. Applied through `DataService:ResetData(player, overrides)`, which re-fires `PlayerLoaded` so every service resyncs. `ResetData` lists every progress field by hand and also clears `Receipts`; Settings are kept. A new saved progress field must be added there too. `TrainingTier` was missing until 2026-10-16, so Robux-bought stands survived a reset.
- **Auto preset:** in Studio only, set the string attribute `AdminAutoPreset` on Workspace (Edit mode) to a preset Id, e.g. `Desert`. The server applies it on your first load each Play. Clear the attribute to keep your real save. Studio has API access, so data otherwise persists between Plays.
- **Warps:** parts inside `Workspace.AdminWarps` (a Model with `ModelStreamingMode` Persistent, so the client sees them all under streaming). Each part's `Label` attribute is the button text and `Order` sorts them; the player lands on top of the part facing its front. "My Base" is added by code (the plot's `BaseSpawn`). To add a warp, drop in a part; no code change. Current: Lobby, Arm/Geode/Sell Shop, Forest, Desert, Jungle, Ocean, Snow.
- **Shortcuts:** Ctrl+Shift + the command's `Shortcut` key, `Button` commands only (C cash, P Rok, G geode, M master, H next hatch Secret, K spawn spots, Backspace reset, N weather in 10 s), handled by `AdminController`.
- **Adding a command:** add `{ Id, Label, Tab, Kind, Default?, Choices?, Shortcut? }` to `AdminConfig.Commands` and a handler with the same Id in `AdminService/Commands.luau`. The handler gets `(context, player, argument)` and calls the owning service's public method (e.g. `StatsService:SetStrength`, `ArmService:SetTier`, `PedestalService:SetSlots`, `RockService:ForceNextMaster`). Commands act on the caller only.
- **Rule:** every new system ships with its admin commands (spawn it, force it, skip its timer), so the panel keeps up with the game.
- Everything goes through one packet, `AdminRun(commandId, argument)`; the argument is `""` for buttons.
- The pre-tabs panel is backed up as `ServerStorage.UIBackup.AdminPanel_PreTabs`.

Related: [[Code Output Rules]], [[Menu Panel Style]]
