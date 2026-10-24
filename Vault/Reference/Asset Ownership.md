---
description: Chop a Rock moved to the Sciyth Studio group on 2026-10-03; older assets are user-owned and shared with the group, new imports go to the group.
type: reference
---
# Asset ownership

As of 2026-10-03 the Chop a Rock experience is published under the user's personal Roblox account, and every 3D import and image upload so far went to that account too. That matches, so nothing is broken.

- Asset ownership can't be moved from a user to a group. Restricted assets can be shared with a group or experience from Creator Hub (Creations, open the asset, its sharing/permissions settings).
- Experience ownership transfer (user to group) does not move user-owned assets. Before transferring, share the meshes and images with the group (or with the experience), or re-upload them under the group from the FBX/PNG files in `assets/`.
- Re-uploaded rocks need their tags, attributes, SurfaceAppearance and registry entries copied to the new MeshParts.

2026-10-03: the user wants the game moved to the group as soon as possible, for revenue-percentage payouts. Transfer is Creator Hub, the game, Configure, Settings, "Initiate ownership transfer"; email must be verified, the request expires after 7 days, and the game must be made public again afterwards. No developer products or game passes exist yet, so moving now is cheap.

**Done 2026-10-03:** the game was transferred to Sciyth Studio and the user-owned assets were shared with the group (they load fine). The game is not public again yet. Import new models with the group-owned place open; re-uploading the old assets under the group is optional cleanup.

**Image uploads (2026-10-06):** the Studio MCP `upload_image` uploads to the user's personal account (GuiltyArcher), so the image fails to load in the group-owned game (`ContentProvider` reports `Failure`). Ask the user to import the PNG through Studio with the group place open and use the id they give back. The purple Index book went this way: the MCP upload `74222274385745` failed, and the user's import `80371787143053` works.

**Again 2026-10-07 (VFX_LevelUp textures):** the four `upload_image` uploads (`122918034582236`, `87536004748908`, `98491112835796`, `130979523603366`) failed in play with "The experience doesn't have access permission to use asset id ... Click to share access". Clicking that link in Studio's Output should share the asset with the experience and keep the id, which is quicker than re-importing (unconfirmed until the user tries it).

Related: [[Chop a Rock]], [[Tintable Mesh Textures]]

**Recovering a user-owned image with no source file (2026-10-23):** the Hot Streak flame (94131698155889, uploaded by Roblox Assistant) had no PNG on disk. Open Cloud and assetdelivery both refuse to download it, and the public thumbnail API only gives 24-bit RGB (no transparency). What worked: in Studio Edit, `AssetService:CreateEditableImageAsync(Content.fromUri(id))` + `ReadPixelsBuffer` returns the exact RGBA pixels; encode them as palette + run-length text, rebuild the PNG locally (PowerShell System.Drawing), upload with `.claude/skills/vfx/scripts/upload_images.ps1`, then compare both ids' pixel buffers in Studio (0 bytes differed). New id `105471732927066`. When testing loads in Play, preload ImageLabels, not bare id strings: `PreloadAsync({"rbxassetid://..."})` reported `Failure` even for working icons.
