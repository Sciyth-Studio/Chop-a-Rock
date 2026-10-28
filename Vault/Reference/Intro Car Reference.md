---
description: 2026-10-27 ChatGPT six-view sheet for the intro cutscene's red toy convertible; what to take from it and the proportion change made for the seat and animations
type: reference
---
# Intro car reference

![[Intro Car Sheet.png]]

Prompt: `assets/Decor/IntroCar/Prompts.md` (no images attached). Built in meshlab as `tools/meshlab/models/IntroCar.luau` ([[Meshlab]]); the first test of a reference sheet + meshlab.

Take from it:
- Red body with one white stripe over the hood and front face, and the trunk deck and back face.
- Round yellow headlights with small yellow indicators below, a black slot grille, a white plate, red bumpers with a dark grey lip, square red tail lights, one exhaust on the right.
- Short upright windshield in a red frame, small red mirrors, open cabin with dark grey seats and headrests, a grey floor, the steering wheel on the left.
- Black tyres on dark rims, tucked under the body (they don't stick out past it).

Changed: the sheet's car is tall for its length (door tops about a third of its length). At the current car's 12.5 x 7 footprint that puts the doors about 4.2 studs high, but the `Seat` (root 2.95 up) and the Boing Out clip are tuned for doors about 2.5 high, so the build lowers the body to about 3. See [[Intro Cutscene]].
