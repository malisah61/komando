"""
Komando - Harita render hatti (Blender 4.2).

Bolum dosyasini (levels/*.json) okur, 3D sahneyi kurar ve oyunun egik (oblik) bakis
acisiyla render alir. 1 Blender birimi = 1 oyun pikseli. Yukseklik z, ekranda z*SHEAR
kadar yukari kayar (oyundaki yukseltilmis cizimle ayni geometri).

    blender -b --python tools/blender/harita.py -- levels/bolum0.json [--samples 32] [--quick]

Cikti (ham, kayipsiz): levels/<bolum>_art/v<aci>/   (v0..v3 hep ayni duzen)
    ground_X_Y.png zemin karolari (yollar, camur, su, kopruler, bina ici zeminler, nesnelerin golgeleri)
    objects_N.png  nesne atlasi (duvarlar, agaclar, kum torbalari, araclar ...)
    roofs_N.png    cati atlasi (bina icine girince seffaflasir)
    manifest.json  her parcanin atlas bolgesi, dunyadaki yeri ve hangi engele ait oldugu
Sonraki adim: python3 tools/varlik/hat.py sikistir levels/<bolum>_art/v<aci>
(WebP'ye cevirir, ayarlar tools/varlik_ayarlari.json). Hat: render -> sikistir -> Godot import -> export.
"""
import bpy
import bmesh
import json
import math
import os
import random
import sys
import numpy as np
from mathutils import Matrix, Vector

SHEAR = 1.0
WALL = 12.0
DOOR = 60.0
WALL_H = 50.0
SAMPLES = 64
SCALE = 2            # oyun pikseli basina render pikseli (yakinlastirinca da net)
TILE = 2048          # zemin resmi bu boyutta parcalara bolunur (telefon doku siniri)
PAGE = 4096          # atlas sayfasi en buyuk boyutu
TEX_DIR = "assets/textures"
PAINT = True         # Kuwahara "yagli boya" efekti
VIEW = 0             # bakis acisi: 0..3 (her biri 90 derece; Commandos 2'deki 4 yonlu kamera)


# ================================================================ bakis acisi
def view_xy(gx, gy, W, H, k):
    """oyun (dunya) koordinati -> k. bakis acisindaki ekran koordinati.
    Oyun tarafiyla ayni formul: v = (g - c).rotated(-k*90) + c'"""
    x, y = gx - W / 2.0, gy - H / 2.0
    a = -k * math.pi / 2.0
    ca, sa = round(math.cos(a)), round(math.sin(a))
    rx, ry = x * ca - y * sa, x * sa + y * ca
    W2, H2 = (H, W) if k % 2 else (W, H)
    return rx + W2 / 2.0, ry + H2 / 2.0


def view_bbox(bb, W, H, k):
    xs, ys = [], []
    for (x, y) in ((bb[0], bb[1]), (bb[2], bb[1]), (bb[2], bb[3]), (bb[0], bb[3])):
        vx, vy = view_xy(x, y, W, H, k)
        xs.append(vx); ys.append(vy)
    return [min(xs), min(ys), max(xs), max(ys)]


def rotate_scene(W, H, k):
    """tum sahneyi (egik projeksiyondan once) bakis acisina dondur"""
    for ob in bpy.data.objects:
        if ob.type != "MESH":
            continue
        me = ob.data
        for v in me.vertices:
            vx, vy = view_xy(v.co.x, -v.co.y, W, H, k)
            v.co.x, v.co.y = vx, -vy
        me.update()


# ================================================================ yardimcilar
def srgb(c):
    return tuple(pow(max(0.0, x), 2.2) for x in c[:3]) + (1.0,)


def B(x, y, z=0.0):
    """oyun koordinati -> Blender (y ters)"""
    return Vector((x, -y, z))


_mats = {}


def mat(name, c1, c2=None, rough=0.8, scale=0.03, bump=0.3, kind="noise", metal=0.0):
    key = name
    if key in _mats:
        return _mats[key]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf = nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    tc = nodes.new("ShaderNodeTexCoord")
    if c2 is None:
        bsdf.inputs["Base Color"].default_value = srgb(c1)
    else:
        if kind == "wave":          # kiremit / tahta sirasi
            tex = nodes.new("ShaderNodeTexWave")
            tex.inputs["Scale"].default_value = scale
            tex.inputs["Distortion"].default_value = 2.0
            tex.bands_direction = "Y"
        elif kind == "brick":
            tex = nodes.new("ShaderNodeTexBrick")
            tex.inputs["Scale"].default_value = scale
            tex.inputs["Color1"].default_value = srgb(c1)
            tex.inputs["Color2"].default_value = srgb(c2)
            tex.inputs["Mortar"].default_value = srgb([x * 0.7 for x in c2])
        else:
            tex = nodes.new("ShaderNodeTexNoise")
            tex.inputs["Scale"].default_value = scale
            tex.inputs["Detail"].default_value = 6.0
            tex.inputs["Roughness"].default_value = 0.6
        links.new(tc.outputs["Object"], tex.inputs["Vector"])
        if kind == "brick":
            links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        else:
            mix = nodes.new("ShaderNodeMixRGB")
            mix.inputs["Color1"].default_value = srgb(c1)
            mix.inputs["Color2"].default_value = srgb(c2)
            links.new(tex.outputs["Fac"], mix.inputs["Fac"])
            links.new(mix.outputs["Color"], bsdf.inputs["Base Color"])
        if bump > 0:
            bn = nodes.new("ShaderNodeBump")
            bn.inputs["Strength"].default_value = bump
            src = tex.outputs["Fac"] if "Fac" in tex.outputs else tex.outputs["Color"]
            links.new(src, bn.inputs["Height"])
            links.new(bn.outputs["Normal"], bsdf.inputs["Normal"])
    _mats[key] = m
    return m


