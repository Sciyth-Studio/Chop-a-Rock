---
description: 22.6 s wordless Tom & Jerry style "The Master" intro for first-time players - a boulder rolls off a cliff onto your car, the Master teleports in and Master-chops it so the halves fly off-screen, then teleports you to your stand; client-only set, Claude-made animations, sounds, how it hands off to the tutorial.
type: system
---
# Intro Cutscene

Story from the user (2026-10-27): a boulder lands on the player's car, a sensei called **the Master** Master-chops it in two, the player is jealous, he says "Go train, kid!", and they land on the map. Plan: `IntroCutscenePlan.md` (approved with defaults). Launch Checklist §1 item. All timings are drafts in `IntroConfig`.

## When it plays
- `IntroController` (client) waits for data and the character, then plays only if `Tutorial.Step == Train`, `Taps == 0` and `Furthest <= Train`. Rejoining after any training rep or later step skips it; rejoining before the first rep replays it (no saved flag, by choice).
- Test it: Reset Player Data (admin), then stop and start Play. It only checks on load.
- No Skip (user-approved default).

## Feedback round 1 (user, 2026-10-28)
- **No text, ever.** A Tom & Jerry style cartoon: sound carries the jokes. The captions and `StarterGui.IntroCaption` are gone (screen module deleted).
- Much more sound (list below). The user picked: teleport `4861638982` (DBZ instant transmission, for the Master arriving and for the cut to the map), "go train" `139540283473798` (in place of the notification sound), dizzy `8730871251`, car driving `74532914640475`.
- The boulder has no outline. It rolls off the cliff (a `Slope` part, 4 up over 40, was added on the cliff top) instead of dropping from the sky.
- The split must be ridiculous, with the halves flying out of the scene. The old physics split pushed too gently to read as a split. The intro now spawns the `SplitModel` pieces anchored and flies them on a scripted arc along the Master's right vector (`Piece*` in `IntroConfig`).
- The Master teleports in (flicker + white flash ball, `Stage.Teleport`), and he isn't standing there from the start.
- His wind-up "wobble" was the `tremble` layer in `master_chop` (it flipped sign every 2 frames but was sampled every 3, so it aliased into a wobble). It was removed and Chop re-uploaded as `113949446646883`.
- The drive is longer (`CarStart` moved to z 160, 8.9 s).
- The player copy loses the black `CharacterHighlight` outline (Highlights are stripped from both rigs).
- The rock-rise sound played behind the loading screen: `RockController` now skips it while `LoadingCover` is open or the intro plays.

