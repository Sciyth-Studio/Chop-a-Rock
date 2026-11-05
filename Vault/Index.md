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
- Procedures belong in skills (`.claude/skills/`), not here: `model-workflow` (start of any modelling request), `batch-model` (a whole set in one Blender file), `rock-model`, `studio-ui`, `studio-playtest`, `vfx`, `new-zone`, `studify` (builds made from Studio parts: fit, stud variants, blockouts, part recipes).

## Project
- [[Chop a Rock]] — what the game is, repos, design source of truth
- [[To Do]] — running task list: next, approved, waiting on the user, deferred; phases in `ROADMAP.md`
- [[Launch Checklist]] — pre-launch actions from Hud's Guide (Downloads): first 5 minutes, analytics, session length, performance, page setup, ad run; "Your call" items need the user's decision
- [[Trello Board]] — shared Chop A Rock board with the user's brother (faultypunisher); lists, label colours, connector limits

## Preferences
- [[Code Output Rules]] — whole files, no comments, no scope creep, propose-and-wait on player-facing changes
- [[Only Surface Blocking Opens]] — on status questions, name only items that gate current work
- [[High Saturation Colors]] — max-saturation by default; chop-quality palette
- [[Realistic Rock Bodies]] — zone rock bodies are muted realistic stone (user retinted them in Studio); only props are saturated; read the templates, not recipes.md
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
- [[Pets Stay Rocks]] — superseded 2026-11-03 by [[Animal Pets]]; only describes the rock Pets until the swap ships
- [[Reuse Pet Eyes]] — copy Bloky's eye and pupil meshes for every Pet, never rebuild them
- [[Keep Decor Simple]] — zone decor is few, primitive-shape props; reuse and recolour; Studio parts and particles over Blender models
- [[Decor In ForestTree Style]] — decor is built like the JungleTree (crossed-box stud courses, alternating shades, chunky trunks, root fins); greens match their zone floor; settled 2026-10-28
- [[Decor Without References]] — decor reference prompts are run with no images attached; the look is written into the prompt
- [[User Playtests Changes]] — the user playtests in Studio; Claude runs check.ps1 and lists what to try, and playtests only when asked
- [[Ask The User To Look]] — need eyes on something in Studio? Ask the user instead of long screenshot loops
- [[Menu Panel Style]] — dark grey stud body, striped gradient header, Chrome title, black outlines, sharp corners
- [[Bacon Hair In Marketing Art]] — the avatar in every icon and thumbnail is the Bacon Hair; studs only on the ground, if at all

