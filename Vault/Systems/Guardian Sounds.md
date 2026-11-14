---
description: 2026-11-11 each zone Guardian (egg fight enemy) has its own Call on fight start and Hurt on each Good+ hit - 20 SFX_Guardian_<Pet>_Call/Hurt sounds, CC0 Freesound, earshot-picked; ids, sources, levels; not yet heard in Play.
type: system
---
# Guardian sounds (2026-11-11)

The user asked for "sfx for the fights for each egg" and chose **own voice per Guardian**: each [[Zone Enemies]] Guardian gets a Call (replaces the shared cow-like `SFX_Enemy_Roar` at fight start) and a Hurt (on each Good or better chop, on top of `SFX_Enemy_Hit`). Hit, miss, win, lose and tick stay shared. Nobody has listened yet; the user tests in Play.

## Code
- `EnemyConfig.GuardianCallFormat` / `GuardianHurtFormat` (`SFX_Guardian_%s_Call` / `_Hurt`), filled with `EnemyConfig.PetKeys[zone]`, so zones 6-10 already use their own animal (Frog, Zebra...) even while their model is the Bunny fallback.
- `EnemyController/Audio.Guardian(zone, format, fallbackKey)`; a zone missing from `PetKeys` plays the old roar. Called in `onFightStarted` and `onChopResult`.
- 20 keys in `AssetRegistry`. Sounds in Studio: `ReplicatedStorage.Assets.Sounds.Enemy.Guardians` (save the place).

## Sounds (all CC0 1.0, confirmed on each Freesound page)
Files: mono 48 kHz, short fades, peak-normalised to -1.5 dBFS; the quiet ones got +6 dB into a limiter. Volume aims the loudest 100 ms at -13 dB (Call) / -15 dB (Hurt), capped at 1.06. z = earshot match on the final file.

| Guardian | Call: source, trim | z | Hurt: source, trim | z | Call id / Hurt id |
|---|---|---|---|---|---|
| Bunny | 790546 cbrews "Squeaky pliers" 1.16-2.18 | 3.08 squeak | 288941 toefur "rat-squeak" 0.06-0.49 | 3.90 | 86924796903257 / 118320471819470 |
| Gecko | 351301 mopedmetzger "gekko" 5.44-6.80 | 4.07 "a gecko calling" | 149924 vollkornbrot "gecko" 5.19-5.92 | 4.33 | 77250636152797 / 116116856026992 |
| Monkey | 400084 Radio_fragola_gorizia "chimpanzee2" 9.11-11.10 | 4.77 | same file 7.44-7.74 | 3.89 | 82605651713721 / 123787150079996 |
| Crab | 496600 PhonosUPF "castanets attack 2" 0.01-0.81 | 5.37 castanets | 698816 Funky_Audio bubble echoes 12.57-12.97 | 4.90 bubbles | 125304339863997 / 72768067927557 |
| Penguin | 150873 al.barbosa penguin colony 0.0-1.8 | 4.10 | 705839 Breviceps "Penguin Squeak" 0.04-0.58 | 3.45 | 103684855320427 / 129478323372670 |
| Frog | 462863 Breviceps "Common toad" 4.72-6.62 | 4.10 | 354132 betterchinese "Frog croaking" 0.67-0.91 | 4.32 | 112132171747504 / 83194636762675 |
| Zebra | 269571 shadoWisp "horse neigh shortened" 0.23-1.38 | 5.26 neigh | 59569 3bagbrew "horse" 2.31-2.92 | 3.40 snort | 139511433786706 / 99258605533883 |
| Beetle | 390733 FunWithSound "Buzzing Insect Short" 0.02-1.02 | 3.30 | 582683 AKkingStudio "Bee Buzz" 1.17-1.79 | 3.05 | 137485695984321 / 115054206523819 |
| Salamander | 828434 Saladsounds "Sudden Burst of Small Flame" 1.14-2.33 | 4.45 fiery hiss | 155660 the_semen_incident "cig_extinguish" 0.02-0.56 | 3.19 steam hiss | 123655510403393 / 124417939460977 |
| Bat | 667579 Yoyodaman234 "Bat Screech" 2.40-3.98 | 3.41 "small animal shrieking" (2.29 "bat squeaking") | 669717 vestibule-door "bat-like monster sonar click" 1.47-1.90 | 2.44 plausible | 134696234579320 / 98446005598341 |

## Weak spots
- **Crab:** real crabs are near silent and no claw recording read as claws (best z 1.8), so the Call is castanets and the Hurt is a designed bubble (p_real 0.66, uncertain; Call 0.63).
- **Bunny Call** is squeaky pliers, not an animal; it reads strongly as a small squeak (p_real 0.99).
- **Bat Hurt** is only plausible; earshot's vocabulary has no good bat words.
- **Beetle Hurt** sits about -19 dB, ~4 dB under the other hurts (a buzz has low crest even after limiting).
- All 20 were "Reviewing" at upload; silent in game until Roblox approves them.
- Work files (downloads, trims, scripts) are in the session scratchpad, not the repo.

Related: [[Zone Enemies]], [[Boss Sounds]], [[SFX Audit]], [[Eggs From Rocks]]
