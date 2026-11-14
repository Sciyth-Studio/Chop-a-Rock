---
description: Potions (built 2026-11-12, partly played by Claude) - one-size 10 min boosts kept in the bag and drunk from the new Potions tab; only from bosses; PotionService on top of BoostService timers; Bag button back on the hotbar with Pets / Eggs / Potions tabs
type: system
---
# Potions

Design: `PotionPlan.md` (user approved 2026-11-12, "this is perfect as a reward"). User calls: **only from bosses**, **one size** (no Small/Medium/Big), tutorial keeps its auto 2x Strength, the Boss Egg (not built) always gives the boss Pet at ~8% of the Boss Chest.

## How it works
- Five potions in `PotionConfig`: Luck (x2 egg luck), Strength (x2 training), Hatch (eggs hatch 2x as fast), Speed (+8 walk speed), Focus (Perfect zone 1.5x, capped at 17%). Each lasts `Seconds` 600.
- **Bag:** `data.Potions[key] = count`. `PotionService:Grant` / `GrantRandom` / `Drink` / `Clear`. Packet `DrinkPotion(key) -> bool`.
- **Timers:** a drunk potion is a personal boost in `BoostService` under the key `Potion<Key>` (same save, countdown, cap, `BoostEnds<key>` / `BoostPaused<key>` attributes). `BoostService` asks `PotionService:IsPaused` for those keys. Counts down only while: Strength = training, Luck = in a zone (`ZonePresenceService`), Hatch = an egg is hatching (`GeodeService:IsHatching`), Focus = in any chop (rock, Diamond, boss, Guardian), Speed = always.
- **Effects:** Strength adds +1 in `PassService:GetMultiplier("Strength")`. Luck multiplies the luck in `GeodeService.GrantGeodes`. Hatch pulls hatching pads' `ReadyAt` earlier by 1 s per second (`GeodeService:AdvanceHatching`, PotionService tick). Speed is a `WalkSpeedService` bonus (source `Potion`). Focus passes a `perfectScale` into `ChopZones.Classify` on all four chop services, and `ChopBar` draws it from the `BoostEndsPotionFocus` attribute (multiplied with the boss's mad scale).
- **Drops:** `BossService.finish`: a credited win gives 1 random potion; a time-out after mad gives 1 with a 25% chance (`BossAlmostChance`).
- **Labels:** potions are added to the bottom-right boost labels (`Screens/BoostPills`) with their own text style (new `Purple` style for Focus).
- **Admin (Shop tab):** Give Potion (x3; Random or a type, alias `potion`), Clear Potions (`nopotions`).
- Not built yet: the Strength potion run-out "Get it forever?" card, analytics events, the Boss Chest and Boss Egg.

## Bag button and tabs (Studio)
- `Toolbar.Bar.BagButton`: the old Pets toggle restored from `UIBackup["Toolbar.BeforePetsRight"]`, label "Bag", outlined golden backpack icon, first in the bar (954 wide). `Screens/Toolbar` opens the Pets panel on click (`ToolbarConfig.BagButtonName`); ~ still works. The right-side `PetsButton` menu button is deleted (`MenuButtonConfig`), and `OfferRail.Container` moved back to x -16.
- `Pets.PopRoot.Panel.Tabs`: three 120 px tiles left of the panel (`TabPets`, `TabEggs`, `TabPotions`, each with an `ActiveColor` attribute; idle grey `PetsConfig.IdleTabColor`). `Screens/Pets` swaps the header title and icon, the count line, and the grid: Pets tab = Pets (Equip Best and +1 Slot shown), Eggs tab = eggs, Potions tab = potion cards (`PetStacks.PaintPotion`) whose detail popup shows the effect, "Lasts 10 min" and **Drink!**.
- Backups: `ServerStorage.UIBackup["Toolbar.BeforeBagButton"]` (Toolbar, Pets, MenuButtons, OfferRail).
- Reference: [[Inventory Tabs Reference]].

## Icons
Real set since 2026-11-12, from the user's ChatGPT run of `assets/Icons/Potions/Prompts.md`: sheet `assets/Icons/Potions/PotionSheet.webp`, cut and cleaned into `Clean/` (alpha ramp 150-230, islands under 400 px dropped, split on column gaps, 8% padding, 512 px), outlines baked into `Outlined/` (ids in its `assets.json`): Luck 136122184424656 (round flask, clover), Strength 76548713469285 (square jug, arm), Hatch 102090116512531 (egg bottle), Speed 78675091475510 (winged slim bottle, bolt), Focus 130676061399927 (cone flask, target). The Potions tab uses the Luck one. The Eggs tab uses the pack's `Item/Egg/Egg 1st` (user's pick), outlined, 88606902814397. The old pack-bottle stand-ins (`StandIn/`) are unused.

## Played by Claude 2026-11-12
Bag button opened the panel, the Potions tab showed both potions with counts, clicking a card opened the popup, Drink! drank a Speed potion (walk 105 → 113, count 3 → 2, label "Speed Potion (09:58)"), a Luck potion drunk in the lobby showed "paused". Not played: Strength, Hatch and Focus effects, boss drops, the Eggs tab.

Related: [[Toolbar]], [[World Bosses]], [[Boosts Lead Into Passes]]

**Pause icon (user 2026-11-13):** a paused boost or potion label shows a pause icon instead of the word "paused". `BoostPills.Stack.PillTemplate` has `PauseIcon` (two 8x26 bars, upright since 2026-11-13, with a `UIGradient` and a 2.5 px `UIStroke`) and `PauseIconShadow` (black, 40%, 2,3 offset), just left of the item icon. `Screens/BoostPills` paints the bars in the label's own text style (gradient + stroke from `TextStyleConfig`) and narrows the label by `PauseIconGapPixels` (44) while paused. Falls back to the word if the icon is missing. Backup: `UIBackup["BoostPills.BeforePauseIcon"]`.
