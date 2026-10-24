---
description: Four global in-world leaderboards (Strength, Money/s, Perfect Chops, Playtime) in the lobby, OrderedDataStore, 60 s refresh, top 10 + pinned You row, #1 player statue on top
type: system
updated: 2026-10-22
---
Built 2026-10-21 (see [[Leaderboards Approved]]). Not playtested yet.

**Where:** `Workspace.Leaderboards`, four Models tagged `Leaderboard` with a `Board` attribute (`Strength`, `MoneyPerSecond`, `PerfectChops`, `Playtime`). Since 2026-10-21 each one stands on the outer side of a centre shop and faces the centre the same way the shop does. Money/s is by the Sell Shop (16, −302), Perfect Chops by the Geode Shop (16, −252), Strength by the Aura Shop (68, −252) and Playtime by the Cannon Shop (68, −302). Since 2026-10-21 each `Slab` is the LeaderboardSlab MeshPart (option C of four boulder-style slabs the user picked; Open Cloud model 135655275595736; files in `assets/Lobby/LeaderboardSlab/`). It was built with `rock_builder.build_boulder` (seed 11, 8.4×3.6×11.4 units, `center_height` 0.75) and cut flat front and back at y ±1, about 100 tris. In Studio it is scaled 1.3x to 19.5×27.1×4.5 studs, bottom on the floor, and keeps the old Part's colour, Glacier material and `2022 Stud` variant. The `Board` SurfaceGui now sits on `BoardFace`, an invisible non-colliding 11.85×16.3 Part on the flat front, shifted 0.4 studs sideways. That is the biggest 16:22 rectangle that fits the flat face, checked by raycasts. `PixelsPerStud` is 800 / width (67.55), so the canvas is still 800×1100 px. `StatueSpot` sits on the slab's top centre (y 27.5). The import set `CollisionFidelity` to Default, which a script can't change: set it to Hull on each slab in Properties. Code finds `Board` and `StatueSpot` by recursive lookup, so the names matter but the parent doesn't.

**Board face:** `Panel` → `Header` (the Rebirth header's Track cloned and recoloured per board: Strength orange, Money/s green, Perfect Chops purple, Playtime sky), `Title` (Chrome, set from config). `Columns` (`Hash`/`Player`/`Column`). `List` holds a hidden `RowTemplate` (68 px: `Fill` with gradient + stripes, `Rank`, `AvatarBox.Avatar`, `PlayerName`, `Value` with the board's text style). `You` is the pinned 96 px row in the board colour. Every label has a `…Shadow` copy.

**Code:**
- `LeaderboardService` (server):
  - Every `RefreshSeconds` it adds playtime, writes each player's changed values, reads the top `RankLimit` (100) per board, resolves usernames, and sets the `Leaderboards` replica (`Boards`, `Standings` per user id).
  - Values are stored log-encoded (`Stores.Encode`), so trillions fit in an OrderedDataStore.
  - Studio uses `Leaderboard_Studio_<Key>` stores. If datastores fail, it falls back to ranking the players in this server (warns once).
  - `Statues` builds the #1 player's R15 avatar on `StatueSpot`, scaled `StatueScale`, tagged `ChopDummy` so it loops the chop. It only rebuilds when #1 changes.
- `LeaderboardController` (client) holds the replica. The `Leaderboard` component clones the rows and renders on change.
- Config: `LeaderboardConfig` (boards, titles, row and medal colours, timings).

**Stats:**
- `PerfectChops` (new PlayerData field) counts Perfect and Master chops on rocks, the Diamond Rock, Geode Fall geodes and geode cracks. It skips tutorial chops (`StatsService:RecordChop`).
- `Playtime` (new field, seconds) is added each refresh and on leave.
- Money/s is `PedestalService:GetIncomeRate` (pedestal rates incl. Index bonus). It is live only, so it is not rewritten on leave.

