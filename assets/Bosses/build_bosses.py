import bpy, bmesh, math, random, sys
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree

sys.path.insert(0, r"C:\Users\Admin\Documents\RobloxDev\.claude\skills\rock-model\scripts")
import rock_builder as rb

V = Vector
OFFSET = {"BigCroc": -14.0, "BoulderCrab": 0.0, "FrostYeti": 13.0}
ONLY = globals().get("ONLY")
VOXEL = 0.07
DENSITY = globals().get("DENSITY", 3.0)
ANGLE = globals().get("ANGLE", 13.0)


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
        self.prims, self.details, self.paints, self.cuts, self.plate_specs = [], [], [], [], []
        self.zmin = None

    def _add(self, bm, color):
        if self.zmin is not None:
            for v in bm.verts:
                v.co.z = max(v.co.z, self.zmin)
        self.prims.append((to_mesh(bm), color))
        return self

    def ball(self, c, r, color, sub=3, both=False, e=2.0):
        for sx in (1, -1) if both else (1,):
            bm = bmesh.new()
            bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=1.0)
            for v in bm.verts:
                k = (abs(v.co.x) ** e + abs(v.co.y) ** e + abs(v.co.z) ** e) ** (1 / e)
                q = v.co / k
                v.co = V((sx * c[0] + q.x * r[0], c[1] + q.y * r[1], c[2] + q.z * r[2]))
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

    def plates(self, directions, centre, r, color):
        self.plate_specs.append((directions, centre, r, color))
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
        sm.iterations = 3
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
        bmesh.ops.dissolve_limit(bm, angle_limit=math.radians(ANGLE), verts=bm.verts[:], edges=bm.edges[:])
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
        for directions, centre, r, color in self.plate_specs:
            tree = BVHTree.FromBMesh(bm)
            rng = random.Random(7)
            for k in directions:
                k = V(k).normalized()
                hit, normal, _, _ = tree.ray_cast(V(centre) + k * 30, -k)
                if hit is None:
                    continue
                u, v = frame(normal)
                pts = []
                for i in range(6):
                    a = i * math.tau / 6 + rng.uniform(-0.25, 0.25)
                    q = (u * math.cos(a) + v * math.sin(a)) * r * rng.uniform(0.75, 1.1)
                    edge, _, _, _ = tree.ray_cast(hit + q + normal * 2.0, -normal)
                    edge = edge if edge is not None else hit + q
                    pts += [edge - normal * 0.4, edge + normal * 0.09]
                pts.append(hit + normal * 0.09)
                self.details.append((pts, color))
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


def scallops(centre, rx, ry, n, w, length, a0=0.0, a1=math.tau, thick=0.4, out=0.2, seed=0):
    rng = random.Random(seed)
    groups = []
    for i in range(n):
        a = a0 + (a1 - a0) * (i + 0.5) / n
        dxy = V((math.cos(a), math.sin(a), 0))
        t = V((-math.sin(a), math.cos(a), 0))
        p = V(centre) + V((math.cos(a) * rx, math.sin(a) * ry, 0))
        up = V((0, 0, 0.35))
        ln = length * rng.uniform(0.8, 1.2)
        tip = p + dxy * out * ln + V((0, 0, -ln))
        groups.append([
            p + t * w + up, p - t * w + up, p + t * w - dxy * thick + up, p - t * w - dxy * thick + up,
            tip + t * w * 0.22, tip - t * w * 0.22, tip - dxy * thick * 0.6,
        ])
    return groups


