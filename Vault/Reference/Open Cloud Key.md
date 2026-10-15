---
description: Open Cloud API key lives in the user env var ROBLOX_API_KEY; scopes are assets, asset-permissions, dev products, creator store products; works on Sciyth Studio group assets.
type: reference
---
# Open Cloud key

Set up 2026-10-08. The user made a Roblox Open Cloud API key for uploading assets and managing developer products.

- Stored as the Windows **user** environment variable `ROBLOX_API_KEY`. Never print it, echo it, or write it to a file in the repo. Use it as `$env:ROBLOX_API_KEY` in the `x-api-key` header.
- Scopes: `asset-permissions` (write), `assets` (read, write), `creator store products` (read, write), `developer products` (read, write).
- Tested 2026-10-08: `GET https://apis.roblox.com/assets/v1/assets/80371787143053` returned the group-owned IndexPurpleBook image (creator group `10962733`), so the key can reach Sciyth Studio group assets.
- A new or changed env var only reaches shells after the Claude app is fully quit from the tray and reopened; closing the window is not enough.

Uploading through this key with `creationContext.creator.groupId = "10962733"` should put new images and meshes under the group, avoiding the personal-account problem in [[Asset Ownership]] (untested).

Related: [[Asset Ownership]], [[Chop a Rock]]

**FBX models, 2026-10-10:** Claude imports 3D models itself; the user doesn't need to use the 3D Importer. Upload each FBX with `assetType` **Model** (file part `type=model/fbx`) under group 10962733. The script `.claude/skills/rock-model/scripts/upload_model.ps1 -Path <fbx> -Name <name>` prints the asset id. Then in Edit, `InsertService:LoadAsset(id)` via the Studio MCP returns a Model holding one MeshPart per Blender object, named after the object, with correct size and orientation (Blender -Y is Roblox -Z). All 12 zone rocks went in this way. The upload for display name "ReefBoulder" failed every time with `INTERNAL` / "Unknown Error", while the same file uploaded fine as "Reef Boulder". If an upload keeps failing, give it a display name with spaces.

**Upload tested 2026-10-10:** `POST https://apis.roblox.com/assets/v1/assets` (multipart: `request` JSON with `assetType`, `displayName`, `creationContext.creator.groupId` 10962733, plus `fileContent`), then poll `operations/<id>`. Use `assetType` **Image** for UI icons: a `Decal` upload (113266790078316) gave an id that an ImageLabel could not load (`AssetFetchStatus.Failure`), the `Image` upload (97839648540693, the Luck clover) loaded fine in the group-owned game. This replaces the "untested" note above.

**VFX textures, 2026-10-13:** 29 Diamond and Aura particle/beam/icon PNGs uploaded as `Image` under the group and work in the templates, so this is the default route for VFX uploads (no `upload_image`, no "share access" clicks). Right after upload, 7 of the larger images reported `AssetFetchStatus.Failure` in `PreloadAsync` though the API already said `Approved`; a minute later all loaded. Retry before assuming a bad id.
