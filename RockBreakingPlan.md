# Rock breaking: plan

Status: **approved 2026-10-30. Build steps 3 (zone scale config: rocks, Diamond rock, snap, chop camera) and 4 (rescale the map) done 2026-10-30, not playtested; resistance and overkill not built.** The user accepted D1-D10 and answered the open questions (section 2). Every number marked *draft* is a placeholder for playtesting and will live in config.

## Why
An experienced dev's feedback: breaking rock, the core fantasy, isn't potent enough. Today breaking already has a timing chop, quality tiers up to Master, live splitting on Perfect hits, Rush and Diamond rocks. But being strong is mostly told through numbers:
- A rock's hits before the break look the same. Only the last one changes the rock.
- Outgrowing a rock makes it duller. Easy rocks are even left out of Hot Streak on purpose.
- Rocks barely grow. The biggest regular rock is Snow Third at 27.7 wide and 18 tall, against a 5-stud character.

The user picked three fixes (2026-10-30): **scale**, **visible resistance** and **overkill shatter**.

**Scale, as the user set it (2026-10-30):** rocks keep their boulder shapes and simply get bigger zone after zone, and zones grow with them. Leaning on the cannon more is fine, and aura walk speed rises with progress anyway. The scale **resets at the start of each new world**, so world 2 starts at forest size again. An earlier draft made rocks into tall pillars to keep zones small; the user turned that down.

## Read first
`AGENTS.md`, `Vault/Index.md`, `Chop_a_Rock_Master_Game_Plan.txt` (§02 loop, §06 world, §07 economy), `World1Plan.md`, the vault notes `Rock Spawning`, `Chop Effects`, `Hot Streak`, `Diamond Rock`, `Zone Line`, `Slice Test`, `Rocks Look Like Boulders`, `Cannon Shop`, `Auras`, and `RockSpawnSystemPlan.md`.

## What's there now (measured 2026-10-30)
- Ten zones in one straight line on +Z, each 220 x 168, with 36-stud terraces either side. Lobby to the Ruins is about 1,700 studs; the boss arena (300 x 300) is after the Ruins. Code has no zone coordinates in it.
- 25 rocks per player per zone, in three strips (weakest near the entrance). `RockConfig` has rocks for the first five zones only.
- Rock sizes (W x H x D): Forest 7.0 x 4.2 x 6.0 to 18.2 x 12.0 x 16.7; Snow 9.6 x 7.9 x 8.8 to 27.7 x 18.0 x 24.8. Rock width already grows about 11% per zone.
- A rock takes about 4 hits at its minimum strength (`ChopConfig.HitsAtMinStrength`), fewer as you get stronger.
- Walk speed 25. Auras add +2 to +28 (up to 53, about 2.1x).

## 1. Decisions to approve

| # | Question | Recommendation | Why |
| --- | --- | --- | --- |
| D1 | How fast do things grow? | One **zone scale** per zone: **x1.15** per zone (*draft*), so zone n is 1.15^(n-1): Forest 1.0, Desert 1.15, Jungle 1.32, Ocean 1.52, Snow 1.75, Swamp 2.01, Savanna 2.31, Bamboo 2.66, Volcano 3.06, Ruins 3.52. | One number to tune. By the Ruins everything is 3.5x the forest, so the Ruins' biggest rock is about 64 wide and 42 tall next to the same 5-stud character. |
| D2 | What grows? | **Everything in the zone**: rocks, floor, terraces (height too), decor, spawn area, entrance sign. The character doesn't. | Each zone stays the same kind of scene, only bigger, so the player feels smaller and stronger. Rock counts and spacing stay the same. |
| D3 | Rock shapes | Rocks **keep their boulder shapes**, made at forest size and scaled by the zone scale. Each zone's First / Second / Third keep about the same size ratio as now (about 1 : 1.6 : 2.6). | No pillars (user). Rocks get their look per zone from colour, props and formations, as now. |
| D4 | Zone sizes and the walk | Ruins zone about **775 x 590** (*draft*, from D1). The whole line goes from about 1,700 to about **3,400 studs**. Walking it takes about the same time at max aura speed (53) as the current line takes at base speed. | Auras roughly cancel the extra length. Walking a zone stays about 7-11 s. The cannon becomes the normal way to reach far zones, which is fine (user). |
| D5 | New worlds | The zone scale **resets to 1.0** at the start of each world (*draft*: same x1.15 growth inside it). | User's call. Keeps each world's numbers sane and gives every world the same "it keeps getting bigger" arc. |
| D6 | Rock counts | Keep **25** per zone everywhere. | D2 scales the floor with the rocks, so they fit the same. |
| D7 | Visible resistance | Every hit changes the rock: a **shudder**, **chunks knocked off** and the rock **stepping down** about 10-15% in size (*draft*). The final hit gets a **hit-stop** (a ~0.08 s freeze on impact, *draft*) and a camera kick, scaled with rock size. | Players see the rock losing. On a 60-stud boulder, chunks the size of the player falling off sell the scale. |
| D8 | Overkill shatter | When your strength is at least **10x** a rock's requirement (*draft*), the chop is an **overkill**: no timing hold (one quick tap), the rock **blows apart** with more pieces flung further, and a **shockwave** breaks your other rocks within a radius you also overkill (*draft* 15 studs x zone scale). Each pays its normal amount. | Outgrowing a zone becomes the best feeling instead of the worst. With the strips, walking back through the front of a zone becomes a stage for showing off. Weak rocks pay little, so the cash effect is small. |
| D9 | Hot Streak and overkill | Overkill chops still don't build the streak (as now), but they **keep it alive**, like Diamond Rock chops. | Keeps streaks from being farmed on weak rocks while not punishing the walk to stronger rocks. |
| D10 | Cash balance | Payouts don't change because of this plan. | This plan is about feel, not the economy. |

## 2. Answers (user, 2026-10-30)
- **Chop camera and snap:** they scale with the rock, like the effects already do (`ChopConfig.ReferenceRockSize`).
- **Boss arena:** scaled to at least the Ruins' zone scale.
- **Debris:** chunks knocked off by D7 stay on the ground **until the rock you're working on is destroyed**, then clear with it.
- **Streaming:** whether far zones load is a performance call for the playtest. The user may add a camera pan over the zones right after the first intro cutscene, then back into the player's head (not in this plan; see [[Intro Cutscene]]).
- **Diamond Rock and Rush rocks** (not raised by the user; recommendation stands): they scale with the zone like normal rocks, and can't be overkilled.

## 3. Build order
1. **Visible resistance (D7)** on the existing rocks first: shudder, chunks, step-down, hit-stop. Fastest way to test whether breaking feels stronger.
2. **Overkill shatter (D8, D9):** server rule, quick tap, shockwave, bigger burst.
3. **Zone scale config (D1):** one `ZoneScale` per zone; rock templates, effects, chop camera and snap read it.
4. **Rescale the map (D2, D4):** in Studio, zone by zone from the Desert on: floors, terraces, decor, spawn areas, signs, teleport and cannon markers, admin warps, then the boss arena. Re-check the whole-stud grid and the joins between zones (see `Zone Line`).
5. **Playtest:** feel, overkill chains, walking times with and without auras, cannon flights to far zones, chop camera on the biggest rocks, frame rate with debris.

## Not in this plan
New zones, world 2 itself, changes to strength or cash curves, new rock shapes, the zone flyover after the intro cutscene.
