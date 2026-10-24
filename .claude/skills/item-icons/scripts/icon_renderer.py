import json
import math
import os
import sys

import bmesh
import bpy
import numpy as np
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Euler, Matrix, Vector
from mathutils.bvhtree import BVHTree

SKILL = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(SKILL)))

STYLE = {
    "size": 512,
    "supersample": 2,
    "outline": 0.022,
    "margin": 0.012,
    "camera_direction": (0.22, 0.2, -1.0),
    "fov": 20.0,
    "samples": 96,
    "stud_size": 0.56,
    "stud_height": 0.17,
    "stud_bevel": 0.07,
    "stud_sink": 0.02,
    "stud_edge_gap": 0.06,
    "phase_steps": 5,
    "specular": 0.25,
    "stud_mode": {"outlet": "geometry", "inlet": "texture"},
    "stud_bump": 0.35,
    "world_strength": 1.0,
    "sun_strength": 2.4,
    "sun_angle": 35.0,
    "sun_from": (0.55, 0.85, -0.6),
    "exposure": 0.35,
    "roughness": {"Plastic": 0.55, "SmoothPlastic": 0.35, "Neon": 0.5},
    "neon_strength": 2.5,
}

RBX_TO_BLENDER = Matrix(((-1, 0, 0), (0, 0, 1), (0, 1, 0)))
BLENDER_TO_RBX = RBX_TO_BLENDER.inverted()


def to_blender(v):
    return RBX_TO_BLENDER @ Vector(v)


def srgb_to_linear(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def rbx_rotation(orientation):
    rx, ry, rz = (math.radians(a) for a in orientation)
    return (
        Matrix.Rotation(ry, 3, "Y") @ Matrix.Rotation(rx, 3, "X") @ Matrix.Rotation(rz, 3, "Z")
    )


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    return bpy.context.scene


def import_parts(fbx, parts, object_names, prefix=None):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=os.path.join(ROOT, fbx))
    imported = {o.name: o for o in set(bpy.data.objects) - before}
    result = {}
    for part_name, part in parts.items():
        candidates = [object_names.get(part_name), part_name]
        if prefix:
            candidates += [prefix if part_name == "Rock" else None, f"{prefix}_{part_name}"]
        obj = next((imported[c] for c in candidates if c and c in imported), None)
        if obj is None or obj.type != "MESH":
            raise RuntimeError(f"No mesh object for part {part_name} in {fbx}")
        place_part(obj, part)
        result[part_name] = obj
    for name, obj in imported.items():
        if obj not in result.values():
            bpy.data.objects.remove(obj)
    return result


def place_part(obj, part):
    me = obj.data
    me.transform(obj.matrix_world)
    obj.matrix_world = Matrix.Identity(4)
    rbx = [BLENDER_TO_RBX @ v.co for v in me.vertices]
    lo = Vector([min(p[i] for p in rbx) for i in range(3)])
    hi = Vector([max(p[i] for p in rbx) for i in range(3)])
    center = (lo + hi) / 2
    extent = hi - lo
    scale = Vector([part["size"][i] / extent[i] if extent[i] > 1e-6 else 1 for i in range(3)])
    rot = rbx_rotation(part["orientation"])
    pos = Vector(part["position"])
    for v, p in zip(me.vertices, rbx):
        local = Vector([(p[i] - center[i]) * scale[i] for i in range(3)])
        v.co = RBX_TO_BLENDER @ (pos + rot @ local)
    if me.has_custom_normals:
        with bpy.context.temp_override(object=obj, active_object=obj):
            bpy.ops.mesh.customdata_custom_splitnormals_clear()
    for poly in me.polygons:
        poly.use_smooth = False
    me.update()


def make_material(name, part):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    color = [srgb_to_linear(c) for c in part["color"]] + [1.0]
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = STYLE["roughness"].get(part["material"], 0.5)
    bsdf.inputs["Specular IOR Level"].default_value = STYLE["specular"]
    if part["material"] == "Neon":
        bsdf.inputs["Emission Color"].default_value = color
        bsdf.inputs["Emission Strength"].default_value = STYLE["neon_strength"]
    return mat


def world_per_uv(obj):
    me = obj.data
    uv = me.uv_layers.active.data
    length_3d = length_uv = 0.0
    for poly in me.polygons:
        loops = list(poly.loop_indices)
        for a, b in zip(loops, loops[1:] + loops[:1]):
            length_3d += (me.vertices[me.loops[a].vertex_index].co - me.vertices[me.loops[b].vertex_index].co).length
            length_uv += (uv[a].uv - uv[b].uv).length
    return length_3d / length_uv


