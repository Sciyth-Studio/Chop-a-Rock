---
description: The user's VFX texture kit at Downloads/VFX Assets - 1,935 ready-made particle, flipbook and beam textures, catalogued in its _catalog folder; the vfx skill checks it before drawing (kit.py).
type: reference
---
# VFX texture kit

The user has a community VFX texture kit at `C:/Users/Admin/Downloads/VFX Assets` (464 MB, 1,935 images), from the same source as the `roblox-vfx` skill (2026-10-15). It is not in the repo; keep it out (size, and its licence is unknown). If it moves, set `VFX_KIT` or pass `--kit`, and rebuild the catalog.

- **Layout:** `1_Normal` (single sprites: Impact, Flares, Stars, Shards, Shockwaves and Rings, Sigils, Slashes or Crescents, Specs or Wisps, Swirls, Cracks, Elements/Fire/Smoke/Lightning/Water, Misc/Money, Rock, Rocks, Ground, Impact Frames...), `2_Flipbooks` (sheets: Fire, Smoke, Impact, Lightning, Shockwaves, Slashes, Water, Wind, Rocks, Shards, Money...), `3_BeamsTrails` (Elemental energy/fire/lightning/smoke/water/wind, Misc).
- **Format** (catalog, 2026-10-15): 1,644 greyscale on alpha (tintable), 180 on black with no alpha (`LightEmission` 1 only), 111 with colour baked in. Single sprites are mostly soft light; flipbooks mostly crisp drawn matter. Some "tintable" drawings are dark grey (catalog `value` under about 0.4) and tint dark.
- **Sizes vary:** 128 to 4096 px. Flipbook grids: 587 4x4, 93 8x8, 78 2x2, 41 undetected, 5 not square. `kit.py prepare` scales sprites to at most 512, flipbooks to 1024 x 1024, strips to at most 1024.
- **Quality:** looks like work by experienced Roblox VFX artists: cel puffs, crisp impact stars, torn rings, clean four-point flares, cartoon smoke sheets. Plenty fits the cartoon look (cel smoke, impact stars, money, rock chips and shards).
- The skill's references measure "a widely shared community particle kit" of 1,108 textures. This kit may be a later or larger version of it; not confirmed.
- **Watch for:** folders named after anime/games (`Demon Slayer AHH`, `Genshin`, Kanji text) may be fan copies; uploads are moderated and irreversible, so prefer generic shapes.

**Catalog (built 2026-10-15):** `.claude/skills/vfx/scripts/kit.py index` writes `<kit>/_catalog/catalog.json` (id `K0001`..., type, kind, edge, value, size, grid, frames, words) and 95 contact sheet pages in `<kit>/_catalog/sheets/`. Ids follow sorted paths, so they shift if files are added; `kit_sources.json` in each effect folder keeps the kit path too. Workflow (search, look, prepare, preview, upload) is in the vfx skill's `vfx-textures.md`, "Check the kit before drawing".

Related: [[VFX From Roqer]], [[VFX Reference Folder]], [[Open Cloud Key]]
