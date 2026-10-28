# Pack meshlab OBJs into ONE .fbx for the Open Cloud Model upload (Chop a Rock route: upload_model.ps1,
# then InsertService:LoadAsset gives one MeshPart per object, named after the object).
#   blender -b -P tools/meshlab/tools/export_fbx.py -- <out.fbx> <a.obj> [b.obj ...]
# Pass absolute paths. Each OBJ becomes an object named after its file ("ForestTree_s1"), keeping its
# vertex colours, stud UVs and normals, left at the origin (Studio re-places them).
# The OBJ's front (-Z) is imported onto Blender -Y, which the Roblox importer reads back as -Z.
# render.py's axes (front onto +Y) came out turned 180° in Roblox (intro car, 2026-10-27).
import bpy, sys, os

argv = sys.argv[sys.argv.index("--") + 1:]
out, srcs = argv[0], argv[1:]
bpy.ops.wm.read_factory_settings(use_empty=True)

objs = []
for src in srcs:
    bpy.ops.object.select_all(action="DESELECT")
    bpy.ops.wm.obj_import(filepath=src, forward_axis="Z", up_axis="Y")
    obj = bpy.context.selected_objects[0]
    name = os.path.splitext(os.path.basename(src))[0]
    obj.name = name
    obj.data.name = name
    objs.append(obj)

bpy.ops.object.select_all(action="DESELECT")
for obj in objs:
    obj.select_set(True)
bpy.context.view_layer.objects.active = objs[0]
bpy.ops.export_scene.fbx(
    filepath=out,
    use_selection=True,
    object_types={"MESH"},
    apply_scale_options="FBX_SCALE_UNITS",
    axis_forward="-Z",
    axis_up="Y",
    mesh_smooth_type="FACE",
    path_mode="STRIP",
    bake_space_transform=True,
)
print("wrote", out, "with", len(objs), "objects")
