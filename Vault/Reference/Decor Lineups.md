---
description: 2026-10-28 ChatGPT lineup sheets for the 12 zone decor props (A: pine, bush, stump, mushroom, cactus, prickly pear; B: palm, leaf plant, kelp, coral, starfish, snow pile); used for parts and proportions; the models are in the ForestTree block style
type: reference
---
# Decor lineups

Made from the cartoon prompts in `assets/Decor/Prompts.md` with no images attached ([[Decor Without References]]). Copies are in `assets/Decor/LineupA.png` and `LineupB.png`. Top row front, bottom row 3/4 (nearly the same angle, so depth is a guess). Props aren't to scale.

The sheets are smooth cartoon renders, but the models are built in the `ForestTree` block style ([[Decor In ForestTree Style]]). Take the parts, proportions and colours from the sheets, not the finish. Models: `tools/meshlab/models/Decor*.luau` (13 with `DecorSnowPine`), contact sheet `tools/meshlab/out/DecorSheet.png`. Smooth and low-poly faceted versions built in side sessions were dropped. Copies of them are kept only in that day's scratchpad.

## Lineup A: shared, forest, desert
![[Decor Lineup A.png]]
Pine: four stacked cones with wavy scalloped rims and a short dark brown trunk. Bush: one big ball with smaller balls clumped round it. Stump: flared base with root toes, light tan top with rings. Mushroom: red dome cap with big white round spots, short cream stem. Cactus: saguaro with soft ribs, the lower arm on the viewer's left (+X). Prickly pear: oval pads growing from each other, magenta flowers on the tips.

## Lineup B: jungle, ocean, snow
![[Decor Lineup B.png]]
Palm: curved ringed trunk, broad drooping fronds with notched edges, coconuts under the crown. Leaf plant: broad pointed leaves with a centre vein, fanning up. Kelp: three wavy olive ribbons with small float bulbs. Coral: pink antler-like branching with rounded tips. Starfish: plump and low, with light dots. Snow pile: a low white drift of rounded lumps, icy blue underneath.

Related: [[Meshlab]], [[Keep Decor Simple]]

## Lineups C and D: zones 6-10 (2026-10-29)
The prompts are in `assets/Decor/Prompts.md`. Copies of the sheets are in `assets/Decor/LineupC.webp` and `LineupD.png`. The user asked for the existing models to be used as the style guide, along with the sheets.

### Lineup C: swamp, savanna
![[Decor Lineup C.webp]]
Take these from the sheet:
- **Cattails:** thin reeds, fat brown sausage heads with a spike, long leaves bending out.
- **Lily pads:** three flat pads with a notch, and a pink flower on the biggest.
- **Dead tree:** a thick crooked trunk with root flares and forked bare limbs.
- **Acacia:** a slim Y-forked trunk under one wide, flat, thin canopy.
- **Grass tuft:** a fan of golden blades bending at the tips, with a couple of seed stalks.
- **Termite mound:** a lumpy terracotta base and two chimney towers with holes.

### Lineup D: bamboo, volcano, ruins
![[Decor Lineup D.png]]
Take these from the sheet:
- **Bamboo:** a lime clump with ring joints and small pointed leaves.
- **Mossy stone:** a low grey boulder under a thick drippy moss cap.
- **Vent:** a charcoal cone with a glowing orange hole (the smoke is a particle emitter).
- **Broken pillar:** a square plinth, a column with a jagged break, and a vine spiralling up it.
- **Statue head:** lying on its side, with a heavy brow, closed eyes, a long flat nose and moss on top.
- **Rune stone:** a rounded-top slab with a purple glowing rune.

The models are in [[Meshlab]] (Zone decor 6-10). These are reused or recoloured instead of getting a slot:
- Swamp: Stump, Mushroom and the Bush, as `SwampBush`.
- Volcano: `CharredTree` (the Dead Tree) and `AshPile` (the Snow Pile).
- Bamboo: `BambooShoot`, a short Bamboo wrapper.

The arena gets no props for now (user, 2026-10-29).
