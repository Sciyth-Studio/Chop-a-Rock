---
description: Workspace.RockShowcase - EditorOnly plates west of the zones with a copy of every zone's chop rocks and their split pieces, for examining models in Edit.
type: reference
---
# Rock Showcase

Built 2026-10-13 because the user wanted somewhere outside the map to examine every zone's rock models.

- `Workspace.RockShowcase` (tagged `EditorOnly`, so it never reaches players) is centred on X -260, west of the zones' -X terraces. One stud plate per zone (170 x 110, zone floor colour) sits level with that zone, at its centre Z: Forest -135, Desert -15, Jungle 105, Ocean 225, Snow 345, plus a Diamond plate at Z -255.
- On each plate the three rocks stand in a row, smallest on the left when looking +Z (from the map's lobby end). Each rock's `SplitModel` sits 50 studs behind it with the pieces pulled 4 studs apart, so the cut faces and the props on each half show. A name sign stands in front of each rock and a zone title sits at the plate's near edge.
- Appearance changes sync live in Edit (2026-10-13, the user wanted to see colour changes without playtesting). The local plugin `RockShowcase.lua` (source in `.claude/skills/rock-model/plugin/`, installed in `%LOCALAPPDATA%\Roblox\Plugins\`, loaded when Studio starts) mirrors Color, Material, MaterialVariant, Transparency, Reflectance, TextureID, Highlight and Decal properties from each `Model_Rock_*` and `Model_RockSplit_*` template onto its copy, matching descendants by name path. Split piece bodies follow the rock template's Color, Material and MaterialVariant, as `Utils/SplitModel` does at break time; split props follow the split template. Copies find their template through a `ShowcaseSource` attribute (split models also `ShowcaseRock`). The plugin rebinds when anything under `ReplicatedStorage.Assets` is added or removed, or the showcase is rebuilt.
- Shape, size and new props don't sync. After reshaping or replacing a template, rerun `.claude/skills/rock-model/scripts/build_rock_showcase.luau` in `execute_luau` (Edit). It deletes and rebuilds the folder, and scales each split to its rock's width like the break code. New zones or rock keys go in its `ZONES` table. If the plugin changes, update the copy in the Plugins folder too.
- The admin warps don't go there. In Edit, fly the camera over. In Play, it's gone (moved to `ServerStorage.EditorOnly`).

Related: [[VFX Showcase]], [[Zone Line]], [[Studio Assets Folders]]
