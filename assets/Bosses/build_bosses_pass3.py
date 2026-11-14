import bpy, bmesh, math, random, sys
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree

sys.path.insert(0, r"C:\Users\Admin\Documents\RobloxDev\.claude\skills\rock-model\scripts")
import rock_builder as rb

V = Vector
OFFSET = {"BigCroc": -14.0, "BoulderCrab": 0.0, "FrostYeti": 13.0}
ONLY = globals().get("ONLY")
VOXEL = 0.07
DENSITY = globals().get("DENSITY", 7.0)


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


def mx(pts):
    return [V((-p[0], p[1], p[2])) for p in pts]


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


def cone(base, tip, r, n=4, rot=0.0, squash=1.0):
    base, tip = V(base), V(tip)
    return ring(base, tip - base, r, n, rot, squash) + [tip]


def crystal(base, tip, r, n=5, rot=0.0):
    base, tip = V(base), V(tip)
    d = tip - base
    return ring(base, d, r * 0.7, n, rot) + ring(base + d * 0.5, d, r, n, rot) + [tip]


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


def plate(c, normal, r, t, n=6, rot=0.0, inner=0.7, sink=0.2, squash=1.0):
    c, normal = V(c), V(normal).normalized()
    return ring(c - normal * sink, normal, r, n, rot, squash) + ring(c + normal * t, normal, r * inner, n, rot, squash)


def brow_pts(cx, y_back, y_front, z, e, side):
    xo, xi = cx + 0.7 * e, max(cx - 0.7 * e, 0.03)
    pts = []
    for y in (y_back, y_front):
        pts += [V((xo, y, z + 0.36 * e)), V((xi, y, z - 0.02 * e)), V((xi, y, z + 0.6 * e)), V((xo, y, z + 0.95 * e))]
    return pts if side > 0 else mx(pts)


def sring(y, top, bottom, hw, e=2.6, n=20, x=0.0):
    cz, b = (top + bottom) / 2, (top - bottom) / 2
    out = []
    for i in range(n):
        t = math.tau * i / n
        ct, st = math.cos(t), math.sin(t)
        out.append(V((x + hw * math.copysign(abs(ct) ** (2 / e), ct), y, cz + b * math.copysign(abs(st) ** (2 / e), st))))
    return out


def hull_bm(pts):
    bm = bmesh.new()
    for p in pts:
        bm.verts.new(p)
    bmesh.ops.convex_hull(bm, input=bm.verts[:])
    for v in [v for v in bm.verts if not v.link_faces]:
        bm.verts.remove(v)
    return bm


