---
description: 2026-10-02 — forest zone rock tiers: stone First, boulder Second, mossy boulder Third; how the mossy rock is coloured.
type: decision
---
# Forest rock tiers

**2026-10-02.** Forest zone rocks, in tier order:

- **First (`Basic`)**: a plain stone (a tree stump was dropped because it doesn't fit Chop a Rock), not made yet; `DisplayName` is "Stone". Until it is authored in Workspace.Rocks, `Rocks.Spawn` makes a grey placeholder Part at the config position.
- **Second**: the boulder (`Rock_Second`, was `Rock_Basic`), `SplitModel` Model_RockSplit_Boulder.
- **Third**: the mossy boulder (`Rock_Third`), about 19 x 12 x 16.5 studs, `SplitModel` Model_RockSplit_MossyBoulder. It replaced the old Third placeholder, and `DisplayName` is now "Mossy Boulder".

The old Second and Third placeholder parts were deleted.

**Moss is vertex colour, not a second mesh or material.** Roblox splits multi-material meshes into separate parts, and a separate moss cap would not follow the split halves. Upward-facing facets are green and the rest is cool grey, baked in Blender; the MeshPart is white SmoothPlastic so the baked colours show. Recolouring the part from code would tint the moss too.

**Export scale:** Roblox's importer ignores the FBX unit-scale option. `rock_builder.export_fbx` scales the vertices 2x so 1 Blender unit imports as 2 studs. See the `rock-model` skill.

Related: [[Rocks Look Like Boulders]]
