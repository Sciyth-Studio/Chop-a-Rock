import sys

import bmesh
import bpy

rb = sys.modules["rock_builder"]
H = 0.5
COLLECTION = "BasePlot"

P = dict(
    SLABS=((64.0, 0.0, 0.6), (62.0, 0.6, 1.4), (60.0, 1.4, 2.4)),
    BACK_EXTRA=30.0,
    FLOOR_H=2.4, SLAB_BEVEL=0.12,
    WALK_HALF=4.0, WALK_H=0.4, TRIM_W=0.6, TRIM_H=0.1,
    PAD=9.0, PAD_XS=(11.0, 22.0), PAD_YS=(-21.0, -10.0),
    PAD_BASE_H=0.1, PAD_RIM_W=1.0, PAD_RIM_H=0.5,
    PEN_X=28.0, PEN_Y0=2.0, PEN_Y1=58.0, PEN_H=2.0, PEN_TOP_H=0.4,
    STAIR_Y=-4.0, STAIR_STEPS=3,
    FENCE_H=3.0, POST=1.2, POST_GAP=7.0, RAIL=0.6, RAIL_ZS=(1.1, 2.3), FENCE_INSET=0.7,
)


def collection():
    col = bpy.data.collections.get(COLLECTION)
    if col is None:
        col = bpy.data.collections.new(COLLECTION)
        bpy.context.scene.collection.children.link(col)
    return col


def new_obj(name, bm):
    rb._remove_object(name)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(name, me)
    collection().objects.link(obj)
    return obj


def box_bm(bm, x0, x1, y0, y1, z0, z1, bevel=0.0):
    sub = bmesh.new()
    bmesh.ops.create_cube(sub, size=1.0)
    for v in sub.verts:
        v.co.x = (x1 if v.co.x > 0 else x0) * H
        v.co.y = (y1 if v.co.y > 0 else y0) * H
        v.co.z = (z1 if v.co.z > 0 else z0) * H
    if bevel > 0:
        edges = [e for e in sub.edges if not all(abs(v.co.z - z0 * H) < 1e-6 for v in e.verts)]
        bmesh.ops.bevel(sub, geom=edges, offset=bevel * H, segments=1, affect="EDGES", profile=0.5, clamp_overlap=True)
    me = bpy.data.meshes.new("tmp")
    sub.to_mesh(me)
    sub.free()
    bm.from_mesh(me)
    bpy.data.meshes.remove(me)


def box(name, x0, x1, y0, y1, z0, z1, bevel=0.0):
    bm = bmesh.new()
    box_bm(bm, x0, x1, y0, y1, z0, z1, bevel)
    return new_obj(name, bm)


def join_boxes(name, boxes):
    bm = bmesh.new()
    for b in boxes:
        box_bm(bm, *b)
    return new_obj(name, bm)


def finish(obj, material, color):
    rb.planar_stud_uvs(obj.data)
    rb._finish(obj, rb.plain_material(material, color))
    return obj, rb.stats(obj.data)


def slab_box(slab, p, lift):
    w, z0, z1 = slab
    return (-w / 2, w / 2, -w / 2, w / 2 + p["BACK_EXTRA"], z0 - lift, z1, p["SLAB_BEVEL"])


def build_floor(color=(59, 59, 59), p=P):
    return finish(join_boxes("BasePlot_Floor", [slab_box(p["SLABS"][-1], p, 0.01)]), "BasePlotFloor", color)


def build_edge(color=(59, 59, 59), p=P):
    boxes = [slab_box(slab, p, 0.01 if i else 0.0) for i, slab in enumerate(p["SLABS"][:-1])]
    return finish(join_boxes("BasePlot_Edge", boxes), "BasePlotEdge", color)


def carpet_boxes(p=P):
    wh, t = p["WALK_HALF"], p["WALK_H"]
    slabs = p["SLABS"]
    out = []
    for upper, lower in zip(slabs[:0:-1], slabs[-2::-1]):
        face = -upper[0] / 2
        edge = -lower[0] / 2
        out.append((-wh, wh, face - t, face + 0.01, lower[2] - 0.01, upper[2] + t, 0.0))
        out.append((-wh, wh, edge + (0.02 if lower is slabs[0] else 0.0), face - t + 0.01, lower[2] - 0.01, lower[2] + t, 0.0))
    return out


def stair_rects(p=P):
    f, t = p["FLOOR_H"], p["WALK_H"]
    count = p["STAIR_STEPS"]
    depth = (p["PEN_Y0"] - p["STAIR_Y"]) / count
    rise = (p["PEN_H"] - t) / count
    return [
        (p["STAIR_Y"] + i * depth, p["PEN_Y0"] + p["FENCE_INSET"], f + t + (i + 1) * rise)
        for i in range(count)
    ]