def add_stud_texture(obj, variant):
    mat = obj.data.materials[0]
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    uv = nodes.new("ShaderNodeUVMap")
    uv.uv_map = obj.data.uv_layers.active.name
    mapping = nodes.new("ShaderNodeMapping")
    mapping.inputs["Scale"].default_value = [world_per_uv(obj) / variant["studsPerTile"]] * 3
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(os.path.join(SKILL, "textures", variant["texture"]))
    tex.image.colorspace_settings.name = "Non-Color"
    tex.interpolation = "Cubic"
    gain = nodes.new("ShaderNodeMath")
    gain.operation = "MULTIPLY"
    gain.inputs[1].default_value = 2.0
    tint = nodes.new("ShaderNodeMix")
    tint.data_type = "RGBA"
    tint.blend_type = "MULTIPLY"
    tint.inputs["Factor"].default_value = 1.0
    tint.inputs["A"].default_value = bsdf.inputs["Base Color"].default_value
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = STYLE["stud_bump"]
    links.new(uv.outputs["UV"], mapping.inputs["Vector"])
    links.new(mapping.outputs["Vector"], tex.inputs["Vector"])
    links.new(tex.outputs["Color"], gain.inputs[0])
    links.new(gain.outputs[0], tint.inputs["B"])
    links.new(tint.outputs["Result"], bsdf.inputs["Base Color"])
    links.new(tex.outputs["Color"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])


def stud_template(tile):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    s = STYLE["stud_size"] * tile
    h = STYLE["stud_height"] * tile
    sink = STYLE["stud_sink"] * tile
    for v in bm.verts:
        v.co.x *= s
        v.co.y *= s
        v.co.z = h if v.co.z > 0 else -sink
    top_edges = [e for e in bm.edges if not all(v.co.z < 0 for v in e.verts)]
    bmesh.ops.bevel(
        bm,
        geom=top_edges,
        offset=STYLE["stud_bevel"] * tile,
        segments=3,
        affect="EDGES",
        profile=0.5,
    )
    verts = [v.co.copy() for v in bm.verts]
    faces = [[v.index for v in f.verts] for f in bm.faces]
    bm.free()
    return verts, faces


def point_in_tri(p, a, b, c):
    def cross(o, u, w):
        return (u[0] - o[0]) * (w[1] - o[1]) - (u[1] - o[1]) * (w[0] - o[0])

    d1, d2, d3 = cross(a, b, p), cross(b, c, p), cross(c, a, p)
    neg = d1 < -1e-9 or d2 < -1e-9 or d3 < -1e-9
    pos = d1 > 1e-9 or d2 > 1e-9 or d3 > 1e-9
    return not (neg and pos)


def flat_regions(obj):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.faces.ensure_lookup_table()
    seen = set()
    regions = []
    for face in bm.faces:
        if face.index in seen:
            continue
        n = face.normal.copy()
        stack = [face]
        group = []
        seen.add(face.index)
        while stack:
            f = stack.pop()
            group.append(f)
            for e in f.edges:
                for g in e.link_faces:
                    if g.index not in seen and g.normal.dot(n) > math.cos(math.radians(2)):
                        seen.add(g.index)
                        stack.append(g)
        tris = []
        for f in group:
            loops = [v.co.copy() for v in f.verts]
            for i in range(1, len(loops) - 1):
                tris.append((loops[0], loops[i], loops[i + 1]))
        regions.append((n, tris))
    bm.free()
    return regions


