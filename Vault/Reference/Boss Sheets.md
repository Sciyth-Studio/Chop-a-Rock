---
description: 2026-11-10 six-view sheets for the three world bosses (Big Croc, Boulder Crab, Frost Yeti), the approved Blender build, Motor6D rigs in Studio, and 27 animation clips (9 per boss, uploaded 2026-11-11) with a floor check.
type: reference
---
# Boss sheets (2026-11-10)

Sheets from the prompts in `assets/Bosses/Prompts.md`, after the lineup `assets/Bosses/Lineup.webp`. The front is the top-left view on all three. Copies are in `assets/Bosses/<Name>/<Name>_sheet.webp`.

## Big Croc
![[Big Croc Reference Sheet.webp]]
- Long and low: about 4 times as long as tall. Dark green back, lime belly, lime underside on the tail.
- The lime lower jaw is wider than the snout, with white teeth pointing **up** from its edge.
- Eyes on two bumps on top of the head, dark brows slanting down to the snout.
- One row of dark ridges down the middle of the back and tail, smaller ones beside it on the body.
- Upper legs are tall blocks with the orange weak spot on the outer face.

## Boulder Crab
![[Boulder Crab Reference Sheet.webp]]
- The grey boulder shell covers most of the body. Moss is a few small flat patches.
- Eyes sit at the shell's front lower edge on short red stalks, under a rock brow.
- Huge claws held in front, tips pointing in. The lower pincer is its own piece.
- The sheet draws the cyan weak spots on the top segment of the back legs, not on the body, and shows only four or five legs clearly. The model has six legs, with spots on the back two each side.

## Frost Yeti
![[Frost Yeti Reference Sheet.webp]]
- Wider than tall across the fists. Short legs, fists hang at about knee height.
- Navy face, jaw, chest plate, lower back, fists and feet; pale blue fur as big faceted lumps.
- Thick white horns curving up, ice spikes behind the shoulders, tusks up from the lower jaw.
- Weak spots: both sides of the belly beside the chest plate, and both knees.

## The build (first pass, waiting on the user's feedback)
- `assets/Bosses/build_bosses.py` rebuilds all three in `assets/Bosses/Bosses.blend` (run it with `exec` through the Blender MCP; set `ONLY = {"FrostYeti"}` in the namespace to rebuild one). One collection per boss. Front is -Y, +X is the boss's left.
- **One mesh per rig piece**, named `<Boss>_<Piece>`, coloured with a `Col` vertex colour attribute (part colour white in Studio). Each object carries custom properties `joint` (hinge point, boss-local Blender units), `parent` (piece name or `Root`) and `kind`. The Studio rig script will read these as its hinge list ([[LihFolk Vault]], "V2 and rigging").
- Separate objects for things code changes: `<Boss>_WeakSpot1`-`4` (Neon, with `centre` and `normal` properties), `<Boss>_Eyes` and `<Boss>_Pupils` (the eyes turn red when the boss gets mad).
- Eyes are Bloky's meshes scaled up evenly (2.4 to 2.6x), each eye moved apart. The angry look comes from a brow wedge on the head piece that covers the eye's top inner corner.
- Pieces: Croc 19 (Body, Head, Jaw, 4 legs x Upper/Lower/Foot, Tail1-4), Crab 28 (Body, Shell, 2 x Claw1-3 + Pincer, 6 legs x 3), Yeti 16 (R15 names plus Jaw). Triangles: Croc 1,940, Crab 1,204, Yeti 1,628.
- Size in Blender units (W x D x H): Croc 7.5 x 17.7 x 4.7, Crab 12.5 x 11.4 x 6.4, Yeti 11.9 x 6.2 x 11.2. Stud size is not decided.
- Gotchas: `bmesh.ops.convex_hull` leaves inside points as loose vertices, so the script's `hull` deletes them. Painting hull faces for moss gave patches far too big; small hex plates placed by a ray cast onto the shell read better.

## Second pass (2026-11-10, after Claude's own critique; waiting on the user)
- Croc: deep skull in two steps (cranium, snout), thick jaw, lump upper legs with bent lower legs and clawed feet, belly at 0.45, stepped tail sections. Yeti: head lower and forward, fur tufts (`tufts`) on shoulders, wrists, ankles, back and head, curved horns (`chain`), chunky crystals. Crab: shell is five overlapping rough lumps, eyes in a dark rock socket on the Shell piece, weak spots tilted up and out.
- Brows now cover the eye's top inner third (`brow_pts`); lower than that hid the eyes on the Crab.
- `preview.py` has `shot`, `pose(boss, {piece: (axis, degrees)})` and `rest`; `pose` turns each piece about its stored `joint`, so it also checks the hinge data. One strong pose per boss showed no gaps.
- Triangles: Croc 1,242, Crab 1,248, Yeti 1,976. Size (W x D x H): Croc 8.1 x 18 x 4.5, Crab 12.5 x 11.8 x 6.8, Yeti 12.5 x 7.7 x 11.
- The piece counts and names above are unchanged, except the Crab's eyes hang off `Shell`, not `Body`.

