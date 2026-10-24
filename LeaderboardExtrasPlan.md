# Leaderboard extras (weekly tab, #1 crown, pass toast): plan

Status: **built 2026-10-22, not playtested** (see `Vault/Systems/Leaderboards.md` § Extras). Changes while building: the crown is a spinning 3D crown built from parts (`Model_LeaderboardCrown`) instead of a billboard image, because the free crown images had backgrounds. The board SurfaceGui stays in Workspace, because Workspace buttons take clicks. Clicks need you within 40 studs instead of using `MaxDistance`, which would hide the board. The tabs fit without shrinking the rows. Titles show for the all-time #1 only. The user liked all three on 2026-10-21 (`Vault/Decisions/Leaderboards Approved.md`) and picked the options below on 2026-10-22. Lines marked **(user)** are the user's choices; numbers marked *draft* go in `LeaderboardConfig` and are checked in a playtest.

## Read first
`AGENTS.md`, `Vault/Index.md`, vault notes `Leaderboards`, `Leaderboards Approved`, `Leaderboard Reference`, `UI Text Style`, `UI Feel`, `No All Caps In UI`, `Font Glyphs`. Code: `LeaderboardService` (`init`, `Stores`, `Statues`), `Components/Leaderboard`, `LeaderboardController`, `LeaderboardConfig`, `StatsService`, `NotificationService`. Skills: `studio-ui`, `studio-playtest`.

