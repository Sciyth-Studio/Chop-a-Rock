import random
import sys

import bmesh
import bpy
from mathutils import Vector

rb = sys.modules["rock_builder"]
H = 0.5
COLLECTION = "BasePlot"

P = dict(
    SLABS=((64.0, 0.0, 0.6), (62.0, 0.6, 1.4), (60.0, 1.4, 2.4)),
    FLOOR_H=2.4, SLAB_BEVEL=0.12,
    WALK_HALF=4.0, WALK_H=0.4, TRIM_W=0.6, TRIM_H=0.1,
    SLOT=9.0, SLOT_H=0.3, SLOT_X=21.0, SLOT_YS=(-19.5, -6.5, 6.5, 19.5),
    PIT_Y=0.0, PIT_INNER=16.0, FRAME_W=1.5, FRAME_H=0.5, PIT_DEPTH=0.5,
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


def build_floor(color=(20, 20, 20), p=P):
    w, z0, z1 = p["SLABS"][-1]
    floor = box("BasePlot_Floor", -w / 2, w / 2, -w / 2, w / 2, z0 - 0.01, z1, p["SLAB_BEVEL"])
    pi = p["PIT_INNER"] / 2
    pit = box("tmp_pit", -pi, pi, p["PIT_Y"] - pi, p["PIT_Y"] + pi, p["FLOOR_H"] - p["PIT_DEPTH"], p["FLOOR_H"] + 1)
    rb.boolean(floor, pit, "DIFFERENCE")
    rb._remove_object("tmp_pit")
    bm = bmesh.new()
    bm.from_mesh(floor.data)
    for i, (sw, sz0, sz1) in enumerate(p["SLABS"][:-1]):
        box_bm(bm, -sw / 2, sw / 2, -sw / 2, sw / 2, sz0 - (0.01 if i else 0.0), sz1, p["SLAB_BEVEL"])
    bm.to_mesh(floor.data)
    bm.free()
    rb.clean_mesh(floor.data, 0.0)
    rb.planar_stud_uvs(floor.data)
    rb._finish(floor, rb.plain_material("BasePlotFloor", color))
    return floor, rb.stats(floor.data)


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


def stone_boxes(p=P):
    f = p["FLOOR_H"]
    top_half = p["SLABS"][-1][0] / 2
    pi, py, fw, fh = p["PIT_INNER"] / 2, p["PIT_Y"], p["FRAME_W"], p["FRAME_H"]
    out = [
        (-p["WALK_HALF"], p["WALK_HALF"], -top_half, py - pi - fw + 0.01, f - 0.01, f + p["WALK_H"], 0.0),
        (-pi - fw, pi + fw, py + pi, py + pi + fw, f - 0.01, f + fh, 0.1),
        (-pi - fw, pi + fw, py - pi - fw, py - pi, f - 0.01, f + fh, 0.1),
        (-pi - fw, -pi, py - pi, py + pi, f - 0.01, f + fh, 0.1),
        (pi, pi + fw, py - pi, py + pi, f - 0.01, f + fh, 0.1),
    ]
    out += carpet_boxes(p)
    sh = p["SLOT"] / 2
    for s in (-1, 1):
        for y in p["SLOT_YS"]:
            cx = s * p["SLOT_X"]
            out.append((cx - sh, cx + sh, y - sh, y + sh, f - 0.01, f + p["SLOT_H"], 0.1))
    return out


def build_stone(color=(128, 128, 128), p=P):
    stone = join_boxes("BasePlot_Stone", stone_boxes(p))
    rb.planar_stud_uvs(stone.data)
    rb._finish(stone, rb.plain_material("BasePlotStone", color))
    return stone, rb.stats(stone.data)


def trim_boxes(p=P):
    wh, tw, t, th, over = p["WALK_HALF"], p["TRIM_W"], p["WALK_H"], p["TRIM_H"], 0.05
    slabs = p["SLABS"][::-1]
    back = p["PIT_Y"] - p["PIT_INNER"] / 2 - p["FRAME_W"] + 0.01
    rects = []
    for upper, lower in zip(slabs, slabs[1:]):
        face = -upper[0] / 2
        rects.append((face, back, upper[2] - 0.01, upper[2] + t + th))
        rects.append((face - t - over, face, lower[2] - 0.01, upper[2] + t + th))
        back = face - t - over
    rects.append((-slabs[-1][0] / 2, back, slabs[-1][2] - 0.01, slabs[-1][2] + t + th))
    out = []
    for s in (-1, 1):
        xa, xb = sorted((s * (wh - tw), s * (wh + over)))
        out += [(xa, xb, y0, y1, z0, z1, 0.0) for y0, y1, z0, z1 in rects]
    return out


def build_trim(color=(255, 255, 255), p=P):
    trim = join_boxes("BasePlot_Trim", trim_boxes(p))
    rb.planar_stud_uvs(trim.data)
    rb._finish(trim, rb.plain_material("BasePlotTrim", color))
    return trim, rb.stats(trim.data)


def clip(poly, a, b):
    mid = (a + b) / 2
    n = b - a
    out = []
    for i, cur in enumerate(poly):
        prev = poly[i - 1]
        cin = (cur - mid).dot(n) <= 0
        pin = (prev - mid).dot(n) <= 0
        if cin != pin:
            d = cur - prev
            t = (mid - prev).dot(n) / d.dot(n)
            out.append(prev + d * t)
        if cin:
            out.append(cur)
    return out


def shrink(poly, gap):
    poly = [v for i, v in enumerate(poly) if (v - poly[i - 1]).length > 1e-4]
    c = sum(poly, Vector((0, 0))) / len(poly)
    lines = []
    for i, a in enumerate(poly):
        b = poly[(i + 1) % len(poly)]
        d = (b - a).normalized()
        n = Vector((d.y, -d.x))
        if (c - a).dot(n) > 0:
            n = -n
        lines.append((a - n * gap / 2, d))
    out = []
    for i in range(len(lines)):
        (p1, d1), (p2, d2) = lines[i - 1], lines[i]
        den = d1.x * d2.y - d1.y * d2.x
        if abs(den) < 1e-6:
            out.append(p2)
            continue
        t = ((p2.x - p1.x) * d2.y - (p2.y - p1.y) * d2.x) / den
        out.append(p1 + d1 * t)
    return out


def build_crack(color=(90, 90, 90), seed=4, grid=4, gap=0.5, p=P):
    rng = random.Random(seed)
    pi = p["PIT_INNER"] / 2
    cell = p["PIT_INNER"] / grid
    seeds = []
    for i in range(grid):
        for j in range(grid):
            seeds.append(Vector((-pi + (i + 0.5 + rng.uniform(-0.35, 0.35)) * cell,
                                 -pi + (j + 0.5 + rng.uniform(-0.35, 0.35)) * cell)))
    square = [Vector((-pi, -pi)), Vector((pi, -pi)), Vector((pi, pi)), Vector((-pi, pi))]
    bm = bmesh.new()
    z0 = p["FLOOR_H"] - p["PIT_DEPTH"] - 0.01
    for s in seeds:
        poly = square
        for o in seeds:
            if o is not s:
                poly = clip(poly, s, o)
        poly = shrink(poly, gap)
        z1 = p["FLOOR_H"] - p["PIT_DEPTH"] + rng.uniform(0.35, 0.65)
        bot = [bm.verts.new(Vector((v.x * H, (v.y + p["PIT_Y"]) * H, z0 * H))) for v in poly]
        top = [bm.verts.new(Vector((v.x * H, (v.y + p["PIT_Y"]) * H, z1 * H))) for v in poly]
        bm.faces.new(list(reversed(bot)))
        tf = bm.faces.new(top)
        for i in range(len(poly)):
            j = (i + 1) % len(poly)
            bm.faces.new([bot[i], bot[j], top[j], top[i]])
        bmesh.ops.bevel(bm, geom=list(tf.edges), offset=0.12 * H, segments=1, affect="EDGES", profile=0.5, clamp_overlap=True)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.dissolve_degenerate(bm, dist=1e-4, edges=bm.edges)
    obj = new_obj("BasePlot_Crack", bm)
    rb.planar_stud_uvs(obj.data)
    rb._finish(obj, rb.plain_material("BasePlotCrack", color))
    return obj, rb.stats(obj.data)


def build_all():
    return {
        "floor": build_floor()[1],
        "stone": build_stone()[1],
        "trim": build_trim()[1],
        "crack": build_crack()[1],
    }


def preview_extras(p=P):
    pad_mat = rb.plain_material("PreviewPad", (40, 230, 60))
    ped_mat = rb.plain_material("PreviewPedestal", (128, 128, 128))
    out = []
    f = p["FLOOR_H"] + p["SLOT_H"]
    for s in (-1, 1):
        for i, y in enumerate(p["SLOT_YS"]):
            cx = s * p["SLOT_X"]
            ped = box(f"Preview_Ped{s}{i}", cx - 4, cx + 4, y - 4, y + 4, f, f + 2.7, 0.15)
            rb._finish(ped, ped_mat)
            x = s * (p["SLOT_X"] - 8.25)
            pad = box(f"Preview_Pad{s}{i}", x - 1.75, x + 1.75, y - 3.25, y + 3.25, p["FLOOR_H"], p["FLOOR_H"] + 0.2)
            rb._finish(pad, pad_mat)
            out += [ped, pad]
    return out


def render_set(objs, d, prefix):
    rb.setup_preview_scene()
    bpy.context.scene.camera.data.clip_end = 1000.0
    rb.render_preview(objs, d + rf"\{prefix}_34.png", (42.0, -58.0, 34.0), target=(0, 0, 0))
    rb.render_preview(objs, d + rf"\{prefix}_top.png", (0.01, -0.01, 80.0), target=(0, 0, 0))
    rb.render_preview(objs, d + rf"\{prefix}_front.png", (0, -62.0, 3.0), target=(0, 0, 1.2))
    rb.render_preview(objs, d + rf"\{prefix}_edge.png", (-7.0, -24.0, 3.5), target=(0, -15, 0.6))
