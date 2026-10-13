# Rock recipes

Specs of rocks already built with `rock_builder.py`. Use them as starting points or to rebuild a rock exactly.

## BlockRock (Rock_Basic, first chop rock)

Approved 2026-09-30. About 12 x 5.4 x 9.3 studs, 226 tris, plain grey (120, 120, 120) SmoothPlastic. Files in `assets/Rocks/Forest/BlockRock/`. Registry key of its split: `Model_RockSplit_Block`.

```python
blocks = [
    dict(x=0.0, y=0.2, z0=0.0, w=3.6, d=2.8, h=1.6, taper=0.90, clips=[0.5, 0, 0.6, 0.3], rot=4),
    dict(x=-0.2, y=0.3, z0=1.3, w=3.0, d=2.3, h=0.95, taper=0.84, clips=[0.6, 0.5, 0.4, 0.6], rot=-7),
    dict(x=-1.25, y=-1.25, z0=0.0, w=2.0, d=1.3, h=1.15, taper=0.88, clips=[0.4, 0, 0, 0.3], rot=-8),
    dict(x=1.35, y=-1.45, z0=0.0, w=1.5, d=1.1, h=0.7, taper=0.85, clips=[0, 0.35, 0.3, 0], rot=15),
    dict(x=2.1, y=0.4, z0=0.0, w=1.7, d=2.0, h=1.25, taper=0.87, clips=[0, 0.5, 0.4, 0], rot=14),
    dict(x=-2.15, y=0.1, z0=0.0, w=1.4, d=1.9, h=0.95, taper=0.90, clips=[0.4, 0, 0, 0.4], rot=-12),
    dict(x=0.6, y=1.75, z0=0.0, w=2.3, d=1.3, h=1.35, taper=0.88, clips=[0, 0, 0.4, 0.5], rot=6),
    dict(x=-1.5, y=1.6, z0=0.0, w=1.2, d=1.1, h=0.8, taper=0.85, clips=[0.3, 0.3, 0, 0], rot=-20),
]
rock, report = rb.build_rock("BlockRock", blocks, height_scale=1.2, color=(120, 120, 120))
pieces, split_report = rb.split_rock(rock, [(None, None, 0.04)], 0)
```

Split: one straight vertical cut along the chop direction, 0.08 studs off centre, 51/49 by volume, pieces 152 and 110 tris, clearance 0.26.

History: the two front blocks (indices 2 and 3) were at x = -0.9 and 1.0, crowding the centre line so no clean centred cut existed; they were moved apart for the chop-aligned split. Earlier splits (a stepped crack, then a 27-degree diagonal) were rejected because they did not follow the chop.

## BoulderRock (boulder-style chop rock, proposed 2026-10-02)

About 11.6 x 7 x 10 studs, 108 tris, faceted boulder with inlet studs as a see-through overlay (`assets/Textures/Studs/SingleInletStud.png`), grey (120, 120, 120). Files in `assets/Rocks/Forest/BoulderRock/`.

```python
rock, report = rb.build_boulder("BoulderRock", width=6.0, depth=5.0, height=3.5, facets=30,
    cut_depth=(0.02, 0.2), min_nz=-0.5, center_height=0.3, lean=(0.12, 0.08), seed=4)
chosen, tried = rb.find_mesh_split(rock, merges=(0.0,))
pieces, split_report = rb.split_rock(rock, chosen["steps"], 0, chosen["merge"])
```

Split: straight cut along the chop direction at x = 0.06 (0.12 studs off centre), 50.5/49.5 by volume, pieces 72 tris each.

## Desert rocks (2026-10-10, with props)

Built from the desert sheet in the vault (`Reference/Zone Rocks Reference`). Files are in `assets/Rocks/Desert/<Name>/`, and all three share `assets/Rocks/Desert/DesertRocks.blend`. Props are separate meshes in both FBX files (see SKILL.md "Props").

Sandstone (240,190,90), 8 x 4.2 x 7 studs: a layered mini mesa from `build_layers`, seed 5.

    SAND = [dict(cx=0, cy=0, rx=1.95, ry=1.7, z0=0.0, h=0.85, taper=0.86, sides=10),
            dict(cx=-0.1, cy=0.1, rx=1.55, ry=1.35, z0=0.75, h=0.75, taper=0.84, sides=9),
            dict(cx=0.08, cy=0.15, rx=1.1, ry=0.95, z0=1.4, h=0.7, taper=0.8, sides=8)]
    rock, rep = rb.build_layers("Sandstone", SAND, 5, (240, 190, 90))

