import math
import random

import bmesh
import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

STUD = 0.5
COLLECTION = "RockBuilder"


def _collection():
    col = bpy.data.collections.get(COLLECTION)
    if col is None:
        col = bpy.data.collections.new(COLLECTION)
        bpy.context.scene.collection.children.link(col)
    return col


def _remove_object(name):
    obj = bpy.data.objects.get(name)
    if obj is not None:
        mesh = obj.data if obj.type == "MESH" else None
        bpy.data.objects.remove(obj, do_unlink=True)
        if mesh is not None and mesh.users == 0:
            bpy.data.meshes.remove(mesh)


def footprint(w, d, clips):
    hx, hy = w / 2, d / 2
    corners = [(-hx, -hy), (hx, -hy), (hx, hy), (-hx, hy)]
    pts = []
    for i, (x, y) in enumerate(corners):
        c = clips[i] if clips else 0
        if c <= 0:
            pts.append((x, y))
            continue
        for nb in (corners[i - 1], corners[(i + 1) % 4]):
            dv = Vector((nb[0] - x, nb[1] - y)).normalized() * c
            pts.append((x + dv.x, y + dv.y))
    return pts


def block_points(block, height_scale):
    rot = Matrix.Rotation(math.radians(block.get("rot", 0)), 3, "Z")
    pts = footprint(block["w"], block["d"], block.get("clips"))
    z0 = block.get("z0", 0) * height_scale
    h = block["h"] * height_scale
    taper = block.get("taper", 0.9)
    center = Vector((block["x"], block["y"], 0))
    bot = [rot @ Vector((x, y, z0)) + center for x, y in pts]
    top = [rot @ Vector((x * taper, y * taper, z0 + h)) + center for x, y in pts]
    return bot, top


def prism_object(name, bot, top):
    _remove_object(name)
    bm = bmesh.new()
    n = len(bot)
    bv = [bm.verts.new(p) for p in bot]
    tv = [bm.verts.new(p) for p in top]
    bm.faces.new(list(reversed(bv)))
    bm.faces.new(tv)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((bv[i], bv[j], tv[j], tv[i]))
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(name, me)
    _collection().objects.link(obj)
    return obj


def boolean(target, other, operation):
    mod = target.modifiers.new("Bool", "BOOLEAN")
    mod.operation = operation
    mod.solver = "EXACT"
    mod.object = other
    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = target.evaluated_get(depsgraph)
    new_mesh = bpy.data.meshes.new_from_object(evaluated)
    target.modifiers.remove(mod)
    old = target.data
    target.data = new_mesh
    if old.users == 0:
        bpy.data.meshes.remove(old)


def clean_mesh(me, merge):
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
    bmesh.ops.dissolve_limit(bm, angle_limit=math.radians(0.5), verts=bm.verts, edges=bm.edges)
    bmesh.ops.dissolve_degenerate(bm, dist=1e-4, edges=bm.edges)
    if merge > 0:
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=merge)
        bmesh.ops.dissolve_degenerate(bm, dist=1e-4, edges=bm.edges)
        bmesh.ops.dissolve_limit(bm, angle_limit=math.radians(1.0), verts=bm.verts, edges=bm.edges)
    bmesh.ops.triangulate(bm, faces=bm.faces, quad_method="BEAUTY", ngon_method="BEAUTY")
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()


def stats(me):
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.faces.ensure_lookup_table()
    tree = BVHTree.FromBMesh(bm)
    self_hits = sum(
        1
        for a, b in tree.overlap(tree)
        if a < b and not set(bm.faces[a].verts) & set(bm.faces[b].verts)
    )
    angles = [math.degrees(min(l.calc_angle() for l in f.loops)) for f in bm.faces]
    def is_hidden_sliver(face):
        longest = max(face.edges, key=lambda e: e.calc_length())
        others = [o for o in longest.link_faces if o is not face]
        return bool(others) and others[0].normal.dot(face.normal) > 0.9999

    visible_slivers = sum(
        1 for f, a in zip(bm.faces, angles) if a < 4 and f.normal.z > -0.99 and not is_hidden_sliver(f)
    )
    islands = 0
    seen = set()
    for f in bm.faces:
        if f.index in seen:
            continue
        islands += 1
        stack = [f]
        while stack:
            cur = stack.pop()
            if cur.index in seen:
                continue
            seen.add(cur.index)
            for e in cur.edges:
                for nf in e.link_faces:
                    if nf.index not in seen:
                        stack.append(nf)
    xs = [v.co.x for v in bm.verts]
    ys = [v.co.y for v in bm.verts]
    zs = [v.co.z for v in bm.verts]
    result = {
        "tris": len(bm.faces),
        "nonmanifold": sum(not e.is_manifold for e in bm.edges),
        "self_intersections": self_hits,
        "min_angle": round(min(angles), 2) if angles else 0,
        "visible_slivers": visible_slivers,
        "islands": islands,
        "volume": round(bm.calc_volume(), 4),
        "min_z": round(min(zs), 5),
        "dims": [round(max(xs) - min(xs), 3), round(max(ys) - min(ys), 3), round(max(zs) - min(zs), 3)],
        "dims_studs": [
            round((max(xs) - min(xs)) / STUD, 2),
            round((max(zs) - min(zs)) / STUD, 2),
            round((max(ys) - min(ys)) / STUD, 2),
        ],
    }
    bm.free()
    return result


