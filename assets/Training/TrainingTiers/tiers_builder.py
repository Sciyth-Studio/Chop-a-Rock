import math
import random
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

rb = sys.modules["rock_builder"]
H = 0.5

DARK = (45, 45, 45)
GREY = (128, 128, 128)
LIGHT = (200, 200, 200)
SILVER = (215, 215, 220)
NAVY = (25, 45, 120)
RED = (220, 40, 30)
GOLD = (235, 175, 30)
CYAN = (0, 230, 255)
PURPLE = (110, 30, 200)


def collection(name):
    col = bpy.data.collections.get(name)
    if col is None:
        col = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(col)
    return col


def finish(name, bm, color, col):
    rb._remove_object(name)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.triangulate(bm, faces=bm.faces, quad_method="BEAUTY", ngon_method="BEAUTY")
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(name, me)
    collection(col).objects.link(obj)
    rb.planar_stud_uvs(me)
    rb._finish(obj, rb.plain_material(f"Tier_{'_'.join(map(str, color))}", color))
    return obj


def box(bm, lo, hi, bevel=0.0):
    lo, hi = Vector(lo), Vector(hi)
    c, s = (lo + hi) / 2, hi - lo
    m = Matrix.Translation(c * H) @ Matrix.Diagonal((s.x * H, s.y * H, s.z * H, 1.0))
    verts = bmesh.ops.create_cube(bm, size=1.0, matrix=m)["verts"]
    if bevel > 0:
        edges = list({e for v in verts for e in v.link_edges})
        bmesh.ops.bevel(bm, geom=edges, offset=bevel * H, segments=1, affect="EDGES", profile=0.5, clamp_overlap=True)


def frame_from(direction):
    d = Vector(direction).normalized()
    return d.to_track_quat("Z", "Y").to_matrix().to_4x4()


def cyl(bm, p0, p1, r, sides=12, r1=None):
    p0, p1 = Vector(p0), Vector(p1)
    m = Matrix.Translation((p0 + p1) / 2 * H) @ frame_from(p1 - p0)
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=sides, radius1=r * H,
                          radius2=(r if r1 is None else r1) * H, depth=(p1 - p0).length * H, matrix=m)


def prism(bm, pts, axis_lo, axis_hi, plane="xz"):
    def at(p, t):
        if plane == "xz":
            return Vector((p[0], t, p[1])) * H
        if plane == "xy":
            return Vector((p[0], p[1], t)) * H
        return Vector((t, p[0], p[1])) * H
    lo = [bm.verts.new(at(p, axis_lo)) for p in pts]
    hi = [bm.verts.new(at(p, axis_hi)) for p in pts]
    bm.faces.new(lo)
    bm.faces.new(hi[::-1])
    n = len(pts)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new([lo[i], lo[j], hi[j], hi[i]])


def annulus(bm, centre, r_in, r_out, y0, y1, sides=16):
    cx, cz = centre
    ring = lambda r, y: [bm.verts.new(Vector((cx + r * math.cos(2 * math.pi * i / sides), y, cz + r * math.sin(2 * math.pi * i / sides))) * H) for i in range(sides)]
    o0, o1, i0, i1 = ring(r_out, y0), ring(r_out, y1), ring(r_in, y0), ring(r_in, y1)
    for k in range(sides):
        j = (k + 1) % sides
        bm.faces.new([o0[k], o0[j], o1[j], o1[k]])
        bm.faces.new([i0[k], i1[k], i1[j], i0[j]])
        bm.faces.new([o0[k], i0[k], i0[j], o0[j]])
        bm.faces.new([o1[k], o1[j], i1[j], i1[k]])


def octagon(half, chamfer):
    a, b = half, half - chamfer
    return [(b, -a), (a, -b), (a, b), (b, a), (-b, a), (-a, b), (-a, -b), (-b, -a)]


