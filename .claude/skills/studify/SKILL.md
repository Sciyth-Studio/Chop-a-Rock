---
name: studify
description: Use when building something for Chop a Rock out of Studio parts rather than a Blender mesh - fences, crates, stalls, signs posts, lanterns, bridges, paths, hills, simple trees, decor scatter, a lobby or zone layout blockout - or when placing, fitting or cleaning up part builds (z-fighting, gaps between parts, floating or sunken props, doors and windows that show slits). Covers the survey-first rule, the stud MaterialVariant map, the grid and scale ruler, seams by overlap, the layout blockout hand-off for maps, part recipes and the coplanar sweep. Not for Blender models (use model-workflow) or UI (use studio-ui).
---

# Stud-style part builds

Adapted from the downloaded `studify` skill (2026-10-27), cut down to fit this project's vault. The rules here are for things built from `Part`, `WedgePart`, `CornerWedgePart`, `TrussPart` and the occasional union. Rocks, Roks, stalls, stands and anything else that comes from Blender stay on `model-workflow`; they sit alongside part builds and are not banned.

Read first: vault [[Keep Decor Simple]], [[Studs On Models By Default]], [[Tintable Mesh Textures]], [[Zone Line]] (zone colours), [[Ask The User To Look]], [[No All Caps In UI]] (sign text too). When the job matches a group in `references/INDEX.md`, open 3-6 of those reference images before building and treat them as the target for silhouette, colour balance and prop vocabulary.

## How much to build

[[Keep Decor Simple]] wins over everything below. Decor is few pieces, primitive shapes, reused and recoloured between zones. The fit rules (no gaps, no z-fighting, nothing floating) apply to every build however small; the detail rules apply only as far as the user asked for.

- Gameplay furniture (pads, buttons, the rock spawn area, collect pads) stays simple: players read it as UI.
- A prop players stand next to (a stall, the entrance sign) gets a mid-detail pass: frames, trim, a sill. Scatter far from the path gets none.
- If unsure how detailed something should be, propose a part count and wait.

## Materials: the stud variant map

Survey `MaterialService` first and use only variants that exist there. The current roster (see [[Tintable Mesh Textures]]): `2022 Inlet`, `2022 Stud` (outlet), `2022 Big Stud`, `2022 Small Stud`, `2022 Universal`, `2022 Weld`, `2022 Diamond Stud`, `2022 Glue`.

Every part: `Material = Enum.Material.Plastic`, `MaterialVariant` from the map below, faces `Smooth`, colour on `Color`. Decide the map by role before the first part and apply it uniformly: every copy of a repeated element gets the same variant.

| Role | Variant |
| --- | --- |
| Default for any part (walls, props, caps) | `2022 Inlet` |
| Floors, plates, the tops players walk on | `2022 Stud` |
| Big fills where 1-stud studs look busy (hill masses, long walls) | `2022 Big Stud` |
| Posts, rails, frames, crates when the user wants the X look | `2022 Weld` (ask first; Inlet is the default) |
| Parts under ~0.5 studs in every dimension (handles, bolts, petals) | none: plain Plastic |

- `2022 Glue` is not used.
- Neon is an accent only: thin glow strips, a glow pad under a hero prop, a lamp core. Neon parts get no variant. If a Neon part is thicker than trim, it's wrong.
- No other materials (Wood, Brick, Glass, SmoothPlastic). Windows are plain Plastic in a pale sky colour, opaque or Transparency 0.2-0.4, always with something opaque behind them.
- Unions take the variant like any part. Use them only for shapes steps can't make (arches, punched openings, rounded cutouts), never to cut part count: a union costs more than the parts it replaced.

## Colour

Colours come from the zone's palette in [[Zone Line]], not from the reference images' pastels. Pick 5-8 colours per build including one accent, and keep them uniform within the zone. One leaf colour per tree, varied between neighbouring trees. Rocks in a pile pick a different tone each from the zone's cliff colours. A zone reskin recolours the same build; it doesn't re-lay it out.

## Grid, rotation and scale

