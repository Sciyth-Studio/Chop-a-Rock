---
description: Reference sheet for the per-zone geode stand (the pedestal geodes are bought from), 2026-10-03; same model in every zone.
type: reference
---
# Geode stand reference

![[Geode Stand Reference Sheet.png]]

Take from it:
- Square stone plinth: wide low base step, tapered body (wider at the bottom), overhanging cap slab with a thin raised plate on top. The top is flat and empty; the geode sits there.
- Small blue crystal clusters at the four corners of the base step, as their own part so their colour can change.
- Plain warm-grey stone. Studs go on in Roblox, not in the sheet.

Build (Blender, `GeodeStand` collection, `assets/Geodes/GeodeStand/stand_builder.py`): `GeodeStand` about 8 x 5.46 x 8 studs (first built at 4.55, then the user asked for 1.2x taller). The reference is nearly as tall as it is wide; it was kept lower so the geode on top stays near head height. Top plate is 6.6 studs square, which fits the 6.2 x 5.2 geode. `GeodeStand_Crystals` is 16 closed crystals in one mesh.

## In Studio (2026-10-03)
- Forest copy: `Workspace.GeodeStand` (placed by the user on `Forest Zone.Floor`), template `ReplicatedStorage.Assets.Models.Model_GeodeStand` (AssetRegistry key of the same name). PrimaryPart `GeodeStand`, pivot at bottom centre, so new zones can `PivotTo` a floor point.
- Stone: SmoothPlastic, `Color` 163,158,148, `Studs` SurfaceAppearance, Hull collision. Crystals: SmoothPlastic, `Color` 50,110,255, CanCollide/CanTouch/CanQuery off.
- The import came in unanchored; check Anchored after every 3D Importer import.

Related: [[Geode Reference]], [[Shop Stall Reference]], [[Studs On Models By Default]]
