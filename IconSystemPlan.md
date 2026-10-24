# Item icons: plan

Status: **approved 2026-10-23 with every recommended answer (D1-D6).** D1 was then refined the same day to the user's reference look (`Vault/Reference/Rok Icon Reference`): a near-front bright render with real raised studs and a black outline. The user approved the look the same day. Steps 1, 2, 4, 5 and 6 are done: all 9 icons and `contact_sheet.png` are rendered, the `item-icons` skill is written, `ItemIcons` plus the Index and Geode Stand switch (with the ViewportFrame fallback) are playtested, `check.ps1` passes and the docs are written. Step 3 is done too: all 9 were uploaded with the existing `ROBLOX_API_KEY` (the user's choice over D3's separate key), `ItemIconConfig.luau` is generated, and the real icons were playtested.

Spike findings (details in `Vault/Reference/Item Icon Rendering`):
- The Basic rock's source is `assets/Rocks/Forest/BoulderRock/BoulderRock.fbx` (the Boulder at 0.6x, turned 180°), not BlockRock. Rok bodies use `2022 Small Stud` (0.5), not Inlet.
- The FBXs have no `FaceShade` colours, so materials are the Studio colour only.
- One variant tile = `StudsPerTile` world studs (Inlet 1, Small Stud 0.5), measured.
- Roks get real stud geometry (whole studs per face). Rocks keep a drawn Inlet texture at the measured pitch. Whether rocks should get raised studs too is an open question for the user.
- Manifest: `.claude/skills/item-icons/manifest.json`. Studio values: `assets/Icons/specs.json`.

Goal: every Rok and every rock kind gets a PNG icon, uploaded once and shown with an `ImageLabel`, so the UI stops building a ViewportFrame per card. Adding a new Rok or rock then means running one skill, not hand-making a picture.

## Read first
`AGENTS.md`, `Vault/Index.md`, and the vault notes `ViewportFrame Gotchas`, `Index` (system), `Asset Ownership`, `Tintable Mesh Textures`, `Baked Face Shading`, `Drop In Assets Over Ids In Code`. Skills: `rock-model`, `model-workflow`, `studio-ui`.

## What exists today
- ViewportFrame previews are built in four screens: `Index` (cards + detail), `GeodeStand` (cards), `HatchReveal` (one big model) and `Shop` (arm preview, out of scope).
- Models: `Assets/Models/Model_Rok_<Name>` (6 Roks) and `Model_RockPreview_<RockKey>` (3 rocks). Source FBX files: `assets/Roks/<Name>/<Name>.fbx`, `assets/Rocks/<Zone>/<Rock>/<Rock>.fbx`.
- Every part uses one of only three looks (checked in Studio 2026-10-06): **Plastic + `2022 Inlet`** stud variant (bodies, rocks), **SmoothPlastic** (eyes, leaves, caps...), **Neon** (Berry's berries, Treebo's fireflies). Colour lives on the Studio part, and the baked `FaceShade` vertex colours live in the FBX.
- Image uploads made with the Studio MCP go to the personal account and **fail to load** in the group-owned game (`Asset Ownership`).

## Why Blender renders the icons, not Studio
Studio has no way to save a render to a file. The MCP `screen_capture` returns the picture to Claude only, and nothing in the engine can read ViewportFrame pixels. Blender renders straight to PNG with a transparent background, and because there are only three materials, it can match the Studio look closely. Studio stays the **source of truth for colours**: the renderer reads them from Studio, so nobody keeps colours in two places.

## Pipeline

```text
Studio (colours) --execute_luau--> assets/Icons/specs.json
FBX + specs.json --Blender: icon_renderer.py--> assets/Icons/<Kind>_<Key>.png + contact_sheet.png
PNGs --upload (D3)--> asset ids --> src/shared/Config/ItemIconConfig.luau (generated)
Screens --ItemIcons.Get(kind, key)--> ImageLabel  (fallback: ViewportFrame while an icon is missing)
```

