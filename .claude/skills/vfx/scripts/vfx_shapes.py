"""VFX mesh shapes for Blender: crescent slashes, shockwave rings, cones, spirals, domes.

Derived from Roqer by S4US (https://github.com/S4US/Roqer, commit bf7118b,
apps/desktop/runtime/blender-worker.ts, AGPL-3.0-or-later), used with the
author's permission (granted to the user by DM, 2026-10-07). Local dev tool;
nothing here ships in the game.

Shapes are built in studs around the origin, facing Roblox forward (Blender -Y),
as one open sheet with UVs: U along the sweep, V across it.
"""

import math
import os

import bmesh
import bpy
from mathutils import Vector

COLLECTION = "VFXShapes"
OUT = os.path.join(r"C:\Users\Admin\Documents\RobloxDev", "assets", "VFX")


def _collection():
    col = bpy.data.collections.get(COLLECTION)
    if col is None:
        col = bpy.data.collections.new(COLLECTION)
        bpy.context.scene.collection.children.link(col)
    return col


def remove(name):
    obj = bpy.data.objects.get(name)
    if obj is not None:
        mesh = obj.data if obj.type == "MESH" else None
        bpy.data.objects.remove(obj, do_unlink=True)
        if mesh is not None and mesh.users == 0:
            bpy.data.meshes.remove(mesh)


def _heading(angle):
    return Vector((math.sin(angle), -math.cos(angle), 0.0))


def surface(name, point, columns=32, rows=1):
    remove(name)
    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.new("UVMap")
    verts = [[bm.verts.new(Vector(point(c / columns, r / rows))) for r in range(rows + 1)] for c in range(columns + 1)]
    for c in range(columns):
        for r in range(rows):
            corners = ((c, r), (c + 1, r), (c + 1, r + 1), (c, r + 1))
            face = bm.faces.new([verts[i][j] for i, j in corners])
            for loop, (i, j) in zip(face.loops, corners):
                loop[uv_layer].uv = (i / columns, j / rows)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    _collection().objects.link(obj)
    return obj


def crescent(name, radius, width, sweep=160, segments=40, taper=True):
    if not 0 < width < radius:
        raise ValueError("width must be between 0 and radius")
    half = math.radians(sweep) / 2

    def point(u, v):
        thickness = width * (max(math.sin(math.pi * u), 0.03) if taper else 1.0)
        return _heading(half - 2 * half * u) * (radius - thickness + thickness * v)

    return surface(name, point, segments, 2 if taper else 1)


def ring(name, radius, width=0.5, height=0.0, top_radius=None, segments=48):
    if height <= 0:
        if not 0 < width < radius:
            raise ValueError("width must be between 0 and radius")
        return surface(name, lambda u, v: _heading(2 * math.pi * u) * (radius - width + width * v), segments, 1)
    top = radius if top_radius is None else top_radius
    return surface(
        name,
        lambda u, v: _heading(2 * math.pi * u) * (radius + (top - radius) * v) + Vector((0, 0, height * v)),
        segments,
        1,
    )


def cone(name, radius, height, tip_radius=0.0, segments=32):
    tip = max(tip_radius, 0.001)
    return surface(
        name,
        lambda u, v: _heading(2 * math.pi * u) * (radius + (tip - radius) * v) + Vector((0, 0, height * v)),
        segments,
        4,
    )


def spiral(name, radius, height, width, turns=1.5, top_radius=None, segments=96):
    top = radius if top_radius is None else top_radius

    def point(u, v):
        return _heading(2 * math.pi * turns * u) * (radius + (top - radius) * u) + Vector(
            (0, 0, height * u + width * (v - 0.5))
        )

    return surface(name, point, segments, 1)


def dome(name, radius, segments=32, rings=12, full_sphere=False):
    def point(u, v):
        polar = math.pi * (1 - v) if full_sphere else (math.pi / 2) * (1 - v)
        return _heading(2 * math.pi * u) * (radius * math.sin(polar)) + Vector((0, 0, radius * math.cos(polar)))

    return surface(name, point, segments, rings)


def stats(obj):
    mesh = obj.data
    xs = [v.co.x for v in mesh.vertices]
    ys = [v.co.y for v in mesh.vertices]
    zs = [v.co.z for v in mesh.vertices]
    return {
        "name": obj.name,
        "tris": sum(len(p.vertices) - 2 for p in mesh.polygons),
        "size_studs": (round(max(xs) - min(xs), 2), round(max(zs) - min(zs), 2), round(max(ys) - min(ys), 2)),
    }


def export_fbx(objects, effect, file_name):
    folder = os.path.join(OUT, effect)
    os.makedirs(folder, exist_ok=True)
    path = os.path.join(folder, file_name + ".fbx")
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
    return path
