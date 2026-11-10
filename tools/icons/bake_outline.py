import argparse
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage


def bake(source: Path, target: Path, size: int, thickness: float, color: tuple[int, int, int]) -> None:
    image = Image.open(source).convert("RGBA")
    bbox = image.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
    if bbox:
        image = image.crop(bbox)
    content = size - 2 * (round(size * thickness) + 4)
    scale = content / max(image.size)
    image = image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))), Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(image, ((size - image.width) // 2, (size - image.height) // 2))

    pixels = np.array(canvas).astype(np.float32) / 255
    alpha = pixels[..., 3]
    distance = ndimage.distance_transform_edt(alpha < 0.5)
    ring = np.clip(size * thickness + 0.5 - distance, 0, 1)
    outline_alpha = np.maximum(ring, alpha)

    rgb = pixels[..., :3] * alpha[..., None] + np.array(color, np.float32)[None, None, :] / 255 * (1 - alpha[..., None])
    result = np.dstack([rgb, outline_alpha])
    result[outline_alpha == 0, :3] = 0
    Image.fromarray((result * 255 + 0.5).astype(np.uint8), "RGBA").save(target)


def main() -> None:
    parser = argparse.ArgumentParser(description="Bake a solid outline into icon PNGs.")
    parser.add_argument("sources", nargs="+", type=Path)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--size", type=int, default=512)
    parser.add_argument("--thickness", type=float, default=0.034)
    parser.add_argument("--color", default="0,0,0")
    args = parser.parse_args()
    color = tuple(int(part) for part in args.color.split(","))
    args.out.mkdir(parents=True, exist_ok=True)
    for source in args.sources:
        target = args.out / f"{source.stem}.png"
        bake(source, target, args.size, args.thickness, color)
        print(target)


if __name__ == "__main__":
    main()
