"""VFX texture and flipbook drawing helpers (numpy only).

Derived from Roqer by S4US (https://github.com/S4US/Roqer, commit bf7118b,
apps/desktop/runtime/blender-worker.ts, AGPL-3.0-or-later), used with the
author's permission. Dev tool for drawing assets; nothing here ships in a game.
"""

import glob
import os
import shutil
import sys
import struct
import tempfile
import time
import zlib

import numpy as np

OUT = os.environ.get("VFX_OUT") or os.path.join(os.path.expanduser("~"), "VFX")
REVIEW = os.path.join(tempfile.gettempdir(), "vfx_review")
SHEET_SIDE = 1024
GRIDS = (2, 4, 8)
PREVIEW_FOLDER = "vfx-preview"


def grid(size=256):
    s = (np.arange(size, dtype=np.float32) + 0.5) / size * 2.0 - 1.0
    x, y = np.meshgrid(s, -s)
    return x, y


def polar(x, y):
    return np.hypot(x, y), np.arctan2(y, x)


def _smooth(t):
    return t * t * (3.0 - 2.0 * t)


def cut(field, at=0.0, soft=0.008):
    soft = max(float(soft), 1e-5)
    return _smooth(np.clip((np.asarray(field, np.float32) - at + soft) / (2.0 * soft), 0.0, 1.0))


def ease_out(t, power=3.0):
    return 1.0 - (1.0 - np.clip(t, 0.0, 1.0)) ** power


def noise(size=256, scale=4, octaves=4, seed=0):
    rng = np.random.default_rng(seed)
    total = np.zeros((size, size), np.float32)
    weight = 0.0
    for octave in range(octaves):
        n = max(1, int(round(scale))) * 2**octave
        lattice = rng.random((n, n)).astype(np.float32)
        coords = np.arange(size, dtype=np.float32) * n / size
        i0 = np.floor(coords).astype(int)
        f = _smooth(coords - i0)
        i0 %= n
        i1 = (i0 + 1) % n
        rows = lattice[i0] * (1 - f)[:, None] + lattice[i1] * f[:, None]
        layer = rows[:, i0] * (1 - f)[None, :] + rows[:, i1] * f[None, :]
        amplitude = 0.5**octave
        total += layer * amplitude
        weight += amplitude
    return total / weight


def voronoi(size=256, cells=8, seed=0):
    rng = np.random.default_rng(seed)
    points = rng.random((cells, cells, 2)).astype(np.float32)
    coords = (np.arange(size, dtype=np.float32) + 0.5) * cells / size
    px, py = np.meshgrid(coords, coords)
    cx, cy = np.floor(px).astype(int), np.floor(py).astype(int)
    nearest = np.full((size, size), 1e9, np.float32)
    second = np.full((size, size), 1e9, np.float32)
    for oy in (-1, 0, 1):
        for ox in (-1, 0, 1):
            gx, gy = cx + ox, cy + oy
            jitter = points[gy % cells, gx % cells]
            d = np.hypot(px - gx - jitter[..., 0], py - gy - jitter[..., 1])
            second = np.minimum(second, np.maximum(nearest, d))
            nearest = np.minimum(nearest, d)
    return nearest, second - nearest


def sample(image, u, v):
    image = np.asarray(image, np.float32)
    h, w = image.shape[:2]
    fx = (np.asarray(u, np.float32) % 1.0) * w - 0.5
    fy = (np.asarray(v, np.float32) % 1.0) * h - 0.5
    x0, y0 = np.floor(fx).astype(int), np.floor(fy).astype(int)
    tx, ty = fx - x0, fy - y0
    x0, y0 = x0 % w, y0 % h
    x1, y1 = (x0 + 1) % w, (y0 + 1) % h
    top = image[y0, x0] * (1 - tx) + image[y0, x1] * tx
    bottom = image[y1, x0] * (1 - tx) + image[y1, x1] * tx
    return top * (1 - ty) + bottom * ty


_warp_cache = {}


def warp(x, y, amount=0.08, scale=3, seed=0, drift=0.0):
    key = (int(scale), int(seed))
    if key not in _warp_cache:
        _warp_cache[key] = (noise(256, scale, 3, seed), noise(256, scale, 3, seed + 977))
    nx, ny = _warp_cache[key]
    u, v = x * 0.5 + 0.5 + drift, y * 0.5 + 0.5
    return x + (sample(nx, u, v) - 0.5) * 2.0 * amount, y + (sample(ny, u, v) - 0.5) * 2.0 * amount


