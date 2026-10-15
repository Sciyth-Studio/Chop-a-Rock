# Studied reference effects

Breakdowns of effects the user brought in as examples of the quality to aim for. They live in `Workspace.VFXReference` in the Chop a Rock place, studied 2026-10-09 and 2026-10-10. Layout since 2026-10-10: aura rigs in a row at Z -95 (X 310 to 492, 26 studs apart: RuneCircleAura, PurpleEnergyAura, FireAura, CurseFlameAura, ChainBeamAura, LightningAuraKillua, ElectrocutedBody, FireFist), standalone effects at Z -140 (ElectricOrb, BlueBurst, LightningStrike, WindTornado, CelExplosion), GroundTrailA/B at X 400, Z -175 and -187. Original names in the headings below are the old ones (RNG-Aura-01 = RuneCircleAura, Core = ElectricOrb, Stuff = BlueBurst, Lighting-01 = LightningStrike, Tornado-01 = WindTornado, Explosion-01 = CelExplosion, Part = GroundTrail). Open them in Studio and look before building something similar. The user cleared their textures for use in this game on 2026-10-10 (ids at the bottom).

## What they have in common

- **The texture does the work.** Each effect is 3 to 7 layers, and every layer is a detailed painted texture: a runic magic circle, a cel-painted fire flipbook, hand-drawn wind swirls, a lightning flipbook. None of them is built from soft dots and glows. Our 2026-10-09 auras had 15+ layers of simple drawn shapes and looked worse than a three-layer magic circle.
- **One hue per effect.** Every emitter in the effect shares one `Color` (lightning 43,135,255; aura 209,116,255; tornado 115,115,115; explosion 255,124,91) on white or grey textures. Contrast comes from the texture's own values and from Brightness, not from mixing colours. The one exception is a ramp from saturated to white over life (`0,85,255` to `255,255,255`) on bursts.
- **Saturated, mid-luminance colours take high Brightness** without blowing out at bloom threshold 2: blue at Brightness 5 to 10, purple at 5. White, gold and yellow additive layers can't (see the 2026-10-09 Dragon blowout in the vault's Auras note).
- **Fade in and out.** Transparency is almost always `0:1, 0.2:0, 0.5–0.8:0, 1:1`. Nothing pops on or off.
- **Random `Rotation` -360 to 360** on every round sprite, and `Size` envelopes (`±`), so repeats don't show.
- **`LightInfluence` 0** everywhere.
- **The first batch were single standalone effects.** For auras, the user wants layers wrapped around the body as well (`LESSONS.md` §4). The second batch (below) shows how real aura rigs do it. The user dislikes detailed ground circles under auras (2026-10-10: "there's enough going on"); a soft flat glow or ground streaks are fine.

## Body auras (second batch, 2026-10-10)

How the user's aura rigs (R6) are built. Most emit straight from the **Torso** part, not an attachment: a 2x2x1 box volume, so particles start all over the chest.

