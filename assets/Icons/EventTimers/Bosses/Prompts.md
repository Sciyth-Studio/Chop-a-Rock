# Boss face icons: ChatGPT prompts (2026-11-11)

One face icon per world boss, for the boss timer tile (bottom right, `EventTimerConfig.Icons`) and the 7-face boss strip (`WorldBossPlan.md` 3.1). They replace the generic boss fist on the tile. Shown at 92 px, so each face has to read at a glance: big eyes, one strong silhouette, nothing fiddly.

How to run: in ChatGPT image generation, attach `../IconReferenceSheet.png` (the style) and `assets/Bosses/Lineup.webp` (the bosses) and paste one prompt per chat. Ask for a transparent PNG. Save the results here as `BigCroc.png`, `BoulderCrab.png` and `FrostYeti.png`; Claude cleans them to 512 px, bakes the black outline with `tools/icons/bake_outline.py` and uploads them.

All three use the same framing (head and shoulders, 3/4 view turned to the viewer's left, face filling the icon) so they line up in the strip. The bosses are grumpy cartoon villains, but the icons are for 10-year-olds: goofy grumpy, not scary.

---

## 1. Big Croc (`BigCroc.png`)

```
Make one new game icon in exactly the same style as the first attached image (the icon sheet): flat-colour chunky 3D cartoon shapes, a slightly darker side face for depth, small white highlight slivers, bright saturated colours, no outline, no text, no background. Match the shading and level of detail of the sheet; it must sit next to those icons as part of the same set.

Subject: the head of the BIG CROC, the first monster from the left in the second attached image (the boss lineup). Copy its design and colours, but draw it in the icon sheet's flat style, not as a 3D render. Head and the very top of the shoulders only, in a 3/4 view turned slightly to the viewer's left. Dark green head with a big wide lime-green lower jaw, a row of chunky white triangle teeth poking UP from the jaw, two eye bumps on top of the head. Big square white eyes with black square pupils and a small white glint, under thick dark green brows slanting down toward the snout: a grumpy, goofy cartoon scowl, not scary. Two or three dark green back spikes peeking up behind the head. Keep the snout short enough that the whole head fits as a chunky, nearly square shape.

Square 1:1 image, the head centred and filling about 85% of the frame, fully transparent background, no shadow on the ground, no glow halo around the edges.
```

## 2. Boulder Crab (`BoulderCrab.png`)

```
Make one new game icon in exactly the same style as the first attached image (the icon sheet): flat-colour chunky 3D cartoon shapes, a slightly darker side face for depth, small white highlight slivers, bright saturated colours, no outline, no text, no background. Match the shading and level of detail of the sheet; it must sit next to those icons as part of the same set.

Subject: the face of the BOULDER CRAB, the middle monster in the second attached image (the boss lineup). Copy its design and colours, but draw it in the icon sheet's flat style, not as a 3D render. Front and top of the crab only, in a 3/4 view turned slightly to the viewer's left: a big round faceted grey boulder shell on top with two small flat green moss patches, and under its front edge a bright red-orange face. Big square white eyes with black square pupils and a small white glint, on two short red stalks, under a jagged grey rock brow slanting down toward the middle: a grumpy, goofy cartoon scowl, not scary. The tips of the two big red claws raised in front, one on each side of the face, closed, not covering the eyes.

Square 1:1 image, the crab centred and filling about 85% of the frame, fully transparent background, no shadow on the ground, no glow halo around the edges.
```

## 3. Frost Yeti (`FrostYeti.png`)

```
Make one new game icon in exactly the same style as the first attached image (the icon sheet): flat-colour chunky 3D cartoon shapes, a slightly darker side face for depth, small white highlight slivers, bright saturated colours, no outline, no text, no background. Match the shading and level of detail of the sheet; it must sit next to those icons as part of the same set.

Subject: the head of the FROST YETI, the third monster from the left in the second attached image (the boss lineup). Copy its design and colours, but draw it in the icon sheet's flat style, not as a 3D render. Head and the top of the shoulders only, in a 3/4 view turned slightly to the viewer's left. A dark navy face framed by chunky pale ice-blue fur tufts, two thick curved white horns pointing up, two short white tusks pointing up from the lower jaw, and two or three small bright cyan ice crystals sticking up behind the shoulders. Big square white eyes with black square pupils and a small white glint, under a heavy pale-blue fur brow slanting down toward the middle: a grumpy, goofy cartoon scowl, not scary.

Square 1:1 image, the head centred and filling about 85% of the frame, fully transparent background, no shadow on the ground, no glow halo around the edges.
```
