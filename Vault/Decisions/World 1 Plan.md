---
description: 2026-10-29 - world 1 finishes with Swamp, Savanna, Bamboo Forest, Volcano, Golem Ruins plus an always-awake co-op Golem boss that opens world 2; numbers extend the existing rules; full plan in World1Plan.md.
type: decision
---
# World 1 plan (2026-10-29)

Approved by the user 2026-10-29. Full plan with every rock, Pet, geode and number: `World1Plan.md`. Not built.

- **Zones 6-10:** Swamp → Savanna → Bamboo Forest → Volcano → Golem Ruins. World 1 is "somewhat realistic biomes". The Volcano (last before the boss) may be fantastical, and Golem Ruins may use magic. Rejected: Autumn Woods, Cave, Mountains ("in a game filled with rocks, doesn't make much sense"), Beach (it belongs before the Ocean), Canyon (too like the Desert).
- **Numbers extend the existing rules** (x125 per zone, same geode and Pet income rules); see [[Zones After Desert]].
- **Stands:** Meteor, Sun, Black Hole, Galaxy after Cosmic.
- **Savanna Pets** use animal markings and props on rock bodies, which keeps [[Pets Stay Rocks]].
- **Pet names must not clash with weather modifier names** (Toasty, Zappy, etc.); the user rejected Toasty and Sparky for this.
- **Golem boss:** chop its glowing weak spots and dodge shockwaves; co-op; gated at zone 10's toughest rock; first win opens world 2 and gives the Golem Pet. **Never make a progression milestone wait on a timer** (user rejected a :15/:45 spawn clock): it's always awake, and only repeat loot has a ~5 min per-player cooldown.
- **No Baseplate limit:** it's beta only, so space is unlimited.
- **Build only after planning**, because zones are mostly recoloured parts.

Related: [[Rebirth Gated By Strength]], [[Auras]], [[Zone Line]], [[Diamond Rock]]

**2026-10-29 update:** zone signs are short and spoiler-free: "Bamboo Zone", "Ruins Zone". No player-facing label says "Golem". The boss arena is a fairly square walled courtyard, bigger than a zone, not round. The blockout is in [[Zone Line]].

**2026-10-31 rocks:** The user approved the look of the zone 6-10 rocks. Bodies are realistic muted stone ([[Realistic Rock Bodies]]), props are saturated, and everything is Plastic. Bodies use `2022 Inlet`. Base sizes are First about 10 x 8 studs, Second about 18 x 15, Third about 28 x 18, and `ZoneScale` applies on top. Each zone gets one ChatGPT sheet with all three rocks; the prompts are in `assets/Rocks/<Zone>/Prompts.md`. Smoke is a ParticleEmitter on a prop, and the break must turn it off (code change still needed).

| Rock | Body | Props |
|---|---|---|
| Muddy Rock | 115,95,70 | mud drips 85,60,35; reeds 110,150,40 |
| Reedy Boulder | 85,95,80 | cattail stalks 90,150,40, heads 120,70,30; lily pad 60,170,50, flower 255,120,180 |
| Rooty Boulder | 120,115,95 | roots 95,65,40 |
| Grassy Rock | 190,150,100 | dry grass 230,200,90 |
| Acacia Boulder | 165,100,65 | trunk 110,70,35; canopy 100,160,40 |
| Anthill Boulder | 140,110,85 | mound 190,105,60 |
| Shooty Rock | 120,130,125 | shoots 150,210,50 |
| Bamboo Boulder | 90,100,95 | stalks 170,220,60, nodes 120,170,40 |
| Pagoda Boulder | 150,145,130 | pagoda stone 205,200,185; roofs 200,50,40 |
| Smoky Rock | 85,80,80 | cracks 35,30,30; smoke particles |
| Ember Boulder | 60,50,50 | Neon cracks 255,120,0 |
| Crater Boulder | 110,70,55 | Neon crater 255,90,0; smoke particles |
| Rune Rock | 130,135,120 | Neon runes 170,80,255 |
| Pillar Boulder | 95,100,90 | column 220,215,200 |
| Statue Boulder | 175,165,140 | stone fist 145,145,140 |

**2026-11-01 Pet prompts:** lineup + six sheet prompts for each zone 6-10 are in `assets/Pets/<Zone>/Prompts.md` (Swamp, Savanna, Bamboo, Volcano, Ruins), Snow's format, body colours from the zone tables above. Not run yet.

**2026-11-03 Pets:** zone 6-10 Pets are now blocky animals, see [[Animal Pets]] and `AnimalPetsPlan.md`. Those prompts and the Pet looks and body colours in `World1Plan.md` still describe rocks, so use `assets/Pets/Animals/<Zone>.md` instead. Income and odds stand.
