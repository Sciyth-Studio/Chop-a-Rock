---
description: ChatGPT reference sheet (2026-10-13) for the Diamond Rock remodel - the whole rock is a cyan crystal cluster, no stone body; open before modelling it.
type: reference
---
# Diamond Rock reference

![[Diamond Rock Reference.webp]]

The user chose (2026-10-13) to make the whole Diamond Rock out of crystals rather than a grey boulder with gems. It replaces the placeholder `Model_Rock_Diamond` (the boulder mesh x2.2, 25.5 x 15.5 x 21.9 studs, colour 0, 160, 230, split with `Model_RockSplit_Boulder`).

What to take from the sheet:
- **Shape:** a low faceted crystal base (a rounded, slightly sloped pedestal) with chunky hexagonal-ish crystals growing out of it. Tall ones are in the middle and shorter ones lean outward around the edge. The top view (bottom middle) shows them radiating out on every side.
- **Faceting:** each crystal is a prism with a pointed tip of 3 to 5 flat faces. There's no surface detail.
- **Colour:** one pale cyan for the whole thing. In game the colour comes from the part.
- **Ignore:** the views don't agree with each other. In the top-middle view one side is a single big slab, which the other views don't show. The cluster also came out about as tall as it is wide, not the requested 26 x 15 x 22.

User choices 2026-10-13: about 26 x 20 x 22 studs (the same footprint as before, a bit taller), small crystals all the way round instead of the big slab, the usual stud overlay, and the colour kept at 0, 160, 230. Claude's first Blender draft is a 9-sided faceted base with one tall centre crystal, 5 medium crystals tilted about 20° and 7 short ones tilted about 40°, all six-sided prisms with pointed tips. It is 402 tris, clean, 25 x 19.6 x 20.4 studs, with a straight split at x = 0 (54 / 46). Approved and wired 2026-10-13: `assets/Rocks/Diamond/DiamondRock/` (FBX, split, previews, `.blend`), uploaded as assets 81055104900239 (rock) and 119703443673784 (split). It replaced the placeholder in place, keeping its Highlight, and has no `RockKey`.

Related: [[Diamond Rock]], [[Boulder Reference]]

**2026-11-09 remodel (user):** the Diamond Rock is being remodelled in meshlab (Lune) at twice its size, from the event timer icon: a grey stone base with big cyan crystals instead of the all-crystal cluster. The reference sheet prompt is in `assets/Rocks/Diamond/DiamondRockV2/Prompt.md` (attach `assets/Icons/EventTimers/DiamondRock.png`). Waiting on the sheet.

**2026-11-09 sheets:** the first v2 sheet (grey slab with nine cyan crystals) is kept as an example of what's too plain, and the user wants it "more extravagant... a cool server event":

![[Diamond Rock V2 First Try.webp]]

Second prompt, "Diamond Colossus" (in `Prompt.md`, run with no reference image attached, user 2026-11-09): a cracked stone crater, tiered crystal crown, a glowing diamond heart, a floating shard ring, glowing cracks. It's built in meshlab as `Base` / `Crystals` / `Core` / `Shards` parts so the core can pulse and the shards can spin. Final in-game size is about 100 studs across (2x the current in-game size), modelled at that size with `ArenaScale` back to 1.

**Diamond Colossus sheet (2026-11-09):**

![[Diamond Colossus Sheet.webp]]

What to take from it: a ring of chunky tilted grey stone slabs; a tall hexagonal central spire with a crown of large spires and a low ring of spikes over the rim (12-fold from above); a white-cyan brilliant-cut diamond heart in the middle; 8-10 floating shards; cyan cracks in the stone. Ignore: the views disagree on where the heart sits (front centre, then off to the left or right). It goes dead centre, raised, with gaps between the spires so it shows from every side. The soft halo around the heart is a lighting effect, not geometry.

**Draft 1 (2026-11-09, approved and imported, see [[Diamond Rock]]):** `tools/meshlab/models/DiamondRock.luau`, about 100 x 90 studs, 3,588 tris: Body 1.8k (12-sided mound + 22 tilted slabs + rim chunks, studs), Crystals ~830 (centre spire out of the heart's top, 8 crown spires, 14 rim spikes over the edge), Shards 480 (10 bipyramids, 3 heights), Core 48 (8-sided brilliant cut, radius 19, centre at y 35), Veins ~600 (zigzag strips on two of every three slabs + 6 radial strips on the mound). The shading bake needs `cell = 9` at this size; `2.5` split the body into 10k triangles. The preview render can't show Neon, so the heart and veins look pale.

![[Diamond Colossus Draft 1.png]]
