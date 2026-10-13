---
description: Hit, crack, break, Perfect and Master VFX on rocks plus the coin cash pop (blockout built 2026-10-07); templates are tinted by quality and scaled by rock size from code.
type: system
---
# Chop effects

Built 2026-10-07 as a blockout with Roblox built-in textures, then given custom textures (below) the same day once the user approved the timing and size. Picked by the user: quality-coloured accents with rock-coloured matter, a coin fountain for cash, and a Master wind-up before the burst.

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

## Textures
Drawn 2026-10-07 with `vfx_draw` (sources in `assets/VFX/Chop/`), uploaded by GuiltyArcher with `upload_image` and shared with the experience: ImpactStar 108160687082964 (Grid4x4 OneShot), Flash 137739014780004, Shard 72115844556132 (two-tone), Puff 89842293218952 (Grid4x4 OneShot), Ring 86973755749304, Glint 75840693106402, Streak 83922731235972, Dollar 114639041914556, Glow 127509283933231. Layers map by name: Stars → ImpactStar, Master Confetti → Shard, Dust/DustColumn/Skirt/Puff/Swirl → Puff, Ring*/Collapse → Ring, Sparkles/Gather/Sparks/GoldGlints → Glint, Streaks → Streak, Cash Pop Glints → Dollar, Backing/Core → Glow. Master `Pillar` keeps the level-up pillar texture.

**2026-10-09 swaps (user picked toolbox images, single frames, FlipbookLayout None):** Middle dust (Hit Dust, Crack Puff, DustColumn, Master WindUp Swirl) → "Smoke2" 11204150798. Base Skirt (Break/Perfect/Master) → "Smoke" 467188845. VFX_Rock_Dust is unchanged.

**2026-10-09: rock chips removed.** The Chips layers (Hit, Break, Perfect, Master) were swapped to the toolbox "Rocks" image 8132607319, came out near-black (grey-shaded image × rock tint), and even brightened the user found them ugly, so all four layers were deleted. Breaks still throw physical chunks. Don't re-add particle chips without asking.

Other players' chops (`RockChopShown`) play the same templates through `Effects.Shown`, using `OthersChunkColor` as the rock colour.

## Conventions read by `RockController/Effects.luau`
- Authored for a 10-stud rock (`ChopConfig.ReferenceRockSize`): base at the pivot, `Center` attachment at Y 5. Code scales sizes, speeds, accelerations, attachment offsets, parts and light range by `rockSizeX / 10` (minimum `MinScale`).
- `Tint` attribute on an emitter: `Quality` (the `ChopStyleConfig` colour), `QualityHot` (white to quality colour), `Rock` (the rock's `Color`), `Dust` (rock colour lightened by `DustLightenAmount`).
- `MinQuality` attribute: the layer is removed below that quality (Break's ring from Good, sparkles from Great). `BreakCountScale` multiplies every `EmitCount` above 1 for Bad to Great.
- On this place's teal floor, dust needs starting Transparency near 0 to read at all; additive glows read at Brightness 2 to 3.
- Coins are physics parts in the `Debris` collision group. Roblox gravity (196) needs about 50 studs/s of upward speed for a 6 to 7 stud arc.

Related: [[Rock Spawning]], [[VFX From Roqer]], [[High Saturation Colors]].
