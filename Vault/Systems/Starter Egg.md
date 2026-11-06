---
description: 2026-11-05 — replaces the Robux starter pack offer. After the tutorial a 1.8x Mystery Egg drops from the sky onto your base, counts down 15 min of time in game, then opens into the Capybara. StarterEggService, StarterEggController, StarterEggConfig. Played in Studio.
type: system
updated: 2026-11-05
---
# Starter Egg

User, 2026-11-05: "remove the starter pack offer ... the pet from that should still stay, but now after the tutorial ... an egg with a 15 min timer falls from the sky and onto the players plot. the egg is guaranteed to give the pet from the starter pack, but they have to stay 15 mins to see what it is and run my time up. egg also needs to be cool as hell and larger than normal". It's a retention hook: the free reward makes players stay 15 minutes, and they don't know what's inside.

## How it works
- **Given** on `TutorialService.Finished` (once: `data.StarterEgg.IsOpened` blocks a second one). Data: `StarterEgg = { HasEgg, HasLanded, SecondsLeft, PadIndex, IsOpened }`.
- **Hatch pad (user, 2026-11-05: "move the big egg onto an actual egg spot (whatever is open)"):** when it drops it takes the first empty hatch pad (`GeodeService:FreePadIndex`) and saves `PadIndex`. `GeodeService` treats that pad as reserved through `StarterEggService:PadIndexOf`: its prompt stays off, Place and Place All skip it, and it isn't counted as empty. Opening the egg frees it. If every pad is full, the drop waits for one. If the saved pad has a geode on it (old saves), it picks again.
- **Drop:** it falls only when you're within `DropRangeStuds` (120) of your plot's pivot, so you see it. The tutorial ends at the base, so it normally falls at once. The server builds the model on the pad's spot with `LandsAt` 2.5 s ahead. The client holds it 260 studs up and plays the Geode Fall marker, meteor trail and impact (all 1.6x size, tinted Eclipsed purple), whoosh and land sounds, and a heavier camera shake.
- **Timer:** 900 s that only count down while you're in the game (`StarterEggService` tick, saved every 30 s and on leaving). It starts when the egg lands. The label (`UI_DiamondLabel`, purple) reads "Mystery Egg" over "???" while falling, then m:ss, then "Ready!".
- **Looks:** `Model_Egg_RuinsRune` at 1.8x (about 10 studs tall, other eggs are 5.6), a rainbow-cycling Highlight outline, a slow spin and bob. **Eclipse effect (user, 2026-11-05):** the Eclipsed modifier's tint and particles (`PetModifier.Tint` and `PetModifier.AddVFX`, now shared with `ModifiedPet`), on the egg only. The Capybara gets no modifier (it's exclusive). Plus the Geode Fall idle effect in purple **without the light pillar** (the user called the beam texture "the chain"; `FallEffects.AddIdle(..., hasPillar = false)`). Geode Fall still has its pillar. All drafts in `StarterEggConfig`. A one-off egg model through `model-workflow` would make it stand out more.
- **Open:** an owner-only "Open" prompt (`OwnedPrompt`) once ready. Checks bag room ("Bag full! Sell Pets to open it"), grants `PetKey` (Capybara, Legendary, exclusive) through `PetService:Grant`, and plays the normal hatch reveal (`GeodeHatched` with key `StarterEgg`; `HatchController/Scene` builds the starter model at 1.8x). No server-wide announcement.
- **Notices:** "Something is falling on your base...", "A Mystery Egg landed on your base! Stay 15 min to open it", "Your Mystery Egg is ready to open!" (drafts).
- **Admin** (Events tab): Give Starter Egg (`starteregg`; replaces the current one, drops when you're home) and Starter Egg: 10s Left (`starteggready`).

## Starter pack offer removed
- Gone: the 24 h offer window (`OfferService` opening it on the Boulder hint and again on the first rebirth), the `StarterOffer` popup screen and the `StarterOfferShown` packet, the rail offer, the Robux Shop card, `ShopCards.FillStarter`, `PurchaseController:PromptStarterPack`, the admin Grant / Reset Starter Pack buttons, and the `OfferSeconds` / `DueAttribute` config.
- Kept: the dev product's receipt handler and `OfferService:GrantStarterPack`, so anyone who already paid still gets theirs. `data.StarterPack` stays in saves.
- Studio (2026-11-05): `StarterGui.StarterOffer` and the Robux Shop `Templates.StarterCard` moved to `ServerStorage.UIBackup` (`StarterOffer`, `RobuxShop_StarterCard`). **Save the place.** The rail's rotating offer slot is still there with no offers, ready for a future one.
- The 5-min free 2x Strength after the tutorial is unchanged ([[Boosts Lead Into Passes]]).

## Also changed
- The Geode Fall effect helpers moved from `RockController/GeodeFall` to `Utils/FallEffects` (tint, play, meteor, sound, shake, idle, label paint, with an optional scale) so both use them.

## Checked in Play 2026-11-05
Second pass: an already-landed egg from an old save moved onto Pad 1 on join, with the Eclipsed tint and particles and no pillar beam; after granting a geode, Pads 2-8 were active and Pad 1 stayed off.

Away from the base nothing drops; walking home drops it. It falls from y 270 and lands on the path (bottom 5.5, path top 5.4). Label 14:51 after landing. The 10 s admin makes the prompt active. Opening removes the egg, plays the reveal at the egg and puts the Capybara in the hotbar and pen ($100/s). Not tested: the real tutorial ending, or leaving and rejoining mid-timer. The test account has a fresh starter egg waiting from the last test.

Related: [[Tutorial]], [[Geode Fall]], [[Robux Shop Plan Approved]], [[Animal Pets]], [[Admin Panel]]
