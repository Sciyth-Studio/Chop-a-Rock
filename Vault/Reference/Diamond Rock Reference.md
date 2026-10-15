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