def strip_outline(pts, w):
    left, right = [], []
    n = len(pts)
    for i in range(n):
        p = Vector(pts[i])
        d_in = (p - Vector(pts[i - 1])).normalized() if i > 0 else None
        d_out = (Vector(pts[i + 1]) - p).normalized() if i < n - 1 else None
        normals = [Vector((-d.y, d.x)) for d in (d_in, d_out) if d is not None]
        nrm = sum(normals, Vector((0, 0))).normalized()
        scale = w / 2 / max(nrm.dot(normals[0]), 0.3)
        left.append(tuple(p + nrm * scale))
        right.append(tuple(p - nrm * scale))
    return left + right[::-1], left, right


def chain(bm, points, pitch=0.26, length=0.36, width=0.22, bar=0.07, normal=(0, 1, 0)):
    path = [Vector(p) for p in points]
    seg = []
    total = 0.0
    for a, b in zip(path, path[1:]):
        seg.append((a, b, total))
        total += (b - a).length
    count = max(1, int(total / pitch))
    for k in range(count + 1):
        s = min(k * pitch, total)
        for a, b, t0 in seg:
            if s <= t0 + (b - a).length + 1e-6:
                d = (b - a).normalized()
                p = a + d * (s - t0)
                break
        n = Vector(normal)
        side = d.cross(n)
        if side.length < 1e-4:
            side = d.orthogonal()
        side.normalize()
        up = side.cross(d).normalized()
        if k % 2:
            side, up = up, side
        link(bm, p, d, side, up, length, width, bar)


def link(bm, p, d, side, up, length, width, bar):
    hl, hw = length / 2, width / 2
    outer = [(-hl, -hw), (hl, -hw), (hl, hw), (-hl, hw)]
    inner = [(-hl + bar, -hw + bar), (hl - bar, -hw + bar), (hl - bar, hw - bar), (-hl + bar, hw - bar)]
    def v(u, w, t):
        return bm.verts.new((p + d * u + side * w + up * t) * H)
    o0 = [v(u, w, -bar / 2) for u, w in outer]
    o1 = [v(u, w, bar / 2) for u, w in outer]
    i0 = [v(u, w, -bar / 2) for u, w in inner]
    i1 = [v(u, w, bar / 2) for u, w in inner]
    for k in range(4):
        j = (k + 1) % 4
        bm.faces.new([o0[k], o0[j], o1[j], o1[k]])
        bm.faces.new([i0[k], i1[k], i1[j], i0[j]])
        bm.faces.new([o0[k], i0[k], i0[j], o0[j]])
        bm.faces.new([o1[k], o1[j], i1[j], i1[k]])


def build_brick():
    col = "Tier2_Brick"
    bm = bmesh.new()
    for s in (-1, 1):
        c = s * 1.85
        box(bm, (c - 0.8, -0.75, 0), (c + 0.8, 0.75, 0.45), 0.06)
        box(bm, (c - 0.55, -0.5, 0.44), (c + 0.55, 0.5, 2.31), 0.04)
        box(bm, (c - 0.8, -0.75, 2.3), (c + 0.8, 0.75, 2.7), 0.06)
    pillars = finish("BrickStand_Pillars", bm, GREY, col)

    z0, ch, g, length, half = 2.7, 0.5, 0.06, 1.0, 2.55
    bricks = bmesh.new()
    for r in range(3):
        offset = 0.0 if r % 2 == 0 else (length + g) / 2
        x = -half - offset
        while x < half:
            x0, x1 = max(x, -half), min(x + length, half)
            if x1 - x0 > 0.2:
                box(bricks, (x0 + g / 2, -0.55, z0 + r * ch + g / 2), (x1 - g / 2, 0.55, z0 + (r + 1) * ch - g / 2), 0.04)
            x += length + g
    zt = z0 + 3 * ch
    for x0 in (-length - g / 2, g / 2):
        box(bricks, (x0, -0.55, zt + g / 2), (x0 + length, 0.55, zt + ch - g / 2), 0.04)
    brick = finish("TrainingBricks", bricks, RED, col)

    mortar = bmesh.new()
    box(mortar, (-half + 0.05, -0.5, z0 - 0.01), (half - 0.05, 0.5, zt - 0.05))
    box(mortar, (-length + 0.05, -0.5, zt - 0.06), (length - 0.05, 0.5, zt + ch - 0.05))
    mortar_obj = finish("TrainingBricks_Mortar", mortar, LIGHT, col)
    return [pillars], [brick, mortar_obj]


