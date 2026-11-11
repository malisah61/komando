"""
DENEME: Quaternius Universal Animation Library (CC0) ile asker sprite'i.

Hazir insan hareketleri (motion capture tabanli) + bizim kiyafet/aksesuarlarimiz.
    blender -b --python tools/blender/asker2.py -- --out /tmp/deneme --outfits alman_er [--quick]

asker.py ile ayni cikti duzenini uretir (8 yon, slot duzeni, json), yani oyun degisiklik gerektirmez.
"""
import bpy
import json
import math
import os
import sys
import tempfile
import numpy as np
from mathutils import Matrix, Vector
from bpy_extras.object_utils import world_to_camera_view

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import asker as A   # sahne, kamera, malzeme ve parca yardimcilari

GLB = "kaynak/ual/AnimationLibrary_Godot_Standard.glb"

# oyun adi -> (UAL hareketi, kare sayisi, fps, dongu)
ANIMS = [
    ("idle",   "Idle_Loop_Rig",        6, 6,  True),
    ("walk",   "Walk_Loop_Rig",        8, 10, True),
    ("run",    "Sprint_Loop_Rig",      8, 14, True),
    ("crouch", "Crouch_Fwd_Loop_Rig",  8, 9,  True),
    ("action", "Punch_Jab_Rig",        6, 14, False),   # bicak darbesi
    ("plant",  "Fixing_Kneeling_Rig",  8, 8,  True),    # patlayici kurma
    ("shoot",  "Pistol_Shoot_Rig",     5, 14, False),   # ates
    ("death",  "Death01_Rig",          8, 10, False),
]

# kemik esleme: Quaternius (Rigify DEF-) -> aksesuar baglama noktalari
BONE = {"head": "DEF-head", "spine": "DEF-spine.003", "hips": "DEF-hips",
        "hand_r": "DEF-hand.R", "hand_l": "DEF-hand.L"}


def load_ual():
    bpy.ops.import_scene.gltf(filepath=os.path.abspath(GLB))
    for ob in list(bpy.data.objects):
        if ob.type == "MESH" and ob.name.startswith("Icosphere"):
            bpy.data.objects.remove(ob, do_unlink=True)
    rig = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
    body = [o for o in bpy.data.objects if o.type == "MESH" and o.parent == rig][0]
    # hareket verisi nesne donusunu de anahtarliyor olabilir: yonu bir ust bos nesneyle cevir
    pivot = bpy.data.objects.new("YonPivot", None)
    bpy.context.scene.collection.objects.link(pivot)
    rig.parent = pivot
    return rig, body


def paint_body(body, o):
    """Govdeyi kemik agirliklarina gore boya: ust beden, pantolon, bot, ten."""
    mats = {
        "skin": A.mat("skin2", o["skin"], 0.6),
        "top": A.mat("top2", o["top"], 0.85),
        "pants": A.mat("pants2", o["pants"], 0.85),
        "boots": A.mat("boots2", o["boots"], 0.45),
    }
    body.data.materials.clear()
    order = ["skin", "top", "pants", "boots"]
    for k in order:
        body.data.materials.append(mats[k])
    gname = {g.index: g.name for g in body.vertex_groups}

    def part(bone):
        b = bone.lower()
        if "head" in b or "neck" in b or "hand" in b or "f_" in b or "thumb" in b:
            return "skin"
        if "foot" in b or "toe" in b:
            return "boots"
        if "shin" in b:
            return "pants" if True else "boots"
        if "thigh" in b or "hips" in b:
            return "pants"
        return "top"

    vpart = []
    for v in body.data.vertices:
        best, bw = "top", -1.0
        for g in v.groups:
            if g.weight > bw:
                bw, best = g.weight, part(gname.get(g.group, ""))
        vpart.append(best)
    for p in body.data.polygons:
        votes = {}
        for vi in p.vertices:
            votes[vpart[vi]] = votes.get(vpart[vi], 0) + 1
        k = max(votes, key=votes.get)
        # botlar: incik altinin alt kismi
        p.material_index = order.index(k)
        p.use_smooth = True


