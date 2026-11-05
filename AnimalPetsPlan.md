# Animal Pets: plan for world 1

Status: draft for the user's approval, written 2026-11-03. The fox is modelled and approved; nothing else is modelled and the game is unchanged. Pets go by their real animal names (user, 2026-11-03). The other animal choices and rarities below are Claude's proposals.

## 1. The style (set by the fox)

Prompt reference: `Vault/Attachments/Bloky Reference Sheet.png`, attached to every prompt, because a plain body gives ChatGPT nothing animal to copy (user, 2026-11-03). The approved Fox (`Vault/Attachments/Fox Reference Sheet.webp`) is the look to compare results against, and no prompt attaches or mentions it. Forest's lineup covers the other five animals only.

- **Body:** Bloky's chamfered cube is both head and body. No neck, no separate head.
- **Eyes:** copies of `Bloky_Eyes` and `Bloky_Pupils`, moved but never resized. No mouth.
- **Added parts:** only what makes the animal recognisable: usually ears or horns, a snout or beak, stubby feet, and a tail.
- **Colour:** bright natural colours in flat areas with clean edges, one Roblox part per colour. Zones no longer share a body colour.
- **Rarity:** Commons are simplest. Rarer animals get bigger shapes and more parts, and Legendary and Secret get glowing Neon accents.
- **Size:** same body as Bloky, about 2 x 1.9 x 1.9 studs. Under 800 triangles per Pet.

## 2. Motion

No rig and no animation clips. The feet are too short for walking to read.

`IdlePet` already breathes, blinks, hops and drops in, and it moves every part of a Pet, so added parts work with no motion code. Tails, wings and ears stay separate parts, which leaves room to add a wag or flap later without remodelling.

## 3. Lineup

$/s and odds stay as they are in `PetConfig`, `GeodeConfig` and `World1Plan.md`. Only the model and name change.

| Zone | Common | Uncommon | Rare | Epic | Legendary | Secret |
|---|---|---|---|---|---|---|
| Forest | Bunny | Squirrel | Fox | Owl | Bear | Unicorn |
| Desert | Gecko | Armadillo | Scorpion | Vulture | Camel | Sphinx |
| Jungle | Monkey | Toucan | Sloth | Tiger | Gorilla | Panther |
| Ocean | Crab | Clownfish | Turtle | Octopus | Shark | Narwhal |
| Snow | Penguin | Seal | Reindeer | Walrus | Arctic Wolf | Yeti |
| Swamp | Frog | Duck | Snail | Beaver | Alligator | Hydra |
| Savanna | Zebra | Giraffe | Rhino | Elephant | Cheetah | Lion |
| Bamboo | Beetle | Koi | Crane | Panda | Red Panda | Monkey Sensei |
| Volcano | Salamander | Imp Cat | Lava Tortoise | Hellhound | Dragon | Phoenix |
| Ruins | Bat | Raven | Wizard Cat | Guard Dog | Minotaur | Nine-Tailed Fox |

**Looks that the name doesn't cover**
- **Hydra:** green and scaly, with a faceless body, three long necks with big toothy heads, glowing green spines, a thick tail and stubby feet. No wings, so it stays apart from the Volcano's Dragon. The user's pick, 2026-11-03; redesigned 2026-11-04.
- **Panther:** glossy black with faint charcoal spots, glowing gold claws and tail tip. The user's pick over the Chameleon, 2026-11-03.
- **Sphinx:** a golden cat.
- **Monkey Sensei:** white beard and a straw hat.
- **Imp Cat:** red, with horns.
- **Lava Tortoise:** a small volcano for a shell, with glowing lava. Replaced the Baby Dragon, 2026-11-04.
- **Hellhound:** a charcoal dog with lava cracks and a flame on its tail. Replaced the Young Dragon, 2026-11-04.
- **Wizard Cat:** black, in a wizard hat.
- **Guard Dog:** a hound in a helmet.
- **Nine-Tailed Fox:** star-speckled, with a portal ring that hints at world 2.