def place_studs(obj, tile, blockers):
    template_verts, template_faces = stud_template(tile)
    s = STYLE["stud_size"] * tile
    clearance = STYLE["stud_height"] * tile + 0.02
    world_up = Vector((0, 0, 1))
    verts, faces = [], []
    for n, tris in flat_regions(obj):
        if abs(n.dot(world_up)) > 0.95:
            right = Vector((1, 0, 0))
        else:
            right = world_up.cross(n).normalized()
        up = n.cross(right).normalized()
        origin = tris[0][0]
        flat = [tuple(((p - origin).dot(right), (p - origin).dot(up)) for p in t) for t in tris]
        xs = [p[0] for t in flat for p in t]
        ys = [p[1] for t in flat for p in t]
        half = s / 2 + STYLE["stud_edge_gap"] * tile
        if max(xs) - min(xs) < 2 * half or max(ys) - min(ys) < 2 * half:
            continue

        def fits(cx, cy):
            probes = [(cx, cy), (cx - half, cy - half), (cx + half, cy - half), (cx - half, cy + half), (cx + half, cy + half)]
            if not all(any(point_in_tri(p, *t) for t in flat) for p in probes):
                return None
            world = [origin + right * px + up * py for px, py in probes]
            if any(b.ray_cast(p + n * 1e-3, n, clearance)[0] is not None for b in blockers for p in world):
                return None
            return world[0]

        steps = STYLE["phase_steps"]
        best = []
        for pi in range(steps):
            for pj in range(steps):
                x0 = min(xs) + half + tile * pi / steps
                y0 = min(ys) + half + tile * pj / steps
                cells = []
                cx = x0
                while cx <= max(xs) - half + 1e-6:
                    cy = y0
                    while cy <= max(ys) - half + 1e-6:
                        at = fits(cx, cy)
                        if at is not None:
                            cells.append(at)
                        cy += tile
                    cx += tile
                if len(cells) > len(best):
                    best = cells
        basis = Matrix((right, up, n)).transposed()
        for at in best:
            start = len(verts)
            verts.extend(at + basis @ v for v in template_verts)
            faces.extend([k + start for k in f] for f in template_faces)
    if not verts:
        return None
    me = bpy.data.meshes.new(obj.name + "_Studs")
    me.from_pydata([tuple(v) for v in verts], [], faces)
    for poly in me.polygons:
        poly.use_smooth = False
    studs = bpy.data.objects.new(obj.name + "_Studs", me)
    bpy.context.scene.collection.objects.link(studs)
    studs.data.materials.append(obj.data.materials[0])
    return studs


def bvh_of(obj):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    tree = BVHTree.FromBMesh(bm)
    bm.free()
    return tree


