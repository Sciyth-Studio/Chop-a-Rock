---
description: The user's Excel balance model (Downloads/Chop_a_Rock_Balance_Model_v18.xlsx, world boss cash since v18, playtime and retention checks since v17, New Loop tab since 2026-11-03, Starter Egg and King Rex since v13, no rebirth since v14, 20-stand ladder since v15, base upgrades since v16): what each tab checks, that Claude maintains it in this chat since 2026-10-19, and how to edit it without breaking it.
type: reference
---
# Balance model

The user's spreadsheet model of the economy. It was first built in claude.ai, and since 2026-10-19 the user keeps it with Claude Code ("I'll just stick with this chat"). Latest: `C:\Users\Admin\Downloads\Chop_a_Rock_Balance_Model_v16.xlsx` (2026-11-09: base upgrades, see the last section). v15: `Chop_a_Rock_Balance_Model_v15_final.xlsx` (2026-11-09: the 20-stand ladder, see below; the plain `_v15.xlsx` next to it is a stale copy of v14 that Excel had locked). v14 (2026-11-09: rebirth removed). v13 (2026-11-05: New Loop rows 51-55 and columns BN-BV add the [[Starter Egg]] and King Rex, see below). v12 (2026-11-03: new tab **New Loop** models [[Zone Geodes And Enemies]] for all 10 zones, with per-zone hatch time and Pet income columns on its far right; the other tabs still describe the old shop loop and weren't changed). v11 (2026-10-29: new tab **Zones 6-10** balances the world 1 finish from `World1Plan.md` with the same formulas, one row per zone; row 6 is Snow as a check and matches the other tabs; every check passes for zones 6-10; the main tabs still cover zones 1-5. v10, 2026-10-28: aura tiers 6-15). To re-run it, `scratchpad` scripts aren't kept: edit the yellow levers on the tab directly. Decisions made with it: [[Balance Pass Oct 18]].

## Tabs
- **Checks**: pass/fail per zone against the targets on Inputs. This is the summary to read first. 50 checks since v8; v9 passes 49, and the one failure (Snow has too little to save for) is expected until zone 6. Training targets are for idle players; the Board Slice check (columns E-F) only fails when a minigame player is too slow (see [[Training Minigame Board Slice]]).
- **Zone Model** (old loop, still has rebirth): training time to each rebirth gate (columns Q-R: with Board Slice), chop and pet income, offline, walking, and the Index and weather multipliers.
- **Jackpots**: the max chop multiplier stack against the next stand's price.
- **Collection**: hatch odds after luck, the cost to finish each Pets page, hatch-and-sell worst cases, and pity. Since v9 (2026-10-22) rows 114-141 model the planned geode pity (`GeodePitySystemPlan.md`): Legendary and Secret guarantees at Inputs B74 (2x) expected hatches, fed into avg sell and the page cost (helper columns N-R); Inputs B80 turns pity off to compare.
- **Payback**: minutes of income to afford each aura, cannon, stand, geode and slot in each zone.
- **Inputs**: assumptions (yellow) and targets. Rows 88-99 (v8): Board Slice numbers from `TrainingMinigameConfig`, share of boards sliced (75%) and share of training time played (100%), giving its training mult. **Config**: values copied from the Luau configs.

## Keeping it true
- Config must match the game. To check it, require every config in Studio Edit mode, `HttpService:JSONEncode` them into `_G`, read the result back in chunks, and compare.
- As of v6: the Config arms block holds the aura tiers (auras replaced arms 2026-10-18, see [[Cannons And Auras Replace Arms]]). The old aura block holds the draft cannons. Since v7 the Forest Geode is $500; the tutorial's first geode is $150 (`TutorialConfig.GeodePrice`, see [[Tutorial]]), which the model doesn't cover.
- Snow Pets (and Cozy at $120M) are in the model but not in PetConfig yet.

