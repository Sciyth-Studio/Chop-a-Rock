# Geode pity: plan

Status: **built 2026-10-22, playtested by the user the same day** (see `Vault/Systems/Geode Shop.md` § Pity). Changes while building: the shop bars sit above the Rok grid, beside 2x Luck (there are only 16 px under the grid), and the reveal tag is a Gold "Guaranteed!" stamp tilted opposite the "New!" badge. Decisions approved 2026-10-22. The user picked every recommendation in section 1. The same day the balance model (v9) showed the first draft (1.5x, a guaranteed Legendary could be a Secret) made the Jungle and Snow Roks pages too quick, so the user moved to 2x with a Legendary guarantee that is always a Legendary (P1, P2). Every number marked *draft* lives in config and is checked in a playtest. The Shop bar and reveal tag are built in Studio and shown to the user before they're final.

## Read first
`AGENTS.md`, `Vault/Index.md`, `GeodeSystemPlan.md`, and the vault notes `Geode Shop`, `Geode Fall`, `Weather`, `Balance Model`, `Balance Pass Oct 18`, `Hatch Reveal Reference`, `Menu Panel Style`. Skills: `studio-ui`, `studio-playtest`.

## Why
Geode odds are flat, so bad luck has no floor. In the [[Balance Model]] (v8, Collection tab), half of players see the Forest Secret by 633 hatches, but 1 in 10 are still waiting at 2,102 and 1 in 100 at 4,203. Pity puts a ceiling on that without changing the odds most players see.

## What is already decided (do not change)
- `HatchOdds.Roll` rolls a crack at the player's luck (Rare+ scaled, Common/Uncommon shrink to fit, lucky share capped at 90%). `HatchOdds.RollAtLeast(geodeKey, rarity)` rolls only from a rarity and up, by weight. Geode Fall already uses it.
- The roll happens only on the server, at release, in `GeodeService/Cracking.Release`. The geode is taken and the Rok granted with no yield in between.
- The shop and reveal show base odds. Spam hatching is fine ([[Balance Pass Oct 18]]), and an auto-open gamepass is planned.
- Geodes, Roks and the Index survive rebirth.

## 1. Decisions (approved 2026-10-22, user picked each recommendation)

| # | Question | Decision | Why |
| --- | --- | --- | --- |
| P1 | What counts as a hit? | **Two counters per geode:** Legendary-or-better, and Secret. A Legendary or Secret resets the Legendary counter; a Secret resets both. **The Legendary guarantee always gives the geode's Legendary, never its Secret** (user, 2026-10-22, after v9); only the Secret counter gives Secrets. | Legendary is the chase Rok most players care about; Secret is the server-announced one. Epic+ would fire often and matter little. Letting the Legendary guarantee roll Secrets made Secrets ~50% more common over time. |
| P2 | Thresholds | **2x the expected hatches** at the model's luck for that zone (*draft*, balance model v9 Inputs B74; was 1.5x until v9 showed Jungle and Snow pages at 4.2 and 4.9 min, under the 5-minute minimum). See the table below. | About 1 in 7 players (e^-2 = 13.5%) ever reach a guarantee; the rest hit it first by luck. It rescues the unlucky tail and keeps every model check passing. |
| P3 | Per geode or shared? | **Per geode, kept through rebirth.** | A shared count would let players stack misses on $500 Forest geodes and spend them on a $36.7B Snow geode. Geodes and Roks already survive rebirth, so wiping progress toward a Rok would feel like a loss. |
| P4 | UI | **Geode Shop bar + reveal tag.** A slim progress bar per counter under each tab's Rok grid ("Legendary in 37", "Secret in 812"), and a "Guaranteed!" tag on the hatch reveal when pity gave the Rok. | Visible pity is the reason to keep cracking after a dry run, and the tag tells the player why they got it. |
| P5 | Geode Fall | **Ignored.** Fall hatches neither add to nor reset the counters. | Fall Roks are free bonus Roks (already Rare+). Pity is about geodes the player bought. |
| P6 | Weather | **Modifiers aren't hits.** A hit is about rarity only. A pity hatch still rolls `WeatherService:RollHatchModifier` as normal. | Modifiers are a separate layer on any rarity. |

### Thresholds (*draft*, `GeodeConfig.Geodes.<Zone>.Pity`)

Hatches with no hit before the next crack is guaranteed. Expected hatches are from the model's chance after luck (rebirths = zone - 1, average timing bonus).

| Geode | Legendary+ chance | Legendary at | Secret chance | Secret at |
| --- | --- | --- | --- | --- |
| Forest | 1.205% | **165** | 0.110% | **1,830** |
| Desert | 1.792% | **110** | 0.179% | **1,120** |
| Jungle | 2.590% | **75** | 0.259% | **780** |
| Ocean | 4.185% | **50** | 0.558% | **360** |
| Snow | 5.981% | **35** | 0.748% | **270** |

