---
name: model-workflow
description: Use whenever the user asks to get something modelled for the game (a rock, prop, tree, building, character piece, any 3D asset), or asks how to make a model. Lays out the six-step pipeline (idea, ChatGPT reference, ChatGPT design prompt, Claude models it in Blender, feedback loop, import) and says which step they are on. Rocks also use the rock-model skill for step 4 and 6.
---

# Model workflow

Every model goes through the same six steps. When the user brings up a model, start by listing the steps, say which one they are on, and name what they owe next. Do not skip ahead to Blender without a reference image.

1. **Idea.** The user says what it is, where it goes (zone), roughly how big (studs), and the look (low-poly faceted, plain colours, no baked texture unless asked). Ask for what is missing; recommend defaults. For anything chopped, also ask whether it needs a split.
2. **ChatGPT reference.** The user collects 2 to 4 reference images (existing game assets, screenshots, Pinterest) and gives them to ChatGPT. Tell them to use references only for colour palette, lighting and finish, never for shape.
3. **ChatGPT design prompt.** Claude writes the prompt that makes ChatGPT produce one multi-view reference sheet (front, back, left, right, top, one 3/4 view). Start from `references/reference-sheet-prompt.md`, fill in the SHAPE block for this model, and keep it short: do not pad it with detail the model does not need. The user runs it and sends the image back.
4. **Claude models it.** Claude builds the mesh in Blender through the Blender MCP from the reference sheet. Ask which view is the front (front faces Roblox -Z). Rocks: use the `rock-model` skill (builder, quality checks, split). Everything: one watertight mesh, flat bottom if it sits on the ground, pivot at bottom centre, low tri count (rock boulders about 100 to 500), plain colour set on the part in Roblox.
5. **Feedback loop.** Claude renders previews (several angles, and the split pulled apart if there is one) and shows them. The user says what to change; Claude adjusts and re-renders until the user approves. Player-facing looks need approval before they are final. Do not export until approved.
6. **Import.** Claude exports FBX files to `assets/<Category>/<Name>/` (`rock_builder.export_fbx` scales vertices 2x so 1 Blender unit imports as 2 studs; Roblox ignores the FBX unit option). The user imports them in Studio with 3D Importer (Claude cannot), sets `CollisionFidelity` to Hull, and says when they are in. Then Claude wires them in through the Studio MCP (names, parent, tags, attributes, registry entries, colour, material, position), verifies by values, and the user playtests and saves the place. Rocks follow the wiring steps in `rock-model`.

## Notes

- Shortcuts exist when a new model is a variant of an existing one: duplicate and rotate, resize or recolour in Studio instead of modelling (the Stone rock is the Boulder mesh scaled and turned 180 degrees). Rotating a chop rock in Studio only keeps its split aligned at 180 degrees; for other angles, rotate in Blender and re-split. Offer this before starting steps 2 to 4.
- Vertex colours baked in Blender show in Roblox when the part colour is white; the part colour multiplies them.
- Commit with explicit paths; `assets/` is the hand-off folder and is not committed.