def tex_mat(name, slot, tile, fallback, tint=None, rough=0.85, bump=0.4, big_var=0.0, desat=None):
    """Poly Haven dokusu (kutu projeksiyonu, UV gerekmez). Doku yoksa yedek malzeme."""
    diff = os.path.join(TEX_DIR, slot, "diff.jpg")
    if not os.path.exists(diff):
        return fallback
    if name in _mats:
        return _mats[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nodes, links = m.node_tree.nodes, m.node_tree.links
    bsdf = nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = rough
    tc = nodes.new("ShaderNodeTexCoord")
    mp = nodes.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (1.0 / tile, 1.0 / tile, 1.0 / tile)
    links.new(tc.outputs["Object"], mp.inputs["Vector"])
    it = nodes.new("ShaderNodeTexImage")
    it.image = bpy.data.images.load(os.path.abspath(diff), check_existing=True)
    it.projection = "BOX"
    it.projection_blend = 0.25
    links.new(mp.outputs["Vector"], it.inputs["Vector"])
    col = it.outputs["Color"]
    if desat is not None:
        hsv = nodes.new("ShaderNodeHueSaturation")
        hsv.inputs["Saturation"].default_value = desat
        links.new(col, hsv.inputs["Color"])
        col = hsv.outputs["Color"]
    if tint is not None:
        mul = nodes.new("ShaderNodeMixRGB")
        mul.blend_type = "MULTIPLY"
        mul.inputs["Fac"].default_value = 1.0
        mul.inputs["Color2"].default_value = srgb(tint)
        links.new(col, mul.inputs["Color1"])
        col = mul.outputs["Color"]
    if big_var > 0:
        # buyuk olcekli renk dalgalanmasi: doku tekrari belli olmasin
        nz = nodes.new("ShaderNodeTexNoise")
        nz.inputs["Scale"].default_value = 0.004
        links.new(tc.outputs["Object"], nz.inputs["Vector"])
        ramp = nodes.new("ShaderNodeValToRGB")
        ramp.color_ramp.elements[0].color = (0.75, 0.78, 0.6, 1)
        ramp.color_ramp.elements[1].color = (1.15, 1.08, 0.9, 1)
        links.new(nz.outputs["Fac"], ramp.inputs["Fac"])
        mv = nodes.new("ShaderNodeMixRGB")
        mv.blend_type = "MULTIPLY"
        mv.inputs["Fac"].default_value = big_var
        links.new(col, mv.inputs["Color1"])
        links.new(ramp.outputs["Color"], mv.inputs["Color2"])
        col = mv.outputs["Color"]
    links.new(col, bsdf.inputs["Base Color"])
    rp = os.path.join(TEX_DIR, slot, "rough.jpg")
    if os.path.exists(rp):
        ri = nodes.new("ShaderNodeTexImage")
        ri.image = bpy.data.images.load(os.path.abspath(rp), check_existing=True)
        ri.image.colorspace_settings.name = "Non-Color"
        ri.projection = "BOX"
        ri.projection_blend = 0.25
        links.new(mp.outputs["Vector"], ri.inputs["Vector"])
        links.new(ri.outputs["Color"], bsdf.inputs["Roughness"])
    if bump > 0:
        bn = nodes.new("ShaderNodeBump")
        bn.inputs["Strength"].default_value = bump
        bn.inputs["Distance"].default_value = 2.0
        links.new(it.outputs["Color"], bn.inputs["Height"])
        links.new(bn.outputs["Normal"], bsdf.inputs["Normal"])
    _mats[name] = m
    return m


def grass_mat():
    """iki olcekli gurultu: buyuk lekeler (kuru/yesil) + ince cimen dokusu"""
    if "grass" in _mats:
        return _mats["grass"]
    m = bpy.data.materials.new("grass")
    m.use_nodes = True
    nodes, links = m.node_tree.nodes, m.node_tree.links
    bsdf = nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.95
    tc = nodes.new("ShaderNodeTexCoord")
    big = nodes.new("ShaderNodeTexNoise")
    big.inputs["Scale"].default_value = 0.004
    big.inputs["Detail"].default_value = 4
    fine = nodes.new("ShaderNodeTexNoise")
    fine.inputs["Scale"].default_value = 0.35
    fine.inputs["Detail"].default_value = 8
    links.new(tc.outputs["Object"], big.inputs["Vector"])
    links.new(tc.outputs["Object"], fine.inputs["Vector"])
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.35
    ramp.color_ramp.elements[0].color = srgb((0.30, 0.40, 0.19))
    ramp.color_ramp.elements[1].position = 0.7
    ramp.color_ramp.elements[1].color = srgb((0.44, 0.47, 0.24))
    links.new(big.outputs["Fac"], ramp.inputs["Fac"])
    mix = nodes.new("ShaderNodeMixRGB")
    mix.blend_type = "MULTIPLY"
    mix.inputs["Fac"].default_value = 0.35
    links.new(ramp.outputs["Color"], mix.inputs["Color1"])
    links.new(fine.outputs["Color"], mix.inputs["Color2"])
    links.new(mix.outputs["Color"], bsdf.inputs["Base Color"])
    bn = nodes.new("ShaderNodeBump")
    bn.inputs["Strength"].default_value = 0.5
    links.new(fine.outputs["Fac"], bn.inputs["Height"])
    links.new(bn.outputs["Normal"], bsdf.inputs["Normal"])
    _mats["grass"] = m
    return m


def obj_from_bm(name, bm, material, coll):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    if isinstance(material, list):
        for mm in material:
            me.materials.append(mm)
    else:
        me.materials.append(material)
    ob = bpy.data.objects.new(name, me)
    coll.objects.link(ob)
    return ob


def flat_poly(name, pts, z, material, coll):
    bm = bmesh.new()
    vs = [bm.verts.new(B(p[0], p[1], z)) for p in pts]
    if len(vs) >= 3:
        f = bm.faces.new(vs)
        if f.normal.z < 0:
            f.normal_flip()
    return obj_from_bm(name, bm, material, coll)


def prism(name, pts, h, material, coll, z0=0.0, top_mat=None, jitter=0.0, rng=None, bevel=0.0):
    bm = bmesh.new()
    vs = [bm.verts.new(B(p[0], p[1], z0)) for p in pts]
    f = bm.faces.new(vs)
    if f.normal.z > 0:
        f.normal_flip()
    ext = bmesh.ops.extrude_face_region(bm, geom=[f])
    top = [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, vec=Vector((0, 0, h)), verts=top)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    if bevel > 0:
        bmesh.ops.bevel(bm, geom=list(bm.edges), offset=bevel, segments=2, affect="EDGES", profile=0.5)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    if jitter > 0 and rng:
        bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=2, use_grid_fill=True)
        for v in bm.verts:
            if v.co.z > z0 + 0.5:
                v.co += Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(-1, 1))) * jitter
    mats = [material] if top_mat is None else [material, top_mat]
    if top_mat is not None:
        for face in bm.faces:
            if face.normal.z > 0.7:
                face.material_index = 1
    return obj_from_bm(name, bm, mats, coll)


def blob(name, center, r, h, material, coll, rng, sub=2, squash=0.8, rough=0.18):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=1.0)
    for v in bm.verts:
        n = v.co.normalized()
        k = 1.0 + rng.uniform(-rough, rough)
        v.co = Vector((n.x * r * k, n.y * r * k, n.z * r * squash * k))
    bmesh.ops.translate(bm, vec=B(center[0], center[1], h), verts=bm.verts)
    for f in bm.faces:
        f.smooth = True
    return obj_from_bm(name, bm, material, coll)


def box(name, x, y, z, sx, sy, sz, material, coll, rot=0.0):
    """oyun koordinatinda merkez (x,y), taban z"""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=Vector((sx, sy, sz)), verts=bm.verts)
    bmesh.ops.rotate(bm, cent=Vector(), matrix=Matrix.Rotation(rot, 3, "Z"), verts=bm.verts)
    bmesh.ops.translate(bm, vec=B(x, y, z + sz / 2), verts=bm.verts)
    return obj_from_bm(name, bm, material, coll)


def cyl(name, x, y, z, r, h, material, coll, segs=10, axis="Z", caps=True):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=caps, segments=segs, radius1=r, radius2=r, depth=h)
    if axis in ("X", "Y"):
        bmesh.ops.rotate(bm, cent=Vector(), matrix=Matrix.Rotation(math.pi / 2, 3, "Y" if axis == "X" else "X"), verts=bm.verts)
        bmesh.ops.translate(bm, vec=B(x, y, z), verts=bm.verts)
    else:
        bmesh.ops.translate(bm, vec=B(x, y, z + h / 2), verts=bm.verts)
    return obj_from_bm(name, bm, material, coll)


def join(objs, name):
    if len(objs) == 1:
        objs[0].name = name
        return objs[0]
    ctx = bpy.context
    for o in ctx.view_layer.objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    ctx.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    objs[0].name = name
    return objs[0]


def poly_bbox(pts):
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    return min(xs), min(ys), max(xs), max(ys)


