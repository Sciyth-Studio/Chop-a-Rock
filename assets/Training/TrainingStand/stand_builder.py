import sys
import bmesh
import bpy

rb = sys.modules["rock_builder"]
H = 0.5

P = dict(
    POST_X=1.56, POST_W=0.55, POST_D=0.74,
    FOOT_H=0.46, FOOT_D=2.55, FOOT_OUT=1.19, FOOT_BEV=0.12,
    BOARD_BOTTOM=3.2, BR_T=0.42, BR_H=0.9, EMBED=0.15,
    CROSS_Z0=0.17, CROSS_Z1=0.8, CROSS_D=0.6,
)


def new_obj(name, bm):
    rb._remove_object(name)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(name, me)
    rb._collection().objects.link(obj)
    return obj


def box(name, x0, x1, y0, y1, z0, z1, bevel=0.06, top_only=False):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co.x = (x0 if v.co.x < 0 else x1) * H
        v.co.y = (y0 if v.co.y < 0 else y1) * H
        v.co.z = (z0 if v.co.z < 0 else z1) * H
    if bevel > 0:
        if top_only:
            edges = [e for e in bm.edges if all(v.co.z > (z0 + z1) / 2 * H for v in e.verts)]
        else:
            edges = [e for e in bm.edges if not all(abs(v.co.z - z0 * H) < 1e-6 for v in e.verts)]
        bmesh.ops.bevel(bm, geom=edges, offset=bevel * H, segments=1, affect="EDGES", profile=0.5, clamp_overlap=True)
    return new_obj(name, bm)


