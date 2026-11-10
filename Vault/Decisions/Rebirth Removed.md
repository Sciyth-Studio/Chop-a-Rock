---
description: 2026-11-09 — the user scrapped rebirth; strength and cash never reset, training stands are cash only (Steel $4M, Vault $250M, Energy Core $16B, Cosmic $1.1T), no cash multiplier; supersedes Rebirth Gated By Strength. Next: a 20-stand metal-and-gem ladder.
type: decision
---
# Rebirth removed (2026-11-09)

Supersedes [[Rebirth Gated By Strength]].

The user: "I'm scrapping rebirth. It's much simpler to just not have it. ... the only things still rebirth gated can always be cash gated, and this makes scaling and balancing infinitely easier." Their reasons: wiping money is a pain, so is wiping strength, and top games in this genre don't have a rebirth system.

## What changed
- **Stands are cash only.** The rebirth requirement (rebirths 1, 4, 7, 10, 13) is gone. The upgrade sign always shows the price, and short of cash it opens the [[Cash Packs]] prompt as before.
- **Prices cut** to keep each stand at 2.5-4.4 minutes of income without the multiplier. Brick $50K (same), Steel $4M (was $5M), Vault $250M ($400M), Energy Core $16B ($30B), Cosmic $1.1T ($2.4T). Divided by the rebirth multiplier the player would have had in the zone where they buy it.
- **No strength cap.** Strength was capped at the next rebirth gate. Now it only goes up, and rock `StrengthRequired` alone gates rocks and zones. "Rebirth ready!" is gone; "<Rock> unlocked!" stays.
- **No cash multiplier.** Chop, Diamond Rock and pedestal income all pay x1 (was 1 + 0.1 x rebirths).
- **Saves:** `PlayerData.Migrate` sets `Rebirths = nil`. Strength, PeakStrength, TrainingTier and Cash are untouched. No compensation (the game isn't live). Old `Hints.Rebirth` keys are left in saves; nothing reads them.
- **Funnel step 11** was `FirstRebirth`; it is now `SecondStand` (TrainingTier ≥ `TutorialConfig.SecondStandTier` 2). Step numbers are saved, so the slot was reused instead of renumbered.
- **Celebration burst kept.** The tutorial-complete burst (`VFX_LevelUp` + `SFX_Level_Up`) moved from `RebirthEffectController` to `CelebrationEffectController` with `CelebrationConfig`.
- **Gone:** `RebirthService`, `RebirthHintService`, `RebirthConfig`, `Utils/RebirthStats`, `shared/RebirthHint`, `Screens/Rebirth`, `TutorialController/RebirthHint`, `TrainingStands.ForRebirths` / `IndexForRebirths`, the `Rebirth` packet, analytics sink `Rebirth`, `IconConfig.Rebirth`, the Player List `Rebirths` column, admin `SetRebirths` and the Rebirth Hint reset choice, the sign's rebirth lock and `RebirthIcon`. Admin presets Pre-Rebirth / Rebirth Ready became Early Forest / Forest Done; presets set `TrainingTier` directly.
- **Studio:** `StarterGui.Rebirth` and the sign's `CashButton.RebirthIcon` moved to `ServerStorage.UIBackup.RebirthRemoved20261109`. The menu button was removed by the menu-buttons session.

## Balance (Balance Model v14)
Run on the New Loop tab ([[Balance Model]] v14):
- Each zone after the Forest is about 20% shorter, because strength is never climbed twice. About 231 min to the top of Golem Ruins instead of 288.
- Income without the multiplier is 1.3x lower in the Desert, 3.4x by the Volcano. Hence the price cut.
- Carried cash barely matters: income grows about 64x per zone.
- Checks 35 / 51 (33 in v13). Pets too strong (Volcano, Golem Ruins) and offline too generous (Volcano) now pass. New fail: Golem Ruins has nothing to save for, because its own aura takes 6.3 min of income. Auras from the Bamboo Forest on take 5-6 min; aura prices are a separate pass.
- Risk: from the Ocean on, Pet income may let a player buy the next stand before reaching the zone's top rock. If so the zone just runs faster. Check in playtests.

## Next: 20-stand ladder (agreed direction, not built)
With rebirth gone, stands are the main strength milestone. The user wants stands scaled like a material ladder (not tied to zones), picked for what a 13-year-old thinks is cool: Wood, Bronze, Iron, Silver, Gold, Steel, Amethyst, Emerald, Titanium, Sapphire, Ruby, Platinum, Obsidian, Tungsten, Diamond, Black Diamond, Painite (no fun fact on the sign), Meteorite, Dark Matter, Neutron Star. Two per zone, x10 strength per rep each (1, 2, 6, 60, 500, 5K ... 400Q); prices about 3 min of income where bought (first of a zone at the end of the previous zone, second at the zone's second rock): $0, $8K, $30K, $800K, $3M, $60M, $250M, $4B, $15B, $300B, $1T, $20T, $80T, $1.5Q, $5Q, $80Q, $400Q, $6Qi, $25Qi, $400Qi. A scratch run lands within about 10% of the sheet's training targets (Forest 0.7 min, Golem Ruins 11% short). The user plans to build them in Lune: one metal build and one gem build, varied by colour, material, glow and break sound. Built 2026-11-09: modelled ([[Stand Ladder Models]]), in `TrainingConfig` and in [[Balance Model]] v15 (35 / 51; the Forest trains on Wood only, Bronze is bought at its top).
