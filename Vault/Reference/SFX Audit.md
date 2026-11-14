---
description: 2026-11-11 earshot audit of all 65 unique SFX files (89 Sound instances) - levels in game, clipping, silence before the sound, what each actually sounds like, and the fixes it points to.
type: reference
---
# SFX audit (2026-11-11)

Claude ran earshot (`measure`, `describe`, `rank`) on every `SFX_` sound in `ReplicatedStorage.Assets.Sounds`. Audio was downloaded through the Open Cloud key, which needs the **Asset Delivery** permission (`legacy-asset:manage`; added by the user 2026-11-11). The files come back gzip-compressed OGG. The script and data are in that session's scratchpad, not in the repo. To re-run: download with `asset-delivery-api/v1/assetId/<id>`, gunzip, then call earshot's Python (`%APPDATA%\uv\tools\earshot\Scripts\python.exe`, `from earshot import api`).

"Game level" = the file's loudness (LUFS; RMS for clips under 0.4 s) plus the Sound's `Volume` in dB. Across all SFX the median is **-24 LUFS**, with the middle half between -29 and -20. These are measurements; nobody listened.

## Fix first
- **Clipping baked into the file** (samples at full scale, so it distorts at any volume): Cannon_Boom 9,414 clipped samples and true peak +2.8 dBTP, Cannon_Land 5,440, Diamond_Despawn 251, Rock_Break 108 (plays on every rock break), Slice_ThrowBomb 72, Rush_Chime / Weather_Start 44, Chop_Master 36.
- **Much louder than the rest:** Cannon_Boom -8.9 (15 dB over the median), Intro_Teleport -12.4, Cannon_Land -12.5, Intro_CarDrive -13.4.
- **Much quieter than the rest:** UI_Hover -50, UI_PanelOpen / PanelClose / Tab / ShopBell about -41, Enemy_Tick -41, Diamond_Beacon -36, Diamond_Tick / Rush_Tick -36. The UI sounds sit about 16 dB under everything else.
- **Silence before the sound** (the sound starts late after it is triggered): Intro_GoTrain 0.39 s, Intro_Dizzy 0.37, Weather_Sandstorm 0.35, Diamond_Appear / Level_Up 0.30 (0.375 at its 0.8 speed), Rock_Rise 0.30, Intro_Gulp 0.30, Diamond_Shimmer 0.25, **Diamond_Shatter 0.21** (the break should land on the hit), **UI_Error 0.20** (feedback feels laggy), Cannon_Whoosh 0.18. Fix with `Sound.TimePosition` or a trimmed re-upload.
- **No audio:** Weather_Eclipse and Weather_HeatWave have no SoundId.

## Sounds that may not be what their name says (earshot's top reading, z)
- **Chop_* (all five qualities):** a success chime (z 3.9) or kalimba note (3.0), not an impact. Pitch-shifted per quality (Bad 0.5, Mid 0.6, Good 1.0, Great 1.1, Perfect 1.25), so possibly on purpose.
- **Rock_Crack / Hatch_Step:** a squishy wet squelch (4.2).
- **Enemy_Roar:** a cow mooing (3.5). **Intro_GoTrain:** a cow mooing (2.8).
- **Intro_CarDrive:** a phone vibration buzz (3.2) or error buzz (2.8), not an engine.
- **Slice_ThrowBomb:** coins dropping (3.2), not a throw.
- **Cannon_Equip:** digging in soil (3.5).
- **Diamond_Hit / Money_Gain / Diamond_Payout:** coins dropping (3.7). Right for money, wrong for the Block round's "Blocked!".
- These match their names: Cannon_Boom explosion (4.4), Cannon_Whoosh fast whoosh (4.0), Enemy_Hit punchy impact (4.5), Slice swipes (3.7-4.4), Train_Steel glass ting (4.7), Train_Vault door slam (4.1), Weather_Thunder / Thunderstorm thunder (3.5 / 4.0), HotStreak_Loop crackling fire (4.7), UI_Click wooden block (3.8), UI_Error error buzz (4.0).

## Block round sounds
- Ranked for "a metal shield blocking a heavy hit, a solid clang": **Train_Vault** is the only strong match (z 3.5, sounds like a door slam), so it should replace Diamond_Hit's coins for "Blocked!". No sound in the game is a true metal clang.
- Ranked for "a rising whoosh building tension": **Cannon_Whoosh** is the only plausible match (z 2.8). It is 3.2 s long with a 0.18 s lead, so it needs trimming to fit the 0.6 s wind-up. The current warning sound, Intro_SlideUp, reads as a glass harp tone or balloon squeak (3.6 / 2.7).
- Enemy_Hit (Ouch, punchy impact 4.5) and Chop_Perfect (chime, pitched up) fit their jobs.

## Applied (2026-11-11, Studio edits; the place must be saved)
- **Volumes:** Cannon_Boom 0.5 to 0.18, Cannon_Land 0.5 to 0.21, Intro_Teleport 0.6 to 0.25, Intro_CarDrive 0.4 to 0.15. UI_PanelOpen 1.9, PanelClose 1.7, Tab 1.65, ShopBell 1.95 (all were 0.5), UI_Hover 0.3 to 1.25, Enemy_Tick 0.7 to 2.6, Diamond_Tick / Rush_Tick 0.5 to 1.0. Each changed Sound keeps its old value in the attribute `AuditOldVolume`. The UI sounds were brought to about -30 LUFS, a little under the gameplay sounds, not to the -24 median.
- **Start offsets:** a Sound's number attribute `StartSeconds` is copied to `TimePosition` by `AssetRegistry.get`. `LocalSound.PlayInstance` (used by `LocalSound.Play` and the Diamond Rock's `playOnce`) plays from there through `Sound:Play()`, because `PlayLocalSound` may ignore it. Set on Diamond_Appear and Level_Up 0.28, Diamond_Shimmer 0.23, Diamond_Shatter 0.19, UI_Error 0.18, Rock_Rise 0.28, Weather_Sandstorm 0.33, Cannon_Whoosh 0.16. Checked in Play: UI_Error started at 0.18 and ended on time. Sounds played through other paths (HotStreak, the egg tick, 3D sounds a controller plays itself) get the position only if they `:Play()` the AssetRegistry copy.
- **Not changed:** the intro sounds (GoTrain, Dizzy, Gulp), because the intro timeline was timed by eye around them as they are. The clipped files, the silent weathers and the off-name sounds need new audio.
- **Block rounds:** "Blocked!" now plays Train_Vault, and the warning plays Cannon_Whoosh (its peak lands about 0.8 s in, during the cursor pass).

Related: [[Block Rounds]], [[Open Cloud Key]]