Prop: `grass_tuft("Sandstone_Grass", (2.15, -0.97, 0), 2)` at the front-right base. Split at x = 0.02, 53/47.

CanyonBoulder (255,120,30), 12 x 6.9 x 10 studs: a tall back-left mass with ledges stepping down to the front-right. Seed 2, then `fix_slivers`.

    CANYON = [dict(cx=0.2, cy=-0.1, rx=3.0, ry=2.45, z0=0.0, h=0.95, taper=0.9, sides=8, jitter=0.1),
              dict(cx=0.55, cy=-0.35, rx=2.0, ry=1.75, z0=0.8, h=1.0, taper=0.88, sides=7, jitter=0.1),
              dict(cx=-0.75, cy=0.45, rx=2.0, ry=1.9, z0=0.0, h=3.0, taper=0.84, sides=8, jitter=0.1),
              dict(cx=-0.85, cy=0.55, rx=1.4, ry=1.3, z0=2.85, h=0.6, taper=0.82, sides=7, jitter=0.08)]

Props: `skull(..., (0.85, -1.15, 1.8), -20 deg, 1.4)` on the middle ledge, then three `flowers` (r 0.28) and a leaf `grass_tuft` on the lower front-right ledge. Split at x = -0.3, 56/44.

CactusBoulder (210,50,20), 18.5 x 12 x 17 studs: `build_boulder(width=9.5, depth=8.5, height=6.0, facets=30, cut_depth=(0.02, 0.2), min_nz=-0.5, center_height=0.3, lean=(0.1, 0.06), seed=4)`. Width, depth and height are studs / 2.

Props: `saguaro` tall (trunk 4.2 x r0.5, arms (1.7,-1,0.75,1.5) and (2.3,1,0.65,1.3)) at (2.3,-0.6), and short (2.6 x r0.45, arm (1.2,-1,0.6,1.0)) at (-2.5,-1.4). Each base is sunk 0.4 below the surface. A `blossom` (r 0.42, tilted 25 deg to the front) sits on the tall cactus's top. Split at x = 0.08, 51/49.

Placing props: find spots by ray-casting down onto the rock (`rock.ray_cast`) and keep only flat hits (normal z > 0.95). Keep every prop fully on one side of x = 0 so it rides with one split half.

## Jungle, ocean and snow rocks (2026-10-10, with props)

Every body is `build_boulder` followed by `fix_slivers`. The `.blend` files are `assets/Rocks/Jungle/JungleRocks.blend`, `Ocean/OceanRocks.blend` and `Snow/SnowRocks.blend`. Props that cross x = 0 are cut in half by `split_with_props`, and `export_rock_set` writes the FBX files and previews.

| Rock | Body (w, d, h units; seed) | Props |
|---|---|---|
| FernRock (70,220,40) | 4, 3.5, 3; s3 | `fern` 8 fronds (30,150,45) on top |
| VineBoulder (20,200,110) | 7, 6, 4.2; s4 | 4 `surface_path` + `tube` vines with wobble (40,150,40), `surface_leaves` (60,190,50), yellow `blossoms` |
| TikiBoulder (255,170,0) | 11, 9.5, 7; s1 | `tiki_face` (170,80,0) on the front, `fern` palm crown (40,180,50) |
| BarnacleRock (0,190,255) | 4.5, 4, 3.5; s2 | 16 `barnacles` (240,235,215) from `surface_spots` |
| KelpBoulder (0,120,255) | 8, 7, 4.5; s3 | `kelp` ribbons (110,130,30), 9 strands from the top outward |
| ReefBoulder (190,60,255) | 12.5, 11, 6; s1 | 3 `coral` (pink, blue, yellow), 3 `anemones`, 2 `starfish` |
| SnowyRock (90,200,255) | 5, 4.5, 4; s7 | `snow_cap` (min_nz 0.5, 0.32 thick) |
| DriftBoulder (40,120,255) | 9, 8, 7.5; s8, `slope_cut` normal (-0.7,0,1) at 0.62 H | `snow_cap` 0.6 thick, `icicles` (185,230,255) under the front lip |
| IglooBoulder (255,90,160) | 14, 12.5, 9; s6, center_height 0.1 | `igloo_bricks` in 5 rows, `igloo_door` on the +X side plus a dark Hole (40,50,110) |

Lessons:
- Vary the seed between zones: the same seed gives the same silhouette at any size.
- Leaves and fronds are flat double-sided quads (`double_quad`, `recalc=False`), at a third of the triangle cost of thin hulls.
- A wide relief across facets sinks in the middle, so `front_relief` cuts it into narrow strips.
- A slope that faces the player hides the rock behind snow, so slope wedges sideways.
