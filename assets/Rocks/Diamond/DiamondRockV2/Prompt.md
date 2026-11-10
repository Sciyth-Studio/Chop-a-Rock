# Diamond Rock v2: ChatGPT reference sheet prompt (2026-11-09, second try)

The first sheet (`Sheet_FirstTry.webp`, a grey slab with nine cyan crystals) read too plain for a server-wide boss event. This one is meant to look like a raid boss you hit, not a rock: a giant crystal heart that crashed into the arena, held in a cracked stone crater, with floating shards and a glowing core.

Final size in game: about 100 studs across, twice the current in-game rock. It's built in meshlab as separate parts, so the code can animate them:
- `Base`: the stone crater ring (studs, grey)
- `Crystals`: the big crystal body (cyan, plain faces)
- `Core`: the glowing heart in the middle (Neon, pulses)
- `Shards`: the floating ring of shards (spins slowly around the rock)

How to run: paste the prompt below into ChatGPT with **no images attached** (user, 2026-11-09); the look is written into the prompt. Send the sheet back.

```text
Generate ONE image: a model reference sheet of a single giant "Diamond Colossus" boss rock for a Roblox game, in a bright, flat-coloured, chunky low-poly toy style (like a stylised mobile game asset): solid colours per face, crisp edges, soft even lighting, no realism. It is the centrepiece of a server-wide boss event, so it must look spectacular, powerful and valuable, like a raid boss made of crystal.

SHAPE:
- A wide, cracked grey stone crater ring as the base, as if a huge crystal meteor slammed into the ground: chunky broken stone slabs tilted outward all the way around, with a few big stone chunks thrown up on their edges.
- Bursting out of the crater, a massive cluster of huge faceted cyan diamond crystals in tiers, like a giant crown: one colossal central spire (about twice the base's width tall), a ring of large spires around it leaning outward, then a lower ring of jagged crystal spikes fanning out over the crater rim. Every crystal is a long six-sided prism with a sharp faceted tip. Radiates out evenly on all sides when seen from above.
- In the middle of the cluster, half sunk between the spires, a big round-cut faceted diamond "heart" that glows bright white-cyan from inside, clearly visible from every side through gaps between the spires.
- A ring of 8 to 10 sharp crystal shards floating in mid-air around the upper half of the cluster, evenly spaced, each tilted, not touching anything, like they orbit the rock.
- Thin glowing cyan cracks running across the stone crater toward the crystals.
- Colours: muted grey stone; bright saturated cyan crystals with lighter cyan top faces and deeper blue side faces; white-cyan glowing heart and cracks. No other colours.
- Low-poly faceted surfaces: broad flat planes and crisp edges, chunky toy style, not realistic. Keep it simple enough to be modelled in under 4,000 triangles.
- Flat bottom, sitting on the ground.
- Clean faces with no studs, no surface texture, no particles, no sparkle effects drawn in the air. Plain flat-colored faces only.

LAYOUT:
- A single image showing the SAME Diamond Colossus from 6 views, arranged in a grid: front, back, left side, right side, top-down, and one 3/4 perspective view.
- The 5 flat views (front, back, left, right, top) are orthographic: straight-on with no perspective distortion. Keep the camera level for the side views.
- The Diamond Colossus is identical in every view: same shape, proportions, and colors, the floating shards in the same places.
- Keep the same scale across the flat views, and align them so heights and widths match across views, like a blueprint.
- Plain light-grey background, even lighting, no dramatic shadows.
- No text, labels, or watermarks.
```

## Build notes (step 4, after the sheet comes back)
- meshlab model `tools/meshlab/models/DiamondRock.luau`, built at final size (about 100 studs across, so the stud overlay stays normal size; `DiamondRockConfig.ArenaScale` goes back to 1). Pivot bottom centre, front -Z.
- Parts: `Base` (the main part the chop code uses, grey, `2022 Stud`), `Crystals` (0, 160, 230, plain UVs), `Core` (Neon, white-cyan, pulses), `Shards` (Neon or Glass cyan, spins on Y in `RockController/Diamond.luau`), glowing cracks drawn into `Core` or `Base` as Neon strips. The parts are children of `Rock`, so `ZoneScale.Apply` and the effects keep working.
- Hit feedback ideas once it's in: the shards speed up and the core flashes on each hit, the shards fly off on the break. These are player-facing, so they get proposed before they're built.
- Camera: since 2026-11-09 the chop camera holds the over-the-shoulder shot for the whole Diamond fight (no move to the impact shot and back on every hit).
