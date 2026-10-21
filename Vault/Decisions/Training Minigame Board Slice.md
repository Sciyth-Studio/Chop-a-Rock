---
description: 2026-10-20 — first training minigame is Board Slice, a Fruit Ninja-style swipe game drawn as a 2D overlay while training; optional on top of idle reps, each server-accepted slice adds bonus strength (draft 0.5 rep, about 1.5x training for a typical player) since 2026-10-20; bombs reset the score.
type: decision
---
# Training minigame: Board Slice (2026-10-20)

The user asked for games to play at a training stand while strength goes up ([[To Do]], added 2026-10-15). They were going to make a Fruit Ninja clone first, but none existed in the project or their Documents, so on 2026-10-20 they chose to build it fresh in this game. They picked Claude's recommendation on every question:

- **Fresh, themed on the stand:** the pieces that fly up are the player's own stand breakable (board, bricks, steel beam, vault door, energy orb, cosmic cube, by `TrainingTier`), plus bombs. Not plain fruit.
- **Reward = training multiplier (first build, replaced below):** each slice filled a power meter; strength per rep is multiplied by `1 + Power × (MaxMultiplier − 1)` while the game is open. A missed piece drains some power, a bomb empties it. Closing the game drops the bonus.
- **Changed 2026-10-20 (user): bonus strength, not a multiplier.** "Successful chops should provide bonus strength (balance so it averages around 1.5x training speed)." The power meter, multiplier and miss penalty are gone. Each board slice the server accepts adds `BonusRepsPerSlice` (0.5, draft) reps of strength (stand per-rep × aura), with the same carry as idle reps, and a "+N N" pop shows where it was sliced. The maths: a wave every 1.3 s of 1-3 pieces with 12% bombs is about 1.37 boards/s; a typical player who slices ~75% gets ~1.03 × 0.5 ≈ 0.5 extra reps/s, so ~1.5x; a perfect player gets ~1.68x. Not measured in play yet (the user is testing). Bombs still reset the score.
- **Optional, on top of idle training:** reps keep coming at the stand's normal pace whether or not you play. While training, a Play button above the training hint opens the game; Close (or stopping training) ends it. AFK players lose nothing.
- **2D screen overlay:** pieces arc across the screen as UI over the 3D view. Swipe with a finger on phones, drag with the mouse held on PC. No gamepad slicing at first, so the Play button hides on gamepad.

## In the balance model (v8, 2026-10-20)
[[Balance Model]] v8 models Board Slice on Inputs rows 88-99. From the config that's 1.81 boards per wave and 1.39 boards/s, so x1.52 training at 75% sliced and x1.69 perfect, for a player who plays the whole time they train. Against the training targets (1 / 3 / 5 / 7 / 10 min, ±25%), every zone fails "too fast": 0.7 / 2.2 / 3.4 / 4.3 / 7.1 min. The Ocean is the tightest: full-time play stays inside the targets only up to about x1.23 (about 0.22 reps per slice, or playing about 45% of the time).
- **Decided 2026-10-20 (user): the training targets are for idle players.** "Board Slice is a reward for skill, so faster is fine. Keep the stands as they are." The stands and `BonusRepsPerSlice` stay as they are. The model's Board Slice check now fails only if a minigame player is slower than the target.

## Server authority
The server owns everything that pays. It spawns each wave (piece ids, kinds, launch delays and the arc numbers the client draws) and tracks each piece's launch time. The client only reports "I sliced piece N". The server accepts it once per piece, only if the piece is alive (between `MinSliceSeconds` after launch and `FlightSeconds` + `LatencySlackSeconds`), and only during an open game while training. The bonus and the score are computed on the server and sent with `TrainingMinigameScore` (score, gain). A cheating client can at most slice every board and skip every bomb, the same as a perfect player (~1.68x).

## Draft numbers (`TrainingMinigameConfig`, not approved)
- `BonusRepsPerSlice` 0.5 (the multiplier numbers were removed 2026-10-20).
- A wave every 1.3 s, 1-3 pieces, 12% bomb chance (never a wave of only bombs), first wave 0.8 s after opening.
- Flight 2.4 s, apex 50-85% of the screen height.

## Where it lives
- Server: `TrainingService/Minigame.luau` (sessions passed in; spawn, slice, expire, score), wired from `TrainingService/init.luau`. Stopping training ends the game.
- Client: `UIController/Screens/TrainingMinigame` (folder: `init`, `Pieces`, `Swipe`), StarterGui `TrainingMinigame`; Play button in `TrainingHint`.
- Packets: `TrainingMinigameOpen` (request), `TrainingMinigameClose`, `TrainingMinigameWave`, `TrainingMinigameSlice`, `TrainingMinigamePower`.

## Panel, score and best (user, 2026-10-20)
While playing, the game sits in a house panel that covers the screen, "like a shop", with a **grey header and no icon** (user's words). It is a copy of the Settings panel titled "Board Slice", with its red X as the close button. Inside the body: a `Stats` row (Score left in Chrome, the multiplier and its bar in the middle until round 3, now Strength; Best right in Gold) and the dark `Arena` slot the pieces fly up into.
- **Score** (approved by the user 2026-10-20): boards sliced since you opened the game or last hit a bomb. A bomb resets it to 0; misses don't. The server counts it and sends it with the power.
- **Best** is saved in `PlayerData.TrainingMinigameBest` (server-set when the score passes it), shown through `DataController:Observe`.
- The panel is sized in code to `PanelScreenWidth` 0.94 × `PanelScreenHeight` 0.96 of the screen below Roblox's top bar, divided by its `ScreenScale`, so it covers the Teleport Bar (at 0.9 the bar peeked over the header). Each frame `Playfield` (a sibling above the panel, not a child, so piece offsets aren't scaled twice) is moved onto `Arena`'s on-screen rect. `Playfield.ClipsDescendants` is on, so pieces rise from the arena's bottom edge.

