"""Poly Haven'dan CC0 dokulari indirir -> assets/textures/<yuva>/{diff,rough}.jpg
GitHub Actions'ta calisir (gelistirme ortaminin internet erisimi kisitli)."""
import json, os, sys, urllib.request

UA = {"User-Agent": "komando-oyunu-doku-indirici"}

def get(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60) as r:
        return r.read()

slots = json.load(open("tools/dokular.json"))
assets = json.loads(get("https://api.polyhaven.com/assets?t=textures"))
ids = sorted(assets.keys())
out_root = "assets/textures"
credits = []
for slot, keys in slots.items():
    if slot.startswith("_"):
        continue
    pick = None
    for k in keys:
        cands = [i for i in ids if i == k] or [i for i in ids if k in i]
        if cands:
            pick = cands[0]
            break
    if not pick:
        print("BULUNAMADI", slot); continue
    files = json.loads(get(f"https://api.polyhaven.com/files/{pick}"))
    d = os.path.join(out_root, slot); os.makedirs(d, exist_ok=True)
    for key, name in (("Diffuse", "diff"), ("Rough", "rough")):
        try:
            url = files[key]["1k"]["jpg"]["url"]
        except KeyError:
            continue
        open(os.path.join(d, name + ".jpg"), "wb").write(get(url))
    credits.append(f"- {slot}: [{assets[pick]['name']}](https://polyhaven.com/a/{pick}) - CC0, Poly Haven")
    print("OK", slot, pick)
open(os.path.join(out_root, "KAYNAKLAR.md"), "w").write("# Dokular (CC0)\n\n" + "\n".join(credits) + "\n")
