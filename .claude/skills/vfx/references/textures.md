# Drawing textures and mesh shapes

Texture guidance condensed from Roqer's VFX texture reference by S4US; the scripts are derived from Roqer's Blender helpers, used with permission.

## Loading the scripts

Blender must be running with the MCP add-on. Without Blender open, `vfx_draw` also runs under Blender's bundled Python (it has numpy): write a script in the scratchpad that loads the module the same way and run it with `"C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -I script.py` (worked 2026-10-09 for the aura textures). Windows has no other Python.

Run once per Blender session (and again after editing a script) with `execute_blender_code`:

```python
import sys, types, os
base = r"C:\Users\Admin\Documents\RobloxDev\.claude\skills\vfx\scripts"
for n in ("vfx_draw", "vfx_shapes"):
    p = os.path.join(base, n + ".py")
    m = types.ModuleType(n); m.__file__ = p
    exec(compile(open(p, encoding="utf-8").read(), p, "exec"), m.__dict__)
    sys.modules[n] = m
vd, vs = sys.modules["vfx_draw"], sys.modules["vfx_shapes"]
```

Later calls use `vd = sys.modules["vfx_draw"]`. `vfx_draw` needs only numpy; `vfx_shapes` touches only objects it names and its own `VFXShapes` collection.

## What good textures look like

- **Custom, white, shape in alpha.** The particle's `Color` tints them.
- **Two families.** Drawn matter (chips, puffs, slashes, stars, splashes) has crisp edges: cut with `vd.cut(field, soft=0.006 to 0.01)`. Light (glows, flares, glints, soft rings) falls off smoothly from a hot core and keeps the symmetry of light: four equal straight arms, round glows.
- **Drawn matter is lopsided.** Uneven counts, lengths, spacing; strokes that taper like pen pressure; detail from holes and notches, not shading (at most a lit and a shadow tone). Even spacing, mirror symmetry and uniform outlines read as clip art.
- **A flash keeps a solid centre.** Small holes punched into a core read as eyes.
- **Smoke:** clean cel puffs suit this game's cartoon look; mottled billows with a crisp rim read as heavier.
- **Detail density is the quality bar.** The user's reference textures (`studied.md`) are busy inside: a magic circle with concentric bands, glyphs and spokes; swirl rings of several tapered strokes at different radii; fire flipbooks with painted inner tongues and a darker rim. A single shape per texture (one leaf, one gust arc, one dot) looks cheap next to them even with many layers stacked. Before drawing, list the 3 to 6 sub-shapes inside the texture.
- **Beam textures run vertically:** the image's Y axis maps along the beam, from Attachment0 to Attachment1, and X maps across its width. A pillar drawn with its bright core along X showed nothing (2026-10-10); draw the core as a vertical line.
- **Ground and ring textures need structure all the way round:** rings of ticks, runes or notches, an inner and an outer band, broken arcs. A plain soft ring reads as a halo, not a circle.
- **Frames grow, then break apart.** Peak around frame 4 to 6 of 16, then eaten into 2 to 6 pieces; last cells may be blank.
- **Size:** single textures 256 or 512 px; flipbook sheets are always 1024 x 1024 (`Grid4x4` = 256 px frames, the usual choice). Leave padding inside each cell.
- Roblox has no multiply blend: darken with a black layer at `LightEmission` 0. Use `additive=True` only for a layer that is always `LightEmission` 1.

## vfx_draw

Coordinates run -1 to 1, x right, y up. Shapes are fields: positive inside. Combine with `np.maximum` (union), `np.minimum` (intersection), `np.minimum(a, -b)` (subtract).

| Function | Gives |
| --- | --- |
| `grid(size)` | `x, y` arrays |
| `polar(x, y)` | `r, angle` |
| `noise(size, scale, octaves, seed)` | Tiling smooth noise, 0 to 1 |
| `voronoi(size, cells, seed)` | `nearest, edge`; `cut(-edge + 0.05)`-style cracks, `nearest < r` blobs |
| `sample(image, u, v)` | Wrapped bilinear lookup, 0 to 1 coordinates; scroll or warp noise per frame |
| `warp(x, y, amount, scale, seed, drift)` | Noise-pushed coordinates: draw with them for organic shapes |
| `spline(points, samples, closed)` | Smooth path through control points |
| `stroke(x, y, path, width, head, tail)` | Brush stroke along a path; `width` a number, list (head to tail) or function of u; draw on by raising `tail`, erase by raising `head` |
| `blob(x, y, radius, lobes, rough, seed, center)` | One-piece lumpy blob for puffs and chunks |
| `glow(r, radius)` | Gaussian falloff for light |
| `cut(field, at, soft)` | Hard edge |
| `ease_out(t, power)` | Fast then slow growth |
| `texture(effect, name, image, size, additive)` | Writes `assets/VFX/<effect>/<name>.png`; `image` is an array or `f(size)` |
| `sheet(effect, name, frame, grid, loop, padding, additive)` | Writes a 1024 flipbook; `frame(t, size)`, t 0 to 1 |
| `studio_preview(path)` | Copies into Studio, returns an `rbxasset://textures/vfx-preview/...` address |

A drawing function returns alpha (white shape), `(alpha, value)` for a grey tone under one `Color`, or an RGB/RGBA array. `texture` and `sheet` return a report: `review` (a PNG over a dark ground: open it with Read and look), `coverage` per frame, `peak_frame`, `empty_frames`, `clipped_frames` (drawing touches the cell edge: shrink or pad it), `held_frames`, and the `layout` and `mode` to set on the emitter.

## Examples

