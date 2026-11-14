# Boss move chop bar overlays: ChatGPT prompts (2026-11-11)

While a boss's signature move is on you, the chop bar gets covered:
- **Frost Yeti (Frost):** ice chunks freeze onto two parts of the bar.
- **Big Croc (Chomp):** a croc's jaws clamp down on the bar from above and below.
- **Boulder Crab (Shell):** stone slabs cover the parts of the bar that don't count.

The overlays draw above the bar's black outline. The cursor still draws above them, so you can always see it. Vault: Boss Bar Research, "Signature overlays".

**How to run them:**
- In ChatGPT image generation, paste one prompt per chat.
- Attach the files each prompt lists:
  - `assets/Icons/EventTimers/IconReferenceSheet.png`, the game's icon style.
  - The boss's own icon from `assets/Icons/EventTimers/Bosses/`, for its colours.
- Ask for a transparent PNG.
- Save the result in this folder under the name in the heading. Claude will clean them up, bake the outline, split the sheets, upload them and wire them in.

**Things every prompt asks for, and why:**
- **Straight-on front view, no perspective.** The art lies flat on a flat bar.
- **No outline.** Claude bakes the game's black outline in afterwards. A drawn outline would come out doubled.
- **No studs.** The game's own stud texture goes on top in Studio, so it matches the bar exactly.
- **Fully opaque pieces with clean edges.** ChatGPT tends to add soft glows and a haze, which make a grey fringe on the bar.
- **Pieces well apart on the sheet.** Claude cuts them out by finding each separate shape.

---

## 1. Ice chunks (`IceChunks.png`)
Attach: `IconReferenceSheet.png`, `Bosses/FrostYeti.png`

```
Make game UI art in exactly the same style as the attached icon sheet: flat-colour chunky 3D cartoon shapes, a slightly darker side face for depth, small crisp white highlight slivers, bright saturated colours, no outline, no text. Use the icy blues and whites of the attached yeti icon.

Subject: two separate chunks of solid ice, drawn side by side with a wide empty gap between them, both seen perfectly straight-on from the front (orthographic, no perspective, no tilt). Each chunk is roughly rectangular, about twice as wide as it is tall, but with irregular chipped, faceted edges: a few flat bevelled facets along the top edge, chipped corners, one or two shallow notches. They look like slabs of ice that froze solid onto something flat. Colour: pale icy cyan-white front face, slightly deeper blue facets on the bevelled edges, a few long diagonal white highlight streaks across the front, and a couple of faint frozen-in bubbles. The ice is solid and opaque, not glassy or see-through.

From the bottom edge of each chunk hang 5 to 7 chunky icicles of different lengths (the longest about half the chunk's height), pointing straight down, with sharp tips, the same ice colours and a white highlight line down one side. Make the two chunks clearly different from each other (different notches, different icicle lengths) but the same size.

Landscape 3:2 image. Fully transparent background, no shadow, no glow, no snow or sparkles around them, no frost haze. Hard, clean edges.
```

## 2. Ice shards (`IceShards.png`)
Attach: `IconReferenceSheet.png`, `Bosses/FrostYeti.png`

```
Make game UI art in exactly the same style as the attached icon sheet: flat-colour chunky 3D cartoon shapes, a slightly darker side face for depth, small crisp white highlight slivers, bright saturated colours, no outline, no text. Use the icy blues and whites of the attached yeti icon.

Subject: a sheet of 8 separate broken ice shards, the pieces left when a slab of ice shatters. Angular faceted chunks and splinters of different shapes: two big wedge chunks, three medium angular pieces, one snapped-off icicle tip, two small splinters. Pale icy cyan-white faces, deeper blue facets, a white highlight sliver on each. Seen straight-on, laid out in a loose grid with plenty of empty space between every piece so none touch.

Square 1:1 image. Fully transparent background, no shadow, no glow, no sparkles, hard clean edges.
```

## 3. Croc jaws (`CrocJaws.png`)
Attach: `IconReferenceSheet.png`, `Bosses/BigCroc.png`

```
Make game UI art in exactly the same style as the attached icon sheet: flat-colour chunky 3D cartoon shapes, a slightly darker side face for depth, small crisp white highlight slivers, bright saturated colours, no outline, no text. Use the greens of the attached crocodile icon.

Subject: a crocodile's upper jaw and lower jaw, drawn as two separate long horizontal pieces, one above the other with a wide empty gap between them, both seen perfectly from the side and straight-on (orthographic, no perspective). Each jaw is a long, chunky, slightly curved band that runs the full width of the image: a rounded blunt snout tip at the right end, a thicker cheek at the left end. The outside of each jaw is bright green with chunky square scale bumps along its outer edge and a darker green underside face; a few small nostril bumps on the top of the upper snout.

The teeth line the inner edge of each jaw, facing the other jaw: on the upper jaw they point straight down, on the lower jaw straight up. 12 to 14 big chunky triangular teeth per jaw, off-white with a light grey side face, alternating big and small, evenly spaced along the whole length, with a strip of pink gum showing between the jaw and the teeth. The teeth should be large and obvious, about as tall as the jaw band itself is thick.

Landscape 3:2 image, both jaws spanning nearly edge to edge. Fully transparent background (including the gap between the jaws and between the teeth), no head, no eyes, no body, no shadow, no glow, hard clean edges.
```

