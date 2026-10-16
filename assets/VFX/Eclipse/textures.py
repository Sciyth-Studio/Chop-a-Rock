import os

import numpy as np
from PIL import Image

OUT = os.path.dirname(os.path.abspath(__file__))
SIZE = 512
RNG = np.random.default_rng(7)


def corona():
    y, x = np.mgrid[0:SIZE, 0:SIZE].astype(np.float64)
    c = (SIZE - 1) / 2
    dx, dy = (x - c) / c, (y - c) / c
    r = np.sqrt(dx * dx + dy * dy)
    a = np.arctan2(dy, dx)

    moon = 0.36
    rim = np.exp(-(((r - moon) / 0.012) ** 2))

    streak = np.zeros_like(a)
    for _ in range(9):
        k = RNG.integers(2, 9)
        streak += RNG.uniform(0.3, 1.0) * np.cos(k * a + RNG.uniform(0, 2 * np.pi))
    streak = (streak - streak.min()) / (streak.max() - streak.min())
    reach = 0.09 + 0.15 * streak**2

    outside = np.clip(r - moon, 0, None)
    halo = np.exp(-outside / 0.07) * 0.9
    rays = np.exp(-outside / reach) * 0.65
    glow = (halo + rays) * (r >= moon)

    fade = np.clip((r - 0.45) / (0.95 - 0.45), 0, 1)
    edge = (1 - fade * fade * (3 - 2 * fade)) ** 2
    glow *= edge
    rim *= edge

    white = np.array([255, 245, 255], dtype=np.float64)
    pink = np.array([235, 160, 255], dtype=np.float64)
    purple = np.array([150, 55, 235], dtype=np.float64)
    t = np.clip(outside / 0.35, 0, 1)[..., None]
    glow_col = pink * (1 - t) + purple * t

    rgb = glow[..., None] * glow_col + rim[..., None] * white
    rgb = np.clip(rgb, 0, 255).astype(np.uint8)
    Image.fromarray(rgb, "RGB").save(os.path.join(OUT, "Corona.png"))


if __name__ == "__main__":
    corona()
