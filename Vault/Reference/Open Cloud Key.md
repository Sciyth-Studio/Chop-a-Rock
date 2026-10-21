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

**Developer products, 2026-10-16:** The game's universe id is `10768221393` (place 81877269405934). List them with `GET https://apis.roblox.com/developer-products/v2/universes/10768221393/developer-products/creator`. Create one with `POST .../universes/10768221393/developer-products` as multipart form fields `name`, `description`, `price`, `isForSale=true`; the response gives `productId`. Send it with `curl -F` from Bash. PowerShell `Invoke-RestMethod -Form` got `403 WAF Blocked Request`. Product names must be unique in the universe. The five training stand products were made this way.

**Updating developer products, 2026-10-21:** the list call above still returns 200 with all five stand products (ids 3719074519/40/43/45/47, still named "<Stand> Training Stand"). Rename or change one with `PATCH https://apis.roblox.com/developer-products/v2/universes/10768221393/developer-products/<productId>` (Beta), using the same multipart fields as create. The key's `developer products` write scope covers it, so no change to the key is needed. Renaming is outward-facing, so ask the user before sending it. Tested 2026-10-21: `PATCH` with the single field `isForSale=false` took the five stand products off sale. Two of them returned a 500 the first time and worked on retry, so re-list the products to check. The four [[Cash Packs]] were created the same day with `curl -F`.

**VFX textures, 2026-10-13:** 29 Diamond and Aura particle/beam/icon PNGs uploaded as `Image` under the group and work in the templates, so this is the default route for VFX uploads (no `upload_image`, no "share access" clicks). Right after upload, 7 of the larger images reported `AssetFetchStatus.Failure` in `PreloadAsync` though the API already said `Approved`; a minute later all loaded. Retry before assuming a bad id.

**Audio, 2026-10-20:** WAV files upload the same way with `assetType` **Audio** and file part `type=audio/wav` under group 10962733. Nine minigame sounds (0.2-6 s) all came back with ids within a few seconds and loaded in Studio through `PreloadAsync` (`IsLoaded`, correct `TimeLength`). See [[Training Minigame Board Slice]].
