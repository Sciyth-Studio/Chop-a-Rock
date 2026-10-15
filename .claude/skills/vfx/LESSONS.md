# VFX lessons

Rules the user has taught about effects, each with the moment behind it. Newest
at the bottom. These win over the references when they disagree. Add one entry
per piece of feedback: the rule, then **Why** (what happened) and **How to
apply**. Entries 2-12 carry over from the earlier vfx skill (2026-10-07 to
2026-10-10).

## 1. Actual VFX, never 3D objects

Build effects from ParticleEmitters, Beams and Trails with textures. Never
from 3D objects such as sphere or ball-cluster "puffs".

**Why:** after a "flat, terrible coloring" complaint on a strategy game's
explosions, they were remade as shaded 3D ball clusters, and those were rejected
too: they read as 3D objects, not effects. (From the upstream skill.)

**How to apply:** fix flatness with particle technique instead:
- layered flipbook emitters with offset spawn shapes, random rotation and
  staggered `EmitDelay`;
- colour and size sequences; a dark layer or black twin for value
  (`vfx-design.md` §3);
- soft opaque smoke textures at `LightInfluence` 1 so the scene shades them;
- warm colour ramps, and smoke beside fire carrying the fire's colour.

## 2. Chop a Rock is smooth cartoon

The art direction (Master Game Plan §03) is smooth cartoon, bright and
saturated (vault [[High Saturation Colors]]).

**Why:** the game's look; mottled, gritty smoke fights it.

**How to apply:** lean toward clean cel shapes and saturated energy. Use
mottled, heavy smoke only when the user asks for weight.

## 3. This place blows out warm additive layers

**Why:** on this place (bloom threshold 2, saturated colour correction, bright
sky and floor), additive gold layers at Brightness 4-6 summed into a white blob
(2026-10-07, VFX_LevelUp; again on the Dragon aura 2026-10-09).

**How to apply:** read `Lighting`'s `BloomEffect` before picking Brightness.
Rings and pillars read well at Brightness 1.4-2.5 with `LightEmission`
0.15-0.3; glints and dots hold up at 3-4. Saturated mid-luminance colours (blue,
purple) take Brightness 5-10 at `LightEmission` 1; white, yellow and gold
don't. Painted, shaded textures (cel fire, smoke) go at `LightEmission` 0 with
Brightness about 4. Tiny sparks can go very bright (the reference explosion's
specks run at 500).

## 4. An aura goes around the body

**Why:** an aura made only from a ground layer lacked substance (2026-10-10).

**How to apply:** wrap the character in layers (`references/studied.md`, body
auras):
- **Rear flames:** big upright flames (`FacingCameraWorldUp`, a 4x4 fire
  sheet) rising from 3-4 attachments just inside the feet, Size about 3-4,
  `ZOffset` -1.5 to -2 so the body covers their middle and they frame it.
- **Spiral ribbons:** 2-3 orbiting attachment pairs (250-420° a second, radius
  1.6-2, spread over the body's height) with Trails 0.3-0.55 s long and about
  0.6 studs wide, Transparency starting at 0 or they vanish on a bright floor.
- **A wrapping texture on the body:** electric arcs with a flicker curve, or a
  camera-facing swirl ring, as an emitter directly on the body part.
- **Rising streaks** (`VelocityParallel`) from a ring at the feet; flames that
  shoot up and stop (Speed 8-25, Drag 5, `Squash` 0 to 0.4).
- **Fizz:** tiny dots at a high rate on each limb make the body crackle.

## 5. No detailed ground circle under an aura

**Why:** "there's enough going on" (2026-10-10).

**How to apply:** a soft flat ground glow or rising streaks from the feet are
enough.

## 6. Darkness through black twins, not a dark blob

**Why:** the user asked for darkness on the Spirit aura, then rejected a solid
dark-energy blob over the body (2026-10-10), even though the reference
PurpleEnergyAura uses one.

**How to apply:** black twins of flames and streaks (`LightEmission` 0, a
`ZOffset` step behind, a little bigger), so dark tongues lick up between the
coloured ones.

## 7. Electric auras use fine lines

**Why:** chunky bolt sprites and big beams read as cartoon and were rejected
(2026-10-10).

**How to apply:** many thin hairline lightning snaps hugging every body part
(Size about 2.7 to 0.6 to 2.1, Lifetime 0.2-0.3, not locked to the part).

## 8. One hero layer

**Why:** a Thunder aura with snaps, flashes, a shockwave, arcs and bolts all at
once was "too many competing particle effects" (2026-10-10).

**How to apply:** pick the single element the effect is about (Thunder's
scrolling bolts, Spirit's rising flame column) and keep everything else small
and sparse. Keep stacked additive layers in check: carry substance with shaped
textures, not glow (Spirit 2026-10-09).

## 9. Detailed textures over many layers

**Why:** the user's reference effects (`studied.md`) use 3-7 layers, each a
detailed painted texture; our 2026-10-09 auras had 15+ layers of simple shapes
and looked worse than a three-layer magic circle.

**How to apply:** before drawing, list the 3-6 sub-shapes inside each texture
(bands, glyphs, spokes, several tapered strokes, painted inner tongues). If an
effect needs more than about 8 layers to look busy, draw a better texture
instead of adding layers. Ground and ring textures need structure all the way
round (ticks, runes, notches, inner and outer bands, broken arcs); a plain soft
ring reads as a halo.

## 10. Tint only greyscale textures

**Why:** magenta over a reference fire sheet with orange baked in rendered red
(2026-10-10).

**How to apply:** `Color` multiplies the texture. Check that a borrowed texture
is greyscale before tinting it to another hue (`studied.md` lists the baked
ones). Tiers of a set differ in silhouette and motion, not only colour.

## 11. Beam textures run vertically

**Why:** a pillar drawn with its bright core along X showed nothing
(2026-10-10).

**How to apply:** on a Beam or Trail the image's Y axis runs along its length
and X across its width; draw the core as a vertical line (`vfx-motion.md`).

## 12. `VelocityPerpendicular` at Speed 0 vanishes on a moving part

**Why:** ground rings at Speed 0 drew nothing on the aura walkers
(2026-10-10), though Speed 0 works on a static part (the reference aura).

**How to apply:** always give flat sprites Speed 0.001.