## Decisions (user, 2026-10-22)
- **Weekly tab:** two tab buttons on every board, *All-time* and *Weekly*. Tapping one switches only what **you** see. Each board starts on All-time.
- **Weekly values are "gained this week":** Strength gained (a rebirth doesn't wipe it), Perfect Chops this week, Playtime this week. Money/s shows your **best** Money/s this week. Resets **Monday 00:00 UTC**.
- **#1 crown:** the all-time #1 of each board gets a gold crown over their head with a title line (`#1 Strength`) and a `[#1 Strength]` tag before their chat messages. Weekly #1 gets nothing.
- **Pass toast:** fires for passing a player **in your server** (checked every 5 s) and for passing someone in the **global top 100** (each refresh).

## 1. Weekly tab

### Week number and store keys
- `Week.luau` (shared, `ReplicatedStorage/Utils`): `Week.Current(now)` = `math.floor((now - MondayEpoch) / 604800)` with `MondayEpoch = 345600` (1970-01-05 00:00 UTC, a Monday). `Week.EndsAt(week)` = `MondayEpoch + (week + 1) * 604800`. Client and server use it, so the "Resets in" text and the server agree.
- Weekly stores are new OrderedDataStores per week and board: **`Leaderboard_W<week>_<Key>`**, and **`Leaderboard_Studio_W<week>_<Key>`** in Studio (for example `Leaderboard_W2964_Strength`). A new week reads a new, empty store, so nothing has to be wiped. Old weeks are just never read again.
- `Stores.Write` and `Stores.ReadTop` take a store name instead of a board key (`Stores.Name(key, week?)` builds it), so the same code serves both tabs. Values stay log-encoded with `Stores.Encode`.
- `LeaderboardConfig.WeekOffset` (*draft* 0, Studio only) lets the admin panel jump a week to test the reset.

### Player data
New `PlayerData.Weekly` (with `Data`, `Template`, `Validate`, `Migrate` together):
```
Weekly = { Week = 0, Strength = 0, PerfectChops = 0, Playtime = 0, MoneyPerSecond = 0 }
```
- `LeaderboardService` rolls it over before it reads or adds anything: if `Weekly.Week ~= Week.Current()`, zero the four values and set `Week`. Do this on load and each refresh, so a player online across Monday 00:00 starts the new week at the next refresh.
- **Strength gained:** `StatsService:AddStrength` adds `after - before` to `Weekly.Strength` (after rollover). Admin `SetStrength` and rebirth resets don't count, because they aren't gains.
- **Perfect Chops:** `StatsService:RecordChop` adds 1 to `Weekly.PerfectChops` next to `PerfectChops`.
- **Playtime:** `countPlaytime` and `onReleasing` add the same seconds to `Weekly.Playtime`.
- **Money/s:** each refresh sets `Weekly.MoneyPerSecond = math.max(Weekly.MoneyPerSecond, current rate)`. This is the one weekly value written on leave as well, since the best is stored.
- `DataService:ResetData` and admin presets reset it; admin snapshots include it.

### Server refresh
- `writePlayer` writes the weekly values to the weekly stores the same way it writes the all-time ones (only when the encoded value changed). With 8 players that is at most 64 writes a minute, under the ordered-store write budget (`60 + 10 x players` a minute).
- **Reads alternate.** The ordered-store read budget is `5 + 2 x players` a minute, so one player alone allows 7. Reading 8 boards a minute (4 all-time + 4 weekly) would go over. Each refresh reads one tab: All-time on even refreshes, Weekly on odd ones. So each tab updates every 2 minutes and the other tab's last result is kept. *(draft; if the budget allows later, read both when 2+ players are in the server.)*
- Replica `Leaderboards` grows: `Boards` and `Standings` stay as they are (all-time). New `WeeklyBoards`, `WeeklyStandings` (same shapes) and `WeekEndsAt` (a number, from `Week.EndsAt`).
- The datastore fallback (this server's players only) works for weekly too, using `Weekly` values.
- No statue for the weekly tab. The statue stays the all-time #1.

### Board (Studio, the user's look)
- Under each board's `Header`, a new `Tabs` frame with two buttons: `AllTime` ("All-time") and `Weekly` ("Weekly"). The selected one is filled in the board's colour, the other dark (*draft*), like the Index `TabTemplate`. `ClickSound = "SFX_UI_Tab"`.
- A `Resets` label ("Resets in 3d 4h") next to the tabs, only shown on Weekly. It uses the existing `duration` formatter.
- Canvas room: the canvas is 800×1100 and is already full (header, columns, 10 × 68 px rows, 96 px You row). The tabs need about 70 px, so the rows go to 62 px (*draft*). The user checks the layout in Studio.
- The column header doesn't change between tabs. The pinned You row shows your weekly rank and value on Weekly.

### Client (`Components/Leaderboard`)
- Keeps `self.Tab` (`"AllTime"` or `"Weekly"`), starting at All-time. A tab click sets it, recolours the tabs and re-renders from `Boards`/`Standings` or `WeeklyBoards`/`WeeklyStandings`.
- Weekly Money/s is formatted the same as all-time.
- **Clicks on the board:** a SurfaceGui left in Workspace may not take clicks reliably. The first build step checks this in Studio. If clicks don't arrive, the component moves the `Board` SurfaceGui into `PlayerGui` (with `Adornee = BoardFace`, `ResetOnSpawn = false`), which is the standard way to make world UI clickable. `MaxDistance` (*draft* 60 studs) stops clicks from across the lobby.
- Button feel: `ButtonFeel.Bind` runs on screens only. The component calls it on the board gui as well, so the tabs darken, grow and tick like every other button.

## 2. #1 crown

### Who gets one
- After each refresh that read the **all-time** tab, the server sets a string attribute on every player in the server: `LeaderboardTitles`, a comma list of the boards they are #1 on (`"Strength,Playtime"`), or nil.
- Only real global #1s. In the datastore fallback (ranking only this server) the attribute is cleared, so nobody wears a crown for being first among four people.
- Someone who is #1 on several boards gets one crown. The title line lists the boards in config order: `#1 Strength & Playtime` (*draft*; more than two shows `#1 on 3 boards`).

### Overhead crown (client)
- New `CrownController`: watches every player's `LeaderboardTitles` and character. It clones `Assets/UI/CrownBillboard` onto the character's `Head` and removes it when the attribute clears.
- `CrownBillboard` (authored in Studio): a BillboardGui with a gold crown image and a `Title` label below it. The title uses the existing `Gold` text style, baked in when authored if `Typography` doesn't reach the billboard. `StudsOffset` sits above the name and above the Hot Streak head fire (*draft* 3.5 studs), `MaxDistance` 120 (*draft*), `AlwaysOnTop = false`.
- **Crown art:** a flat gold crown image, drawn and uploaded with the Open Cloud key. A 3D crown mesh (through `model-workflow`) can replace it later if the user wants one. *Open: the user picks or approves the crown image.*
- The statue on the board doesn't wear the crown (the statue already shows who is #1).

### Chat tag (client)
- `TextChatService.OnIncomingMessage` in the same controller. If the message's `TextSource` player has `LeaderboardTitles`, set `PrefixText` to `<font color="#FFC400">[#1 Strength]</font> ` + the old prefix. Several boards: the first in config order (`[#1 Strength]`), to keep chat short.
- Check first that the game uses `TextChatService` (not legacy chat). If it is legacy, this needs another approach and goes back to the user.

## 3. "You passed X!" toast

All on the server, new child `LeaderboardService/Passes.luau`, all-time boards only (weekly passes would repeat the same toast).

### In your server (every 5 s)
- Every `PassCheckSeconds` (*draft* 5) the server reads each in-server player's live value on **Strength, Money/s and Perfect Chops**. Playtime is skipped: everyone online gains it at the same rate, so the order among online players never changes.
- It keeps the last order per board. When A was behind B and is now ahead by at least `PassMargin` (*draft* 1%), A gets "You passed B in Strength!".
- Spam guards (*drafts*):
  - The first check after someone joins only records the order; joining never causes a toast for anyone.
  - A pair (A over B on one board) toasts at most once every `PairCooldownSeconds` (600). Two players trading places on Money/s while equipping Roks don't ping-pong.
  - At most one pass toast per player every `ToastCooldownSeconds` (30). If several passes land together, the toast names the highest one and adds "and 2 more".
  - Both values must be above 0, and players still in the first tutorial are left out.

### Global top 100 (each all-time refresh)
- `refresh` already builds the rank of every top-100 entry. `Passes` keeps last refresh's ranks per board. For each in-server player who is ranked now: anyone who was ahead of them last time and is behind them now (and still in the top 100) was passed.
- Toast: "You passed B! You're #12 in Strength". Only the highest-ranked person passed is named, so only that one name is resolved (`resolveNames`, which already caches).
- The same pair cooldown and per-player cooldown apply, shared with the server checks, so passing someone who is also in your server gives one toast, not two.
- Reaching the top 100 for the first time gives "You're #87 in Strength!" instead (*draft*).

### Toast
- `NotificationService:Notify(player, "Pass", text)` with a new `Pass` kind in `NotificationConfig.Kinds` (gold, *draft*). It goes through the normal notification stack, so the Notifications setting turns it off.
- The person who was passed gets no toast (not asked for; see Out of scope).

## Config (`LeaderboardConfig`, drafts)
`WeekOffset = 0`, `WeeklyStorePrefix = "Leaderboard_W"`, `StudioWeeklyStorePrefix = "Leaderboard_Studio_W"`, `TabNames = { AllTime = "All-time", Weekly = "Weekly" }`, `ResetsText = "Resets in "`, `ClickDistance = 60`, `CrownOffset = 3.5`, `CrownDistance = 120`, `PassCheckSeconds = 5`, `PassMargin = 0.01`, `PairCooldownSeconds = 600`, `ToastCooldownSeconds = 30`, `PassBoards = { "Strength", "MoneyPerSecond", "PerfectChops" }`.

## Admin
- `LeaderboardRefresh`: runs a refresh now (both tabs, ignoring the alternation) so testing doesn't wait 2 minutes.
- `LeaderboardWeek <n>`: sets `WeekOffset` in Studio to test the weekly reset.

## Build order
1. Studio check: does a Workspace SurfaceGui button on the board take clicks? Decide Workspace vs PlayerGui.
2. `Week` util, `Stores` names, `PlayerData.Weekly` + migrate, the `StatsService` hooks, weekly writes and alternate reads, replica fields.
3. Board tabs in Studio (user's look), then component tab logic.
4. `LeaderboardTitles`, `CrownController`, crown billboard and image, chat tag.
5. `Passes`, the `Pass` notification kind.
6. Admin commands, `./scripts/check.ps1`, vault notes (`Leaderboards`, `To Do`).

## Testing (Play, by value; the user plays the look)
1. Train: the Weekly Strength value grows by exactly what all-time grew. Rebirth: all-time Strength drops, weekly doesn't.
2. Perfect chop: both counters +1. Equip better Roks then worse ones: weekly Money/s keeps the best.
3. `LeaderboardWeek 1`: the weekly values reset at the next refresh, the Weekly tab is empty, then fills with you. All-time is untouched.
4. Tabs: clicking Weekly on one board changes only that board, only for you (check with a second test player). "Resets in" counts down.
5. Reads per minute stay within the budget with 1 player (watch the output for datastore budget warnings over 5 minutes).
6. Crown: the solo player in Studio is #1 globally on the Studio stores, so the crown and chat tag show. Datastores off (fallback): no crown.
7. Two test players: raise B's Strength above A's → B gets "You passed A in Strength!" within 5 s. Swap back and forth: no second toast for 10 minutes. Join a third player who is ahead: no toast.
8. Notifications setting off: no pass toasts.
9. `./scripts/check.ps1` passes.

## Out of scope
A "B passed you!" toast for the passed player; weekly rewards or prizes; a monthly tab; weekly statues; crowns for weekly #1; changing the four boards or the 60 s refresh.