Legendary rounds to 5, Secret to 10 (model Collection rows 29-33 and 120-124). The Secret guarantee's gross worst-case cost is on Collection row 29-33 (`Pity cost`), about a third more than at 1.5x.

### Rules
- **Counting.** Each counter holds the cracks of that geode since the last hit at its rarity or better. Only real cracks count: a crack that took a geode and granted a Rok. Too-weak clinks, a full Backpack and failed grants don't count.
- **Firing.** Before rolling, if `Secret + 1 >= Secret threshold`, the crack rolls `RollAtLeast(geode, "Secret")`. Otherwise, if `Legendary + 1 >= Legendary threshold`, it gives a Legendary from that geode (by weight among its Legendaries, today one each), never a Secret. Otherwise the normal luck roll. The Secret check goes first, so when both are due the Secret wins and resets both.
- **After the roll.** Every counter whose rarity the hatched Rok reaches goes to 0; the rest go up by 1. So a normal-luck Legendary also resets the Legendary counter.
- **Luck doesn't move the thresholds.** Luckier players simply hit before pity more often.
- **The tutorial's $150 geode** is a Forest crack and counts.
- **Admin:** "Next Hatch: <Rarity>" counts like a real crack (its result resets or adds), so the reset can be tested. "Grant Rok" isn't a crack and doesn't count.
- **Shown odds don't change.** The shop and reveal keep showing base odds; the bar is the only pity display.
- **New geodes** (a zone added later) get `Pity` thresholds in their `GeodeConfig` entry; a geode with no `Pity` entry has no pity.