## Method for the third pass (found 2026-11-10)
The user's real limit is about 10,000 triangles per boss, and passes 1 and 2 (convex lumps, 1.2-2k) were too coarse. No installed, claude.ai or directory skill covers creature modelling; the method is in [[LihFolk Vault]] section 45: `Low-Poly Creature From a Flat Reference Sheet`, `Matching a Concept Sheet - Boss Creature Case Study` and `scripts/build_wolf_v3.py`, `build_void_owl.py`.
- Loft body sections traced from the side view (superellipse rings from a table of x, top, bottom, half-width), add limbs as tubes and tufts as cones, all overlapping.
- Fuse with a voxel remesh, smooth, decimate to a target count with symmetry, then carve: triangulate, `dissolve_limit` about 5 degrees, triangulate.
- Colour faces after carving by region tests, then a neighbour majority filter to remove sliver faces. Markings are colour, not geometry.
- Compare every render with the sheet at the same angle, plus a flat black silhouette render.
- Trap: after a dissolve or delete, `bm.from_mesh` reuses freed face slots, so `bm.faces[n0:]` is not the new faces. Tag old faces first. (`Piece.add` in `build_bosses.py` uses the index range; safe only while nothing is deleted from that bmesh.)
- Studio's own `rbx-import-asset` skill covers the upload and import check for step 6.

## Third pass (2026-11-10, waiting on the user)
- `build_bosses.py` is now the fuse-and-carve script (`build_bosses_pass2.py` and `Bosses_pass2.blend` keep the old one). Each rig piece is a list of overlapping primitives (`ball`, `loft` of `sring` sections, `tube`, `solid`) fused by a 0.07 voxel remesh, smoothed, decimated to `density` triangles per square unit and carved at 5 degrees. A face takes the colour of the nearest primitive; `paint` and `region` recolour after that (lime belly, moss, navy back).
- Crisp parts (teeth, horns, crystals, fins, brows, weak-spot frames, eye sockets) are `detail` hulls added after carving, so they keep sharp edges.
- Only the left side is built. `Boss.finish` mirrors every `Left*` piece and its weak spot to `Right*`.
- Density sets facet size: 7 for the Croc and Crab limbs, 4.5 for the Yeti, 3 for the Crab's shell. Smaller numbers give the bigger facets the sheets have.
- Triangles: Croc 2,843, Crab 3,312, Yeti 2,908. Size (W x D x H): Croc 7.3 x 19 x 4, Crab 11.2 x 11.5 x 6.6, Yeti 12.3 x 7.5 x 11.
- Same piece names and counts as before, so `preview.py` poses still work; one strong pose per boss showed no gaps.

## Boolean cuts (2026-11-10)
The user pointed at the `blender-3d-modeling` skill (`github.com/Andrew1326/dominations`, Apache-2.0). It is a general Blender Python cheat sheet (from_pydata, bmesh, modifiers, curves), not a creature method; its example scripts delete the whole scene, so don't run them in an open file. The one technique that helped was the Boolean modifier: `Piece.cut(pts, colour)` subtracts a hull after the voxel remesh (EXACT solver) and the cut faces take the cutter's colour. Used for the Crab's eye notch in the shell (eyes now sit inside it, replacing the dark box) and the Yeti's open mouth.

## Fourth pass (2026-11-10, waiting on the user)
Claude's critique of pass 3: built from spheres, so everything was blobby with small even triangles, where the sheets have big flat planes. Fixes, all in `build_bosses.py` (`build_bosses_pass3.py` and `Bosses_pass3.blend` keep the old one):
- **Facets:** `DENSITY` 3 (was 7), carve angle `ANGLE` 13 degrees (was 5), 3 smooth passes. The Crab's shell uses density 1.4.
- **Blocks:** `ball(..., e=)` makes a superellipsoid; e 2 is a sphere, about 3 a rounded box. Limbs, shoulders, fists, feet and the shell use 2.6 to 3.6.
- **Fur:** `scallops(...)` adds a ring of broad blunt lappets under each fur mass, fused in so they carve with it. Thin `tufts` read as icicles; smooth lumps read as snowballs.
- **Moss:** `Piece.plates` ray-casts onto the carved shell and lays irregular six-sided plates. Painting faces gave jagged stars.
- **Crab legs:** the upper segment now runs steeply down and out, so the weak spot sits on a face that points outward. With a near-level upper segment the only outward face is the end cap, which the next segment covers.
- `preview.py` has `silhouette(boss, tag, target, direction, scale)` (Workbench flat black on white).
- Triangles including eyes and weak spots: Croc 2,024, Crab 2,226, Yeti 2,532. Size (W x D x H): Croc 7.6 x 19.1 x 4.2, Crab 10.7 x 11.8 x 6.6, Yeti 12.5 x 8.1 x 11.

