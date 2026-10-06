# Index screen: plan

Status: **approved and built 2026-10-06.** The user chose purple (D1) and went ahead with every other recommendation. The Index icon is now the purple book (`80371787143053`). Built as planned; see the vault note `Systems/Index`. Every number marked *draft* is a placeholder for playtesting and lives in config.

## Read first
`AGENTS.md`, `Vault/Index.md`, `Chop_a_Rock_Master_Game_Plan.txt` (Reasons to come back, Collection / Index, weather modifiers, §10), `GeodeSystemPlan.md`, and the vault notes `Index UI Reference`, `UI Style References`, `Menu Panel Style`, `Geode Stand UI Reference`, `ViewportFrame Gotchas`. Skills: `studio-ui`, `studio-playtest`.

## What is already decided (do not change)
- The index tracks **every kind of rock broken and every pet rock hatched** (Master Game Plan, Collection / Index).
- The index persists through rebirth.
- Weather modifiers (Dusty, Windy, Toasty, Zappy, Eclipsed) and Golden pets come later; "Index can later gain a column per modifier" and "Golden column in the index" are already noted.
- `Index.Pets` (hatch count per pet key) already exists and `PetService` already increments it. The HUD already has an `IndexButton` pointing at a screen named `Index`, which doesn't exist yet.
- Style is [[Menu Panel Style]]. The three screenshots give layout and content only.

## Layout (from the three screenshots)

```text
+--------------------------------------------------------------------------------+
| [Index]  (Chrome title, striped gradient header)                          [X]  |
+--------+-----------------------------------------------+-----------------------+
| Roks   | Roks Index  · Normal                  3 / 6   |   [ big preview  ]    |
| 3 / 6  |-----------------------------------------------|                       |
|--------|  Forest                                       |   Sprout              |
| Rocks  |  [Bloky] [Sprout] [ ??? ]                     |   Uncommon            |
| 2 / 3  |  [ ??? ] [ ??? ]  [ ??? ]                     |   1 in 4              |
|        |  [=========-----------] 3 / 6   [zone reward] |   x1.25 Money         |
|        |  (more zones stack below; list scrolls)       |   Rewards:            |
|        |                                               |   [$100] [+10 str]    |
|        |                                               |   [ Claim ]           |
|        |        [      Claim All (2)      ]            |                       |
+--------+-----------------------------------------------+-----------------------+
```

- **Panel:** about 1000 x 640 (the 560 x 410 Rebirth panel was rejected as cramped), `ScreenScale` on the root so phones shrink it.
- **Tab column (left, from shot 3):** one tab per index page, each showing "found / total". The active tab gets the striped gradient fill; inactive tabs are grey. Pages for now: **Roks** and **Rocks** (D2). Modifier and Golden tabs slot in here later.
- **Header bar (from shot 2):** page name plus "found / total" in a value pill.
- **Zone sections (shots 1 and 2):** a vertical `ScrollingFrame`. Each zone has a label ("Forest"), a grid of cards, and a progress bar with the zone-completion reward icon at its end. More zones stack below.
- **Cards:** the Geode Stand card reused: rarity `ColorGlow` + `WeldTexture` + Rok `ViewportFrame` + name. Unfound entries show a black silhouette and "???" (D6). A card with an unclaimed reward gets a small red "!" badge. Clicking a card selects it (white selection stroke) and fills the detail pane.
- **Detail pane (right, shots 1 and 2):** big preview, name (Chrome), rarity (rarity colour; Secret keeps its rainbow), "1 in N", money multiplier, hatch count, then **Rewards:** tiles and a **Claim / Claimed!** button (green / grey, weld texture like every menu button).
- **Claim All (N)** along the bottom of the middle column; grey and reading "Claim All" when there is nothing to claim.

## 1. Decisions needed

| # | Question | Recommendation | Why |
| --- | --- | --- | --- |
| D1 | Header colour | **Purple** (edge 120,0,220, centre 200,120,255, studs 70,0,140). | Rebirth is red, Arm Shop orange, Geode Stand sky blue; shot 1's magenta is close to this and still unused. |
| D2 | Ship the **Rocks** page now? | **Yes.** Count breaks per `RockKey` in `Index.Rocks` (RockService on a break). Three forest rocks today. | It's already decided that the index tracks rocks. It's cheap, and the tab column isn't a lone tab. |
| D3 | Per-entry reward | **Cash + Strength**, scaled by rarity. *Drafts:* Common $50 / +5, Uncommon $100 / +10, Rare $250 / +25, Epic $600 / +60, Legendary $1,500 / +150, Secret $5,000 / +500. Rocks: $100 / +10 each. | Two tiles like the screenshots, and both feed our two currencies. Strength resets on rebirth, but each reward is claimed once anyway. |
| D4 | Zone-completion reward (icon at the end of the bar) | **Permanent +10% money** per completed zone page (*draft*), kept through rebirth. | Gives completion a lasting goal, which is the "reason to come back" the plan lists. |
| D5 | Retroactive rewards | Entries hatched or broken **before** this ships are claimable. | Early players shouldn't lose rewards they earned. |
| D6 | Unfound entries | **Silhouette + "???" for every unfound entry**, Secret included. The stand still shows non-Secret Roks openly. | Filling in the silhouettes is the collection hook; the stand still tells you what's inside. |
| D7 | Odds line | "1 in N" at base luck (no luck, no gamepass), from the geode's weights: Bloky 1 in 2, Sprout 1 in 4, Shroomy 1 in 10, Nesty 1 in 26, Berry 1 in 100, Treebo 1 in 1,000. Rocks show "Needs 20 Strength" instead. | Kids read "1 in 100" better than 1%. Luck-adjusted odds belong to the stand. |
| D8 | HUD badge | A red count badge on the Index menu button when rewards are waiting. | Players otherwise never find unclaimed rewards. |
| D9 | Modifier / Golden tabs | **Not now.** Reserve the data shape (section 3) so they're additive later. | Neither system exists yet; empty tabs would confuse. |

