---
description: The one base-plot inspiration image the user liked (2026-10-03); flat stud-plate plot with rows of pedestals and price pads.
type: reference
---
# Base plot reference

![[Base Plot Reference.webp]]

Take from it:
- The whole plot is flat stud plates: a dark slate floor with a raised light-grey walkway strip down the middle.
- Rows of identical square pedestals along both sides of the walkway, each with a bright green pad in front showing a money amount (collect/earnings pad).
- Pedestals are low stepped blocks (a wider plinth under a slightly smaller top), light grey, studded.
- Small yellow upgrade tags on the far-row pedestals.
- Saturated, toy-like colours; everything blocky and studded, no detail beyond that.

In Chop a Rock the pedestals hold displayed pet rocks (offline money), so the green pad maps to that pedestal's earnings. The plot also needs a geode crack area, room for more pedestal slots bought with money, and extra floors from rebirth (Master Game Plan §06, §08). 8 plots ring the training hub.

## Reference sheet

![[Base Plot Reference Sheet.png]]

Take from it: the top-down view's layout (rim with an entrance vestibule walled off from the floor, centre walkway into a framed cracked-rock pit, square slot plates in rows) and the colours (slate floor, light blue-grey stone). The sheet shows 4 slots per side and its views disagree with each other. The build uses 5 per side, as specified.

## Blender build (step 4, 2026-10-03)
`assets/Base/BasePlot/plot_builder.py`, collection `BasePlot`. There are three meshes so each can be coloured on its own: `BasePlot_Floor` (80 x 1 x 120, with the pit cut in), `BasePlot_Stone` (rim, corner posts, vestibule walls, walkway, slot plates, pit frame) and `BasePlot_Crack` (16 Voronoi stones in the pit). The stone mesh is separate closed boxes joined without booleans, because exact-solver unions of coplanar boxes gave 635 non-manifold edges. The user found 80 x 120 too long and asked for a squarer plot, so it's now 90 x 90. The entrance area is 12 deep and the pit centre is at y = 33. The user cut it to 8 slots, 4 per side, then asked for the rows to be centred front-to-back and moved closer to the side walls. After that they asked for the slots to be a bit closer to the walkway with room left for the pads. Slot plate centres are x = ±27 studs (11 studs from the wall), y = -28.5, -9.5, 9.5, 28.5 (entrance at -y; 9.5 studs to the front and back walls). Each earnings pad (3.5 x 6.5) goes on the floor 1.5 studs in from its plate, on the walkway side (centre x ≈ ±18.25). That leaves about 11.5 studs of floor between the pads and the walkway. The user asked for higher walls, so the rim is 2.5 studs and the posts 3.2. The 80 x 120 version was exported, then replaced by the square one. The final 90 x 90, 8-slot version was approved and exported 2026-10-03, overwriting the old file. Exports go to `assets/Base/BasePlot/BasePlot.fbx` (all three meshes) and `BasePlot.blend`. For collision, use PreciseConvexDecomposition, not Hull, because Hull would fill the plot into one box.

## In Studio (2026-10-03)
- The base pedestal reuses the geode stand instead of a new model: `ReplicatedStorage.Assets.Models.Model_BasePedestal` is `Model_GeodeStand` with the GlowCircle removed and `Pedestal` + `Crystals` squashed to half height (8 x 2.73 x 8). Stone 165,172,195. `EarningsPad` is a 6.5 x 0.4 x 3.5 green Part on the front (-Z) side, CanCollide off. Pivot at bottom centre.
- On plain Parts, studs are a `Texture` on the Top face with the inlet stud image at 1 stud per tile, which matches the mesh studs' size.
- The lobby's ColorCorrection washes light greys out to white and pushes slate toward bright blue, so pick plot colours darker than they should look.
- The base plot goes through the full `model-workflow` pipeline (decided 2026-10-03): Claude models the plot in Blender, then `Model_BasePedestal` copies are placed on top of it in Studio.
- Step 1 spec (user approved Claude's defaults, 2026-10-03): 80 x 120 studs (later 90 x 90); slate floor plate; raised centre walkway along the length; 10 flat pedestal spots, 5 per side (later 8); sunken cracked-rock geode crack area at the far end of the walkway; low ~1-stud stone rim with the entrance gap facing the hub; no rebirth floors yet; blocky, flat colours, studs added in Roblox. Pedestals and earnings pads are Studio parts, not in the mesh.
- The `BasePlotTest` scratch slice has been deleted.
- Imported plot (2026-10-03): `Workspace.BasePlot`, placed by the user at bottom centre -45, 1, -384 on the lobby floor. Template `ReplicatedStorage.Assets.Models.Model_BasePlot`, pivot at the floor's bottom centre (PrimaryPart `BasePlot_Floor`). AssetRegistry has `Model_BasePlot` and `Model_BasePedestal`. Colours (user asked for an almost-black floor and dark grey stone and pedestals, no crystals): floor 22,20,18, stone and pedestals 82,76,70, crack 66,61,56. They're slightly warm on purpose: Lighting's blue OutdoorAmbient (157,178,255) plus ColorCorrection saturation 0.5 make neutral greys look blue. `Crystals` was removed from `Model_BasePedestal` and from every placed pedestal. Studs are MaterialVariants: `2022 Stud` (outlet) on the floor and `2022 Inlet` on the stone, crack, pedestals and pads. All parts are anchored by script (the import came in unanchored again).
- **Import axis:** in this import the entrance (Blender -Y) ended up on Roblox **+Z** and the pit on -Z. That's the opposite of the rock-model skill's axis note, so work out orientation from the parts (crack vs floor position) rather than assuming.
- `BasePlot.Pedestals` holds `Pedestal1`–`Pedestal8` (attribute `SlotIndex`), each facing the walkway (pad side, local -Z) with its pivot on the plate top (floor bottom + 1.3). The pedestal's `EarningsPad` is 8.25 studs in front of its pivot and 0.3 lower, so it sits on the floor 1.5 studs from the plate.
- 2026-10-04: floor, stone and crack got [[Baked Face Shading]] with the edge glow (`plot_builder.shade`). Posts were widened 0.02 studs per side so their outer faces cover the rim wall ends instead of sharing a plane with them, so the stone mesh is now 90.04 wide. `Workspace.BasePlot` and the template `Model_BasePlot` share one `RBX_ReimportId`. Reimport the Workspace copy, then `ApplyMesh` its parts onto the template's.
- 2026-10-04: `Workspace.BasePlot` has since moved to pivot -56, 1, -460.86, rotated 180°, so its pit is on world −Z at z ≈ -493.86. Both it and `Model_BasePlot` are tagged `BasePlot` (`BaseService` only uses tagged plots under Workspace and sets `OwnerUserId` on the owner's plot). Each has a `GeodeSpot` Attachment in `BasePlot_Crack` on the pit surface, which is flush with the floor (top y ≈ floor top + 0.11), facing the walkway; geodes are placed there. New plots copied from the template carry both.
- 2026-10-06: the hand-placed `Workspace.BasePlot` was deleted. Plots are now spawned from the template at runtime; see [[Bases]].
- Gotcha: squashing a MeshPart that is a model's PrimaryPart doesn't move its `PivotOffset`. The squashed pedestal kept the old -2.73 offset and floated 1.4 studs up until `PivotOffset` was reset to `-Size.Y / 2`.

Related: [[Geode Stand Reference]], [[Studs On Models By Default]], [[High Saturation Colors]]