def spline(points, samples=64, closed=False):
    p = np.asarray(points, np.float32)
    if p.ndim != 2 or p.shape[1] != 2 or len(p) < 2:
        raise ValueError("points must be two or more (x, y) pairs")
    if closed:
        p = np.vstack([p[-1:], p, p[:2]])
    else:
        p = np.vstack([2 * p[:1] - p[1:2], p, 2 * p[-1:] - p[-2:-1]])
    spans = len(p) - 3
    s = np.linspace(0.0, spans, max(samples, spans + 1), dtype=np.float32)
    i = np.minimum(np.floor(s).astype(int), spans - 1)
    t = (s - i)[:, None]
    p0, p1, p2, p3 = p[i], p[i + 1], p[i + 2], p[i + 3]
    return 0.5 * (
        2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t**2 + (3 * p1 - p0 - 3 * p2 + p3) * t**3
    )


def _width_profile(width):
    if callable(width):
        return lambda u: np.asarray(width(u), np.float32)
    if np.ndim(width) == 0:
        return lambda u: np.full_like(u, float(width))
    keys = np.asarray(width, np.float32)
    stops = np.linspace(0.0, 1.0, len(keys))
    return lambda u: np.interp(u, stops, keys).astype(np.float32)


def stroke(x, y, path, width=0.08, head=0.0, tail=1.0):
    path = np.asarray(path, np.float32)
    lengths = np.linalg.norm(np.diff(path, axis=0), axis=1)
    along = np.concatenate([[0.0], np.cumsum(lengths)]) / max(float(lengths.sum()), 1e-6)
    profile = _width_profile(width)
    field = np.full(np.shape(x), -1.0, np.float32)
    for k in range(len(path) - 1):
        a, d = path[k], path[k + 1] - path[k]
        t = np.clip(((x - a[0]) * d[0] + (y - a[1]) * d[1]) / max(float(d @ d), 1e-12), 0.0, 1.0)
        u = along[k] + (along[k + 1] - along[k]) * t
        inside = profile(u) * 0.5 - np.hypot(x - a[0] - d[0] * t, y - a[1] - d[1] * t)
        field = np.maximum(field, np.where((u >= head) & (u <= tail), inside, -1.0))
    return field


def blob(x, y, radius=0.5, lobes=7, rough=0.6, seed=0, center=(0.0, 0.0)):
    rng = np.random.default_rng(seed)
    rough = float(np.clip(rough, 0.0, 1.0))
    lean = rng.uniform(0.0, 2.0 * np.pi)
    core = radius * (1.0 - 0.4 * rough)
    bx = center[0] + np.cos(lean) * radius * 0.18 * rough
    by = center[1] + np.sin(lean) * radius * 0.18 * rough
    field = core - np.hypot(x - bx, y - by)
    for _ in range(max(1, int(lobes))):
        angle = rng.uniform(0.0, 2.0 * np.pi)
        reach = core * rng.uniform(0.75, 1.0)
        bias = 1.0 + 0.45 * rough * np.cos(angle - lean)
        r = radius * rough * rng.uniform(0.35, 0.8) * bias
        field = np.maximum(field, r - np.hypot(x - bx - np.cos(angle) * reach, y - by - np.sin(angle) * reach))
    return field


def glow(r, radius=0.4):
    return np.exp(-((r / radius) ** 2))


def _rgba(result, size, additive):
    if isinstance(result, tuple):
        alpha = np.asarray(result[0], np.float32)
        value = np.broadcast_to(np.asarray(result[1], np.float32), (size, size))
        rgba = np.stack([value, value, value, alpha], axis=-1)
    else:
        a = np.asarray(result, np.float32)
        if a.shape == (size, size):
            rgba = np.stack([np.ones_like(a), np.ones_like(a), np.ones_like(a), a], axis=-1)
        elif a.shape == (size, size, 3):
            rgba = np.concatenate([a, np.ones((size, size, 1), np.float32)], axis=-1)
        elif a.shape == (size, size, 4):
            rgba = a
        else:
            raise ValueError(f"expected a {size}x{size} alpha, (alpha, value), or RGB/RGBA array; got {a.shape}")
    rgba = np.clip(np.nan_to_num(rgba), 0.0, 1.0)
    if additive:
        rgba = np.concatenate([rgba[..., :3] * rgba[..., 3:], np.ones((size, size, 1), np.float32)], axis=-1)
    return rgba


def save_png(path, rgba):
    data = (np.clip(rgba, 0.0, 1.0) * 255.0 + 0.5).astype(np.uint8)
    h, w = data.shape[:2]
    rows = np.concatenate([np.zeros((h, 1), np.uint8), data.reshape(h, w * 4)], axis=1).tobytes()

    def chunk(tag, body):
        return struct.pack(">I", len(body)) + tag + body + struct.pack(">I", zlib.crc32(tag + body) & 0xFFFFFFFF)

    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(rows, 9)))
        f.write(chunk(b"IEND", b""))
    return path