1. **Read colours from Studio.** One `execute_luau` call walks each icon model and records, per part name, its `Color`, `Material` and `MaterialVariant`. Claude writes the result to `assets/Icons/specs.json`.
2. **Render in Blender** (new skill `item-icons`, script `.claude/skills/item-icons/scripts/icon_renderer.py`, run through the Blender MCP in a scratch scene, never in a model's own `.blend`):
   - A manifest in the skill maps each icon to its source: `Pet/Bloky -> assets/Roks/Bloky/Bloky.fbx`, `Rock/Basic -> assets/Rocks/Forest/BlockRock/BlockRock.fbx`, and so on.
   - Materials: Studio colour x `FaceShade` vertex colour. Inlet adds the stud texture through the existing stud UVs. SmoothPlastic is flat, and Neon becomes emission.
   - Camera: the same direction as today's previews (`IndexConfig.Preview.CameraDirection`, converted from Roblox axes), fitted to the bounding box with fixed padding so every icon has the same margin. The film is transparent.
   - Output: `assets/Icons/Pet_Bloky.png`, `Rock_Basic.png`, ... at the size picked in D2, plus `contact_sheet.png` of everything for review.
3. **QA:** Claude compares each render with a Studio `screen_capture` of the same model and checks colour, scale and silhouette. The user approves the contact sheet before anything is uploaded.
4. **Upload** (D3) and write the ids to the generated `ItemIconConfig.luau`: `{ Pet = { Bloky = "rbxassetid://..." }, Rock = { Basic = "rbxassetid://..." } }`. Only PNGs whose hash changed are uploaded again. Hashes are kept in `assets/Icons/uploaded.json`.
5. **Runtime:** a shared `ItemIcons` module with `ItemIcons.Get(kind, key): string?`. Screens swap their card `Preview` ViewportFrame for an `ImageLabel` named `Icon`. Silhouettes keep working the same way, through `ImageColor3 = IndexConfig.HiddenColor`. When an icon is missing (a new Rok before its render), the screen falls back to the current ViewportFrame code, so nothing breaks while content is added.

## 1. Decisions needed

| # | Question | Recommendation | Why |
| --- | --- | --- | --- |
| D1 | Icon look | **The current preview look plus a thick black outline** (about 3% of the icon size) and no drop shadow. Option B: exactly like today's ViewportFrames. | Black outlines are already the house style ([[Menu Panel Style]]), and outlined icons read better at card size and in silhouette. An outline isn't possible in a ViewportFrame, so this is a real upgrade. |
| D2 | Resolution | **512 x 512** PNG. | Sharp on the 1000-wide panels and the detail pane, and it scales down cleanly to small cards. Roblox allows up to 1024. |
| D3 | How icons get uploaded to the group | **Open Cloud script** `scripts/upload_icons.py`. You create a Sciyth Studio group API key with `asset:write` in Creator Hub and set it as the env var `ROBLOX_ICONS_API_KEY` yourself. The script uploads to the group and writes the ids file. Option B: you bulk-import the PNGs in Studio's Asset Manager with the group place open and paste the ids back to Claude. | A fully hands-off re-render-and-upload loop, and every asset is group-owned from the start. Claude never sees the key. B works with no setup but costs a manual step for every new Rok. |
| D4 | Ids in a generated config file vs a Studio folder | **Generated `ItemIconConfig.luau` in git.** | The drop-in-folder preference came from ids that lived only in Studio and were wiped by Rojo. These ids are written by a script into the repo, so they can't be lost the same way, and a Studio folder would add a manual step to a pipeline that is otherwise automatic. |
| D5 | Which screens switch | **Index (cards + detail) and Geode Stand cards.** HatchReveal keeps its 3D model. The Shop arm preview is unchanged. | The grids are where many ViewportFrames add up. The reveal is a single model, and the 3D model suits its grow-and-flash animation. |
| D6 | What gets icons now | **6 Roks + 3 rocks.** The manifest takes geodes and other items later with no code change. | That's the request. The format is ready for more. |

## 2. Work order (after approval)
1. Spike: render Bloky and the Basic rock, then show them next to Studio captures. Lock in the look (D1) before doing the rest.
2. Write the `item-icons` skill and `icon_renderer.py`, then render all 9 icons and the contact sheet for approval.
3. Upload route (D3): set up the key, then add `upload_icons.py` and `ItemIconConfig.luau`.
4. Add the `ItemIcons` module and the screen changes (`Index.luau`, `GeodeStand.luau`) with the ViewportFrame fallback. Add `Icon` ImageLabels to the Studio card templates.
5. Playtest the Index and the Geode Stand, check silhouettes, then run `./scripts/check.ps1`.
6. Docs: a vault note `Systems/Item Icons` and an Index entry, plus a step in `model-workflow` / `rock-model` step 6: "render and upload the icon".

## Risks
- **The FBX may not match Studio** if a rock was reshaped after export (rocks are sometimes remodelled by hand). The step 3 side-by-side catches it. The fix is to re-export from that rock's `.blend`.
- **Stud texture scale:** the inlet stud's tiling has to match `2022 Inlet`'s StudsPerTile. Measure it once in the spike and keep it in the renderer.
- **Lighting drift:** Blender's light won't match the in-game ViewportFrame exactly. It only needs to be consistent across icons, because icons are compared with each other, not with the world.