def offset_poly(pts, d):
    """basit miter ofset (puruzsuz cokgenler icin yeterli)"""
    n = len(pts)
    # saat yonu mu?
    area = sum(pts[i][0] * pts[(i + 1) % n][1] - pts[(i + 1) % n][0] * pts[i][1] for i in range(n))
    sgn = 1 if area > 0 else -1
    out = []
    for i in range(n):
        p0, p1, p2 = Vector(pts[i - 1]), Vector(pts[i]), Vector(pts[(i + 1) % n])
        e1 = (p1 - p0).normalized()
        e2 = (p2 - p1).normalized()
        n1 = Vector((e1.y, -e1.x)) * sgn
        n2 = Vector((e2.y, -e2.x)) * sgn
        nm = (n1 + n2)
        nm = nm.normalized() if nm.length > 1e-6 else n1
        out.append([p1.x - nm.x * d, p1.y - nm.y * d])
    return out


def circle_pts(c, r, n=12):
    return [[c[0] + math.cos(math.tau * i / n) * r, c[1] + math.sin(math.tau * i / n) * r] for i in range(n)]


def building_walls(rect, door):
    x0, y0, w, h = rect
    x1, y1 = x0 + w, y0 + h
    cx, cy = x0 + w / 2, y0 + h / 2
    hd = DOOR / 2
    walls = []
    if door == "N":
        walls += [(x0, y0, cx - hd - x0, WALL), (cx + hd, y0, x1 - cx - hd, WALL)]
    else:
        walls.append((x0, y0, w, WALL))
    if door == "S":
        walls += [(x0, y1 - WALL, cx - hd - x0, WALL), (cx + hd, y1 - WALL, x1 - cx - hd, WALL)]
    else:
        walls.append((x0, y1 - WALL, w, WALL))
    if door == "W":
        walls += [(x0, y0 + WALL, WALL, cy - hd - y0 - WALL), (x0, cy + hd, WALL, y1 - WALL - cy - hd)]
    else:
        walls.append((x0, y0 + WALL, WALL, h - WALL * 2))
    if door == "E":
        walls += [(x1 - WALL, y0 + WALL, WALL, cy - hd - y0 - WALL), (x1 - WALL, cy + hd, WALL, y1 - WALL - cy - hd)]
    else:
        walls.append((x1 - WALL, y0 + WALL, WALL, h - WALL * 2))
    return walls   # level.gd ile ayni sira ve olculer


