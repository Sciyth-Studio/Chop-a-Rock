import bpy, bmesh, math, random, sys
from mathutils import Vector, Matrix

sys.path.insert(0, r"C:\Users\Admin\Documents\RobloxDev\.claude\skills\rock-model\scripts")
import rock_builder as rb

V = Vector
OFFSET = {"BigCroc": -14.0, "BoulderCrab": 0.0, "FrostYeti": 13.0}
ONLY = globals().get("ONLY")


def lin(rgb):
    def f(c):
        c = c / 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    return (f(rgb[0]), f(rgb[1]), f(rgb[2]), 1.0)


def collection(name):
    col = bpy.data.collections.get(name)
    if col is None:
        col = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(col)
    return col


def clear(name):
    col = collection(name)
    for obj in list(col.objects):
        me = obj.data
        bpy.data.objects.remove(obj)
        if me and me.users == 0 and not me.name.startswith("Bloky_"):
            bpy.data.meshes.remove(me)


def color_material():
    mat = bpy.data.materials.get("BossColor")
    if mat is None:
        mat = bpy.data.materials.new("BossColor")
        mat.use_nodes = True
        nt = mat.node_tree
        bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
        attr = nt.nodes.new("ShaderNodeVertexColor")
        attr.layer_name = "Col"
        nt.links.new(attr.outputs["Color"], bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.9
    return mat


def neon_material(name, rgb):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = lin(rgb)
    bsdf.inputs["Emission Color"].default_value = lin(rgb)
    bsdf.inputs["Emission Strength"].default_value = 0.9
    mat.diffuse_color = lin(rgb)
    return mat


def sc(pts, origin, k):
    o = V(origin)
    return [o + (V(p) - o) * k for p in pts]


def mx(pts):
    return [V((-p.x, p.y, p.z)) for p in pts]


def blob(c, r, seed, rings=3, seg=7, jit=0.1, zmin=None, zmax=None):
    rng = random.Random(seed)
    pts = []
    for i in range(rings + 2):
        lat = -math.pi / 2 + math.pi * i / (rings + 1)
        if i in (0, rings + 1):
            pts.append(V((0, 0, math.sin(lat))) * (1 + rng.uniform(-jit, jit)))
            continue
        for j in range(seg):
            lon = math.tau * (j + 0.5 * (i % 2)) / seg + rng.uniform(-0.15, 0.15)
            k = 1 + rng.uniform(-jit, jit)
            pts.append(V((math.cos(lat) * math.cos(lon), math.cos(lat) * math.sin(lon), math.sin(lat))) * k)
    out = []
    for p in pts:
        q = V((c[0] + p.x * r[0], c[1] + p.y * r[1], c[2] + p.z * r[2]))
        if zmin is not None:
            q.z = max(q.z, zmin)
        if zmax is not None:
            q.z = min(q.z, zmax)
        out.append(q)
    return out


def cbox(c, size, ch=0.15):
    hx, hy, hz = size[0] / 2, size[1] / 2, size[2] / 2
    pts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            for sz in (-1, 1):
                pts.append(V((c[0] + sx * (hx - ch), c[1] + sy * hy, c[2] + sz * hz)))
                pts.append(V((c[0] + sx * hx, c[1] + sy * (hy - ch), c[2] + sz * hz)))
                pts.append(V((c[0] + sx * hx, c[1] + sy * hy, c[2] + sz * (hz - ch))))
    return pts


def frame(d):
    d = d.normalized()
    ref = V((0, 0, 1)) if abs(d.z) < 0.9 else V((0, 1, 0))
    u = d.cross(ref).normalized()
    v = d.cross(u).normalized()
    return u, v


def ring(p, d, r, n=6, rot=0.0, squash=1.0):
    u, v = frame(d)
    return [p + (u * math.cos(rot + i * math.tau / n) + v * math.sin(rot + i * math.tau / n) * squash) * r for i in range(n)]


def frustum(p0, p1, r0, r1, n=6, rot=0.0, squash=1.0, bulge=0.0):
    p0, p1 = V(p0), V(p1)
    d = p1 - p0
    pts = ring(p0, d, r0, n, rot, squash) + ring(p1, d, r1, n, rot, squash)
    if bulge:
        pts += ring((p0 + p1) / 2, d, max(r0, r1) * (1 + bulge), n, rot + math.pi / n, squash)
    return pts


def cone(base, tip, r, n=4, rot=0.0, squash=1.0):
    base, tip = V(base), V(tip)
    return ring(base, tip - base, r, n, rot, squash) + [tip]


def rect_ring(y, hw, z0, z1, ch=0.3, x=0.0):
    return [
        V((x - hw + ch, y, z0)), V((x + hw - ch, y, z0)), V((x + hw, y, z0 + ch)), V((x + hw, y, z1 - ch)),
        V((x + hw - ch, y, z1)), V((x - hw + ch, y, z1)), V((x - hw, y, z1 - ch)), V((x - hw, y, z0 + ch)),
    ]


def plate(c, normal, r, t, n=6, rot=0.0, inner=0.7, sink=0.2):
    c, normal = V(c), V(normal).normalized()
    return ring(c - normal * sink, normal, r, n, rot) + ring(c + normal * t, normal, r * inner, n, rot)


class Boss:
    def __init__(self, name):
        self.name = name
        self.pieces = {}
        clear(name)
        self.col = collection(name)
        self.spots = 0

    def piece(self, name, joint, parent):
        p = Piece(self, name, joint, parent)
        self.pieces[name] = p
        return p

    def link(self, obj, joint, parent, kind):
        self.col.objects.link(obj)
        obj.location.x = OFFSET[self.name]
        obj["joint"] = list(joint)
        obj["parent"] = parent
        obj["kind"] = kind

    def spot(self, parent, c, normal, r, color, rot=0.0, t=0.22):
        self.spots += 1
        bm = bmesh.new()
        hull(bm, plate(c, normal, r, t, rot=rot))
        me = bpy.data.meshes.new(f"{self.name}_WeakSpot{self.spots}")
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bm.to_mesh(me)
        bm.free()
        me.materials.append(neon_material(f"{self.name}_Neon", color))
        obj = bpy.data.objects.new(me.name, me)
        self.link(obj, self.pieces[parent].joint, parent, "WeakSpot")
        obj["centre"] = list(c)
        obj["normal"] = list(V(normal).normalized())
        return obj

    def eyes(self, parent, s, cx, y, z):
        for kind, rgb in (("Eyes", (245, 245, 245)), ("Pupils", (20, 20, 20))):
            bm = bmesh.new()
            bm.from_mesh(bpy.data.meshes["Bloky_" + kind])
            for v in bm.verts:
                side = 1 if v.co.x > 0 else -1
                v.co = V((side * cx + (v.co.x - side * 0.205) * s, y + (v.co.y + 0.47) * s, z + (v.co.z - 0.53) * s))
            me = bpy.data.meshes.new(f"{self.name}_{kind}")
            bm.to_mesh(me)
            bm.free()
            me.materials.append(rb.plain_material(f"Boss_{kind}_Mat", rgb))
            obj = bpy.data.objects.new(me.name, me)
            self.link(obj, self.pieces[parent].joint, parent, kind)

    def finish(self):
        tris = 0
        for p in self.pieces.values():
            tris += p.finish()
        return tris


def hull(bm, pts):
    tmp = bmesh.new()
    for p in pts:
        tmp.verts.new(p)
    bmesh.ops.convex_hull(tmp, input=tmp.verts[:])
    for v in [v for v in tmp.verts if not v.link_faces]:
        tmp.verts.remove(v)
    me = bpy.data.meshes.new("_tmp")
    tmp.to_mesh(me)
    tmp.free()
    bm.from_mesh(me)
    bpy.data.meshes.remove(me)


class Piece:
    def __init__(self, boss, name, joint, parent):
        self.boss, self.name, self.joint, self.parent = boss, name, V(joint), parent
        self.bm = bmesh.new()
        self.bm.loops.layers.float_color.new("Col")

    def add(self, pts, color, both=False):
        for group in ([pts, mx(pts)] if both else [pts]):
            n0 = len(self.bm.faces)
            hull(self.bm, group)
            self.bm.faces.ensure_lookup_table()
            lay = self.bm.loops.layers.float_color["Col"]
            c = lin(color)
            for f in self.bm.faces[n0:]:
                for loop in f.loops:
                    loop[lay] = c
        return self

    def paint(self, directions, color, cos_limit, centre):
        lay = self.bm.loops.layers.float_color["Col"]
        c = lin(color)
        for f in self.bm.faces:
            d = (f.calc_center_median() - V(centre)).normalized()
            if any(d.dot(V(k).normalized()) > cos_limit for k in directions):
                for loop in f.loops:
                    loop[lay] = c

    def paint_fans(self, directions, color, centre):
        lay = self.bm.loops.layers.float_color["Col"]
        c = lin(color)
        for k in directions:
            k = V(k).normalized()
            vert = max(self.bm.verts, key=lambda v: (v.co - V(centre)).normalized().dot(k))
            for f in vert.link_faces:
                for loop in f.loops:
                    loop[lay] = c

    def patches(self, directions, centre, r, color, t=0.06):
        from mathutils.bvhtree import BVHTree

        tree = BVHTree.FromBMesh(self.bm)
        for i, k in enumerate(directions):
            k = V(k).normalized()
            hit, normal, _, _ = tree.ray_cast(V(centre) + k * 30, -k)
            if hit is not None:
                self.add(rough_plate(hit, normal, r, t, i), color)

    def finish(self):
        bm = self.bm
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        me = bpy.data.meshes.new(f"{self.boss.name}_{self.name}")
        bm.to_mesh(me)
        tris = sum(len(f.verts) - 2 for f in bm.faces)
        bm.free()
        for poly in me.polygons:
            poly.use_smooth = False
        rb.planar_stud_uvs(me)
        me.materials.append(color_material())
        me.color_attributes.active_color = me.color_attributes["Col"]
        me.color_attributes.render_color_index = me.color_attributes.find("Col")
        obj = bpy.data.objects.new(me.name, me)
        self.boss.link(obj, self.joint, self.parent, "Piece")
        return tris


def brow_pts(cx, y_back, y_front, z, e, side):
    xo, xi = cx + 0.7 * e, max(cx - 0.7 * e, 0.03)
    pts = []
    for y in (y_back, y_front):
        pts += [V((xo, y, z + 0.36 * e)), V((xi, y, z - 0.02 * e)), V((xi, y, z + 0.6 * e)), V((xo, y, z + 0.95 * e))]
    return pts if side > 0 else mx(pts)


def jit(pts, seed, amt=0.08):
    rng = random.Random(seed)
    return [V(p) + V((rng.uniform(-amt, amt), rng.uniform(-amt, amt), rng.uniform(-amt, amt))) for p in pts]


def tufts(centre, rx, ry, n, length, w, a0=0.0, a1=math.tau, down=1.0, out=0.35, seed=0):
    rng = random.Random(seed)
    groups = []
    for i in range(n):
        a = a0 + (a1 - a0) * (i + 0.5) / n
        dxy = V((math.cos(a), math.sin(a), 0))
        t = V((-math.sin(a), math.cos(a), 0))
        p = V(centre) + V((math.cos(a) * rx, math.sin(a) * ry, 0))
        d = (dxy * out + V((0, 0, -down))).normalized()
        ln = length * rng.uniform(0.75, 1.2)
        up = V((0, 0, w * 0.9))
        groups.append([p + t * w + up, p - t * w + up, p - dxy * w * 0.9 + up * 0.5, p + dxy * w * 0.45 + up * 0.3, p + d * ln])
    return groups


def chain(points, radii, n=6):
    groups = []
    for i in range(len(points) - 1):
        a, b = V(points[i]), V(points[i + 1])
        d0 = (b - a) if i == 0 else (b - V(points[i - 1]))
        d1 = (V(points[i + 2]) - a) if i + 2 < len(points) else (b - a)
        if radii[i + 1] <= 0:
            groups.append(ring(a, d0, radii[i], n) + [b])
        else:
            groups.append(ring(a, d0, radii[i], n) + ring(b, d1, radii[i + 1], n))
    return groups


def crystal(base, tip, r, n=5, rot=0.0):
    base, tip = V(base), V(tip)
    d = tip - base
    return ring(base, d, r * 0.7, n, rot) + ring(base + d * 0.5, d, r, n, rot) + [tip]


def rough_plate(c, normal, r, t, seed, n=7, sink=0.5):
    rng = random.Random(seed)
    c, normal = V(c), V(normal).normalized()
    u, v = frame(normal)
    pts = []
    for i in range(n):
        a = i * math.tau / n + rng.uniform(-0.2, 0.2)
        k = r * rng.uniform(0.7, 1.15)
        e = u * math.cos(a) * k + v * math.sin(a) * k
        pts += [c - normal * sink + e, c + normal * t + e * 0.88]
    return pts


def build_yeti():
    FUR, FUR2, NAVY, BROW = (168, 205, 242), (146, 188, 234), (42, 62, 120), (26, 40, 88)
    HORN, ICE, GLOW, FRAME, MOUTH = (242, 238, 228), (70, 175, 255), (40, 170, 255), (30, 44, 96), (14, 20, 46)
    b = Boss("FrostYeti")

    def fringe(piece, groups, mirror=None):
        for i, g in enumerate(groups):
            piece.add([mirror(p) for p in g] if mirror else g, FUR if i % 2 else FUR2)

    lt = b.piece("LowerTorso", (0, 0, 3.5), "Root")
    lt.add(blob((0, 0.1, 3.7), (2.5, 1.75, 1.15), 11, rings=2, seg=7, jit=0.12), FUR)
    lt.add(blob((0, -1.0, 3.5), (1.45, 0.95, 0.95), 12, rings=2, seg=6), NAVY)
    lt.add(blob((0, 1.1, 3.7), (1.6, 0.85, 0.95), 13, rings=2, seg=6), NAVY)

    ut = b.piece("UpperTorso", (0, 0, 4.4), "LowerTorso")
    ut.add(blob((0, -0.3, 6.3), (3.15, 2.2, 2.1), 21, rings=3, seg=8, jit=0.12), FUR)
    ut.add(blob((0, -0.05, 4.9), (2.55, 1.85, 1.25), 22, rings=2, seg=7, jit=0.12), FUR2)
    ut.add(blob((0, 1.0, 7.3), (2.9, 1.95, 1.65), 23, rings=2, seg=7, jit=0.14), FUR)
    front = ((0.6, -2.62, 7.0), (2.0, -2.2, 6.85), (2.15, -2.5, 5.9), (0.8, -2.85, 5.9), (1.25, -2.3, 4.4), (0.4, -2.15, 3.95))
    ut.add([V((x * s, y + dy, z)) for s in (-1, 1) for x, y, z in front for dy in (0.0, 0.9)], NAVY)
    fringe(ut, tufts((0, 1.0, 6.5), 2.7, 1.85, 5, 1.1, 0.5, a0=0.35, a1=math.pi - 0.35, seed=1))
    fringe(ut, tufts((0, -0.3, 5.5), 3.0, 2.1, 2, 1.0, 0.5, a0=-1.05, a1=-0.35, seed=2))
    fringe(ut, tufts((0, -0.3, 5.5), 3.0, 2.1, 2, 1.0, 0.5, a0=math.pi + 0.35, a1=math.pi + 1.05, seed=3))
    for i, (p0, p1, r) in enumerate((
        ((2.2, 1.5, 7.9), (2.75, 2.0, 10.7), 0.62), ((3.2, 1.1, 7.5), (4.25, 1.6, 9.7), 0.52),
        ((1.3, 2.1, 7.8), (1.45, 2.9, 9.9), 0.48), ((2.8, 2.1, 7.1), (3.6, 3.0, 8.7), 0.42),
    )):
        ut.add(crystal(p0, p1, r, rot=i), ICE, both=True)
    ut.add(plate((1.95, -1.4, 4.75), (0.6, -1, 0), 0.82, 0.02, inner=0.95, sink=0.6), FRAME, both=True)

    hd = b.piece("Head", (0, -1.2, 6.9), "UpperTorso")
    hd.add(blob((0, -2.0, 7.8), (2.2, 1.85, 1.75), 31, rings=3, seg=8, jit=0.1), FUR)
    hd.add(blob((0, -2.2, 9.2), (1.6, 1.3, 0.75), 32, rings=2, seg=6, jit=0.14), FUR2)
    hd.add(cbox((0, -3.35, 7.8), (3.0, 1.1, 1.75), 0.4), NAVY)
    hd.add(cbox((0, -3.95, 7.25), (1.45, 0.5, 0.6), 0.15), NAVY)
    hd.add(cbox((0, -3.8, 6.9), (2.3, 0.2, 0.3), 0.05), MOUTH)
    for side in (1, -1):
        hd.add(brow_pts(0.74, -3.7, -4.28, 8.1, 0.78, side), BROW)
    for i, x in enumerate((-1.25, -0.65, 0.0, 0.65, 1.25)):
        z = 8.85 + (0.12 if i % 2 else 0)
        hd.add([V((x - 0.36, -3.5, z + 0.25)), V((x + 0.36, -3.5, z + 0.25)), V((x, -3.2, z + 0.5)), V((x, -4.0, z + 0.3)), V((x * 1.08, -4.3, z - 0.28))], FUR if i % 2 else FUR2)
    for g in (
        [V((1.9, -2.9, 8.1)), V((1.9, -2.3, 7.5)), V((2.1, -2.1, 8.2)), V((1.6, -2.6, 7.6)), V((2.85, -3.0, 6.9))],
        [V((1.9, -2.0, 7.6)), V((1.9, -1.4, 7.1)), V((2.1, -1.3, 7.8)), V((1.6, -1.7, 7.1)), V((2.75, -1.8, 6.5))],
    ):
        hd.add(g, FUR2, both=True)
    for side in (1, -1):
        pts = [(side * x, y, z) for x, y, z in ((1.5, -1.9, 8.5), (2.4, -1.9, 8.75), (3.0, -1.95, 9.25), (3.25, -2.05, 10.0), (3.1, -2.2, 10.95))]
        for g in chain(pts, (0.7, 0.66, 0.58, 0.45, 0.0)):
            hd.add(g, HORN)
    b.eyes("Head", 2.6, 0.74, -3.9, 8.0)

    jw = b.piece("Jaw", (0, -2.7, 6.75), "Head")
    jw.add(cbox((0, -3.5, 6.45), (2.9, 1.5, 0.8), 0.25), NAVY)
    jw.add(cone((0.98, -4.1, 6.6), (1.04, -4.3, 7.5), 0.32, n=4), HORN, both=True)

    for side, tag in ((1, "Left"), (-1, "Right")):
        def s(p):
            return V((p[0] * side, p[1], p[2]))

        ua = b.piece(tag + "UpperArm", s((3.0, -0.1, 7.1)), "UpperTorso")
        ua.add([s(p) for p in blob((3.95, -0.2, 7.1), (1.7, 1.7, 1.55), 41, rings=2, seg=7, jit=0.13)], FUR)
        ua.add([s(p) for p in jit(frustum((4.15, -0.25, 6.7), (4.7, -0.55, 4.9), 1.4, 1.2, n=7, bulge=0.1), 42)], FUR2)
        fringe(ua, tufts((3.95, -0.2, 6.25), 1.5, 1.5, 5, 1.0, 0.5, a0=-2.0, a1=2.0, seed=4), s)

        la = b.piece(tag + "LowerArm", s((4.7, -0.55, 4.9)), tag + "UpperArm")
        la.add([s(p) for p in jit(frustum((4.7, -0.55, 5.25), (4.6, -1.3, 3.4), 1.2, 1.55, n=7, bulge=0.08), 43)], FUR)
        fringe(la, tufts((4.6, -1.3, 3.75), 1.4, 1.4, 7, 0.95, 0.48, seed=5), s)

        ha = b.piece(tag + "Hand", s((4.6, -1.3, 3.3)), tag + "LowerArm")
        ha.add([s(p) for p in blob((4.55, -1.5, 2.3), (1.3, 1.4, 1.2), 44, rings=2, seg=7, jit=0.1)], NAVY)
        ha.add([s(p) for p in jit(cbox((4.5, -2.3, 1.9), (2.0, 1.0, 1.1), 0.3), 45, 0.05)], NAVY)

        ul = b.piece(tag + "UpperLeg", s((1.6, 0.0, 3.5)), "LowerTorso")
        ul.add([s(p) for p in jit(frustum((1.6, 0.0, 3.8), (1.7, -0.15, 2.4), 1.35, 1.2, n=7, bulge=0.1), 46)], FUR)

        ll = b.piece(tag + "LowerLeg", s((1.7, -0.15, 2.4)), tag + "UpperLeg")
        ll.add([s(p) for p in jit(frustum((1.7, -0.15, 2.7), (1.7, 0.0, 1.2), 1.25, 1.3, n=7), 47)], FUR2)
        ll.add([s(p) for p in plate((1.7, -1.22, 2.15), (0, -1, 0.12), 0.72, 0.02, inner=0.95, sink=0.5)], FRAME)
        fringe(ll, tufts((1.7, 0.0, 1.5), 1.2, 1.2, 7, 0.7, 0.42, seed=6), s)

        ft = b.piece(tag + "Foot", s((1.7, 0.0, 1.1)), tag + "LowerLeg")
        ft.add([s(p) for p in jit([(0.75, 1.0, 0), (2.65, 1.0, 0), (0.85, 1.0, 1.1), (2.55, 1.0, 1.1), (0.6, -1.5, 0), (2.8, -1.5, 0), (0.75, -1.5, 0.75), (2.65, -1.5, 0.75), (0.8, -0.3, 1.2), (2.6, -0.3, 1.2)], 48, 0.0)], NAVY)
        for dx in (-0.72, 0.0, 0.72):
            ft.add([s(p) for p in cbox((1.7 + dx, -1.85, 0.33), (0.62, 0.9, 0.66), 0.18)], NAVY)

    b.spot("UpperTorso", (1.95, -1.4, 4.75), (0.6, -1, 0), 0.62, GLOW)
    b.spot("UpperTorso", (-1.95, -1.4, 4.75), (-0.6, -1, 0), 0.62, GLOW)
    b.spot("LeftLowerLeg", (1.7, -1.22, 2.15), (0, -1, 0.12), 0.54, GLOW)
    b.spot("RightLowerLeg", (-1.7, -1.22, 2.15), (0, -1, 0.12), 0.54, GLOW)
    return b.finish()


def build_crab():
    RED, RED2, DARK = (238, 72, 26), (205, 56, 20), (70, 22, 12)
    ROCK, ROCK3, ROCK2, MOSS, GLOW = (142, 142, 142), (156, 156, 156), (104, 104, 104), (98, 165, 48), (40, 220, 255)
    b = Boss("BoulderCrab")
    W_, K_ = (3.85, -3.8, 2.0), 1.4

    body = b.piece("Body", (0, 0, 1.9), "Root")
    body.add(jit(cbox((0, 0.1, 1.9), (6.0, 4.4, 1.6), 0.55), 1, 0.05), RED)
    body.add(cbox((0, -2.05, 1.7), (3.6, 0.7, 1.3), 0.3), RED2)
    body.add(cbox((0, -2.42, 1.42), (1.5, 0.12, 0.2), 0.04), DARK)
    body.add(frustum((0.8, -2.3, 2.1), (0.8, -3.0, 2.85), 0.34, 0.34, n=5), RED2, both=True)

    shell = b.piece("Shell", (0, 0.3, 2.6), "Body")
    centre = (0, 0.5, 3.5)
    shell.add(blob(centre, (4.0, 3.6, 2.9), 7, rings=3, seg=7, jit=0.15, zmin=2.5), ROCK)
    shell.add(blob((-1.3, 1.3, 5.0), (2.3, 2.1, 1.6), 8, rings=2, seg=6, jit=0.16), ROCK3)
    shell.add(blob((1.9, -0.5, 4.75), (2.0, 1.9, 1.45), 9, rings=2, seg=6, jit=0.16), ROCK3)
    shell.add(blob((0.4, 2.7, 3.8), (2.5, 1.5, 1.7), 10, rings=2, seg=6, jit=0.16, zmin=2.5), ROCK)
    shell.add(blob((-2.4, -1.0, 3.9), (1.7, 1.8, 1.5), 14, rings=2, seg=6, jit=0.16, zmin=2.5), ROCK)
    shell.patches(((0.55, -0.35, 0.75), (-0.5, 0.35, 0.8), (0.1, 0.9, 0.45), (-0.85, -0.3, 0.45), (0.9, 0.5, 0.35)), centre, 1.0, MOSS)
    shell.add(cbox((0, -2.95, 3.35), (3.1, 0.9, 1.3), 0.3), ROCK2)
    for side in (1, -1):
        shell.add(brow_pts(0.82, -3.2, -3.85, 3.5, 0.8, side), ROCK)
    b.eyes("Shell", 2.7, 0.82, -3.4, 3.3)

    for side, tag in ((1, "Left"), (-1, "Right")):
        def s(p):
            return V((p[0] * side, p[1], p[2]))

        c1 = b.piece(tag + "Claw1", s((2.4, -1.7, 1.8)), "Body")
        c1.add([s(p) for p in frustum((2.3, -1.6, 1.8), (3.6, -2.6, 1.9), 0.9, 0.85, n=6)], RED2)
        c2 = b.piece(tag + "Claw2", s((3.6, -2.6, 1.9)), tag + "Claw1")
        c2.add([s(p) for p in frustum((3.6, -2.5, 1.9), (3.85, -3.8, 2.0), 0.88, 1.0, n=6)], RED)
        c3 = b.piece(tag + "Claw3", s((3.85, -3.8, 2.0)), tag + "Claw2")
        c3.add([s(p) for p in sc(blob((3.35, -4.55, 2.05), (1.55, 1.3, 1.3), 51, rings=3, seg=7), W_, K_)], RED)
        c3.add([s(p) for p in sc(frustum((2.9, -5.0, 2.45), (1.75, -5.75, 2.0), 0.85, 0.4, n=5, squash=0.8) + [V((1.2, -5.85, 1.45))], W_, K_)], RED)
        for x, y, z in ((2.55, -5.6, 2.75), (2.0, -5.95, 2.4), (3.1, -5.2, 3.0)):
            c3.add([s(p) for p in sc(cone((x, y + 0.2, z - 0.3), (x - 0.1, y - 0.25, z + 0.3), 0.22, n=4), W_, K_)], RED2)
        pn = b.piece(tag + "Pincer", s(sc([(3.3, -5.0, 1.45)], W_, K_)[0]), tag + "Claw3")
        pn.add([s(p) for p in sc(frustum((3.3, -4.9, 1.3), (2.0, -5.6, 0.95), 0.62, 0.34, n=5, squash=0.8) + [V((1.35, -5.8, 1.15))], W_, K_)], RED2)

        for i, (y, yaw) in enumerate(((-0.2, -0.2), (0.9, 0.3), (1.95, 0.85)), start=1):
            d = V((math.cos(yaw), math.sin(yaw), 0))
            root = V((2.9, y, 1.85))
            k1 = root + d * 2.0 + V((0, 0, 0.75))
            k2 = k1 + d * 0.7 + V((0, 0, -1.0))
            tip = k2 + d * 0.3 + V((0, 0, -k2.z))
            l1 = b.piece(f"{tag}Leg{i}_1", s(root), "Body")
            l1.add([s(p) for p in frustum(root - d * 0.3, k1, 0.88, 0.8, n=6, bulge=0.05)], RED)
            l2 = b.piece(f"{tag}Leg{i}_2", s(k1), f"{tag}Leg{i}_1")
            l2.add([s(p) for p in frustum(k1 + V((0, 0, 0.12)), k2, 0.8, 0.7, n=6)], RED2)
            l3 = b.piece(f"{tag}Leg{i}_3", s(k2), f"{tag}Leg{i}_2")
            l3.add([s(p) for p in frustum(k2 + V((0, 0, 0.25)), tip + V((0, 0, 0.35)), 0.7, 0.3, n=5) + [tip]], RED)
            if i >= 2:
                p = root + (k1 - root) * 0.72
                n = (d * 0.7 + V((0, 0, 0.7))).normalized()
                c = p + n * 0.8
                l1.add([s(q) for q in plate(c, n, 0.7, 0.02, inner=0.95, sink=0.4)], RED2)
                b.spot(f"{tag}Leg{i}_1", s(c), s(n), 0.54, GLOW)
    return b.finish()


def build_croc():
    GREEN, GREEN2, DARK, LIME, TOOTH = (44, 142, 52), (38, 128, 48), (26, 100, 40), (204, 232, 44), (245, 245, 240)
    GLOW, FRAME, MOUTH = (255, 125, 0), (22, 84, 34), (60, 20, 20)
    b = Boss("BigCroc")

    body = b.piece("Body", (0, -0.5, 1.8), "Root")
    body.add(jit(rect_ring(-3.8, 1.9, 1.3, 3.1, 0.55) + rect_ring(-1.4, 2.15, 1.3, 3.35, 0.65) + rect_ring(1.2, 2.1, 1.3, 3.25, 0.65) + rect_ring(2.95, 1.65, 1.3, 2.95, 0.5), 1, 0.05), GREEN)
    body.add(rect_ring(-3.75, 1.75, 0.5, 1.45, 0.4) + rect_ring(-1.4, 2.0, 0.42, 1.45, 0.45) + rect_ring(1.2, 1.95, 0.45, 1.45, 0.45) + rect_ring(2.9, 1.5, 0.55, 1.45, 0.4), LIME)
    for y, h in ((-2.8, 1.1), (-1.25, 1.35), (0.35, 1.3), (1.9, 1.1)):
        body.add([V((0.6, y - 0.75, 3.05)), V((-0.6, y - 0.75, 3.05)), V((0.6, y + 0.75, 3.05)), V((-0.6, y + 0.75, 3.05)), V((0, y + 0.2, 3.15 + h))], DARK)
        body.add([V((0.85, y - 0.6, 2.95)), V((1.7, y - 0.6, 2.75)), V((0.85, y + 0.6, 2.95)), V((1.7, y + 0.6, 2.75)), V((1.3, y + 0.15, 3.05 + h * 0.6))], DARK, both=True)

    head = b.piece("Head", (0, -3.8, 2.2), "Body")
    head.add(jit(rect_ring(-3.5, 2.05, 1.8, 3.45, 0.5) + rect_ring(-5.25, 2.0, 1.8, 3.3, 0.5), 2, 0.04), GREEN)
    head.add(rect_ring(-5.0, 1.75, 1.8, 2.85, 0.4) + rect_ring(-6.8, 1.5, 1.8, 2.6, 0.35) + rect_ring(-8.1, 1.4, 1.8, 2.5, 0.35), GREEN2)
    head.add(blob((0, -7.6, 2.55), (1.2, 0.65, 0.4), 3, rings=1, seg=6), GREEN)
    head.add(cbox((0.55, -7.9, 2.85), (0.42, 0.42, 0.25), 0.1), DARK, both=True)
    head.add(blob((1.05, -4.6, 3.45), (0.95, 0.95, 0.75), 4, rings=2, seg=6, jit=0.08), GREEN, both=True)
    head.add(cbox((0, -4.4, 1.72), (3.6, 1.9, 0.2), 0.05), MOUTH)
    for side in (1, -1):
        head.add(brow_pts(1.02, -5.0, -5.72, 3.2, 0.84, side), DARK)
    for y, x in ((-5.6, 1.5), (-6.5, 1.42), (-7.4, 1.35)):
        head.add(cone((x, y, 1.95), (x + 0.05, y, 1.4), 0.2, n=4, rot=math.pi / 4), TOOTH, both=True)
    b.eyes("Head", 2.8, 1.02, -5.4, 3.2)

    jaw = b.piece("Jaw", (0, -3.9, 1.75), "Head")
    jaw.add(jit(rect_ring(-3.7, 2.3, 0.65, 1.75, 0.45) + rect_ring(-6.6, 1.95, 0.8, 1.75, 0.4) + rect_ring(-8.2, 1.75, 1.0, 1.8, 0.35) + rect_ring(-8.6, 1.25, 1.1, 1.78, 0.3), 5, 0.03), LIME)
    for y, x in ((-4.6, 2.1), (-5.6, 2.0), (-6.6, 1.82), (-7.5, 1.72)):
        jaw.add(cone((x, y, 1.65), (x, y - 0.05, 2.5), 0.28, n=4, rot=math.pi / 4), TOOTH, both=True)
    for x in (0.45, 1.2):
        jaw.add(cone((x, -8.35, 1.65), (x, -8.4, 2.45), 0.28, n=4, rot=math.pi / 4), TOOTH, both=True)

    for side, tag in ((1, "Left"), (-1, "Right")):
        def s(p):
            return V((p[0] * side, p[1], p[2]))

        for name, y, seed in (("Front", -2.4, 11), ("Back", 1.6, 12)):
            leg = tag + name
            up = b.piece(leg + "Upper", s((2.0, y, 1.9)), "Body")
            up.add([s(p) for p in blob((2.6, y, 1.85), (1.05, 1.2, 1.1), seed, rings=2, seg=6, jit=0.1)], GREEN)
            up.add([s(p) for p in plate((3.52, y, 1.95), (1, 0, 0.15), 0.8, 0.02, inner=0.95, sink=0.45, rot=math.pi / 6)], FRAME)
            lo = b.piece(leg + "Lower", s((2.95, y - 0.15, 1.25)), leg + "Upper")
            lo.add([s(p) for p in jit(frustum((2.9, y - 0.1, 1.45), (3.1, y - 0.5, 0.45), 0.8, 0.7, n=6), seed + 10, 0.04)], DARK)
            ft = b.piece(leg + "Foot", s((3.1, y - 0.5, 0.55)), leg + "Lower")
            ft.add([s(p) for p in [(2.3, y + 0.15, 0), (3.9, y + 0.15, 0), (2.45, y + 0.15, 0.6), (3.75, y + 0.15, 0.6), (2.15, y - 1.5, 0), (4.05, y - 1.5, 0), (2.3, y - 1.5, 0.42), (3.9, y - 1.5, 0.42)]], GREEN)
            for dx in (-0.62, 0.0, 0.62):
                ft.add([s(p) for p in cone((3.1 + dx, y - 1.35, 0.26), (3.1 + dx * 1.25, y - 2.25, 0.08), 0.3, n=4, rot=math.pi / 4)], GREEN2)
            b.spot(leg + "Upper", s((3.52, y, 1.95)), s((1, 0, 0.15)), 0.6, GLOW, rot=math.pi / 6)

    ys = (2.75, 4.45, 6.1, 7.7, 9.3)
    hw0, hw1 = (1.6, 1.3, 1.0, 0.7), (1.1, 0.85, 0.6, 0.1)
    top0, top1 = (2.9, 2.55, 2.2, 1.85), (2.4, 2.05, 1.7, 1.25)
    bot0, bot1 = (0.6, 0.7, 0.8, 0.9), (0.8, 0.9, 1.0, 1.1)
    parent = "Body"
    for i in range(4):
        t = b.piece(f"Tail{i + 1}", (0, ys[i], (top0[i] + bot0[i]) / 2), parent)
        y0, y1 = ys[i] - 0.15, ys[i + 1] + 0.1
        m0, m1 = bot0[i] + (top0[i] - bot0[i]) * 0.38, bot1[i] + (top1[i] - bot1[i]) * 0.38
        t.add(rect_ring(y0, hw0[i], m0 - 0.1, top0[i], min(0.4, hw0[i] * 0.4)) + rect_ring(y1, hw1[i], m1 - 0.1, top1[i], min(0.4, hw1[i] * 0.4)), GREEN if i % 2 == 0 else GREEN2)
        t.add(rect_ring(y0 + 0.02, hw0[i] * 0.9, bot0[i], m0, min(0.3, hw0[i] * 0.3)) + rect_ring(y1, hw1[i] * 0.9, bot1[i], m1, min(0.3, hw1[i] * 0.3)), LIME)
        ym, zt, w = (ys[i] + ys[i + 1]) / 2, (top0[i] + top1[i]) / 2, hw0[i] * 0.42
        t.add([V((w, ym - 0.6, zt - 0.05)), V((-w, ym - 0.6, zt - 0.05)), V((w, ym + 0.6, zt - 0.25)), V((-w, ym + 0.6, zt - 0.25)), V((0, ym + 0.15, zt + 1.0 - i * 0.2))], DARK)
        parent = f"Tail{i + 1}"
    return b.finish()


builders = {"FrostYeti": build_yeti, "BoulderCrab": build_crab, "BigCroc": build_croc}
tri_report = {name: fn() for name, fn in builders.items() if ONLY is None or name in ONLY}
