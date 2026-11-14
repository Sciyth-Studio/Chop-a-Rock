# World boss prompts

Three bosses for the Boss Arena (`WorldBossPlan.md` 3.4): Big Croc, Boulder Crab, Frost Yeti. Each one gets a different rig:

| Boss | Rig | Joints the sheet must show clearly |
|---|---|---|
| Big Croc | Four legs: Root, Body, Head, Jaw, 4 legs x 3, Tail x 4 | separate lower jaw, leg segments, tail segments |
| Boulder Crab | Crawler: Body, rigid Shell, 2 claw arms x 3 + pincer, 6 legs x 3 | pincer hinge, leg segments, shell sitting on the body |
| Frost Yeti | Two legs (R15 names): torso, head, jaw, arms, legs | shoulders, elbows, wrists, hips, knees |

They'll be rigid-piece rigs (meshlab or Blender pieces joined by Motor6Ds; see the vault note LihFolk Vault, "V2 and rigging"). So the sheets ask for chunky segments with a clear joint line at every bend, a neutral rest pose, and limbs held away from the body.

The user wants them **mean** (2026-11-10): angry glares under slanted brows, teeth, spikes, cartoon-villain menace, no gore.

Each boss has **4 glowing weak spots low on its body** (plan 4.3) where players chop. They're in the design so they become separate parts.

Run each prompt in its own ChatGPT chat. Send the sheets back together, and say if the front isn't the top-left view.

**Step 1: the lineup.** Attach `Vault/Attachments/Bloky Reference Sheet.png`.

```text
Using the attached grey character sheet ONLY for the eye style, lighting and finish (not its body shape or grey colour), generate ONE image: a lineup of three big mean boss monsters for a kids' Roblox game, side by side. They look tough, angry and menacing, like cartoon villains: no gore, nothing realistic.

ALL THREE:
- Each has the attached character's eye style (white chamfered squares, black chamfered-square pupils, small square glints), but narrowed into an angry glare under a heavy blocky brow that slants down toward the middle.
- Chunky toy-like low-poly bodies: broad flat faceted planes meeting at soft angles, not smooth and not realistic. Bright, saturated colours in flat areas with clean straight edges. Clean surface with no cracks, studs, fur strands, or surface texture.
- Built from chunky blocky segments with a clear joint line at every bend (jaw, shoulders, elbows, hips, knees, tail sections), like a posable action figure.
- Each has four glowing weak spots low on its body: big flat glowing crystal patches, easy to see from the ground.
- Standing in a neutral rest pose, limbs held a little away from the body, mouth closed.

LEFT TO RIGHT:
1. Big Croc: a huge long crocodile on four short thick bent legs, belly low to the ground. Dark green back with a yellow-green belly and jaw. A big long snout with rows of jagged white triangle teeth sticking out of the closed mouth, a separate lower jaw, the eyes sitting on bumps on top of the head, chunky dark green back ridges, and a long thick tail in four tapering sections. Glowing orange weak spots on the outer side of each leg's top.
2. Boulder Crab: a huge crab whose shell is a giant faceted grey boulder with a few patches of green moss. Under the shell, a bright red-orange body, two huge chunky pincer claws on thick three-part arms held up in front, and six thick pointed legs in three segments each, bent at the knees. Eyes on two short stalks rising from the front, under a jagged rock brow, and jagged spikes along the claws. Glowing cyan weak spots where the four back legs meet the body.
3. Frost Yeti: a huge hulking yeti with a broad chest, hunched forward and standing upright on two short thick legs, with long heavy arms ending in big fists that hang near the ground (an ape-like stance). Shaggy chunky faceted fur in pale ice blue, a dark navy face, chest, hands and feet, two curved white horns, and jagged ice crystal spikes on the shoulders and back. A snarling mouth with two big white tusks pointing up from a separate lower jaw. Glowing bright blue weak spots on both knees and both sides of the belly.

LAYOUT:
- Top row: all three from the front, side by side, on one ground line, shown roughly to scale (the Croc long and low, the Crab wide, the Yeti tallest). Bottom row: the same three in the same order from a 3/4 view.
- Plain light-grey background, even lighting, no dramatic shadows. No text, labels, or watermarks.
```

Lineup generated 2026-11-10: `assets/Bosses/Lineup.webp`. In it the Crab's legs hide under the shell, the Croc's tail is hidden behind it and the Yeti's arms hang against its sides, so the six-view prompts spell those out.

**Step 2: one sheet per boss.** Once you're happy with the lineup, run each prompt in its own chat with the lineup image and the Bloky sheet attached.

## Big Croc

