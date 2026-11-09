"""
Komando - Harita render hatti (Blender 4.2).

Bolum dosyasini (levels/*.json) okur, 3D sahneyi kurar ve oyunun egik (oblik) bakis
acisiyla render alir. 1 Blender birimi = 1 oyun pikseli. Yukseklik z, ekranda z*SHEAR
kadar yukari kayar (oyundaki yukseltilmis cizimle ayni geometri).

    blender -b --python tools/blender/harita.py -- levels/bolum0.json [--samples 32] [--quick]

Cikti: levels/<bolum>_art/
    ground.jpg     zemin (yollar, camur, su, kopruler, bina ici zeminler, nesnelerin golgeleri)
    objects.png    nesne atlasi (duvarlar, agaclar, kum torbalari, araclar ...)
    roofs.png      cati atlasi (bina icine girince seffaflasir)
    manifest.json  her parcanin atlas bolgesi, dunyadaki yeri ve hangi engele ait oldugu
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
SAMPLES = 32


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


def prism(name, pts, h, material, coll, z0=0.0, top_mat=None, jitter=0.0, rng=None):
    bm = bmesh.new()
    vs = [bm.verts.new(B(p[0], p[1], z0)) for p in pts]
    f = bm.faces.new(vs)
    if f.normal.z > 0:
        f.normal_flip()
    ext = bmesh.ops.extrude_face_region(bm, geom=[f])
    top = [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, vec=Vector((0, 0, h)), verts=top)
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


def cyl(name, x, y, z, r, h, material, coll, segs=10, axis="Z"):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segs, radius1=r, radius2=r, depth=h)
    if axis == "X":
        bmesh.ops.rotate(bm, cent=Vector(), matrix=Matrix.Rotation(math.pi / 2, 3, "Y"), verts=bm.verts)
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

    M = {
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

    # ------------------------------------------------ zemin
    flat_poly("cimen", [[0, 0], [W, 0], [W, H], [0, H]], 0.0, grass_mat(), g_coll)
    for ri, r in enumerate(level.get("roads", [])):
        x, y, w, h = r
        # ust uste binen yollar ayni yukseklikte olmasin (golge hatasi)
        flat_poly("yol", [[x, y], [x + w, y], [x + w, y + h], [x, y + h]], 0.2 + ri * 0.02, M["dirt"], g_coll)
    for s in level.get("surfaces", []):
        m = M["mud"] if s.get("type") == "mud" else mat("snow", (0.92, 0.93, 0.95), (0.82, 0.85, 0.9), 0.6, 0.05, 0.2)
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
    for bd in level.get("buildings", []):
        x, y, w, h = bd["rect"]
        flat_poly("ic", [[x, y], [x + w, y], [x + w, y + h], [x, y + h]], 0.9, M["floor"], g_coll)

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
            elif q < 0.33:
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
    for bi, bd in enumerate(level.get("buildings", [])):
        rect = bd["rect"]
        bcx, bcy = rect[0] + rect[2] / 2, rect[1] + rect[3] / 2
        for wi, (x, y, w, h) in enumerate(building_walls(rect, bd.get("door", "S"))):
            pts = [[x, y], [x + w, y], [x + w, y + h], [x, y + h]]
            parts = [prism("duvar", pts, WALL_H, M["plaster"], o_coll)]
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
                else:
                    wy = y + 10 + (L - 20) * t0
                    outward = 1 if x + w / 2 > bcx else -1
                    wx = (x + w if outward > 0 else x) + outward * 0.8
                    parts.append(box("cerceve", wx, wy, 16, 2.5, 20, 24, frame, o_coll))
                    parts.append(box("cam", wx + outward * 0.6, wy, 18, 2.5, 15, 19, glass, o_coll))
            add(parts, {"kind": "wall", "building": bi, "wall": wi, "base": poly_bbox(pts)})
        # cati: uzun kenar boyunca semer cati
        x, y, w, h = rect
        ov = 8.0
        x0, y0, x1, y1 = x - ov, y - ov, x + w + ov, y + h + ov
        rc = bd.get("roof", [0.58, 0.3, 0.24])
        rm = mat("roof_%d" % bi, rc, [c * 0.8 for c in rc], 0.8, 0.06, 0.6, "brick")
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
            objs.append(blob("tac", (cx, cy), r * 1.25, th + r * 0.9, leaf, o_coll, rng, 2, 0.85))
            for _ in range(3):
                dx, dy = rng.uniform(-0.5, 0.5) * r, rng.uniform(-0.5, 0.5) * r
                objs.append(blob("tac", (cx + dx, cy + dy), r * rng.uniform(0.6, 0.85), th + r * rng.uniform(1.0, 1.5), leaf, o_coll, rng, 2, 0.85))
        elif t == "bush":
            objs.append(blob("cali", (cx, cy), r * 1.05, r * 0.45, M["hedge"], o_coll, rng, 2, 0.6, 0.22))
            objs.append(blob("cali", (cx + r * 0.3, cy - r * 0.2), r * 0.7, r * 0.6, M["leaf"], o_coll, rng, 2, 0.6, 0.22))
        elif t == "hedge":
            objs.append(prism("cit", pts, 30, M["hedge"], o_coll, jitter=4.0, rng=rng))
        elif t == "wall":
            objs.append(prism("tas", pts, 36, M["stone"], o_coll))
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
            objs.append(prism("sandik", pts, 30, M["wood"], o_coll))
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
        else:
            objs.append(prism("nesne", pts, 28, M["wood"], o_coll))
        add(objs, {"kind": "obstacle", "index": oi, "base": list(bb)})

    # ------------------------------------------------ egik projeksiyon: z yuksekligi ekranda yukari kayar
    for ob in list(g_coll.objects) + list(o_coll.objects) + list(r_coll.objects):
        me = ob.data
        for v in me.vertices:
            v.co.y += v.co.z * SHEAR
        me.update()
    return g_coll, o_coll, r_coll, items


# ================================================================ render
def setup_render(W, H, samples):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = samples
    sc.cycles.use_denoising = True
    sc.render.resolution_x = W
    sc.render.resolution_y = H
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
    sc.render.image_settings.color_depth = "8"
    ids = np.rint(arr[:, :, 0] * 255).astype(np.int32) + np.rint(arr[:, :, 1] * 255).astype(np.int32) * 256
    ids[arr[:, :, 3] < 0.5] = 0
    return ids


def pack(sprites, max_w=2048):
    """basit raf (shelf) paketleme"""
    order = sorted(range(len(sprites)), key=lambda i: -sprites[i].shape[0])
    x = y = shelf = 0
    pos = [None] * len(sprites)
    width = max_w
    for i in order:
        h, w = sprites[i].shape[:2]
        if x + w > width:
            x = 0
            y += shelf + 1
            shelf = 0
        pos[i] = (x, y)
        x += w + 1
        shelf = max(shelf, h)
    height = y + shelf + 1
    atlas = np.zeros((height, width, 4), dtype=np.float32)
    for i, s in enumerate(sprites):
        px, py = pos[i]
        atlas[py:py + s.shape[0], px:px + s.shape[1]] = s
    return atlas, pos


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
        e["rect"] = [int(x0), int(y0), int(x1 - x0), int(y1 - y0)]
        entries.append(e)
    atlas, pos = pack(sprites)
    for e, p in zip(entries, pos):
        e["atlas"] = [int(p[0]), int(p[1])]
    save_array(atlas, os.path.join(out_dir, manifest_key + ".png"))
    manifest[manifest_key] = entries
    print(f"  {manifest_key}: {len(entries)} parca, atlas {atlas.shape[1]}x{atlas.shape[0]}", flush=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    path = argv[0]
    samples = SAMPLES
    quick = "--quick" in argv
    if "--samples" in argv:
        samples = int(argv[argv.index("--samples") + 1])
    with open(path) as f:
        level = json.load(f)
    W, H = level["size"]
    out_dir = os.path.splitext(path)[0] + "_art"
    os.makedirs(out_dir, exist_ok=True)
    tmp = os.path.join(out_dir, "_tmp")
    os.makedirs(tmp, exist_ok=True)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    g, o, r, items = build(level, quick)
    setup_render(W, H, samples)
    sc = bpy.context.scene
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"

    # 1) zemin: nesneler gorunmez ama golge dusurur
    print("zemin render...", flush=True)
    sc.render.film_transparent = False
    show(g, True, True); show(o, False, True); show(r, False, True)
    for ob in r.all_objects:
        ob.visible_shadow = False      # bina ici karanlik kalmasin (cati seffaflasinca gorunur)
    ground = render_to_array(os.path.join(tmp, "ground.png"), W, H)
    save_array(ground[:, :, :3].copy(), os.path.join(out_dir, "ground.jpg"), "JPEG", 88)

    manifest = {"size": [W, H], "shear": SHEAR, "wall_h": WALL_H}
    sc.render.film_transparent = True

    # 2) nesneler (catilar haric)
    print("nesne render...", flush=True)
    show(g, False, False); show(o, True, True); show(r, False, False)
    beauty = render_to_array(os.path.join(tmp, "objects.png"), W, H)
    ids = id_pass(items, set(ob.name for ob in o.all_objects), W, H, tmp)
    extract(beauty, ids, items, ("wall", "obstacle"), "objects", out_dir, manifest)

    # 3) catilar
    print("cati render...", flush=True)
    show(o, False, False); show(r, True, True)
    for ob in r.all_objects:
        ob.visible_shadow = True
    beauty = render_to_array(os.path.join(tmp, "roofs.png"), W, H)
    ids = id_pass(items, set(ob.name for ob in r.all_objects), W, H, tmp)
    extract(beauty, ids, items, ("roof",), "roofs", out_dir, manifest)

    with open(os.path.join(out_dir, "manifest.json"), "w") as f:
        json.dump(manifest, f)
    for fn in os.listdir(tmp):
        os.remove(os.path.join(tmp, fn))
    os.rmdir(tmp)
    print("BITTI", out_dir, flush=True)


if __name__ == "__main__":
    main()
