import bpy, math, sys
from mathutils import Vector, Matrix

sys.path.insert(0, r"C:\Users\Admin\Documents\RobloxDev\.claude\skills\rock-model\scripts")
import rock_builder as rb

ROOT = r"C:\Users\Admin\Documents\RobloxDev\assets\Bosses"
NAMES = ("BigCroc", "BoulderCrab", "FrostYeti")
OFFSET = {"BigCroc": -14.0, "BoulderCrab": 0.0, "FrostYeti": 13.0}


def render(path, target, direction, scale, res=(1100, 800)):
    scene = bpy.context.scene
    rb.setup_preview_scene()
    scene.render.engine = "BLENDER_EEVEE"
    cam = scene.camera
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = scale
    cam.data.clip_end = 500
    cam.location = Vector(target) + Vector(direction).normalized() * 80
    cam.rotation_euler = (Vector(target) - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def solo(name):
    for c in NAMES:
        for o in bpy.data.collections[c].objects:
            o.hide_render = name is not None and c != name


def shot(boss, tag, target, direction, scale, res=(1100, 800)):
    solo(boss)
    render(rf"{ROOT}\{boss}\{boss}_{tag}.png", (target[0] + OFFSET[boss], target[1], target[2]), direction, scale, res)
    solo(None)


def pose(boss, rots):
    objs = list(bpy.data.collections[boss].objects)
    pieces = {o.name.split("_", 1)[1]: o for o in objs if o["kind"] == "Piece"}
    cache = {"Root": Matrix.Identity(4)}

    def mat(name):
        if name not in cache:
            o = pieces[name]
            j = Vector(o["joint"])
            axis, deg = rots.get(name, ("X", 0.0))
            cache[name] = mat(o["parent"]) @ Matrix.Translation(j) @ Matrix.Rotation(math.radians(deg), 4, axis) @ Matrix.Translation(-j)
        return cache[name]

    base = Matrix.Translation((OFFSET[boss], 0, 0))
    for o in objs:
        name = o.name.split("_", 1)[1] if o["kind"] == "Piece" else o["parent"]
        o.matrix_world = base @ mat(name)


def silhouette(boss, tag, target, direction, scale, res=(900, 700)):
    scene = bpy.context.scene
    solo(boss)
    rb.setup_preview_scene()
    old = scene.world.color[:]
    scene.world.color = (1, 1, 1)
    sh = scene.display.shading
    keep = (sh.light, sh.color_type, sh.single_color[:], sh.background_type)
    sh.light, sh.color_type, sh.single_color, sh.background_type = "FLAT", "SINGLE", (0, 0, 0), "WORLD"
    cam = scene.camera
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = scale
    t = (target[0] + OFFSET[boss], target[1], target[2])
    cam.location = Vector(t) + Vector(direction).normalized() * 80
    cam.rotation_euler = (Vector(t) - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.filepath = rf"{ROOT}\{boss}\{boss}_{tag}.png"
    bpy.ops.render.render(write_still=True)
    sh.light, sh.color_type, sh.single_color, sh.background_type = keep
    scene.world.color = old
    scene.render.engine = "BLENDER_EEVEE"
    solo(None)


def rest(boss):
    pose(boss, {})


def dims():
    out = {}
    for n in NAMES:
        lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
        for o in bpy.data.collections[n].objects:
            for v in o.data.vertices:
                for i in range(3):
                    lo[i] = min(lo[i], v.co[i])
                    hi[i] = max(hi[i], v.co[i])
        out[n] = {"min": [round(x, 2) for x in lo], "max": [round(x, 2) for x in hi]}
    return out