def pad_centres(p=P):
    return [(s * x, y) for s in (-1, 1) for x in p["PAD_XS"] for y in p["PAD_YS"]]


def pad_frame_boxes(p=P):
    f = p["FLOOR_H"]
    half, rim = p["PAD"] / 2, p["PAD_RIM_W"]
    top = f + p["PAD_RIM_H"]
    out = []
    for cx, y in pad_centres(p):
        out.append((cx - half, cx + half, y + half - rim, y + half, f - 0.01, top, 0.1))
        out.append((cx - half, cx + half, y - half, y - half + rim, f - 0.01, top, 0.1))
        out.append((cx - half, cx - half + rim, y - half + rim, y + half - rim, f - 0.01, top, 0.1))
        out.append((cx + half - rim, cx + half, y - half + rim, y + half - rim, f - 0.01, top, 0.1))
    return out


def build_pad_frames(color=(125, 125, 125), p=P):
    return finish(join_boxes("BasePlot_PadFrames", pad_frame_boxes(p)), "BasePlotPadFrame", color)


def build_pad_centres(color=(82, 82, 82), p=P):
    f = p["FLOOR_H"]
    inner = p["PAD"] / 2 - p["PAD_RIM_W"] + 0.02
    return {
        f"pad{i}": finish(
            box(f"BasePlot_Pad{i}", cx - inner, cx + inner, y - inner, y + inner, f - 0.01, f + p["PAD_BASE_H"]),
            "BasePlotPad",
            color,
        )[1]
        for i, (cx, y) in enumerate(pad_centres(p), 1)
    }


def path_boxes(p=P):
    f = p["FLOOR_H"]
    top_half = p["SLABS"][-1][0] / 2
    wh = p["WALK_HALF"]
    out = [(-wh, wh, -top_half, p["STAIR_Y"] + 0.01, f - 0.01, f + p["WALK_H"], 0.0)]
    out += carpet_boxes(p)
    out += [(-wh, wh, y0, y1, f - 0.01, z1, 0.0) for y0, y1, z1 in stair_rects(p)]
    return out


def build_path(color=(125, 125, 125), p=P):
    return finish(join_boxes("BasePlot_Path", path_boxes(p)), "BasePlotPath", color)


def trim_boxes(p=P):
    wh, tw, t, th, over = p["WALK_HALF"], p["TRIM_W"], p["WALK_H"], p["TRIM_H"], 0.05
    slabs = p["SLABS"][::-1]
    back = p["STAIR_Y"] + 0.01
    rects = []
    for upper, lower in zip(slabs, slabs[1:]):
        face = -upper[0] / 2
        rects.append((face, back, upper[2] - 0.01, upper[2] + t + th))
        rects.append((face - t - over, face, lower[2] - 0.01, upper[2] + t + th))
        back = face - t - over
    rects.append((-slabs[-1][0] / 2, back, slabs[-1][2] - 0.01, slabs[-1][2] + t + th))
    rects += [(y0, y1, p["FLOOR_H"] - 0.01, z1 + th) for y0, y1, z1 in stair_rects(p)]
    out = []
    for s in (-1, 1):
        xa, xb = sorted((s * (wh - tw), s * (wh + over)))
        out += [(xa, xb, y0, y1, z0, z1, 0.0) for y0, y1, z0, z1 in rects]
    return out


def build_trim(color=(125, 125, 125), p=P):
    trim = join_boxes("BasePlot_Trim", trim_boxes(p))
    rb.planar_stud_uvs(trim.data)
    rb._finish(trim, rb.plain_material("BasePlotTrim", color))
    return trim, rb.stats(trim.data)


def build_pen(color=(82, 82, 82), p=P):
    top = p["FLOOR_H"] + p["PEN_H"]
    x, y0, y1 = p["PEN_X"], p["PEN_Y0"], p["PEN_Y1"]
    pen = box("BasePlot_Pen", -x, x, y0, y1, top - p["PEN_TOP_H"], top, 0.15)
    return finish(pen, "BasePlotPen", color)


def build_pen_side(color=(125, 125, 125), p=P):
    x, y0, y1, inset = p["PEN_X"], p["PEN_Y0"], p["PEN_Y1"], 0.02
    bottom = p["FLOOR_H"] - 0.01
    side = box("BasePlot_PenSide", -x + inset, x - inset, y0 + inset, y1 - inset, bottom, bottom + p["PEN_H"] - p["PEN_TOP_H"] + 0.02)
    return finish(side, "BasePlotPenSide", color)


def spaced(a, b, gap):
    count = max(1, round((b - a) / gap))
    return [a + (b - a) * i / count for i in range(count + 1)]