def build_steel():
    col = "Tier3_Steel"
    plates, posts, bolts = bmesh.new(), bmesh.new(), bmesh.new()
    for s in (-1, 1):
        c = s * 2.0
        box(plates, (c - 0.85, -0.7, 0), (c + 0.85, 0.7, 0.4), 0.05)
        for bx in (-0.62, 0.62):
            for by in (-0.47, 0.47):
                box(bolts, (c + bx - 0.11, by - 0.11, 0.38), (c + bx + 0.11, by + 0.11, 0.58), 0.03)
        box(posts, (c - 0.45, -0.42, 0.38), (c - 0.27, 0.42, 3.27), 0.02)
        box(posts, (c + 0.27, -0.42, 0.38), (c + 0.45, 0.42, 3.27), 0.02)
        box(posts, (c - 0.28, -0.26, 0.38), (c + 0.28, 0.26, 3.27))
    out = [finish("SteelStand_Plates", plates, GREY, col), finish("SteelStand_Posts", posts, NAVY, col),
           finish("SteelStand_Bolts", bolts, DARK, col)]
    beam = bmesh.new()
    box(beam, (-3.1, -0.7, 3.25), (3.1, 0.7, 3.47), 0.05)
    box(beam, (-3.05, -0.52, 3.45), (3.05, 0.52, 3.87))
    box(beam, (-3.15, -0.76, 3.85), (3.15, 0.76, 4.17), 0.06)
    return out, [finish("SteelBeam", beam, (150, 150, 155), col)]


def build_vault():
    col = "Tier4_Vault"
    cz, rad, t = 3.85, 1.8, 0.4
    base = bmesh.new()
    box(base, (-2.3, -1.3, 0), (2.3, 1.3, 0.5), 0.06)
    box(base, (-0.6, -1.42, 0), (0.6, 1.42, 0.62), 0.05)
    housings, rods = bmesh.new(), bmesh.new()
    legs = [((0, 0, 0.5), (0, 0, cz - rad + 0.15)), ((-1.55, 0, 0.5), (-0.8, 0, cz - rad + 0.45)), ((1.55, 0, 0.5), (0.8, 0, cz - rad + 0.45))]
    for p0, p1 in legs:
        p0, p1 = Vector(p0), Vector(p1)
        mid = p0.lerp(p1, 0.55)
        cyl(housings, p0, mid, 0.32, 10)
        cyl(housings, mid - (p1 - p0).normalized() * 0.15, mid + (p1 - p0).normalized() * 0.02, 0.38, 10)
        cyl(rods, mid, p1, 0.2, 10)
    stand_chains = bmesh.new()
    for sx in (-1, 1):
        for sy in (-1, 1):
            y = sy * 0.95
            box(base, (sx * 1.62 - 0.18, y - 0.18, 0.48), (sx * 1.62 + 0.18, y + 0.18, 0.78), 0.04)
            chain(stand_chains, [Vector((sx * 1.62, y, 0.72)), Vector((sx * 2.36, y, 0.6)), Vector((sx * 2.4, y, 0.08))], normal=(0, 1, 0))
    frame = [finish("VaultStand_Base", base, DARK, col), finish("VaultStand_Pistons", housings, (70, 70, 70), col),
             finish("VaultStand_Rods", rods, SILVER, col), finish("VaultStand_Chains", stand_chains, (110, 110, 110), col)]

    door = bmesh.new()
    cyl(door, (0, -t, cz), (0, t, cz), rad, 16)
    for y0, y1 in ((-t - 0.08, -t + 0.01), (t - 0.01, t + 0.08)):
        annulus(door, (0, cz), 1.2, 1.5, y0, y1)
    cyl(door, (0, -t - 0.06, cz), (0, -t + 0.01, cz), 0.75, 16)
    cyl(door, (0, t - 0.01, cz), (0, t + 0.06, cz), 0.75, 16)
    for s in (-1, 1):
        box(door, (s * 1.72 - 0.2, -0.3, cz - 0.4), (s * 1.72 + 0.2, 0.3, cz + 0.4), 0.04)
    door_obj = finish("VaultDoor", door, (75, 75, 80), col)

    chains = bmesh.new()
    rim = rad + 0.06
    for ang in (45, 135):
        a = math.radians(ang)
        d = Vector((math.cos(a), 0, math.sin(a)))
        c = Vector((0, 0, cz))
        yf, yb = -t - 0.14, t + 0.14
        for sgn in (1, -1):
            e = d * sgn * rim
            chain(chains, [c + Vector((0, yf, 0)), c + e + Vector((0, yf, 0)), c + e * 1.04 + Vector((0, 0, 0)) + Vector((0, yf * 0.4, 0)),
                           c + e * 1.04 + Vector((0, yb * 0.4, 0)), c + e + Vector((0, yb, 0)), c + Vector((0, yb, 0))])
    chain_obj = finish("VaultDoor_Chains", chains, (120, 120, 125), col)

    lock = bmesh.new()
    yl = -t - 0.25
    box(lock, (-0.32, yl - 0.13, cz - 0.62), (0.32, yl + 0.13, cz - 0.08), 0.05)
    box(lock, (-0.25, yl - 0.05, cz - 0.1), (-0.15, yl + 0.05, cz + 0.22))
    box(lock, (0.15, yl - 0.05, cz - 0.1), (0.25, yl + 0.05, cz + 0.22))
    box(lock, (-0.25, yl - 0.05, cz + 0.14), (0.25, yl + 0.05, cz + 0.24))
    lock_obj = finish("VaultDoor_Lock", lock, GOLD, col)
    return frame, [door_obj, chain_obj, lock_obj]


