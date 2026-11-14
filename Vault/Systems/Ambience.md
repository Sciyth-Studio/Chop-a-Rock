---
description: 2026-11-11 zone ambience - a quiet looping 2D bed per zone from the drop-in folder Assets.Ambience (Sound named after the zone), crossfaded 2 s on zone change by AmbienceController; all ten zones sourced (CC0 Freesound, earshot-picked), not yet heard.
type: system
---
# Ambience

Built 2026-11-11 from the [[VFX SFX Coverage Audit]] (the game had no ambience at all). The user chose "Forest only first": build the system with one loop, listen, then source the other nine.

## How it works
- **Drop-in folder** ([[Drop In Assets Over Ids In Code]]): `ReplicatedStorage.Assets.Ambience` (in `default.project.json` with `$ignoreUnknownInstances`). Each Sound is named after its zone (`Forest`, `Desert`, ...); its own `Volume` is the level. A zone with no Sound is silent, and so are the lobby and the boss arena (no zone).
- `src/client/Controllers/AmbienceController.luau` polls the local character every 0.5 s with `Utils/ZoneAt` (the Z-only `RockSpawnArea` lookup, moved out of `ZonePresenceService` so both use it). On a change it fades the old bed out and the new one in over 2 s (`AmbienceConfig`). The clone plays 2D from `SoundService`, looped, in the `SoundEffects` group, so the SFX toggle and master Volume control it.
- Planned beds (user approved the list 2026-11-11): Desert dry wind, Jungle insects + tropical birds, Ocean shore waves + odd gull, Snow soft cold wind, Swamp frogs + crickets, Savanna grassland wind + insects, Bamboo rustling bamboo + trickling stream, Volcano low rumble + bubbling lava, Ruins hollow wind + cave drips.

## Forest loop
- Source: Freesound 856018, newlocknew, "AMBForst_Late Spring. A Quiet Forest Edge. Hot. Sunny" (CC0 1.0, read on its page 2026-11-11). Five CC0 candidates were ranked with earshot for "a calm sunny forest with birds singing and a gentle breeze"; this one won (z 4.1, forest ambience 3.5) and none read as traffic or voices.
- Made: 100-163 s, 120 Hz high-pass (the original had heavy sub rumble), the last 3 s crossfaded into the first 3 s so it loops cleanly, stereo narrowed (`extrastereo 0.4`) because the original was partly out of phase (correlation -0.43, now +0.43), loudness-normalised to -18 LUFS, OGG.
- Asset 101415027011210 (Audio, group 10962733), Volume 0.16, so about -34 LUFS in game, 10 dB under the [[SFX Audit]] median. It was "Reviewing" at upload and won't play until approved. Measured, not heard.
- `Assets.Ambience.Forest` was made in Studio, so **the place must be saved**.

## The other nine (2026-11-11, user: "Yes, do all nine")
Six CC0 candidates per zone (52 previews, ~220 MB) were searched on Freesound, ranked with earshot for the zone's description, checked against "footsteps, people talking, traffic, music" (none matched), and each licence read on its page. Same processing as Forest (63 s window, 3 s crossfade loop, high-pass, -18 LUFS, OGG) via the scratchpad script `make_loop.sh`. Volume = what puts the file at -34 LUFS in game. All uploaded under group 10962733 and "Reviewing" at upload. Measured, not heard.

| Zone | Source (Freesound id, author, title) | Cut | z | Asset | Volume |
|---|---|---|---|---|---|
| Desert | 156414 felix.blume "Wind blowing into some cactus spine... Atacama" | 5-68 s, HP 80 | 4.6 | 85624250155472 | 0.176 |
| Jungle | 479573 craigsmith "R25-01 Big Jungle Ambience" | 45-108, HP 120 | 4.8 | 81464157055793 | 0.166 |
| Ocean | 872757 Anya_Media "CU of waves on beach, distant ocean roar" | 2-65, HP 50 | 5.4 | 82175176303329 | 0.153 |
| Snow | 454213 kyles "swirling winter wind gusty grains sand" | 35-98, HP 80 | 3.4 | 79927139421230 | 0.132 |
| Swamp | 32655 greysound "FrogsAndCrickets ExcerptB" | 12-75, HP 100 | 7.4 | 84465657555486 | 0.164 |
| Savanna | 164656 DanGasior "meadow insects sunny afternoon" | 35-98, HP 120 | 4.3 | 86877524763920 | 0.188 |
| Bamboo | 404688 indieground "Bamboo forest" 190-247 + 559955 Cinetony "Small stream in forest" at -16 dB | 54 s loop, HP 100 | 3.2 | 123564325159887 | 0.174 |
| Volcano | 415608 RTB45 "Mud Volcano Field - Salton Sea" 125-164 + 474852 Fission9 "Lava Loop 4" low-passed 250 Hz at -4 dB | 36 s loop, HP 20 | 5.6 | 96128030546135 | 0.164 |
| Ruins | 177958 Sclolex "Water Dripping in Cave" | 5-68, HP 60 | 5.3 | 99191302389203 | 0.327 |

Caveats for the listen:
- **Bamboo** is the weakest match: the bamboo recording is dense rustling and the mix still reads a little like rain (z 3.0). With the stream at -9 dB it read as heavy rain, so the stream is at -16 dB.
- **Volcano** reads as thick bubbling/boiling (z 6.2); the rumble layer is quiet under it.
- **Desert** wind dips about 4.6 dB over the loop seam (the gusts vary); others dip 0.6-2 dB.
- **Ruins** is sparse drips with quiet between them, so its integrated loudness is -24 LUFS and its Volume is higher (0.327).
- Stereo phase is at or above 0 for all (no mono cancellation). Jungle is mono.

Related: [[Settings]], [[Zone Banner]]
