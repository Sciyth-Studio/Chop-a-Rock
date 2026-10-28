---
description: Join cover shown to every player (2026-10-28) - dark stud backdrop, Gold "Chop a Rock", bouncing Bloky, Chrome "Loading..."; closed by IntroController once data says no intro, or once the intro is preloaded and warmed up behind it
type: system
---
# Loading cover

Approved 2026-10-28 (user picked "everyone on join" and "title + bouncing Bloky"). It hides the HUD popping in while data loads, and for first-time players it hides the intro's first-render hitches.

## Pieces
- `StarterGui.LoadingCover` (Studio, stored **disabled** so it doesn't cover the edit viewport; toggle `Enabled` to preview): DisplayOrder 100, IgnoreGuiInset. `Cover` is a full-screen CanvasGroup (14, 16, 20) with the menu panels' `StudTexture` (`73393331823706`, 23 px tiles, black at 0.55). `Content` (760 x 560, `ScreenScale`) holds `Title` "Chop a Rock" (`Gold`, 4 px stroke), `Bloky` (icon `114244702896000`, 200 px), `Status` "Loading..." (`Chrome`, 3 px stroke), each with a black `...Shadow` copy.
- `Screens/LoadingCover.luau`: `StartsOpen`, so UIController opens it the moment PlayerGui has it. It bounces `Bloky` and `BlokyShadow`, and on Close waits out `MinSeconds` and then fades `Cover.GroupTransparency` over `FadeSeconds`. It closes itself after `MaxSeconds` (20) if nothing else does.
- `LoadingCoverConfig`: screen name, fade 0.4, min 0.6, max 20, bounce 28 px every 0.7 s.

## Progress bar (2026-10-28)
User asked for a bar built on progress-bar psychology. `Content.ProgressBar` (560 x 42, block style: dark well, 3 px black stroke, sharp corners) holds `Track` > `Fill`: a green gradient (60, 235, 0) to (20, 170, 0), panel studs, `Ribs` (the header stripe texture `124988166234585`, 64 px tiles) and a `Shine` line. The Status text moved down to y 515.

Each rule and where it lives:
- **Head start (endowed progress, Nunes & Drèze 2006):** it opens at `Milestones.Joined` 0.12, not 0.
- **Truthful milestones (Myers 1985):** it jumps to `DataLoaded` 0.45 (from `DataController.Loaded`), then on `IntroController.LoadProgressed` to `StageBuilt` 0.6, `AnimationsLoaded` 0.75 and `Preloaded` 0.9.
- **Never stall, never go back (Harrison et al. 2007, stalls and slowdowns feel longest):** between milestones it creeps toward halfway to 100% (`CreepShare`, `CreepRate`), and the fill only grows.
- **Speed up at the end (Harrison et al. 2007):** on Close it dashes to 100% with Quad In over `FinishSeconds` 0.25, holds 0.15 so 100% registers, then fades.
- **Backwards-moving ribs (Harrison, Yeo & Hudson 2010, about 11% shorter feel; faster pulses feel faster):** `Ribs` scroll right to left, speeding up from 40 to 140 px/s as it fills.
- **Explain the wait (Maister 1985):** `StatusTexts` per stage: "Loading...", "Loading your save...", "Setting the scene...", "Almost ready...".
- **No percentage number:** an exact number makes a stall obvious.

Tested in Play 2026-10-28: no backwards frames, ribs moving, statuses in order, dash then fade. The close takes about 0.8 s, so the cover still hides the first moment of the intro's drive shot.

## Who closes it
`IntroController`: on every early exit in `begin` (no intro, missing character), in the intro's `finish`, and on the intro path after the preload and warm-up, right as the intro clock starts. The first 0.4 s of the drive shot fades in from it.

## Intro preload and warm-up
After the animations load, `ContentProvider:PreloadAsync` runs on the set, the Master, the player copy and the boulder (`IntroConfig.PreloadTimeoutSeconds` 6). Then the camera sits Scriptable on the first shot for `WarmupFrames` (10) before the clock starts. Measured 2026-10-28: no intro frame over 100 ms (worst 29 ms, 1033 frames in 17.2 s), against three 190-260 ms hitches before. The load hitches (up to 873 ms in Studio) now land under the cover. See [[Intro Cutscene]].

Not checked: what shows between the Roblox loading screen and PlayerGui filling (the probe only saw the cover from about 5 s after the client started), and how it looks on a phone.
