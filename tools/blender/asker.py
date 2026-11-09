"""
Komando - Temel asker modeli ve sprite render hatti (Blender 4.2).

Tek bir iskelet + tek bir animasyon seti -> her kiyafet icin 8 yonlu sprite sheet.

Calistirma:
    blender -b --python tools/blender/asker.py -- --out assets/sprites [--outfits komando,alman_er] [--quick]

Her kiyafet icin iki dosya uretir:
    <cikti>/<isim>_sprite_sheet.png   (satirlar: animasyon x 8 yon, sutunlar: kareler)
    <cikti>/<isim>_sprite_sheet.json  (oyunun okudugu duzen bilgisi)

Yeni kiyafet eklemek icin OUTFITS sozlugune bir kayit ekle.
Yeni hareket eklemek icin ANIMS listesine ve pose() fonksiyonuna ekle;
tum kiyafetler otomatik olarak o hareketi kazanir.
"""
import bpy
import bmesh
import math
import os
import sys
import json
import tempfile
import numpy as np
from mathutils import Matrix, Vector
from bpy_extras.object_utils import world_to_camera_view

# ---------------------------------------------------------------- ayarlar
FRAME = 128              # her karenin piksel boyutu
ELEVATION = 50.0         # kamera egimi (derece) - Commandos benzeri 3/4 gorunum
ORTHO = 4.2              # kameranin gordugu alan (metre) - yere dusen asker de sigsin
DIRS = 8                 # 0=Dogu 1=GD 2=Guney 3=GB 4=Bati 5=KB 6=Kuzey 7=KD (Godot acisi)
SAMPLES = 24
SLOT = 8                 # her (animasyon, yon) dizisi icin ayrilan kare sayisi
SLOTS_PER_ROW = 2        # sayfa satirinda yan yana kac dizi (doku boyutu 4096 altinda kalsin)

# isim, kare sayisi, fps, dongu
ANIMS = [
    ("idle",   4, 4,  True),
    ("walk",   8, 10, True),
    ("run",    8, 14, True),
    ("action", 6, 14, False),   # bicak darbesi
    ("death",  6, 10, False),
]


def srgb(c):
    return tuple(pow(x, 2.2) for x in c[:3]) + (1.0,)


# ---------------------------------------------------------------- kiyafetler
# her parcanin rengi ve takilacak aksesuarlar
OUTFITS = {
    "komando": {
        "skin": (0.86, 0.68, 0.52), "top": (0.30, 0.36, 0.22), "pants": (0.33, 0.37, 0.24),
        "boots": (0.18, 0.13, 0.09), "gear": (0.55, 0.50, 0.36),
        "head": "beret", "head_color": (0.12, 0.40, 0.14),
        "items": ["webbing", "knife"],
    },
    "alman_er": {
        "skin": (0.88, 0.72, 0.58), "top": (0.43, 0.46, 0.39), "pants": (0.40, 0.43, 0.37),
        "boots": (0.08, 0.08, 0.08), "gear": (0.12, 0.10, 0.08),
        "head": "stahlhelm", "head_color": (0.36, 0.39, 0.33),
        "items": ["belt", "rifle", "canteen"],
    },
    "alman_subay": {
        "skin": (0.88, 0.72, 0.58), "top": (0.36, 0.39, 0.33), "pants": (0.30, 0.31, 0.29),
        "boots": (0.06, 0.06, 0.06), "gear": (0.35, 0.22, 0.12),
        "head": "cap", "head_color": (0.32, 0.35, 0.30),
        "items": ["belt", "holster"],
    },
    "alman_kis": {
        "skin": (0.88, 0.72, 0.58), "top": (0.88, 0.89, 0.90), "pants": (0.84, 0.85, 0.86),
        "boots": (0.10, 0.10, 0.10), "gear": (0.25, 0.22, 0.18),
        "head": "stahlhelm", "head_color": (0.92, 0.92, 0.93),
        "items": ["belt", "rifle"],
    },
}

