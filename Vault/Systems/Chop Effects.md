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

## Aura slashes, replaced by the cut line (user 2026-11-12 playtest: "vfx for chopping, slash vfx kinda colored to player aura", "especially for perfect chops"; built 2026-11-13)
- `VFX_Chop_Slash` (every hit, Bad to Great, including the breaking chop): one camera-facing crescent (kit K0638 "Slashes or Crescents IDK/11", uploaded 136657173851044) at -50 to -40 degrees, 0.18-0.2 s, grows 4.5 to 8.6 studs at the reference rock size, `Tint` `Aura`; a white `SlashCore` copy inside it; 5 small `Sparks` (Glint) thrown toward the camera in the aura colour.
- `VFX_Chop_SlashPerfect` (Perfect and Master): a white `Flash`, `SlashA` = the outlined crescent (kit K0663 "slash_74", black outline baked in, uploaded 137235204523055) at -40 degrees, 6 to 13 studs over 0.3 s, aura tint at `LightEmission` 0 so the outline stays black; `SlashB` = the plain crescent in white at -62 degrees as a speed line; 14 `Sparks`. A first try with two crossed outlined crescents and a ring read as a closed circle, not a slash, so it became one hero crescent.
- Both play at the hit point facing the camera (`impactCFrame`), scaled by rock size, from `RockController/Effects` `playSlash` in `Hit`, `Break` and `BreakBurst`. New `Tint` kind `Aura` = the local player's `HumanoidRootPart.AuraColor` ([[Ki Aura Module]]), white with no aura. Other players' chops (`Shown`) don't get slashes.
- Textures in `assets/VFX/ChopSlash/` (`kit_sources.json`, `assets.json`). Showcase stands `Stand_Chop_Slash` / `Stand_Chop_SlashPerfect` next to `Chop.Hit (Perfect)` (recoloured blue).
- Checked in Edit with `Capture.hold` (blue sample tint), not yet in a playtest chop.

**Slash dial-in (user 2026-11-13):** the slash must run in a straight line down the cut where the rock splits, not as a crescent at the impact point. While it is being tuned, `ChopEffectConfig.SlashOnly = true` turns off the hit and break particle effects (`HitKey`, Break/Perfect/Master bursts). Sounds, shake, crack, the Master wind-up, chunks and the split stay on. Set it back to false when the slash is done. The live cut (`LiveSplit`) is a vertical plane through the rock centre facing the player (`ChopApproach.Rotation(...).RightVector`), so on screen it is a vertical line down the middle. Pre-split rocks (`SplitModel`) cut along their own axis instead.

