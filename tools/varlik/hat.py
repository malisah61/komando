#!/usr/bin/env python3
"""Komando varlik hatti: render -> SIKISTIRMA -> Godot import -> export.

Tum ayarlar tools/varlik_ayarlari.json dosyasinda. Kullanim:

  python3 tools/varlik/hat.py sikistir [levels/bolum3_art ...] [--zorla]
      Blender ciktisini (PNG/JPG) oyun bicimine cevirir: zemin karolari WebP (karo_px),
      nesne/cati atlaslari saydamligi koruyan kayipli WebP (bos kenar kirpilir),
      v0 icin kucuk zemin onizlemesi (mini harita / buyuk harita). manifest.json guncellenir.
      Eski duzen (v0 dosyalari _art/ kokunde) _art/v0/ altina tasinir.

  python3 tools/varlik/hat.py ayarla
      project.godot [importer_defaults] ve mevcut .import dosyalarini ayarlardan yazar,
      export_presets.cfg exclude_filter'i gunceller.

  python3 tools/varlik/hat.py butce [--build build] [--md cikti.md]
      Bolum x aci basina MB (Godot'un export'a koyacagi .ctex boyutu), paket boyutlari,
      butce asimi uyarilari (GitHub Actions ::warning::).
"""
import json
import os
import re
import shutil
import sys

KOK = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
AYAR_YOLU = os.path.join(KOK, "tools", "varlik_ayarlari.json")


def ayarlar():
    with open(AYAR_YOLU, encoding="utf-8") as f:
        return json.load(f)


# ------------------------------------------------------------------ sikistir
def _sil(yol):
    for p in (yol, yol + ".import"):
        if os.path.exists(p):
            os.remove(p)


def eski_duzeni_tasi(art):
    """_art/manifest.json (v0 kokte) -> _art/v0/"""
    if not os.path.exists(os.path.join(art, "manifest.json")):
        return
    v0 = os.path.join(art, "v0")
    os.makedirs(v0, exist_ok=True)
    for f in os.listdir(art):
        p = os.path.join(art, f)
        if os.path.isfile(p):
            shutil.move(p, os.path.join(v0, f))
    print("  tasindi:", art, "-> v0/")


def _alfa_kirp(im):
    """atlas koordinatlari (0,0)'dan basladigi icin sadece sag/alt bos alan kirpilir"""
    a = im.getchannel("A")
    bb = a.getbbox()
    if bb is None:
        return im.crop((0, 0, 1, 1))
    return im.crop((0, 0, min(im.width, bb[2] + 2), min(im.height, bb[3] + 2)))


def _bolum_ayari(A, d):
    """harita ayarlari + bolume ozel ezmeler (bolum_ozel.<bolum>)"""
    hz = json.loads(json.dumps(A["harita"]))
    ad = os.path.basename(os.path.dirname(os.path.normpath(d)))
    if ad.endswith("_art"):
        ad = ad[:-4]
    for k, v in A.get("bolum_ozel", {}).get(ad, {}).items():
        if isinstance(v, dict) and k in hz:
            hz[k].update(v)
    return hz


