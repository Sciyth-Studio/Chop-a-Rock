#!/usr/bin/env python3
"""kit: browse and use the VFX texture kit (C:/Users/Admin/Downloads/VFX Assets) without opening every file.

The kit stays outside the repo. Its catalog and contact sheets live in <kit>/_catalog/.
Set VFX_KIT or pass --kit to use another location.

    kit.py index                               build _catalog/catalog.json and the contact sheets
    kit.py folders                             folders with counts and their contact sheet pages
    kit.py search <words> [--type sprite|flipbook|beam] [--kind tintable|additive|baked]
                          [--edge crisp|soft|mixed] [--limit 40]
    kit.py sheet <id ...> -o <png>             contact sheet of chosen ids, to compare
    kit.py prepare <id ...> --effect <Effect> [--name <Name> ...] [--size 512]
                                               copy into assets/VFX/<Effect>/ at Roblox sizes, record the source
"""
import json
import os
import re
import sys

KIT = os.environ.get("VFX_KIT", r"C:\Users\Admin\Downloads\VFX Assets")
REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", ".."))
TYPES = {"1_Normal": "sprite", "2_Flipbooks": "flipbook", "3_BeamsTrails": "beam"}
JUNK = {"png", "jpg", "new", "document", "untitled", "extracted", "copy", "the", "and", "idk", "idfk", "ahh"}
PAGE = 48
COLUMNS = 8
CELL = 128


def _catalog_dir():
    return os.path.join(KIT, "_catalog")


def _catalog_path():
    return os.path.join(_catalog_dir(), "catalog.json")


def _slug(text):
    return re.sub(r"[^A-Za-z0-9]+", "_", text).strip("_")


def _words(rel):
    tokens = re.split(r"[^A-Za-z]+", os.path.splitext(rel)[0].replace(os.sep, " "))
    return sorted({t.lower() for t in tokens if len(t) > 2 and t.lower() not in JUNK})


def _ink(image):
    import numpy
    rgba = numpy.asarray(image.convert("RGBA"), dtype=numpy.float32) / 255.0
    alpha = rgba[..., 3]
    if alpha.min() > 0.99:
        return rgba[..., :3].max(axis=-1), rgba, False
    return alpha, rgba, True


def _grid(ink):
    import numpy
    height, width = ink.shape
    if height != width:
        return None
    best, best_score = None, None
    for grid in (8, 4, 2):
        if width % grid:
            continue
        cell = width // grid
        edges = numpy.zeros_like(ink, dtype=bool)
        for k in range(1, grid):
            edges[:, k * cell - 1:k * cell + 1] = True
            edges[k * cell - 1:k * cell + 1, :] = True
        score = float((ink[edges] > 0.05).mean())
        if best_score is None or score < best_score - 1e-4:
            best, best_score = grid, score
        if score < 0.002:
            return grid
    return best if best_score is not None and best_score < 0.02 else None


def _describe(path, rel):
    import numpy
    from PIL import Image
    image = Image.open(path)
    width, height = image.size
    small = image.convert("RGBA")
    small.thumbnail((512, 512))
    ink, rgba, has_alpha = _ink(small)
    visible = ink > 0.05
    if not has_alpha:
        kind = "additive"
    else:
        rgb = rgba[..., :3]
        brightest = rgb.max(-1)
        lit = visible & (brightest > 0.08)
        saturation = ((brightest - rgb.min(-1)) / numpy.maximum(brightest, 1e-3))[lit].mean() if lit.any() else 0.0
        kind = "baked" if saturation >= 0.2 else "tintable"
    solid = ink > 0.5
    inner = solid.copy()
    inner[1:] &= solid[:-1]
    inner[:-1] &= solid[1:]
    inner[:, 1:] &= solid[:, :-1]
    inner[:, :-1] &= solid[:, 1:]
    rim = int((solid & ~inner).sum())
    blur = float(((ink > 0.1) & (ink < 0.9)).sum()) / max(rim, 1)
    edge = "crisp" if blur < 3 else "soft" if blur > 8 else "mixed"
    top = rel.split(os.sep)[0]
    entry = {
        "path": rel.replace(os.sep, "/"),
        "folder": os.path.dirname(rel).replace(os.sep, "/"),
        "type": TYPES.get(top, "sprite"),
        "size": [width, height],
        "kind": kind,
        "edge": edge,
        "coverage": round(float(visible.mean()), 3),
        "value": round(float(rgba[..., :3].max(-1)[visible].mean()), 2) if visible.any() else 0.0,
        "words": _words(rel),
    }
    if entry["type"] == "flipbook":
        grid = _grid(ink)
        entry["grid"] = grid
        if grid:
            cell = ink.shape[0] // grid
            cells = [float((ink[r * cell:(r + 1) * cell, c * cell:(c + 1) * cell] > 0.05).mean())
                     for r in range(grid) for c in range(grid)]
            entry["frames"] = sum(1 for c in cells if c > 0)
    return entry


