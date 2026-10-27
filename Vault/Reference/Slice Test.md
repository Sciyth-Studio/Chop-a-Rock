---
description: Workspace.SliceTest (2026-10-24) - live any-angle rock slicing with EditableMesh, west of the lobby; how it works, timings and the EditableMesh memory budget gotcha.
type: reference
---
# Slice Test

Built 2026-10-24 to try option 4 of the ways to cut rocks: slicing the mesh live along the swipe instead of swapping in a pre-made `SplitModel`. The same day the user chose it for real breaks, so rocks can spawn at any yaw without 8 split meshes per rock (see "In the game" below).

## In the game (2026-10-24)
- Perfect and Master breaks of zone rocks use `Utils/LiveSplit`. `RockController` calls `LiveSplit.Preload` when a rock spawns (each mesh is read once per session, cached by MeshId). It calls `LiveSplit.Prepare` on `RockMinigameStart` when `canBreak` is true, so the halves are built during the chop and the break is instant. `Effects.Break` gets the prepared split and falls back to the `SplitModel`, then to box halves, if it isn't ready or failed. It is discarded when the rock is removed.
- The cut is vertical through the rock's centre, square to the chop camera (`ChopConfig.CameraOffsetFromRock`, turned with the rock when it has `ChopRelative`). So the cut looks the same on screen at any rock yaw.
- Playtested 2026-10-24 with Always Perfect on yaw-rotated JungleSecond and JungleThird. Both breaks spawned `<rock>_LiveSplit` models; the palm prop was cut and the face prop went whole to one side. The break wasn't seen on screen yet.
- Not using it yet: Geode Fall and the Diamond Rock still break with their `SplitModel`.
- Still to check: a live/private server (asset permissions for `CreateEditableMeshAsync`) and a phone (memory budget). If either fails, breaks fall back to the `SplitModel` without errors, apart from a `[MeshSlicer]` warning.

- **Where:** `Workspace.SliceTest` (Model, `ModelStreamingMode` Persistent) at X -400, Z -300, between the lobby's west edge and the [[Rock Showcase]]: a stud plate, a sign and five rock copies in `Rocks` (forest Second and Third, DesertThird, OceanThird, SnowSecond, with `RockKey`/`SplitModel` removed). The admin warp is "Slice Test".
- **StudioOnly tag:** the model and its warp are tagged `StudioOnly`. `EditorOnly.Strip` moves `StudioOnly` instances out of Workspace on live servers only, so the test exists in Studio Play but never reaches players.
- **How to use:** in Play, click and drag across a rock. The cut plane passes through the camera and both ends of the drag. Rays sampled along the drag pick which rocks get cut, the halves (props included) push apart, then fade, and the rock comes back after 4 s. Numbers are in `SliceTestConfig`.
- **Code:** `src/client/Components/SliceTest` (component on the `SliceTest` tag) uses `Utils/LiveSplit`, which uses `Utils/MeshSlicer`: `Read` loads a MeshPart's triangles in part-space studs, `Split` clips them against a plane and fills each cut loop with a fan from its centre (cap UVs projected at the mesh's own UV-per-stud, so studs show on the cut), `Build` turns triangles into a MeshPart. Every prop MeshPart is cut by the same plane and welded to its root half; a prop the plane misses goes whole to its side.
- **Timings (Studio, 2026-10-24):** reading a mesh takes 350-770 ms the first time, so the component preloads every rock part when it starts. After that a whole slice took 32-64 ms (split under 1 ms; each piece about 30 ms to build).

## EditableMesh gotchas
- An `AssetService:CreateEditableMeshAsync` mesh is centred, in mesh units: part space = mesh position x `Size / MeshSize`.
- `CreateMeshPartAsync` keeps vertex positions as given (it does not recentre), so `Build` recentres the vertices and offsets the CFrame.
- The MeshPart renders from its EditableMesh: destroy the EditableMesh and the part goes invisible. Keep it alive until the part is destroyed.
- **Memory budget:** growable meshes (`CreateEditableMesh({})`) are expensive. Only about 8 fit at once on the client, even empty. Fixed-size meshes are cheap: 300 copies of a rock mesh loaded with room to spare. The first version kept the growable meshes alive and props stopped slicing by the third rock. Fix: build in a growable mesh, copy it to a fixed-size one with `CreateEditableMeshAsync(Content.fromObject(builder), { FixedSize = true })`, destroy the builder, and render the copy. At most `MaxConcurrentBuilds` (4) builders exist at once.
- Players' devices have their own budgets (mobile is likely smaller). Not tested on a phone or in a live server.

Related: [[Rock Showcase]], [[Chop Effects]], [[Rocks Look Like Boulders]]