def setup_world(scene):
    world = bpy.data.worlds.new("IconWorld")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (1, 1, 1, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = STYLE["world_strength"]
    scene.world = world
    sun_data = bpy.data.lights.new("IconSun", "SUN")
    sun_data.energy = STYLE["sun_strength"]
    sun_data.angle = math.radians(STYLE["sun_angle"])
    sun = bpy.data.objects.new("IconSun", sun_data)
    scene.collection.objects.link(sun)
    toward = to_blender(STYLE["sun_from"]).normalized()
    sun.rotation_euler = (-toward).to_track_quat("-Z", "Y").to_euler()


def setup_camera(scene, objects):
    cam_data = bpy.data.cameras.new("IconCamera")
    cam_data.sensor_fit = "AUTO"
    cam_data.sensor_width = 36
    cam_data.sensor_height = 36
    cam_data.lens_unit = "FOV"
    cam_data.angle = math.radians(STYLE["fov"])
    cam = bpy.data.objects.new("IconCamera", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    points = [o.matrix_world @ v.co for o in objects for v in o.data.vertices]
    lo = Vector([min(p[i] for p in points) for i in range(3)])
    hi = Vector([max(p[i] for p in points) for i in range(3)])
    center = (lo + hi) / 2
    direction = to_blender(STYLE["camera_direction"]).normalized()
    distance = (hi - lo).length / 2 / math.tan(cam_data.angle / 2)
    cam.location = center + direction * distance
    cam.rotation_euler = (-direction).to_track_quat("-Z", "Y").to_euler()
    bpy.context.view_layer.update()
    uv = [world_to_camera_view(scene, cam, p) for p in points]
    u0, u1 = min(p.x for p in uv), max(p.x for p in uv)
    v0, v1 = min(p.y for p in uv), max(p.y for p in uv)
    fill = 1 - 2 * (STYLE["outline"] + STYLE["margin"])
    zoom = fill / max(u1 - u0, v1 - v0)
    cam_data.angle = 2 * math.atan(math.tan(cam_data.angle / 2) / zoom)
    cam_data.shift_x = ((u0 + u1) / 2 - 0.5) * zoom
    cam_data.shift_y = ((v0 + v1) / 2 - 0.5) * zoom


def setup_render(scene, path):
    scene.render.engine = "CYCLES"
    scene.cycles.samples = STYLE["samples"]
    scene.cycles.use_denoising = True
    scene.render.film_transparent = True
    size = STYLE["size"] * STYLE["supersample"]
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    scene.render.resolution_percentage = 100
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.view_settings.exposure = STYLE["exposure"]
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.filepath = path


def load_pixels(path):
    img = bpy.data.images.load(path)
    img.colorspace_settings.name = "Non-Color"
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    bpy.data.images.remove(img)
    return px


def downsample(px, factor):
    h, w, _ = px.shape
    rgb = px[..., :3] * px[..., 3:4]
    a = px[..., 3:4]
    rgb = rgb.reshape(h // factor, factor, w // factor, factor, 3).mean(axis=(1, 3))
    a = a.reshape(h // factor, factor, w // factor, factor, 1).mean(axis=(1, 3))
    return rgb, a


def outline(rgb_premul, alpha):
    size = alpha.shape[0]
    r = STYLE["outline"] * size
    ri = int(math.ceil(r))
    padded = np.pad(alpha[..., 0], ri)
    grown = np.zeros_like(alpha[..., 0])
    for dy in range(-ri, ri + 1):
        for dx in range(-ri, ri + 1):
            d = math.hypot(dx, dy)
            if d > r + 0.5:
                continue
            weight = min(1.0, r + 0.5 - d)
            shifted = padded[ri + dy : ri + dy + size, ri + dx : ri + dx + size] * weight
            np.maximum(grown, shifted, out=grown)
    grown = grown[..., None]
    out_a = alpha + grown * (1 - alpha)
    out_rgb = np.where(out_a > 1e-6, rgb_premul / np.maximum(out_a, 1e-6), 0)
    return np.concatenate([out_rgb, out_a], axis=2)


def save_png(px, path):
    h, w, _ = px.shape
    img = bpy.data.images.new("IconOut", w, h, alpha=True)
    img.colorspace_settings.name = "Non-Color"
    img.pixels[:] = np.clip(px, 0, 1).ravel().tolist()
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    bpy.data.images.remove(img)


def render_icon(key, spec, manifest, variants, out_dir):
    scene = reset_scene()
    entry = manifest[key]
    parts = import_parts(entry["fbx"], spec["parts"], entry.get("objects", {}), entry.get("prefix"))
    for name, obj in parts.items():
        obj.data.materials.clear()
        obj.data.materials.append(make_material(name, spec["parts"][name]))
    studs = []
    for name, obj in parts.items():
        variant = variants.get(spec["parts"][name]["variant"])
        if variant and STYLE["stud_mode"].get(variant["kind"]) == "texture":
            add_stud_texture(obj, variant)
        elif variant:
            blockers = [bvh_of(o) for n, o in parts.items() if n != name]
            stud = place_studs(obj, variant["studsPerTile"], blockers)
            if stud:
                studs.append(stud)
    kind, name = key.split("/")
    raw = os.path.join(out_dir, f"_raw_{kind}_{name}.png")
    setup_render(scene, raw)
    setup_world(scene)
    setup_camera(scene, list(parts.values()) + studs)
    bpy.ops.render.render(write_still=True)
    rgb, a = downsample(load_pixels(raw), STYLE["supersample"])
    os.remove(raw)
    final = os.path.join(out_dir, f"{kind}_{name}.png")
    save_png(outline(rgb, a), final)
    return final


def contact_sheet(manifest, out_dir):
    cell, columns, gap = 256, 3, 16
    keys = [k for k in manifest if os.path.exists(os.path.join(out_dir, k.replace("/", "_") + ".png"))]
    rows = math.ceil(len(keys) / columns)
    w, h = gap + columns * (cell + gap), gap + rows * (cell + gap)
    sheet = np.zeros((h, w, 4), dtype=np.float32)
    sheet[..., :3] = 0.24
    sheet[..., 3] = 1
    for i, key in enumerate(keys):
        px = load_pixels(os.path.join(out_dir, key.replace("/", "_") + ".png"))
        factor = px.shape[0] // cell
        rgb, a = downsample(px, factor)
        x = gap + (i % columns) * (cell + gap)
        y = h - (gap + (i // columns) * (cell + gap)) - cell
        region = sheet[y : y + cell, x : x + cell, :3]
        sheet[y : y + cell, x : x + cell, :3] = rgb + region * (1 - a)
    path = os.path.join(out_dir, "contact_sheet.png")
    save_png(sheet, path)
    return path


def main(argv):
    args = argv[argv.index("--") + 1 :] if "--" in argv else []
    specs = json.load(open(os.path.join(ROOT, "assets", "Icons", "specs.json")))
    manifest = json.load(open(os.path.join(SKILL, "manifest.json")))
    keys = args or list(manifest)
    out_dir = os.path.join(ROOT, "assets", "Icons")
    for key in keys:
        print("ICON", render_icon(key, specs["icons"][key], manifest, specs["variants"], out_dir))
    print("SHEET", contact_sheet(manifest, out_dir))


if __name__ == "__main__":
    main(sys.argv)