def sikistir_aci(d, A, zorla=False):
    from PIL import Image
    Image.MAX_IMAGE_PIXELS = None
    mp = os.path.join(d, "manifest.json")
    if not os.path.exists(mp):
        return
    with open(mp) as f:
        man = json.load(f)
    hz = _bolum_ayari(A, d)
    k = int(man.get("view", 0))
    scale = float(man.get("scale", 1.0))
    W, H = man["size"]
    degisti = False

    # ---- zemin: tum karolari birlestir, yeniden olcekle, karo_px parcalara bol
    zem = man.get("ground", [])
    hedef_karo = int(hz["zemin"]["karo_px"])
    olcek = float(hz["zemin"].get("olcek", 1.0))
    gereken = zorla or any(not g["file"].endswith(".webp") for g in zem) or \
        man.get("ground_tile_px") != hedef_karo or float(man.get("ground_scale", scale)) != scale * olcek
    if zem and gereken:
        px = float(man.get("ground_scale", scale))   # mevcut karolarin piksel/dunya orani
        tuval = Image.new("RGB", (int(round(W * px)), int(round(H * px))), (40, 44, 34))
        for g in zem:
            im = Image.open(os.path.join(d, g["file"])).convert("RGB")
            r = g["rect"]
            tuval.paste(im, (int(round(r[0] * px)), int(round(r[1] * px))))
        yeni_px = scale * olcek
        if abs(yeni_px - px) > 1e-6:
            tuval = tuval.resize((int(round(W * yeni_px)), int(round(H * yeni_px))), Image.LANCZOS)
        for g in zem:
            _sil(os.path.join(d, g["file"]))
        yeni = []
        T = hedef_karo
        for ty in range(0, tuval.height, T):
            for tx in range(0, tuval.width, T):
                parca = tuval.crop((tx, ty, min(tuval.width, tx + T), min(tuval.height, ty + T)))
                fn = "ground_%d_%d.webp" % (tx // T, ty // T)
                parca.save(os.path.join(d, fn), "WEBP", quality=int(hz["zemin"]["kalite"]), method=6)
                yeni.append({"file": fn, "rect": [tx / yeni_px, ty / yeni_px, parca.width / yeni_px, parca.height / yeni_px]})
        man["ground"] = yeni
        man["ground_scale"] = yeni_px
        man["ground_tile_px"] = T
        if k == 0:
            mw = int(hz["mini"]["genislik_px"])
            mini = tuval.resize((mw, max(1, int(round(mw * tuval.height / tuval.width)))), Image.LANCZOS)
            _sil(os.path.join(d, "ground_mini.webp"))
            mini.save(os.path.join(d, "ground_mini.webp"), "WEBP", quality=int(hz["mini"]["kalite"]), method=6)
            man["ground_mini"] = {"file": "ground_mini.webp", "rect": [0, 0, W, H]}
        degisti = True
        print("  zemin: %d karo (%d px), %.2f px/birim" % (len(yeni), T, yeni_px))

    # ---- nesne / cati atlaslari
    for key, ak in (("objects", "nesne"), ("roofs", "cati")):
        sayfalar = man.get(key + "_pages", [key + ".png"] if os.path.exists(os.path.join(d, key + ".png")) else [])
        yeni = []
        for fn in sayfalar:
            if fn.endswith(".webp") and not zorla:
                yeni.append(fn)
                continue
            p = os.path.join(d, fn)
            im = Image.open(p).convert("RGBA")
            if hz[ak].get("kirp", True):
                im = _alfa_kirp(im)
            yfn = os.path.splitext(fn)[0] + ".webp"
            _sil(p)
            im.save(os.path.join(d, yfn), "WEBP", quality=int(hz[ak]["kalite"]),
                    alpha_quality=int(hz[ak]["alfa_kalite"]), method=6)
            yeni.append(yfn)
            degisti = True
        if sayfalar:
            man[key + "_pages"] = yeni
    # gecici render klasoru
    shutil.rmtree(os.path.join(d, "_tmp"), ignore_errors=True)
    if degisti:
        with open(mp, "w") as f:
            json.dump(man, f)
        print("  yazildi:", mp)


def sikistir(yollar, zorla=False):
    A = ayarlar()
    if not yollar:
        yollar = sorted(os.path.join(KOK, "levels", f) for f in os.listdir(os.path.join(KOK, "levels")) if f.endswith("_art"))
    for art in yollar:
        art = os.path.normpath(art)
        if os.path.basename(art).startswith("v") and os.path.basename(art)[1:].isdigit():
            print(art)
            sikistir_aci(art, A, zorla)
            continue
        print(art)
        eski_duzeni_tasi(art)
        for k in range(4):
            d = os.path.join(art, "v%d" % k)
            if os.path.isdir(d):
                sikistir_aci(d, A, zorla)


# ------------------------------------------------------------------ ayarla
def _godot_deger(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    return json.dumps(v)


def _import_yaz(yol, params):
    with open(yol, encoding="utf-8") as f:
        s = f.read()
    if 'importer="texture"' not in s:
        return False
    eski = s
    for k, v in params.items():
        satir = "%s=%s" % (k, _godot_deger(v))
        if re.search(r"^%s=.*$" % re.escape(k), s, re.M):
            s = re.sub(r"^%s=.*$" % re.escape(k), satir, s, flags=re.M)
        elif "[params]" in s:
            s = s.replace("[params]\n", "[params]\n\n" + satir + "\n", 1)
    if s != eski:
        with open(yol, "w", encoding="utf-8") as f:
            f.write(s)
        return True
    return False


def ayarla():
    A = ayarlar()
    gi = A["godot_import"]
    # project.godot importer_defaults (yeni dosyalar: harita karolari CI'da boyle import edilir)
    pg = os.path.join(KOK, "project.godot")
    with open(pg, encoding="utf-8") as f:
        s = f.read()
    blok = "[importer_defaults]\n\ntexture={\n" + ",\n".join(
        '"%s": %s' % (k, _godot_deger(v)) for k, v in gi["harita"].items()) + "\n}\n"
    s = re.sub(r"\[importer_defaults\].*?\n}\n", blok, s, flags=re.S) if "[importer_defaults]" in s else s.rstrip() + "\n\n" + blok
    with open(pg, "w", encoding="utf-8") as f:
        f.write(s)
    n = 0
    # henuz import edilmemis harita dosyalari icin en kucuk .import (Godot gerisini doldurur)
    for dp, _, fs in os.walk(os.path.join(KOK, "levels")):
        for fn in fs:
            if fn.endswith(".webp") and not os.path.exists(os.path.join(dp, fn + ".import")):
                with open(os.path.join(dp, fn + ".import"), "w", encoding="utf-8") as f:
                    f.write('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\n\n')
                    for k, v in gi["harita"].items():
                        f.write("%s=%s\n" % (k, _godot_deger(v)))
                n += 1
    for kat, kok in (("sprite", "assets/sprites"), ("harita", "levels")):
        for dp, _, fs in os.walk(os.path.join(KOK, kok)):
            for fn in fs:
                if fn.endswith(".import"):
                    n += _import_yaz(os.path.join(dp, fn), gi[kat])
    # export disi dosyalar
    ep = os.path.join(KOK, "export_presets.cfg")
    with open(ep, encoding="utf-8") as f:
        s = f.read()
    s = re.sub(r'^exclude_filter=".*"$', 'exclude_filter="%s"' % A["export_haric"], s, flags=re.M)
    with open(ep, "w", encoding="utf-8") as f:
        f.write(s)
    print("ayarlandi: project.godot, %d .import, export_presets.cfg" % n)


# ------------------------------------------------------------------ butce
def _ctex_boyutu(src):
    """Godot'un export'a koyacagi boyut (import edilmisse .ctex, degilse kaynak dosya)."""
    imp = src + ".import"
    if os.path.exists(imp):
        with open(imp, encoding="utf-8") as f:
            s = f.read()
        m = re.search(r'^dest_files=\[(.*)\]$', s, re.M)
        if m:
            yollar = [p.strip().strip('"') for p in m.group(1).split(",")]
            boy = []
            for p in yollar:
                q = os.path.join(KOK, p.replace("res://", ""))
                if os.path.exists(q):
                    boy.append(os.path.getsize(q))
            if boy:
                return max(boy)      # her platform tek bicim alir
    return os.path.getsize(src)


def _mb(b):
    return b / (1024.0 * 1024.0)


def butce(build="build", md=None):
    A = ayarlar()
    B = A["butce_mb"]
    lv = os.path.join(KOK, "levels")
    satirlar = ["| Bölüm | v0 | v1 | v2 | v3 | Toplam MB |", "|---|---|---|---|---|---|"]
    uyari = []
    toplam_harita = 0.0
    for art in sorted(f for f in os.listdir(lv) if f.endswith("_art")):
        aci = []
        for k in range(4):
            d = os.path.join(lv, art, "v%d" % k)
            t = 0
            if os.path.isdir(d):
                for fn in os.listdir(d):
                    if fn.endswith((".webp", ".png", ".jpg")):
                        t += _ctex_boyutu(os.path.join(d, fn))
            aci.append(_mb(t))
        tt = sum(aci)
        toplam_harita += tt
        satirlar.append("| %s | %s | %.1f |" % (art[:-4], " | ".join("%.1f" % a for a in aci), tt))
        if tt > B["yeni_bolum"]:
            uyari.append("%s haritasi %.1f MB (bolum butcesi %d MB)" % (art[:-4], tt, B["yeni_bolum"]))
    spr = 0
    sd = os.path.join(KOK, "assets", "sprites")
    for fn in os.listdir(sd):
        if fn.endswith(".png"):
            spr += _ctex_boyutu(os.path.join(sd, fn))
    satirlar.append("| (karakter sprite'lari) | | | | | %.1f |" % _mb(spr))
    satirlar.append("| **Toplam varlik** | | | | | **%.1f** |" % (toplam_harita + _mb(spr)))
    paket = [("APK", os.path.join(build, "android", "komando.apk"), B["apk"]),
             ("Windows zip", os.path.join(build, "dist", "Komando-Windows.zip"), B["pc_zip"]),
             ("Linux zip", os.path.join(build, "dist", "Komando-Linux.zip"), B["pc_zip"]),
             ("Web .pck", os.path.join(build, "web", "index.pck"), B["web_pck"])]
    psat = ["", "| Paket | MB | Bütçe |", "|---|---|---|"]
    for ad, p, lim in paket:
        if os.path.exists(p):
            m = _mb(os.path.getsize(p))
            psat.append("| %s | %.1f | %d %s |" % (ad, m, lim, "✔" if m <= lim else "✘ AŞILDI"))
            if m > lim:
                uyari.append("%s %.1f MB > butce %d MB" % (ad, m, lim))
    cikti = "\n".join(satirlar + psat)
    print(cikti)
    for u in uyari:
        print("::warning title=Boyut butcesi::" + u)
    if md:
        with open(md, "w", encoding="utf-8") as f:
            f.write(cikti + "\n")
    ss = os.environ.get("GITHUB_STEP_SUMMARY")
    if ss:
        with open(ss, "a", encoding="utf-8") as f:
            f.write("## Boyut bütçesi\n\n" + cikti + "\n\n" + "\n".join("- ⚠️ " + u for u in uyari) + "\n")
    return uyari


if __name__ == "__main__":
    a = sys.argv[1:]
    if not a:
        print(__doc__)
        sys.exit(1)
    if a[0] == "sikistir":
        sikistir([x for x in a[1:] if not x.startswith("--")], "--zorla" in a)
    elif a[0] == "ayarla":
        ayarla()
    elif a[0] == "butce":
        b = a[a.index("--build") + 1] if "--build" in a else os.path.join(KOK, "build")
        m = a[a.index("--md") + 1] if "--md" in a else None
        butce(b, m)
    else:
        print(__doc__)
        sys.exit(1)
