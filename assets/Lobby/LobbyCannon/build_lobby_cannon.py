import math
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, r"C:\Users\Admin\Documents\RobloxDev\.claude\skills\rock-model\scripts")
import rock_builder as rb

IRON = (50, 50, 50)
ORANGE = (255, 140, 0)

P = dict(
    scale=2.1,
    tilt=35.0,
    pivot_y=0.4,
    pivot_z=2.15,
    barrel_r=0.61,
    bore_r=0.5,
    plug=0.3,
    barrel_front=3.2,
    barrel_back=-1.6,
    muzzle_r=0.79,
    muzzle_len=0.45,
    back_r=0.74,
    back_len=0.45,
    knob_r=0.46,
    knob_tip_r=0.24,
    knob_len=0.4,
    cheek_x=0.62,
    cheek_t=0.3,
    wheel_y=0.15,
    wheel_r=1.0,
    wheel_x=0.97,
    wheel_t=0.5,
    hub_r=0.34,
    hub_out=0.18,
    peg_r=0.2,
    peg_out=0.14,
)


def poly(n, r, rot):
    return [(math.cos(rot + i * math.tau / n) * r, math.sin(rot + i * math.tau / n) * r) for i in range(n)]


def add_prism(bm, profile, a0, a1, place):
    lo = [bm.verts.new(place(u, v, a0)) for u, v in profile]
    hi = [bm.verts.new(place(u, v, a1)) for u, v in profile]
    n = len(profile)
    bm.faces.new(list(reversed(lo)))
    bm.faces.new(hi)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((lo[i], lo[j], hi[j], hi[i]))


def add_frustum(bm, n, r0, r1, a0, a1, rot, place):
    lo = [bm.verts.new(place(u, v, a0)) for u, v in poly(n, r0, rot)]
    hi = [bm.verts.new(place(u, v, a1)) for u, v in poly(n, r1, rot)]
    bm.faces.new(list(reversed(lo)))
    bm.faces.new(hi)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((lo[i], lo[j], hi[j], hi[i]))


def add_ring(bm, n, r_out, r_in, a0, a1, rot, place):
    o0 = [bm.verts.new(place(u, v, a0)) for u, v in poly(n, r_out, rot)]
    o1 = [bm.verts.new(place(u, v, a1)) for u, v in poly(n, r_out, rot)]
    i0 = [bm.verts.new(place(u, v, a0)) for u, v in poly(n, r_in, rot)]
    i1 = [bm.verts.new(place(u, v, a1)) for u, v in poly(n, r_in, rot)]
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((o0[i], o0[j], o1[j], o1[i]))
        bm.faces.new((i0[j], i0[i], i1[i], i1[j]))
        bm.faces.new((o0[j], o0[i], i0[i], i0[j]))
        bm.faces.new((o1[i], o1[j], i1[j], i1[i]))


def barrel_space(u, v, a):
    t = math.radians(P["tilt"])
    local = Vector((u, a, v))
    rot = Matrix.Rotation(t, 3, "X")
    return rot @ local + Vector((0, P["pivot_y"], P["pivot_z"]))


def x_axis(cy, cz):
    return lambda u, v, a: Vector((a, cy + u, cz + v))


def side_profile(x0, x1, profile):
    return lambda bm: add_prism(bm, profile, x0, x1, lambda u, v, a: Vector((a, u, v)))


OCT = math.pi / 8


def build_barrel():
    bm = bmesh.new()
    b = P["barrel_back"]
    add_prism(bm, poly(8, P["barrel_r"], OCT), b, b + P["plug"], barrel_space)
    add_ring(bm, 8, P["barrel_r"], P["bore_r"], b + P["plug"], P["barrel_front"] - P["muzzle_len"] + 0.1, OCT, barrel_space)
    k0 = P["barrel_back"] - P["knob_len"]
    add_frustum(bm, 8, P["knob_tip_r"], P["knob_r"], k0, P["barrel_back"] + 0.05, OCT, barrel_space)
    return rb.make_obj("LobbyCannon_Barrel", bm, IRON)


def build_bands():
    bm = bmesh.new()
    f = P["barrel_front"]
    add_ring(bm, 8, P["muzzle_r"], P["bore_r"], f - P["muzzle_len"], f, OCT, barrel_space)
    b = P["barrel_back"]
    add_prism(bm, poly(8, P["back_r"], OCT), b, b + P["back_len"], barrel_space)
    return rb.make_obj("LobbyCannon_Bands", bm, ORANGE)


def build_carriage():
    bm = bmesh.new()
    cheek = [(-1.6, 0.55), (1.25, 0.55), (1.25, 1.55), (0.85, 2.4), (-0.05, 2.4), (-1.6, 1.3)]
    for s in (-1, 1):
        x0 = s * P["cheek_x"]
        x1 = s * (P["cheek_x"] + P["cheek_t"])
        side_profile(min(x0, x1), max(x0, x1), cheek)(bm)
    add_prism(bm, [(-0.25, 0.75), (0.45, 0.75), (0.45, 1.3), (-0.25, 1.3)], -P["cheek_x"], P["cheek_x"],
              lambda u, v, a: Vector((a, u, v)))
    trail = [(-3.1, 0.0), (-1.1, 0.0), (-1.1, 0.95), (-3.1, 0.3)]
    add_prism(bm, trail, -0.75, 0.75, lambda u, v, a: Vector((a, u, v)))
    return rb.make_obj("LobbyCannon_Carriage", bm, ORANGE, recalc=True)


def build_wheels():
    bm = bmesh.new()
    r = P["wheel_r"] / math.cos(math.pi / 12)
    for s in (-1, 1):
        x0 = s * P["wheel_x"]
        x1 = s * (P["wheel_x"] + P["wheel_t"])
        add_prism(bm, poly(12, r, math.pi / 12 + math.pi / 2), min(x0, x1), max(x0, x1),
                  x_axis(P["wheel_y"], P["wheel_r"]))
    return rb.make_obj("LobbyCannon_Wheels", bm, ORANGE)


def build_hubs():
    bm = bmesh.new()
    for s in (-1, 1):
        x0 = s * (P["wheel_x"] + P["wheel_t"] - 0.05)
        x1 = s * (P["wheel_x"] + P["wheel_t"] + P["hub_out"])
        add_prism(bm, poly(8, P["hub_r"], OCT), min(x0, x1), max(x0, x1), x_axis(P["wheel_y"], P["wheel_r"]))
        x0 = s * (P["cheek_x"] + P["cheek_t"] - 0.05)
        x1 = s * (P["cheek_x"] + P["cheek_t"] + P["peg_out"])
        add_prism(bm, poly(8, P["peg_r"], OCT), min(x0, x1), max(x0, x1), x_axis(P["pivot_y"], P["pivot_z"]))
    return rb.make_obj("LobbyCannon_Hubs", bm, IRON)


def build():
    objs = [build_barrel(), build_bands(), build_carriage(), build_wheels(), build_hubs()]
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for o in objs:
        for v in o.data.vertices:
            lo = Vector(map(min, lo, v.co))
            hi = Vector(map(max, hi, v.co))
    shift = Matrix.Scale(P["scale"], 4) @ Matrix.Translation(Vector((-(lo.x + hi.x) / 2, -(lo.y + hi.y) / 2, -lo.z)))
    for o in objs:
        o.data.transform(shift)
        rb.planar_stud_uvs(o.data)
        o.data.update()
    size = (hi - lo) * 2 * P["scale"]
    tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in objs)
    return objs, {"studs": [round(c, 2) for c in size], "tris": tris}