# ---------------------------------------------------------------- iskelet
# isim: (bas, kuyruk, ebeveyn)   -- karakter -Y yonune (kameraya) bakar
BONES = {
    "root":        ((0, 0, 0.0),      (0, 0, 0.3),      None),
    "hips":        ((0, 0, 0.95),     (0, 0, 1.05),     "root"),
    "spine":       ((0, 0, 1.05),     (0, 0, 1.45),     "hips"),
    "head":        ((0, 0, 1.48),     (0, 0, 1.75),     "spine"),
    "upper_arm.L": ((0.23, 0, 1.42),  (0.23, 0, 1.13),  "spine"),
    "forearm.L":   ((0.23, 0, 1.13),  (0.23, 0, 0.86),  "upper_arm.L"),
    "upper_arm.R": ((-0.23, 0, 1.42), (-0.23, 0, 1.13), "spine"),
    "forearm.R":   ((-0.23, 0, 1.13), (-0.23, 0, 0.86), "upper_arm.R"),
    "thigh.L":     ((0.10, 0, 0.95),  (0.10, 0, 0.52),  "hips"),
    "shin.L":      ((0.10, 0, 0.52),  (0.10, 0, 0.08),  "thigh.L"),
    "thigh.R":     ((-0.10, 0, 0.95), (-0.10, 0, 0.52), "hips"),
    "shin.R":      ((-0.10, 0, 0.52), (-0.10, 0, 0.08), "thigh.R"),
}


def build_rig():
    data = bpy.data.armatures.new("AskerRig")
    rig = bpy.data.objects.new("AskerRig", data)
    bpy.context.scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    for name, (h, t, parent) in BONES.items():
        eb = data.edit_bones.new(name)
        eb.head = h
        eb.tail = t
        eb.roll = 0.0
    for name, (h, t, parent) in BONES.items():
        if parent:
            data.edit_bones[name].parent = data.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    for pb in rig.pose.bones:
        pb.rotation_mode = "XYZ"
    return rig


# ---------------------------------------------------------------- geometri
_materials = {}


def mat(name, color, rough=0.8):
    key = (name, tuple(color))
    if key in _materials:
        return _materials[key]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = srgb(color)
    bsdf.inputs["Roughness"].default_value = rough
    _materials[key] = m
    return m


def _obj_from_bm(name, bm, material):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = False
    me.materials.append(material)
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def box(name, size, material):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=Vector(size), verts=bm.verts)
    return _obj_from_bm(name, bm, material)


def cyl(name, r1, r2, depth, material, segs=8):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segs, radius1=r1, radius2=r2, depth=depth)
    return _obj_from_bm(name, bm, material)


def sphere(name, r, material, scale=(1, 1, 1), segs=10, rings=7):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segs, v_segments=rings, radius=r)
    bmesh.ops.scale(bm, vec=Vector(scale), verts=bm.verts)
    return _obj_from_bm(name, bm, material)


def attach(ob, rig, bone, loc, rot=(0, 0, 0)):
    """Parcayi kemige bagla (kati baglama: agirlik boyamaya gerek yok)."""
    bpy.context.view_layer.update()
    ob.location = loc
    ob.rotation_euler = rot
    ob.parent = rig
    ob.parent_type = "BONE"
    ob.parent_bone = bone
    pb = rig.pose.bones[bone]
    tail = rig.matrix_world @ pb.matrix @ Matrix.Translation((0, pb.bone.length, 0))
    ob.matrix_parent_inverse = tail.inverted()