def is_clean(report):
    return report["nonmanifold"] == 0 and report["self_intersections"] == 0 and report["islands"] == 1


def _block_planes(blocks, height_scale, offset):
    tops = []
    sides = []
    for block in blocks:
        bot, top = block_points(block, height_scale)
        bot = [p - offset for p in bot]
        top = [p - offset for p in top]
        center = Vector((block["x"] - offset.x, block["y"] - offset.y))
        tops.append((top[0].z, center, block.get("rot", 0)))
        z0 = bot[0].z
        n = len(bot)
        for i in range(n):
            j = (i + 1) % n
            normal = (bot[j] - bot[i]).cross(top[j] - bot[i]).normalized()
            sides.append((normal, bot[i], (bot[i] + bot[j]) / 2, z0))
    return tops, sides


def stud_uvs(me, blocks, height_scale, offset, tile_studs=1):
    tops, sides = _block_planes(blocks, height_scale, offset)
    bm = bmesh.new()
    bm.from_mesh(me)
    uv = bm.loops.layers.uv.active or bm.loops.layers.uv.new("UVMap")
    up_axis = Vector((0, 0, 1))
    scale = STUD * tile_studs

    def assign(face, fn):
        for loop in face.loops:
            u, v = fn(loop.vert.co)
            loop[uv].uv = (u / tile_studs, v / tile_studs)

    for face in bm.faces:
        n = face.normal
        c = face.calc_center_median()
        if n.z > 0.99:
            best = min(tops, key=lambda t: abs(t[0] - c.z))
            rot = Matrix.Rotation(math.radians(-best[2]), 2)
            center = best[1]
            assign(face, lambda p, rot=rot, center=center: tuple(
                x / STUD + 0.5 for x in rot @ (Vector((p.x, p.y)) - center)
            ))
            continue
        if n.z < -0.99:
            assign(face, lambda p: (p.x / STUD, p.y / STUD))
            continue
        right = (-n).cross(up_axis).normalized()
        up = n.cross(right).normalized()
        match = None
        for normal, point, mid, z0 in sides:
            if n.dot(normal) < 0.995:
                continue
            dist = abs((c - point).dot(normal))
            if dist < 0.05 and (match is None or dist < match[0]):
                match = (dist, mid, z0)
        if match:
            _, mid, z0 = match
            assign(face, lambda p, mid=mid, z0=z0, right=right, up=up: (
                (p - mid).dot(right) / STUD + 0.5,
                (p.z - z0) / max(up.z, 0.2) / STUD,
            ))
        else:
            assign(face, lambda p, right=right, up=up: (p.dot(right) / STUD, p.z / max(up.z, 0.2) / STUD))
    bm.to_mesh(me)
    bm.free()


def plain_material(name, rgb):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    for node in list(nodes):
        if node.type == "TEX_IMAGE":
            nodes.remove(node)
    bsdf = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")

    def to_linear(c):
        c = c / 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    bsdf.inputs["Base Color"].default_value = (*[to_linear(c) for c in rgb], 1)
    bsdf.inputs["Roughness"].default_value = 0.9
    mat.diffuse_color = (*[to_linear(c) for c in rgb], 1)
    return mat


def _finish(obj, material):
    for poly in obj.data.polygons:
        poly.use_smooth = False
    obj.data.materials.clear()
    obj.data.materials.append(material)


