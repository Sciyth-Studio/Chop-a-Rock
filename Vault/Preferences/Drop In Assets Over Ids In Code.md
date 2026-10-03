---
description: The user prefers adding content by dropping instances into a Studio folder, not by pasting asset ids into config code.
type: preference
updated: 2026-10-03
---
When a system plays or shows a list of assets (music, and likely future sound/image lists), build it to read whatever instances sit in a Studio folder under `ReplicatedStorage.Assets`, not a list of ids in a config module.

**Why:** 2026-10-03 the background music stopped because its track ids had lived only in Studio's copy of `MusicConfig`; Rojo synced the empty repo file over them. The user said they'd "much rather have the music system be a drop sound into folder instead of adding ids to code."

**How to apply:** add the folder to `default.project.json` under `Assets` with `$ignoreUnknownInstances: true`, so Rojo creates it but never empties it. Read the instances at runtime and use their own properties (e.g. a Sound's `Volume`). Music now works this way: Sounds dropped in `ReplicatedStorage.Assets.Music` play shuffled. See [[Studio Live Editing vs Rojo]].
