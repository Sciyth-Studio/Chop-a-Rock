---
description: World boss fight music (built 2026-11-11, WorldBossPlan 4.2) - a looped fight track near the Boss Arena from the wake roar, +2 semitones when mad, a sting on Finish it, back to the normal playlist on Defeated or Leaving; drop-in folders Music.BossFight and Music.BossFinish.
type: system
---
# Boss music

Built 2026-11-11 for [[World Bosses]] (`WorldBossPlan.md` 4.2). Client only: `MusicController/Boss.luau`, started from `MusicController.Start`. It reads only the replicated `Workspace.WorldBoss` attributes (`Phase`, `IsMad` from `BossConfig`), so `BossService` and `BossController` were not touched.

## What it does
- **Plays** while the boss's `Phase` is Fighting 3, Mad 4 or Finish 5 **and** the player is near the arena: character root (or camera focus) inside x -132 to 216, z -781 to -433 (`MusicConfig.BossHearMin/Max`: the arena's inside plus 30 studs, so the gateway end of the lobby counts). Checked every 0.5 s and on every phase change. So it starts on the wake roar (2 → 3), and someone who walks in mid-fight hears it too. Everyone else keeps the playlist.
- While it plays, the playlist is held with `MusicController:Hold()` (fades out and pauses, resumes on release). The fight track is a random pick from the folder, looped, in the `Music` SoundGroup (so the Settings Music toggle mutes it), fading in over 0.5 s.
- **Mad:** when `IsMad` turns true, `PlaybackSpeed` tweens to 2^(2/12) = 1.122 over 0.4 s (tempo rises too), the same way as the Guardian fight in [[Zone Enemies]]. Joining late on a mad boss starts at 1.122.
- **Finish it:** on the change into Phase 5 a sting plays once over the loop, and the loop ducks to 35% for 6 s, then comes back over 1 s. Only for players who are hearing the fight track.
- **End:** Defeated 6, Leaving 7, the model being removed, or walking away fades the fight track out over 1.5 s and releases the hold, so the normal music comes back.

## Diamond Rock (2026-11-11)
The user: "diamond rock is technically a boss so it should have a lot of the same stuff as the rest of them". The [[Diamond Rock]] has its own `BossFight/DiamondRock` track (see Tracks), on the same rules:
- Plays for players near the arena from the moment `Workspace.DiamondRock` appears until the model is removed (broken or timed out).
- At 25% health or less (`DiamondRockConfig.LowHealthRatio`, the same point as its crumble look) the track rises 2 semitones over 0.4 s. It reads `Health` / `MaxHealth` on the model's part that carries `MaxHealth` (the `Rock` part).
- No sting: the rock has no "Finish it!" step.
- Not playtested yet (the user tests in Play).

## Tracks (Studio only, `ReplicatedStorage.Assets.Music`, see [[Drop In Assets Over Ids In Code]])
The playlist only reads Sounds sitting directly in `Music`, so these subfolders are ignored by it. All are Roblox licensed library, no upload needed.

**One track per boss (the user's picks, 2026-11-11).** Each Sound in `BossFight` is named after its boss key: the `Boss` attribute on `Workspace.WorldBoss` (the `BossConfig.Bosses` key), or `DiamondRock` for the [[Diamond Rock]]. `Boss.luau` plays the Sound with that name, and falls back to a random one from the folder if none matches (so a new boss needs a Sound named after its key). If a boss and a rock are out at once, the boss's track wins.
- `BossFight/BigCroc`: "Furious Squad" (1839366348, 64.8 s), -8.2 LUFS, Volume 0.28
- `BossFight/BoulderCrab`: "Dangerous Pirate" (1836272569, 87.5 s), -11.9 LUFS, Volume 0.43
- `BossFight/FrostYeti`: "Sword Fight" (1836334472, 168.0 s), -19.6 LUFS, Volume 1.03
  - **Replaced by the user 2026-11-12** with 9042697552 (60.06 s, about 113.3 BPM, F minor, fades out from 57.5 s). Claude set `PlaybackRegionsEnabled` and `LoopRegion` 2.1227-52.9583 s on the Sound in Studio: the intro bar plays once, then 24 bars (three 8-bar phrases) loop, ending before the fade. The seam was picked by spectral match between the loop's first bar and bars 20-26 (bar 25 won at 0.79) and trimmed to the smallest waveform jump; level holds across it. `Boss.luau` clones the Sound, so the region carries over with no code. Measured, not heard. Any new fight track that fades needs its own region.
- `BossFight/DiamondRock`: "Mystical Nature" (1839883317, 111.5 s), -13.7 LUFS, Volume 0.52
- `BossFinish/Battle Approach Sting` (1837950851, 7.6 s), Volume 0.35.

**Levelled 2026-11-11 (earshot measure):** Volume = 10^((-19.3 - LUFS) / 20), so each track plays at about -19.3 LUFS. That is the level the Guardian's "Fight" sits at (-11.3 LUFS at Volume 0.4), and the level of the first picks. The playlist at 0.5 plays at about -16 to -19 (Prima Bossa Nova -10.2 LUFS, No More -12.6), so the fight music sits at or a little under it. Furious Squad has clipping baked into the file (true peak +1.9 dBTP, 1,369 clipped samples), and turning it down does not remove that. If the user wants it gone, the fix is a different track.

**Replaced:** the first picks, `Last Man Standing` (9045953477, Volume 0.27) and `Edge Of Extinction` (9043171470, Volume 0.33), shared by every boss. The earshot notes below are about those two and the sting.

earshot (2026-11-11) against "energetic upbeat orchestral video game boss battle music with driving drums and brass": Last Man Standing z +3.36 strong, Edge Of Extinction z +3.31 strong (both read as "epic trailer music" z +3.2). Neither reads as scary: "dark scary horror music" z +1.23 and +1.48 (no match). Rejected: Rage Mode (z +3.82 but reads as techno, z +3.3), Judgement Day (z +3.33, weak "dark" z +2.0, 4,999 clipped samples), and the Guardian's own "Fight" (z +2.64). Loudness: -8.0 and -9.7 LUFS; volumes are set so each lands near the Guardian's "Fight" (-11.3 LUFS at Volume 0.4). The sting: "a short heroic orchestral brass fanfare sting with a big drum hit" z +3.92, mood "triumphant and heroic" z +3.86, -8.2 LUFS. Nobody has listened to them yet.

## Playtest (Claude, 2026-11-11, one player in the arena)
`boss BigCroc`, `bosswake`: fight track on at Phase 3, playlist paused. Teleported to the lobby (z -330): fight track gone, playlist back at 0.5; back in: fight track again. `bosshit` twice: Mad, PlaybackSpeed 1.000 → 1.122 in about 0.4 s. More `bosshit`: Defeated, track fades out, playlist plays. `bossend`: Leaving, same. **Finish was only tested by setting `Phase` to 5 on the client** (the admin -25% hit jumps from 25% straight to 0, so a real Finish needs chops): the sting played and the loop ducked to 0.09-0.10 and came back to 0.27.

Related: [[World Bosses]], [[Boss Arena]], [[Zone Enemies]], [[Settings]]
