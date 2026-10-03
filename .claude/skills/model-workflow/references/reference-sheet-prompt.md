# Reference sheet prompt (step 3)

Give this to ChatGPT with the user's reference images attached. Replace the SHAPE block for each model. Keep SHAPE to what the silhouette needs, and drop anything that does not change the model.

```text
Using the attached reference images ONLY for color palette, lighting, and finish, generate ONE image: a model reference sheet of a single <OBJECT> for a Roblox game.

SHAPE:
- <the silhouette, proportions and base in two to four bullets>
- Low-poly faceted surfaces: broad flat planes meeting at soft angles, not smooth and not realistic. Keep it simple enough to be modelled in under <N> triangles.
- <ground contact, e.g. flat bottom, sitting on the ground>
- Clean surface with no cracks, studs, or surface texture. Plain flat-colored faces only.

LAYOUT:
- A single image showing the SAME <OBJECT> from 6 views, arranged in a grid: front, back, left side, right side, top-down, and one 3/4 perspective view.
- The 5 flat views (front, back, left, right, top) are orthographic: straight-on with no perspective distortion. Keep the camera level for the side views.
- The <OBJECT> is identical in every view: same shape, proportions, and colors.
- Keep the same scale across the flat views, and align them so heights and widths match across views, like a blueprint.
- Plain light-grey background, even lighting, no dramatic shadows.
- No text, labels, or watermarks.
```

Lessons from the rocks:

- Do not tell the generator to match the references' style or shape; the references only supply colour, lighting and finish.
- Say "no studs, no cracks, no texture". Stud overlays and crack stages are added in Roblox, not baked into the model.
- Chop rocks use the boulder look (Vault: Rocks Look Like Boulders), not stacked blocks.