## Reference
- [[Game Icon Pack]] — the game's icons come from the user's Free Icon Pack v3.1 (Downloads); the ChatGPT style sheet `assets/Icons/Cannon/IconStyleSheet.png` is 8 of them; check the pack before prompting; use "1st" (no outline)
- [[Game Icon Reference]] — 2026-10-31 icon + thumbnail: over-the-shoulder Bacon Hair chop icon, the plain baseplate + sky background wording the user loved, 1 vs 999,999 split thumbnail; prompts in `assets/Icons/GameIcon/` and `assets/Icons/GameThumbnail/`
- [[Balance Model]] — the user's Excel economy model (Downloads, v8), kept in this chat since 2026-10-19: tabs, syncing it to the Luau, editing it via Excel COM
- [[Master Game Plan]] — design source-of-truth doc and its tags
- [[Team Create Saves]] — Team Create is on: Studio edits save to Roblox as they're made; never ask the user to Ctrl+S (2026-10-29)
- [[Studio Live Editing vs Rojo]] — new instances sync but script edits don't → restart Studio
- [[Tile Style Reference]] — 2026-10-15 pilot restyle (HUD tiles + Daily Rewards panel): outline + colour-to-clear gradient + shade box tiles, translucent dark bodies, square corners, stud headers, no stripes; applied to menu buttons and shops, backups in `UIBackup.BeforeTileStyle`
- [[UI Style References]] — screenshots of panel UI the user likes; open before building or restyling menus
- [[Studded Panel Style Reference]] — 2026-10-05 restyle target: dark stud body, striped gradient headers, white/black-stroke text, sharp black outlines
- [[Tintable Mesh Textures]] — studs are the 2022 MaterialVariants in MaterialService (`2022 Inlet`, `2022 Stud` = outlet); copy MaterialVariant with Material
- [[Fight Flow Reference]] — 2026-11-03 clip of another game's fight the user wants ours designed like: charge banner, 3-2-1 camera cuts, side-on tug of war, red tint, result banner, landing dent and arrows
- [[Boulder Reference]] — reference image for the boulder-style chop rocks; open before modelling rocks
- [[Font Glyphs]] — which arrows/symbols render in the game font (▶ and the Robux icon do, ➜ doesn't)
- [[Zone Line]] — since 2026-11-04 zones only scale in length (table at top; all 220 wide, Ruins 1108 long, line ends z 5118), with fewer rocks in later zones; `RetainingWall` on each terrace's outer edge; zone order forest → desert → jungle → ocean → snow → swamp → savanna → bamboo → volcano → ruins + walled square boss arena (6-10 are blockouts; signs never say "Golem"); folders, Z ranges (168 apart since 2026-10-16), floor/terrace colours, whole-stud grid and the lobby gap fix
- [[Forest Zone Entrance]] — transparent wall + SurfaceGui sign at the forest gateway; copy for new zones
- [[Asset Ownership]] — game moved to the Sciyth Studio group 2026-10-03; old assets user-owned but shared; recover a sourceless image via EditableImage pixels
- [[Open Cloud Key]] — `ROBLOX_API_KEY` user env var; assets + dev products scopes; reaches group assets; never print it
- [[Shop Stall Reference]] — striped-awning market stall sheet for the lobby shops; three meshes for recolouring
- [[Stand Name Signs]] — shop / "Wood Training" name billboards (Arm Shop deleted 2026-10-18) above the stands; BillboardGuis don't show in screen_capture
- [[Geode Reference]] — closed + split geode sheets; flat chipped faces, no bumps, crystals are a separate rarity-coloured part
- [[Egg Lineups]] — 2026-11-05 ChatGPT lineups for the 20 zone eggs, what to take from each; modelled in meshlab with Lune
- [[Geode Stand Reference]] — per-zone pedestal geodes are bought from; tapered stone plinth with corner crystals
- [[Hatch Reveal Reference]] — the old full-screen Pet reveal (big name, odds %, NEW!, sunburst, money stat); the card was replaced 2026-11-03 by an in-world label, the geode's hover, white and rarity steps stay
- [[Free Camera Hatch Reference]] — 2026-11-03 frames from the user's clip: the egg opens where it sits while you walk and turn the camera, then the Pet stands there with its name and $/s
- [[Index UI Reference]] — three simulator Index screenshots: zone card grid, detail pane with rewards and Claim, Claim All, variant tabs down the side
- [[Cannon Shop UI Reference]] — 2026-10-20 inspo for the Cannon Shop (tried, then dropped for the Aura Shop look): zone-tinted tall cards per tier (preview, zone block, cash + Robux price, Unequip), subtitle + cash line, footer line
- [[Geode Stand UI Reference]] — egg-shop screenshots for the stand's odds/buy modal: header, 3x2 pet cards with %, big buttons; opened by prompt
- [[Monetization References]] — 2026-10-24: 20 screenshots of other games' Robux UI, the `09 Monetization` notes (Downloads), and the user's calls: timed boosts crucial, paid geodes OK, gifting and server boosts in; feeds `RobuxShopPlan.md`
- [[LihFolk Vault]] — 2026-10-28 third-party Roblox vault in Downloads (825 notes); read-only, don't run its installer; odds-disclosure, receipt, pity, onboarding notes worth checking against
- [[Leaderboard Reference]] — 2026-10-21 in-world leaderboard inspo: signpost list with headshots, ranked table with medal rows and pinned "#100+ You", stone arch built from world pieces (the dog in it is that game's HUD)
- [[Shopkeeper Avatar]] — R6 avatar of user 341574948 leaning on the geode stand; how to import and pose one
- [[Zone Rocks Reference]] — ChatGPT sheets for the desert to ruins chop rocks (zones 6-10 added 2026-10-31) (3 each, with props); open before modelling them
- [[World 1 Rocks]] — the 15 zone 6-10 rocks built 2026-10-31: asset ids, props, colours, tris; decor props are meshlab OBJs, cracks/runes carved, no split models
- [[Diamond Rock Reference]] — 2026-10-13 sheet: the whole Diamond Rock is a cyan crystal cluster on a faceted base, crystals radiating all round
- [[Mossy Stone Reference]] — 2026-10-14 remodel of the forest Mossy Boulder (Third): faceted rock with a separate thick moss cap and moss split halves
- [[Bloky Reference]] — first Pet (pet rock): chamfered cube, chamfered-square eyes as separate meshes
- [[Swamp To Ruins Animal Sheets]] — 2026-11-04 six-view sheets for the animal Pets in zones 6-10, what to take from them and where the builds are
- [[Fox Reference]] — 2026-11-03 sheet and approved model for the Fox, the first animal Pet and the look to compare the others against; prompts attach Bloky's sheet, not this one
- [[Forest Animal Sheets]] — 2026-11-03 six-view sheets for the five Forest animal Pets beside the Fox; batch-built in `ForestAnimals.blend`
- [[Desert To Snow Animal Sheets]] — 2026-11-03 six-view sheets for the Desert, Jungle, Ocean and Snow animal Pets; batch-built in one `<Zone>Animals.blend` per zone
- [[Capybara And King Rex Sheets]] — 2026-11-03 sheets for the exclusive animal Pets; King Rex has its own dinosaur shape; built in `ExclusiveAnimals.blend`
- [[Sprout Reference]] — Uncommon forest Pet: Bloky's body and eyes plus a two-leaf seedling mesh on top
- [[Shroomy Reference]] — Rare forest Pet: taller Bloky body, red-spotted mushrooms on top and the left side
- [[Nesty Reference]] — Epic forest Pet: Bloky body, low-poly twig nest with three pebble eggs on top (~480 tris for nest + eggs)
- [[Berry Reference]] — Legendary forest Pet: Bloky body, faceted leaf crown with four glowing magenta berries
- [[Treebo Reference]] — Secret forest Pet: Bloky body, three-blob faceted tree from the back right, glowing firefly cubes
- [[Desert Pets Lineup]] — 2026-10-14 lineup of the six golden amber desert Pets; attach to every desert six-view prompt; Sunny's crystal crown not to be copied
- [[Desert Pet Sheets]] — 2026-10-14 six-view sheets for all six desert Pets; per-Pet notes on what to take (Sunny = flat sun rays, Ankhy ankh stands upright)
- [[Jungle Pet Sheets]] — 2026-10-16 six-view sheets for the six dragon-fruit-pink jungle Pets; batch-built in one `JunglePets.blend`
- [[Ocean Pet Sheets]] — 2026-10-19 six-view sheets for the six coral orange ocean Pets (Drip, Bubbly, Shelly, Reefy, Glowy, Chompy); batch-built in one `OceanPets.blend`
- [[Snow Pet Sheets]] — 2026-10-20 six-view sheets for the six frost blue snow Pets (Hexy, Beanie, Cozy, Stacky, Climby, Starry); batch-built in one `SnowPets.blend`
- [[Exclusive Pet Sheets]] — 2026-10-25 sheets for the off-white exclusive Pets: Champ (red karate headband, starter pack) and Kingy (gem crown and red cape, exclusive stand); built in `ExclusivePets.blend`
- [[Training Stand Reference]] — karate board-stand, sawhorse and pine-board images for the breakable training stand
- [[Training Upgrade Sign Reference]] — 2026-10-14 in-world "Upgrade / Level 2 > Level 3" sign with red cash and purple Robux buttons, for the training stand
- [[Base Plot Reference]] — the one base inspiration the user liked: stud-plate plot, pedestal rows with green earnings pads
- [[Why The Game Looks Blue]] — skybox env lighting + blue OutdoorAmbient + ColorCorrection saturation; tested one at a time
- [[Baked Face Shading]] — greyscale per-face vertex colours baked in Blender; no longer used on buildings (see Flat Shading On Buildings)
- [[Studio Reimport]] — Alt+Shift+R updates an imported Model's meshes in place by mesh name; keeps colours, materials, children
- [[ViewportFrame Gotchas]] — runtime camera, no particles, real R15 arm meshes for previews
- [[Item Icon Rendering]] — icon spike 2026-10-23: variant tile = StudsPerTile world studs, Roblox (x,y,z) = Blender (-x,z,y), VF lighting is sRGB colour × (0.667 + 0.58 N·L), headless Blender renderer gotchas
- [[Pet Icon Reference]] — 2026-10-23 target look for Pet icons: near-front bright render, real raised studs, thick black outline following the studs
- [[Trove Promises]] — `trove:AddPromise`, never `trove:Add`, for Promises; Add throws on a settled one and disables the whole screen (broke the HUD strength counter 2026-10-23)
- [[Number Ticker]] — `Utils/NumberTicker` counts HUD numbers up over 0.3-0.6 s on one shared Heartbeat, writing text only when the formatted string changes; decreases snap
- [[Movement Lock]] — freeze the player only via `Utils/MovementLock` (ref-counted); overlapping save/restore left WalkSpeed stuck at 0 after chops
- [[VFX Showcase]] — `Workspace.VFXShowcase` stands + local plugin loop every effect in Edit; add a stand per new effect
- [[Rock Showcase]] — `Workspace.RockShowcase` at x -900 (moved 2026-10-31, the scaled terraces had swallowed it): every zone's rocks (+ exploded splits for Forest to Snow) on EditorOnly plates; `RockShowcase` plugin mirrors template colour edits live; rebuild script in `rock-model`
- [[Slice Test]] — live EditableMesh rock slicing: Perfect/Master breaks use `Utils/LiveSplit` (prepared at chop start, cut square to the chop camera, SplitModel fallback) since 2026-10-24; `Workspace.SliceTest` (StudioOnly) swipe test west of the lobby; only ~8 growable EditableMeshes fit, so pieces are copied to fixed-size ones
- [[VFX Reference Folder]] — `Workspace.VFXReference`: the user's example effects (aura, tornado, lightning, explosion); the VFX quality bar
- [[VFX Texture Kit]] — `Downloads/VFX Assets`: 1,935 ready-made particle/flipbook/beam textures, catalogued in its `_catalog/`; the vfx skill checks it before drawing (`kit.py`)
- [[Studio Assets Folders]] — `ReplicatedStorage.Assets` Models/VFX sorted into feature subfolders (rocks by zone); AssetRegistry looks up recursively
- [[Animation Uploads]] — Claude makes R15 clips itself: pose data → .rbxmx → Open Cloud upload as `model/x-rbxm`; Edit preview needs unanchored limbs + `StepAnimations`; uploads can't be archived
- [[Intro Car Reference]] — 2026-10-27 six-view sheet for the intro's red toy convertible (stripe, round headlights, tucked wheels); body lowered to ~3 studs to keep the seat and Boing Out clip
- [[Decor Lineups]] — cartoon lineup sheets for the zone decor props (A forest/desert, B jungle/ocean/snow 2026-10-28; C swamp/savanna, D bamboo/volcano/ruins 2026-10-29); built as meshlab `Decor*` models
- [[Meshlab]] — MIT kit in `tools/meshlab` (Luau-built stud props → Lune → Blender preview); export_fbx.py → upload_model.ps1 → LoadAsset at 1 unit = 1 stud; Blender 5.2 path, absolute paths; `ForestTree` used for the intro trees
- [[Chop Dummy]] — chop is two clips in `Assets/Animations` (WindUp loop + Strike) played by `Utils/ChopAnimation`; tag an R15 rig `ChopDummy` to loop it

## Systems
_One note per game system as they're worked on._
- [[Bases]] — 6 plots cloned onto `BaseSpot` plates in a U around the centre shops; claim on join, per-base `BaseSpawn`, owner-only training stand; owner signpost (headshot + username) by the entrance; plots leaked on leave until 2026-10-28 (`PlayerRemoving` sees Parent nil → `DataSessions:BeginRelease`)
- [[Rock Spawning]] — per-player rocks rise in `RockSpawnArea` boxes; each rock kind spawns in its own strip, weakest by the `ZoneEntrance` (2026-10-29); server keeps data, client draws rocks and effects; forest floor is rotated and sits on the Baseplate
- [[Zone Geodes]] — 2026-11-03, not playtested: 4 free geodes per player per zone, anywhere in the zone clear of walls, decor and your rocks; 30 s respawn; going for one starts the enemy fight; `ZoneGeodeService`, `ZoneGeodeController`, `ZoneGeodeConfig`, admin Spawn Zone Geode
- [[Admin Panel]] — tabbed top-bar "Admin" panel: presets (+ Studio auto-preset), warps (`Workspace.AdminWarps`), value commands, Reset Player Data (name + press twice), testing-speed commands, Ctrl+Shift+Space command bar, data snapshots; add a command = config entry + `AdminService/Commands` handler
- [[Global Announcements]] — admin `Global Message` (Events tab, `announce`) → filtered, gold 8 s notification in every server via MessagingService; bypasses the Notifications setting; `AnnouncementService`, `AnnouncementConfig`
- [[Teleport Bar]] — top-centre Base / Shops / Rocks buttons; Shops pops out Aura / Cannon on top with Sell centred below; `TeleportService` ends chops first, cooldown 3 s (draft), markers in `Workspace.TeleportPoints`
- [[Index]] — Pets + Rocks pages, per-entry cash/strength claims, +10% money per completed zone, HUD badge; `IndexService` + `IndexRewards`
- [[Geode Shop]] — odds screen removed 2026-11-03 (backup in `UIBackup`); was one lobby shop, a tab per zone geode, opens on the zone your Best Strength reaches; buying gated on Best Strength (kept through rebirth), cracking ungated (2026-10-28); new zone = config only (no stand); pity bars (Legendary + Secret guarantees per geode, built 2026-10-22); pit "Choose Geode" picker saves which geode cracks next (2026-10-28)
- [[Auto Open]] — 2026-10-28 game pass: third pit prompt (R) starts hands-off cracking of owned geodes, rolled quality through `Cracking.Finish` (pity unchanged), stop pill, stops on range/out of geodes/bag full; `GeodeService/AutoOpen`, `AutoOpenConfig`, `Screens/AutoOpenButton`
- [[Pedestals]] — Pets as Backpack tools, pedestals earning flat $/s onto green pads (cleared on rebirth), slots, Equip Best, Pets panel, idle motion (breathe, blink, drop-in); `PedestalService` + `PetService/Tools` + `Components/IdlePet`
- [[Held Items]] — 2026-11-03, not playtested: held Pets and geodes sit above the head, both arms up; `HeldItemController`, `Utils/HeldGrip`, `HeldItemConfig`
- [[Toolbar]] — 2026-10-29 custom hotbar (Roblox Backpack CoreGui off) of Pet stacks with keys 1-7, `PetsToggle` or ~ opening the Pets inventory panel (stacked cards, search, Placed badge, Equip Best, +1 Slot); `Screens/Toolbar`, `Screens/Pets`, `UIController/PetStacks`, `ToolbarConfig`
- [[Pet Sizes]] — Tiny/Normal/Big/Giant/Huge/Colossal (15/55/20/7/2.5/0.5%, x0.75-x2 scale, 2026-10-29) rolled on every grant, luck pushes only sizes above Normal, looks only; `PetSizeConfig`, `PetSize`, `Pet.Size`
- [[Sell Shop]] — green lobby stall selling Backpack Pets (100 s of income, draft); sort Value/Rarity/Newest, Select All; replaced Delete
- [[Chop Effects]] — hit/crack/break/Perfect/Master VFX + coin cash pop; `Tint`/`MinQuality` attributes, scaled by rock size from code
- [[Shop Pads]] — neon floor rectangles open the Geode, Sell and Aura shops on approach, "Open" prompt to reopen while standing on one; `ShopPad` tag + `Screen` attribute; Beam width gotcha
- [[Settings]] — master Volume with -/+, Music/SFX/Low Graphics/Auto Equip/Notifications toggles; what each does
- [[Golden Rocks]] — replaced Rush Rocks 2026-11-03: 2% draft chance a rock spawns gold, x3 pay, no timer; `RockController/Golden`, `GoldenRockConfig`, admin Ctrl+Shift+R
- [[Geode Fall]] — one geode per player, max 4, crashes into reached zones; since 2026-11-03 first to press Take gets a Falling Geode item (Rare or better), no chop or fight; `GeodeFallService`, `RockController/GeodeFall`, `GeodeFallConfig`, admin Ctrl+Shift+F; anti-teleport sampling
- [[Diamond Rock]] — shared server rock rolled by the Event Clock at a random clear spot, beacon, no timer pill since 2026-11-03, 60 s, paid per hit by damage share; `DiamondRockService`, `DiamondRockConfig`, admin Ctrl+Shift+D / T
- [[Chop Minigame]] — 2026-11-03 draft: horizontal `ChopBar` in the enemy fight bar's style, hotbar hidden, over-the-shoulder wind-up camera that moves to the chop camera on release; wall pull-in; numbers in `ChopConfig`
- [[Hot Streak]] - chained Good+ chops multiply chop money, add walk speed, head fire; `HotStreakService`, `WalkSpeedService`, `HotStreakConfig`
- [[UI Feel]] — every button darkens + grows on hover with a tick, squashes on press, clicks; `UIController/ButtonFeel`, `UIFeelConfig`; UIScale pivot/list-layout gotchas; panel pop, `Shimmer` attention shine, `context.Feedback` success bounce / error shake, toggle and tab sounds
- [[Cannon Shop]] — lobby shop (opposite Free Gift at x 156, z -207, facing into the lobby since 2026-11-03) with one cannon per zone from the desert (all nine, Desert to Ruins, since 2026-10-30), free and auto-unlocked at the zone's strength since 2026-11-03; Equip, then walking into the Forest pops a 5 s Fire Cannon button (since 2026-10-31; `Workspace.CannonTrigger`) and the `LobbyCannon` fires you on a 2 s arc to `TeleportPoints.Cannon<Zone>`; zone-coloured charge/blast/trail/landing/equip effects and sounds (`Assets/VFX/Cannon`, `Assets/Sounds/Cannon`); `CannonService`, `CannonController`, `CannonConfig`
- [[Auras]] — since 2026-10-18 auras replace arms: cash tiers in order at the red Aura Shop (15 tiers for world 1 = zones 1-10 since 2026-10-28, one per zone), training x (old arm numbers) + speed (+2 to +80, raised 2026-11-04 for the longer zones, draft); one `VFX_Aura` template tinted per tier; `AuraService`, `AuraController`, `AuraConfig`, `Screens/Shop`
- [[Event Clock]] — 2026-10-29: every 5 min (:00/:05 server time) one event rolls: Geode Fall 40, Diamond Rock 35, Weather 25, no repeats; `EventClockService`, `EventClockConfig`; Rush Rocks stay separate
- [[Weather]] — events rolled by the Event Clock, 4 min each, 1 in 4 rocks spawn as storm rocks (pay boost; hitting them raises the once-a-minute catch roll), at most one Pet per player catches per roll, hatch modifiers, lighting looks, weather pill; `WeatherService`, `WeatherController`, `WeatherConfig`
- [[Tutorial]] — 5-step first-time tutorial, no Skip (2026-10-27), then a staggered aura hint (`AuraHintService`); `TutorialService` owns the step in PlayerData and logs a 13-step onboarding funnel to 60 min played; `TutorialController` pins notification text, straight-line chevrons, teleport-button spotlights, SpotlightUI on buy buttons, chop-meter pointer, red pad locks; weather ignored while it runs
- [[Kid Friendly Pass]] — 2026-10-29, not playtested: phone-only wider/slower chop zones (`TouchChop` attribute, `ChopZones` isTouch), left click to chop, short notifications with an optional icon, free first Master Chop 2-4 min after the tutorial (`RockService/FirstMaster`), Huge Shroomy from the tutorial geode
- [[Intro Cutscene]] — 17 s "The Master" intro on first load (2026-10-27, not playtested): boulder squashes your car, the Master's chop, "Go train, kid!", lands facing your stand; client-only set, `IntroController`, `IntroConfig`
- [[Loading Cover]] — 2026-10-28 join cover for everyone (stud backdrop, Gold title, bouncing Bloky, progress bar built on progress-bar psychology: head start, real milestones, creep, end dash, backwards ribs, stage text); closed by `IntroController` after data, or after the intro's preload + first-shot warm-up (fixed the intro's start-up hitches); `LoadingCoverConfig`
- [[Analytics]] — 2026-10-27: cash economy events on every server cash change (`AnalyticsConfig` Sources/Sinks, `Utils/Analytics`, `AdjustCash(..., flow, detail)`) and a 3-step `RobuxShop` funnel (`RobuxShopFunnelService`); onboarding funnel stays in Tutorial
- [[Cash Packs]] — four Robux packs worth 3/12/40/150 of your zone's geode; a can't-afford buy (auras, cannons, geodes, slots, training sign) opens the Robux prompt for the covering pack directly, no popup; `CashPackConfig`, `Utils/CashPack`, `CashPackController`; stand products off sale
- [[Item Icons]] — 2026-10-23: Blender-rendered PNG icons for Pets/rocks via `Utils/ItemIcons` (ViewportFrame fallback) in Index, Geode Stand, Pets and Sell Shop (HatchReveal stays 3D); generated `ItemIconConfig`, `scripts/upload_icons.py`, `item-icons` skill; all 45 icons live 2026-10-24, Champ and Kingy added 2026-10-25
- [[Player List]] — 2026-10-28 Roblox-style top-right `leaderstats`: Strength, Money, Rebirths as NumberValues ranked by Strength, 0.5 s refresh; `PlayerListService`, `PlayerListConfig`
- [[Leaderboards]] — four global lobby boards (Strength, Money/s, Perfect Chops, Playtime), 60 s refresh, #1 statue; `LeaderboardService`, `Components/Leaderboard`, `LeaderboardConfig`; boulder-style mesh slabs with the board on a `BoardFace` part; weekly tab, #1 crown + chat tag, pass toasts (2026-10-22, `CrownController`, `Passes`)
- [[Free Gift]] — 2026-10-28 lobby pad by the entrance opens a "Free Gift!" panel (like, favorite, join steps); Claim checks the favorite on the client (permission prompt, since 2026-11-03) and Sciyth Studio group membership server-side (`GetGroupsAsync`, not cached `IsInGroup`), likes can't be checked; once per player (`Offers.FreeGift`), cash worth 3 zone geodes; meshlab cash chest on the pad since 2026-10-30; `FreeGiftService`, `Screens/FreeGift`, `FreeGiftConfig`
- [[Zone Enemies]] — built 2026-11-03, not playtested: one personal enemy per zone (scaled-up Common Pet), spam-click fights through `EnemyService:RequestFight`, launched if you lose, flees at 25x; `EnemyService`, `EnemyController`, `EnemyConfig`, `Screens/EnemyFight`, admin `fight`
- [[Wild Geode]] — 2026-10-29, not playtested: after 4-6 min of chopping the next rock you break had a geode hidden in it; the break opens it into the hatch reveal, luck from that chop, Uncommon+, pity counts, no tell; `GeodeService/Wild`, `WildGeodeConfig`, admin Ctrl+Shift+J

## Decisions
_Dated "chose X because Y" notes. Design decisions still go in the Master Game Plan's Decision Log._
- [[No UI Scaling Landscape Only]] — 2026-11-01 phone layouts removed, mobile locked to `LandscapeSensor`, `ScreenScale` = min(w/1920, h/1080) with no clamps so phones match PC 1:1 (iPhone ~0.36, Studio 0.78)
- [[Roks Renamed To Pets]] — 2026-10-31 "Rok" became "Pet" everywhere (code, Studio, assets, vault); no save migration
- [[Rocks Look Like Boulders]] — 2026-10-02: boulder look, user remodels by hand; what a hand-made rock must keep
- [[Forest Rock Tiers]] — stone First, boulder Second, Mossy Boulder Third (moss-cap prop since 2026-10-14; "the mossy rock" means Third); export scale gotcha
- [[Big Numbers Over Small Ones]] — 2026-10-10: billions are fine; keep tier growth, add money sinks and scale costs with income
- [[Zones After Desert]] — 2026-10-10: approved jungle, ocean, snow rocks (built as placeholders), Pets and geodes (not built); the number rules
- [[VFX From Roqer]] — 2026-10-07 Roqer VFX pipeline; since 2026-10-15 the vfx skill is the MIT `roblox-vfx` skill, runtime at `ReplicatedStorage.VFX` (Emit/Build/Capture/Shapes)
- [[Coloured Pets After Forest]] — superseded 2026-11-03 by [[Animal Pets]]; zone body colours of the rock Pets still in the game
- [[Animal Pets]] — 2026-11-03: Pets become blocky animals in natural colours on Bloky's body, no rig, real animal names; the Fox sets the style; Capybara (starter pack) and King Rex (3x best Pet) replace Champ and Kingy; draft lineup and build order in `AnimalPetsPlan.md`; not built
- [[Rebirth Gated By Strength]] — 2026-10-13: no levels; since 2026-11-03 one rebirth per rock (gate x5, draft stand unlocks at rebirths 1, 4, 7, 10, 13, each sets strength per 1 s rep); rebirth gives cash only; Robux buys the stand cash, never skips the gate (2026-10-18)
- [[Balance Pass Oct 18]] — 2026-10-18: stands set training pace (arms ≤ x2.5), offline 2 h at 0.125, spam hatching OK, Cosmic $2.4T, Index claims scale per zone (10% of gate) and the Index bonus covers pedestals; Rush+storm add, friends cap +30%, sell 60 s; Ocean geode x3, Forest geode $500 with a $150 tutorial geode; all in Luau (Cozy and the Snow geode since 2026-10-20)
- [[Training Minigame Board Slice]] — 2026-10-20: first training minigame is a Fruit Ninja-style 2D swipe game, optional on top of idle reps; server-counted slices fill a power meter that multiplies strength per rep (draft up to x2); bombs empty it
- [[Geode Fall Event]] — 2026-10-20, approved and built (see [[Geode Fall]]): 6-8 geodes crash into random zones players have reached, rolled by the Event Clock, first to chop claims one (not stealable, no per-player cap), Rare+ from that zone's geode, full Backpack = respawn
- [[Chop Timing Uses Client Time]] — 2026-10-21: chop quality judged on the client's elapsed time, clamped server-side to a fixed 0.4 s window (draft; not ping-sized); every chop flow uses `Utils/ChopTiming`
- [[Cannons And Auras Replace Arms]] — 2026-10-18: lobby Cannon Shop sells per-zone cannons you equip; arms removed, auras keep the arm multipliers and cash prices plus a little speed, one shared effect coloured by tier; old five auras scrapped
- [[Leaderboards Approved]] — 2026-10-21: Strength, Money/s, Perfect Chops, Playtime; global, 60 s; weekly tab, #1 crown, pass toast liked but not built
- [[Rarity Ribbon And Modifier Tags]] — 2026-10-23: sell cards show rarity as a gradient ribbon (`Utils/RarityRibbon`) and the modifier as its name in its weather colours (`PetModifier.PaintLabel`)
- [[Robux Shop Plan Approved]] — 2026-10-24: user accepted R1-R13 of `RobuxShopPlan.md`: paid Lucky Geodes, gifting, server boosts incl. Server 2x Luck, 24 h starter offer, VIP, exclusive Pet stand; not built
- [[Auto Open At The Pit]] — 2026-10-24: auto-open pass = hands-off cracking at your own pit (second prompt), owned geodes only, model quality mix, no auto-sell, 199 R$; `AutoOpenGeodePlan.md`, built 2026-10-28 (see [[Auto Open]])
- [[World 1 Plan]] — 2026-10-29: zones 6-10 Swamp, Savanna, Bamboo Forest, Volcano, Golem Ruins; stands Meteor/Sun/Black Hole/Galaxy; always-awake co-op Golem boss opens world 2; never time-gate a milestone; `World1Plan.md`
- [[Zone Geodes And Enemies]] — 2026-11-03, approved, not built: free geodes in zones guarded by a personal enemy (spam click, launched if you lose), 8 hatch pads at a remodelled base, 8 best Pets pay your account; shop, cracking, pity, Auto Open and Wild Geodes go; `ZoneGeodesPlan.md`
- [[Eggs Replace Geodes]] — 2026-11-05: two egg models per zone replace the geodes, each dressed from a zone rock, second item key per zone so the look stays; players see "egg", code keeps `Geode`; all ten zones switched over and playtested by Claude 2026-11-05, zones 6-10 Pets and odds are drafts; `EggModelsPlan.md`
- [[Geodes As Inventory Items]] — 2026-11-03: geodes are held items (hotbar first, Pets panel), placed and opened on hatch pads with the camera free and an in-world Pet label; Geode Fall is a plain pickup that keeps Rare or better; zone geodes spawn anywhere in the zone
- [[Rock Props Reuse Decor]] — 2026-10-31: a rock prop that exists as zone decor (acacia, bamboo, cattails, termite mound...) uses the real meshlab decor mesh, white + `2022 Stud` so vertex colours show; MeshSlicer keeps those colours on live cuts

- [[Wild Geodes]] — 2026-10-29, approved and built (see [[Wild Geode]]): the user kept the shop and added random geodes hidden in rocks; crack on the break, better-than-normal odds (Uncommon+ draft), no tell
- [[Rock Breaking Scale]] — 2026-10-30, approved; map, rocks, Diamond rock, snap and chop camera scaled 2026-10-30 (`ZoneScaleConfig`, `Utils/ZoneScale`); resistance and overkill not built: zones scale x1.15 each (rocks, floor, terraces, decor; not the character), reset per world, no pillars; visible resistance, overkill shatter at 10x; `RockBreakingPlan.md`

## Inbox
_Unsorted learnings for the user to review._
