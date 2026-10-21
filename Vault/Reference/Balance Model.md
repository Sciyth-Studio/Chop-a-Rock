---
description: The user's Excel balance model (Downloads/Chop_a_Rock_Balance_Model_v8.xlsx): what each tab checks, that Claude maintains it in this chat since 2026-10-19, and how to edit it without breaking it.
type: reference
---
# Balance model

The user's spreadsheet model of the economy. It was first built in claude.ai, and since 2026-10-19 the user keeps it with Claude Code ("I'll just stick with this chat"). Latest: `C:\Users\Admin\Downloads\Chop_a_Rock_Balance_Model_v8.xlsx`. Decisions made with it: [[Balance Pass Oct 18]].

## Tabs
- **Checks**: pass/fail per zone against the targets on Inputs. This is the summary to read first. 50 checks since v8; v8 passes 49, and the one failure (Snow has too little to save for) is expected until zone 6. Training targets are for idle players; the Board Slice check (columns E-F) only fails when a minigame player is too slow (see [[Training Minigame Board Slice]]).
- **Zone Model**: training time to each rebirth gate (columns Q-R: with Board Slice), chop and pet income, offline, walking, and the Index and weather multipliers.
- **Jackpots**: the max chop multiplier stack against the next stand's price.
- **Collection**: hatch odds after luck, the cost to finish each Roks page, hatch-and-sell worst cases, and pity.
- **Payback**: minutes of income to afford each aura, cannon, stand, geode and slot in each zone.
- **Inputs**: assumptions (yellow) and targets. Rows 88-99 (v8): Board Slice numbers from `TrainingMinigameConfig`, share of boards sliced (75%) and share of training time played (100%), giving its training mult. **Config**: values copied from the Luau configs.

## Keeping it true
- Config must match the game. To check it, require every config in Studio Edit mode, `HttpService:JSONEncode` them into `_G`, read the result back in chunks, and compare.
- As of v6: the Config arms block holds the aura tiers (auras replaced arms 2026-10-18, see [[Cannons And Auras Replace Arms]]). The old aura block holds the draft cannons. Since v7 the Forest Geode is $500; the tutorial's first geode is $150 (`TutorialConfig.GeodePrice`, see [[Tutorial]]), which the model doesn't cover.
- Snow Roks (and Cozy at $120M) are in the model but not in PetConfig yet.

## Editing gotchas
- Edit through Excel COM from PowerShell (`New-Object -ComObject Excel.Application`), not openpyxl. openpyxl drops the conditional formats that colour PASS/FAIL. Excel also recalculates, so values can be read back right away.
- In PowerShell 7, `$ws.Cells(r, c).Value2 = ...` can throw a cast error. Use `$ws.Range("A$r")` and cast values with `[double]` or `[string]`. In single-quoted strings, escape `'` as `''`.
- To add a row to a block other formulas read (aura tiers, Roks), insert it *inside* the block (above its last row) so Excel widens every range that reads it.
- Test options in a scratch copy first, then apply the chosen ones to a new version number, and add a "Changes in vN" list at the bottom of Read Me.