def build_croc():
    GREEN, GREEN2, DARK, LIME, TOOTH = (44, 142, 52), (38, 128, 48), (26, 100, 40), (204, 232, 44), (245, 245, 240)
    GLOW, FRAME, MOUTH = (255, 125, 0), (22, 84, 34), (60, 20, 20)
    b = Boss("BigCroc")

    body = b.piece("Body", (0, -0.5, 2.2), "Root", sym=True)
    body.loft([sring(-4.7, 3.5, 1.25, 2.0, 3.2), sring(-3.3, 3.45, 1.2, 2.25, 3.2), sring(-1.0, 3.42, 1.15, 2.35, 3.2), sring(1.2, 3.3, 1.2, 2.25, 3.2), sring(3.4, 3.1, 1.3, 1.9, 3.2)], GREEN)
    body.paint(lambda p, n: p.z < 1.95, LIME)
    for i, y in enumerate((-3.5, -2.15, -0.8, 0.55, 1.9)):
        body.detail(fin(y, 3.2, 0.6, 1.2, 1.05 - abs(i - 2) * 0.08), DARK)
        if i < 4:
            body.detail([V((p.x + 1.3, p.y + 0.1, p.z - 0.28)) for p in fin(y, 3.2, 0.42, 0.95, 0.6)], DARK, both=True)

    head = b.piece("Head", (0, -4.4, 2.4), "Body", sym=True)
    head.loft([sring(-3.5, 3.5, 1.75, 2.0, 3.3), sring(-4.4, 3.55, 1.75, 2.05, 3.4), sring(-5.25, 3.7, 1.75, 2.05, 3.4), sring(-5.95, 3.0, 1.75, 1.85, 3.4), sring(-7.4, 2.9, 1.75, 1.6, 3.4), sring(-8.5, 2.75, 1.8, 1.4, 3.4)], GREEN)
    head.ball((1.0, -5.0, 3.6), (0.95, 0.9, 0.6), GREEN, both=True, e=2.8)
    head.ball((0.55, -8.05, 2.85), (0.36, 0.42, 0.3), GREEN, both=True)
    for side in (1, -1):
        head.solid(brow_pts(1.0, -5.1, -6.2, 3.38, 0.9, side), DARK)
    head.detail(cbox((1.0, -5.7, 3.4), (1.25, 0.34, 1.0), 0.15), DARK, both=True)
    head.detail(fin(-4.55, 3.4, 0.5, 1.0, 0.75), DARK)
    head.detail(cbox((0, -6.3, 1.76), (2.9, 4.0, 0.1), 0.03), MOUTH)
    b.eyes("Head", 2.8, 1.0, -5.87, 3.4)

    jaw = b.piece("Jaw", (0, -4.4, 1.7), "Head", sym=True)
    jaw.loft([sring(-3.7, 1.72, 1.0, 2.2, 3.2), sring(-4.4, 1.72, 0.85, 2.25, 3.2), sring(-6.0, 1.72, 0.9, 2.1, 3.2), sring(-7.6, 1.72, 1.0, 1.9, 3.2), sring(-8.85, 1.75, 1.15, 1.55, 3.2)], LIME)
    lip = [(2.2, -4.5, 1.6), (2.1, -6.2, 1.62), (1.9, -7.8, 1.65), (1.3, -8.9, 1.68), (0.0, -9.2, 1.7)]
    jaw.tube(lip + [(-x, y, z) for x, y, z in reversed(lip[:-1])], [0.3] * 9, LIME, n=6)
    for x, y in ((2.1, -5.3), (2.0, -6.7), (1.75, -8.0), (0.7, -9.0)):
        jaw.detail(cone((x, y, 1.7), (x, y - 0.03, 2.5), 0.42, n=4, rot=math.pi / 4), TOOTH, both=True)

    for name, y in (("Front", -2.6), ("Back", 1.7)):
        leg = "Left" + name
        up = b.piece(leg + "Upper", (2.0, y, 2.5), "Body")
        up.ball((2.6, y, 1.9), (0.9, 1.05, 1.08), GREEN, e=3.2)
        up.detail(plate((3.5, y, 1.95), (1, 0, 0), 0.8, 0.02, n=5, rot=-math.pi / 2, inner=0.95, sink=0.5, squash=1.2), FRAME)
        lo = b.piece(leg + "Lower", (2.7, y - 0.1, 1.2), leg + "Upper")
        lo.ball((2.72, y - 0.2, 0.92), (0.75, 0.8, 0.58), GREEN2, e=3.2)
        ft = b.piece(leg + "Foot", (2.75, y - 0.35, 0.6), leg + "Lower")
        ft.ball((2.75, y - 0.6, 0.38), (0.92, 0.9, 0.38), GREEN, e=3.6)
        for dx in (-0.62, 0.0, 0.62):
            ft.ball((2.75 + dx * 1.05, y - 1.7, 0.3), (0.26, 0.7, 0.3), GREEN2, e=3.0)
        b.spot(leg + "Upper", (3.5, y, 1.95), (1, 0, 0), 0.62, GLOW, n=5, rot=-math.pi / 2, squash=1.2)

    y0, y1 = 3.0, 9.6

    def at(t):
        return y0 + (y1 - y0) * t, 1.9 + (0.2 - 1.9) * t, 3.1 + (1.5 - 3.1) * t, 1.25 + (1.15 - 1.25) * t

    parent = "Body"
    for i in range(4):
        ya, _, ta, ba = at(i / 4)
        t = b.piece(f"Tail{i + 1}", (0, ya, (ta + ba) / 2), parent, sym=True)
        for k in range(2):
            a = at((i * 2 + k) / 8)
            c = at((i * 2 + k + 1) / 8)
            t.loft([sring(a[0] - 0.12, a[2], a[3], a[1], 3.2), sring(c[0] + 0.05, c[2] - (a[2] - c[2]) * 0.35, c[3], max(0.12, c[1] * 0.86), 3.2)], GREEN if (i * 2 + k) % 2 == 0 else GREEN2)
            ym = (a[0] + c[0]) / 2
            t.detail(fin(ym, (a[2] + c[2]) / 2 - 0.2, max(0.16, a[1] * 0.4), 0.7, 0.85 - (i * 2 + k) * 0.07), DARK)
        t.paint(lambda p, n: p.z < 1.2 + (1.75 - (p.y - y0) / (y1 - y0) * 1.45) * 0.38, LIME)
        parent = f"Tail{i + 1}"
    return b.finish()


