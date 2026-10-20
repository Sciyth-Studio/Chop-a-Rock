---
description: 2026-10-19 six-view sheets for the six coral orange ocean Roks (Drip, Bubbly, Shelly, Reefy, Glowy, Chompy); what to take from each.
type: reference
---
# Ocean Rok sheets

Received 2026-10-19 from the sheet prompts in `assets/Roks/Ocean/Prompts.md` (batch mode, `batch-model` skill). Copies in `assets/Roks/<Name>/<Name>_sheet.webp`. Front = the top-left view in every sheet (eyes facing out). Body coral orange 255, 95, 70 ([[Coloured Roks After Forest]]), eyes reused ([[Reuse Rok Eyes]]).

![[Drip Reference Sheet.webp]]
![[Bubbly Reference Sheet.webp]]
![[Shelly Reference Sheet.webp]]
![[Reefy Reference Sheet.webp]]
![[Glowy Reference Sheet.webp]]
![[Chompy Reference Sheet.webp]]

Take from them:
- **Drip:** new body, a faceted round drop. Near-spherical, widest just below the middle, slightly flattened base, short soft point on top. Eyes sit at mid-height and are a little bigger than on the other Roks. No prop.
- **Bubbly:** Bloky body with a cluster of about eight blue faceted bubbles on top: one big one high in the middle, mid-size ones around it, two or three small ones at the edges. The cluster is about 0.9 of the body's width and adds about two thirds of its height.
- **Shelly:** cream spiral shell lying at front left, lilac scallop shell standing at front right, a clump of five flat, branching green seaweed blades behind them, the tallest about as tall as the body.
- **Reefy:** two violet coral trees, one at each top corner toward the front, each a trunk forking two or three times into stubby branches with bright pink ball tips. They rise about the body's height and spread a little past its sides.
- **Glowy:** navy tube stalk from the top centre curving forward and to the Rok's left (viewer's right in the front view), ending in a cyan Neon faceted ball out in front and to the side. Three cyan Neon gill bars on each side face, near the front edge, standing slightly out.
- **Chompy:** the hood swallows the whole Rok. Take it as a rounded grey-blue shark shell around the body, with a white lip and white teeth framing a front opening where the orange face and eyes show. Small black shark eyes on the hood above the mouth corners, a dorsal fin on top with a cyan Neon back edge, a tail fin at the back, small side fins, and three cyan Neon gill bars per side. Built with a boxy hood instead (see below).

Build: all six in `assets/Roks/Ocean/OceanRoks.blend`, one collection per Rok, laid out along X for previews. Previews in `assets/Roks/Ocean/lineup_*.png`. The build script was a scratch file. Feedback (2026-10-19): Chompy's round sphere hood was "too round" and the body poked through it. The hood was rebuilt as a chamfered box the Rok body's shape: an outer box minus an inner box and a rounded-rect mouth, both booleans. That body copy is fully inside it (ray-checked). Gotcha: boolean cutters must sit at the hood's `location.x` in the lineup, or the cut silently misses. Approved and exported 2026-10-19 to `assets/Roks/<Name>/<Name>.fbx`, checked by re-import (min z 0 for all).

Meshes and colours (body 255, 95, 70 + `2022 Small Stud`; eyes and pupils as Bloky's). Size in studs (W x D x H):
- **Drip:** new body only, 242 tris; 2.3 x 2.2 x 2.5.
- **Bubbly:** `Bubbly_Bubbles` 0, 170, 255 (720 tris); 2.1 x 2.0 x 3.1.
- **Shelly:** `Shelly_Spiral` 250, 238, 222; `Shelly_Scallop` 180, 110, 255; `Shelly_Seaweed` 40, 190, 40; 2.0 x 2.0 x 3.4.
- **Reefy:** `Reefy_Coral` 140, 50, 255; `Reefy_Tips` 255, 40, 210; 2.7 x 2.0 x 3.4.
- **Glowy:** `Glowy_Stalk` 25, 40, 120; `Glowy_Lure` and `Glowy_Gills` 0, 230, 255 Neon; 2.3 x 2.3 x 2.9.
- **Chompy:** `Chompy_Hood` and `Chompy_Fins` neutral grey 140 (not the sheet's slate blue, per [[Literal Black And Grey]]); `Chompy_Teeth` 250 (lip and teeth); `Chompy_SharkEyes` 20; `Chompy_Glow` 0, 230, 255 Neon (gill bars and the dorsal fin's back edge); 2.9 x 3.1 x 3.5. The body inside is hidden.

In Studio (2026-10-19): uploaded through Open Cloud as group Model assets (Drip 97938199223715, Bubbly 129831073837229, Shelly 85885708776235, Reefy 76092713222124, Glowy 70635783618375, Chompy 94804153761330). Loaded with `InsertService:LoadAsset` into `ReplicatedStorage.Assets.Models.Roks` as `Model_Rok_<Name>`, with `AssetRegistry` entries. Set up like the jungle six: PrimaryPart is the body, pivot at bottom centre on the origin, front faces -Z, all parts anchored. Body Plastic + `2022 Small Stud`; props SmoothPlastic; `Glowy_Lure`, `Glowy_Gills` and `Chompy_Glow` Neon. In `PetConfig`, the Ocean Geode and the Index Roks page since 2026-10-19 ([[Geode Shop]]).
