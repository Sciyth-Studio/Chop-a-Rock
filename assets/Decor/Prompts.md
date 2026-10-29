# Zone decor prompts

Twelve simple props, shown in two lineups of six so each prop stays big and clear. Run each prompt in its own chat with no images attached; the look is described in the prompt.

Rewritten 2026-10-28: cartoon versions of the real things, not blocky or brick-built (the user: the blocky sheets "look like legos"). Built with meshlab (lathes, lofts, tubes, smooth Organic blobs) with the colours baked in. Studs come from the Studio material, so the sheets show none. The snowy pine is the forest pine recoloured, so it has no slot.

**Lineup A: shared, forest, desert**

```text
Generate ONE image: a lineup of six simple decoration props for a bright, cartoony Roblox game, left to right.

STYLE:
- Stylised cartoon versions of the real things, like props in a polished Roblox simulator game or an animated kids' film: simple, chunky, slightly exaggerated proportions, soft rounded forms, clean silhouettes. Not built from blocks or bricks, not voxel, not realistic.
- Highly saturated, vivid colours: pure grass green, bright chocolate brown, fire-engine red, sunny orange, hot pink. No muted, pastel, dusty or greyish tones.
- Smooth matte plastic finish, flat colour per part with gentle shading. No texture, studs, cracks, gradients or fine detail.
- Soft, even studio lighting. Each prop sits flat on the ground.

LEFT TO RIGHT:
1. Pine tree: a short brown trunk and three stacked green cone tiers with soft rounded edges, each smaller than the one below, slightly wavy bottom rims.
2. Bush: a round, puffy green bush made of four or five soft overlapping balls, wider than tall.
3. Tree stump: a short wide brown stump, flared at the base with a few roots, a light tan cut top with growth rings.
4. Mushroom: a thick cream stem, a big round red dome cap with round white spots.
5. Cactus: a classic cartoon saguaro, a tall rounded green column with two bent arms going up, one higher than the other, soft vertical ribs.
6. Prickly pear: four or five flat oval green pads growing out of each other at angles, with two pink flowers on the top edges.

LAYOUT:
- Top row: all six from the front, side by side, standing on one ground line. Bottom row: the same six in the same order from a 3/4 view.
- Props are NOT to scale: each one fills its own slot so its shape is clear.
- Plain light-grey background, even lighting, no dramatic shadows. No text, labels or watermarks.
```

**Lineup B: jungle, ocean, snow**

```text
Generate ONE image: a lineup of six simple decoration props for a bright, cartoony Roblox game, left to right.

STYLE:
- Stylised cartoon versions of the real things, like props in a polished Roblox simulator game or an animated kids' film: simple, chunky, slightly exaggerated proportions, soft rounded forms, clean silhouettes. Not built from blocks or bricks, not voxel, not realistic.
- Highly saturated, vivid colours: pure grass green, bright chocolate brown, hot pink, sunny orange, snow white. No muted, pastel, dusty or greyish tones.
- Smooth matte plastic finish, flat colour per part with gentle shading. No texture, studs, cracks, gradients or fine detail.
- Soft, even studio lighting. Each prop sits flat on the ground.

LEFT TO RIGHT:
1. Palm tree: a gently curved, ringed brown trunk with a crown of six or seven big drooping green fronds and a few coconuts.
2. Leaf plant: a tropical plant of five or six big broad pointed green leaves fanning up and out from the ground, waist height.
3. Kelp: three tall wavy olive-green kelp ribbons rising from the ground, different heights, a few small float bulbs.
4. Coral: a hot pink branching coral, a short trunk splitting into rounded finger-like branches pointing up.
5. Starfish: a plump orange five-point starfish lying flat, raised in the middle, small lighter dots on top.
6. Snow pile: a low, wide, soft white snow drift made of three or four rounded lumps, faint icy blue in the shadows.

LAYOUT:
- Top row: all six from the front, side by side, standing on one ground line. Bottom row: the same six in the same order from a 3/4 view.
- Props are NOT to scale: each one fills its own slot so its shape is clear.
- Plain light-grey background, even lighting, no dramatic shadows. No text, labels or watermarks.
```

The front and 3/4 views are enough to model props this simple, so no six-view sheet per prop unless one comes out unclear. Models: `tools/meshlab/models/Decor*.luau` (first pass was blocky; rework to the sheets).

## Zones 6-10 (2026-10-29)