def build_core():
    col = "Tier5_Core"
    oz, orad = 3.7, 1.0
    frame, glow = bmesh.new(), bmesh.new()
    prism(frame, octagon(2.2, 0.6), 0, 0.35, "xy")
    prism(frame, octagon(1.9, 0.5), 0.33, 0.65, "xy")
    box(frame, (-0.6, -2.35, 0), (0.6, -1.6, 0.78), 0.04)
    annulus_z(glow, 1.0, 1.25, 0.64, 0.68)
    for y0, y1 in ((-2.23, -2.19), (2.19, 2.23)):
        for s in (-1, 1):
            box(glow, (s * 1.1 - 0.5, y0, 0.14), (s * 1.1 + 0.5, y1, 0.22))
    for s in (-1, 1):
        box(glow, (s * 2.19, -0.8, 0.14), (s * 2.23, 0.8, 0.22))
    for z in (0.26, 0.42, 0.58):
        box(glow, (-0.32, -2.38, z - 0.04), (0.32, -2.34, z + 0.04))
    for s in (-1, 1):
        pts = [(s * 1.5, 0.6), (s * 1.5, 1.6), (s * 2.0, 2.25), (s * 2.0, oz + 0.95)]
        outline, left, right = strip_outline(pts, 0.56)
        prism(frame, outline if s > 0 else outline[::-1], -0.3, 0.3)
        outer = right if s > 0 else left
        stripe, _, _ = strip_outline([(x + s * 0.0, z) for x, z in outer], 0.1)
        inset = [(x - s * 0.12, z) for x, z in stripe]
        for y0, y1 in ((-0.34, -0.29), (0.29, 0.34)):
            prism(glow, inset if s > 0 else inset[::-1], y0, y1)
        for dz in (-1, 1):
            zc = oz + dz * 0.72
            box(frame, (s * 0.95 - 0.02, -0.34, zc - 0.28), (s * 1.75, 0.34, zc + 0.28), 0.05)
            box(frame, (s * 0.62, -0.26, zc - 0.2 + dz * 0.0), (s * 0.95 + 0.02, 0.26, zc + 0.2), 0.04)
    frame_obj = finish("CoreStand_Frame", frame, (55, 55, 60), col)
    glow_obj = finish("CoreStand_Glow", glow, CYAN, col)
    orb = bmesh.new()
    bmesh.ops.create_icosphere(orb, subdivisions=2, radius=orad * H, matrix=Matrix.Translation((0, 0, oz * H)))
    return [frame_obj, glow_obj], [finish("EnergyCore", orb, CYAN, col)]


