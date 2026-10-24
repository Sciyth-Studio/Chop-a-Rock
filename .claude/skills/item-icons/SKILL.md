---
name: item-icons
description: Use when a Rok or rock needs its card icon (the PNG shown in the Index and Geode Stand instead of a 3D ViewportFrame), when a new Rok, rock or zone is added, when an item's colour or mesh changed so its icon is stale, or when the user asks to render, re-render, upload or fix item icons. Covers reading part colours from Studio into specs.json, rendering 512x512 outlined PNGs in headless Blender with icon_renderer.py, the contact sheet, uploading to the Sciyth Studio group with scripts/upload_icons.py, and the generated ItemIconConfig the screens read.
---

# Item icons

Every Rok and rock kind gets a 512×512 transparent PNG icon, rendered in Blender and uploaded once to the group. The Index cards and detail pane and the Geode Stand cards show it in an `Icon` ImageLabel. Until an item has an icon, they fall back to the old ViewportFrame (`Preview`), so a new Rok never breaks the UI. Background and measured facts: vault notes `Item Icon Rendering`, `Rok Icon Reference` and `Item Icons`.

The look (approved 2026-10-23): a near-front, bright Cycles render, raised whole studs on `2022 Small Stud` parts (Roks), the drawn Inlet texture at 1 stud per tile on `2022 Inlet` parts (rocks), and a black outline of 2.2% that follows the silhouette. All of it is in `STYLE` at the top of `scripts/icon_renderer.py`. Don't change the look without the user's approval.

## Files
| File | What it is |
| --- | --- |
| `manifest.json` (this skill) | Icon key (`Pet/<PetKey>`, `Rock/<RockKey>`) → FBX path, plus a part → FBX object map when the names differ (`"Rock": "BoulderRock"`) |
| `assets/Icons/specs.json` | Per icon, the Studio model's parts: colour, material, variant, size, mesh size, position, orientation. Also the stud variants and their tile textures |
| `scripts/icon_renderer.py` (this skill) | Renders `assets/Icons/<Kind>_<Key>.png` and `contact_sheet.png` |
| `textures/` (this skill) | Stud tiles: `SmallStud.png` sampled from Studio, `Inlet.png` drawn to match it (stored as 0.5 = ×1 brightness) |
| `scripts/upload_icons.py` (repo) | Uploads new or changed PNGs and writes `ItemIconConfig.luau` |
| `assets/Icons/uploaded.json` | Icon key → `{hash, id}`. Unchanged PNGs aren't uploaded again |
| `src/shared/Config/ItemIconConfig.luau` | Generated `{ Pet = {...}, Rock = {...} }` of `rbxassetid://` ids. Don't hand-edit it |
| `src/shared/Utils/ItemIcons.luau` | `Get(kind, key)`, `Apply(holder, kind, key, buildFallback)`, `Tint(visual, color)` |

## Adding or refreshing icons
1. **Manifest.** Add `"Pet/<PetKey>": { "fbx": "assets/Roks/<Name>/<Name>.fbx", "objects": {} }`. For a rock, use the `Rock/<RockKey>` key and the FBX of the mesh its `Model_RockPreview_<RockKey>` uses. Several rocks share one mesh at different scales (Basic = Boulder at 0.6x, turned 180°), so check the preview's MeshId and size, not the folder name. Fill `objects` when a Studio part name isn't the FBX object name.
2. **Specs from Studio** (Edit mode, `execute_luau`). Walk the model (`Assets.Models.Roks.Model_Rok_<Name>` or `Model_RockPreview_<Key>`) and, for every BasePart, record `color` (0–255), `material`, `variant` (MaterialVariant), `size`, `meshSize`, `position` and `orientation`. Write them under `icons["<key>"].parts` in `specs.json`, next to `model` and `boundsSize`. Studio is the source of truth for colours, so never type colours in by hand.
3. **Render** (about 30 s per icon on Cycles; the Blender GUI isn't needed):
   ```bash
   "/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup --python .claude/skills/item-icons/scripts/icon_renderer.py -- Pet/<Key>
   ```
   With no keys it renders everything in the manifest, which takes about 5 minutes, so run it in the background. Every run rewrites `contact_sheet.png`.
4. **Check.** Open the PNG and the contact sheet. Compare silhouettes and colours against the Studio model, and send the contact sheet to the user. New items in the approved look are a check, not a gate. A new part type (a new material or variant) needs the user's eye first.
5. **Upload.** Run `py scripts/upload_icons.py`. It reads the key from the `ROBLOX_API_KEY` user env var, uploads changed PNGs as `Image` assets under group 10962733, records them in `uploaded.json` and regenerates `ItemIconConfig.luau`. `--config-only` only regenerates the config. Then run `./scripts/check.ps1`. Images can report `Failure` for a minute after upload, so retry before assuming a bad id.
6. Nothing changes in the screens: `ItemIcons.Apply` picks up the new id.

## The API key
`upload_icons.py` uses the existing Open Cloud key in the `ROBLOX_API_KEY` user env var (assets read/write, reaches group 10962733; see the vault note `Open Cloud Key`). The user chose it over a separate icons key on 2026-10-23. Never print, echo or write the key anywhere. The script passes it to curl through a temporary header file.

## Renderer notes
- Roblox (x, y, z) = Blender (-x, z, y) for FBXs made with `rock_builder.export_fbx`. Parts are placed from Studio's size, position and orientation (Ry·Rx·Rz), so the FBX's export scale doesn't matter.
- Raised studs are fitted per flat region, at Studio's tile pitch (`StudsPerTile`), whole studs only, with the grid phase picked to fit the most. Studs that would sit under another part (eyes, props) are skipped.
- The camera direction is `STYLE.camera_direction`, in Roblox axes. The view is zoomed and shifted so the silhouette fills the frame minus the outline and margin, so every icon has the same border.
- Neon parts get emission (`neon_strength`). Separate glowing bits like Treebo's fireflies get their own outlines.
