import os

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SLIVER_DEGREES = 30


def coords(size):
    axis = (np.arange(size) + 0.5) / size * 2 - 1
    x, y = np.meshgrid(axis, axis)
    return x, y, np.hypot(x, y), np.arctan2(y, x)


def smooth(edge0, edge1, value):
    t = np.clip((value - edge0) / (edge1 - edge0), 0, 1)
    return t * t * (3 - 2 * t)


def kit(name, size, zoom=1.0):
    big = int(round(size * zoom))
    image = Image.open(os.path.join(HERE, name)).convert("RGBA").resize((big, big), Image.LANCZOS)
    data = np.asarray(image).astype(np.float64) / 255
    value = data[..., :3].max(axis=2) * data[..., 3]
    start = (big - size) // 2
    return value[start:start + size, start:start + size]


def noise(size, cells, seed):
    rng = np.random.default_rng(seed)
    grid = rng.random((cells + 1, cells + 1))
    grid[-1, :] = grid[0, :]
    grid[:, -1] = grid[:, 0]
    axis = np.arange(size) / size * cells
    i = axis.astype(int)
    f = axis - i
    f = f * f * (3 - 2 * f)
    top = grid[i][:, i] * (1 - f)[None, :] + grid[i][:, i + 1] * f[None, :]
    bottom = grid[i + 1][:, i] * (1 - f)[None, :] + grid[i + 1][:, i + 1] * f[None, :]
    return top * (1 - f)[:, None] + bottom * f[:, None]


def save(name, alpha, rgb=None):
    alpha = np.clip(alpha, 0, 1)
    height, width = alpha.shape
    if rgb is None:
        rgb = np.ones((height, width, 3))
    out = np.dstack([np.clip(rgb, 0, 1), alpha])
    Image.fromarray((out * 255).round().astype(np.uint8), "RGBA").save(os.path.join(HERE, name + ".png"))
    print("wrote", name)


def slam_ring():
    size = 512
    _, _, r, _ = coords(size)
    inside = 1 - smooth(0.97, 1.0, r)
    fill = (0.28 + 0.2 * r) * inside
    ring = kit("KitSlamRing.png", size)
    cracks = np.zeros((size, size))
    web = kit("KitCrackWeb.png", 440)
    pad = (size - 440) // 2
    cracks[pad:pad + 440, pad:pad + 440] = np.clip(web * 1.6, 0, 1) * 0.85
    rim = smooth(0.9, 0.95, r) * (1 - smooth(0.985, 1.0, r))
    save("SlamRing", np.maximum.reduce([fill, ring * inside, cracks * inside, rim]))


def spot():
    size = 512
    _, _, r, _ = coords(size)
    inside = 1 - smooth(0.97, 1.0, r)
    fill = 0.3 * inside
    ring = kit("KitSpotRing.png", size, 1.5) * inside
    inner = np.exp(-((r - 0.45) / 0.025) ** 2) * 0.55
    dot = (1 - smooth(0.06, 0.1, r)) * 0.8
    save("Spot", np.maximum.reduce([fill, ring, inner, dot]))


def pocket():
    size = 512
    _, _, r, _ = coords(size)
    inside = 1 - smooth(0.95, 1.0, r)
    fill = (0.3 + 0.15 * smooth(0.5, 0.95, r)) * inside
    ring = np.clip(kit("KitPocketRing.png", size, 1.08) * 1.6, 0, 1) * inside
    rim = smooth(0.88, 0.93, r) * (1 - smooth(0.97, 1.0, r))
    save("Pocket", np.maximum.reduce([fill, ring, rim]))


def shadow():
    size = 256
    _, _, r, _ = coords(size)
    blob = np.clip(1 - r * r, 0, 1) ** 1.6 * 0.95
    save("Shadow", blob, np.zeros((size, size, 3)))


def ice_sheet():
    size = 512
    frost = 0.6 * noise(size, 8, 1) + 0.3 * noise(size, 24, 2) + 0.1 * noise(size, 64, 3)
    cracks = np.clip(kit("KitCrackTile.png", size) * 2.2, 0, 1)
    alpha = 0.45 + 0.35 * frost
    alpha = np.maximum(alpha, cracks * 0.95)
    shade = 0.82 + 0.18 * frost
    rgb = np.dstack([shade, shade, shade])
    rgb = np.maximum(rgb, cracks[..., None])
    save("IceSheet", alpha, rgb)


def fan():
    size = 1024
    _, _, r, theta = coords(size)
    half_gap = np.radians(SLIVER_DEGREES) / 2
    to_gap = np.pi - np.abs(theta)
    edge_distance = r * np.sin(np.clip(np.abs(to_gap - half_gap), 0, np.pi / 2))
    in_danger = smooth(-0.002, 0.002, to_gap - half_gap)
    hole = smooth(0.02, 0.04, r)
    bands = 0.5 + 0.5 * np.cos(r * 2 * np.pi * 18)
    fill = (0.3 + 0.12 * bands) * in_danger * hole
    edge = np.exp(-(edge_distance / 0.006) ** 2) * hole
    save("Fan", np.maximum(fill, edge))


def tail():
    width, height = 512, 64
    along = (np.arange(width) + 0.5) / width
    across = (np.arange(height) + 0.5) / height * 2 - 1
    u, v = np.meshgrid(along, across)
    body = np.exp(-(v / 0.55) ** 2)
    core = np.exp(-(v / 0.18) ** 2)
    ramp = smooth(0.0, 0.25, u) * (1 - smooth(0.9, 1.0, u) * 0.6)
    save("Tail", np.maximum(body * 0.7, core) * (0.35 + 0.65 * ramp))


def arrow():
    size = 256
    x, y, _, _ = coords(size)

    def chevron(thickness):
        apex_y = -0.55
        arm = np.abs(x)
        line = apex_y + arm * 1.0
        distance = np.abs(y - line) / np.sqrt(2)
        span = (arm <= 0.7) & (y >= apex_y - 0.2)
        return np.where(span, 1 - smooth(thickness - 0.03, thickness, distance), 0)

    outline = chevron(0.2)
    fill = chevron(0.14)
    rgb = np.dstack([fill, fill, fill])
    save("Arrow", np.maximum(outline, fill), rgb)


if __name__ == "__main__":
    slam_ring()
    spot()
    pocket()
    shadow()
    ice_sheet()
    fan()
    tail()
    arrow()
