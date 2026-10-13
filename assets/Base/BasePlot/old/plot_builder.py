import math
import random
import sys

import bmesh
import bpy
from mathutils import Vector

rb = sys.modules["rock_builder"]
H = 0.5
COLLECTION = "BasePlot"

P = dict(
    W=90.0, L=90.0, FLOOR_H=1.0,
    RIM_W=2.0, RIM_H=2.5, POST=2.8, POST_H=3.2,
    GAP_HALF=8.0, VEST_DEPTH=12.0,
    WALK_HALF=5.0, WALK_H=0.4,
    SLOT=10.0, SLOT_H=0.3, SLOT_X=27.0, SLOT_YS=(-28.5, -9.5, 9.5, 28.5),
    PIT_Y=33.0, PIT_INNER=15.0, FRAME_W=1.5, FRAME_H=0.5, PIT_DEPTH=0.5,
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


def shade(obj, edge_width=0.12, edge_shade=0.62):
    rb.face_shade_colors(obj.data, edge_width=edge_width, edge_shade=edge_shade)
    rb.planar_stud_uvs(obj.data)


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


def stone_boxes(p=P):
    hw, hl = p["W"] / 2, p["L"] / 2
    f, rw, rh = p["FLOOR_H"], p["RIM_W"], p["RIM_H"]
    top = f + rh
    gap, vd = p["GAP_HALF"], p["VEST_DEPTH"]
    vest_back = -hl + rw + vd
    out = [
        (-hw, hw, hl - rw, hl, f - 0.01, top, 0.12),
        (-hw, -hw + rw, -hl, hl - rw, f - 0.01, top, 0.12),
        (hw - rw, hw, -hl, hl - rw, f - 0.01, top, 0.12),
        (-hw + rw, -gap - rw, -hl, -hl + rw, f - 0.01, top, 0.12),
        (gap + rw, hw - rw, -hl, -hl + rw, f - 0.01, top, 0.12),
    ]
    for s in (-1, 1):
        wx0, wx1 = sorted((s * gap, s * (gap + rw)))
        out.append((wx0, wx1, -hl, vest_back, f - 0.01, top, 0.12))
        bx0, bx1 = sorted((s * p["WALK_HALF"], s * gap))
        out.append((bx0, bx1, vest_back - rw, vest_back, f - 0.01, top, 0.12))
    ph, pt = p["POST"] / 2, f + p["POST_H"]
    posts = [(-hw + ph, -hl + ph), (hw - ph, -hl + ph), (-hw + ph, hl - ph), (hw - ph, hl - ph)]
    for s in (-1, 1):
        posts.append((s * (gap + ph), -hl + ph))
        posts.append((s * (gap + rw - ph), vest_back - ph))
    for cx, cy in posts:
        out.append((cx - ph - 0.02, cx + ph + 0.02, cy - ph - 0.02, cy + ph + 0.02, f - 0.01, pt, 0.15))
    frame_outer = p["PIT_INNER"] / 2 + p["FRAME_W"]
    walk_end = p["PIT_Y"] - frame_outer
    out.append((-p["WALK_HALF"], p["WALK_HALF"], vest_back - rw, walk_end + 0.01, f - 0.01, f + p["WALK_H"], 0.1))
    sh = p["SLOT"] / 2
    for s in (-1, 1):
        for y in p["SLOT_YS"]:
            cx = s * p["SLOT_X"]
            out.append((cx - sh, cx + sh, y - sh, y + sh, f - 0.01, f + p["SLOT_H"], 0.1))
    pi, py, fw, fh = p["PIT_INNER"] / 2, p["PIT_Y"], p["FRAME_W"], p["FRAME_H"]
    out += [
        (-pi - fw, pi + fw, py + pi, py + pi + fw, f - 0.01, f + fh, 0.1),
        (-pi - fw, pi + fw, py - pi - fw, py - pi, f - 0.01, f + fh, 0.1),
        (-pi - fw, -pi, py - pi, py + pi, f - 0.01, f + fh, 0.1),
        (pi, pi + fw, py - pi, py + pi, f - 0.01, f + fh, 0.1),
    ]
    return out


def build_floor(color=(55, 65, 100), p=P):
    floor = box("BasePlot_Floor", -p["W"] / 2, p["W"] / 2, -p["L"] / 2, p["L"] / 2, 0, p["FLOOR_H"])
    pi = p["PIT_INNER"] / 2
    pit = box("tmp_pit", -pi, pi, p["PIT_Y"] - pi, p["PIT_Y"] + pi, p["FLOOR_H"] - p["PIT_DEPTH"], p["FLOOR_H"] + 1)
    rb.boolean(floor, pit, "DIFFERENCE")
    rb._remove_object("tmp_pit")
    rb.clean_mesh(floor.data, 0.0)
    shade(floor)
    rb._finish(floor, rb.plain_material("BasePlotFloor", color))
    return floor, rb.stats(floor.data)


def build_stone(color=(170, 176, 196), p=P):
    stone = join_boxes("BasePlot_Stone", stone_boxes(p))
    shade(stone)
    rb._finish(stone, rb.plain_material("BasePlotStone", color))
    return stone, rb.stats(stone.data)


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


def build_crack(color=(130, 130, 136), seed=4, grid=4, gap=0.5, p=P):
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
    obj = new_obj("BasePlot_Crack", bm)
    shade(obj)
    rb._finish(obj, rb.plain_material("BasePlotCrack", color))
    return obj, rb.stats(obj.data)


def build_all():
    return {
        "floor": build_floor()[1],
        "stone": build_stone()[1],
        "crack": build_crack()[1],
    }


def render_set(objs, d, prefix):
    rb.setup_preview_scene()
    bpy.context.scene.camera.data.clip_end = 1000.0
    rb.render_preview(objs, d + rf"\{prefix}_34.png", (55.0, -85.0, 55.0), target=(0, 0, 0))
    rb.render_preview(objs, d + rf"\{prefix}_top.png", (0.01, -0.01, 125.0), target=(0, 0, 0))
    rb.render_preview(objs, d + rf"\{prefix}_front.png", (0, -75.0, 10.0), target=(0, 0, 0.5))
    rb.render_preview(objs, d + rf"\{prefix}_pit.png", (10.0, 8.0, 12.0), target=(0, 23, 0.4))