## 3b. Bite mark (`BiteMark.png`)
Attach: `IconReferenceSheet.png`, `Bosses/BigCroc.png`

When the zone jumps, this goes over its old spot for a moment, as if the croc bit that piece out of the bar. It's tall and narrow because it covers one zone-width of the bar.

```
Make game UI art in exactly the same style as the attached icon sheet: flat-colour chunky 3D cartoon shapes, a slightly darker side face for depth, small crisp white highlight slivers, bright saturated colours, no outline, no text.

Subject: a big cartoon bite mark, seen straight-on (orthographic, no perspective), shaped like a chunk bitten out of a flat bar. A tall rounded-rectangle hole, about 1.5 times as tall as it is wide. Its top and bottom edges are a row of deep zig-zag tooth notches (5 or 6 sharp triangular notches on each, like the bite of a crocodile), and its left and right sides are slightly ragged, torn edges. Inside the hole is a very dark, almost black purple-brown. Along the inner rim is a thin band of darker torn material with a few small chipped flakes breaking off the edges. Two or three tiny chunks fly off the corners, separate from the main shape.

Portrait 2:3 image, the bite mark centred and filling about 80% of the height. Fully transparent background, no shadow, no glow, hard clean edges.
```

## 3c. Chomp burst (`ChompBurst.png`)
Attach: `IconReferenceSheet.png`, `Bosses/BigCroc.png`

This pops where the jaws snap shut on each zone jump, and a smaller copy pops where the zone lands.

```
Make game UI art in exactly the same style as the attached icon sheet: flat-colour chunky 3D cartoon shapes, a slightly darker side face for depth, small crisp white highlight slivers, bright saturated colours, no outline, no text. Use the greens of the attached crocodile icon as the accent colour.

Subject: a comic-book impact burst for a crocodile's jaws snapping shut. A chunky jagged starburst with 8 to 10 uneven sharp points, white in the middle shading out to bright lime green at the tips. Around it, 6 short thick motion slashes point outward, and 4 small tooth-shaped white triangles fly away from the centre in different directions. Bold and readable at small size, seen straight-on.

Square 1:1 image, the burst centred and filling about 85% of the frame. Fully transparent background, no shadow, no glow halo, hard clean edges.
```

## 4. Stone slabs (`StoneSlabs.png`)
Attach: `IconReferenceSheet.png`, `Bosses/BoulderCrab.png`

```
Make game UI art in exactly the same style as the attached icon sheet: flat-colour chunky 3D cartoon shapes, a slightly darker side face for depth, small crisp white highlight slivers, bright saturated colours, no outline, no text. Use the stone greys and warm orange-brown accents of the attached crab icon.

Subject: three separate heavy stone slabs, laid out with a wide empty gap between each, all seen perfectly straight-on from the front (orthographic, no perspective). Each slab is a thick, blocky, roughly rectangular slab of stone with flat chiselled faces, bevelled edges showing a darker side face along the bottom and right, chipped corners, and two or three short dark cracks. Front faces are mid grey with a lighter top bevel; a few warm orange-brown pebbles or a thin orange-brown mineral vein in each. All three slabs are the same height but different widths: one almost square, one about 1.6 times as wide as tall, one about 2.5 times as wide as tall. They should look like they could slam down side by side and cover a strip.

Landscape 3:2 image. Fully transparent background, no shadow, no dust, no glow, hard clean edges.
```

## 5. Stone rubble (`StoneRubble.png`)
Attach: `IconReferenceSheet.png`, `Bosses/BoulderCrab.png`

```
Make game UI art in exactly the same style as the attached icon sheet: flat-colour chunky 3D cartoon shapes, a slightly darker side face for depth, small crisp white highlight slivers, bright saturated colours, no outline, no text. Use the stone greys and warm orange-brown accents of the attached crab icon.

Subject: a sheet of 8 separate broken stone chunks, the pieces left when a stone slab smashes. Blocky angular rocks with flat chiselled faces: two big chunks, three medium, three small pebbles. Mid grey faces, lighter top bevels, darker side faces, one or two with a small orange-brown fleck. Seen straight-on, laid out in a loose grid with plenty of empty space between every piece so none touch.

Square 1:1 image. Fully transparent background, no shadow, no dust, no glow, hard clean edges.
```

## 6. Cracks (`Cracks.png`)
No attachment needed. Used for both materials: tinted white on the ice and dark on the stone just before they break off.

```
Game UI texture: a single pure white crack pattern on a fully transparent background, like the cracks that spread across a pane of ice or a stone slab just before it shatters. One impact point slightly off centre, with 6 to 8 jagged main cracks spreading out to the edges of the image, a few short branches off each, and a small rough ring of crack around the impact point. Bold chunky cartoon lines with sharp zig-zag angles, thick near the impact point and tapering to thin at the ends. Pure white lines only, no shading, no grey, no glow, no texture, no background.

Landscape 2:1 image, the cracks reaching all four edges.
```