## Editing gotchas
- Edit through Excel COM from PowerShell (`New-Object -ComObject Excel.Application`), not openpyxl. openpyxl drops the conditional formats that colour PASS/FAIL. Excel also recalculates, so values can be read back right away.
- In PowerShell 7, `$ws.Cells(r, c).Value2 = ...` can throw a cast error. Use `$ws.Range("A$r")` and cast values with `[double]` or `[string]`. In single-quoted strings, escape `'` as `''`.
- To add a row to a block other formulas read (aura tiers, Pets), insert it *inside* the block (above its last row) so Excel widens every range that reads it.
- Test options in a scratch copy first, then apply the chosen ones to a new version number, and add a "Changes in vN" list at the bottom of Read Me.

## Starter Egg and King Rex (v13, 2026-11-05)
- **Starter Egg** holds one hatch pad for 15 min from about 2 min in (lever B52, an assumption). Hatching runs on 7.9 / 7.0 / 7.4 pads in the Forest, Desert and Jungle (column BP feeds AC). The Pets share barely moves (Desert 36.6% to 34.5%), and the checks stay at 33 / 51.
- **Capybara** ($100/s flat) opens in the Jungle, where every Pet already beats it, so it adds nothing to income (column BR). It's a reward for staying, not an earner.
- **King Rex** (1,499 R$, 3x your best Pet) is a buyers-only scenario that isn't in the checks. With it, the Pets share is 40-49% in zones 1-3 and 58-66% from the Ocean on, over the 50% target. A lower multiplier or a cap would bring it back under.
- Volcano and Golem Ruins already fail "pets too strong" without King Rex (51.2%, 53.1%).

## No rebirth (v14, 2026-11-09)
See [[Rebirth Removed]]. On New Loop: B10 (rebirth cash mult.) is 0, so column K is x1; column F (training in zone) counts from the last zone's top rock (factor 1 - 1/125, was 1.24 for three climbs from 0). Stand prices cut on Config E44:E47 (Steel $4M, Vault $250M, Energy Core $16B, Cosmic $1.1T) and the zone 7-10 drafts on Zones 6-10 AJ6:AJ10 ($1.1T, $75T, $5Q, $300Q, $20Qi). Checks 35 / 51 (33 in v13). Zones run about 20% shorter (231 min to the top of Golem Ruins, was 288). The old-loop tabs (Checks, Zone Model, Payback) were not changed. The 20-stand ladder went in at v15.

