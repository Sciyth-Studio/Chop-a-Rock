---
description: The user prefers adding content by dropping instances into a Studio folder, not by pasting asset ids into config code.
type: preference
updated: 2026-10-03
---
When a system plays or shows a list of assets (music, and likely future sound/image lists), build it to read whatever instances sit in a Studio folder under `ReplicatedStorage.Assets`, not a list of ids in a config module.

**Why:** 2026-10-03 the background music stopped because its track ids had lived only in Studio's copy of `MusicConfig`; Rojo synced the empty repo file over them. The user said they'd "much rather have the music system be a drop sound into folder instead of adding ids to code."

**How to apply:** add the folder to `default.project.json` under `Assets` with `$ignoreUnknownInstances: true`, so Rojo creates it but never empties it. Read the instances at runtime and use their own properties (e.g. a Sound's `Volume`). Music now works this way: Sounds dropped in `ReplicatedStorage.Assets.Music` play shuffled. See [[Studio Live Editing vs Rojo]].

**Sounds folder layout (2026-10-10):** `ReplicatedStorage.Assets.Sounds` is split into subfolders by system: `Chop` (hit tiers, Master, Train_Chop), `Rock` (Break, Crack, Rise), `Diamond`, `Rush`, `HotStreak`, `Hatch`, `Level`, `UI` (Notification, Money_Gain). `AssetRegistry.get` finds sounds with a recursive `FindFirstChild` in the Sounds category, so keys are unchanged; drop a new sound in the matching folder. The Rojo `Sounds` folder keeps `$ignoreUnknownInstances`, so the subfolders survive syncs. The `SoundEffects` group is still assigned by `AssetRegistry` on clone. `Assets.Music` is separate and untouched.
