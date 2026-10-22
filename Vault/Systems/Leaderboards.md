---
description: Four global in-world leaderboards (Strength, Money/s, Perfect Chops, Playtime) in the lobby, OrderedDataStore, 60 s refresh, top 10 + pinned You row, #1 player statue on top
type: system
updated: 2026-10-21
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

Related: [[Leaderboard Reference]], [[Pedestals]], [[Menu Panel Style]]