def annulus_z(bm, r_in, r_out, z0, z1, sides=20):
    ring = lambda r, z: [bm.verts.new(Vector((r * math.cos(2 * math.pi * i / sides), r * math.sin(2 * math.pi * i / sides), z)) * H) for i in range(sides)]
    o0, o1, i0, i1 = ring(r_out, z0), ring(r_out, z1), ring(r_in, z0), ring(r_in, z1)
    for k in range(sides):
        j = (k + 1) % sides
        bm.faces.new([o0[k], o0[j], o1[j], o1[k]])
        bm.faces.new([i0[k], i1[k], i1[j], i0[j]])
        bm.faces.new([o0[k], i0[k], i0[j], o0[j]])
        bm.faces.new([o1[k], o1[j], i1[j], i1[k]])


def buttress(bm, quad, centre, frac=0.55, height=0.6, out=0.16, slope=0.14, sink=0.04):
    b0, b1, t0, t1 = quad
    m = (1 - frac) / 2
    bl, br = b0.lerp(b1, m), b0.lerp(b1, 1 - m)
    tl, tr = t0.lerp(t1, m), t0.lerp(t1, 1 - m)
    ul, ur = bl.lerp(tl, height), br.lerp(tr, height)
    edge = br - bl
    n = Vector((edge.y, -edge.x, 0)).normalized()
    if n.dot((bl + br) / 2 - centre) < 0:
        n = -n
    inner = [bl - n * sink, br - n * sink, ur - n * sink, ul - n * sink]
    outer = [bl + n * out, br + n * out, ur + n * out - Vector((0, 0, slope)), ul + n * out - Vector((0, 0, slope))]
    vi = [bm.verts.new(p * H) for p in inner]
    vo = [bm.verts.new(p * H) for p in outer]
    bm.faces.new(vi[::-1])
    bm.faces.new(vo)
    for k in range(4):
        j = (k + 1) % 4
        bm.faces.new([vi[k], vi[j], vo[j], vo[k]])


