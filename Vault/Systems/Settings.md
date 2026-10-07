---
description: Settings panel (2026-10-07): master Volume slider with -/+, toggles Music, SFX, Low Graphics, Auto Equip, Notifications; what each toggle does in code.
type: system
---
# Settings

Layout copied from a horse-game settings screenshot the user liked (2026-10-07), minus its horse rows, in the grey [[Menu Panel Style]]. The old panel is in `ServerStorage.UIBackup.SettingsOld`.

## UI (`StarterGui.Settings.Panel`, 980x520)
- `VolumeRow` (full width): `VolumeValue` (Sky text), `VolumeMinus`, `VolumeSlider` (`Track.Fill` + `Track.Knob`), `VolumePlus`.
- Grey cards (58,58,62, black `OuterStroke`, `InnerBorder` 100,100,106) named `<Setting>Row`, each with a `<Setting>Toggle`. `MusicRow` and `SoundEffectsRow` sit side by side, then `LowGraphicsRow` and `AutoEquipRow`, then a full-width `NotificationsRow`.
- There are no row icons yet. The reference has them; add an `Icon` once the user imports PNGs.

## Data and behaviour
- `Settings` data: `Volume` (0-1), `Music`, `SoundEffects`, `LowGraphics` (default off), `Notifications`, `AutoEquip` (default on). `PlayerData.Migrate` turns the old numeric `Music` into `Volume` plus a `Music` boolean. An old `Music = 0` means music off and keeps `Volume` at 1.
- `SettingsController`: each sound group's volume = base × `Volume`, or 0 when its toggle is off. Low Graphics sets the player attribute `LowGraphics` and turns off `Lighting.GlobalShadows`.
- `Utils/LowGraphics`: `EmitScale()` (0.4) scales chop particle counts and chunk counts in `RockController/Effects`. The cash-pop burst is skipped; the coins stay.
- Notifications off: `NotificationController:Notify` drops everything, server and client notifications alike.
- Auto Equip: `PetService.Granted` fires after each new Rok, and `PedestalService` then runs Equip Best.

Related: [[Pedestals]], [[Menu Panel Style]]
