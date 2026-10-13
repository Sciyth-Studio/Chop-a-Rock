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


def slab(name, cx, cy, rx, ry, z0, h, taper, sides, rng, jitter=0.12, top_shift=(0, 0)):
    bm = bmesh.new()
    off = rng.uniform(0, math.tau)
    for i in range(sides):
        a = off + i * math.tau / sides + rng.uniform(-0.2, 0.2)
        k = 1 + rng.uniform(-jitter, jitter)
        x, y = math.cos(a) * rx * k, math.sin(a) * ry * k
        bm.verts.new((cx + x, cy + y, z0))
        bm.verts.new((cx + top_shift[0] + x * taper, cy + top_shift[1] + y * taper, z0 + h))
    bmesh.ops.convex_hull(bm, input=bm.verts[:])
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(name, me)
    _collection().objects.link(obj)
    return obj


def build_layers(name, layers, seed, color, merges=(0.08, 0.06, 0.1, 0.05, 0.03, 0.12)):
    best = None
    for merge in merges:
        rng = random.Random(seed)
        objs = [slab(f"_{name}_{i}", rng=rng, **layer) for i, layer in enumerate(layers)]
        base = objs[0]
        for o in objs[1:]:
            boolean(base, o, "UNION")
            _remove_object(o.name)
        clean_mesh(base.data, merge)
        rep = stats(base.data)
        score = (not is_clean(rep), rep["visible_slivers"], rep["tris"])
        if best is None or score < best[0]:
            if best:
                _remove_object(best[1].name)
            base.name = f"_{name}_try{merge}"
            best = (score, base, merge)
        else:
            _remove_object(base.name)
    base = best[1]
    _remove_object(name)
    base.name = name
    base.data.name = name
    me = base.data
    xs = [v.co.x for v in me.vertices]
    ys = [v.co.y for v in me.vertices]
    zs = [v.co.z for v in me.vertices]
    shift = Vector(((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, min(zs)))
    for v in me.vertices:
        v.co -= shift
    planar_stud_uvs(me)
    _finish(base, plain_material(f"{name}_Mat", color))
    rep = stats(me)
    rep["merge"] = best[2]
    return base, rep


def fix_slivers(obj, max_iter=10):
    me = obj.data
    for _ in range(max_iter):
        if stats(me)["visible_slivers"] == 0:
            break
        bm = bmesh.new()
        bm.from_mesh(me)
        target = None
        for f in bm.faces:
            if math.degrees(min(l.calc_angle() for l in f.loops)) < 4 and f.normal.z > -0.99:
                target = min(f.edges, key=lambda e: e.calc_length())
                break
        if target is None:
            bm.free()
            break
        bmesh.ops.collapse(bm, edges=[target], uvs=False)
        bmesh.ops.dissolve_degenerate(bm, dist=1e-4, edges=bm.edges)
        bmesh.ops.triangulate(bm, faces=bm.faces, quad_method="BEAUTY", ngon_method="BEAUTY")
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bm.to_mesh(me)
        bm.free()
    planar_stud_uvs(me)
    return stats(me)


def hull_into(bm, pts):
    tmp = bmesh.new()
    for p in pts:
        tmp.verts.new(p)
    bmesh.ops.convex_hull(tmp, input=tmp.verts[:])
    me = bpy.data.meshes.new("_tmp")
    tmp.to_mesh(me)
    tmp.free()
    bm.from_mesh(me)
    bpy.data.meshes.remove(me)


def ring(c, rx, ry, n=6, rot=0.0):
    return [
        Vector((c[0] + math.cos(rot + i * math.tau / n) * rx, c[1] + math.sin(rot + i * math.tau / n) * ry, c[2]))
        for i in range(n)
    ]


def make_obj(name, bm, color, matrix=None, recalc=True):
    _remove_object(name)
    if matrix is not None:
        bmesh.ops.transform(bm, matrix=matrix, verts=bm.verts)
    if recalc:
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(name, me)
    _collection().objects.link(obj)
    planar_stud_uvs(me)
    _finish(obj, plain_material(f"{name}_Mat", color))
    return obj


def grass_tuft(name, pos, seed, n=9, height=1.0, width=0.26, color=(130, 200, 40), spread=0.18):
    rng = random.Random(seed)
    bm = bmesh.new()
    for i in range(n):
        yaw = i * math.tau / n + rng.uniform(-0.3, 0.3)
        tilt = rng.uniform(0.2, 0.55)
        length = height * rng.uniform(0.65, 1.1)
        base = Vector(pos) + Vector((rng.uniform(-spread, spread), rng.uniform(-spread, spread), -0.05))
        rot = Matrix.Rotation(yaw, 4, "Z") @ Matrix.Rotation(tilt, 4, "X")
        corners = [(-width / 2, -0.04, 0), (width / 2, -0.04, 0), (width / 2, 0.04, 0), (-width / 2, 0.04, 0)]
        vs = [bm.verts.new(base + rot @ Vector(p)) for p in corners]
        tip = bm.verts.new(base + rot @ Vector((0, 0, length)))
        bm.faces.new(vs[::-1])
        for k in range(4):
            bm.faces.new((vs[k], vs[(k + 1) % 4], tip))
    return make_obj(name, bm, color)


def skull(name, pos, yaw, scale=1.0, color=(245, 235, 210)):
    bm = bmesh.new()
    hull_into(bm, ring((0, 0.15, 0.0), 0.32, 0.28, 8) + ring((0, 0.18, 0.38), 0.27, 0.22, 8))
    hull_into(
        bm,
        ring((0, -0.2, 0.0), 0.2, 0.22, 6)
        + ring((0, -0.55, 0.0), 0.13, 0.09, 6)
        + ring((0, -0.5, 0.2), 0.11, 0.07, 6)
        + ring((0, -0.15, 0.3), 0.18, 0.16, 6),
    )
    for s in (-1, 1):
        a = ring((s * 0.25, 0.22, 0.3), 0.12, 0.12, 5)
        b = ring((s * 0.58, 0.2, 0.4), 0.09, 0.09, 5)
        c = ring((s * 0.75, 0.16, 0.66), 0.04, 0.04, 5)
        hull_into(bm, a + b)
        hull_into(bm, b + c)
    m = Matrix.Translation(pos) @ Matrix.Rotation(yaw, 4, "Z") @ Matrix.Scale(scale, 4)
    return make_obj(name, bm, color, m)


def _petals(bm, origin, r, cup):
    for i in range(5):
        a = i * math.tau / 5
        tip = Vector((math.cos(a) * r, math.sin(a) * r, r * cup))
        s1 = Vector((math.cos(a - 0.6) * r * 0.5, math.sin(a - 0.6) * r * 0.5, r * cup * 0.4))
        s2 = Vector((math.cos(a + 0.6) * r * 0.5, math.sin(a + 0.6) * r * 0.5, r * cup * 0.4))
        hull_into(bm, [origin @ (p + Vector((0, 0, dz))) for p in (Vector((0, 0, 0)), tip, s1, s2) for dz in (0, 0.07)])


def _flower_centre(bm, origin, r):
    hull_into(bm, [origin @ p for p in ring((0, 0, 0.03), r * 0.3, r * 0.3, 6) + ring((0, 0, 0.15), r * 0.22, r * 0.22, 6)])


def blossom(name, centre, r, tilt_x=0.0, tilt_y=0.0, petal=(255, 90, 180), middle=(255, 220, 40), cup=0.25):
    origin = Matrix.Translation(centre) @ Matrix.Rotation(tilt_y, 4, "Y") @ Matrix.Rotation(tilt_x, 4, "X")
    heads, cents = bmesh.new(), bmesh.new()
    _petals(heads, origin, r, cup)
    _flower_centre(cents, origin, r)
    return make_obj(name + "_Petals", heads, petal), make_obj(name + "_Centers", cents, middle)


def blossoms(name, spots, petal=(255, 220, 40), middle=(255, 140, 0), cup=0.25):
    heads, cents = bmesh.new(), bmesh.new()
    for centre, normal, r in spots:
        rot = Vector((0, 0, 1)).rotation_difference(Vector(normal).normalized()).to_matrix().to_4x4()
        origin = Matrix.Translation(centre) @ rot
        _petals(heads, origin, r, cup)
        _flower_centre(cents, origin, r)
    return make_obj(name + "_Petals", heads, petal), make_obj(name + "_Centers", cents, middle)


def surface_leaves(name, rock, points, size, seed, color, every=2):
    rng = random.Random(seed)
    bm = bmesh.new()
    for i in range(1, len(points) - 1, every):
        p = Vector(points[i])
        d = (Vector(points[i + 1]) - Vector(points[i - 1])).normalized()
        hit, loc, normal, _ = rock.ray_cast(p + (p - Vector((0, 0, 1))).normalized() * 3, -(p - Vector((0, 0, 1))).normalized())
        n = normal if hit else Vector((0, 0, 1))
        side = d.cross(n).normalized() * (1 if (i // every) % 2 == 0 else -1)
        s = size * rng.uniform(0.8, 1.2)
        base = p + n * 0.05
        tip = base + side * s * 1.6 + n * s * 0.4 + d * s * 0.3
        mid1 = base + side * s * 0.8 + d * s * 0.45 + n * s * 0.25
        mid2 = base + side * s * 0.8 - d * s * 0.45 + n * s * 0.25
        double_quad(bm, [base, mid2, tip, mid1], 0.01)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    return make_obj(name, bm, color, recalc=False)


def flowers(name, spots, seed, petal=(255, 90, 180), middle=(255, 220, 40)):
    rng = random.Random(seed)
    heads, cents = bmesh.new(), bmesh.new()
    for x, y, z, r in spots:
        origin = (
            Matrix.Translation((x, y, z + 0.18))
            @ Matrix.Rotation(rng.uniform(-0.25, 0.25), 4, "X")
            @ Matrix.Rotation(rng.uniform(-0.25, 0.25), 4, "Y")
        )
        _petals(heads, origin, r, 0.0)
        _flower_centre(cents, origin, r)
    return make_obj(name + "_Petals", heads, petal), make_obj(name + "_Centers", cents, middle)


def _column(bm, base, r, h, n=8):
    b = Vector(base)
    top = b + Vector((0, 0, h))
    hull_into(bm, ring(b, r, r, n) + ring(top, r, r, n))
    hull_into(bm, ring(top, r, r, n) + ring(top + Vector((0, 0, r * 0.55)), r * 0.7, r * 0.7, n) + [top + Vector((0, 0, r * 0.85))])


def _frame(direction):
    d = Vector(direction).normalized()
    helper = Vector((0, 0, 1)) if abs(d.z) < 0.95 else Vector((1, 0, 0))
    u = d.cross(helper).normalized()
    v = d.cross(u).normalized()
    return d, u, v


def tube(bm, points, radius, n=6):
    pts = [Vector(p) for p in points]
    radii = radius if isinstance(radius, (list, tuple)) else [radius] * len(pts)
    rings = []
    for i, p in enumerate(pts):
        a = pts[max(i - 1, 0)]
        b = pts[min(i + 1, len(pts) - 1)]
        _, u, v = _frame(b - a)
        r = radii[i]
        rings.append([p + (u * math.cos(k * math.tau / n) + v * math.sin(k * math.tau / n)) * r for k in range(n)])
    for i in range(len(rings) - 1):
        hull_into(bm, rings[i] + rings[i + 1])


def frond(bm, base, yaw, length, width, segments=5, lift=0.6, reach=0.9, tip_drop=0.15, fold=0.3, thickness=0.05, serrate=True):
    base = Vector(base)
    out = Vector((math.cos(yaw), math.sin(yaw), 0))
    up = Vector((0, 0, 1))
    p1 = base + up * length * lift + out * length * 0.25
    p2 = base + out * length * reach + up * length * (lift - tip_drop)
    spine = []
    for k in range(segments + 1):
        t = k / segments
        spine.append(base * (1 - t) ** 2 + p1 * 2 * (1 - t) * t + p2 * t * t)
    widths = []
    for k in range(segments + 1):
        t = k / segments
        w = width * math.sin(math.pi * min(1.0, 0.08 + t * 0.92)) ** 0.7
        if serrate and 0 < k < segments and k % 2 == 1:
            w *= 0.55
        widths.append(w)
    for k in range(segments):
        a, b = spine[k], spine[k + 1]
        d = (b - a).normalized()
        side = d.cross(up).normalized()
        for s in (-1, 1):
            edge = (side * s + up * fold).normalized()
            pts = [a, b, b + edge * widths[k + 1] + d * 0.06, a + edge * widths[k]]
            if s < 0:
                pts.reverse()
            double_quad(bm, pts, thickness * 0.2)


def double_quad(bm, pts, offset=0.01):
    a, b, c = Vector(pts[0]), Vector(pts[1]), Vector(pts[2])
    n = (b - a).cross(c - a)
    if n.length < 1e-9:
        return
    n.normalize()
    if n.z < 0:
        pts = list(reversed(pts))
        n = -n
    top = [bm.verts.new(Vector(p) + n * offset) for p in pts]
    bottom = [bm.verts.new(Vector(p) - n * offset) for p in pts]
    bm.faces.new(top)
    bm.faces.new(list(reversed(bottom)))


def fern(name, base, seed, fronds=6, length=1.8, width=0.5, segments=5, lift=0.6, reach=0.9, color=(30, 150, 45), serrate=True, fold=0.3):
    rng = random.Random(seed)
    bm = bmesh.new()
    off = rng.uniform(0, math.tau)
    for i in range(fronds):
        yaw = off + i * math.tau / fronds + rng.uniform(-0.25, 0.25)
        frond(
            bm,
            Vector(base) + Vector((rng.uniform(-0.08, 0.08), rng.uniform(-0.08, 0.08), 0)),
            yaw,
            length * rng.uniform(0.85, 1.1),
            width,
            segments,
            lift * rng.uniform(0.85, 1.15),
            reach,
            fold=fold,
            serrate=serrate,
        )
    bmesh.ops.triangulate(bm, faces=bm.faces)
    return make_obj(name, bm, color, recalc=False)


def surface_path(rock, start, end, steps=12, lift=0.06, arc=1.0, centre=None, wobble=0.0, cycles=2.0, phase=0.0):
    centre = Vector(centre) if centre else Vector((0, 0, 0))
    start, end = Vector(start), Vector(end)
    across = Vector((-(end - start).y, (end - start).x, 0)).normalized()
    pts = []
    top = max(v.co.z for v in rock.data.vertices)
    for i in range(steps + 1):
        t = i / steps
        flat = start.lerp(end, t) + across * wobble * math.sin(phase + t * cycles * math.tau) * math.sin(math.pi * t)
        probe = Vector((flat.x, flat.y, flat.z + math.sin(math.pi * t) * top * arc))
        origin = Vector((centre.x, centre.y, min(probe.z, top) * 0.5))
        direction = (probe - origin).normalized()
        hit, loc, normal, _ = rock.ray_cast(origin + direction * 50, -direction)
        if hit:
            pts.append(loc + normal * lift)
    return pts


def _clip_x(poly, lo, hi):
    def clip(points, keep, cut):
        out = []
        for i, p in enumerate(points):
            q = points[(i + 1) % len(points)]
            pin, qin = keep(p), keep(q)
            if pin:
                out.append(p)
            if pin != qin:
                t = (cut - p[0]) / (q[0] - p[0])
                out.append((cut, p[1] + (q[1] - p[1]) * t))
        return out

    poly = clip(poly, lambda p: p[0] >= lo, lo)
    if poly:
        poly = clip(poly, lambda p: p[0] <= hi, hi)
    return poly


def front_relief(bm, rock, footprint, depth, sink=0.25, front=-1, strip=0.45):
    xs = [p[0] for p in footprint]
    lo, hi = min(xs), max(xs)
    count = max(1, math.ceil((hi - lo) / strip))
    for k in range(count):
        part = _clip_x(footprint, lo + (hi - lo) * k / count, lo + (hi - lo) * (k + 1) / count)
        pts = []
        for x, z in part:
            hit, loc, normal, _ = rock.ray_cast(Vector((x, front * 50, z)), Vector((0, -front, 0)))
            if not hit:
                continue
            pts.append(loc - Vector((0, front * sink, 0)))
            pts.append(loc + Vector((0, front * depth, 0)))
        if len(pts) >= 6:
            hull_into(bm, pts)


def rect(x0, z0, x1, z1):
    return [(x0, z0), (x1, z0), (x1, z1), (x0, z1)]


def tiki_face(name, rock, cx, cz, scale, color=(170, 80, 0)):
    s = scale
    bm = bmesh.new()

    def r(x0, z0, x1, z1):
        return rect(cx + x0 * s, cz + z0 * s, cx + x1 * s, cz + z1 * s)

    def poly(points):
        return [(cx + x * s, cz + z * s) for x, z in points]

    def octagon(x, z, radius):
        return poly([(x + math.cos(i * math.tau / 8 + math.pi / 8) * radius, z + math.sin(i * math.tau / 8 + math.pi / 8) * radius) for i in range(8)])

    front_relief(bm, rock, r(-2.8, 2.2, 2.8, 2.75), 0.4 * s)
    for side in (-1, 1):
        ex = side * 1.35
        front_relief(bm, rock, octagon(ex, 1.2, 0.72), 0.2 * s)
        front_relief(bm, rock, octagon(ex, 1.2, 0.3), 0.55 * s)
        front_relief(bm, rock, poly([(side * 2.15, -0.45), (side * 2.75, -0.15), (side * 2.45, 0.35), (side * 1.9, 0.05)]), 0.25 * s)
    front_relief(bm, rock, poly([(-0.28, 1.6), (0.28, 1.6), (0.75, -0.3), (-0.75, -0.3)]), 0.6 * s)
    front_relief(bm, rock, r(-2.2, -2.0, 2.2, -0.75), 0.2 * s)
    for i in range(6):
        tx = -1.8 + i * 0.72
        front_relief(bm, rock, r(tx - 0.24, -1.55, tx + 0.24, -1.0), 0.45 * s)
    return make_obj(name, bm, color)


def split_prop(obj, x=0.0):
    halves = []
    for suffix, clear_outer in (("_L", True), ("_R", False)):
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        res = bmesh.ops.bisect_plane(
            bm,
            geom=bm.verts[:] + bm.edges[:] + bm.faces[:],
            plane_co=(x, 0, 0),
            plane_no=(1, 0, 0),
            clear_outer=clear_outer,
            clear_inner=not clear_outer,
        )
        cut_edges = [e for e in res["geom_cut"] if isinstance(e, bmesh.types.BMEdge)]
        if cut_edges:
            bmesh.ops.holes_fill(bm, edges=cut_edges, sides=0)
        if not bm.faces:
            bm.free()
            halves.append(None)
            continue
        bmesh.ops.triangulate(bm, faces=bm.faces)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        name = obj.name + suffix
        _remove_object(name)
        me = bpy.data.meshes.new(name)
        bm.to_mesh(me)
        bm.free()
        half = bpy.data.objects.new(name, me)
        _collection().objects.link(half)
        planar_stud_uvs(me)
        half.data.materials.append(obj.data.materials[0])
        halves.append(half)
    return halves


def surface_spots(rock, count, seed, min_nz=-0.2, min_z=0.3, centre=(0, 0, 1), spacing=0.5, keep_clear_x=None):
    rng = random.Random(seed)
    c = Vector(centre)
    spots = []
    tries = 0
    while len(spots) < count and tries < count * 200:
        tries += 1
        d = Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(-0.3, 1))).normalized()
        hit, loc, normal, _ = rock.ray_cast(c + d * 50, -d)
        if not hit or normal.z < min_nz or loc.z < min_z:
            continue
        if keep_clear_x is not None and abs(loc.x - keep_clear_x[0]) < keep_clear_x[1]:
            continue
        if any((loc - s[0]).length < spacing for s in spots):
            continue
        spots.append((loc, normal))
    return spots


def _oriented(origin, normal):
    rot = Vector((0, 0, 1)).rotation_difference(Vector(normal).normalized()).to_matrix().to_4x4()
    return Matrix.Translation(origin) @ rot


def barnacles(name, spots, seed, size=0.35, color=(240, 235, 215)):
    rng = random.Random(seed)
    bm = bmesh.new()
    for loc, normal in spots:
        s = size * rng.uniform(0.7, 1.3)
        m = _oriented(loc - Vector(normal) * 0.05, normal)
        pts = ring((0, 0, -0.05), s, s, 7) + ring((0, 0, s * 0.9), s * 0.55, s * 0.55, 7)
        hull_into(bm, [m @ p for p in pts])
    return make_obj(name, bm, color)


def ribbon(bm, points, width, normals=None, twist=0.0, offset=0.012):
    pts = [Vector(p) for p in points]
    count = len(pts)
    lefts, rights, norms = [], [], []
    for i, p in enumerate(pts):
        d = (pts[min(i + 1, count - 1)] - pts[max(i - 1, 0)]).normalized()
        n = Vector(normals[i]).normalized() if normals else Vector((0, 0, 1))
        side = d.cross(n).normalized()
        w = width * (1 - 0.3 * i / count) / 2
        lefts.append(p - side * w)
        rights.append(p + side * w)
        norms.append(n)
    top_l = [bm.verts.new(p + n * offset) for p, n in zip(lefts, norms)]
    top_r = [bm.verts.new(p + n * offset) for p, n in zip(rights, norms)]
    bot_l = [bm.verts.new(p - n * offset) for p, n in zip(lefts, norms)]
    bot_r = [bm.verts.new(p - n * offset) for p, n in zip(rights, norms)]
    for i in range(count - 1):
        face = bm.faces.new((top_l[i], top_r[i], top_r[i + 1], top_l[i + 1]))
        back = bm.faces.new((bot_l[i + 1], bot_r[i + 1], bot_r[i], bot_l[i]))
        face.normal_update()
        if face.normal.dot(norms[i]) < 0:
            face.normal_flip()
            back.normal_flip()


def kelp(name, rock, strands, seed, width=0.4, color=(110, 130, 30), lift=0.06):
    rng = random.Random(seed)
    bm = bmesh.new()
    top = max(v.co.z for v in rock.data.vertices)
    for start, end, wobble in strands:
        pts = surface_path(rock, start, end, steps=14, lift=lift, arc=0.0, centre=(0, 0, 0), wobble=wobble, cycles=rng.uniform(1.5, 2.5), phase=rng.uniform(0, 6))
        normals = []
        for p in pts:
            d = (p - Vector((0, 0, top * 0.4))).normalized()
            hit, loc, n, _ = rock.ray_cast(p + d * 3, -d)
            normals.append(n if hit else d)
        ribbon(bm, pts, width * rng.uniform(0.85, 1.15), normals)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    return make_obj(name, bm, color, recalc=False)


def coral(name, base, seed, height=1.6, radius=0.13, branches=4, color=(255, 90, 170), spread=0.6):
    rng = random.Random(seed)
    bm = bmesh.new()
    base = Vector(base)
    trunk_top = base + Vector((0, 0, height * 0.45))
    tube(bm, [base - Vector((0, 0, 0.2)), trunk_top], radius, 6)
    for i in range(branches):
        yaw = i * math.tau / branches + rng.uniform(-0.4, 0.4)
        out = Vector((math.cos(yaw), math.sin(yaw), 0))
        start = trunk_top - Vector((0, 0, rng.uniform(0, height * 0.2)))
        mid = start + out * spread * rng.uniform(0.6, 1.0) + Vector((0, 0, height * 0.25))
        tip = mid + out * spread * 0.25 + Vector((0, 0, height * rng.uniform(0.3, 0.5)))
        tube(bm, [start, mid, tip], [radius * 0.9, radius * 0.75, radius * 0.6], 6)
        hull_into(bm, ring(tip, radius * 0.6, radius * 0.6, 6) + [tip + Vector((0, 0, radius * 0.7))])
    tip = trunk_top + Vector((0, 0, height * 0.5))
    tube(bm, [trunk_top, tip], [radius, radius * 0.65], 6)
    hull_into(bm, ring(tip, radius * 0.65, radius * 0.65, 6) + [tip + Vector((0, 0, radius * 0.7))])
    return make_obj(name, bm, color)


def anemones(name, spots, seed, size=0.5, base_color=(255, 140, 0), tentacle_color=(255, 220, 40)):
    rng = random.Random(seed)
    bases, tents = bmesh.new(), bmesh.new()
    for loc, normal in spots:
        s = size * rng.uniform(0.85, 1.15)
        m = _oriented(loc - Vector(normal) * 0.1, normal)
        hull_into(bases, [m @ p for p in ring((0, 0, 0), s * 0.55, s * 0.55, 8) + ring((0, 0, s * 0.6), s * 0.45, s * 0.45, 8)])
        for i in range(12):
            a = i * math.tau / 12
            root = Vector((math.cos(a) * s * 0.35, math.sin(a) * s * 0.35, s * 0.55))
            tip = Vector((math.cos(a) * s * 0.95, math.sin(a) * s * 0.95, s * 1.15))
            hull_into(tents, [m @ p for p in ring(root, s * 0.08, s * 0.08, 4)] + [m @ tip])
    return make_obj(name + "_Base", bases, base_color), make_obj(name + "_Tentacles", tents, tentacle_color)


def starfish(name, loc, normal, size=0.6, color=(255, 110, 30), spin=0.0):
    bm = bmesh.new()
    m = _oriented(Vector(loc) + Vector(normal) * 0.02, normal) @ Matrix.Rotation(spin, 4, "Z")
    for i in range(5):
        a = i * math.tau / 5
        tip = Vector((math.cos(a) * size, math.sin(a) * size, 0.04))
        s1 = Vector((math.cos(a - 0.6) * size * 0.32, math.sin(a - 0.6) * size * 0.32, 0))
        s2 = Vector((math.cos(a + 0.6) * size * 0.32, math.sin(a + 0.6) * size * 0.32, 0))
        hull_into(bm, [m @ (p + Vector((0, 0, dz))) for p in (Vector((0, 0, 0)), tip, s1, s2) for dz in (-0.06, size * 0.18)])
    return make_obj(name, bm, color)


def slope_cut(obj, point, normal):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    res = bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=point, plane_no=normal, clear_outer=True)
    cut_edges = [e for e in res["geom_cut"] if isinstance(e, bmesh.types.BMEdge)]
    if cut_edges:
        bmesh.ops.edgeloop_fill(bm, edges=cut_edges)
    bmesh.ops.triangulate(bm, faces=bm.faces, quad_method="BEAUTY", ngon_method="BEAUTY")
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(obj.data)
    bm.free()
    me = obj.data
    xs = [v.co.x for v in me.vertices]
    ys = [v.co.y for v in me.vertices]
    zs = [v.co.z for v in me.vertices]
    shift = Vector(((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, min(zs)))
    for v in me.vertices:
        v.co -= shift
    planar_stud_uvs(me)
    return stats(me)


def snow_cap(name, rock, min_nz=0.45, thickness=0.3, inset=0.05, color=(245, 250, 255)):
    bm = bmesh.new()
    bm.from_mesh(rock.data)
    keep = [f for f in bm.faces if f.normal.z >= min_nz]
    drop = [f for f in bm.faces if f.normal.z < min_nz]
    bmesh.ops.delete(bm, geom=drop, context="FACES")
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
    me = bpy.data.meshes.new(name + "_shell")
    bm.to_mesh(me)
    bm.free()
    _remove_object(name)
    obj = bpy.data.objects.new(name, me)
    _collection().objects.link(obj)
    mod = obj.modifiers.new("Solid", "SOLIDIFY")
    mod.thickness = thickness + inset
    mod.offset = 1.0
    mod.use_even_offset = True
    mod.use_rim = True
    depsgraph = bpy.context.evaluated_depsgraph_get()
    new_mesh = bpy.data.meshes.new_from_object(obj.evaluated_get(depsgraph))
    obj.modifiers.remove(mod)
    obj.data = new_mesh
    new_mesh.name = name
    bpy.data.meshes.remove(me)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    for v in bm.verts:
        pass
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(obj.data)
    bm.free()
    for v in obj.data.vertices:
        v.co.z -= inset
    planar_stud_uvs(obj.data)
    _finish(obj, plain_material(f"{name}_Mat", color))
    return obj


def cap_edge_points(cap, rock, max_nz=0.2, front_only=None):
    pts = []
    for v in cap.data.vertices:
        if front_only is not None and not front_only(v.co):
            continue
        pts.append(v.co.copy())
    return pts


def drips(name, points, seed, size=0.35, color=(245, 250, 255)):
    rng = random.Random(seed)
    bm = bmesh.new()
    for p in points:
        s = size * rng.uniform(0.7, 1.2)
        top = Vector(p)
        hull_into(bm, ring(top, s * 0.6, s * 0.6, 6) + ring(top - Vector((0, 0, s * 0.6)), s * 0.45, s * 0.45, 6) + [top - Vector((0, 0, s * 1.1))])
    return make_obj(name, bm, color)


def icicles(name, points, seed, length=0.9, radius=0.16, color=(185, 230, 255)):
    rng = random.Random(seed)
    bm = bmesh.new()
    for p in points:
        L = length * rng.uniform(0.6, 1.3)
        r = radius * rng.uniform(0.8, 1.2)
        top = Vector(p) + Vector((0, 0, 0.05))
        hull_into(bm, ring(top, r, r, 5) + [top - Vector((0, 0, L))])
    return make_obj(name, bm, color)


def igloo_bricks(name, rock, rows, seed, brick_h=0.45, depth=0.35, gap=0.08, color=(245, 250, 255), skip=None):
    rng = random.Random(seed)
    bm = bmesh.new()
    top = max(v.co.z for v in rock.data.vertices)
    for z, count in rows:
        off = rng.uniform(0, math.tau)
        for i in range(count):
            a0 = off + i * math.tau / count + gap
            a1 = off + (i + 1) * math.tau / count - gap
            if skip and skip(a0, a1, z):
                continue
            pts = []
            for a in (a0, a1):
                for dz in (-brick_h / 2, brick_h / 2):
                    d = Vector((math.cos(a), math.sin(a), 0))
                    origin = Vector((0, 0, z + dz))
                    hit, loc, normal, _ = rock.ray_cast(origin + d * 50, -d)
                    if not hit:
                        continue
                    pts.append(loc - normal * 0.1)
                    pts.append(loc + normal * depth)
            if len(pts) >= 6:
                hull_into(bm, pts)
    cap_z = rows[-1][0] + brick_h * 0.6
    cap_pts = []
    for i in range(10):
        a = i * math.tau / 10
        d = Vector((math.cos(a), math.sin(a), 0))
        hit, loc, normal, _ = rock.ray_cast(Vector((0, 0, cap_z)) + d * 50, -d)
        if hit:
            cap_pts.append(loc + normal * depth * 0.6)
    cap_pts.append(Vector((0, 0, top + depth)))
    if len(cap_pts) >= 5:
        hull_into(bm, cap_pts)
    return make_obj(name, bm, color)


def igloo_door(name, rock, direction, height, width, length, color=(245, 250, 255), hole=(40, 50, 110)):
    d = Vector(direction).normalized()
    side = Vector((-d.y, d.x, 0))
    hit, loc, normal, _ = rock.ray_cast(Vector((0, 0, height * 0.4)) + d * 50, -d)
    start = Vector((loc.x, loc.y, 0)) - d * 0.6
    end = start + d * (length + 0.6)
    arch, dark = bmesh.new(), bmesh.new()

    def arch_ring(c, w, h, n=8):
        pts = []
        for i in range(n + 1):
            a = math.pi * i / n
            pts.append(c + side * math.cos(a) * w + Vector((0, 0, math.sin(a) * h)))
        return pts

    hull_into(arch, arch_ring(start, width, height) + arch_ring(end, width, height))
    hull_into(dark, arch_ring(end + d * 0.03, width * 0.62, height * 0.7) + arch_ring(end - d * 0.4, width * 0.62, height * 0.7))
    return make_obj(name, arch, color), make_obj(name + "_Hole", dark, hole)


def split_with_props(rock, props, merges=(0.0, 0.05)):
    chosen, _ = find_mesh_split(rock, merges=merges)
    pieces, report = split_rock(rock, chosen["steps"], 0, chosen["merge"])
    for p in pieces:
        planar_stud_uvs(p.data)
    cut = chosen["steps"][0][2]
    pa, pb = pieces
    left, right = (pa, pb) if sum(v.co.x for v in pa.data.vertices) < sum(v.co.x for v in pb.data.vertices) else (pb, pa)
    sides = {left.name: [], right.name: []}
    for prop in props:
        xs = [v.co.x for v in prop.data.vertices]
        if max(xs) <= cut:
            sides[left.name].append(prop)
        elif min(xs) >= cut:
            sides[right.name].append(prop)
        else:
            lo, hi = split_prop(prop, cut)
            if lo:
                sides[left.name].append(lo)
            if hi:
                sides[right.name].append(hi)
    return {"cut": cut, "chosen": chosen, "report": report, "left": left, "right": right, "sides": sides}


def export_rock_set(name, rock, props, split, root, cam, target, split_cam, gap):
    import os

    d = os.path.join(root, name)
    os.makedirs(d, exist_ok=True)
    left, right, sides = split["left"], split["right"], split["sides"]
    split_props = sides[left.name] + sides[right.name]
    for o in [rock, left, right] + props + split_props:
        o.location = (0, 0, 0)
    export_fbx([rock] + props, os.path.join(d, f"{name}.fbx"))
    export_fbx([left, right] + split_props, os.path.join(d, f"{name}_Split.fbx"))
    render_preview([rock] + props, os.path.join(d, f"{name}_preview.png"), cam, target)
    for o in [left] + sides[left.name]:
        o.location.x = -gap
    for o in [right] + sides[right.name]:
        o.location.x = gap
    render_preview([left, right] + split_props, os.path.join(d, f"{name}_Split_preview.png"), split_cam, target)
    for o in [left, right] + split_props:
        o.location = (0, 0, 0)
    return d


def saguaro(name, base, trunk_h, trunk_r, arms, yaw=0.0, color=(60, 200, 60), n=8):
    bm = bmesh.new()
    _column(bm, (0, 0, 0), trunk_r, trunk_h, n)
    r = trunk_r * 0.68
    for z, side, out, rise in arms:
        start = Vector((0, 0, z))
        elbow = start + Vector((side * (trunk_r * 0.6 + out), 0, 0))
        hull_into(
            bm,
            [Vector((c.x, c.y + math.cos(i * math.tau / n) * r, c.z + math.sin(i * math.tau / n) * r)) for c in (start, elbow) for i in range(n)]
            + ring(elbow + Vector((0, 0, -r * 0.3)), r, r, n),
        )
        _column(bm, elbow - Vector((0, 0, r * 0.3)), r, rise, n)
    m = Matrix.Translation(base) @ Matrix.Rotation(yaw, 4, "Z")
    return make_obj(name, bm, color, m)
