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

## Volume split (user 2026-11-13)
The master Volume and the Music / SFX on-off cards became two sliders: `MusicVolumeRow` ("Music") and `SoundEffectsVolumeRow` ("Sounds"), each with Value, Minus, Slider, Plus (Studio; backup `UIBackup["Settings.BeforeVolumeSplit"]`). Data `MusicVolume` and `SoundEffectsVolume` (0-1); `PlayerData.Migrate` turns old `Volume` + toggles into them (a channel that was off becomes 0) and drops the old keys. `SettingsController` sets each SoundGroup to its base volume times its slider (`SettingsConfig.SoundSliders`). Checked in Play: a save with music off loaded as Music 0%, Sounds 100%.

## Data and behaviour
- `Settings` data (before 2026-11-13): `Volume` (0-1), `Music`, `SoundEffects`, `LowGraphics` (default off), `Notifications`, `AutoEquip` (default on). `PlayerData.Migrate` turns the old numeric `Music` into `Volume` plus a `Music` boolean. An old `Music = 0` means music off and keeps `Volume` at 1.
- `SettingsController`: each sound group's volume = base × `Volume`, or 0 when its toggle is off. Low Graphics sets the player attribute `LowGraphics` and turns off `Lighting.GlobalShadows`.
- `Utils/LowGraphics`: `EmitScale()` (0.4) scales chop particle counts and chunk counts in `RockController/Effects`. The cash-pop burst is skipped; the coins stay.
- Notifications off: `NotificationController:Notify` drops everything, server and client notifications alike.
- Auto Equip: `PetService.Granted` fires after each new Pet, and `PedestalService` then runs Equip Best.

Related: [[Pedestals]], [[Menu Panel Style]]
