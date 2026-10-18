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
- Keep [[To Do]] current: remove items once done and checked in code, add new ones when the user approves work. Read it when the user asks what's next. Update the [[Trello Board]] only when the user asks ([[Trello Sync On Request]]).
- Procedures belong in skills (`.claude/skills/`), not here: `model-workflow` (start of any modelling request), `batch-model` (a whole set in one Blender file), `rock-model`, `studio-ui`, `studio-playtest`, `vfx`, `new-zone`.

## Project
- [[Chop a Rock]] — what the game is, repos, design source of truth
- [[To Do]] — running task list: next, approved, waiting on the user, deferred; phases in `ROADMAP.md`
- [[Trello Board]] — shared Chop A Rock board with the user's brother (faultypunisher); lists, label colours, connector limits

## Preferences
- [[Code Output Rules]] — whole files, no comments, no scope creep, propose-and-wait on player-facing changes
- [[Only Surface Blocking Opens]] — on status questions, name only items that gate current work
- [[High Saturation Colors]] — max-saturation by default; chop-quality palette
- [[Literal Black And Grey]] — "black"/"grey" mean neutral black and grey, never slate or tinted; reference sheet colours don't override it
- [[UI Text Style]] — colored stroke + gradient fill; black/white only when asked
- [[No All Caps In UI]] — "Rebirth", never "REBIRTH"; in Studio labels and code strings alike
- [[UI Built In Studio]] — ScreenGuis authored in Studio, driven by UIController screens
- [[Always Restore Camera Type]] — any test script that sets the camera Scriptable puts it back to Custom before it ends
- [[Stage Only Own Files]] — parallel sessions; `git add` by explicit path
- [[Trello Sync On Request]] — touch the Trello board only when the user asks; no automatic mirroring of To Do (2026-10-15, token cost)
- [[Drop In Assets Over Ids In Code]] — asset lists (music etc.) read a Studio folder, not ids in config
- [[Studs On Models By Default]] — every model gets the stud overlay unless told otherwise
- [[Flat Shading On Buildings]] — buildings are flat-coloured (no baked shading) since 2026-10-10; studs + part Color only
- [[Simple Names No Material Clash]] — player-facing names are simple kid words, never a rock material
- [[Roks Stay Rocks]] — pet rocks are rocks with eyes, never animals made of rock; theme via props and formations
- [[Reuse Rok Eyes]] — copy Bloky's eye and pupil meshes for every Rok, never rebuild them
- [[Keep Decor Simple]] — zone decor is few, primitive-shape props; reuse and recolour; Studio parts and particles over Blender models
- [[Decor Without References]] — decor reference prompts are run with no images attached; the look is written into the prompt
- [[Ask The User To Look]] — need eyes on something in Studio? Ask the user instead of long screenshot loops
- [[Menu Panel Style]] — dark grey stud body, striped gradient header, Chrome title, black outlines, sharp corners

