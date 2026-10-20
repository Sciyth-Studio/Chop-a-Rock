---
description: 2026-10-20 — first training minigame is Board Slice, a Fruit Ninja-style swipe game drawn as a 2D overlay while training; optional on top of idle reps, slicing builds a server-counted power meter that multiplies strength per rep (draft up to x2); bombs reset it.
type: decision
---
# Training minigame: Board Slice (2026-10-20)

The user asked for games to play at a training stand while strength goes up ([[To Do]], added 2026-10-15). They were going to make a Fruit Ninja clone first, but none existed in the project or their Documents, so on 2026-10-20 they chose to build it fresh in this game. They picked Claude's recommendation on every question:

- **Fresh, themed on the stand:** the pieces that fly up are the player's own stand breakable (board, bricks, steel beam, vault door, energy orb, cosmic cube, by `TrainingTier`), plus bombs. Not plain fruit.
- **Reward = training multiplier:** each slice fills a power meter; strength per rep is multiplied by `1 + Power × (MaxMultiplier − 1)` while the game is open. A missed piece drains some power, a bomb empties it. Closing the game drops the bonus.
- **Optional, on top of idle training:** reps keep coming at the stand's normal pace whether or not you play. While training, a Play button above the training hint opens the game; Close (or stopping training) ends it. AFK players lose nothing.
- **2D screen overlay:** pieces arc across the screen as UI over the 3D view. Swipe with a finger on phones, drag with the mouse held on PC. No gamepad slicing at first, so the Play button hides on gamepad.

## Server authority
The server owns everything that pays. It spawns each wave (piece ids, kinds, launch delays and the arc numbers the client draws) and tracks each piece's launch time. The client only reports "I sliced piece N". The server accepts it once per piece, only if the piece is alive (between `MinSliceSeconds` after launch and `FlightSeconds` + `LatencySlackSeconds`), and only during an open game while training. Pieces that expire unsliced count as misses on the server. The meter and the multiplier are computed on the server and sent to the client for display. A cheating client can at most slice every board and skip every bomb, which is the same as a perfect player and capped at `MaxMultiplier`.

## Draft numbers (`TrainingMinigameConfig`, not approved)
- `MaxMultiplier` 2, `PowerPerSlice` 0.08, `PowerPerMiss` 0.12, bomb empties it.
- A wave every 1.3 s, 1-3 pieces, 12% bomb chance (never a wave of only bombs), first wave 0.8 s after opening.
- Flight 2.4 s, apex 50-85% of the screen height.

## Where it lives
- Server: `TrainingService/Minigame.luau` (sessions passed in; spawn, slice, expire, multiplier), wired from `TrainingService/init.luau`. Stopping training ends the game.
- Client: `UIController/Screens/TrainingMinigame` (folder: `init`, `Pieces`, `Swipe`), StarterGui `TrainingMinigame`; Play button in `TrainingHint`.
- Packets: `TrainingMinigameOpen` (request), `TrainingMinigameClose`, `TrainingMinigameWave`, `TrainingMinigameSlice`, `TrainingMinigamePower`.

## Panel, score and best (user, 2026-10-20)
While playing, the game sits in a house panel that covers the screen, "like a shop", with a **grey header and no icon** (user's words). It is a copy of the Settings panel titled "Board Slice", with its red X as the close button. Inside the body: a `Stats` row (Score left in Chrome, the multiplier and its bar in the middle, Best right in Gold) and the dark `Arena` slot the pieces fly up into.
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
`StarterGui.TrainingMinigame` (IgnoreGuiInset, DisplayOrder 3): `Panel` (see above: `Header` with `CloseButton`, `Stats` with `Score`, `Meter` (`Multiplier` in `Strength` style + `Bar.Fill`) and `Best`, `Arena`, `Tip`), `Playfield` (ZIndex 10, Active so swipes don't turn the camera), `Flash` (ZIndex 20, red bomb flash), `Templates` folder with `Board` (two `HalfLeft`/`HalfRight` frames tagged with the `Tinted` attribute, coloured from `PieceColors` by stand key), `Bomb` (black circle, red stroke, fuse, `Red` "!") and `Trail` (white segment); `PlayButton` (orange block button "Slice!", a copy of the Tutorial Skip button). While playing, `GuiService.TouchControlsEnabled` is off so the thumbstick doesn't eat swipes; it is restored on close. The tutorial hides the screen (`TutorialConfig.HiddenScreens`).

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