# ================================================================ sahne kurulumu
def build(level, quick=False):
    W, H = level["size"]
    rng = random.Random(7)
    sc = bpy.context.scene
    g_coll = bpy.data.collections.new("Zemin")
    o_coll = bpy.data.collections.new("Nesneler")
    r_coll = bpy.data.collections.new("Catilar")
    for c in (g_coll, o_coll, r_coll):
        sc.collection.children.link(c)

    P = {
        "dirt": mat("dirt", (0.55, 0.45, 0.31), (0.42, 0.34, 0.23), 0.95, 0.05, 0.4),
        "mud": mat("mud", (0.30, 0.22, 0.14), (0.22, 0.16, 0.10), 0.45, 0.06, 0.5),
        "water": mat("water", (0.10, 0.22, 0.27), (0.14, 0.30, 0.34), 0.08, 0.02, 0.15),
        "bank": mat("bank", (0.36, 0.30, 0.20), (0.28, 0.24, 0.16), 0.9, 0.08, 0.4),
        "plank": mat("plank", (0.45, 0.32, 0.18), (0.30, 0.21, 0.12), 0.7, 0.08, 0.3, "wave"),
        "floor": mat("floor", (0.48, 0.36, 0.22), (0.36, 0.26, 0.15), 0.7, 0.06, 0.2, "wave"),
        "plaster": mat("plaster", (0.86, 0.80, 0.68), (0.72, 0.66, 0.54), 0.9, 0.04, 0.25),
        "stone": mat("stone", (0.62, 0.60, 0.55), (0.45, 0.43, 0.40), 0.9, 0.12, 0.6, "brick"),
        "hedge": mat("hedge", (0.17, 0.31, 0.11), (0.10, 0.21, 0.07), 0.9, 0.15, 0.8),
        "leaf": mat("leaf", (0.20, 0.36, 0.13), (0.11, 0.24, 0.08), 0.9, 0.12, 0.8),
        "leaf2": mat("leaf2", (0.27, 0.40, 0.15), (0.16, 0.29, 0.09), 0.9, 0.12, 0.8),
        "bark": mat("bark", (0.30, 0.22, 0.14)),
        "sand": mat("sand", (0.74, 0.66, 0.46), (0.60, 0.53, 0.36), 0.95, 0.25, 0.5),
        "wood": mat("wood", (0.55, 0.40, 0.22), (0.40, 0.28, 0.15), 0.7, 0.1, 0.3, "wave"),
        "canvas": mat("canvas", (0.45, 0.46, 0.33), (0.36, 0.38, 0.26), 0.9, 0.05, 0.2),
        "olive": mat("olive", (0.30, 0.33, 0.24), (0.24, 0.27, 0.19), 0.6, 0.03, 0.1),
        "grey": mat("grey", (0.38, 0.40, 0.36), (0.30, 0.32, 0.29), 0.55, 0.03, 0.1, metal=0.3),
        "tire": mat("tire", (0.06, 0.06, 0.06)),
        "rock": mat("rock", (0.55, 0.54, 0.50), (0.38, 0.37, 0.34), 0.9, 0.08, 0.6),
        "pebble": mat("pebble", (0.5, 0.49, 0.45), (0.4, 0.39, 0.36)),
        "flower": mat("flower", (0.85, 0.80, 0.45)),
        "tuft": mat("tuft", (0.22, 0.33, 0.12), (0.30, 0.40, 0.16), 0.95, 0.3, 0.3),
    }
    M = dict(P)
    M["dirt"] = tex_mat("t_dirt", "dirt", 220, P["dirt"], (1.05, 0.95, 0.8), 0.95, 0.6, 0.3)
    M["mud"] = tex_mat("t_mud", "mud", 160, P["mud"], (0.8, 0.7, 0.6), 0.5, 0.6)
    M["bank"] = tex_mat("t_bank", "mud", 120, P["bank"], (0.95, 0.85, 0.7), 0.9, 0.5)
    M["plank"] = tex_mat("t_plank", "planks", 90, P["plank"], (0.9, 0.8, 0.7), 0.7, 0.4)
    M["floor"] = tex_mat("t_floor", "planks", 70, P["floor"], None, 0.7, 0.3)
    M["plaster"] = tex_mat("t_plaster", "plaster", 90, P["plaster"], (1.0, 0.96, 0.88), 0.9, 0.3)
    M["stone"] = tex_mat("t_stone", "stone", 70, P["stone"], None, 0.9, 0.6)
    M["wood"] = tex_mat("t_wood", "planks", 60, P["wood"], (0.95, 0.85, 0.75), 0.7, 0.4)
    M["bark"] = tex_mat("t_bark", "bark", 40, P["bark"], None, 0.9, 0.6)
    M["rock"] = tex_mat("t_rock", "rock", 60, P["rock"], None, 0.9, 0.7)
    M["olive"] = tex_mat("t_olive", "metal", 80, P["olive"], (0.55, 0.62, 0.42), 0.6, 0.3)
    M["grey"] = tex_mat("t_grey", "metal", 80, P["grey"], (0.6, 0.62, 0.58), 0.55, 0.3)
    M["beam"] = tex_mat("t_beam", "planks", 40, mat("beam", (0.24, 0.16, 0.10)), (0.45, 0.35, 0.28), 0.7, 0.3)
    theme = level.get("theme", "")
    snow = mat("kar", (0.74, 0.77, 0.83), (0.60, 0.65, 0.74), 0.7, 0.012, 0.45)
    M["snow"] = snow
    M["beton"] = tex_mat("t_beton", "stone", 120, mat("beton", (0.55, 0.55, 0.53), (0.45, 0.45, 0.44), 0.85, 0.05, 0.2),
                         (0.75, 0.75, 0.74), 0.85, 0.2, desat=0.1)
    if theme == "kar":
        # kis: zemin kar, yollar camurlu kar, agac/cali karla kapli
        M["dirt"] = tex_mat("t_dirt_kar", "dirt", 220, P["dirt"], (1.35, 1.35, 1.45), 0.9, 0.4, 0.2, desat=0.3)
        M["leaf"] = mat("leaf_kar", (0.70, 0.74, 0.78), (0.16, 0.27, 0.17), 0.8, 0.05, 0.6)
        M["leaf2"] = mat("leaf2_kar", (0.66, 0.70, 0.75), (0.13, 0.22, 0.13), 0.8, 0.05, 0.6)
        M["hedge"] = mat("hedge_kar", (0.66, 0.70, 0.75), (0.15, 0.25, 0.14), 0.8, 0.07, 0.7)
        M["tuft"] = mat("tuft_kar", (0.82, 0.85, 0.9), (0.6, 0.65, 0.7))

    # ------------------------------------------------ zemin
    ground_m = snow if theme == "kar" else tex_mat("t_grass", "grass", 260, grass_mat(), (0.78, 1.0, 0.68), 0.95, 0.5, 0.9)
    flat_poly("cimen", [[0, 0], [W, 0], [W, H], [0, H]], 0.0, ground_m, g_coll)
    for ri, r in enumerate(level.get("roads", [])):
        x, y, w, h = r
        # ust uste binen yollar ayni yukseklikte olmasin (golge hatasi)
        flat_poly("yol", [[x, y], [x + w, y], [x + w, y + h], [x, y + h]], 0.2 + ri * 0.02, M["dirt"], g_coll)
    puddle = mat("puddle", (0.36, 0.40, 0.42), None, 0.04)
    rut = tex_mat("t_rut", "dirt", 220, mat("rut", (0.42, 0.34, 0.23)), (0.86, 0.78, 0.68), 0.9, 0.5)
    for ri, r in enumerate(level.get("roads", [])):
        x, y, w, h = r
        if min(w, h) >= 60:
            for off in (-0.22, 0.22):
                if w >= h:
                    yy = y + h / 2 + off * h
                    flat_poly("iz", [[x, yy - 5], [x + w, yy - 5], [x + w, yy + 5], [x, yy + 5]], 0.45 + ri * 0.02, rut, g_coll)
                else:
                    xx = x + w / 2 + off * w
                    flat_poly("iz", [[xx - 5, y], [xx + 5, y], [xx + 5, y + h], [xx - 5, y + h]], 0.45 + ri * 0.02, rut, g_coll)
            for _ in range(int(max(w, h) / 400)):
                px, py = rng.uniform(x + 10, x + w - 10), rng.uniform(y + 10, y + h - 10)
                rr = rng.uniform(8, 18)
                pts = [[px + math.cos(a) * rr * rng.uniform(0.8, 1.3), py + math.sin(a) * rr * 0.6 * rng.uniform(0.8, 1.2)]
                       for a in [i * math.tau / 10 for i in range(10)]]
                flat_poly("birikinti", pts, 0.7, puddle, g_coll)
    for s in level.get("surfaces", []):
        st = s.get("type")
        m = M["mud"] if st == "mud" else (M["beton"] if st == "beton" else mat("snow", (0.82, 0.84, 0.89), (0.68, 0.72, 0.80), 0.6, 0.05, 0.3))
        flat_poly("camur", s["points"], 0.6, m, g_coll)
    for o in level.get("obstacles", []):
        if o.get("type") == "water":
            flat_poly("kiyi", offset_poly(o["points"], 16), 0.8, M["bank"], g_coll)
    for o in level.get("obstacles", []):
        if o.get("type") == "water":
            flat_poly("su", o["points"], 1.0, M["water"], g_coll)
    for b in level.get("bridges", []):
        x, y, w, h = b
        prism("kopru", [[x, y], [x + w, y], [x + w, y + h], [x, y + h]], 3.0, M["plank"], g_coll, z0=1.2)
        box("korkuluk", x + w / 2, y + 3, 4, w, 5, 6, M["wood"], g_coll)
        box("korkuluk", x + w / 2, y + h - 3, 4, w, 5, 6, M["wood"], g_coll)
    floor_coll = bpy.data.collections.new("BinaIci")
    for bd in level.get("buildings", []):
        x, y, w, h = bd["rect"]
        fo = flat_poly("ic", [[x + WALL, y + WALL], [x + w - WALL, y + WALL], [x + w - WALL, y + h - WALL], [x + WALL, y + h - WALL]],
                       0.9, M["floor"], g_coll)
        floor_coll.objects.link(fo)

    # cimen ustu suslemeler: cakil ve cicek (sadece zemin katmaninda)
    if not quick:
        blocked = []
        for r in level.get("roads", []):
            blocked.append((r[0], r[1], r[0] + r[2], r[1] + r[3]))
        for bd in level.get("buildings", []):
            x, y, w, h = bd["rect"]
            blocked.append((x - 10, y - 10, x + w + 10, y + h + 10))
        for o in level.get("obstacles", []):
            pts = o.get("points") or circle_pts(o["circle"][:2], o["circle"][2])
            blocked.append(tuple(a + b for a, b in zip(poly_bbox(pts), (-6, -6, 6, 6))))
        n = int(W * H / 2200)
        pebbles, flowers, tufts = [], [], []
        for _ in range(n):
            x, y = rng.uniform(0, W), rng.uniform(0, H)
            if any(b[0] < x < b[2] and b[1] < y < b[3] for b in blocked):
                continue
            q = rng.random()
            if q < 0.25:
                pebbles.append(blob("cakil", (x, y), rng.uniform(1.5, 3.5), 0.5, M["pebble"], g_coll, rng, 1, 0.5, 0.3))
            elif q < 0.33 and theme != "kar":
                flowers.append(blob("cicek", (x, y), 1.6, 1.0, M["flower"], g_coll, rng, 1, 0.8, 0.1))
            else:
                tufts.append(blob("tutam", (x, y), rng.uniform(2.5, 5), 0.5, M["tuft"], g_coll, rng, 1, 1.1, 0.35))
        if pebbles:
            join(pebbles, "cakillar")
        if flowers:
            join(flowers, "cicekler")
        if tufts:
            join(tufts, "tutamlar")

    # ------------------------------------------------ nesneler (her biri ayri sprite olacak)
    items = []   # (obj, manifest bilgisi)

    def add(objs, info):
        ob = join(objs, "n%d" % len(items))
        items.append((ob, info))

    glass = mat("glass", (0.10, 0.12, 0.14), None, 0.15)
    frame = mat("frame", (0.30, 0.22, 0.15))
    shutter_cols = [(0.22, 0.36, 0.30), (0.25, 0.32, 0.45), (0.45, 0.20, 0.16), (0.30, 0.38, 0.22)]
    for bi, bd in enumerate(level.get("buildings", [])):
        shutter = mat("panjur_%d" % (bi % 4), shutter_cols[bi % 4], [c * 0.8 for c in shutter_cols[bi % 4]], 0.7, 0.2, 0.2, "wave")
        rect = bd["rect"]
        bcx, bcy = rect[0] + rect[2] / 2, rect[1] + rect[3] / 2
        for wi, (x, y, w, h) in enumerate(building_walls(rect, bd.get("door", "S"))):
            pts = [[x, y], [x + w, y], [x + w, y + h], [x, y + h]]
            parts = [prism("duvar", pts, WALL_H, M["plaster"], o_coll, bevel=1.2)]
            parts.append(prism("taban", [[x - 1.5, y - 1.5], [x + w + 1.5, y - 1.5], [x + w + 1.5, y + h + 1.5], [x - 1.5, y + h + 1.5]], 9, M["stone"], o_coll))
            horiz = w >= h
            L = w if horiz else h
            n = int((L - 20) / 64)
            for k in range(n):
                t0 = (k + 0.5) / n
                if horiz:
                    wx = x + 10 + (L - 20) * t0
                    outward = 1 if y + h / 2 > bcy else -1
                    wy = (y + h if outward > 0 else y) + outward * 0.8
                    parts.append(box("cerceve", wx, wy, 16, 20, 2.5, 24, frame, o_coll))
                    parts.append(box("cam", wx, wy + outward * 0.6, 18, 15, 2.5, 19, glass, o_coll))
                    for sd in (-1, 1):
                        parts.append(box("panjur", wx + sd * 15, wy + outward * 0.4, 16, 9, 2.5, 24, shutter, o_coll))
                else:
                    wy = y + 10 + (L - 20) * t0
                    outward = 1 if x + w / 2 > bcx else -1
                    wx = (x + w if outward > 0 else x) + outward * 0.8
                    parts.append(box("cerceve", wx, wy, 16, 2.5, 20, 24, frame, o_coll))
                    parts.append(box("cam", wx + outward * 0.6, wy, 18, 2.5, 15, 19, glass, o_coll))
                    for sd in (-1, 1):
                        parts.append(box("panjur", wx + outward * 0.4, wy + sd * 15, 16, 2.5, 9, 24, shutter, o_coll))
            # Normandiya yari kereste (colombage) iskeleti: dis yuzde koyu kirisler
            if bd.get("style", "colombage" if bi % 2 == 0 else "sade") == "colombage":
                if horiz:
                    outward = 1 if y + h / 2 > bcy else -1
                    fy = (y + h if outward > 0 else y) + outward * 0.6
                    for zb in (2, 30, WALL_H - 4):
                        parts.append(box("kiris", x + w / 2, fy, zb, w, 2.0, 4, M["beam"], o_coll))
                    xx = x
                    while xx <= x + w:
                        parts.append(box("dikme", min(xx, x + w - 2), fy, 0, 4, 2.0, WALL_H, M["beam"], o_coll))
                        xx += 32
                else:
                    outward = 1 if x + w / 2 > bcx else -1
                    fx = (x + w if outward > 0 else x) + outward * 0.6
                    for zb in (2, 30, WALL_H - 4):
                        parts.append(box("kiris", fx, y + h / 2, zb, 2.0, h, 4, M["beam"], o_coll))
                    yy = y
                    while yy <= y + h:
                        parts.append(box("dikme", fx, min(yy, y + h - 2), 0, 2.0, 4, WALL_H, M["beam"], o_coll))
                        yy += 32
            add(parts, {"kind": "wall", "building": bi, "wall": wi, "base": poly_bbox(pts)})
        # cati: uzun kenar boyunca semer cati
        x, y, w, h = rect
        ov = 8.0
        x0, y0, x1, y1 = x - ov, y - ov, x + w + ov, y + h + ov
        rc = bd.get("roof", [0.58, 0.3, 0.24])
        rm = tex_mat("t_roof_%d" % bi, "roof", 70, mat("roof_%d" % bi, rc, [c * 0.8 for c in rc], 0.8, 0.06, 0.6, "brick"),
                     [min(1.0, c * 1.9) for c in rc], 0.8, 0.6, desat=0.25)
        bm = bmesh.new()
        ridge = 0.32 * min(w, h)
        if w >= h:
            a = [bm.verts.new(B(x0, y0, WALL_H)), bm.verts.new(B(x1, y0, WALL_H)),
                 bm.verts.new(B(x1, y1, WALL_H)), bm.verts.new(B(x0, y1, WALL_H))]
            r0 = bm.verts.new(B(x0, (y0 + y1) / 2, WALL_H + ridge))
            r1 = bm.verts.new(B(x1, (y0 + y1) / 2, WALL_H + ridge))
            bm.faces.new([a[0], a[1], r1, r0])
            bm.faces.new([r0, r1, a[2], a[3]])
            bm.faces.new([a[1], a[2], r1])
            bm.faces.new([a[3], a[0], r0])
        else:
            a = [bm.verts.new(B(x0, y0, WALL_H)), bm.verts.new(B(x1, y0, WALL_H)),
                 bm.verts.new(B(x1, y1, WALL_H)), bm.verts.new(B(x0, y1, WALL_H))]
            r0 = bm.verts.new(B((x0 + x1) / 2, y0, WALL_H + ridge))
            r1 = bm.verts.new(B((x0 + x1) / 2, y1, WALL_H + ridge))
            bm.faces.new([a[0], r0, r1, a[3]])
            bm.faces.new([r0, a[1], a[2], r1])
            bm.faces.new([a[0], a[1], r0])
            bm.faces.new([a[2], a[3], r1])
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        roof = obj_from_bm("cati", bm, rm, r_coll)
        gut = mat("oluk", (0.25, 0.25, 0.26), None, 0.4, metal=0.6)
        gutters = []
        if w >= h:
            for gy in (y0, y1):
                gutters.append(cyl("oluk", (x0 + x1) / 2, gy, WALL_H - 1, 2.2, x1 - x0, gut, r_coll, 6, axis="X"))
        roof = join([roof] + gutters, "cati")
        baca = box("baca", x + w * 0.7, y + h * 0.35, WALL_H, 16, 16, ridge + 22, M["stone"], r_coll)
        roof = join([roof, baca], "r%d" % bi)
        items.append((roof, {"kind": "roof", "building": bi, "base": [x0, y0, x1, y1]}))

    for oi, o in enumerate(level.get("obstacles", [])):
        t = o.get("type", "wall")
        if t == "water":
            continue
        if "circle" in o:
            cx, cy, r = o["circle"]
            pts = circle_pts((cx, cy), r)
        else:
            pts = o["points"]
            cx = sum(p[0] for p in pts) / len(pts)
            cy = sum(p[1] for p in pts) / len(pts)
            r = None
        bb = poly_bbox(pts)
        w, h = bb[2] - bb[0], bb[3] - bb[1]
        objs = []
        if t == "tree":
            th = rng.uniform(26, 40)
            objs.append(cyl("govde", cx, cy, 0, r * 0.22, th + 10, M["bark"], o_coll, 8))
            leaf = M["leaf"] if rng.random() < 0.6 else M["leaf2"]
            objs.append(blob("tac", (cx, cy), r * 1.15, th + r * 0.9, leaf, o_coll, rng, 3, 0.85, 0.12))
            for _ in range(7):
                a = rng.uniform(0, math.tau)
                d = rng.uniform(0.35, 0.8) * r
                lm = leaf if rng.random() < 0.7 else M["leaf2"]
                objs.append(blob("tac", (cx + math.cos(a) * d, cy + math.sin(a) * d), r * rng.uniform(0.45, 0.7),
                                 th + r * rng.uniform(0.8, 1.6), lm, o_coll, rng, 2, 0.85, 0.15))
        elif t == "bush":
            objs.append(blob("cali", (cx, cy), r * 1.05, r * 0.45, M["hedge"], o_coll, rng, 2, 0.6, 0.22))
            objs.append(blob("cali", (cx + r * 0.3, cy - r * 0.2), r * 0.7, r * 0.6, M["leaf"], o_coll, rng, 2, 0.6, 0.22))
        elif t == "hedge":
            objs.append(prism("cit", pts, 30, M["hedge"], o_coll, jitter=4.0, rng=rng))
        elif t == "wall":
            objs.append(prism("tas", pts, 36, M["stone"], o_coll, bevel=1.5))
        elif t == "sandbag":
            # torbalari sira sira diz
            horiz = w >= h
            L = w if horiz else h
            n = max(1, int(L / 22))
            for row in range(2):
                for i in range(n + (0 if row == 0 else -1)):
                    t0 = (i + 0.5 + row * 0.5) / n
                    bx = bb[0] + (L * t0 if horiz else w / 2)
                    by = bb[1] + (h / 2 if horiz else L * t0)
                    objs.append(box("torba", bx, by, row * 8, (22 if horiz else min(w, 24)), (min(h, 24) if horiz else 22), 9, M["sand"], o_coll))
        elif t == "crate":
            objs.append(prism("sandik", pts, 30, M["wood"], o_coll, bevel=1.5))
        elif t == "fence":
            horiz = w >= h
            L = w if horiz else h
            n = max(2, int(L / 40) + 1)
            for i in range(n):
                t0 = i / (n - 1)
                px = bb[0] + (L * t0 if horiz else w / 2)
                py = bb[1] + (h / 2 if horiz else L * t0)
                objs.append(box("direk", px, py, 0, 5, 5, 20, M["wood"], o_coll))
            for z in (8, 16):
                objs.append(box("tel", (bb[0] + bb[2]) / 2, (bb[1] + bb[3]) / 2, z, max(w, 3), max(h, 3), 2.5, M["wood"], o_coll))
        elif t == "tel":
            # dikenli tel orgu (tel makasiyla kesilebilir): X kazikli, sarmal tel
            horiz = w >= h
            L = w if horiz else h
            n = max(2, int(L / 34) + 1)
            for i in range(n):
                t0 = i / (n - 1)
                px = bb[0] + (L * t0 if horiz else w / 2)
                py = bb[1] + (h / 2 if horiz else L * t0)
                objs.append(box("kazik", px, py, 0, 4, 4, 18, M["grey"], o_coll, rot=0.6))
                objs.append(box("kazik", px, py, 0, 4, 4, 18, M["grey"], o_coll, rot=-0.6))
            k = max(3, int(L / 9))
            for i in range(k):
                t0 = (i + 0.5) / k
                px = bb[0] + (L * t0 if horiz else w / 2)
                py = bb[1] + (h / 2 if horiz else L * t0)
                objs.append(cyl("sarmal", px, py, 8 + (i % 2) * 2, 7.0, 1.4, M["grey"], o_coll, 8, "X" if horiz else "Y", caps=False))
        elif t == "projektor":
            # projektor kulesi: kisa direk + tepe lambasi (isik oyunda cizilir)
            objs.append(cyl("direk", cx, cy, 0, 3.5, 40, M["grey"], o_coll, 8))
            objs.append(cyl("lamba", cx, cy, 40, 8, 9, M["grey"], o_coll, 10))
        elif t == "tent":
            bm = bmesh.new()
            ridge_h = 40
            if w >= h:
                v = [bm.verts.new(B(bb[0], bb[1])), bm.verts.new(B(bb[2], bb[1])), bm.verts.new(B(bb[2], bb[3])), bm.verts.new(B(bb[0], bb[3])),
                     bm.verts.new(B(bb[0], cy, ridge_h)), bm.verts.new(B(bb[2], cy, ridge_h))]
                bm.faces.new([v[0], v[1], v[5], v[4]]); bm.faces.new([v[4], v[5], v[2], v[3]])
                bm.faces.new([v[1], v[2], v[5]]); bm.faces.new([v[3], v[0], v[4]])
            else:
                v = [bm.verts.new(B(bb[0], bb[1])), bm.verts.new(B(bb[2], bb[1])), bm.verts.new(B(bb[2], bb[3])), bm.verts.new(B(bb[0], bb[3])),
                     bm.verts.new(B(cx, bb[1], ridge_h)), bm.verts.new(B(cx, bb[3], ridge_h))]
                bm.faces.new([v[0], v[4], v[5], v[3]]); bm.faces.new([v[4], v[1], v[2], v[5]])
                bm.faces.new([v[0], v[1], v[4]]); bm.faces.new([v[2], v[3], v[5]])
            bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
            objs.append(obj_from_bm("cadir", bm, M["canvas"], o_coll))
        elif t == "truck":
            horiz = w >= h
            L, Wd = (w, h) if horiz else (h, w)
            rot = 0.0 if horiz else math.pi / 2
            ax = Vector((1, 0)) if horiz else Vector((0, 1))
            c = Vector((cx, cy))
            def at(f):
                p = c + ax * (f * L)
                return p.x, p.y
            px, py = at(-0.12)
            objs.append(box("kasa", px, py, 10, L * 0.72 if horiz else Wd, Wd if horiz else L * 0.72, 30, M["canvas"], o_coll))
            px, py = at(0.36)
            objs.append(box("kabin", px, py, 10, L * 0.26 if horiz else Wd * 0.95, Wd * 0.95 if horiz else L * 0.26, 24, M["olive"], o_coll))
            for f in (-0.32, 0.05, 0.36):
                px, py = at(f)
                for s in (-1, 1):
                    ox = 0 if horiz else s * Wd / 2
                    oy = s * Wd / 2 if horiz else 0
                    objs.append(box("teker", px + ox, py + oy, 0, 16 if horiz else 6, 6 if horiz else 16, 14, M["tire"], o_coll))
        elif t == "tank":
            horiz = w >= h
            objs.append(box("palet", cx, cy - h * 0.36, 0, w, h * 0.26, 16, M["tire"], o_coll))
            objs.append(box("palet", cx, cy + h * 0.36, 0, w, h * 0.26, 16, M["tire"], o_coll))
            objs.append(box("govde", cx, cy, 10, w * 0.95, h * 0.8, 16, M["grey"], o_coll))
            objs.append(cyl("kule", cx - w * 0.05, cy, 26, min(w, h) * 0.32, 12, M["grey"], o_coll, 12))
            objs.append(box("namlu", cx + w * 0.38, cy, 30, w * 0.6, 5, 5, M["grey"], o_coll))
        elif t == "rock":
            objs.append(blob("kaya", (cx, cy), r, r * 0.15, M["rock"], o_coll, rng, 2, 0.6, 0.25))
            if theme == "kar":
                objs.append(blob("kar", (cx, cy - r * 0.1), r * 0.8, r * 0.5, M["snow"], o_coll, rng, 2, 0.4, 0.2))
        elif t == "tower":
            # gozetleme kulesi: 4 dikme, platform (z=46, oyundaki kule nobetcisi burada durur), korkuluk, cati
            x0, y0, x1, y1 = bb
            for px in (x0 + 3, x1 - 3):
                for py in (y0 + 3, y1 - 3):
                    objs.append(box("dikme", px, py, 0, 5, 5, 74, M["wood"], o_coll))
            objs.append(box("platform", cx, cy, 42, w + 8, h + 8, 4, M["plank"], o_coll))
            for (ax, ay, sx, sy) in ((cx, y0 - 4, w + 8, 3), (cx, y1 + 4, w + 8, 3), (x0 - 4, cy, 3, h + 8), (x1 + 4, cy, 3, h + 8)):
                objs.append(box("korkuluk", ax, ay, 46, sx, sy, 12, M["wood"], o_coll))
            objs.append(box("cati", cx, cy, 74, w + 14, h + 14, 5, M["beam"], o_coll))
            objs.append(box("capraz", cx, y1 - 3, 14, w, 3, 3, M["wood"], o_coll))
        else:
            objs.append(prism("nesne", pts, 28, M["wood"], o_coll))
        add(objs, {"kind": "obstacle", "index": oi, "base": list(bb)})

    # ------------------------------------------------ bakis acisi + egik projeksiyon (z ekranda yukari kayar)
    if VIEW:
        rotate_scene(W, H, VIEW)
        for ob, info in items:
            if "base" in info:
                info["base"] = view_bbox(info["base"], W, H, VIEW)
    for ob in list(g_coll.objects) + list(o_coll.objects) + list(r_coll.objects):
        me = ob.data
        for v in me.vertices:
            v.co.y += v.co.z * SHEAR
        me.update()
    return g_coll, o_coll, r_coll, items, floor_coll


