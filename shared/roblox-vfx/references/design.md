# VFX design rules

Condensed from Roqer's VFX design reference (S4US), which measured published effects by experienced Roblox VFX artists. Numbers are starting points; judge by eye. Match the project's art direction: a bright cartoon game wants clean cel shapes over gritty smoke, a heavier style wants mottled smoke and darker values.

## Purpose and scale

- Name the moment first: a frequent small hit (every swing), a reward beat (a critical hit, level-up, egg hatch, rebirth), an ambient loop (aura, pickup sparkle). Frequent hits are small, one hue and short (gone by about 1 s). Reward beats are staged: anticipation, a big flash, a body that keeps growing, a lingering residue.
- Size for where it is seen. A payoff far from the camera needs size, brightness and height to read. One hit of many: 10 to 13 studs at its peak. A finishing burst: several times the target's size.
- Throw something up. A flat ring or patch on the floor reads as a smear from a low camera. Bursts need a vertical part: chips, a dust column, rising sparks.
- Borrow a reference's rhythm and silhouette, not its colour.

## Colour

- Pick about five colours before building, and use nothing else in the effect.
- Energy (flashes, rings, sparkles) is saturated. Matter (rock chips, dust, smoke) is desaturated or takes the rock's colour. Pair them: energy alone feels weightless.
- Gradients carry value: a layer can run light, then saturated, then dark over its life.
- Smoke beside a glow takes the glow's colour where it is lit; one flat grey reads as a cut-out.
- White is for thin shapes (rings, crescents, star spikes) and the hottest core, never a filled disc.

## Value

Bright parts only read against something darker.
- Black twin: a copy of a coloured emitter with `Color` black (or Brightness 0 to 0.01) at `LightEmission` 0, same texture, size curve, lifetime and delay, at the same `ZOffset` or a step in front. Lopsided shapes (crescents, slashes) only line up with their twin when both lock `Rotation` to one value.
- Black backing: a soft black blob behind the colour (`ZOffset` -1 to -3), 2 to 4 times its size.
- Dim twin: the same hue at Brightness 0.05 to 0.6, one step behind, living a tenth to a fifth longer.
- Additive layers add up: three overlapping glows turn into a white blob that hides the shapes.

| LightEmission | Black renders as |
| --- | --- |
| 0 | Solid ink |
| 0.5 | Faint veil |
| 1 | Invisible |

## Brightness

`Brightness` multiplies `Color`. Read `Lighting.Bloom` first: at Threshold 1, Brightness 5 already blooms; at 2 (a new place's default), Brightness 1 to 3 reads as flat paint.
- Hard cel shapes: `LightEmission` 0 or negative, Brightness 5 to 55.
- Glows and halos: `LightEmission` 1, Brightness 1 to 6.
- The hot core of a hit: one or two front layers at Brightness 50 to 150 for 0.03 to 0.1 s.
- Neon mesh flashes can start very hot and drop fast.
- A Decal's `Color3` above 1 overbrights and blooms (set it from code; 2 to 20).

## Layers and orientation

- Many layers of one sprite each beat a few layers of many particles. Big counts are for scatter: chips, sparks, dots.
- `FacingCamera`: puffs, glows, flares. `VelocityPerpendicular`: flat rings and ground marks (needs `Speed` 0.001; at 0 it doesn't show). `VelocityParallel`: streaks, with `Squash` and `Rotation` -90 so the texture's top leads the motion.

## Timing

- Fire once, die at different times. The order things vanish is the progression.
- Brightness only goes down after the peak. Mass can keep growing: a burst whose body (puffs, chunks, crescents) swells for 0.25 to 1 s after the flash reads as an explosion; one that only shrinks reads as a pop.
- Stagger: flash at 0, everything else from +0.03 s in 0.025 to 0.05 s steps. Simultaneous layers read as noise.
- Anticipation 0.1 to 0.6 s before a big hit: energy gathering inward, a shrinking spiky ring.
- Burst then hang: high `Speed` with strong `Drag` (45 to 75 at Drag 16). Debris falls at `Acceleration` -15 to -27.
- Size pops: debris `0:0, 0.1:peak, 1:0`. Flashes start big and shrink. Rings grow ease-out.
- Lingering smoke runs slower (`TimeScale` 0.6 to 0.95). Transparency keys above 1 make particles vanish before their lifetime ends.

| Layer | Lifetime |
| --- | --- |
| Flash | 0.03 to 0.15 s |
| Crescents, slashes | 0.15 to 0.4 s |
| Burst body | 0.35 to 1.2 s |
| Rings, debris | 0.4 to 1.4 s |
| Smoke, ground marks | 1 to 3 s |

## Budgets

- A few hundred particles per effect. Every emitter is a draw call; big overlapping transparent layers cost the most.
- Frequent effects (every swing) stay lean; pool them if they fire many times a second. Reward beats can use 20 to 40 emitters.
- Effect parts are anchored with no collision, query, touch or shadows (VFXEmit sets this on clones).

## Review

Ask of every held frame:
- From the player's camera, does the payoff fill its share of the screen, and does it rise, or stay a flat splash?
- At about 0.3 s, is a body still carrying the mass, or only sparks?
- Is the flash one sharp shape, bigger than what follows, and gone by about 0.15 s?
- Is there something dark so the bright parts read? Is the centre a white blob?
- Do drawn shapes have hard silhouettes? Does any texture look like clip art (radially even, uniform outlines)?
- Does everything that moves show its speed?
- Does every layer show at normal distance? Does one layer bury another?
- Does a light tint the whole floor? Does it end cleanly with nothing left behind?
