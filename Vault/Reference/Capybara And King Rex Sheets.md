---
description: 2026-11-03 six-view sheets for the exclusive animal Pets, Capybara and King Rex; what to take from each; built in ExclusiveAnimals.blend.
type: reference
---
# Capybara and King Rex sheets

Prompts: `assets/Pets/Animals/Exclusive.md`. The front is the top-left view. Build: `assets/Pets/Exclusive/ExclusiveAnimals.blend`, which also holds a copy of the Fox. Approved and exported 2026-11-03 to `assets/Pets/<Name>/<Name>.fbx`, each checked by re-import. Not uploaded or in Studio yet.

![[Capybara Reference Sheet.webp]]
![[KingRex Reference Sheet.webp]]

Take from them:
- **Capybara:** Bloky's body in caramel, a wide dark snout, round dark ears, dark feet, and a big faceted orange with a green leaf on top. No mouth, no tail.
- **King Rex:** breaks the body rules on purpose (user, 2026-11-03). A cube at the back of the head holds Bloky's real eyes, with a long box snout pushed forward from it, a dark red mouth, a cream jaw and rows of white triangle teeth. It stands on two big legs with gold claws and has tiny arms, a cream belly, a long tail and dark spikes from head to tail. The crown is a new mesh to match the sheet, with short wide points and large gems, not Kingy's. The back runs in one slope from the head down the tail.
- **Neon when imported:** King Rex's claws and gems. It keeps Kingy's gold aura.

The first King Rex sheet kept the cube and looked wrong, so the user replaced it. The prompt asks for its own dinosaur shape now.

## Exported models

Sizes are studs W x D x H. Both also have `_Eyes` and `_Pupils`, which aren't listed. Keys are `Capybara` and `KingRex`.

| Pet | Tris | Size | Parts and colours (RGB) |
|---|---|---|---|
| Capybara | 490 | 2.0 x 2.21 x 3.24 | `Capybara` 190, 125, 75; `_Dark` 105, 65, 45; `_Leaf` 60, 170, 40; `_Nose` 25, 25, 25; `_Orange` 255, 135, 20 |
| KingRex | 1504 | 3.28 x 5.1 x 5.4 | `KingRex` 55, 205, 45; `_Claws` 255, 215, 30; `_Cream` 250, 235, 190; `_Crown` 255, 195, 30; `_GemsBlue` 20, 90, 255; `_GemsRed` 255, 0, 40; `_Head` 55, 205, 45; `_Legs` 55, 205, 45; `_Mouth` 170, 35, 45; `_Nostrils` 25, 90, 35; `_Snout` 55, 205, 45; `_Spikes` 20, 110, 45; `_Tail` 55, 205, 45; `_TailBelly` 250, 235, 190; `_Teeth` 250, 250, 245 |

King Rex is by far the biggest Pet. Check it on pedestals, held overhead (`Utils/HeldGrip`), at 3x on `Workspace.ExclusiveStand`, and with the gold aura, which is sized for a normal Pet body.

Related: [[Animal Pets]], [[Exclusive Pet Sheets]], [[Reuse Pet Eyes]]