# ================================================================ render
def setup_render(W, H, samples):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = samples
    sc.cycles.use_denoising = True
    sc.render.resolution_x = W * SCALE
    sc.render.resolution_y = H * SCALE
    sc.render.resolution_percentage = 100
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "Medium High Contrast"
    sc.cycles.max_bounces = 4

    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (0.62, 0.70, 0.82, 1)
    bg.inputs[1].default_value = 0.55
    sc.world = world

    sun_d = bpy.data.lights.new("gunes", "SUN")
    sun_d.energy = 4.2
    sun_d.angle = math.radians(3)
    sun_d.color = (1.0, 0.95, 0.86)
    sun = bpy.data.objects.new("gunes", sun_d)
    d = Vector((0.55, -0.75, -0.95)).normalized()      # sol usten (kuzeybatidan) gelen isik
    if VIEW:
        # gunes dunyaya sabit: sahneyle birlikte doner (golgeler her acida tutarli)
        a = -VIEW * math.pi / 2.0
        gx, gy = d.x, -d.y
        rx, ry = gx * math.cos(a) - gy * math.sin(a), gx * math.sin(a) + gy * math.cos(a)
        d = Vector((rx, -ry, d.z)).normalized()
    sun.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    sc.collection.objects.link(sun)

    cam_d = bpy.data.cameras.new("kamera")
    cam_d.type = "ORTHO"
    cam_d.ortho_scale = max(W, H)
    cam_d.clip_end = 10000
    cam = bpy.data.objects.new("kamera", cam_d)
    cam.location = (W / 2, -H / 2, 3000)
    sc.collection.objects.link(cam)
    sc.camera = cam
    setup_paint(sc)