def build_rock(name, blocks, height_scale=1.0, color=(120, 120, 120), merge_candidates=(0.075, 0.06, 0.09, 0.05, 0.0)):
    parts = []
    for i, block in enumerate(blocks):
        bot, top = block_points(block, height_scale)
        parts.append(prism_object(f"_{name}_blk{i}", bot, top))
    base = parts[0]
    for other in parts[1:]:
        boolean(base, other, "UNION")
    for other in parts[1:]:
        _remove_object(other.name)
    raw = base.data.copy()

    bm = bmesh.new()
    bm.from_mesh(raw)
    xs = [v.co.x for v in bm.verts]
    ys = [v.co.y for v in bm.verts]
    offset = Vector(((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, min(v.co.z for v in bm.verts)))
    for v in bm.verts:
        v.co -= offset
    bm.to_mesh(raw)
    bm.free()

    attempts = []
    chosen = None
    for merge in merge_candidates:
        trial = raw.copy()
        clean_mesh(trial, merge)
        report = stats(trial)
        report["merge"] = merge
        attempts.append(report)
        if is_clean(report) and (chosen is None or report["visible_slivers"] < chosen[1]["visible_slivers"]):
            if chosen is not None:
                bpy.data.meshes.remove(chosen[0])
            chosen = (trial, report)
        else:
            bpy.data.meshes.remove(trial)
    bpy.data.meshes.remove(raw)
    if chosen is None:
        return None, {"error": "no clean merge candidate", "attempts": attempts}

    _remove_object(name)
    old = base.data
    base.data = chosen[0]
    bpy.data.meshes.remove(old)
    base.name = name
    base.data.name = name
    base.location = (0, 0, 0)
    stud_uvs(base.data, blocks, height_scale, offset)
    _finish(base, plain_material(f"{name}_Mat", color))
    report = stats(base.data)
    report["merge"] = chosen[1]["merge"]
    report["offset"] = [round(offset.x, 4), round(offset.y, 4)]
    return base, report


def stepped_cutter(name, steps, angle=0.0, extent=100.0):
    outline = [(-extent, -extent)]
    for i, (y_from, y_to, x_boundary) in enumerate(steps):
        y0 = -extent if i == 0 else y_from
        y1 = extent if i == len(steps) - 1 else y_to
        outline.append((x_boundary, y0))
        outline.append((x_boundary, y1))
    outline.append((-extent, extent))
    rot = Matrix.Rotation(math.radians(angle), 3, "Z")
    bot = [rot @ Vector((x, y, -extent)) for x, y in outline]
    top = [rot @ Vector((x, y, extent)) for x, y in outline]
    return prism_object(name, bot, top)


def _sample_volume(blocks, height_scale, offset, resolution=0.15):
    prisms = []
    for block in blocks:
        bot, top = block_points(block, height_scale)
        center = Vector((block["x"], block["y"]))
        prisms.append(
            (
                [Vector((p.x, p.y)) for p in bot],
                center,
                bot[0].z,
                top[0].z,
                block.get("taper", 0.9),
            )
        )
    xs = [p.x for poly, *_ in prisms for p in poly]
    ys = [p.y for poly, *_ in prisms for p in poly]
    z_max = max(pr[3] for pr in prisms)
    samples = []

    def inside(poly, point):
        sign = 0
        n = len(poly)
        for i in range(n):
            a, b = poly[i], poly[(i + 1) % n]
            cross = (b - a).cross(point - a)
            if abs(cross) < 1e-9:
                continue
            s = 1 if cross > 0 else -1
            if sign == 0:
                sign = s
            elif s != sign:
                return False
        return True

    x = min(xs) + resolution / 2
    while x < max(xs):
        y = min(ys) + resolution / 2
        while y < max(ys):
            z = resolution / 2
            while z < z_max:
                point = Vector((x, y))
                for poly, center, z0, z1, taper in prisms:
                    if z0 <= z <= z1:
                        t = 1 + (taper - 1) * (z - z0) / (z1 - z0)
                        scaled = [center + (p - center) * t for p in poly]
                        if inside(scaled, point):
                            samples.append(Vector((x - offset.x, y - offset.y)))
                            break
                z += resolution
            y += resolution
        x += resolution
    return samples


def _cut_segments(steps):
    segments = []
    for i, (y_from, y_to, x_boundary) in enumerate(steps):
        y0 = -1e9 if y_from is None else y_from
        y1 = 1e9 if y_to is None else y_to
        segments.append(("vertical", x_boundary, y0, y1))
        if i > 0:
            prev = steps[i - 1][2]
            segments.append(("horizontal", y_from, min(prev, x_boundary), max(prev, x_boundary)))
    return segments


def _clearance(edges, segments, parallel_sin=0.42):
    best = 1e9
    for a, b in edges:
        d = b - a
        length = d.length
        if length < 1e-6:
            continue
        d = d / length
        for kind, value, lo, hi in segments:
            along = abs(d.y) if kind == "vertical" else abs(d.x)
            if along < math.sqrt(1 - parallel_sin**2):
                continue
            if kind == "vertical":
                pa, pb = (a.y, a.x), (b.y, b.x)
            else:
                pa, pb = (a.x, a.y), (b.x, b.y)
            s0, s1 = sorted((pa[0], pb[0]))
            o0, o1 = max(s0, lo), min(s1, hi)
            if o1 <= o0:
                continue

            def offset_at(s):
                if abs(pb[0] - pa[0]) < 1e-9:
                    return pa[1]
                t = (s - pa[0]) / (pb[0] - pa[0])
                return pa[1] + (pb[1] - pa[1]) * t

            v0, v1 = offset_at(o0) - value, offset_at(o1) - value
            dist = 0 if v0 * v1 <= 0 else min(abs(v0), abs(v1))
            best = min(best, dist)
    return best


def _plan_edges(blocks, height_scale, offset):
    edges = []
    for block in blocks:
        bot, top = block_points(block, height_scale)
        for ring in (bot, top):
            pts = [Vector((p.x - offset.x, p.y - offset.y)) for p in ring]
            edges += [(pts[i], pts[(i + 1) % len(pts)]) for i in range(len(pts))]
    return edges


def block_clearances(blocks, height_scale, offset, x=0.0):
    result = []
    for i, block in enumerate(blocks):
        clear = _clearance(_plan_edges([block], height_scale, offset), _cut_segments([(None, None, x)]))
        result.append((i, round(clear, 3)))
    return result


def find_straight_split(
    blocks,
    height_scale,
    offset,
    balance=(0.44, 0.56),
    max_angle=0,
    angle_step=3,
    max_offset=0.2,
    min_clearance=0.25,
):
    samples = _sample_volume(blocks, height_scale, offset)
    plan_edges = _plan_edges(blocks, height_scale, offset)
    candidates = []
    for angle in range(-max_angle, max_angle + 1, angle_step):
        rot = Matrix.Rotation(math.radians(-angle), 2)
        r_xs = sorted((rot @ p).x for p in samples)
        r_edges = [(rot @ a, rot @ b) for a, b in plan_edges]
        steps_count = int(round(max_offset / 0.02))
        for i in range(-steps_count, steps_count + 1):
            boundary = i * 0.02
            left = sum(1 for x in r_xs if x < boundary)
            share = left / len(r_xs)
            if not balance[0] <= share <= balance[1]:
                continue
            steps = [(None, None, boundary)]
            clear = _clearance(r_edges, _cut_segments(steps))
            candidates.append((clear >= min_clearance, clear, -abs(boundary), -abs(angle), steps, angle, share))
    candidates.sort(key=lambda c: (c[0], c[2] if c[0] else c[1], c[1], c[3]), reverse=True)
    return [
        {"steps": c[4], "angle": c[5], "clearance": round(c[1], 3), "share": round(c[6], 3), "clean": c[0]}
        for c in candidates[:5]
    ]


def find_split_steps(blocks, height_scale, offset, balance=(0.42, 0.58), min_step=0.25):
    samples = _sample_volume(blocks, height_scale, offset)
    plan_edges = []
    for block in blocks:
        bot, top = block_points(block, height_scale)
        for ring in (bot, top):
            pts = [Vector((p.x - offset.x, p.y - offset.y)) for p in ring]
            plan_edges += [(pts[i], pts[(i + 1) % len(pts)]) for i in range(len(pts))]
    xs = [p.x for p in samples]
    ys = [p.y for p in samples]
    width = max(xs) - min(xs)
    depth = max(ys) - min(ys)
    y_mid = (max(ys) + min(ys)) / 2
    candidates = []
    fractions = (-0.16, -0.08, 0.0, 0.08, 0.16)
    for angle in (-6, 0, 6):
        rot = Matrix.Rotation(math.radians(-angle), 2)
        r_samples = [rot @ p for p in samples]
        r_edges = [(rot @ a, rot @ b) for a, b in plan_edges]
        for f1 in (-0.22, -0.12):
            for f2 in (0.12, 0.22):
                y1 = y_mid + f1 * depth
                y2 = y_mid + f2 * depth
                for b0 in fractions:
                    for b1 in fractions:
                        for b2 in fractions:
                            xb = [b0 * width, b1 * width, b2 * width]
                            if abs(xb[0] - xb[1]) < min_step or abs(xb[1] - xb[2]) < min_step:
                                continue
                            steps = [(None, y1, xb[0]), (y1, y2, xb[1]), (y2, None, xb[2])]
                            left = 0
                            for p in r_samples:
                                boundary = xb[0] if p.y < y1 else xb[1] if p.y < y2 else xb[2]
                                if p.x < boundary:
                                    left += 1
                            share = left / len(r_samples)
                            if not balance[0] <= share <= balance[1]:
                                continue
                            clear = _clearance(r_edges, _cut_segments(steps))
                            candidates.append((clear, -abs(share - 0.5), steps, angle, share))
    candidates.sort(key=lambda c: (c[0], c[1]), reverse=True)
    return [
        {"steps": c[2], "angle": c[3], "clearance": round(c[0], 3), "share": round(c[4], 3)}
        for c in candidates[:5]
    ]


def split_rock(rock, steps, angle=0.0, merge=0.0):
    name = rock.name
    cutter = stepped_cutter(f"_{name}_cutter", steps, angle)
    pieces = []
    for suffix, operation in (("PieceA", "INTERSECT"), ("PieceB", "DIFFERENCE")):
        piece_name = f"{name}_{suffix}"
        _remove_object(piece_name)
        piece = bpy.data.objects.new(piece_name, rock.data.copy())
        piece.data.name = piece_name
        _collection().objects.link(piece)
        boolean(piece, cutter, operation)
        clean_mesh(piece.data, merge)
        _finish(piece, rock.data.materials[0])
        pieces.append(piece)
    _remove_object(cutter.name)
    reports = {p.name: stats(p.data) for p in pieces}
    total = sum(r["volume"] for r in reports.values())
    whole = stats(rock.data)["volume"]
    return pieces, {
        "pieces": reports,
        "volume_split": [round(r["volume"] / total, 3) for r in reports.values()],
        "volume_matches_rock": abs(total - whole) < 1e-3 * max(whole, 1),
    }


def export_fbx(objects, path, studs_per_unit=2.0):
    from mathutils import Matrix

    up = Matrix.Scale(studs_per_unit, 4)
    down = Matrix.Scale(1.0 / studs_per_unit, 4)
    for obj in objects:
        obj.data.transform(up)
        obj.location *= studs_per_unit
    try:
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.hide_set(False)
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        bpy.ops.export_scene.fbx(
            filepath=path,
            use_selection=True,
            object_types={"MESH"},
            apply_scale_options="FBX_SCALE_UNITS",
            axis_forward="-Z",
            axis_up="Y",
            mesh_smooth_type="FACE",
            path_mode="STRIP",
            bake_space_transform=True,
        )
    finally:
        for obj in objects:
            obj.data.transform(down)
            obj.location /= studs_per_unit


def setup_preview_scene():
    scene = bpy.context.scene
    view = scene.view_settings
    view.view_transform = "Standard"
    view.look = "None"
    view.exposure = 0
    view.gamma = 1
    world = scene.world
    if world and world.use_nodes:
        bg = world.node_tree.nodes.get("Background")
        if bg:
            bg.inputs[0].default_value = (1, 1, 1, 1)
            bg.inputs[1].default_value = 0.6
    if scene.camera is None:
        cam_data = bpy.data.cameras.new("RockBuilderCamera")
        cam = bpy.data.objects.new("RockBuilderCamera", cam_data)
        scene.collection.objects.link(cam)
        scene.camera = cam
    if not any(o.type == "LIGHT" for o in scene.objects):
        sun_data = bpy.data.lights.new("RockBuilderSun", "SUN")
        sun_data.energy = 2.5
        sun = bpy.data.objects.new("RockBuilderSun", sun_data)
        sun.rotation_euler = (math.radians(40), math.radians(15), math.radians(30))
        scene.collection.objects.link(sun)


def render_preview(visible, path, camera_location, target=(0, 0, 1.2)):
    scene = bpy.context.scene
    setup_preview_scene()
    hidden = []
    for obj in scene.objects:
        if obj.type == "MESH" and obj not in visible and not obj.hide_render:
            obj.hide_render = True
            hidden.append(obj)
    for obj in visible:
        obj.hide_render = False
    cam = scene.camera
    cam.location = Vector(camera_location)
    cam.rotation_euler = (Vector(target) - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 768
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    for obj in hidden:
        obj.hide_render = False


def build_boulder(
    name,
    width=6.0,
    depth=5.0,
    height=3.5,
    facets=24,
    cut_depth=(0.0, 0.18),
    min_nz=-0.25,
    center_height=0.45,
    lean=(0.0, 0.0),
    seed=1,
    color=(120, 120, 120),
):
    rng = random.Random(seed)
    a, b = width / 2, depth / 2
    c = height / (1 + center_height)
    center = Vector((0, 0, c * center_height))

    _remove_object(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * 2 * a * 1.2, v.co.y * 2 * b * 1.2, (v.co.z + 0.5) * (center.z + c) * 1.2))

    golden = math.pi * (3 - math.sqrt(5))
    planes = []
    i = 0
    while len(planes) < facets and i < facets * 4:
        t = (i + 0.5) / (facets * 1.3)
        nz = 1 - 2 * t
        i += 1
        if nz < min_nz:
            continue
        r = math.sqrt(max(0.0, 1 - nz * nz))
        ang = i * golden + rng.uniform(-0.35, 0.35)
        n = Vector((math.cos(ang) * r, math.sin(ang) * r, nz))
        n += Vector((rng.uniform(-0.12, 0.12), rng.uniform(-0.12, 0.12), rng.uniform(-0.08, 0.08)))
        n.normalize()
        support = math.sqrt((a * n.x) ** 2 + (b * n.y) ** 2 + (c * n.z) ** 2)
        d = support * (1 - rng.uniform(*cut_depth))
        shift = Vector((lean[0] * max(n.z, 0) * a, lean[1] * max(n.z, 0) * b, 0))
        planes.append((center + shift + n * d, n))

    for co, no in planes:
        res = bmesh.ops.bisect_plane(
            bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=co, plane_no=no, clear_outer=True
        )
        cut_edges = [e for e in res["geom_cut"] if isinstance(e, bmesh.types.BMEdge)]
        if cut_edges:
            bmesh.ops.edgeloop_fill(bm, edges=cut_edges)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
    bmesh.ops.dissolve_degenerate(bm, dist=1e-4, edges=bm.edges)
    bmesh.ops.dissolve_limit(bm, angle_limit=math.radians(0.5), verts=bm.verts, edges=bm.edges)
    bmesh.ops.triangulate(bm, faces=bm.faces, quad_method="BEAUTY", ngon_method="BEAUTY")
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    xs = [v.co.x for v in bm.verts]
    ys = [v.co.y for v in bm.verts]
    shift = Vector(((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, min(v.co.z for v in bm.verts)))
    for v in bm.verts:
        v.co -= shift
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(name, me)
    _collection().objects.link(obj)
    planar_stud_uvs(me)
    _finish(obj, plain_material(f"{name}_Mat", color))
    return obj, stats(me)


def planar_stud_uvs(me, tile_studs=1):
    bm = bmesh.new()
    bm.from_mesh(me)
    uv = bm.loops.layers.uv.active or bm.loops.layers.uv.new("UVMap")
    up_axis = Vector((0, 0, 1))
    for face in bm.faces:
        n = face.normal
        if abs(n.z) > 0.95:
            right = Vector((1, 0, 0))
            up = n.cross(right).normalized()
        else:
            right = up_axis.cross(n).normalized()
            up = n.cross(right).normalized()
        for loop in face.loops:
            p = loop.vert.co
            loop[uv].uv = (p.dot(right) / (STUD * tile_studs), p.dot(up) / (STUD * tile_studs))
    bm.to_mesh(me)
    bm.free()


FACE_SHADES = {"up": 1.0, "down": 0.55, "+x": 0.88, "-x": 0.78, "+y": 0.92, "-y": 0.72}


def _face_shade(n, shades):
    return (
        n.x * n.x * shades["+x" if n.x > 0 else "-x"]
        + n.y * n.y * shades["+y" if n.y > 0 else "-y"]
        + n.z * n.z * shades["up" if n.z > 0 else "down"]
    )


def edge_glow_inset(me, width):
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.dissolve_degenerate(bm, dist=1e-4, edges=bm.edges)
    bmesh.ops.dissolve_limit(bm, angle_limit=0.001, verts=bm.verts, edges=bm.edges)

    def flat(edge):
        return len(edge.link_faces) == 2 and edge.calc_face_angle(1.0) < 0.001

    regions = []
    seen = set()
    for face in bm.faces:
        if face in seen:
            continue
        region, stack = [], [face]
        seen.add(face)
        while stack:
            f = stack.pop()
            region.append(f)
            for e in f.edges:
                if flat(e):
                    for g in e.link_faces:
                        if g not in seen:
                            seen.add(g)
                            stack.append(g)
        regions.append(region)
    for region in regions:
        members = set(region)
        boundary = [e for f in region for e in f.edges if not (flat(e) and all(g in members for g in e.link_faces))]
        area = sum(f.calc_area() for f in region)
        perimeter = sum(e.calc_length() for e in set(boundary))
        thickness = min(width, 0.4 * 2 * area / perimeter) if perimeter > 0 else 0
        if thickness > 1e-4:
            bmesh.ops.inset_region(bm, faces=region, thickness=thickness, use_even_offset=True, use_boundary=True)
    outer = {v for e in bm.edges if not flat(e) for v in e.verts}
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bm.verts.index_update()
    outer_ids = {v.index for v in outer}
    bm.to_mesh(me)
    bm.free()
    return outer_ids


def face_shade_colors(me, shades=FACE_SHADES, name="FaceShade", edge_width=0.0, edge_shade=0.7):
    outer = edge_glow_inset(me, edge_width) if edge_width > 0 else set()
    old = me.color_attributes.get(name)
    if old:
        me.color_attributes.remove(old)
    attr = me.color_attributes.new(name, "BYTE_COLOR", "CORNER")
    me.color_attributes.active_color = attr
    me.color_attributes.render_color_index = me.color_attributes.active_color_index
    for poly in me.polygons:
        value = _face_shade(poly.normal, shades)
        for li in poly.loop_indices:
            v = value * (edge_shade if me.loops[li].vertex_index in outer else 1.0)
            attr.data[li].color_srgb = (v, v, v, 1.0)
    return attr


def stud_overlay_material(name, rgb, image_path):
    mat = plain_material(name, rgb)
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
    base = tuple(bsdf.inputs["Base Color"].default_value)
    img = bpy.data.images.load(image_path, check_existing=True)
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Linear"
    tex.extension = "REPEAT"
    rgb_node = nodes.new("ShaderNodeRGB")
    rgb_node.outputs[0].default_value = base
    mix = nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    links.new(tex.outputs["Alpha"], mix.inputs["Factor"])
    links.new(rgb_node.outputs[0], mix.inputs[6])
    links.new(tex.outputs["Color"], mix.inputs[7])
    links.new(mix.outputs[2], bsdf.inputs["Base Color"])
    return mat


def find_mesh_split(obj, max_offset=0.3, step=0.02, merges=(0.0, 0.05, 0.08, 0.12)):
    xs = [v.co.x for v in obj.data.vertices]
    tried = []
    n = int(round(max_offset / step))
    offsets = sorted((i * step for i in range(-n, n + 1)), key=abs)
    best = None
    for b in offsets:
        clearance = min(abs(x - b) for x in xs)
        for merge in merges:
            pieces, report = split_rock(obj, [(None, None, b)], 0, merge)
            ps = list(report["pieces"].values())
            ok = report["volume_matches_rock"] and all(
                p["nonmanifold"] == 0
                and p["self_intersections"] == 0
                and p["islands"] == 1
                and p["visible_slivers"] == 0
                and abs(p["min_z"]) < 1e-4
                for p in ps
            )
            share = report["volume_split"][0]
            entry = {"steps": [(None, None, b)], "angle": 0, "merge": merge, "clearance": round(clearance, 3), "share": share, "clean": ok}
            tried.append(entry)
            if ok and 0.44 <= share <= 0.56:
                return entry, tried
            if ok and (best is None or abs(share - 0.5) < abs(best["share"] - 0.5)):
                best = entry
    return best, tried