```text
Using the attached boss lineup (the FIRST boss from the left, the Big Croc) as the design to match exactly, and the attached grey character sheet ONLY for the eye style, lighting and finish, generate ONE image: a model reference sheet of that single BIG CROC boss for a kids' Roblox game.

SHAPE:
- A huge long mean crocodile on four short thick bent legs, belly low but clear of the ground. Dark green back, yellow-green belly and jaw, tall sharp dark back ridges.
- The head has a big long snout with rows of jagged white triangle teeth sticking out of the closed mouth, and a SEPARATE lower jaw that meets the head at a clear hinge line at the back of the mouth. The eyes (white chamfered squares, black chamfered-square pupils, small square glints) sit on bumps on top of the head, narrowed into an angry glare under heavy blocky brows that slant down toward the snout.
- Each leg is three chunky blocky segments (upper leg, lower leg, wide flat foot) with clear joint lines, held slightly out from the body. The long thick tail is four tapering box sections with clear joint lines between them, lying straight out behind.
- Four big flat glowing orange crystal weak spots, one on the outer side of each leg's top where it meets the body.
- Low-poly faceted surfaces: broad flat planes meeting at soft angles, not smooth and not realistic. Simple enough to model in under 5,000 triangles. Clean surface with no cracks, studs, scales, or surface texture.

LAYOUT:
- A single image showing the SAME boss from 6 views in a grid: front, back, left side, right side, top-down, and one 3/4 perspective view.
- The 5 flat views are orthographic: straight-on, no perspective distortion, camera level for the side views.
- Identical in every view: same shape, proportions, and colours. Same scale and aligned like a blueprint.
- Put the front view top-left.
- Plain light-grey background, even lighting, no dramatic shadows. No text, labels, or watermarks.
```

## Boulder Crab

```text
Using the attached boss lineup (the SECOND boss from the left, the Boulder Crab) as the design to match exactly, and the attached grey character sheet ONLY for the eye style, lighting and finish, generate ONE image: a model reference sheet of that single BOULDER CRAB boss for a kids' Roblox game.

SHAPE:
- A huge wide mean crab. Its shell is a giant faceted grey boulder with a few flat patches of green moss, sitting on top of a bright red-orange body as a separate piece. The body is wider than it is tall.
- Two huge chunky pincer claws held up in front, each on a thick arm of three blocky segments with clear joint lines. Each pincer's lower half is a separate piece hinged at the wrist so it can open and close. Claws closed, with jagged spikes along their edges.
- Six thick pointed legs, three on each side, each three blocky segments with clear joint lines, bent at the knee and standing out from the body. All six legs are fully visible in the side and back views; the shell does not cover them.
- The eyes (white chamfered squares, black chamfered-square pupils, small square glints) sit on two short stalks rising from the front of the body, narrowed into an angry glare under a jagged rock brow on the shell's front edge. A wide scowling mouth below them.
- Four big flat glowing cyan crystal weak spots, where each of the four back legs meets the body.
- Low-poly faceted surfaces: broad flat planes meeting at soft angles, not smooth and not realistic. Simple enough to model in under 5,000 triangles. Clean surface with no cracks, studs, or surface texture.

LAYOUT:
- A single image showing the SAME boss from 6 views in a grid: front, back, left side, right side, top-down, and one 3/4 perspective view.
- The 5 flat views are orthographic: straight-on, no perspective distortion, camera level for the side views.
- Identical in every view: same shape, proportions, and colours. Same scale and aligned like a blueprint.
- Put the front view top-left.
- Plain light-grey background, even lighting, no dramatic shadows. No text, labels, or watermarks.
```

## Frost Yeti

```text
Using the attached boss lineup (the THIRD boss from the left, the Frost Yeti) as the design to match exactly, and the attached grey character sheet ONLY for the eye style, lighting and finish, generate ONE image: a model reference sheet of that single FROST YETI boss for a kids' Roblox game.

SHAPE:
- A huge hulking mean yeti with a broad chest, hunched forward, standing upright on two short thick legs, with long heavy arms ending in big fists that hang near the ground. Shaggy chunky faceted fur in pale ice blue, made of big flat tufts, not strands. Dark navy face, chest, hands and feet. Two curved white horns and jagged ice crystal spikes on the shoulders and back.
- Built like a posable action figure from blocky pieces with clear joint lines: head, separate lower jaw, chest, belly and hips, upper arm, forearm, fist, upper leg, lower leg, foot. Arms held slightly away from the body, about 30 degrees down from straight out to the sides. Feet flat, shoulder width apart.
- The eyes (white chamfered squares, black chamfered-square pupils, small square glints) narrowed into an angry glare under a heavy blocky fur brow that slants down toward the middle. A snarling mouth with two big white tusks pointing up from the separate lower jaw.
- Four big flat glowing bright blue crystal weak spots: one on each knee and one on each side of the belly.
- Low-poly faceted surfaces: broad flat planes meeting at soft angles, not smooth and not realistic. Simple enough to model in under 5,000 triangles. Clean surface with no cracks, studs, fur strands, or surface texture.

LAYOUT:
- A single image showing the SAME boss from 6 views in a grid: front, back, left side, right side, top-down, and one 3/4 perspective view.
- The 5 flat views are orthographic: straight-on, no perspective distortion, camera level for the side views.
- Identical in every view: same shape, proportions, and colours. Same scale and aligned like a blueprint.
- Put the front view top-left.
- Plain light-grey background, even lighting, no dramatic shadows. No text, labels, or watermarks.
```