## Sounds (user's files, 2026-10-20)
The user sent nine WAVs ("new sfx"). Copies are in `assets/Sounds/TrainingMinigame/` with their ids in `assets.json`. They were uploaded through Open Cloud as `assetType` **Audio** (file part `audio/wav`) under group 10962733, the first audio sent this way, and all loaded in Studio. The Sounds are in `ReplicatedStorage.Assets.Sounds.Slice` at Volume 0.5 and registered in `AssetRegistry`, so they join the SoundEffects group.
- `SFX_Slice_Swipe1-6` (Sword-swipe 1, 2, 3, 4, 5, 7): a random one per stroke, after `SwipeSoundPixels` 140 of movement and at most every `SwipeSoundCooldownSeconds` 0.15. Claude's default for how often they play.
- `SFX_Slice_ThrowBoard` / `SFX_Slice_ThrowBomb` (Throw-fruit / Throw-bomb): when each piece launches.
- `SFX_Slice_Fuse` (Bomb-Fuse, 6.2 s, Looped): one looping Sound in SoundService while any bomb is in the air, destroyed when the game closes.
- The slice hit (`SFX_Chop_Good`) and the bomb hit (`SFX_Rock_Break`) are still the old placeholders. The user sent no slice or explosion sound.

## Studio layout (built 2026-10-20 through the MCP; not in git)
`StarterGui.TrainingMinigame` (IgnoreGuiInset, DisplayOrder 3): `Panel` (see above: `Header` with `CloseButton`, `Stats` with `Score`, `Strength` and `Best`, `Arena`, `Tip`), `Playfield` (ZIndex 10, Active so swipes don't turn the camera), `Flash` (ZIndex 20, red bomb flash), `Templates` folder with `Board` (two `HalfLeft`/`HalfRight` frames tagged with the `Tinted` attribute, coloured from `PieceColors` by stand key), `Bomb` (icon + red outline copies, see Round 3), `Trail`, `Slash`, `Shard` and `Gain`; `PlayButton` (red block button "Play!", a copy of the Tutorial Skip button). While playing, `GuiService.TouchControlsEnabled` is off so the thumbstick doesn't eat swipes; it is restored on close. The tutorial hides the screen (`TutorialConfig.HiddenScreens`).

## Checked in Play 2026-10-20 (by value, not seen on screen)
- Train prompt → Slice! button shows; a real mouse click on it starts the game; pieces launch, arc and spin.
- A real mouse drag across the screen drew trail segments and sliced a board into two halves; the tip hid after the first slice.
- Server gain per rep on a Wood stand with an aura: 31 idle, 62-63 at x2 power, drains back as pieces are missed; Close puts it back to 31.
- Rejected by the server: an unknown id, a slice reported before the piece launched, the second report of the same piece. A bomb took power from 0.12 to 0.
- Space stops training, closes the game and restores walk speed and jump. No warnings from the screen.
- Panel pass (2026-10-20, seen in Play screenshots): grey header "Board Slice" with the red X, Score / multiplier bar / Best inside, brick-coloured pieces in the arena, panel covering the Teleport Bar. A real drag scored 1. Score climbed 0-6 with server-accepted slices, Best saved 6 and still showed 6 after restarting Play.
- Sounds pass (2026-10-20, by value): the fuse was playing exactly while a bomb was on screen in 60 of 60 samples over 15 s, it is in the SoundEffects group, and the red X closed the game and removed it. No AssetRegistry warnings for the new keys.
- **Not checked:** how the sounds actually sound and how often swipes play (nothing was heard), clipping at the arena's bottom edge on screen, phone swipes (touch) and the phone panel size, the bomb flash, the gamepad hide, and multiple players.

Related: [[Rebirth Gated By Strength]], [[Training Stand Reference]], [[Tutorial]], [[Movement Lock]]

## Round 3 (user, 2026-10-20)
- **Play! button:** the entry button reads "Play!" and is painted red (BlockButton edge 230,0,0, centre 255,130,130, studs 140,0,0, the house red of the `Red` text style).
- **Strength in the panel:** the middle of `Stats` is now `Strength` (Strength style, `NumberFormat.Compact` + "N", like the HUD), replacing the multiplier and bar.
- **Slash trail in the aura colour:** each stroke is a tapered two-layer trail (aura-coloured glow 28 px at 0.35 transparency over a white 9 px core) that fades out over 0.22 s, drawn from pooled `Templates.Trail` clones (`Swipe.luau`). The colour is `AuraConfig.Tiers[AuraTier].Color`, or `DefaultSlashColor` white for the colourless "No Aura" tier (user, 2026-10-20; was cyan). A slice adds an aura-coloured slash streak along the swipe (`Templates.Slash` with a white `Core`, both with an ends-transparent gradient) and six piece-coloured `Shard` squares (`Effects.luau`). Sizes were raised once after a Play screenshot showed the shards as dots.
- **Bomb icon:** the user's "Bomb 1st 256px" icon from the Free Icon Pack, uploaded as Image under the group (`rbxassetid://90145766680159`, copy in `assets/Icons/SliceBomb/`). `Templates.Bomb` is that icon over eight red copies offset 3 px (the `IconOutline` trick) for a red stroke. A UIStroke would outline the box, not the bomb.
- Seen in a Play screenshot: the red Play! button, the strength in the panel, the trail (cyan on a save without an aura colour). The user said "ill do testing", so the bonus rate, the slash streak, the bomb icon and the gain pop were not checked by Claude.
- Bomb doubled in size (user, 2026-10-20): `BombSizeShortSide` 0.13 → 0.26 of the arena short side; the hit radius grows with it.