## Fifth pass (2026-11-10, waiting on the user)
User: "croc head and body don't seamlessly transition". `build_bosses_pass4.py` and `Bosses_pass4.blend` keep the previous state.
- **Joining two rig pieces without a step:** give both the same cross-section where they meet (the Croc's body front ring and head back ring are now both about 3.5 tall and 2.0 half-wide), overlap them by about a unit, and carry a shared detail across the seam (a fin on the head). A head turned 22 degrees still shows no gap.
- Croc: smaller, lower upper legs, feet with three separate toes, thicker tail. Moving the brow back past the eye's front face made it look surprised; the brow has to reach in front of the eyes.
- Yeti: cheeks brought forward level with the face, jaw tucked back, a fur block behind the jaw, extra back lumps and scallop rows, bigger crystals and feet, a narrower upper arm so the elbow shows. The navy back patch is now a fused solid, because painting it on triangles gave a ragged edge.
- Crab: shell main shape at e 2.1 with the side lumps kept below its top, so the silhouette is a dome. Moss plates now ray-cast each rim point onto the shell and sit 0.09 above it; at 0.035 they sank into the facets. Legs are longer and spread wider.
- Triangles including eyes and weak spots: Croc 2,052, Crab 2,243, Yeti 2,550.

## Approved and exported (2026-11-10)
The user approved the fifth pass. Exported with `rb.export_fbx(objs, path, studs_per_unit=3.0)`, body first, to `assets/Bosses/<Boss>/<Boss>.fbx`. **3 studs per unit is Claude's draft size**, not the user's call; `Model:ScaleTo` can change it in Studio. Checked by re-import (object count, min z 0, vertex colours on every piece):

| Boss | Objects | Triangles | Size in studs (W x D x H) |
|---|---|---|---|
| Big Croc | 25 (19 pieces, 4 weak spots, eyes, pupils) | 2,049 | 22 x 57 x 13 |
| Boulder Crab | 34 (28 pieces, 4 weak spots, eyes, pupils) | 2,243 | 32 x 35 x 20 |
| Frost Yeti | 22 (16 pieces, 4 weak spots, eyes, pupils) | 2,548 | 37 x 24 x 33 |

`<Boss>_rig.json` beside each FBX lists every piece (`mesh`, `name`, `parent`, `joint`) and the attached weak spots and eyes (`parent`, and `centre` / `normal` for weak spots), already in studs and Roblox axes (Roblox x, y, z = Blender -x, z, y). The Studio rig script should read these for its Motor6Ds. Not uploaded, not in Studio, no rig or animation yet.

**Size (user, 2026-11-10): 5 studs per unit.** At 3 the bosses looked like large enemies beside the roughly 90-stud Diamond Rock. Re-exported and re-checked at 5: Croc 37 x 96 x 21 studs, Crab 53 x 59 x 33, Yeti 62 x 40 x 55 (W x D x H); the `_rig.json` files are at 5 too. The sizes in the table above are the old draft.

## In Studio (2026-11-10)
- Uploaded with `upload_model.ps1`: Big Croc `116318283669231`, Boulder Crab `71149435528841`, Frost Yeti `97385998375973`. `LoadAsset` brought the parts in at their exported positions (no offset, front on -Z); the raw imports are kept in `ServerStorage.BossImports`.
- Rigs: `ReplicatedStorage.Assets.Models.Bosses.Model_Boss_BigCroc` / `BoulderCrab` / `FrostYeti`, registry keys of the same names. Each has an invisible anchored 4-stud `Root` (the `PrimaryPart`), the pieces renamed without the boss prefix (`Body`, `Head`, `LeftLeg2_1`...), one Motor6D per piece named after it and parented to it (Part0 the parent piece, C0 and C1 axis-aligned at the hinge point), `WeakSpot1`-`4` (Neon, `Normal` attribute), `Eyes` and `Pupils` on WeldConstraints, and an `AnimationController` with an `Animator`. Motor6Ds: Croc 19, Crab 28, Yeti 16.
- Pieces are white Plastic with `2022 Stud`; the vertex colours and studs both show, and the studs come out at world size like the floor.
- **Pivot gotcha again:** with `Root` as `PrimaryPart` the model pivots at Root's centre, 2 studs up, so `PivotTo` sank the previews. `Root.PivotOffset = CFrame.new(0, -2, 0)` puts the pivot on the ground.
- Checked in Edit by turning a few Motor6D `C0`s per boss: children, eyes and weak spots follow and return exactly. No animation clips, no boss service, not playtested.
- **User, 2026-11-10: the rigged bosses in the arena "look good".** Next would be the animation clips (idle, attack with `Tele` and `Hit` markers, the half-health clip); not started.
- `Workspace.BossPreview` (tagged `EditorOnly`) holds one copy of each in the arena, facing the gateway, for the user to look at. Delete it when no longer needed.

## Animation clips (2026-11-11, not seen by the user in game yet)
- `assets/Animations/Bosses/boss_clips.py` writes 27 clips, 9 per boss (`build`; `upload` sends only clips missing from `ids.json`, `upload <names>` re-sends named ones). Registry keys `Anim_Boss_<Boss>_<Clip>`, Animation instances in `ReplicatedStorage.Assets.Animations` (the place must be saved).

| Clip | Length | Markers | Use (WorldBossPlan 4.2-4.6) |
|---|---|---|---|
| Sleep | ~3 s loop | | the 30 s before the fight |
| Wake | ~3 s | `Roar` ~1.7 s | wake-up roar, start the camera shake on `Roar` |
| Idle | 2.7-4 s loop | | between attacks |
| Attack | 2.5 s | `Tele` 0, `Hit` 1.5 | Block round swing at a spot |
| Stomp | 2 s | `Tele` 0, `Hit` 1.0 | 75% Stomp Wave: spawn the red ring on `Hit` |
| BigAttack | 5 s | `Tele` 0, `Hit` 4.0 | jumps ~26 studs, hangs through the 4 s countdown, lands on `Hit` |
| Mad | ~3 s | | half-health "gets mad" |
| Dizzy | 1.5 s loop | | "Finish it!" |
| Defeat | ~2 s | `Land` ~0.9 | tumbles belly-up (Croc, Crab) or flat on its back (Yeti); poof it after |

- Moves: Croc rears with jaw open and snaps forward; Crab lifts both claws over its shell and slams them; Yeti raises both fists and slams them down in front with a crouch.
- Joint signs on these rigs (axis-aligned joints, front -Z, +X the boss's right): a forward piece (Head, Body, Claw1) tilts up with +rx, a hanging piece (legs, arms) swings forward with +rx, jaws open with -rx, a tail tilts down with +rx and swings to the boss's right with +ry, Body +rz rolls the boss onto its left side, LowerTorso +rx falls backward. `mirror()` copies Left poses to Right, flipping ry, rz and x.
- **Floor check:** `py -3 assets/Animations/Bosses/ground_check.py [filter]` runs forward kinematics on `rig_boxes.json` (rest boxes and joints pulled from Studio) and prints each clip's deepest dip below the rest pose. Box corners overstate rotated pieces by up to about 2 studs, so only bigger dips are real. It caught what the screenshots missed: the Croc's roaring jaw 8 studs into the floor, Crab claws when lowered (their tips rest near the floor, so hit with the body tilt, never by dropping `Claw1`), and rolls and falls that need the body raised mid-roll.
- When the body rears, lift the tail (negative rx). Keep Body / LowerTorso lifts under 1 stud unless the boss is meant to leave the ground.
- Visual preview without uploading: `preview_luau.py <Boss> <out.luau> '{"Attack":[1.4,1.5]}'` writes a call to the Edit-only `ServerStorage.BossAnimPreview` module (frames along Z at x 1500, clips stacked up); run the file's text with `execute_luau`, then `screen_capture` from +X. Uploaded clips can be posed straight from `Assets.Animations` instead.
- Superseded uploads (still in the group, unused): Croc Mad 111742672787473, Crab Attack 114987625242982, Crab Mad 80734988663941.
- Not built yet: knock-back reaction, per-boss signature-move tells (Chomp, Shell Hide, Frost). No boss service plays any of these yet.

Related: [[World Boss Research]], [[Boss Arena]], [[Reuse Pet Eyes]], [[Animation Uploads]]
