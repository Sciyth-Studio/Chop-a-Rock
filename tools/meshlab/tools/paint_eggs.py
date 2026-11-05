# Paints the body textures for the painted zone eggs, with studs baked in, because a MaterialVariant
# would replace the TextureID. Lay out matches Egg.BuildPainted: U runs around the shell, V up it.
#   blender -b -P tools/meshlab/tools/paint_eggs.py -- [names...]
# Writes assets/Eggs/<Name>/<Name>_body.png. The studs match EggShell's plain eggs: the Animal Stud
# tile every 0.5 studs, laid out per facet of the 12-sided shell.
import os
import sys
import bpy
import numpy as np

here = os.path.dirname(os.path.abspath(__file__))
repo = os.path.abspath(os.path.join(here, "..", "..", ".."))
root = os.path.join(repo, "assets", "Eggs")
tile_path = os.path.join(repo, "assets", "Pets", "Animals", "SmallStud_Faint35.png")

W, H = 2048, 1024
EGG_HEIGHT, EGG_RADIUS = 5.6, 2.4
SIDES = 12
STUD_TILE = 0.5
PROFILE_T = np.array([0, 0.07, 0.2, 0.36, 0.52, 0.68, 0.82, 0.93, 0.985], np.float32)
PROFILE_R = np.array([0.5, 0.76, 0.94, 1, 0.96, 0.84, 0.64, 0.38, 0.12], np.float32)

U, V = np.meshgrid((np.arange(W) + 0.5) / W, (np.arange(H) + 0.5) / H)
U, V = U.astype(np.float32), V.astype(np.float32)
RADIUS = np.interp(V, PROFILE_T, PROFILE_R).astype(np.float32) * EGG_RADIUS
CIRCUMFERENCE = RADIUS * np.pi * 2


def rgb(r, g, b):
    return np.array([r, g, b], dtype=np.float32) / 255


def load_tile():
    image = bpy.data.images.load(tile_path)
    w, h = image.size
    pixels = np.array(image.pixels[:], dtype=np.float32).reshape(h, w, image.channels)[..., :3]
    bpy.data.images.remove(image)
    return pixels


TILE = load_tile()


def stud_map():
    offset = 15 / 360
    columns = ((U - offset) % 1) * SIDES
    across = columns % 1
    row = np.clip(np.searchsorted(PROFILE_T, V, side="right") - 1, 0, len(PROFILE_T) - 2)
    t0, t1 = PROFILE_T[row], PROFILE_T[row + 1]
    r0, r1 = PROFILE_R[row] * EGG_RADIUS, PROFILE_R[row + 1] * EGG_RADIUS
    along = (V - t0) / (t1 - t0)
    slant = np.hypot((t1 - t0) * EGG_HEIGHT, r1 - r0)
    width = 2 * RADIUS * np.sin(np.pi / SIDES)
    x = (across - 0.5) * width
    y = along * slant
    h, w = TILE.shape[:2]
    ix = (((x / STUD_TILE) % 1) * w).astype(np.int32) % w
    iy = (((y / STUD_TILE) % 1) * h).astype(np.int32) % h
    return TILE[iy, ix]


STUDS = stud_map()


def save(name, art, keep_from=None):
    studded = art * STUDS
    if keep_from is not None:
        keep = V > keep_from
        studded[keep] = art[keep]
    folder = os.path.join(root, name)
    os.makedirs(folder, exist_ok=True)
    rgba = np.ones((H, W, 4), dtype=np.float32)
    rgba[..., :3] = np.clip(studded, 0, 1)
    image = bpy.data.images.new(name, W, H)
    image.colorspace_settings.name = "Non-Color"
    image.pixels = rgba.ravel().tolist()
    image.filepath_raw = os.path.join(folder, f"{name}_body.png")
    image.file_format = "PNG"
    image.save()
    bpy.data.images.remove(image)
    print("painted", name)


def front_coords():
    du = (U - 0.25 + 0.5) % 1 - 0.5
    return du * CIRCUMFERENCE, V * EGG_HEIGHT


def fill(art, x, y, points, colour):
    px = np.array([p[0] for p in points], np.float32)
    py = np.array([p[1] for p in points], np.float32)
    window = (x > px.min()) & (x < px.max()) & (y > py.min()) & (y < py.max())
    inside = np.zeros(x.shape, bool)
    for i in range(len(points)):
        j = (i + 1) % len(points)
        if py[i] == py[j]:
            continue
        crosses = (py[i] > y) != (py[j] > y)
        at = (px[j] - px[i]) * (y - py[i]) / (py[j] - py[i]) + px[i]
        inside ^= crosses & (x < at)
    art[inside & window] = colour


