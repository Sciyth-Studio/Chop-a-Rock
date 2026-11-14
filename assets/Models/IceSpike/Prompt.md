# Ice Spike (Frost Yeti Ice Spikes Big Attack)

Step 3 prompt for the ChatGPT reference sheet. Attach 2 to 4 references (the Frost Yeti, the Snow zone, any icy game art) for colour, lighting and finish only.

Built with meshlab (`tools/meshlab/models/IceSpike.luau`): a cluster of tapered six-sided prisms is a loft from a hexagon ring to a point, which suits meshlab well. In the game, about 600 copies burst out of the arena floor in a ring around the yeti. They're seen mostly from a wide camera 165 studs back and 130 up, so the top view and the silhouette matter most, and close-up detail doesn't. Drop-in key: `Model_Boss_IceSpike` in `ReplicatedStorage.Assets.Models`, pivot at the bottom centre, about 9 studs tall and 4 studs across. The code scales each copy 0.8 to 1.3x and turns it randomly.

```text
Using the attached reference images ONLY for color palette, lighting, and finish, generate ONE image: a model reference sheet of a single ICE SPIKE CLUSTER for a Roblox game.

SHAPE:
- One tall main crystal, a straight six-sided prism that tapers to a sharp point, about twice as tall as it is wide at the base, leaning slightly. Two or three shorter crystals of the same shape grow out of its base at different angles, leaning outward like a burst.
- Hard, crisp faceted edges: flat planes and sharp corners, no rounding, not realistic. Simple enough to be modelled in under 300 triangles.
- The base is a flat, rough ring of a few broken ice chunks, so the cluster looks like it just punched up through the ground. Flat bottom.
- Colours: pale icy blue body, near-white tips, a slightly deeper blue at the base. Plain flat-coloured faces only, with no cracks, studs, bubbles, or surface texture. Not transparent in the sheet.

LAYOUT:
- A single image showing the SAME ICE SPIKE CLUSTER from 6 views, arranged in a grid: front, back, left side, right side, top-down, and one 3/4 perspective view.
- The 5 flat views (front, back, left, right, top) are orthographic: straight-on with no perspective distortion. Keep the camera level for the side views.
- The ICE SPIKE CLUSTER is identical in every view: same shape, proportions, and colors.
- Keep the same scale across the flat views, and align them so heights and widths match across views, like a blueprint.
- Plain light-grey background, even lighting, no dramatic shadows.
- No text, labels, or watermarks.
```
