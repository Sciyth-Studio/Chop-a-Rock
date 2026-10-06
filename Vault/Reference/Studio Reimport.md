---
description: Studio's 3D Reimport (Alt+Shift+R) updates an imported Model's meshes in place, matched by mesh name, keeping Color/Material/children; config lives on the device.
type: reference
---
# Studio reimport

Looked up 2026-10-04 (https://create.roblox.com/docs/art/modeling/reimport).

- Select the imported Model, then right-click → Reimport ⟩ Reimport, or press Alt+Shift+R. Only the user can do this; it is UI only.
- Models from the 3D Importer carry an `RBX_ReimportId` attribute. The file path and import settings are stored on the device, not in the place. On another PC, or if Studio has forgotten, use Reimport ⟩ Configure and pick the FBX.
- Matching is by mesh name and path: same name updates that MeshPart, a new name creates a new MeshPart, and a removed mesh is left alone. Keep Blender object names equal to the Studio MeshPart names (e.g. `ShopStall_Wood`).
- Only the mesh content and the part's position and rotation are replaced. Color, Material, MaterialVariant, CollisionFidelity, RenderFidelity, attributes and children (attachments, BillboardGuis) are kept.
- Prefer it over re-importing and swapping parts when a Blender model changes, as long as the model in Studio is still the import Model with its original part names.
- Vertex colours do survive Reimport. Checked on the shop stall 2026-10-04.
- **When Reimport can't match** (Model lost its `RBX_ReimportId`, or parts were renamed, e.g. the training stand's `Frame`): the user imports the FBX fresh, then `target:ApplyMesh(importedMeshPart)` from `execute_luau` (Edit) swaps the mesh in place. It worked 2026-10-04 on the stand's Frame, TrainingBoard and four BoardStacks, keeping CFrame, Size, Color, MaterialVariant, attributes and children. Then delete the import Models. The import Model takes the FBX name, so it can share a name with the real Model (two `Workspace.TrainingStand`s); tell them apart by `RBX_ReimportId`.

Related: [[Shop Stall Reference]]