## Music (user, 2026-10-28)
`IntroConfig.Cues`: each cue is a Sound in `Assets/Sounds/Intro` played at `At` from `StartSeconds`, then stopped or faded at `Until`, and preloaded with the stage. Volumes are on the Sound instances (music 0.4, effects 0.6).
- Drive `MUS_Intro_Drive` 1845764031 (user) 0-6, hard stop at the rumble.
- Suspense `MUS_Intro_Suspense` 9042777042 ("Secret Scheme", Claude's pick) 6-8.3.
- Falling whistle `SFX_Intro_FallWhistle` 132173082718180 (user, 2.69 s) from 1.4 s in at 7.6, so it ends on the 8.9 squash.
- Dizzy `MUS_Intro_Dizzy` 1842344059 ("On Tip Toes", wah-wah mutes, Claude's pick) 9.3-11.2.
- Master `MUS_Intro_Master` 1838864418 (user) 11.2-14.5.
- Kabuki `MUS_Intro_Kabuki` 4726086884 (user) replaces the Master wind-up sound (`PlayMasterWindUp(part, true)` keeps only the effect). Inside the track: drum hits at 5.50 and 7.03 s (sharp onsets, the loudest peaks), then the **"yoo" voice**, which rises in the mids from 7.9 s and reaches full strength at ~8.25 s, then a low rumble to 10.2 s. The user wants the **yoo** on the hit (first try lined up the 7.03 drum: "the yoo part isn't lined up with the hit"). It starts at 5.9 s (after the first drum decays) at 14.52, so the full yoo lands ~0.3 s before `Impact` (17.17) and has room before the fade at 19.2 (user: at 14.82 it "got faded out", move it back slightly). If the chop moves, keep `At` = Impact - (8.25 - `StartSeconds`).
- Victory `MUS_Intro_Victory` 12222253 (user, 1.2 s fanfare) at 18.6.
- **Player flicker (2026-10-28):** after the crash the player copy blinked: the one-frame double offset at the BoingOut to Dazed switch. The intro timeline now runs on `RunService.PreAnimation`, which also covers the Master's Leap to Chop switch. The user confirmed the flicker is gone. See [[Animation Uploads]].
- **Game music (2026-10-28):** the background playlist kept playing under the intro (the user turned Music on in Settings). The intro now holds `MusicController:Hold()` (fades the playlist out and pauses it; the returned function releases it, then it resumes and fades back in) from `play()` until `finish()`. A track picked while held waits, unplayed. `MUS_*` cues join the `Music` SoundGroup instead of `SoundEffects` (AssetRegistry's default for Sounds), so the Music setting mutes the intro score too and the SFX setting only mutes the effects.
- Measuring audio in Edit: `Sound.PlaybackLoudness` stays 0 there, but an `AudioPlayer` wired to an `AudioAnalyzer` plays and reports `PeakLevel`/`RmsLevel`, and `GetSpectrum()` with `SpectrumEnabled` (a gradual rise in the mid bands = voice, a sharp broadband onset = drum).

## Timeline (seconds, `IntroConfig`)
Drive 0-8.9 (engine loop, honk 1.0; front shot, side tracking from 3.0) · rumble + cut to `CamCliff` 6.0, boulder teeters · rolls down the slope 7.0 (roll sound) · player looks up, sky shot, shadow grows 7.6 · gulp 7.9 · off the edge 8.3 (whistle from 7.6) · boing + squash 8.9 (`Boing` marker), crash shot · dazed + dizzy sound 10.1 · hero shot 10.9 · Master teleports onto the cliff edge 11.2 · leap 12.0 · chop 14.5, wind-up 15.15 (side then face shot), wide 17.0, `Impact` ~17.17 (flash, crash, slide whistle, halves fly off for 3 s) · awe 18.6 · point 19.0, front shot 19.7, "go train" sound 19.9 · Master teleports out + white fade (teleport sound) 21.15 · arrive at the stand 21.75 · done 22.6.
Boulder path: markers `BoulderStart` (on the slope) → `BoulderEdge` (just past the cliff lip) → `Boulder` (rest); the centre rides `BoulderRollHeightStuds` (9) above the markers and snaps to rest at the squash.

## Pieces
- `IntroController/init.luau` timeline, `Stage.luau` (clone set, copy of your avatar, Master, Mega Boulder = forest `Second` rock x2, dark, no outline; rolls, then `Split` flies the halves, car squash/pop, stars, VFX emit), `Shots.luau` (Scriptable camera bound after the default camera, shake, darken, flash, white fade), `Types.luau`.
- Screen: the existing `Letterbox` only (no text).
- Studio: `Assets/Models/Intro/IntroSet` (ground, road, cliff 22 tall behind the boulder spot, 12 primitive trees, red convertible with `Body.Seat`, `Markers` folder of camera and spot parts: move parts to retune shots), `Assets/Models/Intro/IntroMaster` (TemplateR15, white gi, black belt, red headband with tails, grey moustache, brows and hair), `Assets/Animations/Intro/Anim_Intro_*` (9). The set is cloned at `SetOrigin` (-3000, 200, -3000) on the client only.
- Hooks: `RockController:PlayMasterWindUp` / `PlayBreakBurst` (break effect + sound, no split); `TutorialController` `isBusy` also checks `IntroController:IsPlaying()`, so step 1 starts after the camera lands.
- Sounds (`IntroConfig.Sounds`): new `Assets/Sounds/Intro/SFX_Intro_*` (Studio): CarDrive, Honk `9114402335`, RockRoll `9118661490`, Gulp `72850859029835`, FallWhistle `102429199188900`, Boing `2772396665`, Dizzy, Teleport, GoTrain (user picks above), SlideUp `8418350416`; plus existing thunder, cannon boom, rock break, cannon land, UI toggle.

## Animations
Made by Claude, not an animator (the animator fell through). See [[Animation Uploads]]. Source: `assets/Animations/Intro/intro_clips.py` (key poses + eased sampling every 3 frames), ids in `ids.json`. Travel clips: Boing Out ends 9 left / 1.5 down / turned -90 (`BoingRootOffset`), Leap ends 30 forward / 22 down (`LeapRootOffset`); the code moves the root when the next clip starts. Non-looped clips are held on their last frame (`AdjustSpeed(0)`).
Seen in Studio as contact sheets: drive, look-up, boing, leap arc, chop wind-up/strike/bow, point, awe. Not seen in motion or in Play.

## Editing by hand in Studio
- **Set:** `Assets/Models/Intro/IntroSet` can be dragged into Workspace and edited anywhere; the code moves it to `SetOrigin` by its pivot (PrimaryPart `Ground`). Keep the names `Car` (Model, PrimaryPart `Body` with the `Seat` attachment where the player's root sits) and `Markers`.
- **Markers:** `CarStart`/`CarStop` (drive path), `Boulder` (landing spot on the ground), `MasterStart` (Master's root, front = leap direction; the leap lands 30 forward, 22 down). Camera: `CamCrash` and `CamChopWide` are used as-is (position and facing); `CamSky` and `CamHero` use position and their front as the starting look; `CamDriveFront` uses position only (looks at the car); `CamDriveSide` is an offset from `CarStop` that tracks the car. Set one from the Studio view with `marker.CFrame = workspace.CurrentCamera.CFrame` in the command bar. `CamWhoosh` is unused.
- **Trees (2026-10-27):** the 12 primitive trees became `Trees` > 12 `Tree` MeshParts: meshlab `ForestTree` seeds 1-4 in turn, random 15° yaw, scaled 0.9/1.0/1.1 by the old trunk height, Plastic `2022 Stud`, Color white, no collide/touch/query. The old part trees are in `ServerStorage.IntroTrees_Primitive`. See [[Meshlab]]. At the time the set was in `Workspace.IntroSet` (dragged out for editing); `AssetRegistry` only finds it under `Assets/Models/Intro`.
- **Car (2026-10-27):** the part-built red convertible became one `Body` MeshPart, meshlab `IntroCar` (asset `91666183075378`, [[Intro Car Reference]]), 8.15 x 4.8 x 12.9, Plastic `2022 Stud`, Color white. `Body.PivotOffset` keeps the old car's pivot (centre, 1.6 up), so `PivotTo(CarStart)` is unchanged, and `Body.Seat` is at the old world spot (driver left, root 2.95 up). Old car in `ServerStorage.IntroCar_Primitive`. The squash on one mesh isn't seen in Play yet.
- **Master:** `Assets/Models/Intro/IntroMaster`; restyle freely, keep the R15 part names and `HumanoidRootPart`. Since 2026-10-27 (user: "should really just use roblox 2d clothing & accessories") he wears catalog items instead of welded parts: Karategi Shirt `6476167301` and Pants `6476167804` (Mat's Sweatshop), and the user's picks: Black Ninja Headband of the Silent Sun `11297708`, Ancient Wizard Beard `461493477`, and the Old Timer dynamic head `113124428065996` (from bundle `111711586085287`; its Mood animation isn't used), on a skin-coloured body. The part-built version is in `ServerStorage.IntroMaster_Parts`.
  - `Humanoid:AddAccessory` doesn't weld outside Workspace, so the accessories have hand-made `AccessoryWeld`s (handle attachment matched to the body attachment of the same name).
  - `ReplaceBodyPartR15` keeps the new head where it loaded (it was at x 690); in a template, snap it with `Head.CFrame = UpperTorso.NeckRigAttachment.WorldCFrame * Head.NeckRigAttachment.CFrame:Inverse()` and re-seat the accessory handles from their welds.
- **Car facing:** the first IntroCar upload came in turned 180° (meshlab export axis; fixed in `export_fbx.py`, see [[Meshlab]]); `Body` was turned round its pivot in Studio, seat kept.
- **Animations:** paste a new id into the matching `Assets/Animations/Intro/Anim_Intro_*` Animation (published to the group). Keep the event names `Boing`, `Touchdown`, `Land`, `Impact` and roughly the length, or change the times in `IntroConfig`; travel changes need `BoingRootOffset`/`LeapRootOffset`. Claude's clips can be opened in the Animation Editor by inserting `assets/Animations/Intro/build/<clip>.rbxmx` (Insert from File) into a rig's `AnimSaves`.
- **Dizzy stars (2026-10-28):** `Assets/Models/Intro/IntroStar`, a free Creator Store star MeshPart (2546401245, 0.8 tall), cloned 3 times, orbiting the head and spinning; balls are the fallback.
- **Awe shot (2026-10-28):** it used to push in on the player from 7 to 3.5 studs along the player's facing. The Master stands ~4 studs in front of the player there, so the camera drove through him and showed his accessories from inside (user: "when the camera moves through the master it lingers too long"). From `AweCutAt` to `PointCutAt` it is now the Master's POV: from his head (`PovForwardStuds` 0.8 toward the player), looking at the player's head, easing in up to `PovPushStuds` (1.5). The Master is hidden for that shot and shown again at `PointCutAt`. (I first changed the end whoosh by mistake; it is back as it was.)
- **Road (2026-10-28):** the car drove down the middle of the road. The road is now 24 wide (two 12-stud lanes), and it and its centre-line dashes (`RoadLines`) were moved 6 studs to -X, to centre x -1441.37 in set space. The car's path (x -1435.37, facing -Z, right side +X) is now the middle of the right-hand (US) lane, on the cliff side. Nothing else moved; the nearest trees (x -1458, -1460) stay clear of the new west edge (-1453.37).
- **Crash shot:** the tree nearest `CamCrash` filled the left half of the shot; it was moved behind the camera to (-1478, -38) in set space.
- **Markers added 2026-10-28:** `BoulderStart`, `BoulderEdge`, `CamCliff` (position only; looks at the boulder).
- **Sounds:** swap an id on the matching `Assets/Sounds/Intro/SFX_Intro_*` Sound.

## Measured (2026-10-27, Studio Play)
A temporary client probe (LocalScript in StarterPlayerScripts logging camera cuts, captions, `AnimationPlayed` and markers against the moment the camera went Scriptable) showed every scripted beat within 0.02 s of `IntroConfig`. Total 17.21 s (`EndAt` 17.2), markers Boing 5.02, Touchdown 5.79, Land 8.82, Impact 12.49. Before it: about 4.8 s from client start to the first shot (data load, then the intro's animation load). It averaged 58 fps (998 frames); three hitches of 190-260 ms land in the first 0.5 s, while the set is still being built and streamed in. To retrigger it: admin Reset Tutorial (All), then stop and start Play. A wait script run through `execute_luau` while the intro runs leaves the camera Scriptable afterwards (the tool restores the type it saw at the start), so stop Play after measuring.

Fixed 2026-10-28: the start-up hitches came from the first render of the set at `SetOrigin`. The intro now preloads and warms up the first shot behind the [[Loading Cover]]. Re-measured: 0 hitches, worst intro frame 29 ms, beats unchanged. The probe now times from the `Drive` animation, because the camera goes Scriptable earlier for the warm-up.

## Status
Signed off by the user 2026-10-28 ("intro is done") after playtesting the round-1 feedback, the music, the awe POV shot, the road and the flicker fix.

## Load timeout (2026-10-28)
- The intro sometimes skipped on join. Likely cause (not confirmed by a log): `LoadTimeoutSeconds` was 6 s, and on a cold join the clips can take longer, so it warns "Animations did not load in time" and closes. Raised to 20 s (preload 10 s); the loading cover stays up while it waits. If it still skips, check the client output for that warning.

## Not checked
Round-1 changes not run in Play yet (roll path and its clipping into the cliff lip, `CamCliff` framing, the halves' arc, teleport flicker, sound volumes). Older: timing, shot framing, the car squash, the split on the scaled boulder, the avatar copy (Rthro, layered clothing), the Custom camera keeping the stand facing, touch/phone.

Related: [[Tutorial]], [[Chop Effects]], [[Launch Checklist]]
