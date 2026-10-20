# Ocean Rok prompts

Body colour: coral orange, RGB 255, 95, 70 (user's pick 2026-10-16, from coral and starfish). It stands out from the dark navy floor (0, 55, 110) and lets the blue bubbles and cyan glows pop. Props avoid orange so they read on the body: Reefy's coral is violet, Chompy's shark hood is grey with glowing cyan gill stripes.

Batch run: run the lineup, then all six sheet prompts (each in its own chat), and send the six sheets back together, saying which view is the front. Claude models all six side by side in one Blender scene and renders them together for feedback.

**Step 1: the lineup.** Attach `Vault/Attachments/Bloky Reference Sheet.png` plus your colour/finish references.

```text
Using the attached Bloky sheet for the body shape and eyes (not its grey colour), and the other attached images ONLY for color palette, lighting, and finish, generate ONE image: a lineup of six cute pet rocks for a Roblox game's deep ocean zone, ordered left to right from most common to rarest.

ALL SIX:
- Each is a rock with Bloky's two chamfered-square cartoon eyes on the front (white square, black chamfered-square pupil, small white square glint at top right). No mouth, no limbs, no fins, no tails, and no animal parts except Glowy's gills (Chompy only wears a shark costume hood; the rock under it is plain). The rock body is a bright, saturated coral orange like living coral or a starfish, NOT grey, brown, red, pink or yellow. All six share this body colour.
- Low-poly faceted surfaces: broad flat planes meeting at soft angles. Flat bottoms. No cracks, studs, or texture. Plain flat-colored faces only.
- Rarer ones look more special: more detail, brighter colours, glowing parts on the last two.

LEFT TO RIGHT:
1. Drip (Common): Bloky's cube rounded off into a plump, round water drop: almost a ball, fat and bulging at the bottom, with only a small soft point on top. No sharp corners anywhere. No prop.
2. Bubbly (Uncommon): Bloky's cube with a cluster of five or six bright blue bubbles of different sizes stacked on top, touching each other.
3. Shelly (Rare): Bloky's cube with two seashells on top (a white spiral shell and a lilac fan shell) and a tuft of bright green seaweed behind them.
4. Reefy (Epic): Bloky's cube wearing a crown of bright violet branching coral, like little antlers spreading up from the top.
5. Glowy (Legendary): Bloky's cube with a thin dark curved stalk rising from the back of its top and arching forward, ending in a glowing bright cyan lamp that hangs above the eyes, like an anglerfish lure. On each side of the body, three frilly fish gills: curved slits cut into the rock with thin glowing cyan frills peeking out of them. Otherwise the body stays a plain rock: no fins, tail or fish shape.
6. Chompy (Secret): Bloky's cube wearing a cute kid's shark-costume hood over its top, back and sides: a grey shark head with a tall dorsal fin on top, a little tail fin at the back, and a wide-open jaw ringed with white triangle teeth around the front. The rock's coral orange face and eyes peek out through the open mouth. Glowing bright cyan gill stripes on the hood's sides and a glowing cyan edge along the fin. It should look like the funniest, most special Rok in the lineup.

LAYOUT:
- Top row: all six from the front, side by side, same scale, standing on one ground line. Bottom row: the same six in the same order from a 3/4 view.
- Plain light-grey background, even lighting, no dramatic shadows. No text, labels, or watermarks.
```

**Step 2: one six-view sheet per Rok.** Once you're happy with the lineup, run each prompt below in its own chat with the lineup image and the Bloky sheet attached.

## Drip (Common)

```text
Using the attached ocean Rok lineup (the FIRST rock, Drip, left-most) as the design to match exactly, and the attached Bloky sheet for the body shape and eyes (not its grey colour), generate ONE image: a model reference sheet of that single pet rock for a Roblox game.

SHAPE:
- The body is Bloky's chamfered cube rounded off into a plump, round water drop: almost a ball, fat and bulging around the lower half, with only a small soft point on top. No sharp corners anywhere. It is built from many small flat facets so it still reads as a smooth-worn rock, not a liquid drop. The bottom is flattened just enough to sit steady. Bright, saturated coral orange like living coral, matching the lineup, NOT grey, brown, red, pink or yellow.
- The eyes are exactly Bloky's: two chamfered-square cartoon eyes on the front, standing slightly out, on the round lower half. No mouth, no limbs. No prop.
- Low-poly faceted surfaces: flat planes meeting at soft angles. Simple enough to model in under 400 triangles.
- Flat bottom, sitting on the ground. Clean surface with no cracks, studs, or texture. Plain flat-colored faces only.

LAYOUT:
- A single image showing the SAME pet rock from 6 views in a grid: front, back, left side, right side, top-down, and one 3/4 perspective view.
- The 5 flat views are orthographic: straight-on, no perspective distortion, camera level for the side views.
- Identical in every view: same shape, proportions, and colors. Same scale and aligned like a blueprint.
- Plain light-grey background, even lighting, no dramatic shadows. No text, labels, or watermarks.
```

## Bubbly (Uncommon)

```text
Using the attached ocean Rok lineup as the design to match exactly (Bubbly, the 2nd from the left), and the attached Bloky sheet for the body shape and eyes (not its grey colour), generate ONE image: a model reference sheet of that single pet rock for a Roblox game.

SHAPE:
- The body shape and eyes are exactly Bloky's: a chunky chamfered cube with two chamfered-square cartoon eyes on the front. No mouth, no limbs. The body is bright, saturated coral orange like living coral, matching the lineup, NOT grey, brown, red, pink or yellow.
- A cluster of five or six bright blue bubbles sits on top: one big bubble in the middle and smaller ones around and above it, all touching each other and the top of the body, rising about half the body's height. Each bubble is a low-poly faceted ball in a solid bright blue with one small white square highlight. They must not cover the eyes.
- Low-poly faceted surfaces: broad flat planes meeting at soft angles. The bubbles together are simple enough to model in under 300 triangles.
- Flat bottom, sitting on the ground. Clean surface with no cracks, studs, or texture. Plain flat-colored faces only.

LAYOUT:
- A single image showing the SAME pet rock from 6 views in a grid: front, back, left side, right side, top-down, and one 3/4 perspective view.
- The 5 flat views are orthographic: straight-on, no perspective distortion, camera level for the side views.
- Identical in every view: same shape, proportions, and colors. Same scale and aligned like a blueprint.
- Plain light-grey background, even lighting, no dramatic shadows. No text, labels, or watermarks.
```

## Shelly (Rare)

```text
Using the attached ocean Rok lineup as the design to match exactly (Shelly, the 3rd from the left), and the attached Bloky sheet for the body shape and eyes (not its grey colour), generate ONE image: a model reference sheet of that single pet rock for a Roblox game.

SHAPE:
- The body shape and eyes are exactly Bloky's: a chunky chamfered cube with two chamfered-square cartoon eyes on the front. No mouth, no limbs. The body is bright, saturated coral orange like living coral, matching the lineup, NOT grey, brown, red, pink or yellow.
- Two seashells sit on top: a white cone-shaped spiral shell lying on its side toward the front left, and a lilac fan-shaped scallop shell standing up toward the front right. Behind them a tuft of four or five bright green seaweed blades grows up from the top, taller than the shells and gently curving.
- Low-poly faceted surfaces: broad flat planes meeting at soft angles. Shells and seaweed together simple enough to model in under 400 triangles.
- Flat bottom, sitting on the ground. Clean surface with no cracks, studs, or texture. Plain flat-colored faces only.

LAYOUT:
- A single image showing the SAME pet rock from 6 views in a grid: front, back, left side, right side, top-down, and one 3/4 perspective view.
- The 5 flat views are orthographic: straight-on, no perspective distortion, camera level for the side views.
- Identical in every view: same shape, proportions, and colors. Same scale and aligned like a blueprint.
- Plain light-grey background, even lighting, no dramatic shadows. No text, labels, or watermarks.
```

## Reefy (Epic)

```text
Using the attached ocean Rok lineup as the design to match exactly (Reefy, the 4th from the left), and the attached Bloky sheet for the body shape and eyes (not its grey colour), generate ONE image: a model reference sheet of that single pet rock for a Roblox game.

SHAPE:
- The body shape and eyes are exactly Bloky's: a chunky chamfered cube with two chamfered-square cartoon eyes on the front. No mouth, no limbs. The body is bright, saturated coral orange like living coral, matching the lineup, NOT grey, brown, red, pink or yellow.
- A crown of bright violet branching coral grows from the top: three or four thick stubby coral trunks that split into rounded branch tips, like little antlers, spreading up and out to about the body's width and about two thirds of its height. A few small bright pink round polyps dot the branch tips.
- Low-poly faceted surfaces: broad flat planes meeting at soft angles. The coral is simple enough to model in under 400 triangles.
- Flat bottom, sitting on the ground. Clean surface with no cracks, studs, or texture. Plain flat-colored faces only.

LAYOUT:
- A single image showing the SAME pet rock from 6 views in a grid: front, back, left side, right side, top-down, and one 3/4 perspective view.
- The 5 flat views are orthographic: straight-on, no perspective distortion, camera level for the side views.
- Identical in every view: same shape, proportions, and colors. Same scale and aligned like a blueprint.
- Plain light-grey background, even lighting, no dramatic shadows. No text, labels, or watermarks.
```

## Glowy (Legendary)

```text
Using the attached ocean Rok lineup as the design to match exactly (Glowy, the 5th from the left), and the attached Bloky sheet for the body shape and eyes (not its grey colour), generate ONE image: a model reference sheet of that single pet rock for a Roblox game.

SHAPE:
- The body shape and eyes are exactly Bloky's: a chunky chamfered cube with two chamfered-square cartoon eyes on the front. No mouth, no limbs, no fins, no tail, no teeth, no fish body. The body is bright, saturated coral orange like living coral, matching the lineup, NOT grey, brown, red, pink or yellow.
- An anglerfish-style lure: a thin dark navy stalk grows from the back half of the top, rises about half the body's height and curves forward, ending in a round glowing lamp that hangs out in front of the body, above the eyes and not covering them. The lamp is a faceted ball in bright glowing cyan, emissive, about the size of one eye.
- Fish gills on both sides: on the left and right faces, toward the front, three curved vertical slits are cut into the rock, stacked front to back like a fish's gills. A thin frilly glowing cyan fringe peeks out of each slit, emissive like the lamp.
- Low-poly faceted surfaces: broad flat planes meeting at soft angles. Stalk, lamp and gills together simple enough to model in under 400 triangles.
- Flat bottom, sitting on the ground. Clean surface with no cracks, studs, or texture. Plain flat-colored faces only.

LAYOUT:
- A single image showing the SAME pet rock from 6 views in a grid: front, back, left side, right side, top-down, and one 3/4 perspective view.
- The 5 flat views are orthographic: straight-on, no perspective distortion, camera level for the side views.
- Identical in every view: same shape, proportions, and colors. Same scale and aligned like a blueprint.
- Plain light-grey background, even lighting, no dramatic shadows. No text, labels, or watermarks.
```

## Chompy (Secret)

```text
Using the attached ocean Rok lineup as the design to match exactly (Chompy, the 6th from the left), and the attached Bloky sheet for the body shape and eyes (not its grey colour), generate ONE image: a model reference sheet of that single pet rock for a Roblox game.

SHAPE:
- The body shape and eyes are exactly Bloky's: a chunky chamfered cube with two chamfered-square cartoon eyes on the front. No mouth, no limbs, no fins or tail on the rock itself. The body is bright, saturated coral orange like living coral, matching the lineup, NOT grey, brown, red, pink or yellow.
- The rock wears a cute kid's shark-costume hood, like a onesie hood, fitting snugly over its top, back and both sides and reaching about two thirds of the way down. The hood is a neutral grey shark head: a tall, slightly swept-back dorsal fin stands up from the middle of the top, and a small tail fin sticks out from the back. The hood's front edge is a wide-open shark jaw that frames the rock's face: a ring of white triangle teeth points inward along the top and sides of the opening, and the coral orange face with Bloky's eyes peeks out through the mouth. The teeth must not cover the eyes.
- Glowing accents: three bright glowing cyan gill stripes on each side of the hood, and a thin glowing cyan edge along the back of the dorsal fin. Everything cyan is emissive.
- The hood is a separate shell sitting on the rock, a little thicker than a skin, with its own flat faces.
- Low-poly faceted surfaces: broad flat planes meeting at soft angles. Hood, fins, teeth and gill stripes together simple enough to model in under 600 triangles.
- Flat bottom, sitting on the ground. Clean surface with no cracks, studs, or texture. Plain flat-colored faces only.

LAYOUT:
- A single image showing the SAME pet rock from 6 views in a grid: front, back, left side, right side, top-down, and one 3/4 perspective view.
- The 5 flat views are orthographic: straight-on, no perspective distortion, camera level for the side views.
- Identical in every view: same shape, proportions, and colors. Same scale and aligned like a blueprint.
- Plain light-grey background, even lighting, no dramatic shadows. No text, labels, or watermarks.
```