def loft_bm(rings):
    bm = bmesh.new()
    vs = [[bm.verts.new(p) for p in r] for r in rings]
    n = len(rings[0])
    for a, b in zip(vs, vs[1:]):
        for i in range(n):
            bm.faces.new((a[i], a[(i + 1) % n], b[(i + 1) % n], b[i]))
    bm.faces.new(vs[0])
    bm.faces.new(vs[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    return bm


def tube_rings(points, radii, n=10, squash=1.0):
    pts = [V(p) for p in points]
    rings = []
    u = None
    for i, p in enumerate(pts):
        d = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        if u is None:
            u, _ = frame(d)
        else:
            u = (u - d * u.dot(d)).normalized()
        v = d.cross(u).normalized()
        rings.append([p + (u * math.cos(k * math.tau / n) + v * math.sin(k * math.tau / n) * squash) * radii[i] for k in range(n)])
    return rings


def to_mesh(bm, name="_prim"):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    return me


class Boss:
    def __init__(self, name):
        self.name = name
        self.pieces = {}
        clear(name)
        self.col = collection(name)
        self.spots = 0
        self.tris = 0

    def piece(self, name, joint, parent, sym=False, density=None):
        p = Piece(self, name, joint, parent, sym, density or getattr(self, "density", None))
        self.pieces[name] = p
        return p

    def link(self, obj, joint, parent, kind):
        self.col.objects.link(obj)
        obj.location.x = OFFSET[self.name]
        obj["joint"] = list(joint)
        obj["parent"] = parent
        obj["kind"] = kind

    def spot(self, parent, c, normal, r, color, rot=0.0, t=0.22, n=6, squash=1.0):
        self.spots += 1
        bm = hull_bm(plate(c, normal, r, t, n=n, rot=rot, squash=squash))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
        me = to_mesh(bm, f"{self.name}_WeakSpot{self.spots}")
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
            me = to_mesh(bm, f"{self.name}_{kind}")
            me.materials.append(rb.plain_material(f"Boss_{kind}_Mat", rgb))
            obj = bpy.data.objects.new(me.name, me)
            self.link(obj, self.pieces[parent].joint, parent, kind)

    def finish(self):
        for p in list(self.pieces.values()):
            p.finish()
        for obj in list(self.col.objects):
            own = obj.name.split("_", 1)[1]
            left = own.startswith("Left") if obj["kind"] == "Piece" else obj["parent"].startswith("Left")
            if not left:
                continue
            me = obj.data.copy()
            me.transform(Matrix.Scale(-1, 4, (1, 0, 0)))
            me.flip_normals()
            if obj["kind"] == "WeakSpot":
                self.spots += 1
                me.name = f"{self.name}_WeakSpot{self.spots}"
            else:
                me.name = f"{self.name}_Right{own[4:]}"
            twin = bpy.data.objects.new(me.name, me)
            j = obj["joint"]
            par = obj["parent"]
            self.link(twin, (-j[0], j[1], j[2]), "Right" + par[4:] if par.startswith("Left") else par, obj["kind"])
            if obj["kind"] == "WeakSpot":
                c, n = obj["centre"], obj["normal"]
                twin["centre"] = [-c[0], c[1], c[2]]
                twin["normal"] = [-n[0], n[1], n[2]]
        self.tris = 0
        for obj in self.col.objects:
            if obj["kind"] == "Piece":
                obj.data.calc_loop_triangles()
                self.tris += len(obj.data.loop_triangles)
        return self.tris


class Piece:
    def __init__(self, boss, name, joint, parent, sym, density):
        self.boss, self.name, self.joint, self.parent = boss, name, V(joint), parent
        self.sym, self.density = sym, density or DENSITY
        self.prims, self.details, self.paints, self.cuts = [], [], [], []
        self.zmin = None

    def _add(self, bm, color):
        if self.zmin is not None:
            for v in bm.verts:
                v.co.z = max(v.co.z, self.zmin)
        self.prims.append((to_mesh(bm), color))
        return self

    def ball(self, c, r, color, sub=2, both=False):
        for sx in (1, -1) if both else (1,):
            bm = bmesh.new()
            bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=1.0)
            for v in bm.verts:
                v.co = V((sx * c[0] + v.co.x * r[0], c[1] + v.co.y * r[1], c[2] + v.co.z * r[2]))
            self._add(bm, color)
        return self

    def solid(self, pts, color, both=False):
        for g in ([pts, mx(pts)] if both else [pts]):
            self._add(hull_bm(g), color)
        return self

    def loft(self, rings, color):
        return self._add(loft_bm(rings), color)

    def tube(self, points, radii, color, n=10, squash=1.0, both=False):
        for pts in ([points, mx(points)] if both else [points]):
            self._add(loft_bm(tube_rings(pts, radii, n, squash)), color)
        return self

    def cut(self, pts, color, both=False):
        for g in ([pts, mx(pts)] if both else [pts]):
            bm = hull_bm(g)
            bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
            self.cuts.append((to_mesh(bm, "_cut"), color))
        return self

    def detail(self, pts, color, both=False):
        for g in ([pts, mx(pts)] if both else [pts]):
            self.details.append((g, color))
        return self

    def paint(self, fn, color):
        self.paints.append((fn, color))
        return self

    def region(self, c, r, color):
        c = V(c)
        return self.paint(lambda p, n: ((p.x - c.x) / r[0]) ** 2 + ((p.y - c.y) / r[1]) ** 2 + ((p.z - c.z) / r[2]) ** 2 < 1, color)

    def _fuse(self):
        bm = bmesh.new()
        for me, _ in self.prims:
            bm.from_mesh(me)
        src = to_mesh(bm, "_fuse")
        tmp = bpy.data.objects.new("_fuse", src)
        bpy.context.scene.collection.objects.link(tmp)
        md = tmp.modifiers.new("R", "REMESH")
        md.mode = "VOXEL"
        md.voxel_size = VOXEL
        cutters = []
        for i, (me, _) in enumerate(self.cuts):
            cutter = bpy.data.objects.new("_cutter", me)
            bpy.context.scene.collection.objects.link(cutter)
            cutters.append(cutter)
            bo = tmp.modifiers.new(f"B{i}", "BOOLEAN")
            bo.operation = "DIFFERENCE"
            bo.solver = "EXACT"
            bo.object = cutter
        sm = tmp.modifiers.new("S", "SMOOTH")
        sm.factor = 0.5
        sm.iterations = 5
        dg = bpy.context.evaluated_depsgraph_get()
        dg.update()
        dense = bpy.data.meshes.new_from_object(tmp.evaluated_get(dg))
        dense.calc_loop_triangles()
        area = sum(p.area for p in dense.polygons)
        target = max(60, area * self.density)
        dec = tmp.modifiers.new("D", "DECIMATE")
        dec.ratio = min(1.0, target / max(1, len(dense.loop_triangles)))
        if self.sym:
            dec.use_symmetry = True
            dec.symmetry_axis = "X"
        dg = bpy.context.evaluated_depsgraph_get()
        dg.update()
        low = bpy.data.meshes.new_from_object(tmp.evaluated_get(dg))
        bpy.data.objects.remove(tmp)
        for cutter in cutters:
            bpy.data.objects.remove(cutter)
        bpy.data.meshes.remove(src)
        bpy.data.meshes.remove(dense)
        bm = bmesh.new()
        bm.from_mesh(low)
        bpy.data.meshes.remove(low)
        bmesh.ops.triangulate(bm, faces=bm.faces[:])
        bmesh.ops.dissolve_limit(bm, angle_limit=math.radians(5), verts=bm.verts[:], edges=bm.edges[:])
        bmesh.ops.triangulate(bm, faces=bm.faces[:])
        carved = to_mesh(bm, "_carved")
        bm = bmesh.new()
        bm.from_mesh(carved)
        bpy.data.meshes.remove(carved)
        return bm

    def finish(self):
        bm = self._fuse()
        lay = bm.loops.layers.float_color.new("Col")
        trees = []
        for me, color in self.prims + self.cuts:
            t = bmesh.new()
            t.from_mesh(me)
            trees.append((BVHTree.FromBMesh(t), color))
            t.free()
            bpy.data.meshes.remove(me)
        bm.faces.ensure_lookup_table()
        bm.normal_update()
        colors = {}
        for f in bm.faces:
            p = f.calc_center_median()
            ds = []
            for tree, color in trees:
                hit = tree.find_nearest(p)
                ds.append((hit[3] if hit[0] is not None else 1e9, color))
            best = min(d for d, _ in ds)
            pick = [color for d, color in ds if d <= best + 0.03][-1]
            for fn, color in self.paints:
                if fn(p, f.normal):
                    pick = color
            colors[f] = pick
        for _ in range(2):
            new = {}
            for f in bm.faces:
                nb = [colors[g] for e in f.edges for g in e.link_faces if g is not f]
                if nb and colors[f] not in nb:
                    new[f] = max(set(nb), key=nb.count)
            colors.update(new)
        for f, color in colors.items():
            c = lin(color)
            for loop in f.loops:
                loop[lay] = c
        for pts, color in self.details:
            for f in bm.faces:
                f.tag = True
            d = to_mesh(hull_bm(pts), "_detail")
            bm.from_mesh(d)
            bpy.data.meshes.remove(d)
            lay = bm.loops.layers.float_color["Col"]
            c = lin(color)
            fresh = [f for f in bm.faces if not f.tag]
            bmesh.ops.recalc_face_normals(bm, faces=fresh)
            for f in fresh:
                for loop in f.loops:
                    loop[lay] = c
        for v in bm.verts:
            if v.co.z < 0:
                v.co.z = 0
        tris = sum(len(f.verts) - 2 for f in bm.faces)
        me = to_mesh(bm, f"{self.boss.name}_{self.name}")
        for poly in me.polygons:
            poly.use_smooth = False
        rb.planar_stud_uvs(me)
        me.materials.append(color_material())
        me.color_attributes.active_color = me.color_attributes["Col"]
        me.color_attributes.render_color_index = me.color_attributes.find("Col")
        obj = bpy.data.objects.new(me.name, me)
        self.boss.link(obj, self.joint, self.parent, "Piece")
        return 0 if self.name.startswith("Left") else tris


def fin(y, z, hw, length, h, top=0.35):
    return [
        V((hw, y - length / 2, z)), V((-hw, y - length / 2, z)), V((hw, y + length / 2, z)), V((-hw, y + length / 2, z)),
        V((hw * top, y - length * 0.1, z + h)), V((-hw * top, y - length * 0.1, z + h)),
        V((hw * top, y + length * 0.3, z + h)), V((-hw * top, y + length * 0.3, z + h)),
    ]


def build_croc():
    GREEN, GREEN2, DARK, LIME, TOOTH = (44, 142, 52), (38, 128, 48), (26, 100, 40), (204, 232, 44), (245, 245, 240)
    GLOW, FRAME, MOUTH = (255, 125, 0), (22, 84, 34), (60, 20, 20)
    b = Boss("BigCroc")

    body = b.piece("Body", (0, -0.5, 2.0), "Root", sym=True)
    body.loft([sring(-4.7, 2.7, 1.3, 1.55), sring(-3.3, 3.0, 1.1, 2.0), sring(-1.0, 3.12, 1.05, 2.15), sring(1.2, 3.0, 1.1, 2.05), sring(3.3, 2.75, 1.2, 1.5)], GREEN)
    body.paint(lambda p, n: p.z < 1.72, LIME)
    for i, y in enumerate((-3.5, -2.15, -0.8, 0.55, 1.9)):
        body.detail(fin(y, 2.85, 0.55, 1.15, 1.05 - abs(i - 2) * 0.08), DARK)
        if i < 4:
            body.detail([V((p.x + 1.2, p.y + 0.1, p.z - 0.25)) for p in fin(y, 2.85, 0.4, 0.95, 0.6)], DARK, both=True)

    head = b.piece("Head", (0, -4.4, 2.3), "Body", sym=True)
    head.loft([sring(-4.0, 3.4, 1.85, 1.95, 3.0), sring(-5.2, 3.5, 1.85, 1.95, 3.0), sring(-5.95, 2.85, 1.85, 1.75, 3.0), sring(-7.4, 2.7, 1.85, 1.5, 3.0), sring(-8.5, 2.55, 1.9, 1.3, 3.0)], GREEN)
    head.ball((0.98, -5.0, 3.45), (0.9, 0.85, 0.6), GREEN, both=True)
    head.ball((0.5, -8.05, 2.6), (0.34, 0.4, 0.3), GREEN, both=True)
    head.detail(cbox((0.98, -5.62, 3.2), (1.2, 0.5, 1.0), 0.2), DARK, both=True)
    for side in (1, -1):
        head.detail(brow_pts(0.98, -5.45, -6.12, 3.2, 0.86, side), DARK)
    head.detail(cbox((0, -6.3, 1.88), (2.6, 3.6, 0.12), 0.04), MOUTH)
    b.eyes("Head", 2.7, 0.98, -5.87, 3.2)

    jaw = b.piece("Jaw", (0, -4.4, 1.85), "Head", sym=True)
    jaw.loft([sring(-4.2, 1.9, 1.0, 2.15), sring(-6.0, 1.9, 1.05, 2.0), sring(-7.6, 1.9, 1.15, 1.8), sring(-8.8, 1.95, 1.3, 1.45)], LIME)
    lip = [(2.1, -4.5, 1.8), (2.0, -6.2, 1.82), (1.8, -7.8, 1.86), (1.2, -8.85, 1.9), (0.0, -9.15, 1.92)]
    jaw.tube(lip + [(-x, y, z) for x, y, z in reversed(lip[:-1])], [0.32] * 9, LIME, n=8)
    for x, y in ((2.0, -5.3), (1.9, -6.7), (1.65, -8.0), (0.65, -8.95)):
        jaw.detail(cone((x, y, 1.9), (x, y - 0.05, 2.85), 0.32, n=4, rot=math.pi / 4), TOOTH, both=True)

    for name, y in (("Front", -2.6), ("Back", 1.7)):
        leg = "Left" + name
        up = b.piece(leg + "Upper", (1.9, y, 2.4), "Body")
        up.ball((2.45, y, 2.1), (0.95, 1.15, 1.15), GREEN)
        up.ball((2.6, y - 0.05, 1.5), (0.82, 0.95, 0.75), GREEN)
        up.detail(plate((3.36, y, 1.95), (1, 0, 0.1), 0.86, 0.02, n=5, rot=-math.pi / 2, inner=0.95, sink=0.5, squash=1.25), FRAME)
        lo = b.piece(leg + "Lower", (2.6, y - 0.1, 1.35), leg + "Upper")
        lo.tube([(2.6, y - 0.05, 1.55), (2.7, y - 0.25, 1.0), (2.75, y - 0.35, 0.55)], [0.72, 0.68, 0.64], GREEN2)
        ft = b.piece(leg + "Foot", (2.75, y - 0.35, 0.65), leg + "Lower")
        ft.solid(cbox((2.75, y - 0.7, 0.37), (1.75, 1.9, 0.74), 0.25), GREEN)
        for dx in (-0.58, 0.0, 0.58):
            ft.ball((2.75 + dx, y - 1.75, 0.3), (0.34, 0.55, 0.3), GREEN)
        b.spot(leg + "Upper", (3.36, y, 1.95), (1, 0, 0.1), 0.66, GLOW, n=5, rot=-math.pi / 2, squash=1.25)

    y0, y1 = 2.9, 9.5

    def at(t):
        return y0 + (y1 - y0) * t, 1.55 + (0.14 - 1.55) * t, 2.8 + (1.4 - 2.8) * t, 1.15 + (1.1 - 1.15) * t

    parent = "Body"
    for i in range(4):
        ya, _, ta, ba = at(i / 4)
        t = b.piece(f"Tail{i + 1}", (0, ya, (ta + ba) / 2), parent, sym=True)
        for k in range(2):
            a = at((i * 2 + k) / 8)
            c = at((i * 2 + k + 1) / 8)
            t.loft([sring(a[0] - 0.12, a[2], a[3], a[1]), sring(c[0] + 0.05, c[2] - (a[2] - c[2]) * 0.35, c[3], max(0.1, c[1] * 0.86))], GREEN if (i * 2 + k) % 2 == 0 else GREEN2)
            ym = (a[0] + c[0]) / 2
            t.detail(fin(ym, (a[2] + c[2]) / 2 - 0.2, max(0.14, a[1] * 0.4), 0.7, 0.85 - (i * 2 + k) * 0.07), DARK)
        t.paint(lambda p, n: p.z < 1.1 + (2.7 - 1.15 - (p.y - y0) / (y1 - y0) * 1.35) * 0.36, LIME)
        parent = f"Tail{i + 1}"
    return b.finish()


def build_yeti():
    FUR, NAVY, BROW = (168, 205, 242), (42, 62, 120), (26, 40, 88)
    HORN, ICE, GLOW, FRAME, MOUTH = (242, 238, 228), (70, 175, 255), (40, 170, 255), (30, 44, 96), (14, 20, 46)
    b = Boss("FrostYeti")
    b.density = 4.5

    lt = b.piece("LowerTorso", (0, 0, 3.6), "Root", sym=True)
    lt.ball((0, 0.1, 3.8), (2.4, 1.8, 1.2), FUR)
    lt.region((0, 1.9, 3.8), (1.6, 0.9, 1.0), NAVY)

    ut = b.piece("UpperTorso", (0, 0, 4.5), "LowerTorso", sym=True)
    ut.ball((0, -0.2, 6.3), (3.0, 2.2, 2.1), FUR)
    ut.ball((0, 0.0, 4.9), (2.5, 1.9, 1.3), FUR)
    ut.ball((0, 1.1, 7.4), (2.7, 1.9, 1.6), FUR)
    ut.ball((1.9, 1.6, 6.2), (1.3, 1.0, 1.2), FUR, both=True)
    ut.ball((0, 2.2, 5.6), (1.6, 0.9, 1.3), FUR)
    ut.ball((2.4, 0.6, 5.3), (1.0, 1.2, 1.1), FUR, both=True)
    ut.ball((2.3, -1.3, 6.9), (1.0, 0.9, 0.9), FUR, both=True)
    front = ((0.6, -2.6, 7.0), (2.0, -2.2, 6.85), (2.15, -2.5, 5.9), (0.8, -2.85, 5.9), (1.25, -2.3, 4.4), (0.4, -2.15, 3.6))
    ut.solid([V((x * s, y + dy, z)) for s in (-1, 1) for x, y, z in front for dy in (0.0, 0.9)], NAVY)
    for i, (p0, p1, r) in enumerate((((2.6, 0.9, 8.2), (3.0, 1.2, 9.9), 0.55), ((3.5, 0.8, 7.8), (4.4, 1.1, 9.2), 0.48), ((1.9, 1.5, 8.2), (2.0, 2.0, 9.5), 0.42))):
        ut.detail(crystal(p0, p1, r, rot=i), ICE, both=True)
    ut.detail(plate((1.95, -1.45, 4.7), (0.6, -1, 0), 0.95, 0.02, inner=0.95, sink=0.6), FRAME, both=True)

    hd = b.piece("Head", (0, -1.3, 7.0), "UpperTorso", sym=True)
    hd.ball((0, -2.0, 8.1), (2.15, 1.9, 1.9), FUR)
    hd.ball((0, -2.1, 9.45), (1.5, 1.3, 0.8), FUR)
    hd.ball((1.75, -2.5, 7.5), (0.8, 0.9, 1.1), FUR, both=True)
    hd.ball((0, -3.3, 9.3), (1.75, 0.65, 0.5), FUR)
    hd.ball((0, -3.2, 7.95), (1.5, 0.9, 1.3), NAVY)
    hd.detail(cbox((0, -3.72, 8.2), (2.55, 0.6, 1.05), 0.25), NAVY)
    hd.cut(cbox((0, -3.95, 7.12), (1.8, 1.1, 0.6), 0.12), MOUTH)
    for side in (1, -1):
        hd.detail(brow_pts(0.72, -3.85, -4.4, 8.2, 0.78, side), BROW)
        pts = [(side * x, y, z) for x, y, z in ((1.6, -1.9, 9.0), (2.5, -1.9, 9.2), (3.0, -1.95, 9.7), (3.1, -2.0, 10.3), (2.9, -2.1, 10.95))]
        for g in chain(pts, (0.72, 0.68, 0.56, 0.42, 0.0)):
            hd.detail(g, HORN)
    b.eyes("Head", 2.6, 0.72, -4.02, 8.2)

    jw = b.piece("Jaw", (0, -2.6, 6.85), "Head", sym=True)
    jw.ball((0, -3.3, 6.6), (1.5, 1.05, 0.5), NAVY)
    jw.detail(cone((0.98, -4.0, 6.7), (1.05, -4.2, 7.65), 0.32, n=4), HORN, both=True)

    ua = b.piece("LeftUpperArm", (3.0, 0.0, 7.3), "UpperTorso")
    ua.ball((3.85, -0.1, 7.2), (1.75, 1.75, 1.6), FUR)
    ua.ball((4.25, -0.2, 6.0), (1.35, 1.4, 1.3), FUR)
    ua.ball((4.75, 0.3, 6.9), (1.0, 1.1, 0.9), FUR)
    la = b.piece("LeftLowerArm", (4.5, -0.3, 5.2), "LeftUpperArm")
    la.ball((4.6, -0.6, 4.5), (1.45, 1.5, 1.3), FUR)
    la.ball((4.65, -1.0, 3.7), (1.6, 1.65, 1.0), FUR)
    ha = b.piece("LeftHand", (4.65, -1.1, 3.3), "LeftLowerArm")
    ha.ball((4.65, -1.3, 2.3), (1.5, 1.6, 1.3), NAVY)
    ha.ball((4.6, -2.2, 2.0), (1.3, 0.8, 0.9), NAVY)

    ul = b.piece("LeftUpperLeg", (1.6, 0.0, 3.7), "LowerTorso")
    ul.ball((1.65, 0.0, 3.1), (1.3, 1.35, 1.1), FUR)
    ll = b.piece("LeftLowerLeg", (1.7, -0.1, 2.5), "LeftUpperLeg")
    ll.ball((1.7, -0.05, 2.0), (1.25, 1.3, 1.0), FUR)
    ll.ball((1.7, 0.0, 1.45), (1.32, 1.38, 0.6), FUR)
    ll.detail(plate((1.7, -1.28, 2.15), (0, -1, 0.12), 0.82, 0.02, inner=0.95, sink=0.5), FRAME)
    ft = b.piece("LeftFoot", (1.7, 0.0, 1.2), "LeftLowerLeg")
    ft.solid(cbox((1.7, -0.4, 0.56), (2.3, 2.9, 1.12), 0.38), NAVY)
    for dx in (-0.75, 0.0, 0.75):
        ft.ball((1.7 + dx, -2.0, 0.4), (0.42, 0.62, 0.4), NAVY)

    b.spot("UpperTorso", (1.95, -1.45, 4.7), (0.6, -1, 0), 0.72, GLOW)
    b.spot("UpperTorso", (-1.95, -1.45, 4.7), (-0.6, -1, 0), 0.72, GLOW)
    b.spot("LeftLowerLeg", (1.7, -1.28, 2.15), (0, -1, 0.12), 0.62, GLOW)
    return b.finish()


def build_crab():
    RED, RED2, DARK = (238, 72, 26), (205, 56, 20), (70, 22, 12)
    ROCK, ROCK2, MOSS, GLOW = (142, 142, 142), (104, 104, 104), (98, 165, 48), (40, 220, 255)
    b = Boss("BoulderCrab")

    body = b.piece("Body", (0, 0, 1.9), "Root", sym=True)
    body.ball((0, 0.2, 1.9), (3.3, 2.6, 1.0), RED)
    body.ball((0, -2.0, 1.8), (1.9, 0.8, 0.85), RED2)
    body.tube([(0.78, -2.4, 2.1), (0.78, -3.0, 2.7)], [0.3, 0.3], RED2, n=6, both=True)
    body.detail(cbox((0, -2.78, 1.5), (1.4, 0.12, 0.2), 0.04), DARK)

    shell = b.piece("Shell", (0, 0.3, 2.6), "Body", density=3.0)
    shell.zmin = 2.55
    shell.ball((0, 0.4, 3.9), (4.0, 3.5, 2.6), ROCK, sub=3)
    shell.ball((-1.5, 1.0, 4.6), (2.6, 2.4, 2.0), ROCK, sub=3)
    shell.ball((1.6, -0.3, 4.5), (2.5, 2.3, 2.0), ROCK, sub=3)
    for c, r in (((1.7, -1.6, 5.7), 1.25), ((-2.0, -0.6, 5.7), 1.3), ((0.2, 2.3, 5.9), 1.35), ((-3.0, 1.9, 4.3), 1.2), ((3.3, 1.2, 4.6), 1.15)):
        shell.region(c, (r, r, r), MOSS)
    shell.cut(cbox((0, -3.4, 3.0), (3.5, 1.6, 1.9), 0.35), ROCK2)
    for side in (1, -1):
        shell.detail(brow_pts(0.88, -2.75, -3.5, 3.42, 0.95, side), ROCK)
    b.eyes("Shell", 3.1, 0.88, -2.62, 3.25)

    c1 = b.piece("LeftClaw1", (2.3, -1.6, 1.8), "Body")
    c1.tube([(2.1, -1.4, 1.8), (3.5, -2.6, 1.9)], [0.95, 0.9], RED2, n=8)
    c2 = b.piece("LeftClaw2", (3.5, -2.6, 1.9), "LeftClaw1")
    c2.tube([(3.45, -2.45, 1.9), (3.75, -3.9, 2.0)], [0.92, 1.05], RED, n=8)
    c3 = b.piece("LeftClaw3", (3.75, -3.9, 2.0), "LeftClaw2")
    c3.ball((3.6, -4.9, 2.05), (1.9, 1.7, 1.6), RED)
    c3.tube([(3.3, -5.8, 2.55), (2.4, -6.6, 2.4), (1.55, -6.9, 1.85), (1.2, -6.7, 1.1)], [1.05, 0.85, 0.58, 0.15], RED, n=8)
    pn = b.piece("LeftPincer", (3.5, -5.6, 1.3), "LeftClaw3")
    pn.tube([(3.5, -5.5, 1.25), (2.5, -6.3, 0.95), (1.65, -6.5, 0.8)], [0.8, 0.6, 0.15], RED2, n=8)

    for i, (y, yaw) in enumerate(((-0.4, -0.1), (0.8, 0.25), (1.9, 0.7)), start=1):
        d = V((math.cos(yaw), math.sin(yaw), 0))
        root = V((2.6, y, 1.9))
        k1 = root + d * 1.5 + V((0, 0, 0.5))
        k2 = k1 + d * 0.75 + V((0, 0, -0.9))
        tip = V((k2.x + d.x * 0.25, k2.y + d.y * 0.25, 0.0))
        l1 = b.piece(f"LeftLeg{i}_1", root, "Body")
        l1.tube([root - d * 0.4, k1], [0.95, 0.9], RED, n=8)
        l2 = b.piece(f"LeftLeg{i}_2", k1, f"LeftLeg{i}_1")
        l2.tube([k1 + V((0, 0, 0.15)), k2], [0.9, 0.78], RED2, n=8)
        l3 = b.piece(f"LeftLeg{i}_3", k2, f"LeftLeg{i}_2")
        l3.tube([k2 + V((0, 0, 0.3)), (k2 + tip) / 2, tip], [0.78, 0.55, 0.16], RED, n=8)
        if i >= 2:
            p = root + (k1 - root) * 0.7
            n = (d * 0.8 + V((0, 0, 0.6))).normalized()
            c = p + n * 0.88
            l1.detail(plate(c, n, 0.82, 0.02, n=8, inner=0.95, sink=0.4), RED2)
            b.spot(f"LeftLeg{i}_1", c, n, 0.62, GLOW, n=8)
    return b.finish()


builders = {"FrostYeti": build_yeti, "BoulderCrab": build_crab, "BigCroc": build_croc}
tri_report = {name: fn() for name, fn in builders.items() if ONLY is None or name in ONLY}
