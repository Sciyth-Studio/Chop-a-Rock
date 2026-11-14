# Potion Plan

Status: **built 2026-11-12 (see vault note Potions), user feedback applied** ("this is perfect as a reward"). User calls the same day: potions **only come from bosses**; the tutorial keeps auto-applying its free boost; the Boss Egg always gives the boss Pet and is rarer (about 8%); the Bag button comes back on the hotbar with side tabs for Pets, Eggs and Potions ([[Inventory Tabs Reference]]). All numbers are drafts for the Balance Model.

## 1. Why now

Bosses need rewards that aren't cash (user, 2026-11-12: "I don't want to inflate cash"). Potions are the boss reward: something worth winning that runs out, so the economy doesn't grow forever, and a reason to come back to the arena.

## 2. Rules this has to keep

| Rule | Source | What it means here |
| --- | --- | --- |
| No Robux luck potions | Master Game Plan §00 (2026-10-03), `RobuxShopPlan.md` | Luck potions are free only, earned in game. Never sold, never in a paid bundle. |
| Potions only from bosses | User, 2026-11-12 | Boss wins and the Boss Chest are the only sources. Not from the Index, Guardians, weather, the Free Gift or the tutorial. |
| Timed boosts lead into the 2x passes | [[Boosts Lead Into Passes]] (2026-11-05) | A Strength potion running out shows the same "Get it forever?" card. |
| Don't inflate cash | User, 2026-11-12 | No cash potion. |
| Never punish missing a day; players are about 10 | `WorldBossPlan.md` §2 | Potions keep until you drink them. They never expire in the bag. |
| Few words | [[Kid Friendly Pass]] | "Luck Potion", "Drink!", "+10 min". |

## 3. What a potion is

A **potion** is an item you keep in your bag and drink when you choose. Drinking it starts a timed boost.

- **Kept, not instant:** kids get them in the arena or from the Index, often far from where they'd use them. A potion waits until it's drunk.
- **Only counts down while it's working:** each type pauses when there's nothing for it to do, the way the free 2x Strength already pauses when you stop training (`OnlyWhileTraining`, `BoostPaused<Key>` attributes). Nobody wastes a potion walking back to their base.
- **Same type adds time, not power:** drinking a second Strength potion adds its 10 minutes. Different types run side by side.
- **Cap:** the existing 6 h personal cap (`BoostCapSeconds`) per type. A drink that would pass it is refused with the existing "full" message, and the potion stays in the bag.

## 4. Types

| Potion | Does | Counts down while | Notes |
| --- | --- | --- | --- |
| **Luck** | Eggs you earn get extra luck | You're chopping rocks (a chop session or the walk between rocks in a zone) | Adds to the luck rolled into each egg when it flies out of a rock (`GeodeService/EggLuck`). Free only. |
| **Strength** | More strength per training rep | Training | Same effect as the 2x Strength boost. Run-out card pitches the pass. |
| **Hatch** | Eggs on your pads hatch faster | An egg is hatching on one of your pads | Speeds the pad timers. Doesn't stack with the base level's hatch bonus by multiplying: it adds (see 6). |
| **Speed** | Faster walking | Always | Cheap and fun. Good common reward. |
| **Focus** | Wider Perfect zone on the chop bar | You're in any chop (rocks, Guardians, bosses) | Helps younger kids. The server judge and the drawn bar both use it, the same way the boss's mad Perfect scale works (`ChopZones` `perfectScale`). |

No **Cash** potion (inflation). No **Master** potion (Master Chops are a jackpot; guaranteeing them breaks the surprise).

## 5. Strength of each potion (drafts)

**One size per potion** (user, 2026-11-12: "the potions don't have varying sizes"). Every potion lasts **10 min**.

| Potion | Effect |
| --- | --- |
| Luck | x2 egg luck |
| Strength | x2 training |
| Hatch | eggs hatch 2x as fast (-50% time) |
| Speed | +8 walk speed (`WalkSpeedService`) |
| Focus | Perfect zone 1.5x as wide, under the same 17% cap the bosses use (`MaxPerfectShare`) |

## 6. How it adds up with what's there

- **Strength:** potion and the 2x Strength boost and the pass add together, as boosts and passes do now (pass x2 + boost x2 = 3x). A Strength potion with the pass is 3x, and with the pass and the boost 4x.
- **Luck:** adds to the egg's rolled luck, then the 2x Luck pass and Server 2x Luck apply as today. Odds shown before and after luck (`HatchLuck`, [[Monetization Compliance]]) include it.
- **Hatch:** the potion's cut and the base level's -5% per level add together, with a cap (draft 75%) so hatching never becomes instant. A Hatch potion cuts 50%. Example: base level 4 (-20%) plus a Hatch potion (-50%) = -70%, so a 10 min egg takes 3 min.
- **Offline:** potions don't count down offline. If the user approves offline hatching at half speed (playtest notes 2026-11-12), Hatch potions still only run while you're in the game.

## 7. Where they come from

**Only bosses** (user, 2026-11-12).

| Source | What drops | Why |
| --- | --- | --- |
| **Boss win** | 1 random potion for everyone credited (dealt 3% of their share) | Reward for completion without cash |
| **Boss time-out after mad ("Almost!")** | 25% chance of 1 random potion for everyone who dealt damage | Matches the 25% "Almost!" cash; trying still counts |
| **Boss Chest** (weekly) | See section 8 | The big reward |

