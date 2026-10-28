---
description: 17 s "The Master" intro cutscene for first-time players (built 2026-10-27, not playtested) - boulder squashes your car, the Master Master-chops it, "Go train, kid!", lands you facing your stand; client-only set, Claude-made animations, how it hands off to the tutorial.
type: system
---
# Intro Cutscene

Story from the user (2026-10-27): a boulder lands on the player's car, a sensei called **the Master** Master-chops it in two, the player is jealous, he says "Go train, kid!", and they land on the map. Plan: `IntroCutscenePlan.md` (approved with defaults). Launch Checklist §1 item. All timings are drafts in `IntroConfig`.

## When it plays
- `IntroController` (client) waits for data and the character, then plays only if `Tutorial.Step == Train`, `Taps == 0` and `Furthest <= Train`. Rejoining after any training rep or later step skips it; rejoining before the first rep replays it (no saved flag, by choice).
- Test it: Reset Player Data (admin), then stop and start Play. It only checks on load.
- No Skip (user-approved default).

## Timeline (seconds, `IntroConfig`)
Drive 0-4.9 (front then side tracking shot) · look up + rumble + growing shadow 3.0 · boulder falls 4.4 · boing out of the car and car squash at 5.0 (`Boing` marker) · dazed with orbiting stars 6.1 · Master idle on the cliff, hero shot 6.9 · leap 7.3, lands 8.8 (`Land` marker) · chop 9.8, wind-up darken from 10.45 (side then face shot), wide shot 12.3, `Impact` 12.47 (flash, punch, shake, live split / SplitModel, car pops back) · awe push-in 13.2 · point 13.6, front shot 14.3 · whoosh to white 15.75 · arrive behind your character facing the stand 16.35 · done 17.2 (Custom camera keeps that facing).
Captions (one line, ≤ 4 words): "Uh oh!", "The Master" (Gold), "Master!" (Gold), "Whoa!", "Go train, kid!".

## Pieces
- `IntroController/init.luau` timeline, `Stage.luau` (clone set, copy of your avatar, Master, Mega Boulder = forest `Second` rock x2 dark with a gold Highlight, car squash/pop, stars, VFX emit), `Shots.luau` (Scriptable camera bound after the default camera, shake, darken, flash, white fade), `Types.luau`.
- Screens `IntroCaption` (StarterGui, cloned from TutorialComplete, DisplayOrder 6) and the existing `Letterbox`.
- Studio: `Assets/Models/Intro/IntroSet` (ground, road, cliff 22 tall behind the boulder spot, 12 primitive trees, red convertible with `Body.Seat`, `Markers` folder of camera and spot parts: move parts to retune shots), `Assets/Models/Intro/IntroMaster` (TemplateR15, white gi, black belt, red headband with tails, grey moustache, brows and hair), `Assets/Animations/Intro/Anim_Intro_*` (9). The set is cloned at `SetOrigin` (-3000, 200, -3000) on the client only.
- Hooks: `RockController:PlayMasterWindUp` / `PlayBreak`; `TutorialController` `isBusy` also checks `IntroController:IsPlaying()`, so step 1 starts after the camera lands.
- Sounds are existing keys (`IntroConfig.Sounds`): thunder rumble, cannon boom crash, board throw boing, cannon land, whoosh. No new sounds; no speech bubble (the caption carries the line).

## Animations
Made by Claude, not an animator (the animator fell through). See [[Animation Uploads]]. Source: `assets/Animations/Intro/intro_clips.py` (key poses + eased sampling every 3 frames), ids in `ids.json`. Travel clips: Boing Out ends 9 left / 1.5 down / turned -90 (`BoingRootOffset`), Leap ends 30 forward / 22 down (`LeapRootOffset`); the code moves the root when the next clip starts. Non-looped clips are held on their last frame (`AdjustSpeed(0)`).
Seen in Studio as contact sheets: drive, look-up, boing, leap arc, chop wind-up/strike/bow, point, awe. Not seen in motion or in Play.

## Editing by hand in Studio
- **Set:** `Assets/Models/Intro/IntroSet` can be dragged into Workspace and edited anywhere; the code moves it to `SetOrigin` by its pivot (PrimaryPart `Ground`). Keep the names `Car` (Model, PrimaryPart `Body` with the `Seat` attachment where the player's root sits) and `Markers`.
- **Markers:** `CarStart`/`CarStop` (drive path), `Boulder` (landing spot on the ground), `MasterStart` (Master's root, front = leap direction; the leap lands 30 forward, 22 down). Camera: `CamCrash` and `CamChopWide` are used as-is (position and facing); `CamSky` and `CamHero` use position and their front as the starting look; `CamDriveFront` uses position only (looks at the car); `CamDriveSide` is an offset from `CarStop` that tracks the car. Set one from the Studio view with `marker.CFrame = workspace.CurrentCamera.CFrame` in the command bar. `CamWhoosh` is unused.
- **Trees (2026-10-27):** the 12 primitive trees became `Trees` > 12 `Tree` MeshParts: meshlab `ForestTree` seeds 1-4 in turn, random 15° yaw, scaled 0.9/1.0/1.1 by the old trunk height, Plastic `2022 Stud`, Color white, no collide/touch/query. The old part trees are in `ServerStorage.IntroTrees_Primitive`. See [[Meshlab]]. At the time the set was in `Workspace.IntroSet` (dragged out for editing); `AssetRegistry` only finds it under `Assets/Models/Intro`.
- **Master:** `Assets/Models/Intro/IntroMaster`; restyle freely, keep the R15 part names and `HumanoidRootPart`.
- **Animations:** paste a new id into the matching `Assets/Animations/Intro/Anim_Intro_*` Animation (published to the group). Keep the event names `Boing`, `Touchdown`, `Land`, `Impact` and roughly the length, or change the times in `IntroConfig`; travel changes need `BoingRootOffset`/`LeapRootOffset`. Claude's clips can be opened in the Animation Editor by inserting `assets/Animations/Intro/build/<clip>.rbxmx` (Insert from File) into a rig's `AnimSaves`.
- **Caption:** `StarterGui.IntroCaption`; keep `Caption`, `CaptionShadow` and `PopScale`.

## Not checked
Nothing run in Play yet: timing, shot framing, the car squash, the split on the scaled boulder, the avatar copy (Rthro, layered clothing), the Custom camera keeping the stand facing, touch/phone.

Related: [[Tutorial]], [[Chop Effects]], [[Launch Checklist]]