def setup_paint(sc):
    """Kompozitor: Kuwahara (yagli boya firca darbesi) + hafif renk doygunlugu. Saydamlik korunur."""
    sc.use_nodes = True
    sc.render.use_compositing = PAINT
    nt = sc.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    rl = nt.nodes.new("CompositorNodeRLayers")
    kw = nt.nodes.new("CompositorNodeKuwahara")
    try:
        kw.variation = "ANISOTROPIC"
    except Exception:
        pass
    size = 3 * SCALE
    if hasattr(kw, "size"):
        kw.size = size
    elif "Size" in kw.inputs:
        kw.inputs["Size"].default_value = size
    for attr, val in (("uniformity", 4), ("sharpness", 0.6), ("eccentricity", 1.0)):
        if hasattr(kw, attr):
            setattr(kw, attr, val)
    hs = nt.nodes.new("CompositorNodeHueSat")
    if "Saturation" in hs.inputs:
        hs.inputs["Saturation"].default_value = 1.08
    sa = nt.nodes.new("CompositorNodeSetAlpha")
    comp = nt.nodes.new("CompositorNodeComposite")
    nt.links.new(rl.outputs["Image"], kw.inputs["Image"])
    nt.links.new(kw.outputs["Image"], hs.inputs["Image"])
    nt.links.new(hs.outputs["Image"], sa.inputs["Image"])
    nt.links.new(rl.outputs["Alpha"], sa.inputs["Alpha"])
    nt.links.new(sa.outputs["Image"], comp.inputs["Image"])


