---
description: Entry point to the Chop a Rock knowledge vault. Claude reads this at the start of every task.
---
# Chop a Rock Vault

What Claude has learned while working on the game: preferences, references, gotchas and decisions. Keep this page short; detail lives in the linked notes.

## How Claude uses this vault
- Read this page before starting a task, then open the notes relevant to it.
- When you learn a preference, gotcha or decision, write a note in the right folder (or `Inbox/` if unsure), add it below, and tell the user.
- One idea per note. Frontmatter carries a one-line `description` and a `type`. Link related notes with `[[Note Name]]`.
- Update an existing note rather than adding a duplicate. Delete notes that turn out to be wrong.
- Images the user pastes into chat arrive as files Claude can open and copy into `Attachments/`.
- Images live in `Attachments/`. Every image is embedded in a note that says what to take from it; open images only through those notes.
- Procedures belong in skills (`.claude/skills/`), not here: `model-workflow` (start of any modelling request), `rock-model`, `studio-ui`, `studio-playtest`.

## Project
- [[Chop a Rock]] — what the game is, repos, design source of truth

## Preferences
- [[Code Output Rules]] — whole files, no comments, no scope creep, propose-and-wait on player-facing changes
- [[Only Surface Blocking Opens]] — on status questions, name only items that gate current work
- [[High Saturation Colors]] — max-saturation by default; chop-quality palette
- [[UI Text Style]] — colored stroke + gradient fill; black/white only when asked
- [[UI Built In Studio]] — ScreenGuis authored in Studio, driven by UIController screens
- [[Stage Only Own Files]] — parallel sessions; `git add` by explicit path
- [[Drop In Assets Over Ids In Code]] — asset lists (music etc.) read a Studio folder, not ids in config
- [[Roks Stay Rocks]] — pet rocks are rocks with eyes, never animals made of rock; theme via props and formations
- [[Reuse Rok Eyes]] — copy Bloky's eye and pupil meshes for every Rok, never rebuild them
- [[Menu Panel Style]] — panels look like the HUD buttons: layered gradients, sharp corners, Chrome headers, roomy

## Reference
- [[Master Game Plan]] — design source-of-truth doc and its tags
- [[Studio Live Editing vs Rojo]] — new instances sync but script edits don't → restart Studio
- [[UI Style References]] — screenshots of panel UI the user likes; open before building or restyling menus
- [[Tintable Mesh Textures]] — studs are the 2022 MaterialVariants in MaterialService (`2022 Inlet`, `2022 Stud` = outlet); copy MaterialVariant with Material
- [[Boulder Reference]] — reference image for the boulder-style chop rocks; open before modelling rocks
- [[Font Glyphs]] — which arrows/symbols render in the game font (▶ and the Robux icon do, ➜ doesn't)
- [[Forest Zone Entrance]] — transparent wall + SurfaceGui sign at the forest gateway; copy for new zones
- [[Bloky Reference]] — first Rok (pet rock): chamfered cube, chamfered-square eyes as separate meshes
- [[Sprout Reference]] — Uncommon forest Rok: Bloky's body and eyes plus a two-leaf seedling mesh on top
- [[Shroomy Reference]] — Rare forest Rok: taller Bloky body, red-spotted mushrooms on top and the left side
- [[Nesty Reference]] — Epic forest Rok: Bloky body, low-poly twig nest with three pebble eggs on top (~480 tris for nest + eggs)
- [[Berry Reference]] — Legendary forest Rok: Bloky body, faceted leaf crown with four glowing magenta berries
- [[Treebo Reference]] — Secret forest Rok: Bloky body, three-blob faceted tree from the back right, glowing firefly cubes
- [[Geode Reference]] — closed + split geode sheets; flat chipped faces, no bumps, crystals are a separate rarity-coloured part
- [[Training Stand Reference]] — karate board-stand, sawhorse and pine-board images for the breakable training stand
- [[Base Plot Reference]] — the one base inspiration the user liked: stud-plate plot, pedestal rows with green earnings pads
- [[Why The Game Looks Blue]] — skybox env lighting + blue OutdoorAmbient + ColorCorrection saturation; tested one at a time
- [[ViewportFrame Gotchas]] — runtime camera, no particles, real R15 arm meshes for previews

## Systems
_One note per game system as they're worked on._

## Decisions
_Dated "chose X because Y" notes. Design decisions still go in the Master Game Plan's Decision Log._
- [[Rocks Look Like Boulders]] — 2026-10-02: boulder look, user remodels by hand; what a hand-made rock must keep
- [[Forest Rock Tiers]] — 2026-10-02: stone First, boulder Second, mossy boulder Third; moss is vertex colour; export scale gotcha

## Inbox
_Unsorted learnings for the user to review._