## 2. Player flow
1. Geode Shop, any tab: under the Rok grid, two slim bars. "Legendary in 37" fills toward its threshold in the Legendary colour; "Secret in 812" in the Secret colour with the rainbow gradient. Both show on tabs the player can't reach yet (at 0, "Legendary in 165"), the same as the odds do.
2. A normal crack: no change to the reveal. The bars move the next time the shop opens (or live, if it's open).
3. A pity crack: the reveal plays as usual (the geode grows to the Rok's rarity) and the card shows a small "Guaranteed!" tag under the rarity, in the rarity colour. Secret announcements still go to the server.

## 3. Architecture

### Config (`src/shared/Config/GeodeConfig.luau`)
- Each geode gets `Pity: { [string]: number }?`, rarity key → threshold, for example `Pity = { Legendary = 165, Secret = 1830 }`. The type gains `Pity` as optional.
- `GeodeConfig.PityRarities = { "Secret", "Legendary" }`: the check order (highest first).

### Shared pure module
- `src/shared/HatchPity.luau`, beside `HatchOdds`:
  - `HatchPity.Due(geodeKey, counts) → string?`: the rarity whose guarantee fires on this crack (`count + 1 >= threshold`), checked in `PityRarities` order, else nil.
  - `HatchPity.After(geodeKey, counts, hatchedRarity) → { [string]: number }`: the new counters (reached → 0, others + 1).
  - `HatchPity.Left(geodeKey, counts, rarity) → number?`: cracks left until the guarantee, for the shop bar.
  Pure, so both the server and the shop use the same maths.

### Player data (`src/server/Data/PlayerData.luau`)
- `Pity: { [string]: { [string]: number } }`: geode key → rarity → misses. Template `{}`. Update `Data`, `Template` and `Validate` together (every leaf a natural number); `Reconcile` fills old profiles with `{}`, so no migrate and no schema bump. Old players start at 0.
- Not touched by rebirth. `DataService:ResetData` clears it (it rebuilds from the template). Add `Pity` to admin snapshots.

### Server (`GeodeService/Cracking.luau`)
- In `Release`, after `forcedPet`: when nothing was forced, `HatchPity.Due` picks the rarity; if due, roll `HatchOdds.RollRarity(random, geodeKey, due)` (new: by weight among that geode's Roks of exactly that rarity) instead of `HatchOdds.Roll`. Keep `isPity = due ~= nil`.
- In the same frame as the geode decrement and `PetService:Grant`, write `{ "Pity", geodeKey }` with `HatchPity.After(...)`. On a failed grant the counters are left as they were (the geode is refunded already).
- The print line gains `pity=<rarity|none>`.
- `GeodeFallService` doesn't touch `Pity` (P5).

### Networking (`Packets.luau`)
- `GeodeHatched` gains a last `Boolean8` field `IsPity`. `Cracking` sends `isPity`; `GeodeFallService` sends false. `HatchController` passes it on to `HatchReveal`.
- Counters reach the shop through Replica, like `Geodes`. No new packet.

### Client
- `Screens/GeodeStand.luau`: per tab, read `data.Pity[geodeKey]` and `HatchPity.Left`, set each bar's fill and text; listen for `Pity` changes while open. Hide a bar for a geode with no threshold for that rarity.
- `Screens/HatchReveal.luau`: show `Content.Body.Pity` ("Guaranteed!") when `IsPity`, coloured like the rarity label.

### Studio (built with the `studio-ui` skill, house text style)
- `StarterGui.GeodeStand.Panel.Pity`: a frame under the grid, above the buy buttons, with `Legendary` and `Secret` rows (`Fill`, `Label`). Room may need the buy buttons to move down; check `GeodeStandConfig.ButtonCenterOffsetPixels`.
- `StarterGui.HatchReveal.Content.Body.Pity`: a copy of `Modifier` (y below it), text "Guaranteed!".

### Admin
- "Pity: Next Due" (choice Legendary / Secret): sets the counter of the geode `GeodeOrder.ForStrength` picks to `threshold - 1`, so the next crack is a pity crack. Alias `pity`.

### Balance model
- Done 2026-10-22: `Downloads/Chop_a_Rock_Balance_Model_v9.xlsx`. Collection rows 114-141 hold both guarantees and their effect; avg sell (rows 21-25, 41-45) and the page cost (helper columns N-R) include pity; Inputs B74 = 2, B80 turns pity on/off.

## 4. Build order (each step ends checkable)
1. **Config + `HatchPity` + `HatchOdds.RollRarity`:** thresholds, `PityRarities`, the functions. Check in Studio by value: `Due` fires at exactly 164 misses for the Forest Legendary, `RollRarity(Forest, "Legendary")` only ever gives Berry, Secret beats Legendary when both are due, `After` resets the right counters for each rarity.
2. **Data:** `Pity` field, `Validate`, snapshots. Check: an old profile loads with `Pity = {}`; a bad value (negative, string) fails validation the same way `Geodes` does.
3. **Cracking + packet:** pity roll, counter write, `IsPity`. Check with the admin command: next crack is a pity Legendary+, counters reset; a forced Secret resets both; a too-weak clink and a full Backpack leave counters alone; 300 normal Forest cracks at luck 1 never pass 164 misses. Geode Fall hatch leaves counters alone.
4. **Shop bar:** build in Studio, show the user the look, then wire `GeodeStand`. Check: each tab shows its own counts, the bars move live after a crack, unreachable tabs show full thresholds.
5. **Reveal tag:** "Guaranteed!" on a pity crack only. The user looks at it.
6. **Vault** (balance model v9 already done): a `Systems/Geode Pity` note (or a section in [[Geode Shop]]), and remove the To Do line.
7. `./scripts/check.ps1` passes. The user playtests.

## 5. Risks and gotchas
- **No re-roll:** the pity check and the counter write happen in the release handler, in the same frame as the geode decrement and grant. Leaving a crack never touches the counters.
- **Auto-open gamepass** (planned): it cracks through the same `Release`, so pity works with no extra code. Fast auto-open makes the Snow Legendary guarantee (35) come often; that is by design and inside 2x expected.
- **Balance check (model v9, 2026-10-22):** 49 of 50 checks pass, the same as v8 (Snow's expected "too little to buy"). At the model's luck pity makes Legendary+ hatches about 16-18% more common over time and Secrets about 15% more. Hatches to the first Secret: Forest 913 → 790, Desert 558 → 483, Jungle 386 → 335, Ocean 179 → 155, Snow 134 → 116. Roks page time: 23.8 → 20.4, 12.5 → 10.7, 6.5 → 5.5, 10.1 → 8.7, 7.4 → 6.4 min (minimum 5). Hatch-and-sell worst case (10 rebirths, worst weather): 69 / 82 / 95 / 42 / 45% → 70 / 83 / 96 / 43 / 46%. The Jungle is the closest on both (5.5 min, 96%); a later Jungle odds or price change should re-run the model. The first draft (1.5x, Legendary guarantee could be a Secret) failed the Jungle and Snow page checks (4.2 / 4.9 min) and put the Jungle at 98%.
- **Thresholds are fixed numbers** from the model's luck assumptions. If geode odds or luck change, re-run the model and update `Pity`.
- **Policy:** geodes are cash items, and cash packs only buy cash, so pity changes no Robux odds. If a Robux geode is ever sold, its odds disclosure has to mention pity.

## Out of scope
A soft pity (odds ramping before the guarantee), pity on Geode Fall, a "new Rok" guarantee from the Index, and pity for any later Robux or event geodes.