def add_gear(rig, o):
    """Kiyafet aksesuarlarini ilgili kemiklere bagla (asker.py ile ayni kiyafet sozlugu)."""
    head_m = A.mat("headgear2", o["head_color"], 0.6)
    gear = A.mat("gear2", o["gear"], 0.7)
    hb = rig.pose.bones[BONE["head"]]
    hp = rig.matrix_world @ hb.head
    parts = []

    def att(ob, key, loc, rot=(0, 0, 0)):
        A.attach(ob, rig, BONE[key], loc, rot)
        parts.append(ob)

    top_z = hp.z + 0.20
    h = o["head"]
    if h == "stahlhelm":
        att(A.sphere("helmet", 0.15, head_m, (1.0, 1.05, 0.75), 12, 8), "head", (hp.x, hp.y + 0.01, top_z - 0.02))
        att(A.cyl("helmet_rim", 0.17, 0.165, 0.05, head_m, 12), "head", (hp.x, hp.y + 0.015, top_z - 0.09))
    elif h == "beret":
        att(A.sphere("beret", 0.13, head_m, (1.0, 1.0, 0.38), 12, 6), "head", (hp.x + 0.03, hp.y, top_z), (0, math.radians(-14), 0))
    elif h == "cap":
        att(A.cyl("cap", 0.12, 0.135, 0.1, head_m, 12), "head", (hp.x, hp.y, top_z))
        att(A.box("visor", (0.17, 0.1, 0.02), A.mat("visor2", (0.05, 0.05, 0.05), 0.3)), "head", (hp.x, hp.y - 0.11, top_z - 0.05))
    sb = rig.pose.bones[BONE["spine"]]
    sp = rig.matrix_world @ sb.head
    items = o["items"]
    if "webbing" in items:
        att(A.box("pack", (0.3, 0.14, 0.3), gear), "spine", (sp.x, sp.y + 0.17, sp.z))
    if "rifle" in items:
        wood = A.mat("wood2", (0.40, 0.25, 0.12), 0.6)
        att(A.box("rifle", (0.05, 0.05, 0.85), wood), "spine", (sp.x + 0.05, sp.y + 0.16, sp.z - 0.05), (0, math.radians(28), 0))
    if "canteen" in items:
        hpb = rig.matrix_world @ rig.pose.bones[BONE["hips"]].head
        att(A.cyl("canteen", 0.05, 0.05, 0.12, A.mat("canteen2", (0.3, 0.3, 0.25))), "hips", (hpb.x + 0.18, hpb.y + 0.05, hpb.z - 0.02))
    if "knife" in items:
        hr = rig.matrix_world @ rig.pose.bones[BONE["hand_r"]].tail
        att(A.box("knife", (0.02, 0.04, 0.2), A.mat("blade2", (0.8, 0.8, 0.85), 0.2)), "hand_r", (hr.x, hr.y, hr.z - 0.08))
    return parts


def render_outfit(name, o, out_dir, quick=False):
    rig, body = load_ual()
    rig.animation_data_create()
    rig.animation_data.action = None
    for pb in rig.pose.bones:
        pb.location = (0, 0, 0)
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.rotation_euler = (0, 0, 0)
    bpy.context.view_layer.update()
    paint_body(body, o)
    add_gear(rig, o)
    sc = bpy.context.scene
    anims = ANIMS if not quick else [a for a in ANIMS if a[0] in ("idle", "walk", "crouch", "plant")]
    n_slots = len(anims) * A.DIRS
    rows = (n_slots + A.SLOTS_PER_ROW - 1) // A.SLOTS_PER_ROW
    cols = A.SLOT * A.SLOTS_PER_ROW
    F = A.FRAME
    sheet = np.zeros((rows * F, cols * F, 4), dtype=np.float32)
    tmp_png = os.path.join(tempfile.mkdtemp(), "f.png")
    layout = {"frame": F, "cols": cols, "slot": A.SLOT, "slots_per_row": A.SLOTS_PER_ROW,
              "directions": A.DIRS, "filter": "linear", "display_px": 160, "anims": {}}
    slot = 0
    for anim, act_name, n, fps, loop in anims:
        act = bpy.data.actions[act_name]
        rig.animation_data.action = act
        f0, f1 = act.frame_range
        span = (f1 - f0) if loop else (f1 - f0)
        layout["anims"][anim] = {"slot": slot, "frames": n, "fps": fps, "loop": loop}
        for d in range(A.DIRS):
            theta = d * math.tau / A.DIRS
            rig.parent.rotation_euler = (0, 0, math.pi / 2 - theta + YAW_FIX)
            r = slot // A.SLOTS_PER_ROW
            c0 = (slot % A.SLOTS_PER_ROW) * A.SLOT
            for i in range(n):
                t = i / n if loop else i / max(1, n - 1)
                sc.frame_set(int(round(f0 + span * t)))
                bpy.context.view_layer.update()
                sc.render.filepath = tmp_png
                bpy.ops.render.render(write_still=True)
                img = bpy.data.images.load(tmp_png, check_existing=False)
                px = np.empty(F * F * 4, dtype=np.float32)
                img.pixels.foreach_get(px)
                bpy.data.images.remove(img)
                sheet[r * F:(r + 1) * F, (c0 + i) * F:(c0 + i + 1) * F] = px.reshape(F, F, 4)[::-1]
            slot += 1
        print(f"  {name}: {anim} tamam", flush=True)
    rig.animation_data.action = None
    rig.parent.rotation_euler = (0, 0, 0)
    bpy.context.view_layer.update()
    co = world_to_camera_view(sc, sc.camera, Vector((0, 0, 0)))
    layout["pivot"] = [round(co.x * F, 1), round((1 - co.y) * F, 1)]
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
    print("YAZILDI", png, flush=True)


YAW_FIX = 0.0     # karakterin dinlenme yonu kameraya bakmiyorsa duzeltme (radyan)


def main():
    global YAW_FIX
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = "/tmp/deneme"
    names = list(A.OUTFITS.keys())
    quick = "--quick" in argv
    if "--out" in argv:
        out = argv[argv.index("--out") + 1]
    if "--outfits" in argv:
        names = argv[argv.index("--outfits") + 1].split(",")
    if "--yaw" in argv:
        YAW_FIX = math.radians(float(argv[argv.index("--yaw") + 1]))
    for n in names:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        A._materials.clear()
        A.setup_scene()
        render_outfit(n, A.OUTFITS[n], out, quick)


if __name__ == "__main__":
    main()