def build_body(rig, o):
    skin = mat("skin", o["skin"], 0.6)
    top = mat("top", o["top"])
    pants = mat("pants", o["pants"])
    boots = mat("boots", o["boots"], 0.5)
    gear = mat("gear", o["gear"], 0.7)
    head_m = mat("headgear", o["head_color"], 0.6)
    parts = []

    def add(ob, bone, loc, rot=(0, 0, 0)):
        attach(ob, rig, bone, loc, rot)
        parts.append(ob)

    # govde
    add(box("pelvis", (0.34, 0.22, 0.2), pants), "hips", (0, 0, 0.98))
    add(box("torso", (0.40, 0.24, 0.44), top), "spine", (0, 0, 1.25))
    add(box("collar", (0.18, 0.16, 0.06), top), "spine", (0, 0, 1.48))
    add(cyl("neck", 0.05, 0.05, 0.08, skin), "head", (0, 0, 1.5))
    add(sphere("head", 0.12, skin, (0.95, 1.0, 1.1)), "head", (0, 0, 1.62))
    add(box("nose", (0.04, 0.04, 0.05), skin), "head", (0, -0.12, 1.61))
    # kollar
    for side, x in (("L", 0.23), ("R", -0.23)):
        add(sphere("shoulder" + side, 0.075, top), "upper_arm." + side, (x, 0, 1.42))
        add(cyl("uarm" + side, 0.062, 0.055, 0.3, top), "upper_arm." + side, (x, 0, 1.28))
        add(cyl("farm" + side, 0.055, 0.045, 0.24, top), "forearm." + side, (x, 0, 1.0))
        add(sphere("hand" + side, 0.05, skin), "forearm." + side, (x, 0, 0.84))
    # bacaklar
    for side, x in (("L", 0.10), ("R", -0.10)):
        add(cyl("thigh" + side, 0.085, 0.07, 0.44, pants), "thigh." + side, (x, 0, 0.74))
        add(cyl("shin" + side, 0.068, 0.062, 0.28, pants), "shin." + side, (x, 0, 0.34))
        add(cyl("boot" + side, 0.066, 0.07, 0.18, boots), "shin." + side, (x, 0, 0.12))
        add(box("toe" + side, (0.1, 0.16, 0.07), boots), "shin." + side, (x, -0.05, 0.035))

    # kafalik
    h = o["head"]
    if h == "stahlhelm":
        add(sphere("helmet", 0.15, head_m, (1.0, 1.05, 0.75), 12, 8), "head", (0, 0.01, 1.68))
        add(cyl("helmet_rim", 0.17, 0.165, 0.05, head_m, 12), "head", (0, 0.015, 1.6))
    elif h == "beret":
        add(sphere("beret", 0.14, head_m, (1.0, 1.0, 0.38), 12, 6), "head", (0.03, 0.0, 1.74), (0, math.radians(-14), 0))
        add(sphere("badge", 0.025, mat("badge", (0.8, 0.75, 0.5), 0.3)), "head", (-0.07, -0.1, 1.74))
    elif h == "cap":
        add(cyl("cap", 0.125, 0.14, 0.1, head_m, 12), "head", (0, 0, 1.73))
        add(box("visor", (0.18, 0.1, 0.02), mat("visor", (0.05, 0.05, 0.05), 0.3)), "head", (0, -0.12, 1.69))

    # ekipman
    items = o["items"]
    if "belt" in items or "webbing" in items:
        add(box("belt", (0.42, 0.26, 0.05), gear), "hips", (0, 0, 1.06))
    if "webbing" in items:
        add(box("strapL", (0.05, 0.26, 0.42), gear), "spine", (0.1, 0, 1.27))
        add(box("strapR", (0.05, 0.26, 0.42), gear), "spine", (-0.1, 0, 1.27))
        add(box("pack", (0.3, 0.12, 0.26), gear), "spine", (0, 0.17, 1.28))
    if "canteen" in items:
        add(cyl("canteen", 0.05, 0.05, 0.12, mat("canteen", (0.3, 0.3, 0.25))), "hips", (0.2, 0.06, 0.98))
    if "holster" in items:
        add(box("holster", (0.06, 0.1, 0.14), gear), "hips", (-0.21, 0, 0.98))
    if "rifle" in items:
        wood = mat("wood", (0.40, 0.25, 0.12), 0.6)
        steel = mat("steel", (0.12, 0.12, 0.13), 0.35)
        # omuza asili tufek (sirtta, capraz)
        add(box("rifle_stock", (0.06, 0.05, 0.75), wood), "spine", (0.05, 0.16, 1.2), (0, math.radians(28), 0))
        add(box("rifle_barrel", (0.025, 0.025, 0.4), steel), "spine", (-0.14, 0.17, 1.62), (0, math.radians(28), 0))
    if "knife" in items:
        add(box("knife", (0.02, 0.18, 0.04), mat("blade", (0.8, 0.8, 0.85), 0.2)), "forearm.R", (-0.23, -0.1, 0.83))
    return parts