def _load():
    try:
        with open(_catalog_path(), encoding="utf-8") as handle:
            return json.load(handle)
    except OSError:
        raise SystemExit(f"no catalog at {_catalog_path()}: run kit.py index first")


def _thumb(path, size):
    from PIL import Image
    image = Image.open(path).convert("RGBA")
    image.thumbnail((size, size))
    return image


def _sheet(entries, out, title=None):
    from PIL import Image, ImageDraw
    rows = (len(entries) + COLUMNS - 1) // COLUMNS
    label = 14
    top = 20 if title else 0
    sheet = Image.new("RGB", (COLUMNS * CELL, top + rows * (CELL + label)), (30, 30, 36))
    draw = ImageDraw.Draw(sheet)
    if title:
        draw.text((4, 4), title, fill=(240, 240, 240))
    for i, entry in enumerate(entries):
        row, column = divmod(i, COLUMNS)
        x, y = column * CELL, top + row * (CELL + label)
        image = _thumb(os.path.join(KIT, entry["path"]), CELL - 6)
        sheet.paste(image, (x + (CELL - image.width) // 2, y + label + (CELL - image.height) // 2), image)
        tag = {"additive": " A", "baked": " C"}.get(entry["kind"], "")
        if entry.get("grid"):
            tag += f" {entry['grid']}x{entry['grid']}"
        draw.text((x + 3, y + 1), entry["id"] + tag, fill=(235, 235, 120))
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    sheet.save(out)
    return out


def index():
    """Describe every image in the kit and draw paged contact sheets per folder."""
    entries = []
    paths = []
    for root, dirs, files in os.walk(KIT):
        dirs[:] = sorted(d for d in dirs if d != "_catalog")
        for name in sorted(files):
            if name.lower().endswith((".png", ".jpg", ".jpeg")):
                paths.append(os.path.relpath(os.path.join(root, name), KIT))
    for number, rel in enumerate(paths, 1):
        try:
            entry = _describe(os.path.join(KIT, rel), rel)
        except Exception as error:
            print(f"skipped {rel}: {error}")
            continue
        entry = {"id": f"K{number:04d}", **entry}
        entries.append(entry)
        if number % 200 == 0:
            print(f"{number}/{len(paths)}")
    sheets = os.path.join(_catalog_dir(), "sheets")
    os.makedirs(sheets, exist_ok=True)
    for old in os.listdir(sheets):
        os.remove(os.path.join(sheets, old))
    folders = {}
    for entry in entries:
        folders.setdefault(entry["folder"], []).append(entry)
    pages = {}
    for folder, items in folders.items():
        pages[folder] = []
        for page in range(0, len(items), PAGE):
            chunk = items[page:page + PAGE]
            number = page // PAGE + 1
            out = os.path.join(sheets, f"{_slug(folder)}_p{number}.png")
            _sheet(chunk, out, f"{folder}  ({chunk[0]['id']}-{chunk[-1]['id']}, page {number})")
            pages[folder].append(os.path.relpath(out, KIT).replace(os.sep, "/"))
    catalog = {"kit": KIT, "count": len(entries), "sheets": pages, "entries": entries}
    with open(_catalog_path(), "w", encoding="utf-8") as handle:
        json.dump(catalog, handle, indent=1)
    print(f"{len(entries)} textures, {sum(len(p) for p in pages.values())} sheets -> {_catalog_dir()}")


def folders():
    catalog = _load()
    counts = {}
    for entry in catalog["entries"]:
        counts[entry["folder"]] = counts.get(entry["folder"], 0) + 1
    for folder in sorted(counts):
        sheets = ", ".join(os.path.basename(p) for p in catalog["sheets"].get(folder, []))
        print(f"{counts[folder]:4d}  {folder}  [{sheets}]")
    print(f"sheets in {os.path.join(_catalog_dir(), 'sheets')}")


def search(words, kind=None, type_=None, edge=None, limit=40):
    catalog = _load()
    words = [w.lower() for w in words]
    found = []
    for entry in catalog["entries"]:
        text = entry["path"].lower() + " " + " ".join(entry["words"])
        if all(w in text for w in words) and (not kind or entry["kind"] == kind) \
                and (not type_ or entry["type"] == type_) and (not edge or entry["edge"] == edge):
            found.append(entry)
    for entry in found[:limit]:
        grid = f" grid {entry['grid']}x{entry['grid']} ({entry.get('frames', '?')} frames)" if entry.get("grid") else ""
        print(f"{entry['id']}  {entry['type']:8s} {entry['kind']:8s} {entry['edge']:5s} value {entry['value']:.2f}  "
              f"{entry['size'][0]}x{entry['size'][1]}{grid}  {entry['path']}")
    print(f"{len(found)} match" + ("" if len(found) == 1 else "es") + (f", first {limit} shown" if len(found) > limit else ""))
    return found


def _by_id(ids):
    catalog = {e["id"]: e for e in _load()["entries"]}
    missing = [i for i in ids if i.upper() not in catalog]
    if missing:
        raise SystemExit(f"unknown ids: {missing}")
    return [catalog[i.upper()] for i in ids]


def _resize(image, size):
    from PIL import Image
    premultiplied = image.convert("RGBa").resize(size, Image.LANCZOS)
    return premultiplied.convert("RGBA")


def _square(image, side, fill):
    from PIL import Image
    scale = min(side / image.width, side / image.height, 1.0)
    if scale < 1.0:
        image = _resize(image, (max(1, round(image.width * scale)), max(1, round(image.height * scale))))
    canvas = Image.new("RGBA", (side, side), fill)
    canvas.alpha_composite(image, ((side - image.width) // 2, (side - image.height) // 2))
    return canvas


def prepare(ids, effect, names=None, size=512):
    """Copy kit textures into assets/VFX/<effect>/ at sizes Roblox takes, and record where each came from."""
    from PIL import Image
    entries = _by_id(ids)
    names = names or []
    folder = os.path.join(REPO, "assets", "VFX", effect)
    os.makedirs(folder, exist_ok=True)
    sources_path = os.path.join(folder, "kit_sources.json")
    try:
        with open(sources_path, encoding="utf-8") as handle:
            sources = json.load(handle)
    except OSError:
        sources = {}
    for i, entry in enumerate(entries):
        base = names[i] if i < len(names) else f"{_slug(os.path.basename(entry['folder']))}_{entry['id']}"
        image = Image.open(os.path.join(KIT, entry["path"])).convert("RGBA")
        fill = (0, 0, 0, 255) if entry["kind"] == "additive" else (0, 0, 0, 0)
        notes = []
        if entry["type"] == "flipbook":
            file = base + ".flipbook.png"
            if image.width != image.height:
                print(f"SKIPPED {entry['id']}: flipbook sheet is {image.width}x{image.height}, not square")
                continue
            if image.width < 1024:
                notes.append(f"upscaled from {image.width} (Roblox flipbooks need 1024)")
            out = _resize(image, (1024, 1024)) if image.width != 1024 else image
            with open(os.path.join(folder, base + ".flipbook.json"), "w", encoding="utf-8") as handle:
                json.dump({"grid": entry.get("grid") or 4, "loop": False,
                           "mode": "additive" if entry["kind"] == "additive" else "alpha"}, handle)
            if not entry.get("grid"):
                notes.append("grid not detected, assumed 4x4: check it")
        elif entry["type"] == "beam":
            file = base + ".png"
            scale = min(1.0, 1024 / max(image.size))
            out = _resize(image, (round(image.width * scale), round(image.height * scale))) if scale < 1 else image
        else:
            file = base + ".png"
            side = min(size, max(image.size))
            out = _square(image, side, fill) if image.size != (side, side) else image
        out.save(os.path.join(folder, file))
        sources[file] = {"kit_id": entry["id"], "kit_path": entry["path"], "original_size": entry["size"],
                         "kind": entry["kind"], "grid": entry.get("grid")}
        light = "LightEmission 1 only (baked on black)" if entry["kind"] == "additive" else \
            "colour baked in: tint toward its own hue only" if entry["kind"] == "baked" else "tintable"
        print(f"{entry['id']} -> assets/VFX/{effect}/{file}  {out.width}x{out.height}  {light}"
              + ("  " + "; ".join(notes) if notes else ""))
    with open(sources_path, "w", encoding="utf-8") as handle:
        json.dump(sources, handle, indent=1)


def _option(rest, flag, default=None, many=False):
    if flag not in rest:
        return rest, default
    i = rest.index(flag)
    if many:
        values = []
        j = i + 1
        while j < len(rest) and not rest[j].startswith("--"):
            values.append(rest[j])
            j += 1
        return rest[:i] + rest[j:], values
    return rest[:i] + rest[i + 2:], rest[i + 1]


def _main(argv):
    global KIT
    if len(argv) < 2 or argv[1] in ("-h", "--help"):
        print(__doc__)
        return 0
    command, rest = argv[1], argv[2:]
    rest, kit = _option(rest, "--kit")
    if kit:
        KIT = kit
    if command == "index":
        index()
    elif command == "folders":
        folders()
    elif command == "search":
        rest, kind = _option(rest, "--kind")
        rest, type_ = _option(rest, "--type")
        rest, edge = _option(rest, "--edge")
        rest, limit = _option(rest, "--limit", "40")
        search(rest, kind, type_, edge, int(limit))
    elif command == "sheet":
        rest, out = _option(rest, "-o", "kit_sheet.png")
        print(_sheet(_by_id(rest), out))
    elif command == "prepare":
        rest, effect = _option(rest, "--effect")
        rest, names = _option(rest, "--name", [], many=True)
        rest, size = _option(rest, "--size", "512")
        if not effect:
            raise SystemExit("prepare needs --effect <Effect>")
        prepare(rest, effect, names, int(size))
    else:
        print(f"unknown command {command}\n{__doc__}")
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(_main(sys.argv))