Props from `World1Plan.md`, as two more lineups of six. Some props reuse existing models instead of getting a new slot:
- Swamp reuses Stump, Mushroom and Bush, recoloured.
- Charred Tree is the Dead Tree recoloured.
- Ash Pile is the Snow Pile recoloured.
- Bamboo Shoot is a short, few-stalk Bamboo Clump (a wrapper, like `DecorSnowPine`).
- The Volcano's glowing floor cracks, smoke, mist and sky tint are Studio parts, particles and lighting, not models.

**Lineup C: swamp, savanna**

```text
Generate ONE image: a lineup of six simple decoration props for a bright, cartoony Roblox game, left to right.

STYLE:
- Stylised cartoon versions of the real things, like props in a polished Roblox simulator game or an animated kids' film: simple, chunky, slightly exaggerated proportions, soft rounded forms, clean silhouettes. Not built from blocks or bricks, not voxel, not realistic.
- Highly saturated, vivid colours: pure grass green, bright chocolate brown, golden yellow, sunny orange, warm terracotta. No muted, pastel, dusty or greyish tones.
- Smooth matte plastic finish, flat colour per part with gentle shading. No texture, studs, cracks, gradients or fine detail.
- Soft, even studio lighting. Each prop sits flat on the ground.

LEFT TO RIGHT:
1. Cattails: a clump of five or six tall thin green reeds of different heights, three of them topped with a fat brown sausage-shaped seed head, a few long thin leaves bending outwards.
2. Lily pads: three flat round green lily pads of different sizes lying on the ground, each with one wedge-shaped notch cut out, one small pink flower sitting on the biggest pad.
3. Dead tree: a bare leafless brown tree, a thick slightly crooked trunk with root flares at the base, splitting into three or four bare twisting branches that end in short forks.
4. Acacia tree: a savanna acacia, a thin brown trunk that forks into two or three angled limbs, topped by one wide, flat, thin green canopy like a tabletop, much wider than the tree is tall.
5. Grass tuft: a clump of tall dry golden-yellow grass blades fanning out from the ground, about knee height, a few blades bending over at the tips.
6. Termite mound: a tall lumpy terracotta-orange mound, wide at the base, rising into two or three rounded chimney-like towers of different heights.

LAYOUT:
- Top row: all six from the front, side by side, standing on one ground line. Bottom row: the same six in the same order from a 3/4 view.
- Props are NOT to scale: each one fills its own slot so its shape is clear.
- Plain light-grey background, even lighting, no dramatic shadows. No text, labels or watermarks.
```

**Lineup D: bamboo, volcano, ruins**

```text
Generate ONE image: a lineup of six simple decoration props for a bright, cartoony Roblox game, left to right.

STYLE:
- Stylised cartoon versions of the real things, like props in a polished Roblox simulator game or an animated kids' film: simple, chunky, slightly exaggerated proportions, soft rounded forms, clean silhouettes. Not built from blocks or bricks, not voxel, not realistic.
- Highly saturated, vivid colours: lime green, leaf green, charcoal black, lava orange, light stone grey, glowing purple. No muted, pastel or dusty tones except where stone grey is asked for.
- Smooth matte plastic finish, flat colour per part with gentle shading. No texture, studs, cracks, gradients or fine detail.
- Soft, even studio lighting. Each prop sits flat on the ground.

LEFT TO RIGHT:
1. Bamboo clump: five or six tall straight lime-green bamboo stalks of different heights growing close together, each with clear ring joints, a few small pointed leaves sprouting near the tops.
2. Mossy stone: a low, rounded grey boulder, wider than tall, with a thick bright green moss cap draped over the top.
3. Smoking vent: a short, wide, cone-shaped charcoal-black rock mound with a round hole in the top, the inside of the hole glowing lava orange, a small puff of grey smoke above it.
4. Broken pillar: a light stone-grey round column with a square base block, broken off part way up with a jagged top, green leafy vines wrapping around it.
5. Statue head: a big toppled carved stone head lying on its side on the ground, light stone grey, simple blocky face with closed eyes and a flat nose, a little moss on top. Not a monster, just an old statue.
6. Rune stone: a tall, thick upright slab of grey stone with a rounded top, a simple carved rune symbol on its front glowing bright purple.

LAYOUT:
- Top row: all six from the front, side by side, standing on one ground line. Bottom row: the same six in the same order from a 3/4 view.
- Props are NOT to scale: each one fills its own slot so its shape is clear.
- Plain light-grey background, even lighting, no dramatic shadows. No text, labels or watermarks.
```

Models go in the JungleTree block style ([[Decor In ForestTree Style]]). Take the parts, proportions and colours from the sheets, not the smooth finish. Greens on green floors sit close to that zone's floor colour.