# ---------------------------------------------------------------- animasyon
def reset_pose(rig):
    for pb in rig.pose.bones:
        pb.rotation_euler = (0, 0, 0)
        pb.location = (0, 0, 0)


def R(rig, bone, x=0.0, y=0.0, z=0.0):
    rig.pose.bones[bone].rotation_euler = (math.radians(x), math.radians(y), math.radians(z))


def pose(rig, anim, i, n):
    """Tek bir karenin pozunu kurar. Tum askerler bu fonksiyonu paylasir."""
    reset_pose(rig)
    t = i / n
    s = math.sin(t * math.tau)
    c = math.cos(t * math.tau)
    # kollar bastan hafif asagi-yana
    R(rig, "upper_arm.L", 0, 0, 0)
    R(rig, "upper_arm.R", 0, 0, 0)
    R(rig, "forearm.L", -10)
    R(rig, "forearm.R", -10)
    if anim == "idle":
        R(rig, "spine", 2 + 1.5 * s)
        R(rig, "head", -2 * s)
        R(rig, "upper_arm.L", 3 * s)
        R(rig, "upper_arm.R", 3 * s)
    elif anim in ("walk", "run"):
        a = 22 if anim == "walk" else 36
        lean = 4 if anim == "walk" else 14
        R(rig, "spine", lean)
        R(rig, "thigh.L", a * s)
        R(rig, "thigh.R", -a * s)
        R(rig, "shin.L", -max(0.0, -s) * a * 1.4 - 5)
        R(rig, "shin.R", -max(0.0, s) * a * 1.4 - 5)
        R(rig, "upper_arm.L", -a * 0.8 * s)
        R(rig, "upper_arm.R", a * 0.8 * s)
        R(rig, "forearm.L", -25 if anim == "run" else -12)
        R(rig, "forearm.R", -25 if anim == "run" else -12)
        rig.pose.bones["hips"].location = (0, abs(c) * (0.03 if anim == "walk" else 0.06), 0)
    elif anim == "action":
        # sag kolla ileri dogru bicak darbesi
        k = [0.0, 0.5, 1.0, 1.3, 0.7, 0.2][i]
        R(rig, "spine", 6 + 10 * k)
        R(rig, "upper_arm.R", -40 - 50 * k)
        R(rig, "forearm.R", -60 + 50 * k)
        R(rig, "upper_arm.L", -20 * k)
        R(rig, "thigh.L", -18 * k)
        R(rig, "shin.L", -10 * k)
        R(rig, "thigh.R", 10 * k)
    elif anim == "death":
        k = min(1.0, (i / (n - 1)) ** 1.6)
        R(rig, "root", 86 * k)            # sirt ustu yere duser
        R(rig, "thigh.L", -20 * k)
        R(rig, "shin.L", -30 * k)
        R(rig, "thigh.R", 10 * k)
        R(rig, "upper_arm.L", 0, 0, 50 * k)
        R(rig, "upper_arm.R", 0, 0, -60 * k)
        R(rig, "head", -20 * k)


# ---------------------------------------------------------------- sahne
def setup_scene():
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = SAMPLES
    sc.cycles.use_denoising = True
    sc.render.film_transparent = True
    sc.render.resolution_x = FRAME
    sc.render.resolution_y = FRAME
    sc.render.resolution_percentage = 100
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.view_settings.view_transform = "Standard"
    sc.render.film_transparent = True

    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.55, 0.6, 0.65, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.9
    sc.world = world

    sun_d = bpy.data.lights.new("sun", "SUN")
    sun_d.energy = 3.2
    sun_d.angle = math.radians(8)
    sun = bpy.data.objects.new("sun", sun_d)
    sun.rotation_euler = (math.radians(28), math.radians(-14), math.radians(-35))
    sc.collection.objects.link(sun)

    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = "ORTHO"
    cam_d.ortho_scale = ORTHO
    cam = bpy.data.objects.new("cam", cam_d)
    target = Vector((0, 0, 0.8))
    el = math.radians(ELEVATION)
    cam.location = target + Vector((0, -math.cos(el), math.sin(el))) * 10
    cam.rotation_euler = (math.radians(90) - el, 0, 0)
    sc.collection.objects.link(cam)
    sc.camera = cam

    # golge yakalayici zemin
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=3)
    ground = _obj_from_bm("ground", bm, mat("ground", (0.5, 0.5, 0.5)))
    ground.is_shadow_catcher = True
    return cam


