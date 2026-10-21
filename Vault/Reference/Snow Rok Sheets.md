---
description: 2026-10-20 six-view sheets for the six frost blue snow Roks (Hexy, Beanie, Cozy, Stacky, Climby, Starry); what to take from each.
type: reference
---
# Snow Rok sheets

Received 2026-10-20 from the sheet prompts in `assets/Roks/Snow/Prompts.md` (batch mode, `batch-model` skill). Copies in `assets/Roks/<Name>/<Name>_sheet.webp`. Front = the top-left view in every sheet (eyes facing out). Body frost blue 40, 150, 255 ([[Coloured Roks After Forest]]); the sheets render it lighter and more cyan, so take the colour from here, not the sheet. Eyes reused ([[Reuse Rok Eyes]]). Climby replaced Piney the same day so there's no Christmas Rok ([[Zones After Desert]]).

![[Hexy Reference Sheet.webp]]
![[Beanie Reference Sheet.webp]]
![[Cozy Reference Sheet.webp]]
![[Stacky Reference Sheet.webp]]
![[Climby Reference Sheet.webp]]
![[Starry Reference Sheet.webp]]

Take from them:
- **Hexy:** new body, an upright hexagonal pillar with chamfered top and bottom edges. Flat faces point front and back, so the side views show a corner, and the eyes sit on the front face. It's a little taller than it's wide. No prop.
- **Beanie:** Bloky body with a red knitted beanie: a dome with about ten broad vertical ridges, a thick ridged white cuff that's slightly wider than the body and sits just above the eyes, and a faceted white pompom on top. The beanie adds about 0.8 of the body's height.
- **Cozy:** Bloky body with a thick red-and-white striped scarf ring around it just below the eyes, slightly wider than the body. One tail hangs down the front right corner to the ground and ends in a red fringe. The earmuffs are a thin dark band arching over the top from side to side, with big faceted yellow muffs on the left and right faces at eye height.
- **Stacky:** a slightly taller Bloky body tapering to a narrower chamfered top, with a smaller chamfered rock on top (about half the width) and a black top hat with a red band, tilted. The sheet drew two rocks, not the three in the prompt; take the sheet.
- **Climby:** Bloky body. A dark grey strap rings the body below the eyes. A pickaxe (brown handle, grey head) is strapped diagonally across the back, with its head above the top left. An orange rope coil (four or five long loops) hangs over the top left edge down the left face and front-left corner. A brown pole with an arm at the top stands at the right side, and a dark lantern with warm yellow glowing glass hangs from the arm by a short chain.
- **Starry:** Bloky body with a thin yellow glowing ring tilted around it: low at front left, rising toward the back right. Six or seven small glowing stars sit on the ring, and one bigger star stands on a short stalk on top. None cover the eyes.

Build: all six in `assets/Roks/Snow/SnowRoks.blend`, one collection per Rok, laid out along X. The build script was a scratch file. Previews: `lineup_*.png` and per-Rok `<Name>_views.png`, both in the set folder. The views grids use the sheet's layout (front, back, left / right, top, 3/4) so each one can be compared side by side with its sheet. Compared 2026-10-20 and fixed: Hexy taller (1.18), Beanie's cuff and hat round from above, Cozy's 30 even stripes (spaced by arc length, so no wide stripe at the back) with bigger, higher muffs, Climby's pole touching the body and its rope a tight bundle at the front-left corner, and Starry's ring smaller and just under the eyes. Starry's ring stars are two crossed plates so they read as stars from the front and the sides; the sheet draws them face-on in every view.

Approved 2026-10-20. Climby was reduced before export: its rope went from about 1,500 triangles to 550 by building it as one continuous tube, with ring orientation carried along the path so it doesn't twist. Exported to `assets/Roks/<Name>/<Name>.fbx` and checked by re-import (min z 0 for all).

Meshes and colours (body 40, 150, 255 + `2022 Small Stud`; eyes and pupils as Bloky's). Size in studs (W x D x H):
- **Hexy:** new hexagonal body only, 212 tris; 2.2 x 1.9 x 2.4.
- **Beanie:** `Beanie_Hat` 255, 30, 30; `Beanie_Trim` 250, 250, 250 (cuff and pompom); 652 tris; 2.4 x 2.4 x 3.7.
- **Cozy:** `Cozy_ScarfRed` 255, 30, 30; `Cozy_ScarfWhite` 250, 250, 250; `Cozy_Muffs` 255, 210, 0; `Cozy_Band` 20, 20, 20; 1,188 tris; 3.0 x 2.5 x 2.4.
- **Stacky:** new taller body; `Stacky_Rock` body colour; `Stacky_Hat` 20, 20, 20; `Stacky_Band` 255, 30, 30; 396 tris; 2.0 x 2.0 x 3.5.
- **Climby:** `Climby_Strap` 90, 90, 90; `Climby_Wood` 130, 75, 35 (pick handle and pole); `Climby_PickHead` 140, 140, 140; `Climby_Lantern` 60, 60, 60; `Climby_Glass` 255, 200, 60 Neon; `Climby_Rope` 255, 120, 0; 1,102 tris; 3.0 x 2.4 x 2.4.
- **Starry:** `Starry_Ring` (ring and top stalk) and `Starry_Stars` 255, 215, 0 Neon; 1,152 tris; 3.0 x 3.2 x 3.0.

Uploaded 2026-10-20 through Open Cloud as group Model assets: Hexy 124497951124960, Beanie 80259752841647, Cozy 136656825775141, Stacky 117972580337497, Climby 96194390153118, Starry 102821703384722. Loaded with `InsertService:LoadAsset` into `ReplicatedStorage.Assets.Models.Roks` as `Model_Rok_<Name>`, with `AssetRegistry` entries. Set up like the ocean six: PrimaryPart is the body, pivot at bottom centre on the origin, front faces -Z, all parts anchored. Bodies (and `Stacky_Rock`) are Plastic + `2022 Small Stud`; props are SmoothPlastic; `Climby_Glass`, `Starry_Ring` and `Starry_Stars` are Neon. In config 2026-10-20: `PetConfig` (Cozy at $120M per [[Balance Pass Oct 18]]), the Snow Geode (see [[Geode Shop]]) and the Index's Snow Roks zone. Not playtested yet.
