---
description: 2026-10-29, approved and built (see Wild Geode) - Wild Geodes: every 4-6 min of chopping, the next rock you break had a geode hidden in it and opens straight into the hatch reveal; luck from the breaking chop, Uncommon or better, pity counts, no tell; the shop stays the main source.
type: decision
---
# Wild Geodes (2026-10-29)

**Status: approved and built 2026-10-29; how it works and where it lives: [[Wild Geode]]. Numbers are still drafts.**

A tester suggested dropping the [[Geode Shop]] and only spawning geodes in the zones (likely thinking of the Steal a Brainrot loop). The user is keeping the shop, because its cash sink, [[Cash Packs]], Lucky Geodes, pity and [[Auto Open]] all depend on it, and adding random geodes as a bonus. The game is meant to differ from that loop on purpose. [[Geode Fall]] already covers the shared, competitive version; Wild Geodes are the personal one.

## The user's calls (2026-10-29)
- Crack on the spot, not added to the geode stash.
- "The odds should be better than normal." Claude's draft floor: Uncommon or better.
- First built as a geode that rose in place of a broken rock and was chopped separately. The user then changed it: "the break just starts the opening animation, and the last chop is what the luck comes from. like the rock had a geode hidden in it."
- No tell: a geode rock looks like any other until it breaks. Claude suggested a faint sparkle once you start chopping it, so you'd try for a Perfect; the user chose pure surprise.

## How it plays
1. Every 4-6 minutes of active chopping (random each time), the next rock you break had a geode inside.
2. The break plays as usual and goes straight into the hatch reveal at that spot. No walk, no prompt, nothing to miss.
3. The breaking chop's quality sets the luck, the same as a crack at the pit: a Perfect or Master gives slightly better odds.

## Draft rules
| What | Draft | Why |
|---|---|---|
| Timer | 4-6 min of chopping time, gaps of 8 s or less | a surprise, not a schedule; idle players don't farm it; a variable-interval schedule in active time |
| Not with | a Rush Rock out or scheduled | so the two rewards don't land at once |
| Which geode | the zone of the rock you broke | you can already break that zone's weakest rock, which is the geode's gate |
| Odds | Uncommon or better (the zone's table with Common removed), luck applies | better than a bought geode (user), but below Rare+, which Geode Fall and the paid Lucky Geodes keep |
| Pity | counts like a bought geode | it should feel like progress, not a side roll |
| Full Backpack | no geode; the timer stays due | nothing to lose |
| Tutorial | off until the tutorial ends | |

## Odds with the Uncommon floor
From the current `GeodeConfig` weights (Common removed, the rest scaled up):

| Zone | Uncommon | Rare | Epic | Legendary | Secret | Legendary+ vs a bought geode |
|---|---|---|---|---|---|---|
| Forest | 62.5% | 25.0% | 9.75% | 2.5% | 0.25% | x2.5 |
| Desert | 58.8% | 25.9% | 11.8% | 3.2% | 0.35% | x2.35 |
| Jungle | 55.6% | 26.7% | 13.3% | 4.0% | 0.44% | x2.2 |
| Ocean | 50.0% | 28.0% | 16.0% | 5.2% | 0.8% | x2 |
| Snow | 45.5% | 29.1% | 18.2% | 6.4% | 0.91% | x1.8 |

## Value
A geode costs about 2-3 s of income ([[Balance Pass Oct 18]]), so one every ~5 min is worth almost nothing in cash. It's there for the surprise and to keep players chopping in the zones. With the Uncommon floor, one is worth about 2-2.5 bought geodes' chance at Legendary+, still small next to spam hatching. No [[Balance Model]] pass is needed unless the floor goes up to Rare.

## Still open
- Is Uncommon enough, and is about one every 5 min of chopping right? Both are drafts.

Related: [[Wild Geode]], [[Geode Shop]], [[Geode Fall]], [[Golden Rocks]], [[Rock Spawning]], [[Event Clock]]