def render_outfit(name, outfit, out_dir, quick=False):
    # once onceki kiyafeti temizle
    for ob in list(bpy.data.objects):
        if ob.type == "MESH" and ob.name != "ground":
            bpy.data.objects.remove(ob, do_unlink=True)
    rig = bpy.data.objects["AskerRig"]
    build_body(rig, outfit)
    sc = bpy.context.scene

    anims = ANIMS if not quick else [a for a in ANIMS if a[0] in ("idle", "walk")]
    n_slots = len(anims) * DIRS
    rows = (n_slots + SLOTS_PER_ROW - 1) // SLOTS_PER_ROW
    cols = SLOT * SLOTS_PER_ROW
    sheet = np.zeros((rows * FRAME, cols * FRAME, 4), dtype=np.float32)
    tmp = tempfile.mkdtemp()
    tmp_png = os.path.join(tmp, "f.png")

    layout = {"frame": FRAME, "cols": cols, "slot": SLOT, "slots_per_row": SLOTS_PER_ROW,
              "directions": DIRS, "filter": "linear", "display_px": 160, "anims": {}}
    slot = 0
    for anim, n, fps, loop in anims:
        layout["anims"][anim] = {"slot": slot, "frames": n, "fps": fps, "loop": loop}
        for d in range(DIRS):
            theta = d * math.tau / DIRS             # Godot acisi (y asagi)
            rig.rotation_euler = (0, 0, math.pi / 2 - theta)
            r = slot // SLOTS_PER_ROW
            c0 = (slot % SLOTS_PER_ROW) * SLOT
            for i in range(n):
                pose(rig, anim, i, n)
                bpy.context.view_layer.update()
                sc.render.filepath = tmp_png
                bpy.ops.render.render(write_still=True)
                img = bpy.data.images.load(tmp_png, check_existing=False)
                px = np.empty(FRAME * FRAME * 4, dtype=np.float32)
                img.pixels.foreach_get(px)
                bpy.data.images.remove(img)
                px = px.reshape(FRAME, FRAME, 4)[::-1]   # Blender alttan baslar
                sheet[r * FRAME:(r + 1) * FRAME, (c0 + i) * FRAME:(c0 + i + 1) * FRAME] = px
            slot += 1
        print(f"  {name}: {anim} tamam", flush=True)

    # ayaklarin karedeki konumu (pivot)
    rig.rotation_euler = (0, 0, 0)
    reset_pose(rig)
    bpy.context.view_layer.update()
    co = world_to_camera_view(sc, sc.camera, Vector((0, 0, 0)))
    layout["pivot"] = [round(co.x * FRAME, 1), round((1 - co.y) * FRAME, 1)]

    h, w = sheet.shape[:2]
    out_img = bpy.data.images.new(name + "_sheet", w, h, alpha=True)
    out_img.pixels.foreach_set(sheet[::-1].ravel())
    os.makedirs(out_dir, exist_ok=True)
    png = os.path.join(out_dir, f"{name}_sprite_sheet.png")
    out_img.filepath_raw = png
    out_img.file_format = "PNG"
    out_img.save()
    with open(os.path.join(out_dir, f"{name}_sprite_sheet.json"), "w") as f:
        json.dump(layout, f, indent=1)
    print(f"YAZILDI {png} ({w}x{h})")


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = "assets/sprites"
    names = list(OUTFITS.keys())
    quick = False
    i = 0
    while i < len(argv):
        if argv[i] == "--out":
            out = argv[i + 1]; i += 1
        elif argv[i] == "--outfits":
            names = argv[i + 1].split(","); i += 1
        elif argv[i] == "--quick":
            quick = True
        i += 1
    bpy.ops.wm.read_factory_settings(use_empty=True)
    setup_scene()
    build_rig()
    for n in names:
        render_outfit(n, OUTFITS[n], out, quick)


if __name__ == "__main__":
    main()
