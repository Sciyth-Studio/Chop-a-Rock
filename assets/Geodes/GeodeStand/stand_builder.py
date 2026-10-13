import math
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

rb = sys.modules["rock_builder"]
H = 0.5
COLLECTION = "GeodeStand"

P = dict(
    BASE_HALF=4.0, BASE_H=0.84,
    BODY_BOT=3.25, BODY_TOP=2.85, BODY_Z1=4.56, BODY_BEV=0.14,
    CAP_HALF=3.8, CAP_Z0=4.5, CAP_Z1=5.16,
    PLATE_HALF=3.3, PLATE_Z1=5.46,
)

CLUSTER = (
    (0.00, 0.00, 0.30, 1.6, 8.0, 0.0),
    (0.38, -0.30, 0.22, 1.1, 20.0, -40.0),
    (-0.30, 0.38, 0.21, 0.95, 20.0, 40.0),
    (0.30, 0.30, 0.16, 0.7, 24.0, 0.0),
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


def frustum(name, bot_half, top_half, z0, z1, bevel=0.0, bevel_edges="vertical"):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        top = v.co.z > 0
        half = top_half if top else bot_half
        v.co.x = math.copysign(half, v.co.x) * H
        v.co.y = math.copysign(half, v.co.y) * H
        v.co.z = (z1 if top else z0) * H
    if bevel > 0:
        if bevel_edges == "vertical":
            edges = [e for e in bm.edges if abs(e.verts[0].co.z - e.verts[1].co.z) > 1e-6]
        else:
            edges = [e for e in bm.edges if not all(abs(v.co.z - z0 * H) < 1e-6 for v in e.verts)]
        bmesh.ops.bevel(bm, geom=edges, offset=bevel * H, segments=1, affect="EDGES", profile=0.5, clamp_overlap=True)
    return new_obj(name, bm)


def build_stand(color=(163, 158, 148), merge=0.0, p=P):
    parts = [
        frustum("tmp_base", p["BASE_HALF"], p["BASE_HALF"], 0, p["BASE_H"], bevel=0.1, bevel_edges="top"),
        frustum("tmp_body", p["BODY_BOT"], p["BODY_TOP"], p["BASE_H"] - 0.1, p["BODY_Z1"], bevel=p["BODY_BEV"]),
        frustum("tmp_cap", p["CAP_HALF"], p["CAP_HALF"], p["CAP_Z0"], p["CAP_Z1"], bevel=0.1, bevel_edges="top"),
        frustum("tmp_plate", p["PLATE_HALF"], p["PLATE_HALF"], p["CAP_Z1"] - 0.05, p["PLATE_Z1"], bevel=0.08, bevel_edges="top"),
    ]
    rb._remove_object("GeodeStand")
    stand = parts[0]
    stand.name = "GeodeStand"
    stand.data.name = "GeodeStand"
    for part in parts[1:]:
        rb.boolean(stand, part, "UNION")
        rb._remove_object(part.name)
    rb.clean_mesh(stand.data, merge)
    rb.planar_stud_uvs(stand.data)
    rb._finish(stand, rb.plain_material("GeodeStandStone", color))
    return stand, rb.stats(stand.data)


def crystal(bm, base, radius, height, tilt, yaw, sides=6):
    tip_len = radius * 1.6
    shaft = height - tip_len
    m = Matrix.Translation(base) @ Matrix.Rotation(yaw, 4, "Z") @ Matrix.Rotation(tilt, 4, "X")
    ring_bot, ring_top = [], []
    for i in range(sides):
        a = 2 * math.pi * i / sides
        ring_bot.append(bm.verts.new(m @ Vector((math.cos(a) * radius, math.sin(a) * radius, -0.15 * H))))
        ring_top.append(bm.verts.new(m @ Vector((math.cos(a) * radius, math.sin(a) * radius, shaft))))
    tip = bm.verts.new(m @ Vector((0, 0, height)))
    bm.faces.new(list(reversed(ring_bot)))
    for i in range(sides):
        j = (i + 1) % sides
        bm.faces.new([ring_bot[i], ring_bot[j], ring_top[j], ring_top[i]])
        bm.faces.new([ring_top[i], ring_top[j], tip])


def build_crystals(color=(70, 110, 220), p=P, cluster=CLUSTER):
    bm = bmesh.new()
    corner = p["BODY_BOT"] - 0.05
    for sx, sy in ((1, 1), (-1, 1), (-1, -1), (1, -1)):
        out_yaw = math.atan2(sy, sx)
        for ox, oy, r, h, tilt_deg, spread_deg in cluster:
            local = Vector((ox, oy, 0)) * H
            local.rotate(Matrix.Rotation(out_yaw - math.pi / 4, 3, "Z"))
            base = Vector((sx * corner * H, sy * corner * H, p["BASE_H"] * H)) + local
            yaw = out_yaw + math.radians(spread_deg) + math.pi / 2
            crystal(bm, base, r * H, h * H, math.radians(tilt_deg), yaw)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj = new_obj("GeodeStand_Crystals", bm)
    rb._finish(obj, rb.plain_material("GeodeStandCrystal", color))
    return obj, rb.stats(obj.data)


def render_set(objs, d, prefix):
    rb.render_preview(objs, d + rf"\{prefix}_34.png", (6.0, -8.0, 5.0), target=(0, 0, 0.7))
    rb.render_preview(objs, d + rf"\{prefix}_front.png", (0, -10.0, 1.0), target=(0, 0, 0.8))
    rb.render_preview(objs, d + rf"\{prefix}_top.png", (0.01, -0.01, 11.0), target=(0, 0, 0))
    rb.render_preview(objs, d + rf"\{prefix}_back34.png", (-6.0, 8.0, 5.0), target=(0, 0, 0.7))