- **Body-filling sprite, refreshed fast.** The core trick of PurpleEnergyAura and FireAura. One big camera-facing sprite on the torso (Size 5 to 7), Rate 15 to 100, Lifetime 0.15 to 0.6, random Rotation, `RotSpeed` 240. Many overlapping short-lived copies make a shape that boils in place around the whole body. FireAura is only 5 such emitters: two flame sprites (7 to 5 and 4 to 2.5 studs), a star flare growing 0 to 9, a burst shrinking 10 to 0, and fast embers (Speed 33, Drag 5).
- **A dark core behind the colour (PurpleEnergyAura).** Its `Main` is a black-purple energy blob (`32,19,38`, LE 0, Size 5, Rate 15, Lifetime 0.15, ZOffset -1) behind purple lightning flipbooks (LE 1, Brightness 4) and a black crescent ring (LE 0) under purple crescents. The dark layer makes the purple read as energy instead of a pink glow. This is the "darkness" recipe.
- **Flat rings that snap out.** Shockwave and crescent flipbooks, `VelocityPerpendicular`, Speed 0.001, Lifetime 0.25 to 0.35, Size easing from 0 to 12 over life (many keys, fast then slow), Transparency 0.75 to 0.9 at best. Faint, fast, constant.
- **Rising flame sheets (CurseFlameAura).** A ground attachment (Y -3) firing upward at Speed 15 to 25 with Drag 5 (so they shoot up and stop), Spread 4 to 5: an `S` swirl ring (`VelocityPerpendicular`, `RotSpeed` 600, LE 0, Brightness 5) and two flame sheets with `Squash` 0 to 0.41 (they stretch as they rise), LE 0.2, ZOffset -1. Flat ground glows grow 0 to 7. A disc-shaped `GroundPart` (10x1x10, Shape Disc) throws rock bits and `VelocityParallel` streaks (Squash to 3) upward.
- **Black twins of streaks (FireFist, ChainBeamAura).** Each coloured streak or dot emitter has a black copy (LE 0) at a lower rate. Dark specks among the bright ones give it grit.
- **Particle dust over every limb (LightningAuraKillua).** Every limb and the torso run 250-per-second tiny dots (Size up to 0.24, Lifetime 0.25), so the whole body fizzes. Five Beams from above the head down to the feet use a lightning texture with `TextureSpeed` -3.5 (scrolling down) and curve. A hidden 4x5x3 part around the body flashes six different lightning textures at Lifetime 0.1.
- **Lightning on every part (ElectrocutedBody).** Each body part has 3 behind (ZOffset -2) and 2 in front (ZOffset 2) lightning emitters at Size 2.7 to 0.6 to 2.1 (a snap), Lifetime 0.2 to 0.3.
- **Chain beams to the ground (ChainBeamAura).** Four Beams from the root to points 7 studs out on the floor, curved (`CurveSize0` ±3), chain texture scrolling at `TextureSpeed` 1.5, each end with a star flare and glow.
- Colours stay one hue per aura; Brightness 2 to 5 at LE 0.2 to 1, never higher.

## RNG-Aura-01 (ambient aura, R6 rig)

Everything hangs off the HumanoidRootPart.
- **Ground circle:** three flat particles at the feet (attachment Y -3), `Orientation` VelocityPerpendicular, `EmissionDirection` Top, Speed 0, `LockedToPart`, Rate 1.5, Lifetime 1, LE 1, Brightness 5. The textures are a runic circle (Size 0 to 3.16, scaling in), a ring (4.2) and a glyph band (3.5). Each fades in and out, so at Rate 1.5 and Lifetime 1 they overlap into a circle that is always there and gently breathes.
- **Beam ring:** two Beams between attachments 7.5 studs apart (Z -3.75 and +3.75, Y -2.5), `CurveSize0/1` -5/+5 on one and +5/-5 on the other, Width 7.5, `FaceCamera` false, 50 segments, Transparency 0.5, Brightness 5. Together they close a glowing circle.
- **Light pillars:** four Beams, each from an attachment on the floor (Y -3) to one 2 to 5 studs above it, scattered around the body. `FaceCamera` true, Width 2, Transparency `0:0, 0.7:0, 1:1` (fades out at the top), Brightness 5, a chain-like vertical texture. Different heights make it read as energy rising, not a cage.

## Tornado-01 (wind funnel)

Seven emitters on one attachment at the floor. The funnel is **flat swirl rings flying upward and growing**:
- Windspin 1, 4 and 5: different swirl-ring textures, `VelocityPerpendicular` (so each particle is a horizontal ring), Speed 17.5 straight up (Spread 6), Rate 100, Lifetime 1, Size 0 to 14 (or 9), `RotSpeed` 250, LE 0.75, `LockedToPart`. Each ring is born small at the floor and is wide when it reaches the top, so the stack is a cone.
- Windspin2: a faint white ring layer (Transparency 0.87 at its densest, Speed 2), as a soft body.
- Windspin3: a burst of 4 big rings (Size 0 to 12 to 19.6, Drag 9) after 0.1 s for the opening gust.
- Impact 1 and 2: flat ground splashes at the base (Lifetime 0.3, Rate 15, Size growing 2–4 to 10–13, random rotation). Overlapping short splashes churn instead of sitting still.
- Grey 115,115,115 at LE 0.75 to 1: on a bright sky it reads as white wind without blowing out.

## Lighting-01 (lightning strike)

- **Bolt:** one particle, a 4x4 `OneShot` lightning flipbook at 32 fps, Size 13, `FacingCameraWorldUp` (stays upright whichever way the camera turns), LE 0.5, Brightness 5, attachment 9.9 studs above the ground hit point.
- **Ground impact:** three flat ground textures (two splash or crack decals plus one 20-stud ring), Lifetime 0.3, Rate 15, Brightness 1, ZOffset 0.5 to 1, Transparency `1, 0, 0, 0, 1`.
- **Rising sparks:** a 4x4 `OneShot` spark sheet, Speed 15, Spread 60, Drag 2, Size 0 to 6.4, Brightness 10.
- All in 43,135,255.