## 20-stand ladder (v15, 2026-11-09)
See [[Stand Ladder Models]]. Config's stand block is 20 rows (A42:F61), matching `TrainingConfig`. Column C is the zone the stand is for, and column F (Robux) is blank because no stand has a Robux price in code. The block was grown by inserting rows inside it, so the `INDEX(Config!$D$42:$D$61, ...)` ranges grew and the Roks table moved down 14 rows.
- New Loop D blends the zone's two stands: the first covers the climb to 25x the last zone's top, the second the rest. Formula: `1/(f/first + (1-f)/second)`, f = 24/124. The Forest is f = 1 (Wood only): Bronze ($8K) is about all the cash a 2-minute Forest pays, so it is bought at the Forest's top. With Bronze mid-Forest (f = 0.2) the Forest shrank to 1.3 min and failed pets too weak (22.9%); a Forest Pet income mult. of 3 would also fix that, shorter Forest hatch times would not (15 s: 28.2%).
- New Loop BB/BD (offline and next stand) and Zones 6-10 AI:AJ read the first stand of the next zone (`2*zone+1`). New info columns BW:BX: the mid-zone stand and its minutes, estimated at a quarter of end-of-zone income (Forest: full end income).
- Result: 35 / 51, same as v14, same fails. Training per zone is within about 10% of v14 (Forest 1.1, Golem Ruins 24.8 was 27.9); about 227 min to the top of Golem Ruins (231 in v14). Next stand: 2.6-3.3 min of income everywhere. Mid-zone stands: 2.7-3.4 min (Bronze 0.7 at the Forest's top). Pets share passes in every zone (30.1% Forest to 46.4% Golem Ruins).
- The old-loop tabs (Zone Model stand columns, Payback rows 21-25) read Config rows by position, so they now show the first ladder stands. They are not in the checks.
- Excel COM from PowerShell: cast with `[string]`/`[double]` when a value comes out of a nested array (`Range.Value2 = $s[0]` threw "cannot cast String to Int32"). `Workbooks.Open` sometimes returns null the first time; retry it in a loop. Work on a scratchpad copy and copy it into Downloads at the end: a file copied inside Downloads opened read-only and `Save()` silently did nothing, and a failed COM run leaves a hidden EXCEL.EXE holding the file.

## Base upgrades (v16, 2026-11-09)
See [[Base Upgrades]]. New Loop BY:CD, rows 27-36: BY base level at the end of each zone (Forest 1, Desert 2 ... Bamboo Forest 8, Volcano and Golem Ruins 8), BZ earning Pets = B9 + level - 1, CA hatch mult. = 1 - 0.05 x (level - 1), CB the upgrade price bought in that zone, CC its minutes at a quarter of end-of-zone income, CD a proposed Pet income mult. AE:AJ and BQ read `$BZ` instead of `$B$9`; AC and AR use `BL*$CA`. With the base levels alone it fell to 29 / 51 (Pets too strong Swamp to Golem Ruins). The user picked the trim: BM32:BM36 are now 0.8 / 0.6 / 0.55 / 0.55 / 0.5 (old values in CD32:CD36), matching `PetConfig`, giving 34 / 51 with every Pets-share check passing (the remaining difference from v15 is the old-lineup reference column AW). Read Me rows 104-111 list the changes.

## Playtime and retention checks (v17, 2026-11-10)
See [[Target 90th Percentile]]. `Chop_a_Rock_Balance_Model_v17.xlsx`. Levers on Inputs rows 101-108: target playtime 30.7 min, first-session window 45 min, max minutes between goals 5 (first session) / 8 (later), 45 min a day for a retained player, 7 days of content, offline payout at least 0.25 of the next stand.
- New Loop CE:CM: goals per zone = stands + auras (CE, typed: Forest 2, Desert 3, then 1) + base upgrade + the zone unlock. Rock unlocks inside a zone are left out: rocks step x5, so two of three open in the zone's first fifth. Cannons are free zone travel, not purchases. CK goal pacing, CL return hook (reads BB), CM the day each zone is finished.
- New Loop H13:H15: where a 30.7-min first session ends (Ocean), World 1 in days (5.0), day-7 content check. H11 counts PASS in A27:CM36 plus H7 and H15, out of 72.
- Result: 52 / 72. Fails: Volcano (10.2 min between goals) and Golem Ruins (16.6) pacing, and day-7 content (World 1 is 227 min, 5.0 days at 45 min a day; it passes at 32 min a day or less). Every return hook passes (0.5-0.9 of a stand).

## World boss cash (v18, 2026-11-10)
`Chop_a_Rock_Balance_Model_v18.xlsx`, for `WorldBossPlan.md` ([[World Boss Research]]). Inputs rows 110-115: boss cash 1.25x chopping rocks (user's pick), 40% of play time in boss fights (assumption), 70% of boss rounds are chops, 15% downtime, max income boost 15%.
- New Loop CN:CR: boss $/s = 1.25 x M (chop $/s, full time); CO income boost over a session = 0.4 x (boss - chop) ÷ total; CP next stand minutes with it; CQ check (boost ≤ 15% and next stand ≥ 1 min); CR a 9-min fight's cash in minutes of income. H16: pay per boss chop round = 1.25 ÷ (0.7 x 0.85) = 2.10x a rock round, the number the boss config needs. H11 counts A27:CR36, out of 82.
- Result: 62 / 82, every boss check passes. Income boost 5-11% (Forest 10.6% down to about 5% late, because Pets earn a bigger share there); next stand 2.2-3.0 min (was 2.4-3.2). A 9-min fight pays 6-12 min of income.
