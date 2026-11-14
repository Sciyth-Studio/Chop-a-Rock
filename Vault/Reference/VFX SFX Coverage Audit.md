---
description: 2026-11-11 coverage audit - which game moments have no VFX or no SFX yet, from the code and Studio's Assets; companion to the SFX Audit (which measured the sounds that exist).
type: reference
---
# VFX and SFX coverage audit (2026-11-11)

Claude read every client play call (`LocalSound.Play`, `VFXEmit`, emitters) and listed `ReplicatedStorage.Assets.Sounds` / `Assets.VFX` in Studio: 126 sounds, about 70 VFX templates, **zero Sounds in Workspace**. Nothing was played or heard. Sound quality (levels, clipping, late starts) is in [[SFX Audit]].

## Missing both
- **Boss Arena rise/sink** ([[Boss Arena]]): dust and camera rumble only; no stone grinding or rumble. Stone grind/rumble sound added 2026-11-12 (`SFX_Arena_Grind`); no VFX change.
- **Placing a Pet on a pedestal** ([[Pedestals]]): `Components/Pedestal.luau` has no sound or effect. A small pop + thunk would sell it.
- **Zone Enemy launch, defeat and flee** ([[Zone Enemies]]): reuse Rock dust/Chop hit/break; the planned own effects were never made.
- **Auto Open crack** ([[Auto Open]]): no strike animation or hit for auto cracks.

## Missing SFX
- **Ambience:** no zone beds anywhere (forest birds, desert wind, ocean waves, snow wind, volcano rumble, etc.). Only music plays. Biggest single gap for feel. All ten zones built 2026-11-11 ([[Ambience]]).
- **Weather Eclipse and Heat Wave:** Sound instances have no SoundId.
- **Boss per-boss Big Attacks** ([[World Bosses]]): tail whoosh, ice crack + spike burst, boulder whistle + rock crash (already in To Do, in progress). As of 2026-11-12 `BossFxConfig`: TailSweep has `SFX_Boss_Swing`, BoulderRain the generic `SFX_Boss_Slam`, IceSpikes was silent; **filled 2026-11-12** with `SFX_Boss_IceSpikes`. Boulder whistle and a heavier tail whoosh are still open.
- **Aura equip/buy:** buy now plays `SFX_Aura_On` with the coin sound (2026-11-12, [[Auras]]).
- **Event start** (Geode Fall, Diamond Rock, boss wake via [[Event Clock]]): `EventTimers` is silent; check that each event has a horn/sting when it starts.
- **Generic coin sound overused:** `SFX_Money_Gain` covers sell, Index claim, Shop buy, pedestal slot buy, Hot-streak cash. Fine for money, but a distinct "unlock/upgrade" sound would help slots and the Index.

## Missing VFX
- **Base and training sign upgrades:** sound only, no burst on the sign or stand.
- **Cash Pack and Robux purchases, Free Gift claim:** `BoughtSound` only, no screen or world celebration (check whether `CelebrationEffectController` should fire).
- **Aura equip:** emitters appear instantly; no switch-on burst.
- **Placeholders:** `VFX_Rock_Dust` is a placeholder smoke burst ([[Rock Spawning]]); Diamond Colossus later beats (arrival, vein haze, shard trails, low health) are in `DiamondColossusVfxPlan.md`; zone 6-10 Pets "still need effects" ([[To Do]]).

## Replace (audio exists but is wrong or broken)
From [[SFX Audit]]: clipped Cannon_Boom, Cannon_Land, Rock_Break (every break), Diamond_Despawn, Slice_ThrowBomb, Rush_Chime/Weather_Start, Chop_Master. Off-name: Rock_Crack/Hatch_Step (wet squelch), Enemy_Roar and Intro_GoTrain (cow moo), Intro_CarDrive (phone buzz), Slice_ThrowBomb (coins), Cannon_Equip (digging). No true metal clang for "Blocked!".

## Intentionally silent or fine as is
- [[Zone Banner]] is silent by the user's choice (2026-11-09).
- Crown, leaderboards, teleport bar, upgrade alerts: UI-only, no effect needed unless the user wants one.

## Unused assets (cleanup)
`VFX_Rush_Pillar`, `RushCountdown`, `SFX_Rush_Tick` (unused since Golden Rocks replaced Rush), a Sound named `Fight ` (trailing space) loose in `Assets.Sounds`.

Related: [[SFX Audit]], [[Chop Effects]], [[VFX Showcase]]
