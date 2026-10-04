---
description: Reference sheets for the first-zone geode (closed and split), 2026-10-03; open before modelling or restyling geodes.
type: reference
---
# Geode reference

![[Geode Ref Closed.webp]]
![[Geode Ref Split.webp]]

What to take from them:

- **Closed shape:** boxy, about as wide as tall, built only from big flat chipped faces. The user hates bumps and knobs, and the first ChatGPT try came out egg-shaped (taller-than-wide ovals read as eggs).
- **Split:** two halves cut front to back like the chop rocks, a thick stone rim around a hollow lined with a ring of 8 chunky crystal points aimed at the centre, which stays clear for the pet.
- **Crystal colour changes with rarity**, so crystals are their own part: white with vertex colours (lining about 0.3 grey, crystals near white) so the part `Color` gives bright crystals over a darker cavity.
- Studs on the stone shell, not on the crystals.

## The approved model (2026-10-03)
- Exported to `assets/Geodes/Geode_Basic/` (closed `Geode_Basic.fbx`, `Geode_Basic_Split.fbx`, previews, `.blend`). Closed size about 6.2 x 5.3 x 5.2 studs.
- Split model: `Geode_HalfA` / `Geode_HalfB` (studded shells, cut front to back like the rocks) and `Geode_CrystalsA` / `Geode_CrystalsB` (cavity lining and 14 crystals each: a ring of 9 at the rim, 5 deeper). Hollow about 3.8 x 3.7 x 3.5 studs; pets must fit that.
- Rim about 0.6 studs. The user found 1 stud too thick, big crystals too crowding for the pet, and 8 small crystals too sparse.
- In Studio: `ReplicatedStorage.Assets.Models.Model_Geode_Basic` and `Model_GeodeSplit_Basic` (AssetRegistry keys of the same name), pivots at bottom centre. Shells are grey with the `Studs` overlay. Crystals are SmoothPlastic with a placeholder purple `Color`; the baked shading multiplies it, so code sets the rarity colour on the part.
- Crystal parts are open meshes (no CanCollide needed); keep the shell and crystal halves at their relative positions.

Gameplay side is in the Master Game Plan §03 (Pet rocks). Related: [[Rocks Look Like Boulders]], [[Studs On Models By Default]]