def paint_tiki():
    gold, brown, dark, nose, nose_edge = rgb(255, 170, 0), rgb(95, 62, 38), rgb(55, 32, 18), rgb(235, 120, 20), rgb(170, 80, 15)
    leaf = rgb(50, 170, 45)
    art = np.empty((H, W, 3), np.float32)
    art[:] = gold
    x, y = front_coords()
    for side in (1, -1):
        fill(art, x, y, [(side * 0.18, 3.62), (side * 1.5, 3.92), (side * 1.5, 3.42), (side * 0.18, 3.14)], brown)
        fill(art, x, y, [(side * 0.42, 3.0), (side * 1.38, 3.2), (side * 1.38, 2.8), (side * 0.42, 2.6)], dark)
    fill(art, x, y, [(-0.32, 3.14), (0.32, 3.14), (0.72, 1.86), (-0.72, 1.86)], nose_edge)
    fill(art, x, y, [(-0.22, 3.14), (0.22, 3.14), (0.56, 1.98), (-0.56, 1.98)], nose)
    fill(art, x, y, [(-1.45, 1.72), (1.45, 1.72), (1.15, 0.62), (-1.15, 0.62)], brown)
    fill(art, x, y, [(-1.1, 1.46), (1.1, 1.46), (0.88, 0.88), (-0.88, 0.88)], dark)
    for k in range(-2, 3):
        fill(art, x, y, [(k * 0.36 - 0.12, 1.46), (k * 0.36 + 0.12, 1.46), (k * 0.36 + 0.09, 1.22), (k * 0.36 - 0.09, 1.22)], rgb(240, 225, 185))
    art[V > 0.988] = leaf
    save("JungleTiki", art, keep_from=0.988)


def paint_ember():
    rng = np.random.default_rng(7)
    points = []
    for t, n in [(0.1, 5), (0.32, 6), (0.54, 6), (0.74, 5), (0.91, 3)]:
        for k in range(n):
            points.append(((k + rng.uniform(0.25, 0.75)) / n, t + rng.uniform(-0.035, 0.035)))
    aspect = 2.6
    near, second = np.full(U.shape, 9.0, np.float32), np.full(U.shape, 9.0, np.float32)
    for px, py in points:
        du = np.abs(U - px)
        du = np.minimum(du, 1 - du) * aspect
        d = np.sqrt(du * du + (V - py) ** 2).astype(np.float32)
        second = np.where(d < near, near, np.minimum(second, d))
        near = np.minimum(near, d)
    wobble = 0.006 * np.sin(U * np.pi * 2 * 9 + V * 31) + 0.004 * np.sin(V * 67 + U * np.pi * 2 * 5)
    edge = np.abs(second - near + wobble)
    art = np.empty((H, W, 3), np.float32)
    art[:] = rgb(60, 50, 50)
    for width, colour in ((0.042, rgb(140, 50, 15)), (0.028, rgb(255, 110, 0)), (0.011, rgb(255, 215, 70))):
        art[edge < width] = colour
    save("VolcanoEmber", art)


def paint_crater():
    teeth = 9
    tri = np.abs(((U * teeth) % 1) * 2 - 1)
    index = (U * teeth).astype(int) % teeth
    depth = np.array([0.1, 0.06, 0.13, 0.07, 0.11, 0.05, 0.14, 0.08, 0.1], np.float32)[index]
    art = np.empty((H, W, 3), np.float32)
    art[:] = rgb(235, 100, 30)
    art[V > 0.74 - depth * (1 - tri)] = rgb(170, 50, 30)
    art[V > 0.99] = rgb(255, 255, 255)
    save("VolcanoCrater", art, keep_from=0.83)


