# New Loop Plan: eggs come out of rocks

Status: v3, built 2026-11-06 (not playtested, not committed; see the vault note Eggs From Rocks for what is left). Numbers are drafts until the Balance Model pass.

## The user's answers (2026-11-06)
1. **Chop skill shifts the shuffle's odds**, for both the egg type and the luck.
2. **Egg type:** one of the zone's two looks is the **rare egg**, about **1 in 5** to appear, with **better odds** than the common egg (its own odds table, draft below).
3. **Rock cash** goes through the Balance Model before anything changes. Until then it stays as it is.
4. **Losing a fight:** the egg is lost unless you retry. Everyone gets **1 free retry per 24 h**; after that a retry is a **developer product**.
5. **Still carried home** and hatched on a pad.

## Why
Both outside testers on 2026-11-05 found the same gap ([[Playtest Feedback Nov 5]]): eggs are free pickups gated only by Strength, so chopping only gives cash, and Pets give cash too. The successful dev's fix: "put the eggs in the rocks".

v2 (2026-11-06) follows the user's Discord talk with a third tester (scándi). Picking up a loose egg "did not make that much sense". Instead the egg flies out of the rock as a black egg and shuffles, then you grab it and have to fight for it. The user's calls: the fight uses the **same timing minigame as chopping** (one minigame is easier for ages 6-12, adds time pressure, and timing-based fights haven't been done the way spam clicking and running have), and there is **no running away**, so no speed training ("keep one").

## The loop
1. **Train** at your base for Strength. Unchanged; still the only stat you train.
2. **Break a rock** with the chop minigame.
3. **An egg flies out** of the rock as a black silhouette.
4. **It shuffles** through egg types and luck multipliers, like a slot reel, and lands on one.
5. **Grab it.** The zone's enemy charges you.
6. **Fight with the chop bar.** Land enough Good-or-better chops before the timer runs out.
7. **Win, take it home, place it on a pad, open it.**
8. **Pets earn money.** Money buys auras and training stands, so you get stronger and chop bigger rocks.

## Rules

### 1. The egg comes out of the rock
- Every broken rock launches one egg: black, spinning, landing a few studs from the rock on your side. It's yours only, so other players can't take it (ages 6-12; same rule as Geode Fall).
- Recommended: every rock drops one (no drop chance). Kids can read it, and the fight and pads already limit supply.

### 2. The shuffle
- While it sits there (about 2 s, draft), the silhouette flickers through the zone's egg looks while the luck number above it **counts up through the hundredths** (user, 2026-11-06): x1.00, x1.01, x1.02 ... fast at first, slowing as it nears the final value, with a tick sound per step that rises in pitch. It stops on the rolled value (e.g. x1.73) with a pop: the egg takes its colours and the multiplier locks. Counts that would take too long skip ahead in bigger steps early on, so it always lands in about 2 s.
- Rolled on the server when the rock breaks; the shuffle is presentation only, so no fake near misses (same rule as the stepped hatch reveal idea in To Do).
- **Type (user, 2026-11-06):** the zone's second look (`ForestB` and so on) becomes the **rare egg**, about 1 in 5 (draft 20% base). It has its own odds table: Common and Uncommon weights halved, Rare and up doubled (draft; the Balance Model sets it). The first look stays the zone's normal egg. Players see two names, e.g. "Mossy Egg" and "Rare Mushroom Egg" (names to confirm).
- **Luck is a number to the hundredth, not fixed tiers:** rolled between x1.00 and x3.00 (draft range) on a curve where low values are common: median about x1.25, x2.00 or more about 1 in 8, x2.75 or more about 1 in 40 (drafts).
- **Chop skill shifts both rolls** (user, 2026-11-06): the average quality of your chops on that rock moves the luck curve up and raises the rare egg chance. All-Perfect chops make the rare egg about twice as likely (draft 20% to 40%) and lift the median luck to about x1.75; a Master on the rock sets the floor at x2.00. The count-up shows the result.
- The tutorial's first rock is forced Perfect and its egg lands on x2.00 so the shuffle teaches itself.

### 3. The fight
- Grabbing the egg (prompt or walking into it) calls `EnemyService:RequestFight`, as zone eggs do today. The zone's enemy charges in, and the existing intro banner, camera shots, win and lose sequences stay.
- **Combat is the chop bar** (`ChopBar` screen, `ChopZones` bands), not spam clicking. Each enemy has hit points measured in chops: **Good = 1 hit, Great = 2, Perfect = 3, Master = finishes it** (drafts). Bad and OK miss.
- **Timer:** a countdown bar (draft 12 s) above the chop bar. Clear the enemy's hits before it runs out to win.
- **Strength still matters:** like rocks, higher Strength for the zone widens the good bands (`ChopZones` strength ratio), so the fight gets easier as you grow. Far enough above the zone, the enemy still runs away (the existing flee rule), and the egg is free.
- **Win:** the egg goes into your hotbar.
- **Lose (user, 2026-11-06):** you're launched (existing) and a "Retry?" card appears over the egg. Everyone has **1 free retry per 24 h** (saved as the time it was last used, `data.FreeRetryAt`). After that, a retry is a **developer product** ("Retry Fight", price draft 9 R$, the user sets it). Retrying restarts the fight with the enemy at full hits. Decline, or wait 15 s (draft), and the egg shatters and is gone. While the Robux prompt is open the timer pauses, as Skip Hatch does ([[Monetization Compliance]]). The tutorial's first fight can't be lost.
- One minigame for everything: rocks, Golden and Diamond Rocks, and the enemy fight. Kids learn one skill.

### 4. Taking it home and opening it
- Unchanged: eggs stack in the hotbar, the Base teleport takes you home, you place them on the 8 hatch pads, timers and Skip Wait stay.
- **Each egg keeps its luck.** Saved as a list per egg key (`data.EggLuck[key]`) beside today's counts in `data.Geodes`, so a stack is still one hotbar slot. Placing uses the luckiest egg first. The hotbar, pad label and reveal show "x1.73".
- Opening multiplies the player's normal luck by the egg's (`HatchOdds` still caps the lucky share).

### 5. Money
- Pets pay $/s (unchanged).
- Rock cash goes through the Balance Model (user, 2026-11-06): compare keeping it (A) with cutting it to about 25% (B). Unchanged in code until then.

### 6. What goes, what stays
- **Goes:** free zone eggs (`ZoneGeodeService`, `ZoneGeodeController`, ring spawns), the spam-click combat (`EnemyFight` click input, `HealthClicksAtGate`, `ClicksPerSecond`).
- **Stays:** zone enemies with their charge, banner, launch and flee; Geode Fall; Lucky Eggs; the Starter Egg; the Index; Skip Wait; hatch pads; Pet sizes.

### 7. Tutorial
1. Train: "Break the boards!" (unchanged)
2. Chop: "Chop a rock!" 1 rock (was 3), forced Perfect, egg lands on x2.00
3. GetGeode: "Grab your egg!" A gentle first fight: forced win after any 2 hits, with the Good band spotlit like the first chop
4. Place: "Take it home!" (Base teleport), then "Place your egg!"
5. Open: unchanged; the first egg still hatches the Huge Shroomy

## Risks to check in the Balance Model
- **Supply vs pads:** a rock plus a fight every ~25-40 s still outpaces 8 pads with 30 s to 27 min hatches from the Jungle on. Compare shorter hatches, more pads, or selling eggs.
- **Pets share of income:** the luck roll raises Pet income. Volcano and Golem Ruins already fail "pets too strong" in v13.
- **Rock cash A vs B.**
- **Rare egg:** its share (20% base, up to 40% with Perfect chops) and its better odds both raise Pet income.
- **Retry product:** how often a player loses a fight at the zone's weakest-rock Strength (sets how often the free retry runs out).

## Build steps (after approval)
1. `RockService`: keep per-rock chop scores; on break, roll the egg look and luck value to the hundredth (curve shifted by the score) and hand them to the drop.
2. `EggDropService` (new, server data per player like zone eggs today): spawn the dropped egg, take request, fight hand-off, lose/expire timeout, bag-full check.
3. Client egg drop: launch arc out of the rock, black silhouette, shuffle reel, land pop, label. Reuse `ZoneGeodeController` drawing.
4. `EnemyService` + `EnemyController`: replace click combat with chop-bar rounds (server judges quality the way `RockService` does), hit points in chops, countdown. The `EnemyFight` screen keeps its health bar and gets the timer.
5. `PlayerData`: `EggLuck` lists, `HatchPads[i].Luck` and `FreeRetryAt`, migration (existing eggs x1).
6. `GeodeService` + `GeodeConfig`: the second look per zone gets its own rare odds table; place the luckiest egg first, multiply luck on open; hotbar, pad and reveal show it.
7. Retry: the lose card, the free daily retry, the "Retry Fight" developer product (`MonetizationConfig`, `PurchaseService/Products`; the user creates the product and gives the id).
8. Remove free zone eggs and click combat (Studio UI backups in `UIBackup`).
9. Tutorial text, 1-rock chop step, gentle first fight.
10. Balance Model v14: egg supply, rare egg share and odds, luck curve, fight time, rock cash A vs B, pad pressure.
11. Playtest, then commit.

## Still open (not blocking the build)
- Rare egg names per zone, and whether it gets a glow or other look on top of its model.
- Retry Fight price (draft 9 R$) and product id.
- Rock cash A or B, after the Balance Model.
