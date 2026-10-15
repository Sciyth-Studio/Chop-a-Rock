---
description: 2026-10-14 sheet for the remodelled forest Mossy Boulder (Third tier): faceted grey rock with a separate thick moss cap on top.
type: reference
---
# Mossy Stone reference

Remodel of the forest Third-tier rock (`Third`, "Mossy Boulder"), sheet received 2026-10-14. The user wants the moss as a separate thick piece covering the top, not colour on the stone's faces.

![[Mossy Stone Reference Sheet.png]]

Take from it:
- Stone: chunky, rounded, roughly cube-ish (about as tall as it is wide), slightly flared lower half, flat bottom, broad faceted grey planes.
- Moss: a thick cushion over the whole top, about 40-45% of the total height, overhanging the stone slightly, with a wavy lower edge that dips lower at the front and sides. Rounded square from the top.
- Ignore the sheet's mottled moss texture: the build uses flat faceted green, no texture. The labels are wrong (two "Right Side" and two "Top-Down" views); front, back and the 3/4 view are usable.
- The moss is its own mesh, so the split needs moss halves too, and the Studio rock gains a second part.
- Front is the sheet's Front View panel.

Build (approved 2026-10-14): `build_boulder` seed 7 (width 3.5, depth 3.0, height 2.1, facets 22, min_nz -0.55, center_height 0.55, cut_depth 0.02-0.18, lean 0.05/0.04), then `fix_slivers`: 68 tris, 6.65 x 4.39 x 6.12 studs, the same footprint as the old Stone.

Moss, after two rounds of feedback:
- 0.6 studs thick was too thick; it is 0.32 studs (0.16 units).
- The `snow_cap` edge, stepped along the facets, didn't read as smooth. The cap is now the stone cut by one horizontal plane at 62% height, with a 3-wave lower edge (0.1 units), solidified (even offset off, which made a spike on top) and rim-bevelled 0.05 (one segment, 70 degree limit). About 260 tris, colour (110, 200, 30).
- Bevels often leave self-intersections or open edges in the cap or its split halves. Search the wave phase and bevel width until all three are clean (phase 1.2 here).

Split at x = -0.02, 45/55. Files are in `assets/Rocks/Forest/MossyStoneRock/`, uploaded as 111652374950369 (rock) and 110423050168273 (split).

In Studio this is the forest **Third** rock (Mossy Boulder), not the Stone: it went onto `Model_Rock_Basic` by mistake first and was moved the same day. `Model_Rock_Third` is scaled 2.73x to the old Mossy Boulder's height (18.2 x 12 x 16.7 studs), keeps grey 111 with `2022 Inlet` and has a child `Moss`. `Model_RockSplit_MossyStoneRock` is scaled to match, with `Moss_L` / `Moss_R` under the pieces. The Index preview and Rock Showcase were rebuilt, and in play the moss welds to each spawned rock.

Related: [[Forest Rock Tiers]], [[Rocks Look Like Boulders]]
