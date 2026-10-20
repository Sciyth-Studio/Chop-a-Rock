# Snow Rok prompts

Body colour: frost blue, RGB 40, 150, 255 (user's pick 2026-10-19). It reads as snow and ice against the near-white floor (240, 245, 255). Props avoid blue so they read on the body: a red beanie with a white pompom, a red-and-white scarf with yellow earmuffs, a black top hat, a green pine with warm glowing lights, and glowing golden stars.

Batch run: run the lineup, then all six sheet prompts (each in its own chat), and send the six sheets back together, saying which view is the front. Claude models all six side by side in one Blender scene and renders them together for feedback.

**Step 1: the lineup.** Attach `Vault/Attachments/Bloky Reference Sheet.png` plus your colour/finish references.

```text
Using the attached Bloky sheet for the body shape and eyes (not its grey colour), and the other attached images ONLY for color palette, lighting, and finish, generate ONE image: a lineup of six cute pet rocks for a Roblox game's snowy mountain zone, ordered left to right from most common to rarest.

ALL SIX:
- Each is a rock with Bloky's two chamfered-square cartoon eyes on the front (white square, black chamfered-square pupil, small white square glint at top right). No mouth, no limbs, no animal parts. The rock body is a bright, saturated frost blue like glacier ice, NOT grey, white, navy, purple or pale blue. All six share this body colour.
- Low-poly faceted surfaces: broad flat planes meeting at soft angles. Flat bottoms. No cracks, studs, or texture. Plain flat-colored faces only.
- Rarer ones look more special: more detail, brighter colours, glowing parts on the last two.

LEFT TO RIGHT:
1. Hexy (Common): Bloky's cube reshaped into a chunky six-sided block, like a short hexagonal pillar standing upright, with soft chamfered edges. No prop.
2. Beanie (Uncommon): Bloky's cube wearing a snug red knitted beanie with a folded white cuff and a big fluffy white pompom on top.
3. Cozy (Rare): Bloky's cube with a red-and-white striped knitted scarf wrapped around its lower half, one end hanging down the side, and fluffy yellow earmuffs on a thin band over its top.
4. Stacky (Epic): Bloky's cube with two smaller frost blue rocks stacked on top of it like a little snowman, the top one wearing a tiny black top hat with a red band. Only the big bottom rock has eyes.
5. Piney (Legendary): Bloky's cube with a small green pine tree growing from the back of its top, its branches dusted with white snow and dotted with glowing warm yellow, red and green fairy lights, and a glowing golden star on top.
6. Starry (Secret): Bloky's cube circled by a tilted glowing golden ring, like a little planet's ring, with five glowing golden five-pointed stars of different sizes sitting along it, plus one bigger glowing star floating just above its head.

LAYOUT:
- Top row: all six from the front, side by side, same scale, standing on one ground line. Bottom row: the same six in the same order from a 3/4 view.
- Plain light-grey background, even lighting, no dramatic shadows. No text, labels, or watermarks.
```

**Step 2: one six-view sheet per Rok.** Once you're happy with the lineup, run each prompt below in its own chat with the lineup image and the Bloky sheet attached.

## Hexy (Common)

```text
Using the attached snow Rok lineup (the FIRST rock, Hexy, left-most) as the design to match exactly, and the attached Bloky sheet for the body shape and eyes (not its grey colour), generate ONE image: a model reference sheet of that single pet rock for a Roblox game.

SHAPE:
- The body is Bloky's chamfered cube reshaped into a chunky six-sided block: a short, wide hexagonal pillar standing upright, with a flat hexagonal top and bottom, a flat face pointing straight forward, and soft chamfers on every edge. It is about as wide as it is tall. Bright, saturated frost blue like glacier ice, matching the lineup, NOT grey, white, navy, purple or pale blue.
- The eyes are exactly Bloky's: two chamfered-square cartoon eyes on the front face, standing slightly out. No mouth, no limbs. No prop.
- Low-poly faceted surfaces: broad flat planes meeting at soft angles. Simple enough to model in under 300 triangles.
- Flat bottom, sitting on the ground. Clean surface with no cracks, studs, or texture. Plain flat-colored faces only.

LAYOUT:
- A single image showing the SAME pet rock from 6 views in a grid: front, back, left side, right side, top-down, and one 3/4 perspective view.
- The 5 flat views are orthographic: straight-on, no perspective distortion, camera level for the side views.
- Identical in every view: same shape, proportions, and colors. Same scale and aligned like a blueprint.
- Plain light-grey background, even lighting, no dramatic shadows. No text, labels, or watermarks.
```

## Beanie (Uncommon)

```text
Using the attached snow Rok lineup as the design to match exactly (Beanie, the 2nd from the left), and the attached Bloky sheet for the body shape and eyes (not its grey colour), generate ONE image: a model reference sheet of that single pet rock for a Roblox game.

SHAPE:
- The body shape and eyes are exactly Bloky's: a chunky chamfered cube with two chamfered-square cartoon eyes on the front. No mouth, no limbs. The body is bright, saturated frost blue like glacier ice, matching the lineup, NOT grey, white, navy, purple or pale blue.
- A snug bright red knitted beanie sits on top, covering the top and the upper sides down to just above the eyes, with a thick folded white cuff around its rim and a big round fluffy white pompom on top. The knit is shown only as a few broad vertical ridges, not a texture. The beanie must not cover the eyes.
- Low-poly faceted surfaces: broad flat planes meeting at soft angles. Beanie, cuff and pompom together simple enough to model in under 400 triangles.
- Flat bottom, sitting on the ground. Clean surface with no cracks, studs, or texture. Plain flat-colored faces only.

LAYOUT:
- A single image showing the SAME pet rock from 6 views in a grid: front, back, left side, right side, top-down, and one 3/4 perspective view.
- The 5 flat views are orthographic: straight-on, no perspective distortion, camera level for the side views.
- Identical in every view: same shape, proportions, and colors. Same scale and aligned like a blueprint.
- Plain light-grey background, even lighting, no dramatic shadows. No text, labels, or watermarks.
```

## Cozy (Rare)

```text
Using the attached snow Rok lineup as the design to match exactly (Cozy, the 3rd from the left), and the attached Bloky sheet for the body shape and eyes (not its grey colour), generate ONE image: a model reference sheet of that single pet rock for a Roblox game.

SHAPE:
- The body shape and eyes are exactly Bloky's: a chunky chamfered cube with two chamfered-square cartoon eyes on the front. No mouth, no limbs. The body is bright, saturated frost blue like glacier ice, matching the lineup, NOT grey, white, navy, purple or pale blue.
- A thick knitted scarf in bold red and white stripes wraps once around the lower half of the body, below the eyes, tied at the front right, with one end hanging down the right side to the ground.
- Fluffy bright yellow earmuffs: a thin dark grey band arches over the top from side to side, ending in two round fluffy yellow muffs on the left and right sides at eye height. They must not cover the eyes.
- Low-poly faceted surfaces: broad flat planes meeting at soft angles. Scarf and earmuffs together simple enough to model in under 400 triangles.
- Flat bottom, sitting on the ground. Clean surface with no cracks, studs, or texture. Plain flat-colored faces only.

LAYOUT:
- A single image showing the SAME pet rock from 6 views in a grid: front, back, left side, right side, top-down, and one 3/4 perspective view.
- The 5 flat views are orthographic: straight-on, no perspective distortion, camera level for the side views.
- Identical in every view: same shape, proportions, and colors. Same scale and aligned like a blueprint.
- Plain light-grey background, even lighting, no dramatic shadows. No text, labels, or watermarks.
```

## Stacky (Epic)

```text
Using the attached snow Rok lineup as the design to match exactly (Stacky, the 4th from the left), and the attached Bloky sheet for the body shape and eyes (not its grey colour), generate ONE image: a model reference sheet of that single pet rock for a Roblox game.

SHAPE:
- The body shape and eyes are exactly Bloky's: a chunky chamfered cube with two chamfered-square cartoon eyes on the front. No mouth, no limbs. The body is bright, saturated frost blue like glacier ice, matching the lineup, NOT grey, white, navy, purple or pale blue.
- Two smaller frost blue chamfered rocks are stacked on top like a little snowman: the middle one about two thirds of the body's width, the top one about half its width, each slightly turned so the stack looks hand-built. Only the big bottom rock has eyes.
- The top rock wears a tiny black top hat with a red band, tilted a little to one side.
- Low-poly faceted surfaces: broad flat planes meeting at soft angles. The two small rocks and the hat together simple enough to model in under 300 triangles.
- Flat bottom, sitting on the ground. Clean surface with no cracks, studs, or texture. Plain flat-colored faces only.

LAYOUT:
- A single image showing the SAME pet rock from 6 views in a grid: front, back, left side, right side, top-down, and one 3/4 perspective view.
- The 5 flat views are orthographic: straight-on, no perspective distortion, camera level for the side views.
- Identical in every view: same shape, proportions, and colors. Same scale and aligned like a blueprint.
- Plain light-grey background, even lighting, no dramatic shadows. No text, labels, or watermarks.
```

## Piney (Legendary)

```text
Using the attached snow Rok lineup as the design to match exactly (Piney, the 5th from the left), and the attached Bloky sheet for the body shape and eyes (not its grey colour), generate ONE image: a model reference sheet of that single pet rock for a Roblox game.

SHAPE:
- The body shape and eyes are exactly Bloky's: a chunky chamfered cube with two chamfered-square cartoon eyes on the front. No mouth, no limbs. The body is bright, saturated frost blue like glacier ice, matching the lineup, NOT grey, white, navy, purple or pale blue.
- A small bright green pine tree grows from the back half of the top, about as tall as the body: three stacked tiers of faceted cone branches on a short brown trunk, each tier's upper edge capped with white snow.
- Glowing fairy lights: about nine small round bulbs dotted around the tiers in warm yellow, red and green, all bright and emissive. A glowing golden five-pointed star sits on the tip.
- Low-poly faceted surfaces: broad flat planes meeting at soft angles. Tree, snow, lights and star together simple enough to model in under 500 triangles.
- Flat bottom, sitting on the ground. Clean surface with no cracks, studs, or texture. Plain flat-colored faces only.

LAYOUT:
- A single image showing the SAME pet rock from 6 views in a grid: front, back, left side, right side, top-down, and one 3/4 perspective view.
- The 5 flat views are orthographic: straight-on, no perspective distortion, camera level for the side views.
- Identical in every view: same shape, proportions, and colors. Same scale and aligned like a blueprint.
- Plain light-grey background, even lighting, no dramatic shadows. No text, labels, or watermarks.
```

## Starry (Secret)

```text
Using the attached snow Rok lineup as the design to match exactly (Starry, the 6th from the left), and the attached Bloky sheet for the body shape and eyes (not its grey colour), generate ONE image: a model reference sheet of that single pet rock for a Roblox game.

SHAPE:
- The body shape and eyes are exactly Bloky's: a chunky chamfered cube with two chamfered-square cartoon eyes on the front. No mouth, no limbs. The body is bright, saturated frost blue like glacier ice, matching the lineup, NOT grey, white, navy, purple or pale blue.
- A thin, flat glowing golden ring circles the body like a little planet's ring, tilted about 20 degrees, passing below the eyes at the front and higher at the back, a little wider than the body all round. It touches the body at the sides.
- Five glowing golden five-pointed stars of different sizes sit along the ring, standing upright like charms on a bracelet, none in front of the eyes. One bigger glowing golden star floats just above the centre of the top, held by a short thin glowing stalk.
- Everything golden is bright and emissive.
- Low-poly faceted surfaces: broad flat planes meeting at soft angles. Ring and stars together simple enough to model in under 500 triangles.
- Flat bottom, sitting on the ground. Clean surface with no cracks, studs, or texture. Plain flat-colored faces only.

LAYOUT:
- A single image showing the SAME pet rock from 6 views in a grid: front, back, left side, right side, top-down, and one 3/4 perspective view.
- The 5 flat views are orthographic: straight-on, no perspective distortion, camera level for the side views.
- Identical in every view: same shape, proportions, and colors. Same scale and aligned like a blueprint.
- Plain light-grey background, even lighting, no dramatic shadows. No text, labels, or watermarks.
```