def _review(name, rgba, cells=None, side=512):
    h = rgba.shape[0]
    step = max(1, h // side)
    small = rgba[: h - h % step, : h - h % step].reshape(h // step, step, h // step, step, 4).mean(axis=(1, 3))
    ground = np.array([0.13, 0.14, 0.17], np.float32)
    rgb = small[..., :3] * small[..., 3:] + ground * (1.0 - small[..., 3:])
    if cells:
        n = rgb.shape[0]
        for k in range(1, cells):
            line = k * n // cells
            rgb[line, :] = rgb[:, line] = (0.35, 0.35, 0.4)
    out = np.concatenate([rgb, np.ones(rgb.shape[:2] + (1,), np.float32)], axis=-1)
    return save_png(os.path.join(REVIEW, name + ".review.png"), out)


def _path(effect, name):
    if not name or any(c in name for c in '/\\:*?"<>|. '):
        raise ValueError(f"name must be a plain file name, got {name!r}")
    folder = os.path.join(OUT, effect)
    os.makedirs(folder, exist_ok=True)
    return os.path.join(folder, name + ".png")


def texture(effect, name, image, size=512, additive=False):
    if size not in (64, 128, 256, 512, 1024):
        raise ValueError("size must be 64, 128, 256, 512 or 1024")
    rgba = _rgba(image(size) if callable(image) else image, size, additive)
    path = save_png(_path(effect, name), rgba)
    alpha = rgba[..., 3] if not additive else rgba[..., :3].max(axis=-1)
    border = np.concatenate([alpha[0], alpha[-1], alpha[:, 0], alpha[:, -1]])
    return {
        "path": path,
        "review": _review(name, rgba),
        "coverage": round(float((alpha > 0.05).mean()), 3),
        "touches_edge": bool((border > 0.05).any()),
    }


def sheet(effect, name, frame, grid=4, loop=False, padding=4, additive=False):
    if grid not in GRIDS:
        raise ValueError("grid must be 2, 4 or 8")
    cell = SHEET_SIDE // grid
    inner = cell - 2 * padding
    count = grid * grid
    canvas = np.zeros((SHEET_SIDE, SHEET_SIDE, 4), np.float32)
    if additive:
        canvas[..., 3] = 1.0
    coverage, clipped = [], []
    for index in range(count):
        t = index / count if loop else index / (count - 1)
        rgba = _rgba(frame(t, inner), inner, additive)
        alpha = rgba[..., 3] if not additive else rgba[..., :3].max(axis=-1)
        coverage.append(round(float((alpha > 0.05).mean()), 3))
        border = np.concatenate([alpha[0], alpha[-1], alpha[:, 0], alpha[:, -1]])
        if (border > 0.05).any():
            clipped.append(index)
        row, col = divmod(index, grid)
        top, left = row * cell + padding, col * cell + padding
        canvas[top : top + inner, left : left + inner] = rgba
    path = save_png(_path(effect, name), canvas)
    still = [
        i
        for i in range(1, count)
        if coverage[i] > 0 and abs(coverage[i] - coverage[i - 1]) < 0.01 * max(coverage[i], coverage[i - 1])
    ]
    return {
        "path": path,
        "review": _review(name, canvas, grid),
        "layout": f"Grid{grid}x{grid}",
        "mode": "Loop" if loop else "OneShot",
        "coverage": coverage,
        "peak_frame": int(np.argmax(coverage)),
        "empty_frames": [i for i, c in enumerate(coverage) if c == 0],
        "clipped_frames": clipped,
        "held_frames": still,
    }


def _studio_content_folders():
    if sys.platform == "darwin":
        apps = ("/Applications/RobloxStudio.app", os.path.expanduser("~/Applications/RobloxStudio.app"))
        return [os.path.join(a, "Contents", "Resources", "content") for a in apps if os.path.isdir(a)]
    root = os.path.join(os.environ.get("LOCALAPPDATA", ""), "Roblox", "Versions")
    return [
        os.path.join(os.path.dirname(p), "content")
        for p in glob.glob(os.path.join(root, "*", "RobloxStudioBeta.exe"))
    ]


def studio_preview(path):
    folders = _studio_content_folders()
    if not folders:
        raise RuntimeError("no Roblox Studio install found")
    stem = os.path.splitext(os.path.basename(path))[0]
    file_name = f"{stem}-{int(time.time())}.png"
    for content in folders:
        folder = os.path.join(content, "textures", PREVIEW_FOLDER)
        os.makedirs(folder, exist_ok=True)
        shutil.copyfile(path, os.path.join(folder, file_name))
    return f"rbxasset://textures/{PREVIEW_FOLDER}/{file_name}"