- Sizes and positions in 0.1-stud steps. Massing (floors, walls, layout) in whole studs; trim, sills and plates 0.2-0.5 thick. Finer than 0.1 only for the anti-z-fight offsets.
- Rotations in 15° steps, used with intent (a roof pitch, a leaning sign), never random jitter.
- Ruler: a character is ~5 tall and 3-4 wide. Doorways 7-8 tall x 4-5 wide with the frame; counters 2.5-3; seats ~1.5; fences and railings 3-4; handheld props 1-3. Stay on this ruler unless the user asks for a different scale, then rescale everything.

## Survey first, every time

Before the first part, read the build area with `execute_luau` and work only from what it returns:

```lua
local parts = workspace:GetPartBoundsInBox(CFrame.new(cx, cy, cz), Vector3.new(w, h, d), OverlapParams.new())
local out = {}
for _, p in parts do
	table.insert(out, { p:GetFullName(), { p.Size.X, p.Size.Y, p.Size.Z }, { p.CFrame:GetComponents() } })
end
print(game:GetService("HttpService"):JSONEncode(out))
```

- Any number that can be read from the place is read from it: ground top Y, zone bounds, a wall's face. Store them in named locals (`groundY`, `zoneCenter`) and derive everything from those.
- Attaching to a rotated part uses its CFrame (`existing.CFrame * CFrame.new(offset)`), never world-axis maths.
- Re-survey after the user edits anything by hand, including a blockout they adjusted.
- Never move, resize or delete anything you didn't create.

## Fit: the rules that apply to every build