def link_floor_light(floors, o, r):
    """Bina ici zeminler: duvar/cati golgesi dusmesin (cati seffaflasinca ic karanlik gorunmesin).
    Isik baglama (light linking): ana gunes zeminleri aydinlatmaz, ikinci gunes sadece zeminleri
    aydinlatir ve onun icin binalar golge yapmaz."""
    if not floors.objects:
        return
    sc = bpy.context.scene
    sun = bpy.data.objects["gunes"]
    try:
        sc.collection.children.link(floors)
        rc = bpy.data.collections.new("GunesAlici")
        for ob in floors.objects:
            rc.objects.link(ob)
        for co in rc.collection_objects:
            co.light_linking.link_state = "EXCLUDE"
        sun.light_linking.receiver_collection = rc
        sun2 = bpy.data.objects.new("gunes_ic", sun.data.copy())
        sun2.rotation_euler = sun.rotation_euler
        sc.collection.objects.link(sun2)
        sun2.light_linking.receiver_collection = floors
        bc = bpy.data.collections.new("IcGolgeYok")
        for coll in (o, r):
            for ob in coll.all_objects:
                bc.objects.link(ob)
        for co in bc.collection_objects:
            co.light_linking.link_state = "EXCLUDE"
        sun2.light_linking.blocker_collection = bc
        print("isik baglama: tamam", flush=True)
    except Exception as ex:
        print("isik baglama desteklenmiyor:", ex, flush=True)


def show(coll, camera=True, render=True):
    for ob in coll.all_objects:
        ob.hide_render = not render
        ob.visible_camera = camera


def render_to_array(path, W, H, raw=False):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    img = bpy.data.images.load(path, check_existing=False)
    if raw:
        img.colorspace_settings.name = "Non-Color"
    a = np.empty(W * H * 4, dtype=np.float32)
    img.pixels.foreach_get(a)
    bpy.data.images.remove(img)
    return a.reshape(H, W, 4)[::-1].copy()     # ust satir once


def save_array(arr, path, fmt="PNG", quality=90):
    h, w = arr.shape[:2]
    if arr.shape[2] == 3:
        arr = np.concatenate([arr, np.ones((h, w, 1), dtype=np.float32)], axis=2)
    img = bpy.data.images.new(os.path.basename(path), w, h, alpha=True)
    img.pixels.foreach_set(np.ascontiguousarray(arr[::-1]).ravel())
    img.filepath_raw = path
    img.file_format = fmt
    sc = bpy.context.scene
    if fmt == "JPEG":
        st = sc.render.image_settings
        old = (st.file_format, st.color_mode)
        st.file_format = "JPEG"
        st.quality = quality
        st.color_mode = "RGB"
        img.save_render(path, scene=sc)
        st.file_format, st.color_mode = old
    else:
        img.save()
    bpy.data.images.remove(img)