def fence_boxes(p=P):
    base = p["FLOOR_H"] + p["PEN_H"] - 0.01
    top = base + p["FENCE_H"]
    half, rail = p["POST"] / 2, p["RAIL"] / 2
    x1 = p["PEN_X"] - p["FENCE_INSET"]
    y0, y1 = p["PEN_Y0"] + p["FENCE_INSET"], p["PEN_Y1"] - p["FENCE_INSET"]
    gap = p["WALK_HALF"] + half
    posts = set()
    for x in spaced(-x1, x1, p["POST_GAP"]):
        posts.add((round(x, 3), y1))
    for y in spaced(y0, y1, p["POST_GAP"]):
        posts.add((-x1, round(y, 3)))
        posts.add((x1, round(y, 3)))
    for s in (-1, 1):
        for x in spaced(gap, x1, p["POST_GAP"]):
            posts.add((round(s * x, 3), y0))
    return [(x - half, x + half, y - half, y + half, base, top, 0.08) for x, y in sorted(posts)]


def rail_boxes(p=P):
    base = p["FLOOR_H"] + p["PEN_H"] - 0.01
    half, rail = p["POST"] / 2, p["RAIL"] / 2
    x1 = p["PEN_X"] - p["FENCE_INSET"]
    y0, y1 = p["PEN_Y0"] + p["FENCE_INSET"], p["PEN_Y1"] - p["FENCE_INSET"]
    gap = p["WALK_HALF"] + half
    out = []
    for z in p["RAIL_ZS"]:
        zb, zt = base + z - rail, base + z + rail
        out.append((-x1, x1, y1 - rail, y1 + rail, zb, zt, 0.0))
        for s in (-1, 1):
            xa, xb = sorted((s * x1 - rail, s * x1 + rail))
            out.append((xa, xb, y0, y1, zb, zt, 0.0))
            xa, xb = sorted((s * gap, s * x1))
            out.append((xa, xb, y0 - rail, y0 + rail, zb, zt, 0.0))
    return out


def build_fence_posts(color=(125, 125, 125), p=P):
    return finish(join_boxes("BasePlot_FencePosts", fence_boxes(p)), "BasePlotFencePost", color)


def build_fence_rails(color=(125, 125, 125), p=P):
    return finish(join_boxes("BasePlot_FenceRails", rail_boxes(p)), "BasePlotFenceRail", color)


def build_all():
    for old in ("BasePlot_Crack", "BasePlot_Stone", "BasePlot_Fence"):
        rb._remove_object(old)
    stats = {
        "floor": build_floor()[1],
        "edge": build_edge()[1],
        "path": build_path()[1],
        "trim": build_trim()[1],
        "padframes": build_pad_frames()[1],
        "pen": build_pen()[1],
        "penside": build_pen_side()[1],
        "posts": build_fence_posts()[1],
        "rails": build_fence_rails()[1],
    }
    stats.update(build_pad_centres())
    return stats


def preview_extras(p=P):
    pet_mat = rb.plain_material("PreviewPet", (150, 150, 150))
    geode_mat = rb.plain_material("PreviewGeode", (200, 120, 230))
    out = []
    z = p["FLOOR_H"] + p["PEN_H"]
    pets = [(-18, 18, 5), (-6, 30, 5), (10, 16, 6), (20, 38, 5), (-20, 48, 6), (2, 48, 10), (17, 52, 5), (-10, 40, 5)]
    for i, (x, y, s) in enumerate(pets):
        pet = box(f"Preview_Pet{i}", x - s / 2, x + s / 2, y - s / 2, y + s / 2, z, z + s, 0.2)
        rb._finish(pet, pet_mat)
        out.append(pet)
    f = p["FLOOR_H"] + p["PAD_BASE_H"]
    for i, (cx, y) in enumerate([(-11, -21), (11, -10), (22, -21)]):
        geode = box(f"Preview_Geode{i}", cx - 2.5, cx + 2.5, y - 2.5, y + 2.5, f, f + 5, 0.4)
        rb._finish(geode, geode_mat)
        out.append(geode)
    return out


def render_set(objs, d, prefix):
    rb.setup_preview_scene()
    bpy.context.scene.camera.data.clip_end = 1000.0
    rb.render_preview(objs, d + rf"\{prefix}_34.png", (46.0, -44.0, 42.0), target=(0, 10, 0))
    rb.render_preview(objs, d + rf"\{prefix}_top.png", (0.01, 10.0, 110.0), target=(0, 10, 0))
    rb.render_preview(objs, d + rf"\{prefix}_front.png", (0, -46.0, 8.0), target=(0, 8, 1.2))
    rb.render_preview(objs, d + rf"\{prefix}_back.png", (-40.0, 58.0, 22.0), target=(0, 18, 1.2))
    rb.render_preview(objs, d + rf"\{prefix}_stairs.png", (10.0, -26.0, 8.0), target=(0, -3, 1.2))
