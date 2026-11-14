---
description: 2026-11-11 world boss SFX - 17 SFX_Boss_* sounds (CC0 Freesound recordings, picked and checked with earshot), played by BossSoundController from the WorldBoss model's attributes and animation markers; sources, trims, levels and what is untested.
type: system
---
# Boss sounds

Sound effects for the [[World Bosses]] fight, built 2026-11-11. Claude picked every sound with earshot (96 candidates downloaded with the user's OK, ranked, trimmed, re-checked) and nobody has listened yet. The user tests in Play themselves (2026-11-11: "i could've done the testing"), so Claude did no Play test.

## Code
- `src/client/Controllers/BossSoundController.luau` (registered right after `BossController`) and `src/shared/Config/BossSoundConfig.luau` (keys, marker names, fallback times, roll-off). `BossController` and `BossService` are untouched.
- It watches `WorldBoss`-tagged models: `Phase` (Sleeping loops the snore, Finish loops the dizzy birds, Waking arms the roar, Defeated plays the win sting), `IsMad` false → true (mad roar), `GoldSpot` change during a fight (chime), `Health` drop during a fight (that boss's hit, at most one per 0.07 s, pitch ±6%), `EndsAt` (a tick each second in the last 10 s of a fight phase), and the player's `BossKnockedOut` (knock-out bonk).
- **Markers:** `Animator.AnimationPlayed` on the boss's Animator, matched by `AnimationId` against `Anim_Boss_<Boss>_<Clip>`. Wake `Roar`, Attack / Stomp / BigAttack `Hit` and Defeat `Land` each have a fallback timer (1.7 / 1.5 / 1.0 / 4.0 / 0.9 s), so the sound still plays if markers don't reach the client. The swing starts 0.16 s before the Attack's `Hit` (its peak is 0.11 s in).
- **Where they play:** boss sounds are 3D on the boss's root (InverseTapered, 60 to 420 studs). The chime, tick, win sting and knock-out play 2D, but the first three only when you are within 260 studs of the boss. The poof plays at the boss's last position when the model is removed (after a win or when it leaves).
- Stomp and BigLand are wired to the Stomp and BigAttack clips. The Slam move still plays the `Stomp` clip (`BossConfig.Clips.Slam = "Stomp"`). Since 2026-11-12 the Big Croc doesn't play BigAttack (its Tail Sweep has no jump), so BigLand only fires for the Crab and Yeti. The Tail Sweep plays `SFX_Boss_Swing` from BossAttackController (key `BossFxConfig.Hazards.TailSweep.Sound`).

## Sounds (all CC0 1.0, read on each sound's own Freesound page 2026-11-11)
Studio: `ReplicatedStorage.Assets.Sounds.Boss` (the place must be saved). Files are mono 48 kHz WAVs, trimmed with short fades and peak-normalised to -1.5 dBFS. "Game" = the file's LUFS (RMS for clips under 0.4 s) + Volume, against the [[SFX Audit]] median of -24. z = earshot match for the job's description, then p_real.

| Key | Source (Freesound id, author, title) | Trim (s) | z / p_real | File | Volume | Game |
|---|---|---|---|---|---|---|
| Snore (loop) | 678573 khenshom "Male Snores - Various snores - Close Up" | 0.30-10.60 | 6.01 / 0.98 | -18.5 | 0.33 | -28 |
| Roar (wake) | 467228 VladimirPetrakov "Dragon Roar short" (0.55 s fade-out) | 1.28-2.78 | 5.18 / 0.98 | -8.3 | 0.67 | see Level pass |
| MadRoar | 563684 J.R.Mythical "Dragon Low Roar) mammel growl" | 0.00-3.40 | 5.53 / 0.95 | -8.3 | 0.37 | -17 |
| HitHide (Croc) | 244513 JewTwinz "Realistic Punch" | 0.015-0.33 | 4.59 / 0.87 | -19.6 rms | 0.60 | -24 |
| HitShell (Crab) | 512243 NeoSpica "Rock Smash" | 0.362-0.615 | 4.98 / 0.98 | -15.8 rms | 0.39 | -24 |
| HitFur (Yeti) | 71274 qubodup "Dull Decompression Punch Impact Explodes 96kHz" | 0.091-0.54 | 4.13 / 0.98 | -19.0 | 0.56 | -24 |
| Swing | 475135 bolkmar "FX - Swoosh - Low Pitch" | 0.12-0.62 | 5.12 / 0.86 | -13.9 | 0.39 | -22 |
| Slam (Attack hit) | 813056 AudioPapkin "Big robot footstep" | 0.62-1.90 | 4.05 / 0.92 | -16.3 | 0.65 | -20 |
| Stomp (later) | 721601 DasWaff "Giant step" | 0.97-1.50 | 3.23 / 0.92 | -16.0 | 0.63 | -20 |
| BigLand (later) | 273918 IanStarGem "Huge Impact #2" | 0.00-1.97 | 2.69 plausible / 0.88 | -14.4 | 0.66 | -18 |
| SpotMoved | 211624 qubodup "Magic Wand Glitter" | 16.14-17.18 | 5.04 / 0.93 | -17.9 | 0.39 | -26 |
| Dizzy (loop) | 851731 IENBA "Little Bird Tweeting" | 0.95-6.45 | 5.36 / 0.81 | -12.4 | 0.17 | -28 |
| KnockOut | 466202 Harrisando "Bonk" (ffmpeg `adeclip`) | 0.15-1.00 | 3.60 / 0.97 | -18.7 | 0.77 | -21 |
| Tick | 534094 pbimal "clock-tick-01" | 0.00-0.45 | 4.05 / 0.41 uncertain | -18.4 | 0.33 | -28 |
| Thud (defeat) | 504626 leonelmail "BODY FALL - V HVY - DIRT" | 0.35-1.42 | 4.23 / 0.97 | -22.5 | 1.33 | -20 |
| Poof | 387834 ryansitz "Poof" | 0.40-1.20 | 4.95 / 0.90 | -21.1 | 0.72 | -24 |
| Win | 456966 FunWithSound "Success Fanfare Trumpets" (0.35 s fade-out) | 0.25-3.40 | 3.65 / 0.81 | -11.5 | 0.38 | -20 |

Asset ids (Audio, group 10962733): BigLand 129283746010715, Dizzy 102107863446499, HitFur 108300655047745, HitHide 135227866992835, HitShell 124945382488444, KnockOut 83714797596525, MadRoar 95478796896413, Poof 100157580015972, Roar 120700454579102 (was 74229973144614), Slam 134635973636663, Snore 78431697247615, SpotMoved 118730272119678, Stomp 110835278230650, Swing 119232388151167, Thud 133517827356729, Tick 125035981459075, Win 102438607635518. All 17 were Approved and loaded in Studio (lengths matching the trims) by the end of 2026-11-11.

## Round 2 (2026-11-11, after the user's Play test)
The user: "the winning fanfare sound effect is kinda lame, so is the hit sfx (sounds like slapping a wet puddle)". 41 more CC0 previews were downloaded with the user's OK (15 stings, 26 impacts).
- **Hits:** each trim was scored for "a heavy dry punch thwack, a chunky crunchy impact hit" and against wet words ("a wet squelch", "a wet slap on skin", "a splash of water", "a hand slapping skin"; below z 2 means no match). The old hits backed the complaint: HitFur read squelch z 2.70 and water z 2.65, HitHide's top wet z was 2.14 and HitShell's 1.43. The new trims' top wet z is 0.92 (HitHide), 1.90 squelch (HitShell) and 0.91 (HitFur). Every ice-crack candidate read wet (squelch z 2.68-3.29), so the Yeti now uses a dull padded punch rather than ice. Old hits: 586841 Kinoton (Croc), 567701 Nox_Sound (Crab), 719169 InMotionAudio (Yeti).
- **Win:** scored for "a big triumphant orchestral brass fanfare" and against "a cheap 8-bit chiptune jingle". The old RPG fanfare (607407) scored brass z 3.13 and chiptune z 2.18. The new trumpets score brass 3.65 and chiptune 1.36, the lowest chiptune reading of the 15. plasterbrain's "Tada Fanfare" A/G/F (397355/3/4) scored about the same (brass 3.85-3.97) but are only 1.7 s long. A one-word earshot query can't measure "punchier"; the user's ears decide.

## Level pass (2026-11-11, after "a lot of the boss sfx are too quiet in fights")
The table's Volume and Game columns are from before this pass. Levels below are the loudest 100 ms of each file plus its Volume in dB (dBFS, unweighted; peak = sample peak + Volume). They were measured from the uploaded files and from Asset Delivery downloads, not heard. The boss fight music (Last Man Standing 0.27, Edge Of Extinction 0.33) has a median 100 ms level of -20.8 / -20.1, with a 90th percentile of -17.9 / -18.3. For comparison: Chop -15.3, Chop_Master -9.9, Rock_Break -9.3, Train_Vault -13.9, Enemy_Hit -21.3.

| Sound | Volume | Level (dB) | Peak (dBFS) |
|---|---|---|---|
| Roar | 0.62 → 0.95 (new file: 0.67) | -13.8 → -10.1 | -2.0 (new file: -2.0) |
| MadRoar | 0.37 → 0.74 | -17.8 → -11.8 | -4.1 |
| Slam | 0.65 → 1.04 | -13.6 → -9.5 | -1.1 |
| BigLand | 0.66 → 1.01 | -14.3 → -10.6 | -1.4 |
| Win | 0.38 → 1.06 | -21.6 → -12.7 | -1.0 |
| Stomp | 0.63 → 1.06 | -15.6 → -11.1 | -1.0 |
| Thud | 1.33 → 1.06 | -13.0 → -14.9 | +1.0 → -1.0 (was clipping) |
| KnockOut | 0.77 → 1.06 | -17.0 → -14.3 | -1.0 |
| HitHide | 0.60 → 1.05 | -19.1 → -14.2 | -1.0 |
| HitShell | 0.39 → 1.06 | -20.5 → -11.9 | -1.0 |
| HitFur | 0.56 → 1.05 | -19.9 → -14.5 | -1.0 |
| Swing | 0.39 → 1.06 | -17.6 → -9.0 | -1.0 |
| Poof | 0.72 → 1.06 | -15.0 → -11.7 | -1.0 |
| SpotMoved | 0.39 → 1.06 | -21.3 → -12.7 | -1.0 |
| Tick | 0.33 → 1.06 | -26.0 → -15.9 | -1.0 |
| Snore (loop) | 0.33 → 0.55 | -20.9 → -16.5 | -6.7 |
| Dizzy (loop) | 0.17 → 0.56 | -25.3 → -14.9 | -6.5 |

- Before this pass the hits sat at or under the music's 90th percentile. Now every boss sound is 5-11 dB over the music's median, and the hits are level with or louder than a normal chop.
- Files are peak-normalised to -1.5 dBFS, so about Volume 1.06 is the ceiling before the peak passes -1 dBFS. Twelve sounds sit at that ceiling. A 6 dB limiter test on the capped ones gained only +1.3 to +4.6 dB (hits +1.3 to +2.6) and would blunt the punch, so it wasn't uploaded. If the hits are still too quiet, the next levers are ducking the boss music 3-4 dB during fights (MusicController, the boss-music session's area), or a limited re-upload.
- Each changed Sound keeps its old value in the attribute `LevelOldVolume`.
- `BossSoundConfig` roll-off went from 60/420 to 100/500 studs, so the whole fight area (Stomp circles 45-96 studs out) hears full level. Before, a player 96 studs from the boss lost about 4 dB.

## Picking notes
- **Roars:** almost every roar's closest vocabulary match was "a cow mooing" (the same problem as `SFX_Enemy_Roar`). Claude kept the trims with the highest roar z and the lowest cow z: the wake roar has a cow z of 2.6, the mad roar 1.83. A lion roar (559600) scored a roar z of 5.68 but a cow z of 3.45. Demon Lion (469123) had 40 clipped samples.
- **Bank vs recordings:** earshot's bank chimes and stings read as code-synthesized (p_real ≤ 0.25) and matched worse (bank sting z ≤ 0.6). The best bank whoosh scored z 4.98 against bolkmar's 5.25, so recordings won every role.
- **Weak spots:** Tick realness is uncertain (0.41), though it matches strongly as a clock tick. BigLand is only plausible, with a noisy floor (-21 dB). The Bonk had 24 clipped samples, which `adeclip` repaired (0 after). Round 1's hits were replaced in round 2 (below).
- The work files (downloads, trims, scripts) are in that session's scratchpad, not in the repo.

## To check in Play (user)
`boss BigCroc`, wait for the snore, then `bosswake` (roar near the jaw opening), chop (hide hits), wait for a Block round (swing, then slam on the hit), `bosshit` twice (mad roar), `bosshit` more for Finish it (birds) and the win (thud, poof, fanfare), `bossend` for the ticks; repeat with BoulderCrab and FrostYeti for their hits. Not checked: whether the markers reach the client (fallback timers cover it), and how the levels sit against the boss music.

Related: [[World Bosses]], [[Block Rounds]], [[SFX Audit]], [[Open Cloud Key]]

## Longer wake roar (2026-11-11)
The user picked a longer roar over trimming the old one ("a longer roar makes more sense"). The Wake clips hold the jaw open for 0.83 s (Croc, Roar 1.67 to 2.50, closed by 3.00), 0.66 s (Crab claws, 1.67 to 2.33, down by 2.92) and 0.75 s (Yeti, 1.75 to 2.50, closed by 3.08). The old roar (170454) was silent for its first 0.15 s and stayed loud for only 0.5 s. The new one, 467228 VladimirPetrakov "Dragon Roar short" (CC0, from the round 1 downloads), trimmed 1.28 to 2.78 with a 0.55 s fade:
- It reaches -14 dB 0.15 s after the marker, stays loud from about 0.1 to 0.9 s, and fades out from 0.9 to 1.5 s while the jaw closes.
- earshot gives it a roar z of 5.18 (old 5.88), a cow z of 2.74 (old 2.87, so still "plausible cow") and p_real 0.98.
- Trims later in the same recording scored a lower cow z (1.41 at 2.10 to 3.60), but they start mid-roar and peak 1.2 s in, after the jaw has closed.
- Volume is 0.67, giving -10.1 dB at its loudest 100 ms (the Level pass target). The old SoundId is in the attribute `OldSoundId`.
- New asset 120700454579102 was "Reviewing" when it was set, and the roar is silent in game until Roblox approves it.

## Louder Slam and signature moves (2026-11-12)
The user: Stomp (the crab's move, being renamed "Slam" by the boss-abilities session) was "nowhere near loud enough", and the signature moves had no sounds. 19 more CC0 previews were downloaded with the user's OK; every licence was read on its own page. Scores are earshot z for the query and the top confusion (below 2 = no match).

| Sound | Source (CC0) | Build | z / top alt | p_real | Volume | Level (dB, 100 ms + Volume) |
|---|---|---|---|---|---|---|
| Stomp (Slam move) | 502553 "goblin-fall" 0.10-1.21 + 457531 Breviceps "Dinosaur falls to the ground" 2.98-3.69 (-3 dB) + 502553 lowpassed at 110 Hz (-2 dB) | onsets aligned, 7 dB into a peak limiter | "a huge heavy ground slam..." 6.59 (old file 3.74) / cardboard box thump 3.72, distortion 0.61 | 0.98 | 1.06 | -6.9 (old -11.1); Slam (Attack) is -9.5, Roar -10.1 |
| Chomp (Big Croc) | 830093 Wigglesworth "Jaw or teeth bite at air" 6.78-6.98 + 502553 0.10-0.45 lowpassed at 200 Hz (-15 dB) | 8 dB limiter, 0.33 s | "a hard bite, a jaw snapping closed" 2.63 plausible / wooden block hit 3.81 | 0.85 | 1.06 | -16.7 |
| ShellHide (Boulder Crab) | 758583 magnuswaker "Rubble Trouble (wet reverb)" 0.00-1.27 | 2 dB limiter | "a heavy stone grinding and clunking shut..." 4.89 / explosion 2.20, wet splat 1.05 | 0.89 | 0.80 | -10.9 |
| Frost (Frost Yeti) | 723875 lori.mortimer "Freeze" 5.70-6.91, highpassed at 900 Hz | 8 dB limiter | "ice crackling and freezing over..." 3.42, ice cracking 4.16, top tag ice cubes in a glass 4.47 / squishy wet squelch 2.75, wet squelch 2.12 | 0.95 | 1.06 | -18.3 |

- Asset ids: Stomp 136589548109477 (was 110835278230650, kept in `OldSoundId`), Chomp 74873402796109, ShellHide 133939143603475, Frost 83258292622251. All four were "Reviewing" when set.
- Keys: `BossSoundConfig.Chomp / ShellHide / Frost`, AssetRegistry `SFX_Boss_Chomp / ShellHide / Frost`. The ChopBar overlay (`BossOverlays.luau`, owned by the boss-ui session) plays them with `LocalSound.Play` as each signature effect shows; Chomp on every jaw close. Stomp still plays from BossSoundController on the `Anim_Boss_<Boss>_Stomp` clip's `Hit` marker; if the clip is renamed to Slam, update the clip list in BossSoundController.
- **Weak spots:** the Chomp is only plausible: the snap alone (0.09 s) read as a snare / wooden block (z 1.96), and a louder body layer made it read as a punch (z 2.11). Every ice recording reads somewhat wet (452645 was the strongest for frost at z 4.2-5.0 but squishy squelch 3.0-4.4); 723875 was the least wet. Limiting raised the wet reading slightly.