- **No coplanar faces on any axis.** Two parts that touch or overlap must not share a face plane in X, Y or Z; same-height tops (Y) are the most common miss. Make one 0.0001 bigger (`1.7` vs `1.7001`). Trim, bands and caps sit proud of their wall by 0.05+, never flush.
- **Close seams by overlap, never by inset.** Never leave a 0.05-0.3 gap to dodge z-fighting: from player height it reads as a bright crack. Embed the part 0.1-0.3 into its neighbour and make the sizes differ by 0.0001.
- **Openings are sealed.** A door or window has head, both jambs and a threshold or sill, each overlapping 0.1 into the wall around it; the leaf or pane overlaps 0.1 into the frame. Something opaque fills the space behind. A door leaf is a framed panel (stiles, top, mid and bottom rails, inset panels), not a bare slab.
- **Walls go around openings**, built in strips or negated with a union. Never push a window through an unbroken wall.
- **Separate things never clip.** Inside one model, parts may sink into each other to make its shape (tree tiers, a rock's slabs, a chain of path tiles). Between models (a crate and a wall, a prop and the ground) they rest on each other with the 0.0001 offset.
- **Everything is anchored to something.** Name what holds each accent up; supports are chunky, not toothpicks. Signs and magic pieces may float when that's the design; ask first.
- **Hanging lines** (ropes, wires, bunting): segments along a sagging polyline with `CFrame.lookAt(p1, p2)`, each sized `(p1 - p2).Magnitude + 0.2` so joints overlap, both ends embedded 0.2 into their anchors.
- **Accidental steps get a wedge.** Where two tops of different heights meet and the step isn't a feature, cap it with a `WedgePart`.
- **Transparent parts:** one layer per line of sight, edges embedded 0.1-0.2 into what's around them.

Run `references/coplanar-sweep.luau` on the finished model before calling it done, fix every hit, and rerun until it reports none.

## Maps and layouts: blockout first

For a whole area (a lobby section, a zone's decoration layout, a plaza), don't build straight away:

1. Lay one flat-coloured anchored box per element under a `Blockout` model, named for what it becomes (`BLOCKOUT_Stall`, `BLOCKOUT_Path`, `BLOCKOUT_Hills`). Walking distances and spacing are decided here.
2. Hand it over: one `screen_capture` from above, a list of what each block is, then stop. The user moves, resizes and deletes blocks in Studio.
3. When they say go, re-survey the blockout's real positions and build to them, replacing each block as its real version lands.

Single props skip this.

- Layouts don't sit on one plane: a step up, a raised ledge, a terrace with a wedge ramp. Zone floors and terraces themselves belong to `new-zone`.
- Props sit where they'd be used (the bucket by the well, crates by the stall), and effects need their cause (moss under the drip line, wear on the step that's walked on).
- Keep paths and the rock spawn area clear of props.

## Recipes

Each recipe is one Model of its parts. Build trees, fences and rocks in one zone from one parameterised function, varying only height (±20%) and shade, so they read as a set.

- **Ranch fence:** square posts ~1 x 3 x 1 every 5-7 studs, two rails 0.5-0.8 thick (top rail a little below the post tops, lower rail around mid-height), rails embedded into the posts. Two wood tones, posts vs rails. Nudge post heights ±0.1-0.2.
- **Path:** a chain of 4-stud tiles 0.3 thick along the route, two-tone by grid parity, edges stepping naturally; or overlapping dirt-tone rectangles of varying width, each offset half a stud from the last. No border rails.
- **Rock (decor):** 2-4 slabs stacked with overhanging edges, each at a different 15° yaw, clipped into each other, resting on the ground. For anything players chop, use `rock-model`.
- **Hill or border mass:** 2-4 overlapping blocks of different heights in the zone's cliff colours, some yawed 15°, each capped with an overhanging floor-colour slab (1.2-2.4 thick, 1-2 overhang). Runs of one big mass with smaller shoulders clipping into it, one model per run. `2022 Big Stud` on big faces.
- **Tree:** one recipe per zone. Blob tree: 2-4 cubes clustered on a short square trunk. Tiered pine: stacked shrinking slabs centred on the trunk (widths like 8, 5, 7, 4, 2). Palm or dead tree for the zones that suit them. No balls or cylinders for canopies. Few and large beats many and small.
- **Grass tuft:** 3-5 blades 0.2-0.4 wide, 0.8-1.6 tall, a deeper green than the ground, fanning out at 15°.
- **Ground flower:** five 0.4-thick blocks in a plus shape, contrasting centre.
- **Stall:** 4 posts, counter, two-colour striped awning, sign above.
- **Stepped roof:** rows of 1.2-tall slabs, each 2 studs narrower than the last, first row overhanging the walls by 1-2; 4-7 rows. Not two big wedges.
- **Checker tint on big ground slabs (optional):** a `Texture` on the top face, 2 x 2 checker image, `StudsPerTileU/V = 8`, `Transparency = 0.8`, one per slab. Never fake it with coloured plates.

## Copying a reference

When the user says "make it like this image":

1. Crop it into 4-6 regions with PIL in the scratchpad, upscale 2x, and read how each part is actually built.
2. Sample colours (5 x 5 median, away from shadows), then snap them to the zone palette unless the user wants the reference's colours.
3. Count studs on close crops for real sizes.
4. After building, capture at the reference's camera angle and list every difference against the image itself, not against your plan. Fix and re-diff until the list is empty or the user accepts the rest.

## Building in Studio

```lua
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local MaterialService = game:GetService("MaterialService")

local recording = ChangeHistoryService:TryBeginRecording("Build StudFence")
local model = Instance.new("Model")
model.Name = "StudFence"

local function brick(size: Vector3, cframe: CFrame, color: Color3, variant: string?, props: { [string]: any }?)
	local p = Instance.new(props and props.Class or "Part") :: BasePart
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = Enum.Material.Plastic
	if variant and MaterialService:FindFirstChild(variant, true) then
		p.MaterialVariant = variant
	end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	for k, v in props or {} do
		if k ~= "Class" then
			(p :: any)[k] = v
		end
	end
	p.Parent = model
	return p
end

model.Parent = workspace
if recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end
```

- One named root Model, sub-Models per section (`Fences`, `Trees`, `Props`) and per repeated assembly (each tree, lamp, stall is its own Model).
- Positions come from shared dimension locals, not magic numbers. Name the parts that matter (`Door`, `RoofStep3`).
- Authoring-only copies get the `EditorOnly` tag; anything code reads stays untagged.
- Things the game reads by name go in `ReplicatedStorage.Assets` per [[Studio Assets Folders]].

## Checking it

1. Run the coplanar sweep until it's clean.
2. Run a collision check: `GetPartBoundsInBox` over the finished model's bounds, flag any part that isn't yours intersecting it.
3. One or two `screen_capture`s (three-quarter view, plus one at player height near doors or seams) for obvious problems: gaps, floating or sunken parts, wrong scale against a 5-stud character.
4. Then ask the user to look rather than looping on screenshots, per [[Ask The User To Look]], and remind them to save the place.
