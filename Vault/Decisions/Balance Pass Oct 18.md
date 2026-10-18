---
description: 2026-10-18 balance decisions from the spreadsheet model - stands set training pace, offline doesn't carry progression, spam hatching is fine; numbers in the Luau except Cozy (Snow Roks not in config yet).
type: decision
---
# Balance pass (2026-10-18)

Made with the user's balance model (`Downloads/Chop_a_Rock_Balance_Model_v2.xlsx`, which has a Checks tab testing each zone against targets on Inputs rows 44-48). The v2 copy passes 20 of 20 checks. In the Luau since 2026-10-18 (ArmConfig, TrainingConfig, EconomyConfig, PedestalConfig). Cozy waits for the Snow Roks to go into PetConfig.

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
| Cozy (Snow Rare) $/s | 104,857,600 | 110,000,000 |

Resulting training to the gate: Forest 1.1 / Desert 3.3 / Jungle 5.2 / Ocean 6.5 / Snow 10.9 min, against targets of 1 / 3 / 5 / 7 / 10.

## Still open
- Forest training target lowered to 1 min (user, 2026-10-18: it's the tutorial zone, so fast is fine). The model now passes 20 of 20.
- The Cosmic stand's strength per rep (5B) wasn't re-tuned. Zone 6 isn't in the model. If it keeps the new chain, about 1.5B per rep (x100 the Energy Core).
- Arm prices weren't changed, but arms are now worth much less.

Related: [[Zones After Desert]], [[Rebirth Gated By Strength]], [[Big Numbers Over Small Ones]].

## Arm boost keeps fractions
`TrainingService` keeps a per-player fractional carry (`strengthCarry`, cleared on leave). Each rep adds `floor(StrengthPerRep * mult + carry)` and keeps the remainder, so Wood Arms (x1.25) on the Wood stand average 1.25 per rep (1, 1, 1, 2). Added 2026-10-18 at the user's request. Before that, gains were rounded per rep and Wood Arms added nothing on the Wood stand.
