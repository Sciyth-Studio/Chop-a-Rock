import sys

import bmesh
import bpy
from mathutils import Vector

sys.path.insert(0, r"C:\Users\Admin\Documents\RobloxDev\.claude\skills\rock-model\scripts")
import rock_builder as rb

STUDS = r"C:\Users\Admin\Documents\RobloxDev\assets\Textures\Studs\SingleInletStud.png"

P = dict(
    half_w=3.0,
    post=0.3,
    post_x=2.75,
    post_y_front=1.75,
    post_y_back=-1.75,
    awn_half_w=3.5,
    awn_y_back=-2.15,
    awn_y_front=2.3,
    awn_z_back=6.0,
    awn_z_front=5.0,
    awn_t=0.25,
    stripes=7,
    val_h=0.2,
    val_point=0.3,
    val_t=0.1,
    side_val_h=0.2,
    counter_top=1.75,
    counter_top_t=0.15,
    counter_y_back=1.0,
    counter_y_front=2.25,
    counter_overhang=0.15,
    shelf_z=0.8,
)


def awn_z(y):
    t = (y - P["awn_y_back"]) / (P["awn_y_front"] - P["awn_y_back"])
    return P["awn_z_back"] + (P["awn_z_front"] - P["awn_z_back"]) * t


def prism(bm, outline, axis_offset):
    a = [bm.verts.new(Vector(p)) for p in outline]
    b = [bm.verts.new(Vector(p) + Vector(axis_offset)) for p in outline]
    n = len(outline)
    bm.faces.new(a)
    bm.faces.new(list(reversed(b)))
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((a[i], a[j], b[j], b[i]))


def box(bm, lo, hi):
    x0, y0, z0 = lo
    x1, y1, z1 = hi
    prism(bm, [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0)], (0, 0, z1 - z0))


def finish(name, bm, rgb):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    old = bpy.data.objects.get(name)
    if old:
        bpy.data.objects.remove(old, do_unlink=True)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(obj)
    rb.face_shade_colors(me, edge_width=0.12, edge_shade=0.62)
    rb.planar_stud_uvs(me)
    me.materials.append(rb.stud_overlay_material(f"{name}_Mat", rgb, STUDS))
    return obj


def build_wood(rgb=(214, 140, 64)):
    bm = bmesh.new()
    h = P["post"] / 2
    for x in (-P["post_x"], P["post_x"]):
        for y in (P["post_y_front"], P["post_y_back"]):
            top = awn_z(y + h) - P["awn_t"]
            box(bm, (x - h, y - h, 0), (x + h, y + h, top))
    ct, ctt = P["counter_top"], P["counter_top_t"]
    yb, yf, o = P["counter_y_back"], P["counter_y_front"], P["counter_overhang"]
    hw = P["half_w"]
    box(bm, (-hw - o, yb - o * 0.5, ct - ctt), (hw + o, yf, ct))
    box(bm, (-hw, yf - 0.33, 0), (hw, yf - 0.15, ct - ctt))
    for s in (-1, 1):
        box(bm, (s * hw - (0.15 if s > 0 else 0), yb, 0), (s * hw + (0 if s > 0 else 0.15), yf - 0.33, ct - ctt))
    box(bm, (-hw + 0.15, yb, P["shelf_z"] - 0.06), (hw - 0.15, yf - 0.33, P["shelf_z"] + 0.06))
    return finish("ShopStall_Wood", bm, rgb)


def build_covering(colored, rgb):
    bm = bmesh.new()
    n = P["stripes"]
    aw = P["awn_half_w"]
    sw = 2 * aw / n
    yb, yf, t = P["awn_y_back"], P["awn_y_front"], P["awn_t"]
    vt = P["val_t"]
    ys = yf - vt
    zb, zs = awn_z(yb), awn_z(ys)
    for i in range(n):
        if (i % 2 == 0) != colored:
            continue
        x0, x1 = -aw + i * sw, -aw + (i + 1) * sw
        prism(bm, [(x0, yb, zb - t), (x0, ys, zs - t), (x0, ys, zs), (x0, yb, zb)], (x1 - x0, 0, 0))
        top, bot = zs, awn_z(yf) - t - P["val_h"]
        tip = bot - P["val_point"]
        prism(
            bm,
            [(x0, yf - vt, top), (x0, yf - vt, bot), ((x0 + x1) / 2, yf - vt, tip), (x1, yf - vt, bot), (x1, yf - vt, top)],
            (0, vt, 0),
        )
    if colored:
        vt, sh = P["val_t"], P["side_val_h"]
        y0, y1 = yb, yf - P["val_t"]
        for x in (-aw, aw - vt):
            z0, z1 = awn_z(y0) - t, awn_z(y1) - t
            prism(bm, [(x, y0, z0), (x, y1, z1), (x, y1, z1 - sh), (x, y0, z0 - sh)], (vt, 0, 0))
    return finish("ShopStall_StripeColor" if colored else "ShopStall_StripeWhite", bm, rgb)


def build_all(color=(255, 45, 70)):
    return [
        build_wood(),
        build_covering(False, (245, 245, 245)),
        build_covering(True, color),
    ]
