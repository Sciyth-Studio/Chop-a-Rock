# Rock recipes

Specs of rocks already built with `rock_builder.py`. Use them as starting points or to rebuild a rock exactly.

## BlockRock (Rock_Basic, first chop rock)

Approved 2026-09-30. About 12 x 5.4 x 9.3 studs, 226 tris, plain grey (120, 120, 120) SmoothPlastic. Files in `assets/Rocks/BlockRock/`. Registry key of its split: `Model_RockSplit_Block`.

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

About 11.6 x 7 x 10 studs, 108 tris, faceted boulder with inlet studs as a see-through overlay (`assets/Textures/Studs/SingleInletStud.png`), grey (120, 120, 120). Files in `assets/Rocks/BoulderRock/`.

```python
rock, report = rb.build_boulder("BoulderRock", width=6.0, depth=5.0, height=3.5, facets=30,
    cut_depth=(0.02, 0.2), min_nz=-0.5, center_height=0.3, lean=(0.12, 0.08), seed=4)
chosen, tried = rb.find_mesh_split(rock, merges=(0.0,))
pieces, split_report = rb.split_rock(rock, chosen["steps"], 0, chosen["merge"])
```

Split: straight cut along the chop direction at x = 0.06 (0.12 studs off centre), 50.5/49.5 by volume, pieces 72 tris each.
