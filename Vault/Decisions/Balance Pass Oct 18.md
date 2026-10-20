---
description: 2026-10-18 balance decisions from the spreadsheet model - stands set training pace, offline doesn't carry progression, spam hatching is fine; numbers in the Luau except Cozy (Snow Roks not in config yet).
type: decision
---
# Balance pass (2026-10-18)

Made with the user's balance model (`Downloads/Chop_a_Rock_Balance_Model_v3.xlsx`, which has a Checks tab testing each zone against targets on Inputs rows 44-49 and models weather and the Index). v3 passes 25 of 25 checks. In the Luau since 2026-10-18 (ArmConfig, TrainingConfig, EconomyConfig, PedestalConfig). Cozy waits for the Snow Roks to go into PetConfig.

## Decisions (user, 2026-10-18)
- **Stands set the training pace; arms are a small boost.** Arms at x16 made every zone's rebirth gate take under a minute. Arms can't fix it alone, because the needed arm boost would shrink in later zones.
- **Offline income doesn't carry progression.** The target is that one offline session pays for less than one stand.
- **Spam hatching is fine.** A geode costs about 2-3 s of income at a zone's best rock, and that's OK. The user plans an auto-open gamepass where each auto-open rolls a random hit quality, so it isn't broken.
- **Cosmic stand price follows the x75-100 step** of the earlier stands.

## Proposed numbers (v2 model)
| Lever | Was | Now |
|---|---|---|
| Arm training mult (Grass→Crystal) | 1 / 2 / 4 / 8 / 16 | 1 / 1.25 / 1.5 / 2 / 2.5 |
| Steel / Vault / Energy Core strength per rep | 2,500 / 300,000 / 40M | 2,000 / 200,000 / 15M |
| Cosmic cash price | 500B | 2.4T |
| Offline cap / rate | 4 h / 0.5 | 2 h / 0.125 |
| Cozy (Snow Rare) $/s | 104,857,600 | 120,000,000 |

Resulting training to the gate: Forest 1.1 / Desert 3.3 / Jungle 5.2 / Ocean 6.5 / Snow 10.9 min, against targets of 1 / 3 / 5 / 7 / 10.

## Index (user, 2026-10-18)
- **Claims scale per zone.** Fixed rewards gave Forest 130 strength against a 100 gate, so claims skipped training, and from the Desert on they were worth nothing. Forest base strength is now Common 1, Uncommon 1, Rare 2, Epic 3, Legendary 5, Secret 15, each rock 1 (cash unchanged). Each zone scales them (see [[Index]]), so Common-Epic + rocks are 10% of the gate everywhere.
- **The Index money bonus applies to pedestals too.** It used to boost chopping only, which pushed pets under 15% of income by the Ocean. With it, and Cozy at $120M, Snow pets are at 15.2%.

## Jackpots and selling (user, 2026-10-19)
- **Rush and storm add instead of multiply.** All chop bonuses multiplied, so a Master on a Rush Rock that was also an Eclipse storm rock, at a full streak with friends, paid about 80x an average chop: 1.7-1.9x the next stand in every zone. That undercut the Robux stand-cash product. Now the max is about 0.8-0.9x.
- **Friend boost capped at +30%** (`FriendBoostConfig.MaxPercent`). It had no cap before.
- **Sell value 60 s** (was 100). Hatch-and-sell paid 1.02x in the Ocean and 1.32x in the Snow, a money loop the auto-open gamepass would exploit. Now the Snow is 0.79x, or about 0.91x during weather. Re-check when the luck gamepass is wired.
- Model: `Downloads/Chop_a_Rock_Balance_Model_v4.xlsx`, 35 of 35 checks.

## Geodes (user, 2026-10-19)
- **Ocean Geode x3 ($491.52M), Snow Geode x3.5 ($36.7B, planned).** In the worst case (10 rebirths, Eclipse hatches) selling paid 1.26x in the Ocean and 1.57x in the Snow, and a Roks page took 2 and 1 minutes. Now selling is 0.42x / 0.45x, and pages take 10 / 7 minutes. Snow is x3.5, not x6, so the Snow geode stays a 1-5 minute purchase in the Ocean.
- **Forest Geode back to $500, the tutorial's first geode $150.** The $150 price (set for the tutorial 2026-10-16) made Forest hatch-and-sell pay and a Forest page take 1.6 minutes.
- **No new aura tiers needed for purchases.** Ocean and Snow being short of things to save for is end-of-content and clears as zones are added (user). The model's Snow check is expected to fail until zone 6.
- Model: v7, 44 of 45 checks (the 1 is Snow's expected purchase gap).

## Still open
- Forest training target lowered to 1 min (user, 2026-10-18: it's the tutorial zone, so fast is fine). The model now passes 20 of 20.
- The Cosmic stand's strength per rep (5B) wasn't re-tuned. Zone 6 isn't in the model. If it keeps the new chain, about 1.5B per rep (x100 the Energy Core).
- Arm prices weren't changed, but arms are now worth much less.

Related: [[Zones After Desert]], [[Rebirth Gated By Strength]], [[Big Numbers Over Small Ones]].

## Arm boost keeps fractions
`TrainingService` keeps a per-player fractional carry (`strengthCarry`, cleared on leave). Each rep adds `floor(StrengthPerRep * mult + carry)` and keeps the remainder, so Wood Arms (x1.25) on the Wood stand average 1.25 per rep (1, 1, 1, 2). Added 2026-10-18 at the user's request. Before that, gains were rounded per rep and Wood Arms added nothing on the Wood stand.
