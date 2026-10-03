---
description: 2026-10-02 — chop rocks should read as boulders, not stacked blocks; the user is remodelling them by hand.
type: decision
---
# Rocks look like boulders

**2026-10-02.** The user wants the chop rocks to look like boulders and is remodelling them themselves, replacing the blocky BlockRock style (stacked tapered prisms) made with the `rock-model` skill.

- The `rock-model` skill's builder (`rock_builder.py`) only generates the blocky style. Its split, checks and Studio wiring still apply to any rock mesh, but `find_straight_split` reads block specs, so splitting a hand-made mesh needs a mesh-based search.
- What still has to hold for a hand-made rock to plug into the game: one watertight mesh, flat bottom, pivot at bottom centre, front facing the player (Roblox -Z), plain colour set on the MeshPart, and a split cut along the chop direction (front to back through the middle). See the `rock-model` skill.
- Earlier rock decisions that still stand: plain SmoothPlastic with colour from the part (no baked texture), straight chop-aligned split, keep chop rocks unrotated in Studio.