**Extras (built 2026-10-22, not playtested; plan in `LeaderboardExtrasPlan.md`):**
- **Weekly tab.** Each board has `Panel.Tabs` with `AllTime` and `Weekly` buttons (copies of the Index `TabTemplate`, painted with `BlockButton.Paint` from `TabColors` / `TabIdleColors`) and a `Resets` label shown on Weekly. Columns and List moved down 64 px to make room. Tapping a tab changes only your own view, and only within `ClickDistance` of the board. Workspace SurfaceGui buttons take clicks (the training sign works the same way).
- **Weekly data.** `PlayerData.Weekly` (`Week`, `Strength` gained, `PerfectChops`, `Playtime`, best `MoneyPerSecond`). `StatsService` owns the week (`Utils/Week`, Monday 00:00 UTC) and rolls the table over when the week changes. `AddStrength` and `RecordChop` add to it; admin `SetStrength` and rebirths don't. The weekly stores are `Leaderboard_W<week>_<Key>`. Refreshes read the two tabs in turn (the ordered-store read budget is 5 + 2/player a minute), so each tab updates every 2 min. The first refresh and admin `Leaderboards: Refresh` read both.
- **Crown.** After each all-time read, the server sets `LeaderboardTitles` (comma list of board keys) on every player who is the global #1. It is cleared in the datastore fallback. `CrownController` welds `Model_LeaderboardCrown` (in `Assets/Models/Leaderboards`) 0.6 studs above the head, spinning. Every crown and title is hidden on this client while the player's own geode hatch plays or `HatchReveal` is open (user, 2026-10-22). It also adds a `[#1 Strength]` chat prefix through `TextChatService.OnIncomingMessage`. The crown was modelled 2026-10-22 from a ChatGPT sheet (`assets/Lobby/LeaderboardCrown/`, Open Cloud model 76394896683299):
  - `Crown` MeshPart: gold 255,190,0, Glacier with the `2022 Stud` variant, PrimaryPart. It holds the `TitleBillboard` (Gold `#1 Strength` text, 1.5 studs up).
  - `Gems` MeshPart: Neon 255,0,50, welded to `Crown`.
  - The shape is a 10-sided hollow band, 5 points, 5 thin spikes and 10 gems, about 740 tris and 1.8 studs wide.
- **Pass toast.** `LeaderboardService/Passes`: every 5 s, in-server players on Strength, Money/s and Perfect Chops (1% margin, tutorial players skipped). Each all-time read, the global top 100. Each winner/loser pair toasts once per 10 min and each player at most once per 30 s. The new `Pass` notification kind is Gold text (`NotificationConfig.KindStyles`).
- **Admin.** `Leaderboards: Refresh` and `Leaderboards: Week Offset` (Studio only) are on the Debug tab.
- **Streaming fix (2026-10-23).** The boards stayed blank in the live game and in Play: the rows were empty and the "You" row kept its Studio sample text. The cause: the component's `Start` runs before the board's `BoardFace` and SurfaceGui have streamed in, found no SurfaceGui, and gave up. It now waits on `DescendantAdded` for the SurfaceGui, then sets the board up. Any component on a streamed model must wait for its parts like this.
- **Clickable tabs fix (2026-10-23).** A SurfaceGui parented in Workspace gets **no mouse input**: no MouseEnter, no Activated. The extras plan assumed it did. The component now clones each board's SurfaceGui into the local PlayerGui with `Adornee = BoardFace`, disables the Workspace original, and drives the clone (the trove destroys it on Stop). `BoardFace` also needs **CanQuery on**, because input raycasts skip CanQuery-off parts and hit the boulder behind it instead. CanQuery was set in Studio, so it ships with the place file. Any clickable world UI must do both.
- **Headshots fix.** `setAvatar` now searches recursively. Before this it looked for `Avatar` directly on the row, but `Avatar` sits inside `AvatarBox`, so headshots never showed.

Related: [[Leaderboard Reference]], [[Pedestals]], [[Menu Panel Style]]