def id_pass(items, coll_objs, W, H, tmp):
    """her nesneyi kendi kimlik rengiyle (golgesiz, kenar yumusatmasiz) render al"""
    sc = bpy.context.scene
    old = (sc.cycles.samples, sc.cycles.use_denoising, sc.cycles.filter_width,
           sc.view_settings.view_transform, sc.view_settings.look)
    sc.render.use_compositing = False
    sc.cycles.samples = 1
    sc.cycles.use_denoising = False
    sc.cycles.filter_width = 0.01
    sc.view_settings.view_transform = "Raw"
    sc.view_settings.look = "None"
    sc.render.image_settings.color_depth = "16"
    saved = {}
    for idx, (ob, info) in enumerate(items):
        if ob.name not in coll_objs:
            continue
        k = idx + 1
        m = bpy.data.materials.new("id%d" % k)
        m.use_nodes = True
        nt = m.node_tree
        for n in list(nt.nodes):
            nt.nodes.remove(n)
        em = nt.nodes.new("ShaderNodeEmission")
        em.inputs[0].default_value = ((k % 256) / 255.0, (k // 256) / 255.0, 0.0, 1.0)
        out = nt.nodes.new("ShaderNodeOutputMaterial")
        nt.links.new(em.outputs[0], out.inputs[0])
        saved[ob.name] = [s.material for s in ob.material_slots]
        for s in ob.material_slots:
            s.material = m
    arr = render_to_array(os.path.join(tmp, "id.png"), W, H, raw=True)
    for name, mats in saved.items():
        for s, mm in zip(bpy.data.objects[name].material_slots, mats):
            s.material = mm
    sc.cycles.samples, sc.cycles.use_denoising, sc.cycles.filter_width, sc.view_settings.view_transform, sc.view_settings.look = old
    sc.render.use_compositing = PAINT
    sc.render.image_settings.color_depth = "8"
    ids = np.rint(arr[:, :, 0] * 255).astype(np.int32) + np.rint(arr[:, :, 1] * 255).astype(np.int32) * 256
    ids[arr[:, :, 3] < 0.5] = 0
    return ids


def pack(sprites, max_w=PAGE, max_h=PAGE):
    """raf (shelf) paketleme, gerekirse birden fazla sayfa"""
    order = sorted(range(len(sprites)), key=lambda i: -sprites[i].shape[0])
    pages = [[]]
    x = y = shelf = 0
    pos = [None] * len(sprites)
    for i in order:
        h, w = sprites[i].shape[:2]
        if x + w > max_w:
            x = 0
            y += shelf + 2
            shelf = 0
        if y + h > max_h:
            pages.append([])
            x = y = shelf = 0
        pos[i] = (len(pages) - 1, x, y)
        pages[-1].append(i)
        x += w + 2
        shelf = max(shelf, h)
    atlases = []
    for pi, idxs in enumerate(pages):
        hh = max(pos[i][2] + sprites[i].shape[0] for i in idxs) + 1
        ww = max(pos[i][1] + sprites[i].shape[1] for i in idxs) + 1
        atlas = np.zeros((hh, ww, 4), dtype=np.float32)
        for i in idxs:
            _, px, py = pos[i]
            atlas[py:py + sprites[i].shape[0], px:px + sprites[i].shape[1]] = sprites[i]
        atlases.append(atlas)
    return atlases, pos


def extract(beauty, ids, items, which, manifest_key, out_dir, manifest):
    sprites, entries = [], []
    for idx, (ob, info) in enumerate(items):
        if info["kind"] not in which:
            continue
        k = idx + 1
        mask = ids == k
        if not mask.any():
            continue
        ys, xs = np.nonzero(mask)
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        # kenar yumusatmasi icin 1px genislet
        y0, x0 = max(0, y0 - 1), max(0, x0 - 1)
        y1, x1 = min(ids.shape[0], y1 + 1), min(ids.shape[1], x1 + 1)
        sub_mask = mask[y0:y1, x0:x1].copy()
        grown = sub_mask.copy()
        grown[1:, :] |= sub_mask[:-1, :]; grown[:-1, :] |= sub_mask[1:, :]
        grown[:, 1:] |= sub_mask[:, :-1]; grown[:, :-1] |= sub_mask[:, 1:]
        own_or_free = grown & ((ids[y0:y1, x0:x1] == k) | (ids[y0:y1, x0:x1] == 0))
        spr = beauty[y0:y1, x0:x1].copy()
        spr[~own_or_free] = 0.0
        sprites.append(spr)
        e = dict(info)
        e["rect"] = [int(x0), int(y0), int(x1 - x0), int(y1 - y0)]     # render pikseli
        entries.append(e)
    atlases, pos = pack(sprites)
    for e, p in zip(entries, pos):
        e["page"] = int(p[0])
        e["atlas"] = [int(p[1]), int(p[2])]
    files = []
    for pi, atlas in enumerate(atlases):
        fn = f"{manifest_key}_{pi}.png"
        save_array(atlas, os.path.join(out_dir, fn))
        files.append(fn)
    manifest[manifest_key] = entries
    manifest[manifest_key + "_pages"] = files
    print(f"  {manifest_key}: {len(entries)} parca, {len(atlases)} sayfa", flush=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    path = argv[0]
    samples = SAMPLES
    quick = "--quick" in argv
    if "--samples" in argv:
        samples = int(argv[argv.index("--samples") + 1])
    global SCALE, PAINT, VIEW
    if "--view" in argv:
        VIEW = int(argv[argv.index("--view") + 1]) % 4
    if "--scale" in argv:
        SCALE = int(argv[argv.index("--scale") + 1])
    if "--no-paint" in argv:
        PAINT = False
    with open(path) as f:
        level = json.load(f)
    W0, H0 = level["size"]
    W, H = (H0, W0) if VIEW % 2 else (W0, H0)       # bu acidaki ekran boyutu
    out_dir = os.path.splitext(path)[0] + "_art/v%d" % VIEW
    os.makedirs(out_dir, exist_ok=True)
    tmp = os.path.join(out_dir, "_tmp")
    os.makedirs(tmp, exist_ok=True)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    g, o, r, items, floors = build(level, quick)
    setup_render(W, H, samples)
    link_floor_light(floors, o, r)
    sc = bpy.context.scene
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"

    # 1) zemin: nesneler gorunmez ama golge dusurur
    print("zemin render...", flush=True)
    sc.render.film_transparent = False
    show(g, True, True); show(o, False, True); show(r, False, True)
    for ob in r.all_objects:
        ob.visible_shadow = False      # bina ici karanlik kalmasin (cati seffaflasinca gorunur)
    RW, RH = W * SCALE, H * SCALE
    ground = render_to_array(os.path.join(tmp, "ground.png"), RW, RH)
    manifest = {"size": [W, H], "world_size": [W0, H0], "view": VIEW, "shear": SHEAR, "wall_h": WALL_H, "scale": SCALE, "ground": []}
    for f in os.listdir(out_dir):        # eski ciktilari temizle
        if f.endswith((".jpg", ".png", ".webp")) or f.endswith(".import"):
            os.remove(os.path.join(out_dir, f))
    for ty in range(0, RH, TILE):
        for tx in range(0, RW, TILE):
            part = ground[ty:ty + TILE, tx:tx + TILE, :3].copy()
            fn = f"ground_{tx // TILE}_{ty // TILE}.png"
            save_array(part, os.path.join(out_dir, fn), "PNG")
            manifest["ground"].append({"file": fn, "rect": [tx / SCALE, ty / SCALE, part.shape[1] / SCALE, part.shape[0] / SCALE]})
    sc.render.film_transparent = True

    # 2) nesneler (catilar haric)
    print("nesne render...", flush=True)
    show(g, False, False); show(o, True, True); show(r, False, False)
    beauty = render_to_array(os.path.join(tmp, "objects.png"), RW, RH)
    ids = id_pass(items, set(ob.name for ob in o.all_objects), RW, RH, tmp)
    extract(beauty, ids, items, ("wall", "obstacle"), "objects", out_dir, manifest)

    # 3) catilar
    print("cati render...", flush=True)
    show(o, False, False); show(r, True, True)
    for ob in r.all_objects:
        ob.visible_shadow = True
    beauty = render_to_array(os.path.join(tmp, "roofs.png"), RW, RH)
    ids = id_pass(items, set(ob.name for ob in r.all_objects), RW, RH, tmp)
    extract(beauty, ids, items, ("roof",), "roofs", out_dir, manifest)

    with open(os.path.join(out_dir, "manifest.json"), "w") as f:
        json.dump(manifest, f)
    for fn in os.listdir(tmp):
        os.remove(os.path.join(tmp, fn))
    os.rmdir(tmp)
    print("BITTI", out_dir, flush=True)


if __name__ == "__main__":
    main()
