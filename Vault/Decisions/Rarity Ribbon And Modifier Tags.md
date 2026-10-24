---
description: 2026-10-23 sell cards show rarity as a coloured ribbon across the top and the weather modifier as its name only, in that weather's label gradient.
type: decision
---
# Rarity Ribbon And Modifier Tags

The user said the sell card's plain rarity text "looks lame" (and "Uncommon" clipped), and the modifier text ("Toasty $3.5/s") shouldn't show the multiplier or use a colour that doesn't match its weather.

![[Sell Card Rarity Ribbon.jpg]]

Take from it: the ribbon across the top of each card, and the "Toasty" tag over the bottom of the preview in the Heat Wave colours.

## Rarity ribbon
- `RarityBar` frame across the top of the card (30 px, inset 3 px), white background with a vertical `UIGradient` painted by `Utils/RarityRibbon.Paint(bar, rarityKey)`: rarity colour lightened at the top (`RarityConfig.RibbonLighten`), pure in the middle, darkened at the bottom (`RibbonDarken`). Secret uses `RarityConfig.Rainbow`, horizontal. A 3 px black `Edge` line under it.
- The rarity text sits inside as `Rarity`: `Chrome` style, 2.5 px black stroke, `TextScaled` with `UITextSizeConstraint` max 26, so "Uncommon" and "Legendary" fit.
- Before this, no screen had a rarity chip: Index and HatchReveal use plain rarity-coloured text, the Geode Stand tints the card glow. `RarityRibbon` is the shared look for adopting it elsewhere.

## Modifier tag
- Modifier name only (no multiplier, no rate), on its own `Modifier` label over the bottom of the preview, rotated -6. The `$/s` line stays the normal rate (already including the modifier).
- Colours come from `WeatherConfig.Modifiers[x].LabelTop`/`LabelBottom` (the weather pill and notification colours) via `RokModifier.PaintLabel(label, modifier)`; stroke is `LabelBottom` darkened by `WeatherConfig.LabelDarkAlpha`. Pedestal, Notifications and WeatherController still repeat that paint inline.

Backup of the old card: `ServerStorage.UIBackup.SellCardBeforeRibbon`.

Related: [[Sell Shop]], [[Weather]], [[UI Text Style]]
