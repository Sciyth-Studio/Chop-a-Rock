---
name: batch-model
description: Use when the user wants to batch model a set of models for Chop a Rock (a zone's six Roks, a zone's three rocks, training tiers, any family of props) by looking at them all in Blender at once, or says "batch model", "do them all together" or "model the whole set". Covers separate per-item prompts, taking all the reference sheets at once, building every item side by side in one .blend, one shared feedback round, per-item FBX export, Open Cloud upload and loading into Studio. Runs alongside model-workflow, which still owns the six steps; rocks that split also use rock-model.
---

# Batch model

Batch mode is the `model-workflow` pipeline run for a whole set at once. The prompts stay separate, one per item, but the user sends every sheet together, Claude builds the whole set in one Blender file, and feedback and approval cover the set. First used for the jungle Roks (2026-10-16, vault note Jungle Rok Sheets).

## 1. Prompts (model-workflow steps 1 to 3)

- Settle the set's shared look first (for Roks, the zone body colour; vault: Coloured Roks After Forest). Ask the user if it isn't decided; take inspiration from the zone's own things (the jungle colour came from its fruits).
- Write `assets/<Category>/<Set>/Prompts.md` from `model-workflow/references/reference-sheet-prompt.md`:
  - One lineup prompt showing the whole set.
  - One six-view prompt per item that attaches the lineup and names the item by its position in it.
  - Keep every prompt self-contained, since each runs in its own ChatGPT chat.
- Tell the user to run the lineup, then all the sheet prompts, and send the sheets back together, saying which view is the front.

## 2. Take in the sheets

- Copy each sheet to `assets/<Category>/<Name>/<Name>_sheet.webp` and `Vault/Attachments/<Name> Reference Sheet.webp`.
- Write one vault reference note for the set that embeds every sheet and says what to take from each. Link it from `Vault/Index.md`.

## 3. Build the set in one file

- Save a new file as `assets/<Category>/<Set>/<Set>.blend` straight away, before building anything. If you opened another model's `.blend` to copy parts from it, `save_as` first so that file is never touched.
- Make one collection per item, named after the item. Name objects `<Name>`, `<Name>_Eyes`, `<Name>_<Prop>`, the same pattern as single models.
- Roks: copy the body and eye meshes from an existing Rok `.blend` (any desert one, e.g. `assets/Roks/Spike/Spike.blend`, holds Bloky's body, eyes and pupils). Copy them with `mesh.copy()` plus a translate, and only translate the eyes (vault: Reuse Rok Eyes). The Rok front is -Y in Blender.
- Build props with `rock-model/scripts/rock_builder.py`:
  - Before each item's `make_obj` calls, set `rb.COLLECTION = "<Name>"` so the objects land in that item's collection.
  - Shapes: `hull_into` (convex chunks), `tube` (stems, vines), `blossoms` (flowers), `frond` and `double_quad` (thin leaves).
  - For a vine wrapped around a body, ray-cast the body from its centre along a plane and build a closed ring of quads. Use the plane normal as the ring's fixed axis so the tube doesn't twist.
- Lay the items out along X (about 2.8 units apart; leave more room for wide items) by setting `location.x` on every object. Mesh data stays centred on the origin.

## 4. Preview and feedback (model-workflow step 5)

- Use an ortho camera on the whole row. Render a front, a 3/4 and a back view (`lineup_front.png`, `lineup_34.png`, `lineup_back.png` in the set folder), plus close-ups of anything the user asks about. Send them with `SendUserFile` using absolute paths.
- Compare every item against its sheet before showing it. Props that come out thinner or smaller than drawn is the usual miss.
- Check that props don't cover the eyes.
- Check that anything the sheet draws attached is attached in the model. Viney's flowers had to sit on a vine, not on the bare body.
- Rebuild only the items the user flags, then re-render the whole row.

## 5. Export (model-workflow step 6)

- After approval, for each item: set `location.x = 0` on its objects, run `rb.export_fbx(objs, "assets/<Category>/<Name>/<Name>.fbx")` with the body first in the list, then restore `location.x`.
- Clamp any vertex below z = 0 to 0 before exporting. Wrapped vines and petal bases dip under the ground, and the bounding box then drops the pivot below the body.
- Check every file by importing it into a temporary scene: count the objects, check the size and check that min z is 0. Then delete the temporary scene and orphan meshes.
- Record each item's mesh names, colours and tris in the set's vault note.

## 6. Into Studio

- The upload goes to the group, so ask before running it: `.claude/skills/rock-model/scripts/upload_model.ps1 -Path assets/<Category>/<Name>/<Name>.fbx -Name <Category>_<Name>` for each item (it needs `ROBLOX_API_KEY`; vault: Open Cloud Key). Record the asset ids.
- Studio must be in Edit mode. If it's in Play, ask the user before stopping it.
- With `execute_luau`, for each id:
  - `InsertService:LoadAsset(id)`, then move its MeshParts into a new Model named like the existing set (Roks: `Model_Rok_<Name>` in `ReplicatedStorage.Assets.Models.Roks`).
  - Shift the parts so the body's XZ centre and the set's lowest point sit on the origin. Set `PrimaryPart` to the body and `WorldPivot = CFrame.new()`, and anchor every part.
  - Apply colours and materials. Rok bodies are Plastic with `2022 Small Stud`; eyes are SmoothPlastic 245 and pupils 20. Props are SmoothPlastic, with Neon where noted.
- Read an existing model of the same kind first and match its properties.
- Add `AssetRegistry` entries and check the result by reading values back. Then tell the user to save the place.
- Config (`PetConfig`, geodes, Index) is separate work: propose it as its own session.