**Exclusives and boss**
- **Capybara:** replaces Champ in the starter pack. Caramel brown, with an orange balanced on its head. The user's pick, 2026-11-03.
- **King Rex:** replaces Kingy on the exclusive stand (3x best Pet). Emerald green T-Rex with a toothy jaw, tiny arms, two big feet, a long tail and Kingy's gold crown. No cape, so the tail shows. The user's pick, 2026-11-03.
- **Golem Pet:** stays a rock, as the only rock Pet left. A rare nod to the game's name, from the boss only.

**Keys:** each Pet's config key and model match its name with no spaces: `Fox`, `ArcticWolf`, `Model_Pet_Fox`. No name may be a rock material, "Diamond" or a weather modifier.

## 4. Shapes and colours to watch

These are checked at each zone's lineup step.

- **No feet:** Clownfish, Koi, Turtle, Octopus, Shark, Narwhal and Snail rest on their bellies with a flat bottom.
- **Hydra:** the side heads are smaller cubes, but Bloky's eyes can't be resized, so they'll look big on those heads. Judge it at the lineup step.
- **Giraffe:** a cube can't show the long neck. Stretch its body tall as the one exception, or add a neck and a smaller head.
- **Colours close to the zone floor:**
  - Snow's near-white floor: make the Arctic Wolf blue-grey, the Yeti sky blue and the Seal mid grey. The Penguin stays black and white.
  - Desert's tan floor: make the Camel a stronger gold and give it a red saddle blanket.
  - Swamp's dark green floor: make the Frog bright lime.
  - Volcano's near-black floor: make the Salamander bright orange with black spots.

## 5. What else changes

- **Enemies:** each zone's Guardian is its Common at x5, so they become a giant Bunny, Gecko, Monkey, Crab and so on. `EnemyConfig.PetKeys` needs the new keys.
- **Tutorial:** the free Huge Shroomy becomes a Huge Fox (`TutorialConfig.FirstPetKey`). Same rarity.
- **Config:** `PetConfig`, `GeodeConfig`, `IndexConfig`, `AssetRegistry`, `AdminConfig` presets and the generated `ItemIconConfig`.
- **Icons:** every Pet gets a new render and upload with the `item-icons` skill.
- **Loading cover:** the bouncing Bloky (`Screens/LoadingCover`) is a Studio piece that needs its own decision.
- **Saves:** Pets in saves are stored by key. Each old Pet maps to the new Pet of the same zone and rarity (Bloky to Bunny, Shroomy to Fox), so nothing is lost. `SchemaVersion` gets an explicit migration, following the data rules in `AGENTS.md`.
- **Check in the fox test:** held position with the tail and ears (`Utils/HeldGrip`), pedestal seating now the body sits on feet, the hatch reveal, the Pet label's height and the enemy fight's camera shots.

## 6. Build order

1. **Fox, end to end:** import, icon, then check it in every place from section 5. This sets the part naming and the colour and stud rules.
2. **Forest:** lineup, then five more sheets, batch-built with `batch-model`. Swap the zone in and playtest the first five minutes, including the tutorial.
3. **Desert, Jungle, Ocean, Snow, then Capybara and King Rex:** one lineup and batch per zone. Ocean's lineup goes first of these, as it's the hardest test of the body. Reuse the crown from `ExclusivePets.blend`.
4. **Ship the swap together:** mixed rock and animal zones are fine in testing, but all 32 and the save migration should reach players at once.
5. **Swamp to Ruins:** build each set with its zone, as `World1Plan.md` orders it.

**Prompts:** every lineup and sheet prompt is in `assets/Pets/Animals/<Zone>.md`, plus `Exclusive.md`. The old `assets/Pets/<Zone>/Prompts.md` files are the rock Pets' and aren't used for this.

Models: 32 replaced, 30 new animals, plus the Golem Pet as a rock.

## 7. Open for the user

- Approve or change the animals in section 3.
- Studs on added parts (ears, tail, feet), or on the body only? Decide once the fox is in Studio.
- Does the loading cover keep Bloky as a mascot, or show an animal?
- The game's description and thumbnails say pet rocks anywhere? Check before launch.