def build_yeti():
    FUR, NAVY, BROW = (168, 205, 242), (42, 62, 120), (26, 40, 88)
    HORN, ICE, GLOW, FRAME, MOUTH = (242, 238, 228), (70, 175, 255), (40, 170, 255), (30, 44, 96), (14, 20, 46)
    b = Boss("FrostYeti")

    def fringe(piece, groups):
        for g in groups:
            piece.solid(g, FUR)

    lt = b.piece("LowerTorso", (0, 0, 3.6), "Root", sym=True)
    lt.ball((0, 0.1, 3.8), (2.4, 1.8, 1.2), FUR, e=2.6)
    back = ((1.7, 1.55, 4.45), (1.95, 1.75, 3.8), (1.2, 1.7, 3.0))
    lt.solid([V((x * s, y + dy, z)) for s in (-1, 1) for x, y, z in back for dy in (0.0, 0.42)], NAVY)

    ut = b.piece("UpperTorso", (0, 0, 4.5), "LowerTorso", sym=True)
    ut.ball((0, -0.2, 6.3), (3.0, 2.2, 2.1), FUR, e=2.6)
    ut.ball((0, 0.0, 4.9), (2.5, 1.9, 1.3), FUR, e=2.6)
    ut.ball((0, 1.3, 7.4), (2.9, 2.0, 1.7), FUR, e=2.6)
    ut.ball((0, -1.3, 7.1), (2.0, 1.1, 0.9), FUR, e=2.6)
    ut.ball((0, 2.1, 6.7), (2.3, 0.8, 1.0), FUR, e=2.8)
    ut.ball((1.5, 2.0, 5.6), (1.35, 0.7, 0.9), FUR, both=True, e=2.8)
    fringe(ut, scallops((0, 2.1, 6.0), 2.2, 0.8, 3, 0.7, 0.8, a0=0.5, a1=math.pi - 0.5, seed=11))
    fringe(ut, scallops((0, 1.3, 7.2), 2.8, 2.0, 4, 0.7, 0.8, a0=0.4, a1=math.pi - 0.4, seed=12))
    front = ((2.3, -2.3, 7.05), (2.45, -2.6, 6.2), (1.3, -2.7, 4.5), (0.45, -2.3, 3.6))
    ut.solid([V((x * s, y + dy, z)) for s in (-1, 1) for x, y, z in front for dy in (0.0, 0.9)], NAVY)
    fringe(ut, scallops((0, 1.3, 6.3), 2.8, 1.95, 5, 0.75, 0.9, a0=0.3, a1=math.pi - 0.3, seed=1))
    fringe(ut, scallops((0, 0.0, 5.3), 2.95, 2.15, 4, 0.7, 0.8, a0=0.5, a1=math.pi - 0.5, seed=2))
    fringe(ut, scallops((0, -0.2, 5.4), 2.9, 2.15, 2, 0.6, 0.8, a0=-0.75, a1=0.2, seed=3))
    fringe(ut, scallops((0, -0.2, 5.4), 2.9, 2.15, 2, 0.6, 0.8, a0=math.pi - 0.2, a1=math.pi + 0.75, seed=4))
    for i, (p0, p1, r) in enumerate((((2.6, 1.0, 8.3), (3.05, 1.35, 10.4), 0.7), ((3.5, 0.8, 7.8), (4.6, 1.15, 9.5), 0.6), ((1.9, 1.7, 8.3), (2.0, 2.3, 9.9), 0.52))):
        ut.detail(crystal(p0, p1, r, rot=i), ICE, both=True)
    ut.detail(plate((2.05, -1.45, 4.7), (0.6, -1, 0), 0.95, 0.02, inner=0.95, sink=0.6), FRAME, both=True)

    hd = b.piece("Head", (0, -1.3, 7.0), "UpperTorso", sym=True)
    hd.ball((0, -1.9, 8.2), (2.5, 2.0, 2.0), FUR, e=2.6)
    hd.ball((0, -3.3, 8.0), (1.85, 0.9, 1.45), NAVY, e=3.2)
    hd.ball((0, -3.45, 9.5), (2.15, 0.75, 0.5), FUR, e=3.0)
    hd.ball((2.1, -3.25, 7.95), (0.7, 0.95, 1.35), FUR, both=True, e=3.0)
    fringe(hd, scallops((0, -3.5, 9.3), 1.5, 0.75, 4, 0.45, 0.55, a0=math.pi + 0.5, a1=math.tau - 0.5, thick=0.3, seed=5))
    fringe(hd, scallops((0, -2.2, 7.3), 2.45, 1.7, 2, 0.6, 0.8, a0=-0.9, a1=0.3, seed=6))
    fringe(hd, scallops((0, -2.2, 7.3), 2.45, 1.7, 2, 0.6, 0.8, a0=math.pi - 0.3, a1=math.pi + 0.9, seed=7))
    hd.cut(cbox((0, -4.2, 7.25), (2.1, 1.0, 0.6), 0.12), MOUTH)
    for side in (1, -1):
        hd.detail(brow_pts(0.85, -4.1, -4.6, 8.4, 0.86, side), BROW)
        pts = [(side * x, y, z) for x, y, z in ((1.9, -1.9, 9.3), (2.6, -1.9, 9.6), (2.95, -1.95, 10.2), (2.8, -2.05, 10.95))]
        for g in chain(pts, (0.72, 0.64, 0.46, 0.0)):
            hd.detail(g, HORN)
    b.eyes("Head", 2.9, 0.85, -4.2, 8.4)

    jw = b.piece("Jaw", (0, -2.6, 6.95), "Head", sym=True)
    jw.ball((0, -3.3, 6.65), (1.8, 0.9, 0.5), NAVY, e=3.2)
    jw.detail(cone((1.25, -4.0, 6.75), (1.3, -4.22, 7.75), 0.4, n=4), HORN, both=True)

    ua = b.piece("LeftUpperArm", (3.0, 0.0, 7.3), "UpperTorso")
    ua.ball((3.85, -0.1, 7.2), (1.8, 1.8, 1.6), FUR, e=2.8)
    ua.ball((4.5, -0.2, 6.0), (1.12, 1.22, 1.1), FUR, e=2.8)
    fringe(ua, scallops((3.85, -0.1, 6.3), 1.7, 1.7, 5, 0.7, 0.85, a0=-1.9, a1=1.9, seed=8))
    la = b.piece("LeftLowerArm", (4.7, -0.3, 5.1), "LeftUpperArm")
    la.ball((4.75, -0.7, 4.3), (1.5, 1.55, 1.3), FUR, e=2.8)
    fringe(la, scallops((4.75, -0.8, 3.55), 1.4, 1.45, 7, 0.62, 0.8, seed=9))
    ha = b.piece("LeftHand", (4.6, -1.1, 3.3), "LeftLowerArm")
    ha.ball((4.45, -1.4, 2.3), (1.5, 1.6, 1.25), NAVY, e=3.0)
    ha.ball((4.35, -2.4, 2.0), (1.25, 0.7, 0.85), NAVY, e=3.0)

    ul = b.piece("LeftUpperLeg", (1.6, 0.0, 3.7), "LowerTorso")
    ul.ball((1.65, 0.0, 3.1), (1.3, 1.35, 1.1), FUR, e=2.8)
    ll = b.piece("LeftLowerLeg", (1.7, -0.1, 2.5), "LeftUpperLeg")
    ll.ball((1.7, -0.05, 1.95), (1.3, 1.35, 1.0), FUR, e=2.8)
    fringe(ll, scallops((1.7, -0.05, 1.5), 1.2, 1.25, 6, 0.6, 0.6, a0=0.3, a1=math.tau - 0.3 - math.pi * 0.0, seed=10))
    ll.detail(plate((1.7, -1.4, 2.15), (0, -1, 0.1), 0.82, 0.02, inner=0.95, sink=0.5), FRAME)
    ft = b.piece("LeftFoot", (1.7, 0.0, 1.2), "LeftLowerLeg")
    ft.ball((1.7, -0.35, 0.65), (1.38, 1.65, 0.65), NAVY, e=3.4)
    for dx in (-0.8, 0.0, 0.8):
        ft.ball((1.7 + dx * 1.1, -2.15, 0.45), (0.4, 0.85, 0.45), NAVY, e=3.0)

    b.spot("UpperTorso", (2.05, -1.45, 4.7), (0.6, -1, 0), 0.72, GLOW)
    b.spot("UpperTorso", (-2.05, -1.45, 4.7), (-0.6, -1, 0), 0.72, GLOW)
    b.spot("LeftLowerLeg", (1.7, -1.4, 2.15), (0, -1, 0.1), 0.62, GLOW)
    return b.finish()