```python
import numpy as np
vd = sys.modules["vfx_draw"]
HOLES = vd.noise(256, 6, 4, 1)

def chip_burst(t, size):
    x, y = vd.grid(size)
    rng = np.random.default_rng(7)
    reach = vd.ease_out(t * 1.8)
    field = np.full_like(x, -1.0)
    for _ in range(7):
        a = rng.uniform(0, 2 * np.pi); d = rng.uniform(0.3, 0.75) * reach
        r = rng.uniform(0.08, 0.15) * (1 - 0.5 * t)
        center = (np.cos(a) * d, np.sin(a) * d - 0.25 * t * t)
        field = np.maximum(field, vd.blob(x, y, r, 4, 0.55, int(rng.integers(999)), center))
    return vd.cut(field, soft=0.006)

def cel_puff(t, size):
    x, y = vd.grid(size)
    wx, wy = vd.warp(x, y, 0.08, 4, 5, t * 0.3)
    radius = 0.2 + 0.4 * vd.ease_out(t * 2)
    body = vd.blob(wx, wy, radius, 9, 0.7, 3)
    lit = vd.blob(wx + 0.1, wy - 0.1, radius, 9, 0.7, 3)
    holes = vd.sample(HOLES, x * 0.5, y * 0.5 + t * 0.2) - t * 1.3 + 0.6
    alpha = vd.cut(body) * vd.cut(holes + body * 0.4, soft=0.01)
    return alpha, 0.55 + 0.45 * vd.cut(lit, 0.03)

def impact_star(t, size):
    x, y = vd.grid(size)
    r, ang = vd.polar(*vd.warp(x, y, 0.03, 3, 2))
    rng = np.random.default_rng(5)
    spikes = np.zeros_like(r)
    for i in range(9):
        a = (i + rng.uniform(-0.3, 0.3)) / 9 * 2 * np.pi
        d = np.angle(np.exp(1j * (ang - a)))
        spikes = np.maximum(spikes, np.exp(-((d / rng.uniform(0.09, 0.16)) ** 2)) * rng.uniform(0.45, 1.0))
    reach = (0.28 + 0.62 * spikes) * (0.55 + 0.45 * vd.ease_out(t * 4)) * (1 - 0.75 * t)
    return vd.cut(reach - r, soft=0.006)

def glint(size):
    x, y = vd.grid(size)
    r, _ = vd.polar(x, y)
    def arm(along, across):
        fade = np.clip(1 - np.abs(along) / 0.95, 0, 1)
        return np.exp(-(across / (0.035 * fade + 1e-4)) ** 2) * fade ** 1.5
    return np.clip(np.maximum(arm(y, x), arm(x, y)) + vd.glow(r, 0.07) + 0.3 * vd.glow(r, 0.3), 0, 1)

for name, fn in (("Chips", chip_burst), ("Puff", cel_puff), ("Star", impact_star)):
    report = vd.sheet("ChopHit", name, fn)
vd.texture("ChopHit", "Glint", glint, 256)
```

Look at every review image and ask: is anything evenly spaced or mirror-symmetric that shouldn't be? Is a flare one smooth core with equal straight arms? Is there a stray hole in a solid shape? Is drawn matter crisp? Do the frames grow and break apart, or only scale? Would it survive at game distance?

## Using a sheet

Set `Texture` (preview address while iterating), `FlipbookLayout` `Grid4x4`, `FlipbookMode` `OneShot` (bursts; `Loop` with `FlipbookStartRandom` for steady fire, max 30 fps), and pick `Lifetime` so the frames play at the intended speed. Ignore `FlipbookIncompatible`'s size warning; Studio shows it even for valid sheets. To confirm frames play, hold one particle (`TimeScale` 0) at a few ages and capture: each shot should show one frame, not the grid.

## Mesh shapes (vfx_shapes)

Built in studs around the origin, facing Roblox forward (Blender -Y), one open sheet with UVs (U along the sweep, V across).

| Function | Shape |
| --- | --- |
| `crescent(name, radius, width, sweep=160, segments=40, taper=True)` | Flat slash crescent |
| `ring(name, radius, width=0.5, height=0, top_radius=None)` | Flat shockwave band, or a wall when `height` > 0 (flare `top_radius` for a blast) |
| `cone(name, radius, height, tip_radius=0)` | Open cone |
| `spiral(name, radius, height, width, turns=1.5, top_radius=None)` | Rising ribbon: tornado, aura, charge-up |
| `dome(name, radius, segments=32, rings=12, full_sphere=False)` | Dome or sphere shell |
| `surface(name, point, columns, rows)` | Anything else: `point(u, v)` returns (x, y, z) in studs |
| `stats(obj)` | Triangles and size in studs (width, height, depth) |
| `export_fbx(objects, effect, file_name)` | Writes `assets/VFX/<effect>/<file_name>.fbx` at 1 unit = 1 stud |

Export all of an effect's shapes into one FBX. The user imports it (Import 3D, default dimensions, Anchored); then set `Material` Neon (or ForceField for a shimmer), `Color`, `DoubleSided`, `RenderFidelity` Precise, and turn off `CanCollide`, `CanQuery`, `CanTouch`, `CastShadow`. Check orientation against a known part after import (rock-model skill gotchas). Animate through a `Start`/`End` Model (SKILL.md).

Mesh gotchas:
- `TextureID` on a MeshPart ignores alpha. Fade the part's own `Transparency` (Neon fading 0 to 1 is the reliable mesh effect), or put a Decal on the face of a `Transparency` 1 part (projected across the box face, ignoring UVs).
- A big half-transparent shell looks like tinted plastic; keep it faint (0.85 to 0.96) and let particles carry the brightness.
- Under vertex colours keep `Color` white.
