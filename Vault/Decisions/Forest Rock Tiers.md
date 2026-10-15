---
description: 2026-10-02 — forest zone rock tiers: stone First, boulder Second, mossy boulder Third; how the mossy rock is coloured.
type: decision
---
# Forest rock tiers

**2026-10-02.** Forest zone rocks, in tier order:

- **First (`Basic`)**: a plain stone (a tree stump was dropped because it doesn't fit Chop a Rock); `DisplayName` is "Stone". It is the Boulder mesh scaled down to 6.95 x 4.23 x 5.98 and turned 180 degrees, sharing `Model_RockSplit_Boulder`.
- **Second**: the boulder (`Rock_Second`, was `Rock_Basic`), `SplitModel` Model_RockSplit_Boulder.
- **Third**: the mossy boulder, `DisplayName` "Mossy Boulder". Since 2026-10-14 it is the remodel with a separate moss cap (see [[Mossy Stone Reference]]), scaled 2.73x in Studio to 18.2 x 12 x 16.7 studs, `SplitModel` Model_RockSplit_MossyStoneRock (scaled to match). The first version (vertex-colour moss, 19 x 12 x 16.5, Model_RockSplit_MossyBoulder) is no longer used; its split model is still in Studio.
- "The mossy rock" means this Third rock, not the Stone. On 2026-10-14 the remodel went onto the Stone by mistake and had to be moved, so confirm which rock before replacing a template.

The old Second and Third placeholder parts were deleted.

**Moss is a separate prop mesh (since 2026-10-14).** The user wanted the moss as its own thick piece, so it is a `Moss` MeshPart under the rock, with pre-split `Moss_L` / `Moss_R` halves under the split pieces, like the zone props from the desert on. The first Mossy Boulder baked the moss as vertex colour instead: upward facets green on a white SmoothPlastic part, so recolouring the part tinted the moss too.

**Export scale:** Roblox's importer ignores the FBX unit-scale option. `rock_builder.export_fbx` scales the vertices 2x so 1 Blender unit imports as 2 studs. See the `rock-model` skill.

Related: [[Rocks Look Like Boulders]]
