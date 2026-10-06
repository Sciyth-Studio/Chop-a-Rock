---
description: Reference images for the board-breaking training stand remodel (2026-10-03); open before modelling training props.
type: reference
---
# Training stand reference

![[Training Stand Ref Karate Stand.png]]
![[Training Stand Ref Sawhorse.webp]]
![[Training Stand Ref Boards.webp]]

What to take from them, for the training stand that goes in the lobby near the bases:

- **Karate stand:** the shape idea. A stack of pale boards rests across two dark posts that stand on a footed base.
- **Sawhorse:** chunky wood joinery and the warm orange-pine colour for the frame.
- **Boards:** the pale cream pine colour for the breakable boards.
- **Breaks:** the board splits when chopped, so it needs pre-split pieces (like the rocks) and stays a separate part tagged `TrainingBoard`.

## Reference sheet (ChatGPT, 2026-10-03)

![[Training Stand Sheet.webp]]

The sheet the model is built from. Top row: front and back (the wide view is the front, facing the player). Middle row: the sides. Bottom row: the top view and a 3/4 view. Take from it: square posts on bevelled foot blocks with triangular braces, a low crossbar between the feet, and a cream board in two layers that overhangs the posts.

## Approved model (2026-10-03)

- Frame (`TrainingStand`) 5.5 × 3.2 × 2.55 studs; board (`TrainingBoard`) 4.16 × 0.69 × 1.31 studs, two stacked layers, sitting on the post tops at 3.2 studs.
- Break is one straight cut through the middle, like a real karate break (user's call); a jagged or splintered edge was offered and turned down.
- Everything is studded (inlet stud SurfaceAppearance added in Studio; stud UVs are baked into the meshes).
- `BoardStack` decor (4 loose boards, top one turned 30°) is placed in a few copies around each stand.
- Files and the Blender builder script are in `assets/Training/TrainingStand/`.
- 2026-10-04: all five meshes (frame, board, split pieces, BoardStack) got [[Baked Face Shading]] with the edge glow via `stand_builder.shade(objs)`, and all four FBXs were re-exported. In Studio the frame MeshPart is named `Frame` in `Workspace.TrainingStand`, and the board and BoardStacks are there too. That Model has no `RBX_ReimportId`. Only `ReplicatedStorage.Assets.Models.Model_TrainingBoardSplit` can use [[Studio Reimport]]. In Studio the board is `248,217,109` and the frame is `190,90,30`, all with `2022 Inlet`. The same day the meshes went into Studio: the split by Reimport, and the rest by `ApplyMesh` onto the existing parts.
- 2026-10-06: the stand moved from `Workspace.TrainingStand` into the `Model_BasePlot` template, one owner-only stand per base. See [[Bases]].