## Reference
- [[Master Game Plan]] — design source-of-truth doc and its tags
- [[Studio Live Editing vs Rojo]] — new instances sync but script edits don't → restart Studio
- [[Tile Style Reference]] — 2026-10-15 pilot restyle (HUD tiles + Daily Rewards panel): outline + colour-to-clear gradient + shade box tiles, translucent dark bodies, square corners, stud headers, no stripes; applied to menu buttons and shops, backups in `UIBackup.BeforeTileStyle`
- [[UI Style References]] — screenshots of panel UI the user likes; open before building or restyling menus
- [[Studded Panel Style Reference]] — 2026-10-05 restyle target: dark stud body, striped gradient headers, white/black-stroke text, sharp black outlines
- [[Tintable Mesh Textures]] — studs are the 2022 MaterialVariants in MaterialService (`2022 Inlet`, `2022 Stud` = outlet); copy MaterialVariant with Material
- [[Boulder Reference]] — reference image for the boulder-style chop rocks; open before modelling rocks
- [[Font Glyphs]] — which arrows/symbols render in the game font (▶ and the Robux icon do, ➜ doesn't)
- [[Zone Line]] — zone order forest → desert → jungle → ocean → snow; folders, Z ranges (168 apart since 2026-10-16), floor/terrace colours
- [[Forest Zone Entrance]] — transparent wall + SurfaceGui sign at the forest gateway; copy for new zones
- [[Asset Ownership]] — game moved to the Sciyth Studio group 2026-10-03; old assets user-owned but shared
- [[Open Cloud Key]] — `ROBLOX_API_KEY` user env var; assets + dev products scopes; reaches group assets; never print it
- [[Shop Stall Reference]] — striped-awning market stall sheet for the lobby shops; three meshes for recolouring
- [[Stand Name Signs]] — "Arm Shop" / "Wood Training" / "Geode" billboards above the stands; BillboardGuis don't show in screen_capture
- [[Geode Reference]] — closed + split geode sheets; flat chipped faces, no bumps, crystals are a separate rarity-coloured part
- [[Geode Stand Reference]] — per-zone pedestal geodes are bought from; tapered stone plinth with corner crystals
- [[Hatch Reveal Reference]] — full-screen Rok reveal (big name, odds %, NEW!, sunburst, money stat, "Click to continue"); geode hovers, turns white, grows by rarity
- [[Index UI Reference]] — three simulator Index screenshots: zone card grid, detail pane with rewards and Claim, Claim All, variant tabs down the side
- [[Geode Stand UI Reference]] — egg-shop screenshots for the stand's odds/buy modal: header, 3x2 pet cards with %, big buttons; opened by prompt
- [[Shopkeeper Avatar]] — R6 avatar of user 341574948 leaning on the geode stand; how to import and pose one
- [[Zone Rocks Reference]] — ChatGPT sheets for the desert, jungle, ocean, snow chop rocks (3 each, with props); open before modelling them
- [[Diamond Rock Reference]] — 2026-10-13 sheet: the whole Diamond Rock is a cyan crystal cluster on a faceted base, crystals radiating all round
- [[Mossy Stone Reference]] — 2026-10-14 remodel of the forest Mossy Boulder (Third): faceted rock with a separate thick moss cap and moss split halves
- [[Bloky Reference]] — first Rok (pet rock): chamfered cube, chamfered-square eyes as separate meshes
- [[Sprout Reference]] — Uncommon forest Rok: Bloky's body and eyes plus a two-leaf seedling mesh on top
- [[Shroomy Reference]] — Rare forest Rok: taller Bloky body, red-spotted mushrooms on top and the left side
- [[Nesty Reference]] — Epic forest Rok: Bloky body, low-poly twig nest with three pebble eggs on top (~480 tris for nest + eggs)
- [[Berry Reference]] — Legendary forest Rok: Bloky body, faceted leaf crown with four glowing magenta berries
- [[Treebo Reference]] — Secret forest Rok: Bloky body, three-blob faceted tree from the back right, glowing firefly cubes
- [[Desert Roks Lineup]] — 2026-10-14 lineup of the six golden amber desert Roks; attach to every desert six-view prompt; Sunny's crystal crown not to be copied
- [[Desert Rok Sheets]] — 2026-10-14 six-view sheets for all six desert Roks; per-Rok notes on what to take (Sunny = flat sun rays, Ankhy ankh stands upright)
- [[Jungle Rok Sheets]] — 2026-10-16 six-view sheets for the six dragon-fruit-pink jungle Roks; batch-built in one `JungleRoks.blend`
- [[Training Stand Reference]] — karate board-stand, sawhorse and pine-board images for the breakable training stand
- [[Training Upgrade Sign Reference]] — 2026-10-14 in-world "Upgrade / Level 2 > Level 3" sign with red cash and purple Robux buttons, for the training stand
- [[Base Plot Reference]] — the one base inspiration the user liked: stud-plate plot, pedestal rows with green earnings pads
- [[Why The Game Looks Blue]] — skybox env lighting + blue OutdoorAmbient + ColorCorrection saturation; tested one at a time
- [[Baked Face Shading]] — greyscale per-face vertex colours baked in Blender; no longer used on buildings (see Flat Shading On Buildings)
- [[Studio Reimport]] — Alt+Shift+R updates an imported Model's meshes in place by mesh name; keeps colours, materials, children
- [[ViewportFrame Gotchas]] — runtime camera, no particles, real R15 arm meshes for previews
- [[Movement Lock]] — freeze the player only via `Utils/MovementLock` (ref-counted); overlapping save/restore left WalkSpeed stuck at 0 after chops
- [[VFX Showcase]] — `Workspace.VFXShowcase` stands + local plugin loop every effect in Edit; add a stand per new effect
- [[Rock Showcase]] — `Workspace.RockShowcase` west of the zones: every zone's rocks + exploded splits on EditorOnly plates; `RockShowcase` plugin mirrors template colour edits live; rebuild script in `rock-model`
- [[VFX Reference Folder]] — `Workspace.VFXReference`: the user's example effects (aura, tornado, lightning, explosion); the VFX quality bar
- [[VFX Texture Kit]] — `Downloads/VFX Assets`: 1,935 ready-made particle/flipbook/beam textures, catalogued in its `_catalog/`; the vfx skill checks it before drawing (`kit.py`)
- [[Studio Assets Folders]] — `ReplicatedStorage.Assets` Models/VFX sorted into feature subfolders (rocks by zone); AssetRegistry looks up recursively
- [[Chop Dummy]] — chop is two clips in `Assets/Animations` (WindUp loop + Strike) played by `Utils/ChopAnimation`; tag an R15 rig `ChopDummy` to loop it

## Systems
_One note per game system as they're worked on._
- [[Bases]] — 6 plots cloned onto `BaseSpot` plates in a U around the centre shops; claim on join, per-base `BaseSpawn`, owner-only training stand
- [[Rock Spawning]] — per-player rocks rise in `RockSpawnArea` boxes; server keeps data, client draws rocks and effects; forest floor is rotated and sits on the Baseplate
- [[Admin Panel]] — tabbed top-bar "Admin" panel: presets (+ Studio auto-preset), warps (`Workspace.AdminWarps`), value commands; add a command = config entry + `AdminService/Commands` handler
- [[Teleport Bar]] — top-centre Base / Shops / Rocks buttons; `TeleportService` ends chops first, cooldown 3 s (draft), markers in `Workspace.TeleportPoints`
- [[Index]] — Roks + Rocks pages, per-entry cash/strength claims, +10% money per completed zone, HUD badge; `IndexService` + `IndexRewards`
- [[Geode Shop]] — one lobby shop, a tab per zone geode, opens on the zone your strength reaches; new zone = config only (no stand)
- [[Pedestals]] — Roks as Backpack tools, pedestals earning flat $/s onto green pads (cleared on rebirth), slots, Equip Best, Roks panel, idle motion (breathe, blink, drop-in); `PedestalService` + `PetService/Tools` + `Components/IdleRok`
- [[Sell Shop]] — green lobby stall selling Backpack Roks (100 s of income, draft); sort Value/Rarity/Newest, Select All; replaced Delete
- [[Chop Effects]] — hit/crack/break/Perfect/Master VFX + coin cash pop; `Tint`/`MinQuality` attributes, scaled by rock size from code
- [[Shop Pads]] — neon floor rectangles open the Arm Shop / Geode shop on approach, "Open" prompt to reopen while standing on one; `ShopPad` tag + `Screen` attribute; Beam width gotcha
- [[Settings]] — master Volume with -/+, Music/SFX/Low Graphics/Auto Equip/Notifications toggles; what each does
- [[Rush Rocks]] — after ~3 min of chopping the next rock rises gold near you, 20 s countdown, x3 pay; `RockService/Rush`, `RushRockConfig`, admin Ctrl+Shift+R
- [[Diamond Rock]] — shared server rock every 10-15 min at a random clear spot, beacon + HUD pill, 60 s, paid per hit by damage share; `DiamondRockService`, `DiamondRockConfig`, admin Ctrl+Shift+D / T
- [[Hot Streak]] - chained Good+ chops multiply chop money, add walk speed, head fire; `HotStreakService`, `WalkSpeedService`, `HotStreakConfig`
- [[UI Feel]] — every button darkens + grows on hover with a tick, squashes on press, clicks; `UIController/ButtonFeel`, `UIFeelConfig`; UIScale pivot/list-layout gotchas; panel pop, `Shimmer` attention shine, `context.Feedback` success bounce / error shake, toggle and tab sounds
- [[Auras]] — red lobby Aura Shop, unlock by rebirth, arms + legs + trail, +walk speed; `AuraService`, `AuraController`, `AuraConfig`, `VFX_Aura_<Key>` Limb/Body templates
- [[Weather]] — events on a shared :00/:30 clock for 5 min, 1 in 4 rocks spawn as storm rocks (pay boost; hitting them raises the once-a-minute catch roll), at most one Rok per player catches per roll, hatch modifiers, lighting looks, weather pill; `WeatherService`, `WeatherController`, `WeatherConfig`
- [[Tutorial]] — 9-step first-time tutorial; `TutorialService` owns the step in PlayerData, `TutorialController` pins notification text, pathfinding chevrons, SpotlightUI on buy buttons, red pad locks, Skip; weather ignored while it runs

## Decisions
_Dated "chose X because Y" notes. Design decisions still go in the Master Game Plan's Decision Log._
- [[Rocks Look Like Boulders]] — 2026-10-02: boulder look, user remodels by hand; what a hand-made rock must keep
- [[Forest Rock Tiers]] — stone First, boulder Second, Mossy Boulder Third (moss-cap prop since 2026-10-14; "the mossy rock" means Third); export scale gotcha
- [[Big Numbers Over Small Ones]] — 2026-10-10: billions are fine; keep tier growth, add money sinks and scale costs with income
- [[Zones After Desert]] — 2026-10-10: approved jungle, ocean, snow rocks (built as placeholders), Roks and geodes (not built); the number rules
- [[VFX From Roqer]] — 2026-10-07 Roqer VFX pipeline; since 2026-10-15 the vfx skill is the MIT `roblox-vfx` skill, runtime at `ReplicatedStorage.VFX` (Emit/Build/Capture/Shapes)
- [[Coloured Roks After Forest]] — 2026-10-14: only forest Roks are grey; each later zone's six share one saturated body colour (desert golden amber 215, 152, 35)
- [[Rebirth Gated By Strength]] — 2026-10-13: no levels; rebirth N needs zone N's toughest rock in strength; each rebirth unlocks the next training stand (set strength per 1 s rep); rebirth gives cash + luck only; Robux buys the stand cash, never skips the gate (2026-10-18)
- [[Balance Pass Oct 18]] — 2026-10-18: stands set training pace (arms ≤ x2.5), offline 2 h at 0.125, spam hatching OK, Cosmic $2.4T; in Luau except Cozy

## Inbox
_Unsorted learnings for the user to review._
