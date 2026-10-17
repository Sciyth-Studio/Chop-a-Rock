import os

import numpy as np
from PIL import Image

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

WIDTH, HEIGHT = 32, 256
BASE_ALPHA = 0.65
BAND_ALPHA = 0.9
BAND_CENTERS = (0.25, 0.75)
BAND_HALF_WIDTH = 0.09


def wall_bands():
    v = (np.arange(HEIGHT) + 0.5) / HEIGHT
    alpha = np.full(HEIGHT, BASE_ALPHA)
    for center in BAND_CENTERS:
        distance = np.abs((v - center + 0.5) % 1 - 0.5)
        band = BAND_ALPHA + (BASE_ALPHA - BAND_ALPHA) * np.clip(distance / BAND_HALF_WIDTH, 0, 1)
        alpha = np.maximum(alpha, band)
    image = np.full((HEIGHT, WIDTH, 4), 255, np.uint8)
    image[:, :, 3] = np.round(alpha * 255).astype(np.uint8)[:, None]
    Image.fromarray(image, "RGBA").save(os.path.join(OUTPUT_DIR, "WallBands.png"))


if __name__ == "__main__":
    wall_bands()
