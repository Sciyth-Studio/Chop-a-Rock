# Tutorial polish: plan

Status: **approved and built 2026-10-27** (all six; Option A head start; rebirth hint kept positive; Starter Offer held until the Boulder hint is Done). Passes check.ps1, not playtested. What shipped is in `Vault/Systems/Tutorial.md`. These are fixes from Hud's Guide (`08 Retention, Onboarding and Playtime` → *Visual guidance and tutorial UI*, *Contextual steps and progressive reveal*) applied to the 5-step tutorial and the aura, Boulder and cannon hints. See `Vault/Systems/Tutorial.md` and `Vault/Launch Checklist.md`. Each section can be approved on its own.

## 1. Shorter text: 4 words max (user, 2026-10-27; the guide says about 5)
Every title and detail line, in the tutorial and all hints, is 4 words or fewer. Key names count as words ("Press E" is 2), and counters such as "1/4" or "$87/$150" don't count. Lines already at 4 or fewer stay ("Break the boards!", "Follow the arrows", "Keep going!", "Buy one Forest Geode!", "Walk onto the pad", "Grab your Rok's cash!", "You're ready! Go chop!", "Silver Aura unlocked!", "Buy the Silver Aura!", "Fire the cannon!", "Click Fire to launch!").

| Where | Now | Proposed |
| --- | --- | --- |
| Tutorial, Crack title | Crack it at your base! | Crack your geode! |
| Tutorial, near a Stone | Hold E to chop a Stone | Hold E to chop! |
| Tutorial, near the pit | Hold E to chop the geode | Hold E to crack! |
| Tutorial, chop/crack minigame | Press E when the line is in the glowing zone! | Press E in glow! |
| Meter arrow, waiting | Press E when the line is here | Press E here |
| Meter arrow, in the zone | Now! Press E! | (keep) |
| Tutorial, Collect | Step on the green pad | Step on green pad |
| Teleport hint | Click Rocks to teleport there! | Click Rocks! |
| Teleport hint, shops | Click Shops at the top! | Click Shops! |
| Aura hint, saving | Save up for it: $87/$150 | Save up! $87/$150 |
| Aura hint, walking to the pad | Walk onto the red pad | Step on red pad |
| Aura hint, shop open | Click the price to buy it! | Click Buy! |
| Aura hint title | Train with your new aura! 1/3 | Train with your aura! 1/3 |
| Aura hint, training | Your aura gives x1.25 strength per rep! | x1.25 strength! |
| Boulder hint, training title | Train to unlock the Boulder! 8/20 | Train for the Boulder! 8/20 |
| Boulder hint, chop title | Chop a Boulder! 4x cash | Chop Boulders! 4x cash! |
| Boulder hint, near one | Hold E to chop a Boulder | Hold E to chop! |
| Cannon hint, saving | Save up for it: $x/$y | Save up! $x/$y |
| Cannon hint, walking to the pad | Walk onto the orange pad | Step on orange pad |
| Cannon hint, shop open | Click the price to buy it! | Click Buy! |
| Completion banner (section 5) | Free 2x Strength for 5 min! | Free 2x Strength! |

"Tap" and gamepad keys still swap in as now. The teleport spotlight already shows which button to press, so the button name is enough. New text in sections 3–6 ("Over here!", "Click here!", "Rebirth for x1.25 cash!", "Click Rebirth!", "Tutorial complete!") is already 4 words or fewer.

## 2. Progress never starts at 0
Counters showing 0 today: "Break the boards! 0/4", "Chop rocks for cash! $0/$150", "Train with your aura! 0/3".
- **Option A (recommended): real head start.** New players start with 1 Strength (the board counter reads 1/4 on join, 3 reps left instead of 4). The tutorial Chop step starts at $0 but the first Stone is a forced Perfect, so it ticks within seconds. Option A covers that one with a head start too: the Chop counter only shows once the first Stone breaks, with "Hold E to chop a Stone" until then. The aura reps start at 1/3: buying the aura counts as the first.
- **Option B: display only.** Show every counter as (done + 1)/(goal + 1), e.g. 1/5 boards at the start. No balance change, but the numbers aren't real.

## 3. Step praise
When a tutorial step or hint stage completes, the title shows a short praise for 1.2 s before the next step's text, alongside the step sound that already plays. Never the same word twice in a row:
- Train done: "Strong!"
- Chop done: "Cha-ching!"
- Geode bought: "Got it!"
- Crack done: none (the hatch reveal already celebrates)
- Collect done: goes straight to the completion moment (section 5)
- Hint stages: a rotating "Nice!", "Awesome!", "Great!"

## 4. Idle forgiveness highlight (guide: auto-highlight after ~30 s idle)
During the core tutorial and the Buy stages of the hints: after 20 s with no step progress **and** no movement or input, the guide does the following.
- The target marker grows to 2x and the highlight pulses faster.
- A soft "ping" sound plays.
- The detail line reads "Over here!" (or "Click here!" when a button is spotlighted).
- If a teleport would help, its button is spotlighted even when the walk is shorter than the usual 40-stud rule.

It resets as soon as the player moves or makes progress, and repeats every 20 s. Values in `TutorialConfig` (`IdleSeconds = 20`).

## 5. Completion reward moment
Today, finishing gives a free 2x Strength for 5 min (`MonetizationConfig.TasteSeconds`) with a normal notification "Free 2x Strength for 5 min!". Proposed: keep the reward and make the end feel big.
- On Done: the `VFX_LevelUp` burst on the character (already used for rebirth) and `SFX_Level_Up`.
- A centre-screen banner for ~2.5 s: "Tutorial complete!", with "Free 2x Strength!" under it and the boost icon. Built in Studio as `StarterGui.TutorialComplete` per [[UI Built In Studio]]: Chrome title, Green reward line, no caps. Pops with the existing UI Feel panel pop.
- The "You're ready! Go chop!" Final step stays as the 3 s lead-in.

**Related flag (not part of this change unless you say so):** the Starter Offer opens as soon as the tutorial ends, because `StarterOffer.isFree` only waits for Done. The guide says "first give, then ask": show offers after about a dozen wins, not right after the tutorial. Option: hold the Starter Offer until the Boulder hint is Done, or 5 min of play.

## 6. Rebirth hint
A new staggered hint after the Boulder hint, same pattern as the aura and Boulder hints (`RebirthHint.luau`, `RebirthHintService`, `Hints.Rebirth`).
- **Stages:** Locked 0 → Ready 1 → Done 2.
- **Ready** starts when Strength reaches rebirth 1's `StrengthRequired` (100), once the Boulder hint is Done.
  - The menu `Rebirth` button is spotlighted, title "Rebirth for x1.25 cash!", detail "Click Rebirth!".
  - With the Rebirth panel open, the spotlight moves to `RebirthButton`.
  - The multiplier comes from `RebirthStats.Get(1).CashMultiplier`.
- **Done** on the first rebirth. Silent Done if the player already rebirthed.
- Shows ahead of the aura hint, behind the Boulder hint.
- Logs `RebirthHint` per stage. Admin Reset Tutorial gets a "Rebirth Hint" choice.
- The cannon hint already starts after rebirth 1, so the chain becomes: tutorial → aura → Boulder → rebirth → cannon.
- **Open question:** rebirth resets cash and Strength. Should the detail warn about that ("Resets cash and Strength"), or keep it positive and let the panel explain?
