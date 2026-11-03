---
description: The 15 zone 6-10 chop rocks built 2026-10-31 in one World1Rocks.blend - asset ids, props, colours, tris; decor props are the meshlab decor OBJs; no split models (live slice).
type: reference
---
# World 1 rocks (zones 6-10)

Built 2026-10-31 as one batch in `assets/Rocks/World1Rocks.blend`, one collection per rock, from the sheets in [[Zone Rocks Reference]] and the looks in [[World 1 Plan]]. FBX and preview per rock in `assets/Rocks/<Zone>/<Name>/`. The build scripts (`w1_bodies.py`, `w1_props.py`, `w1_decor.py`) were session scratch; the reusable parts are in `rock-model`.

- **Bodies:** `build_boulder` at base size (First about 10 x 7, Second 16 x 11, Third 24 x 15 studs); `ZoneScale` scales them in game. Muted stone colours ([[Realistic Rock Bodies]]), Plastic + `2022 Inlet`.
- **Decor props** are the zone's real meshlab decor OBJs (`tools/meshlab/out/Decor*_s1.obj`), imported, scaled and seated on the rock ([[Rock Props Reuse Decor]]). In Studio they are white Plastic + `2022 Stud` so their vertex colours show, the same as the zone decor.
- **Hand-built props** are flat colour on the part (Plastic + `2022 Inlet`). Glow props are Neon.
- **Carved features:** the cracks, runes and crater bowl are cut into the body with an exact boolean (one swept prism per crack leg, carved one at a time). The fill is a separate prop sunk into the groove. Overlapping tube cutters left non-manifold edges.
- **No split models.** Breaks live-slice the rock and its props (`Utils/LiveSplit`); no `SplitModel` attribute, so a failed slice falls back to box halves. `MeshSlicer` carries vertex colours since 2026-10-31 so sliced decor props keep their colours.
- **Smoke:** `Smoke` Attachment + ParticleEmitter (`smoke_main.dds`) on Smoky Rock and Crater Boulder; `Effects` hide() disables emitters on break.

| Key | Rock | Asset id | Body | Props | Tris |
|---|---|---|---|---|---|
| SwampFirst | Muddy Rock | 124474366023822 | 115,95,70 | Mud, Drips 85,60,35; Cattails (decor) | 966 |
| SwampSecond | Reedy Boulder | 92099052158748 | 85,95,80 | Cattails, LilyPads (decor) | 1158 |
| SwampThird | Rooty Boulder | 136948182261303 | 120,115,95 | Roots 95,65,40 (strips laid on the facets) | 904 |
| SavannaFirst | Grassy Rock | 112283415669276 | 190,150,100 | GrassTop, GrassA, GrassB (decor GrassTuft) | 1548 |
| SavannaSecond | Acacia Boulder | 83765791477480 | 165,100,65 | Acacia (decor) | 1992 |
| SavannaThird | Anthill Boulder | 123234475444600 | 140,110,85 | Mound (decor TermiteMound) | 778 |
| BambooFirst | Shooty Rock | 100295739520860 | 120,130,125 | Shoots (decor BambooShoot) | 440 |
| BambooSecond | Bamboo Boulder | 73327408690579 | 90,100,95 | Bamboo (decor) | 1688 |
| BambooThird | Pagoda Boulder | 84099415845714 | 150,145,130 | Stone 205,200,185; Roofs 200,50,40; Window 110,70,40 | 288 |
| VolcanoFirst | Smoky Rock | 133922385570764 | 85,80,80 | Cracks 35,30,30 (carved); smoke | 544 |
| VolcanoSecond | Ember Boulder | 134149792710255 | 60,50,50 | Cracks Neon 255,120,0 (carved) | 1266 |
| VolcanoThird | Crater Boulder | 89618223549392 | 110,70,55 | Pool Neon 255,90,0 (carved bowl); smoke | 150 |
| RuinsFirst | Rune Rock | 76018373112502 | 130,135,120 | Runes Neon 170,80,255 (carved) | 550 |
| RuinsSecond | Pillar Boulder | 120795973439186 | 95,100,90 | Pillar (decor) | 680 |
| RuinsThird | Statue Boulder | 135951796617088 | 175,165,140 | Fist 145,145,140 (three fingers, jittered chunks) | 268 |

User calls during the build: the fist bigger, rougher, three fingers; the termite mound must look like the in-game one; roots and drips follow the rock's shape; cracks and runes cut into the rock; the front doesn't matter (chopped from any side).

Related: [[Zone Rocks Reference]], [[Slice Test]], [[Rock Showcase]], [[Meshlab]], [[Decor Lineups]]