## 2. Player flow
1. Player hatches a new Rok (or breaks a new rock kind). The Index button's badge shows the waiting count.
2. Click Index. The screen opens on the Roks page, with the first entry that has an unclaimed reward selected.
3. Click a card to see its details. Click **Claim** (or **Claim All**): server grants the cash and strength, the button turns into "Claimed!", the money delta plays, the badge count drops.
4. When every entry in a zone is found, the bar's reward icon lights up; claiming it (from Claim All or by clicking the icon) applies the permanent money boost and shows a toast.

## 3. Data (`src/server/Data/PlayerData.luau`)
Add to `Index`, with `Template` and `Validate` updated together (no `SchemaVersion` change; missing fields are filled from the template):

```text
Index = {
	Pets = { [petKey]: count },       -- exists
	Rocks = { [rockKey]: count },     -- new (D2)
	Claimed = {                       -- new
		Pets = { [petKey]: true },
		Rocks = { [rockKey]: true },
		Zones = { [pageKey .. ":" .. zoneKey]: true },
	},
}
```

Later, modifiers add `Index.Modifiers[modifier][petKey]` and their own `Claimed` pages, so nothing here has to move.

## 4. Code
- **`src/shared/Config/IndexConfig.luau`** (new): page order (`Roks`, `Rocks`), zone sections per page (Forest → `GeodeConfig.Geodes.Forest` pets; Forest → `Basic`, `Second`, `Third` rocks), reward table by rarity (D3), rock rewards, zone reward multiplier (D4), panel colours, preview camera settings.
- **`IndexRewards`** (new pure module next to `HatchOdds`): `Claimable(data)` returns the list of claimable entries and zones, `OneIn(geodeKey, petKey)` returns N. Shared so the server, the screen and the badge all count the same way.
- **`IndexService`** (new): owns `Index`. `RecordPet` (moved from PetService, which then calls it), `RecordRock` (called by RockService on a break), `Claim(player, page, key)`, `ClaimZone(player, page, zone)`, `ClaimAll(player)`, and `MoneyMultiplier(player)` for the zone bonus (read wherever chop payouts are multiplied). Validates every request: entry exists in config, found, not claimed.
- **Packets:** `ClaimIndex(page: String, key: String) → Boolean8`, `RateLimit(10, 1)`; `ClaimAllIndex() → NumberU8` (count claimed), `RateLimit(2, 1)`.
- **`Screens/Index.luau`** (new) + `Index = require(...)` in `UIController`. Builds sections and cards from `IndexConfig`, observes `{ "Index" }`, handles selection, claim buttons and the tab switch. Rock previews need a preview model per rock in `Assets/Models` (e.g. `Model_RockPreview_Basic`), fetched through `AssetRegistry`.
- **`MenuButtons.luau`**: show the badge on `IndexButton` from `IndexRewards.Claimable`.

## 5. Studio
- `StarterGui.Index` ScreenGui → `Panel` copied from the Geode Stand panel and recoloured (D1): `Tabs` (with a hidden `TabTemplate`), `HeaderBar`, `Sections` scrolling frame (hidden `SectionTemplate` holding `ZoneName`, `Grid` with `CardTemplate`, `Progress` bar + `ZoneReward`), `Detail` pane (`Preview`, `PetName`, `Rarity`, `Odds`, `Stat`, `Hatched`, `Rewards` with a hidden `RewardTemplate` tile, `ClaimButton`), `ClaimAll`.
- `MenuButtons.Container.IndexButton.Badge` (red square, black stroke, white count).
- Remind the user to save the place.

## 6. Build order (each step checked before the next)
1. **Config + data:** `IndexConfig`, new `Index` fields, `Validate`. Check: an existing profile loads with the new empty tables.
2. **IndexService + packets + rock tracking:** move `RecordPet`, add `RecordRock`, claims, zone bonus. Check from the server datamodel: break a rock, hatch through the dev grant, claim, double-claim rejected, Claim All count.
3. **Studio UI:** author the panel and badge. Check by screenshot with a temporary populated copy.
4. **Index screen:** populate, select, claim, tabs. Check in a playtest: silhouettes, "!" badges, claim flow, Secret rainbow.
5. **HUD badge.** Check the count drops as rewards are claimed.
6. **Vault + skill:** add the Index screen to the `studio-ui` skill, a `Systems/Index` vault note, and log the decisions in the Master Game Plan.

Out of scope: modifier and Golden tabs (D9), luck potions as index rewards, rewards for counts beyond the first find (e.g. "hatch 10 Bloky").