def wedge(name, px, py, dx, dy, length, height, thick, z0):
    nx, ny = -dy, dx
    bm = bmesh.new()
    verts = []
    for s in (-thick / 2, thick / 2):
        for a, b in ((0, 0), (length, 0), (0, height)):
            verts.append(bm.verts.new(((px + dx * a + nx * s) * H, (py + dy * a + ny * s) * H, (z0 + b) * H)))
    bm.faces.new(verts[0:3])
    bm.faces.new(verts[3:6])
    for i in range(3):
        j = (i + 1) % 3
        bm.faces.new([verts[i], verts[j], verts[3 + j], verts[3 + i]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return new_obj(name, bm)


def build_frame(merge=0.0, color=(176, 92, 38), p=P):
    parts = []
    for side in (-1, 1):
        pc = side * p["POST_X"]
        inner = pc - side * p["POST_W"] / 2
        outer = pc + side * p["FOOT_OUT"]
        fx0, fx1 = sorted((inner, outer))
        parts.append(box(f"tmp_foot{side}", fx0, fx1, -p["FOOT_D"] / 2, p["FOOT_D"] / 2, 0, p["FOOT_H"], bevel=p["FOOT_BEV"], top_only=True))
        parts.append(box(f"tmp_post{side}", pc - p["POST_W"] / 2, pc + p["POST_W"] / 2, -p["POST_D"] / 2, p["POST_D"] / 2, p["FOOT_H"] - 0.1, p["BOARD_BOTTOM"], bevel=0.05))
        z0 = p["FOOT_H"] - 0.08
        ylen = p["FOOT_D"] / 2 - p["POST_D"] / 2 - p["FOOT_BEV"] - 0.06
        for sy in (-1, 1):
            parts.append(wedge(f"tmp_brace{side}{sy}", pc, sy * (p["POST_D"] / 2 - p["EMBED"]), 0, sy, ylen + p["EMBED"], p["BR_H"], p["BR_T"], z0))
        xlen = p["FOOT_OUT"] - p["POST_W"] / 2 - p["FOOT_BEV"] - 0.06
        parts.append(wedge(f"tmp_braceo{side}", pc + side * (p["POST_W"] / 2 - p["EMBED"]), 0, side, 0, xlen + p["EMBED"], p["BR_H"], p["BR_T"], z0))
    parts.append(box("tmp_cross", -p["POST_X"], p["POST_X"], -p["CROSS_D"] / 2, p["CROSS_D"] / 2, p["CROSS_Z0"], p["CROSS_Z1"], bevel=0.05))
    rb._remove_object("TrainingStand")
    frame = parts[0]
    frame.name = "TrainingStand"
    frame.data.name = "TrainingStand"
    for part in parts[1:]:
        rb.boolean(frame, part, "UNION")
        rb._remove_object(part.name)
    rb.clean_mesh(frame.data, merge)
    rb._finish(frame, rb.plain_material("StandWood", color))
    return frame, rb.stats(frame.data)


def build_board(color=(246, 222, 168), p=P):
    bb = p["BOARD_BOTTOM"]
    rb._remove_object("TrainingBoard")
    board = box("TrainingBoard", -2.02, 2.02, -0.6, 0.6, bb, bb + 0.34, bevel=0.06)
    top = box("tmp_b2", -2.08, 2.08, -0.655, 0.655, bb + 0.32, bb + 0.69, bevel=0.07)
    rb.boolean(board, top, "UNION")
    rb._remove_object("tmp_b2")
    rb.clean_mesh(board.data, 0.0)
    rb._finish(board, rb.plain_material("BoardPine", color))
    return board, rb.stats(board.data)


STACK = (
    (0.00, 0.00, 0.0),
    (0.18, -0.12, 9.0),
    (-0.14, 0.10, -7.0),
    (0.12, 0.02, 30.0),
)


def build_board_stack(name="BoardStack", layers=STACK, length=4.0, depth=1.2, thick=0.3, color=(246, 222, 168)):
    import math
    from mathutils import Matrix
    parts = []
    for i, (ox, oy, yaw) in enumerate(layers):
        z0 = i * (thick - 0.01)
        slab = box(f"tmp_slab{i}", -length / 2, length / 2, -depth / 2, depth / 2, z0, z0 + thick, bevel=0.09)
        slab.data.transform(Matrix.Translation((ox * H, oy * H, 0)) @ Matrix.Rotation(math.radians(yaw), 4, "Z"))
        parts.append(slab)
    rb._remove_object(name)
    stack = parts[0]
    stack.name = name
    stack.data.name = name
    for part in parts[1:]:
        rb.boolean(stack, part, "UNION")
        rb._remove_object(part.name)
    rb.clean_mesh(stack.data, 0.0)
    rb._finish(stack, rb.plain_material("BoardPine", color))
    return stack, rb.stats(stack.data)


def shade(objs, edge_width=0.12, edge_shade=0.62):
    for obj in objs:
        rb.face_shade_colors(obj.data, edge_width=edge_width, edge_shade=edge_shade)
        rb.planar_stud_uvs(obj.data)


def sliver_report(obj):
    import math
    out = []
    me = obj.data
    for poly in me.polygons:
        vs = [me.vertices[i].co for i in poly.vertices]
        angs = []
        for k in range(3):
            a, b, c = vs[k], vs[(k + 1) % 3], vs[(k + 2) % 3]
            u, w = (b - a), (c - a)
            if u.length > 1e-9 and w.length > 1e-9:
                angs.append(math.degrees(u.angle(w)))
        if angs and min(angs) < 2.0:
            out.append({"c": [round(x, 3) for x in poly.center], "n": [round(x, 2) for x in poly.normal], "area": round(poly.area, 5)})
    return out


def render_set(objs, d, prefix):
    rb.render_preview(objs, d + rf"\{prefix}_34.png", (4.2, -6.0, 3.6), target=(0, 0, 0.9))
    rb.render_preview(objs, d + rf"\{prefix}_front.png", (0, -8.0, 1.0), target=(0, 0, 1.0))
    rb.render_preview(objs, d + rf"\{prefix}_side.png", (8.0, 0, 1.0), target=(0, 0, 1.0))
    rb.render_preview(objs, d + rf"\{prefix}_back34.png", (-4.2, 6.0, 3.6), target=(0, 0, 0.9))