RUNES = {
    "Fehu": [((0, 0), (0, 1)), ((0, 0.6), (0.5, 1)), ((0, 0.35), (0.5, 0.75))],
    "Uruz": [((0, 0), (0, 1)), ((0, 1), (0.5, 0.55)), ((0.5, 0.55), (0.5, 0))],
    "Thurisaz": [((0, 0), (0, 1)), ((0, 0.72), (0.4, 0.5)), ((0.4, 0.5), (0, 0.28))],
    "Ansuz": [((0, 0), (0, 1)), ((0, 1), (0.45, 0.7)), ((0, 0.7), (0.45, 0.4))],
    "Raido": [((0, 0), (0, 1)), ((0, 1), (0.45, 0.75)), ((0.45, 0.75), (0, 0.5)), ((0, 0.5), (0.45, 0))],
    "Kenaz": [((0.4, 1), (0, 0.5)), ((0, 0.5), (0.4, 0))],
    "Gebo": [((0, 0), (0.7, 1)), ((0.7, 0), (0, 1))],
    "Wunjo": [((0, 0), (0, 1)), ((0, 1), (0.45, 0.75)), ((0.45, 0.75), (0, 0.5))],
    "Hagalaz": [((0, 0), (0, 1)), ((0.5, 0), (0.5, 1)), ((0, 0.7), (0.5, 0.3))],
    "Nauthiz": [((0.25, 0), (0.25, 1)), ((0, 0.7), (0.5, 0.4))],
    "Isa": [((0, 0), (0, 1))],
    "Jera": [((0.25, 0.95), (0, 0.65)), ((0, 0.65), (0.25, 0.4)), ((0.35, 0.6), (0.6, 0.35)), ((0.6, 0.35), (0.35, 0.05))],
    "Eihwaz": [((0.25, 0), (0.25, 1)), ((0.25, 1), (0.55, 0.8)), ((0.25, 0), (-0.05, 0.2))],
    "Perthro": [((0, 0), (0, 1)), ((0, 1), (0.4, 0.72)), ((0.4, 0.72), (0.4, 0.6)), ((0, 0), (0.4, 0.28)), ((0.4, 0.28), (0.4, 0.4))],
    "Algiz": [((0.3, 0), (0.3, 1)), ((0.3, 0.55), (0, 1)), ((0.3, 0.55), (0.6, 1))],
    "Sowilo": [((0.5, 1), (0, 0.6)), ((0, 0.6), (0.5, 0.4)), ((0.5, 0.4), (0, 0))],
    "Tiwaz": [((0.3, 0), (0.3, 1)), ((0.3, 1), (0, 0.65)), ((0.3, 1), (0.6, 0.65))],
    "Berkano": [((0, 0), (0, 1)), ((0, 1), (0.45, 0.75)), ((0.45, 0.75), (0, 0.5)), ((0, 0.5), (0.45, 0.25)), ((0.45, 0.25), (0, 0))],
    "Ehwaz": [((0, 0), (0, 1)), ((0.6, 0), (0.6, 1)), ((0, 1), (0.3, 0.65)), ((0.3, 0.65), (0.6, 1))],
    "Mannaz": [((0, 0), (0, 1)), ((0.6, 0), (0.6, 1)), ((0, 1), (0.6, 0.5)), ((0.6, 1), (0, 0.5))],
    "Laguz": [((0, 0), (0, 1)), ((0, 1), (0.4, 0.65))],
    "Ingwaz": [((0.3, 0.2), (0.6, 0.5)), ((0.6, 0.5), (0.3, 0.8)), ((0.3, 0.8), (0, 0.5)), ((0, 0.5), (0.3, 0.2))],
    "Othala": [((0.3, 1), (0.6, 0.7)), ((0.6, 0.7), (0.3, 0.4)), ((0.3, 0.4), (0, 0.7)), ((0, 0.7), (0.3, 1)), ((0.3, 0.4), (0, 0)), ((0.3, 0.4), (0.6, 0))],
    "Dagaz": [((0, 0), (0, 1)), ((0.7, 0), (0.7, 1)), ((0, 1), (0.7, 0)), ((0, 0), (0.7, 1))],
}
ROWS = [
    (0.5, 1.15, ["Algiz", "Fehu", "Ansuz", "Raido", "Hagalaz", "Tiwaz", "Berkano", "Mannaz", "Othala", "Dagaz"]),
    (0.77, 0.72, ["Isa", "Kenaz", "Laguz", "Sowilo", "Gebo", "Nauthiz"]),
    (0.22, 0.85, ["Uruz", "Thurisaz", "Wunjo", "Jera", "Eihwaz", "Perthro", "Ehwaz", "Ingwaz"]),
]


def paint_rune():
    distance = np.full(U.shape, 9.0, np.float32)
    for centre_t, height, names in ROWS:
        for k, name in enumerate(names):
            centre_u = (0.25 + k / len(names)) % 1
            segments = RUNES[name]
            xs = [p[0] for s in segments for p in s]
            mid_x = (min(xs) + max(xs)) / 2
            x = ((U - centre_u + 0.5) % 1 - 0.5) * CIRCUMFERENCE
            y = (V - centre_t) * EGG_HEIGHT
            window = (np.abs(y) < height) & (np.abs(x) < height)
            for a, b in segments:
                ax, ay = (a[0] - mid_x) * height, (a[1] - 0.5) * height
                bx, by = (b[0] - mid_x) * height, (b[1] - 0.5) * height
                dx, dy = bx - ax, by - ay
                f = np.clip(((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy), 0, 1)
                d = np.hypot(x - ax - f * dx, y - ay - f * dy).astype(np.float32)
                distance = np.where(window, np.minimum(distance, d), distance)
    art = np.empty((H, W, 3), np.float32)
    art[:] = rgb(90, 85, 110)
    for width, colour in ((0.15, rgb(60, 45, 95)), (0.105, rgb(170, 80, 255)), (0.045, rgb(235, 195, 255))):
        art[distance < width] = colour
    save("RuinsRune", art)


painters = {"JungleTiki": paint_tiki, "VolcanoEmber": paint_ember, "VolcanoCrater": paint_crater, "RuinsRune": paint_rune}
names = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
for name in names or painters:
    painters[name]()
