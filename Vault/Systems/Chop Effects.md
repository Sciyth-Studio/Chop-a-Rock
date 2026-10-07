---
description: Hit, crack, break, Perfect and Master VFX on rocks plus the coin cash pop (blockout built 2026-10-07); templates are tinted by quality and scaled by rock size from code.
type: system
---
# Chop effects

Blockout built 2026-10-07 with Roblox built-in textures; custom textures come once the user has judged the timing and size in play. Picked by the user: quality-coloured accents with rock-coloured matter, a coin fountain for cash, and a Master wind-up before the burst.

## Templates (`ReplicatedStorage.Assets.VFX`, keys in `ChopEffectConfig` / `CashPopConfig`)
| Template | When | Placed at |
| --- | --- | --- |
| `VFX_Chop_Hit` | hit that doesn't break | rock surface facing the camera, emits along -Z |
| `VFX_Chop_Crack` | "Too weak" | same |
| `VFX_Chop_Break` | Bad to Great break (with the physical chunks) | rock base |
| `VFX_Perfect_Burst` | Perfect split | rock base |
| `VFX_Master_WindUp` | the 3 s Master lead-in (`EffectDuration` 3.3) | rock base |
| `VFX_Master_Burst` | Master split; it was registered but missing from Studio until 2026-10-07 | rock base |
| `VFX_Cash_Pop` | pedestal pad collect (player's feet), plus gold Neon coin parts spawned by `CashPopController`. Chop payouts (top of the rock) use the quieter `CashPopConfig.Chop` profile: 3 small coins, low arc, no glint burst. The user found the full pop on every chop too much (2026-10-07) | |

Other players' chops (`RockChopShown`) play the same templates through `Effects.Shown`, using `OthersChunkColor` as the rock colour.

## Conventions read by `RockController/Effects.luau`
- Authored for a 10-stud rock (`ChopConfig.ReferenceRockSize`): base at the pivot, `Center` attachment at Y 5. Code scales sizes, speeds, accelerations, attachment offsets, parts and light range by `rockSizeX / 10` (minimum `MinScale`).
- `Tint` attribute on an emitter: `Quality` (the `ChopStyleConfig` colour), `QualityHot` (white to quality colour), `Rock` (the rock's `Color`), `Dust` (rock colour lightened by `DustLightenAmount`).
- `MinQuality` attribute: the layer is removed below that quality (Break's ring from Good, sparkles from Great). `BreakCountScale` multiplies every `EmitCount` above 1 for Bad to Great.
- On this place's teal floor, dust needs starting Transparency near 0 to read at all; additive glows read at Brightness 2 to 3.
- Coins are physics parts in the `Debris` collision group. Roblox gravity (196) needs about 50 studs/s of upward speed for a 6 to 7 stud arc.

Related: [[Rock Spawning]], [[VFX From Roqer]], [[High Saturation Colors]].