The tutorial keeps auto-applying its free 5 min 2x Strength boost as it does now (user): it isn't a potion and never goes in the bag.

## 8. Boss Chest pool (draft)

The chest opens like an egg hatch and gives **one** reward (user, 2026-11-11).

| Reward | Chance |
| --- | --- |
| Strength or Hatch potion x3 | 42% |
| Luck potion x3 | 27% |
| One of each potion (x5) | 20% |
| **Boss Egg** (hatches on your pads into **the boss Pet, always**; which boss is the one you beat most this week, or random among them on a tie) | 8% |
| Boss cosmetic (aura palette, base trophy or title) | 3% |

User, 2026-11-12: an egg that only sometimes gives the boss Pet "seems mean", so the Boss Egg always gives it and is rarer instead (about 8%). The Pet stays a chance through the chest roll, and nothing adds cash. Boss Egg and cosmetics are separate plans.

## 9. Screens

- **Bag button back on the hotbar (user, 2026-11-12):** the Bag button was scrapped; it returns **as part of the hotbar, like the Pets button was before**, at its left end with a key badge. It opens the inventory panel (`Screens/Pets`, which is already modelled on [[Inventory Tabs Reference]]).
- **Side tabs:** square tab buttons down the panel's left side, each a label over an icon like the reference's top-left button: **Pets** (paw), **Eggs** (egg), **Potions** (potion). The title, count line, search and card grid switch with the tab.
- **Potions tab:** one card per type, a stack count top-right, the potion's colour as the border, its effect and time on the dark strip ("x2 Luck 10m"), and **Drink!** in the detail pane where Pets show Hold. Potions never go on the hotbar slots themselves.
- **Eggs tab:** the eggs you own, with luck and hatch time, moved out of the Pets list.
- **Running:** a drunk potion shows as a label at the bottom right with the other boosts (`Screens/BoostPills`), with its icon, multiplier and time, and "paused" when it isn't counting.
- **Got one:** a short notification with the potion icon ("+1 Luck Potion!").
- **Icons:** one per type, made from `assets/Icons/Potions/Prompts.md` (Luck green, Strength red, Hatch yellow, Speed blue, Focus purple), each its own bottle shape with a symbol. Not the Free Icon Pack bottle (user didn't like it, 2026-11-12); the pack's five potions are only stand-ins until the real icons exist.
- **Hover/tap:** the card explains the potion in one line ("Better eggs from rocks for 10 min").

## 10. Robux (optional, needs the user's call)

Only Strength and Hatch can be sold, never Luck. Option A: leave the existing 2x Strength and 2x Cash boost products as they are and sell no potions. Option B: replace the 15 min / 1 h Strength products with potion bundles (3 or 10 potions), which kids can save for later. B is more flexible for players but changes products the shop already sells. Recommended: **A** for launch, revisit after seeing boost sales.

## 11. Data and code

- **Save:** `data.Potions` = `{ [potionKey]: count }` where `potionKey` is the type (e.g. `Luck`). Running potions reuse `data.Boosts` with new keys (`PotionLuck`, `PotionStrength`, ...). Migration: missing fields default to empty.
- **Config:** `PotionConfig` (types, multipliers, time, colours, icons, "counts down while" rule, drop tables).
- **Server:** `PotionService` (grant, drink, refuse at cap, multiplier lookup) on top of `BoostService`'s countdown and pause. Hooks: `StatsService` (Strength), `GeodeService/EggLuck` (Luck), the pad hatch timer (Hatch), `WalkSpeedService` (Speed), `ChopZones` `perfectScale` in Rock, Enemy, Diamond and Boss services (Focus).
- **Client:** Bag button on the hotbar (`Screens/Toolbar`), side tabs and the Eggs and Potions pages in `Screens/Pets` (Studio UI, built with the `studio-ui` skill), labels in `Screens/BoostPills`, notification icon.
- **Analytics:** custom events `PotionGranted` (type, source), `PotionDrunk` (type), `PotionRanOut` (type), so we can see which ones get used and which sit in bags.
- **Admin:** "Give Potion" (type, count) and "Clear Potions".

## 12. Build order

1. Bag button back on the hotbar, side tabs (Pets, Eggs, Potions) in the inventory panel.
2. `PotionConfig`, save fields, `PotionService` with drink and the Strength and Speed effects; admin give. Playtest drinking and pausing.
3. Potions tab cards and boost labels.
4. Luck, Hatch and Focus effects.
5. Boss win and "Almost!" drops.
6. Boss Chest with the section 8 pool, and the Boss Egg.
7. Balance Model pass on every multiplier and drop rate.

## 13. Open questions for the user

Answered 2026-11-12: the user's idea was this ("this is perfect as a reward"); bosses only; tutorial keeps its auto boost; Boss Egg always gives the boss Pet at about 8%; Bag button on the hotbar with side tabs.

Still open:
1. Are the five types right? (Add or drop any.)
2. Effects in section 5 (x2 for 10 min) OK as a starting point?
3. Robux: section 10 option A (no potions for Robux at launch) or B? With potions boss-only, A fits best.
4. Which boss a Boss Egg gives (section 8 draft: the one you beat most this week).
