---
description: 2026-10-25 six-view sheets for the two exclusive Roks, Champ (starter pack) and Kingy (exclusive stand); off-white bodies; what to take from each.
type: reference
---
# Exclusive Rok sheets

Prompts: `assets/Roks/Exclusive/Prompts.md`. Both bodies are Bloky's in off-white, RGB 240, 235, 220 (draft; the user's pick 2026-10-25 was "off white" for both, not gold or purple). The front is the top-left view on both sheets.

![[Champ Reference Sheet.webp]]
![[Kingy Reference Sheet.webp]]

Take from them:
- **Champ:** Bloky body and eyes, a flat red headband all the way round just above the eyes, knotted at the back corner on the right as seen from the front (Blender +X +Y), with two short wide tails, one angled up and one down. The sheet's back view draws the knot on the wrong side; follow the front and 3/4 views.
- **Kingy:** Bloky body and eyes under a chunky gold crown whose band covers the top edge of the body. Five broad pyramid points (the front one tallest), a gem on each point and red/blue square gems alternating round the band. A red cape hangs from under the crown round the back half of the body, flaring out, with a thick white trim at the bottom just above the ground.

Build: both in `assets/Roks/Exclusive/ExclusiveRoks.blend`, one collection per Rok, Kingy at x 2.8. The build script was a scratch file. Previews: `lineup_*.png` and `<Name>_views.png` in the set folder.

Approved 2026-10-25 and exported to `assets/Roks/<Name>/<Name>.fbx` (checked by re-import, min z 0):
- **Champ:** `Champ` body Plastic + `2022 Small Stud` 240, 235, 220; `Champ_Headband` and `Champ_Knot` (knot and two ribbon tails) SmoothPlastic 230, 0, 0; about 316 prop tris.
- **Kingy:** same body; `Kingy_Crown` SmoothPlastic 255, 200, 0; `Kingy_GemsRed` Neon 255, 0, 0 and `Kingy_GemsBlue` Neon 0, 80, 255; `Kingy_Cape` SmoothPlastic 230, 0, 0; `Kingy_Trim` SmoothPlastic 250, 250, 250; about 836 prop tris; 2.86 x 3.04 x 2.6 studs.
- Eyes and pupils as on every Rok (SmoothPlastic 245 / 20).

Uploaded 2026-10-25 through Open Cloud as group Model assets: Champ 120952354620681, Kingy 98416484211121. Loaded into `ReplicatedStorage.Assets.Models.Roks` as `Model_Rok_Champ` / `Model_Rok_Kingy` (PrimaryPart the body, pivot at bottom centre on the origin, front -Z, anchored), with `AssetRegistry` entries, and `PetConfig` now points at them instead of Bloky's and Starry's models. Seen in Play: both on base pedestals (facing out, sitting flat), Kingy at 3x on `Workspace.ExclusiveStand` facing the aisle, and both icons in the Roks panel. Not checked: the held tool and the hatch reveal.

Kingy's income (`PetService` `updateIncome`): 3x the best non-exclusive Rok's **base** $/s, ignoring its modifier, with a 100 $/s floor (so with only forest Roks he shows $100/s). Decided 2026-10-27 (user: "pick whichever is better for balancing"). Counting the modifier, tried 2026-10-25, let one weather catch pay twice, once on the Rok and again tripled through Kingy, and a Zappy best Rok made Kingy 6x its base. Checked in Play: Starry → Kingy 9.44B, unchanged after Starry turned Zappy. Exclusives never take modifiers (see [[Weather]]). Icons: [[Item Icons]].

Kingy's gold aura (2026-10-27, user asked; look not yet approved): template `ReplicatedStorage.Assets.VFX.Rok.VFX_Rok_GoldAura` (registry key `VFX_Rok_GoldAura`), a `Body` part sized like a Rok body holding four pieces, all reusing already uploaded textures:
- `Glow`: Zappy's soft glow, gold, about 1.8x the body, locked to the part, `ZOffset` -1.
- `Glints`: Level Up star glints rising off the body.
- `Dots`: Level Up dots drifting up.
- `GoldLight`: a PointLight.

`PetConfig` `AuraKey` names it, and `Utils/RokAura.Attach` (server) copies it onto the body before `ScaleTo` in `PedestalService/Display` (pedestals and the exclusive stand) and `PetService/Tools` (Backpack/held). `ScaleTo` scales emitter size and speed but not light range, so `Attach` scales the light. Checked by value in Play: the stand (3x), pedestals (2x) and tools (0.6x) carry it, and Champ doesn't. The Hatch Reveal and UI previews are ViewportFrames, which can't show particles. Kingy refuses modifiers like Champ (a Zappy command on a Kingy left it plain).

Related: [[Bloky Reference]], [[Reuse Rok Eyes]], [[Roks Stay Rocks]], [[Robux Shop Plan Approved]]