## Cut power stages (user 2026-11-13: "needs to become 10x cooler visually so the player gets feedback as to how strong they are getting"; "a combination of furthest zone and overkill per chop"; "overkill for forest zone should be visibly weaker than overkill for ruins")
- Second playtest fixes: the mark no longer moves (beams had the default `TextureSpeed` 1, and the texture stretched as the tip moved; now the attachments sit at full length from the start and a transparency sweep reveals them, `CutRevealEdge` 0.03, Segments 40), and it starts on the ground under the chopping hand (`CutHandNames` RightHand / Right Arm).
- **Power** (`Utils/CutPower.luau`, 1 to `CutMaxPower` 6): base = 1 + (furthest zone - 1)/9 x `CutZoneStages` 4 (furthest = the highest zone with a rock whose `StrengthRequired` <= `PeakStrength`), plus overkill = log(strength ratio)/log(`CutOverkillPerStage` 25) capped at 1, times a reach that grows with the chopped rock's zone (`CutOverkillReachMin` 0.3 in the Forest up to 1 in the Ruins), times `CutOverkillStages` 1. Below Perfect, `CutNormalPenalty` 1. `RockController` computes it per chop (`PeakStrength`, `ChopController:GetStrengthRatio()`, rock key) and passes it to `Effects.Hit` / `Effects.Break`. Diamond / boss breaks don't pass it yet (power 1).
- **Stages** = floor(power); template layers carry `MinStage` (also `Only` = Full/Nick, `Tint` = Aura/Rock): 1 core + aura glow + sparks; 2 speed streaks, aura specks, dust puffs (aura-skill toon puff 14267547915, rock tint); 3 the fissure: black crack beam (kit K1797 `CrackLine`, its own `CrackTop/CrackBottom` attachments `CutCrackDrop` 0.12 lower so it doesn't share the glow's plane), black branching crack decals along the line (K0022 `CrackBranch`, flat, 2.6 s), rock-tinted debris (K1311 `RockChunk` 2x2 random frame), black specks; 4 at the hand: aura brush ring (K0431), white cel shockwave flipbook (K1344), aura burst ring (aura-skill 11198241185), wide debris spray, camera shake (`FallEffects.ShakeCamera`) and a hit-stop on the character (`EnemyController/Hitstop`); 5 an air slash flying on past the rock (`Flyer`/`FlyerCore` camera-facing beams between `FlyTail`/`FlyHead`, 0.3 s, 1.5x the line length, lifted `FlyLift`) and a ray flash where the line ends (K0406, `Finale`); 6 a glowing aura crack over the black one (`CrackGlow`) and floor lightning along the line (aura-skill 13771290435).
- Width grows `CutWidthPerPower` 0.18 per power and the linger `CutHoldPerPower` 0.3 s.
- Kit textures in `assets/VFX/ChopCut/` are **preview addresses** (stamp 191842 for the new ones, 165345 for CutGlow/CutStreaks); upload them once the look is approved. Aura-skill ids are public and need no upload.
- Showcase: `Stand_Chop_CutLine` has `Power` 6, `Stand_Chop_CutNick` `Power` 1 (plugin passes `Power`).
- Checked frozen in Edit at power 1 / 3 / 6. Not yet seen in a real chop.

## Cut line (user 2026-11-13: "the slash is supposed to apply in a straight line down the cut"; "Short nick on hits")