## Core (electric orb)

- **Flicker without a flipbook:** Bolts uses a Transparency curve of about 20 random keypoints between 0.13 and 0.98 over a 0.33 s life, with a random `Rotation`, so arcs flash on and off like electricity. Size 4.8±0.4, colour pale yellow to gold to pale yellow.
- **Bubble:** a soft orb shell at ZOffset 3 (in front of the bolts), Transparency at least 0.7, Lifetime 1.

## Stuff (burst)

- **Lines:** 30 streaks, `VelocityParallel`, Rotation 90, Speed 10 to 20, Size `0, 0.87±0.87, 0` (a pop). Colour blue to white.
- **Wave:** 5 flat spinning swirls (`RotSpeed` 600 to 1000, Size 0 to 5.4±3).
- **Ring:** 2 flat rings, Lifetime 0.3.
- **Burst / Burst2:** two spiky bursts (2 and 3 particles), `VelocityParallel`, ZOffset 2.
- **Light:** a PointLight at Brightness 13, Range 9.
- The emit counts are small: the shapes in the textures carry the effect.

## Explosion-01

- **Fire1–3:** three cel-painted fire flipbooks (4x4 `OneShot`, 30 fps) at **LightEmission 0** and Brightness 4.2, tinted 255,124,91. LE 0 keeps the painted shading and stops the layers adding up to white. Speed 20 with Drag 5 for a puff that stops, Size 10.7 to 12.7±5. `Squash` envelope (-0.12±0.24) gives each puff a different shape. Opaque until 70% of life, then a quick fade.
- **Smoke:** black at LE 0.5, Size 13.5 to 27, Lifetime 2 to 4, slow spin.
- **Specks:** tiny `VelocityParallel` sparks at Brightness 500 (tiny particles can go extremely bright), Rate 250, Speed 30, Drag 2, `RotSpeed` ±700.

## Part strips (ground trail)

A 41-stud invisible part with an attachment at each end and three Beams between them (two left at Transparency 1, so hidden; one visible, Width 2 to 0.5). Each end has an emitter cluster: a small-dot scatter (Rate 100, Spread 360), glow puffs, and sparkle stars at Rotation 45. Blue `0,85,255` to `85,170,255`. A dash or projectile path: a line beam plus a sparkle source at each end.

## Texture ids (cleared for use 2026-10-10)

Some of these textures have colour baked in, so tinting them to another hue fails:
- The cel fire sheets 11395089850, 11395090403 and 11395118687 are orange. Magenta over them renders red.
- The lightning snaps 5511876855, 5511887359 and 5511893461 and the dust dot 5789352409 are blue. Yellow over them renders green.

Tint these only toward their own hue. For other colours, use our greyscale textures (`assets/VFX/Aura/`).

Second batch (cleared with the first): dark energy core 11548493803, purple lightning sheets 11284817648 / 11492870634, shockwave sheet 11198241185, crescents 11548572707 / 11518060690, energy burst sheet 11187840108, fire sprite 10630207905, star flare 11368109749, ember 10953167939, flame sheet 11204150798, swirl ring 8618373035, streak 13712001736 / 8030734851, dust dot 5789352409, scrolling lightning beam 6262372113, chain beam 13976927757, lightning snaps 5511876855 / 5511887359 / 5511893461, rock bit 8132607319, soft glow 8708637750, star 3052949762 / 10598374841.


| Role | Id |
| --- | --- |
| Aura runic circle / ring / glyph band | 16956569427, 14591895021, 16956497860 |
| Aura ring beam / pillar beam | 12781812529, 3029306948 |
| Wind swirl rings | 16669803246, 16669903446, 16669782675, 16669505937, 12685367098 |
| Ground impacts | 16954586568, 16670162492, 16954602535, 16957275379 |
| Lightning flipbook / spark flipbook | 13771290435, 16664675233 |
| Electric arcs / orb shell | 1084955012, 1084955488 |
| Cel fire flipbooks | 11395089850, 11395090403, 11395118687 |
| Burst lines, wave, ring, spikes | 7458821155, 7225262171, 4609193944, 7417147728, 7428241836 |
