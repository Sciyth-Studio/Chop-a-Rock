---
description: 2026-10-10 APPROVED plan for the jungle, ocean and snow chop rocks, Rok lineups and geodes; chop rocks built as placeholders, Roks and geodes wait on models.
type: decision
---
# Zones after the desert (approved 2026-10-10)

Approved by the user 2026-10-10 ("balancing can only really be fixed by playing"), so numbers are still [PLAYTEST] drafts to tune. Built so far: the nine placeholder chop rocks, entrance signs and spawn areas (see [[Zone Line]]). Roks, geodes and stands are not built; they wait on real models. Zone order and floor colours: [[Zone Line]]. Build steps once approved: the `new-zone` skill. Names follow [[Simple Names No Material Clash]] (no sand, ice, lava, crystal, pearl-as-material, diamond). Roks follow [[Roks Stay Rocks]]: Bloky's body and eyes ([[Bloky Reference]]), theme only from a prop on top, never an animal.

## Rule used for the numbers
- Rocks: `StrengthRequired` x5 and `BasePayout` x4 per tier, continuing from `DesertThird` (12,500 / 51,200). All use `RespawnSeconds` 0.8, `TemplateKey` `Model_Rock_<RockKey>`.
- Geode: strength = 5 x the zone's First rock strength, price = 12.5 x its First payout (the forest's 10 / 500 against Stone 2 / 40). The desert has no geode in config yet, so its row is the same rule applied (shown for the chain only).
- Rok income ($/s): forest is 1 / 2 / 5 / 12 / 30 / 150. Each zone multiplies it by (zone First rock payout / 40), the same factor its rocks and geode price grow by: desert x80, jungle x5,120, ocean x327,680, snow x20,971,520. A geode then always costs 500 s of a Common's income, and Roks stay as relevant as chopping in every zone. Claude's recommendation 2026-10-10; the user had no preference. Sell value stays 100 s of income.
- Big numbers are fine (user, 2026-10-10): kids like feeling rich, and purchasing power stays the same as long as costs scale too. The answer is more money sinks, not smaller numbers. The money text needs the short form (K/M/B/T) the HUD already uses; check it before building snow.
- Odds shift weight upward per zone, like the forest pattern (60 / 25 / 10 / 3.9 / 1 / 0.1). Secret stays rare enough to be an announcement.

## Chop rocks
Placeholder look = the existing boulder mesh (split with `Model_RockSplit_Boulder`) tinted the colour below, scaled to the size below. Colours are high saturation and sit against the zone floor from the Zone Line.

| RockKey | DisplayName | StrengthRequired | BasePayout | Placeholder colour (RGB) | Placeholder size (studs) |
|---|---|---|---|---|---|
| JungleFirst | Fern Rock | 62,500 | 204,800 | 70, 220, 40 (leaf green on the 50,130,40 floor) | 8 x 6 x 7 |
| JungleSecond | Vine Boulder | 312,500 | 819,200 | 20, 200, 110 | 14 x 8 x 12 |
| JungleThird | Tiki Boulder | 1,562,500 | 3,276,800 | 255, 170, 0 (carved gold) | 22 x 14 x 19 |
| OceanFirst | Barnacle Rock | 7,812,500 | 13,107,200 | 0, 190, 255 (bright cyan, pops on the 0,55,110 floor) | 9 x 7 x 8 |
| OceanSecond | Kelp Boulder | 39,062,500 | 52,428,800 | 0, 120, 255 | 16 x 9 x 14 |
| OceanThird | Reef Boulder | 195,312,500 | 209,715,200 | 190, 60, 255 (violet) | 25 x 16 x 22 |
| SnowFirst | Snowy Rock | 976,562,500 | 838,860,800 | 90, 200, 255 (sky blue on the near-white floor) | 10 x 8 x 9 |
| SnowSecond | Drift Boulder | 4,882,812,500 | 3,355,443,200 | 40, 120, 255 | 18 x 10 x 16 |
| SnowThird | Igloo Boulder | 24,414,062,500 | 13,421,772,800 | 255, 90, 160 (candy pink for contrast) | 28 x 18 x 25 |

**Built 2026-10-10:** all 12 real models replace the placeholders. Each `Model_Rock_<Key>` is a MeshPart with its props nested under it, with a `Model_RockSplit_<Name>` split and a rebuilt `Model_RockPreview_<Key>`. The files are in `assets/Rocks/<Zone>/<Name>/`, and the recipes in the `rock-model` skill. Real sizes are within about a stud of the table below.