def build_cosmic(seed=3):
    col = "Tier6_Cosmic"
    rng = random.Random(seed)
    cz, half, px = 3.9, 0.95, 2.15
    dark, trim_c = (35, 35, 40), (75, 75, 85)
    pillars, trim, glow = bmesh.new(), bmesh.new(), bmesh.new()
    for s in (-1, 1):
        c = s * px
        prism(trim, [(c + x, y) for x, y in octagon(0.95, 0.3)], 0, 0.3, "xy")
        sides = 7
        bot, top = [], []
        for i in range(sides):
            a = 2 * math.pi * (i + 0.5) / sides
            rb_ = 0.78 * rng.uniform(0.92, 1.05)
            rt = 0.62 * rng.uniform(0.85, 1.05)
            bot.append(bm_v(pillars, c + math.cos(a) * rb_, math.sin(a) * rb_ * 0.85, 0.25))
            top.append(bm_v(pillars, c + math.cos(a) * rt, math.sin(a) * rt * 0.85, 2.3 + rng.uniform(-0.2, 0.2)))
        pillars.faces.new(bot[::-1])
        tc = bm_v(pillars, c, 0, 2.15)
        for i in range(sides):
            j = (i + 1) % sides
            pillars.faces.new([bot[i], bot[j], top[j], top[i]])
            pillars.faces.new([top[i], top[j], tc])
        cx = Vector((c, 0, 0))
        faces = []
        for i in range(sides):
            j = (i + 1) % sides
            mid = (Vector(bot[i].co) + Vector(bot[j].co)) / 2 / H
            faces.append((math.atan2(mid.y, mid.x - c), i, j))
        for target in (-math.pi / 2, math.pi / 2, 0.0, math.pi):
            _, i, j = min(faces, key=lambda f: abs(math.atan2(math.sin(f[0] - target), math.cos(f[0] - target))))
            buttress(pillars, [Vector(v.co) / H for v in (bot[i], bot[j], top[i], top[j])], cx)
        cyl(glow, (c, 0, 2.0), (c, 0, 2.5), 0.26, 8)
    clamps = bmesh.new()
    for s in (-1, 1):
        def side(points):
            out = [(s * x, z) for x, z in points]
            return out if s > 0 else out[::-1]
        body = [(1.3, cz + 0.62), (1.75, cz + 0.98), (2.3, cz + 0.98), (2.55, cz + 0.7), (2.55, cz - 0.7),
                (2.3, cz - 0.98), (1.75, cz - 0.98), (1.3, cz - 0.62), (1.3, cz - 0.38), (1.9, cz - 0.38),
                (1.9, cz + 0.38), (1.3, cz + 0.38)]
        prism(clamps, side(body), -0.65, 0.65)
        plate = [(1.98, cz + 0.84), (2.24, cz + 0.84), (2.42, cz + 0.64), (2.42, cz - 0.64), (2.24, cz - 0.84), (1.98, cz - 0.84)]
        for y0, y1 in ((-0.74, -0.64), (0.64, 0.74)):
            prism(trim, side(plate), y0, y1)
        for dz in (-1, 1):
            fin = [(2.54, cz + dz * 0.2), (2.9, cz + dz * 0.62), (2.54, cz + dz * 0.72)]
            prism(clamps, side(fin) if dz > 0 else side(fin)[::-1], -0.14, 0.14)
            box(trim, (min(s * 1.36, s * 1.7), -0.72, cz + dz * 0.5 - 0.05), (max(s * 1.36, s * 1.7), 0.72, cz + dz * 0.5 + 0.05))
            box(glow, (min(s * 1.26, s * 1.31), -0.5, cz + dz * 0.5 - 0.08), (max(s * 1.26, s * 1.31), 0.5, cz + dz * 0.5 + 0.08))
        box(glow, (min(s * 1.84, s * 1.92), -0.35, cz - 0.25), (max(s * 1.84, s * 1.92), 0.35, cz + 0.25))
        box(glow, (min(s * 1.95, s * 2.3), -0.25, cz - 1.04), (max(s * 1.95, s * 2.3), 0.25, cz - 0.96))
    frame = [finish("CosmicStand_Pillars", pillars, dark, col), finish("CosmicStand_Clamps", clamps, dark, col),
             finish("CosmicStand_Trim", trim, trim_c, col), finish("CosmicStand_Glow", glow, PURPLE, col)]
    cube = bmesh.new()
    box(cube, (-half, -half, cz - half), (half, half, cz + half), 0.06)
    return frame, [finish("CosmicCube", cube, PURPLE, col)]


def bm_v(bm, x, y, z):
    return bm.verts.new(Vector((x, y, z)) * H)


TIERS = (("Brick", build_brick), ("Steel", build_steel), ("Vault", build_vault), ("Core", build_core), ("Cosmic", build_cosmic))


def build_all():
    out = {}
    for name, fn in TIERS:
        frame, breakable = fn()
        out[name] = {"frame": frame, "breakable": breakable,
                     "tris": sum(len(o.data.polygons) for o in frame + breakable)}
    return out


def render_lineup(built, path, spacing=8.0):
    objs = []
    for i, (name, _) in enumerate(TIERS):
        for o in built[name]["frame"] + built[name]["breakable"]:
            o.location.x = (i - 2) * spacing * H
            objs.append(o)
    rb.setup_preview_scene()
    bpy.context.scene.camera.data.clip_end = 1000.0
    rb.render_preview(objs, path + "_front.png", (0, -30.0, 2.2), target=(0, 0, 1.6))
    rb.render_preview(objs, path + "_34.png", (14.0, -24.0, 9.0), target=(0, 0, 1.2))
    for o in objs:
        o.location.x = 0


def render_tier(objs, path):
    rb.setup_preview_scene()
    rb.render_preview(objs, path + "_front.png", (0, -9.0, 1.2), target=(0, 0, 1.1))
    rb.render_preview(objs, path + "_34.png", (5.0, -7.0, 3.6), target=(0, 0, 1.0))
