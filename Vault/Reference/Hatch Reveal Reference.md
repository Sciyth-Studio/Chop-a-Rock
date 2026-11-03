---
description: Egg-hatch result screen the user wants the Pet reveal to look like (2026-10-06), plus their geode hover/white/expand sequence.
type: reference
---
# Hatch reveal reference

![[Hatch Reveal Reference.png]]

Take from it (layout and content; text style per [[UI Text Style]]):
- Full-screen reveal over a blurred, darkened game view. No boxed card.
- Top: the pet's name, very big, white with a thick dark outline. Under it: that pet's odds % in gold.
- "NEW!" in green, tilted, top right of the pet.
- Centre: the pet, very large, on a soft white radial sunburst.
- Under the pet: its stat as icon + green number ("+30" with a lightning icon). Ours: the money icon and the Pet's money multiplier.
- Bottom: a mouse icon and "Click to continue".

The user's geode sequence (2026-10-06): after the chop, the geode **hovers about 4 studs up**, **turns white**, then **expands by an amount that depends on the Pet's rarity**, before the reveal screen.

Related: [[Geode Reference]], [[UI Style References]]

**Replaced 2026-11-03:** the full-screen card is gone ([[Geodes As Inventory Items]]). The hover, white, spin and rarity steps stay and play at the pad with the camera free. After the pop the Pet stands there for `PetShowSeconds` with `UI_HatchRevealLabel` above it (`HatchController/Scene.ShowPet`). `StarterGui.HatchReveal` is unused once this is merged and can be moved to `ServerStorage.UIBackup`.