Real models (user, 2026-10-10): the 12 desert, jungle, ocean and snow rocks show their zone through the rock's shape plus separate prop meshes (cactus, vines, kelp, snow caps), not vertex colour. Work goes one zone at a time, starting with the desert. For each zone the user makes one ChatGPT reference image showing all three rocks, using Claude's prompt, before Claude models them. Props are separate parts, so the split model and the break code have to carry them. The body colours in the table stay as they are (user, 2026-10-10). Every rock has a black outline (a `Highlight` child of the template MeshPart, AlwaysOnTop) and guide arrows lead players to it, so a rock blending into its floor isn't a problem. Don't change colours for visibility. Props parented under the rock MeshPart should pick up the same outline.

## Geodes
Model: reuse `Model_Geode_Basic` / `Model_GeodeSplit_Basic` tinted to the zone, with a stand per zone ([[Geode Stand Reference]]).

| Geode key | DisplayName | StrengthRequired | Price |
|---|---|---|---|
| Forest (exists) | Forest Geode | 10 | 500 |
| Desert (not in config yet) | Desert Geode | 2,500 | 40,000 |
| Jungle | Jungle Geode | 312,500 | 2,560,000 |
| Ocean | Ocean Geode | 39,062,500 | 491,520,000 (x3 since 2026-10-19, [[Balance Pass Oct 18]]) |
| Snow | Snow Geode | 4,882,812,500 | 36,700,160,000 (x3.5 since 2026-10-19, [[Balance Pass Oct 18]]) |

## Roks
Rarity colours as in the master plan. Looks are Bloky body plus one prop on top. The jungle and snow names come from the master plan §03 lineup; the ocean is rewritten for deep ocean (the old Sailor / Matey pirate and beach Roks are dropped, so this also answers the To Do item "Ocean Rok lineup").

### Jungle (income x5,120, odds 55 / 25 / 12 / 6 / 1.8 / 0.2)
| Rarity | Name | Look | $/s | Odds % |
|---|---|---|---|---|
| Common | Roly | Plain chunky round-edged Bloky, no prop | 5,120 | 55 |
| Uncommon | Leafy | One big leaf on top like an umbrella | 10,240 | 25 |
| Rare | Viney | Vines wrapped around the body, small flowers on top | 25,600 | 12 |
| Epic | Coco | Palm fronds and two coconuts on top | 61,440 | 6 |
| Legendary | Tiki | Carved stone mask on top with glowing carved marks | 153,600 | 1.8 |
| Secret | Bloomy | Sits in a giant glowing flower | 768,000 | 0.2 |

### Ocean, deep sea (income x327,680, odds 50 / 25 / 14 / 8 / 2.6 / 0.4)
| Rarity | Name | Look | $/s | Odds % |
|---|---|---|---|---|
| Common | Drip | Plain teardrop-shaped Bloky, no prop | 327,680 | 50 |
| Uncommon | Bubbly | A cluster of blue bubbles floating on top | 655,360 | 25 |
| Rare | Shelly | Seashells and a tuft of seaweed on top | 1,638,400 | 14 |
| Epic | Reefy | Branching coral crown on top | 3,932,160 | 8 |
| Legendary | Glowy | Anglerfish-style glowing lure: a lamp on a curved stalk from its forehead (user liked this 2026-10-10) | 9,830,400 | 2.6 |
| Secret | Chompy | Wears a grey shark-costume hood (dorsal fin, tail fin, open toothy jaw framing its face) with glowing cyan gill stripes (user, 2026-10-19; replaces Venty's vent chimney, which replaced Beamy) | 49,152,000 | 0.4 |

Doubloony (pirate coins) was dropped 2026-10-10 as too pirate for the deep ocean. Glowy's lure is a prop and the body stays a rock (no fish body), per Roks Stay Rocks.

### Snow (income x20,971,520, odds 45 / 25 / 16 / 10 / 3.5 / 0.5)
| Rarity | Name | Look | $/s | Odds % |
|---|---|---|---|---|
| Common | Hexy | Plain six-sided block, no prop | 20,971,520 | 45 |
| Uncommon | Beanie | Knitted beanie with a pompom | 41,943,040 | 25 |
| Rare | Cozy | Scarf and earmuffs | 120,000,000 (was 104,857,600; [[Balance Pass Oct 18]]) | 16 |
| Epic | Stacky | Two small stacked rocks on top with a little top hat | 251,658,240 | 10 |
| Legendary | Piney | Pine tree on its back with glowing lights | 629,145,600 | 3.5 |
| Secret | Starry | Glowing stars floating around it | 3,145,728,000 | 0.5 |

Epic and up roll a trait at hatch (existing 25% rule), so Epic, Legendary and Secret here get traits automatically.

## Open for the user
- Approve or change the rock names, colours and sizes.
- Money sinks to match the big numbers (needs its own plan).
- Desert Roks (Pointy, Spike, Howdy, Flowy, Ankhy, Sunny) and the Desert Geode are still not in config; they wait on the user modelling the desert rocks and geodes. Desert Rok income would be forest x80 (80 / 160 / 400 / 960 / 2,400 / 12,000).