def build_crab():
    RED, RED2, DARK = (238, 72, 26), (205, 56, 20), (70, 22, 12)
    ROCK, ROCK2, MOSS, GLOW = (142, 142, 142), (104, 104, 104), (98, 165, 48), (40, 220, 255)
    b = Boss("BoulderCrab")

    body = b.piece("Body", (0, 0, 1.9), "Root", sym=True)
    body.ball((0, 0.2, 1.9), (3.3, 2.6, 1.0), RED, e=2.8)
    body.ball((0, -2.0, 1.8), (1.9, 0.8, 0.85), RED2, e=2.8)
    body.tube([(0.85, -2.4, 2.1), (0.85, -2.75, 2.8)], [0.3, 0.3], RED2, n=6, both=True)
    body.detail(cbox((0, -2.78, 1.5), (1.4, 0.12, 0.2), 0.04), DARK)

    shell = b.piece("Shell", (0, 0.3, 2.6), "Body", density=1.8)
    shell.zmin = 2.55
    shell.ball((0, 0.4, 3.7), (4.1, 3.6, 2.9), ROCK, sub=3, e=2.1)
    shell.ball((-1.7, 1.1, 3.9), (2.6, 2.5, 2.0), ROCK, sub=3, e=2.2)
    shell.ball((1.8, -0.3, 3.8), (2.5, 2.4, 2.0), ROCK, sub=3, e=2.2)
    shell.cut(cbox((0, -3.5, 3.0), (3.5, 1.6, 1.9), 0.35), ROCK2)
    shell.plates(((0.5, -0.45, 0.75), (-0.55, -0.1, 0.8), (0.1, 0.75, 0.65), (-0.85, 0.5, 0.2), (0.9, 0.4, 0.25)), (0, 0.4, 3.7), 1.15, MOSS)
    for side in (1, -1):
        shell.detail(brow_pts(0.9, -2.85, -3.65, 3.45, 1.0, side), ROCK2)
    b.eyes("Shell", 3.1, 0.9, -2.72, 3.25)

    c1 = b.piece("LeftClaw1", (2.3, -1.6, 1.8), "Body")
    c1.tube([(2.1, -1.4, 1.8), (3.3, -2.45, 1.9)], [0.95, 0.9], RED2, n=6)
    c2 = b.piece("LeftClaw2", (3.3, -2.45, 1.9), "LeftClaw1")
    c2.tube([(3.25, -2.3, 1.9), (3.6, -3.6, 2.0)], [0.92, 1.05], RED, n=6)
    c3 = b.piece("LeftClaw3", (3.6, -3.6, 2.0), "LeftClaw2")
    c3.ball((3.6, -4.7, 2.05), (1.7, 1.55, 1.5), RED, e=2.8)
    c3.tube([(3.4, -5.7, 2.6), (2.7, -6.8, 2.55), (1.9, -7.35, 2.1), (1.55, -7.3, 1.35)], [1.1, 0.92, 0.62, 0.15], RED, n=6, squash=0.8)
    pn = b.piece("LeftPincer", (3.5, -5.5, 1.3), "LeftClaw3")
    pn.tube([(3.5, -5.4, 1.2), (2.8, -6.5, 0.95), (2.0, -6.95, 0.95)], [0.82, 0.62, 0.15], RED2, n=6, squash=0.8)

    for i, (y, yaw) in enumerate(((-0.6, -0.35), (0.8, 0.3), (2.0, 0.95)), start=1):
        d = V((math.cos(yaw), math.sin(yaw), 0))
        root = V((3.0, y, 2.3))
        k1 = root + d * 1.0 + V((0, 0, -1.05))
        k2 = k1 + d * 0.3 + V((0, 0, -0.55))
        tip = V((k2.x + d.x * 0.25, k2.y + d.y * 0.25, 0.0))
        l1 = b.piece(f"LeftLeg{i}_1", root, "Body")
        l1.tube([root - d * 0.5 + V((0, 0, 0.1)), k1], [0.9, 0.85], RED, n=6)
        l2 = b.piece(f"LeftLeg{i}_2", k1, f"LeftLeg{i}_1")
        l2.tube([k1 + V((0, 0, 0.2)), k2], [0.85, 0.72], RED2, n=6)
        l3 = b.piece(f"LeftLeg{i}_3", k2, f"LeftLeg{i}_2")
        l3.tube([k2 + V((0, 0, 0.25)), (k2 + tip) / 2, tip], [0.72, 0.5, 0.16], RED, n=6)
        if i >= 2:
            p = root + (k1 - root) * 0.5
            n = (d * 1.05 + V((0, 0, 0.95))).normalized()
            c = p + n * 0.82
            l1.detail(plate(c, n, 0.74, 0.02, n=8, inner=0.95, sink=0.45), RED2)
            b.spot(f"LeftLeg{i}_1", c, n, 0.56, GLOW, n=8)
    return b.finish()


builders = {"FrostYeti": build_yeti, "BoulderCrab": build_crab, "BigCroc": build_croc}
tri_report = {name: fn() for name, fn in builders.items() if ONLY is None or name in ONLY}