**Current shape (user, after the first playtest 2026-11-13: "way too short", and "by horizontal i meant across the length of the rock, the effects should linger after the rock is split down the middle on the ground and then fade out"; picked the flat-on-the-ground beam test):** the line lies **flat on the ground** (`FaceCamera` false on every beam; attachments get `WorldCFrame` = basis with X along the line and Y horizontal across it, since a Beam's width runs along its attachments' Y axis), at the rock's bottom + `CutGroundLift` 0.3, running along the split from the player's side, under the rock, out the far side: `CutOvershoot` 2.2 x the rock's widest side (Perfect+ 2.5). The tip draws away from the player. A breaking cut then holds `CutHoldSeconds` 1.2 (dimming by `CutHoldDim` 0.35) while the halves fly apart and reveal it, and fades over `CutFadeSeconds` 0.8. Nicks are a short ground line at the rock's near edge (`NickEdgeFraction` 1.15, `NickLengthFraction` 0.35 of the width) with the old quick fade and retract. Sparks and specks now shoot up (`Top`). The upright camera-facing version and its particle ghost, scar and wake (`Center`) were removed. The notes below describe the earlier upright version.
- Replaces the crescents in play (`VFX_Chop_Slash` / `SlashPerfect` stay in Studio and AssetRegistry, unused). `RockController/CutLine.luau` + template `Assets.VFX.Chop.VFX_Chop_CutLine`: a Root part with `Top`, `Mid`, `Bottom`, `Exit` attachments and three Beam layers:
  - `CoreUpper` / `CoreLower`: untextured white, 0.28 studs, Brightness 3 (blooms; Lighting bloom threshold 2.2), split at `Mid` (Upper widens, Lower narrows) so the core is a crisp pointed spindle. `ZOffset` 0.3.
  - `Glow`: one beam Top->Bottom, kit K1911 `Line_08` (a streaky tapered spindle, `assets/VFX/ChopCut/CutGlow.png`), 1.6 studs, aura tint, LightEmission 0.6, Brightness 2. `ZOffset` 0.15.
  - `Streaks` (`MinQuality` 5 = Perfect and Master): kit K1929 `Line_09` (a bundle of fine vertical streaks, `CutStreaks.png`), 3.2 studs, aura tint, base transparency `Alpha` 0.25. `ZOffset` 0.05.
  - Textures are still **preview addresses** (`rbxasset://textures/vfxpreview/165345/...`); upload both in one batch once the look is approved and swap them in.
  - `Exit.Sparks` (aura tint): as the tip passes each quarter of the line (`CutSparkSteps` 4) a few sparks drop there (`CutSparkTrailShare` 0.3 of `EmitCount`), then the full 10 at the bottom. Full lines only.
  - **Borrowed from the fire katana reference (2026-11-13, `studied.md`):** a `Center` attachment (placed at the line's midpoint) holds timed particles, each fired once at its `EmitDelay` seconds after the cut starts, sized for a 10-stud line and scaled by line length / `CutReferenceLength`:
    - `Ghost`: a black twin of the glow spindle (`FacingCamera`, Squash 2.5, 0.3 s, 0.15 -> 1 transparency) fired at 0.09 s, so a dark cut lingers as the bright line fades.
    - `Scar` (`Only` = `Nick`): a thinner black spindle (Squash 2.8, 1.2 s) so each hit that doesn't break leaves a short-lived scratch on the rock.
    - `Wake` (`Only` = `Full`): the grey streak bundle at 0.6 -> 1 transparency, growing 2 -> 2.6, 0.35 s, the swing's afterimage.
    - `Exit` gets `Specks` (aura-tinted streak bits, `VelocityParallel`, 8) and `SpecksDark` (a black set, 4) alongside `Sparks`; all three are `Only` = `Full`. Particles live on after the beams end; the model is destroyed after the longest `Lifetime`.
    - Particle `Squash` stretches height: a `FacingCamera` sprite of this texture renders about size x 2 x (1 + squash) tall, so sizes are `10 / (2 * (1 + squash))`.
  - A black `Outline` spindle for Perfect was tried and removed: Beam draw order ignored `ZOffset` once the textured glow was added (the black drew over the white core), and pushing it back onto its own attachments made it vanish head-on and slide sideways at an angle.
- Timing on template attributes: `DrawSeconds` 0.06 (tip runs top to bottom, ease out), `HoldSeconds` 0.05, `FadeSeconds` 0.16 (width shrinks, transparency rises, the tail retracts `CutRetractFraction` 0.7 down the line). `PerfectWidthScale` 1.5.
- Placement (`ChopEffectConfig`): vertical, through the rock centre pushed toward the player by `CutFrontFraction` 0.55 x the widest side so the rock never hides it, so it sits on the `LiveSplit` cut. Full line = rock height x `CutOvershoot` 1.1 (Perfect+ 1.35). Hits that don't break = a short nick, `NickLengthFraction` 0.35 of the height, `NickWidthScale` 0.7, centre jittered up or down by `NickJitterFraction` 0.15, no sparks. Width scales with rock size like the other chop effects.
- `Effects.Hit` plays the nick; `Break` and `BreakBurst` play the full line, and `Break` now waits `DrawSeconds` before hiding the rock and splitting or throwing chunks, so the line is drawn on the whole rock first.
- `CutLine.Spawn(part, quality, isFull, aura, toward?)` + `CutLine.Pose(line, t)` let it be posed frozen in Edit (pass `toward`; without it `ChopApproach` needs a LocalPlayer). Showcase stands `Stand_Chop_CutNick` / `Stand_Chop_CutLine` (were the slash stands) use the new plugin `Mode` `CutLine` (attributes `Quality`, `IsFull`, `Color`), facing the Studio camera.
- Checked frozen in Edit (blue sample aura) at 0.035 and 0.09 s for Perfect, Good full line and the nick, after the texture pass. Not yet seen in a playtest chop. `SlashOnly` is still on.
- Open: pre-split rocks (`SplitModel`) break along their own axis, so the line won't match their gap; making them split facing the player is a follow-up.
