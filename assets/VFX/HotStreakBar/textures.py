from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent


FLAME_TOP_ROW = 160


def black_to_alpha(name):
    path = HERE / f"{name}.png"
    pixels = np.asarray(Image.open(path).convert("RGB")).astype(float) / 255
    pixels = pixels[FLAME_TOP_ROW:]
    alpha = pixels.max(axis=2)
    out = np.dstack([np.ones_like(pixels), alpha])
    Image.fromarray((out * 255).astype(np.uint8), "RGBA").save(path)


if __name__ == "__main__":
    black_to_alpha("FireFront")
