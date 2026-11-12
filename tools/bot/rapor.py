#!/usr/bin/env python3
"""Bot oyun testi: her bolumu birkac tarz ve tohumla oynatir, sonuclari toplar ve
docs/BOT_RAPORU.md'ye analiz + oneriler yazar. Gece gelistirmesi bu rapordan yola cikar.

    GODOT=/yol/godot python3 tools/bot/rapor.py [--seeds 3] [--styles gizli,saldiri,tam] [--levels bolum0,bolum1]
"""
import json, os, re, subprocess, sys, statistics, time, glob

GODOT = os.environ.get("GODOT", "godot")
args = sys.argv[1:]
def opt(name, default):
    return args[args.index(name) + 1] if name in args else default

seeds = int(opt("--seeds", "3"))
styles = opt("--styles", "gizli,saldiri,tam").split(",")
levels = opt("--levels", ",".join(sorted(os.path.basename(p)[:-5] for p in glob.glob("levels/*.json")))).split(",")
limit = opt("--limit", "2400")
out_md = opt("--out", "docs/BOT_RAPORU.md")
os.makedirs("build/bot", exist_ok=True)

jobs = int(opt("--jobs", str(os.cpu_count() or 2)))
plan = [(lv, st, sd) for lv in levels for st in styles for sd in range(1, seeds + 1)]

def play(job):
    lv, st, sd = job
    out = f"build/bot/{lv}_{st}_{sd}.json"
    if os.path.exists(out):
        os.remove(out)
    cmd = [GODOT, "--headless", "--fixed-fps", "60", "-s", "res://tests/bot.gd", "--",
           f"--level=res://levels/{lv}.json", f"--style={st}", f"--seed={sd}", f"--limit={limit}", f"--out={out}"]
    t0 = time.time()
    try:
        subprocess.run(cmd, timeout=2400, capture_output=True)
    except subprocess.TimeoutExpired:
        pass
    if not os.path.exists(out):
        print(f"{lv} {st} {sd} -> rapor yok (cokme?)", flush=True)
        return None
    r = json.load(open(out))
    r["_real"] = round(time.time() - t0, 1)
    r["_lv"] = lv
    print(f"{lv:8s} {st:8s} {sd} -> {r['result']:12s} {r['time']:5.0f}s tespit {r['detections']:3d}  ({r['_real']} sn)", flush=True)
    return r

from concurrent.futures import ThreadPoolExecutor
with ThreadPoolExecutor(max_workers=jobs) as ex:
    runs = [r for r in ex.map(play, plan) if r is not None]

def mmss(s):
    return "%d:%02d" % (int(s) // 60, int(s) % 60)

L = ["# Bot oyun testi raporu", "",
     f"Tarih: {time.strftime('%Y-%m-%d %H:%M')} — {len(runs)} oyun ({', '.join(styles)} × {seeds} tohum).",
     "Bot `tests/bot.gd`: gizli = çömel, devriye bakıyorsa bekle, şüphelenirse geri çekil, arkadan bıçakla; "
     "saldırı = tabancayla temizle; tam = gizli + isteğe bağlı görevler. Gizli/tam sakinken kaydeder, ölünce son kayıttan "
     "devam eder (en çok 4 kez, Tur 4); saldırı tarzı yüklemez.", ""]
findings = []
for lv in levels:
    rs = [r for r in runs if r["_lv"] == lv]
    if not rs:
        continue
    L += [f"## {lv}", "", "| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Ceset sakl./bulundu | Taş | Takılma | Yükleme | Puan | Biten görevler |",
          "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for r in rs:
        res = r["result"] + (f" ({r['reason']})" if r["reason"] else "")
        L.append(f"| {r['style']} | {r['seed']} | {res} | {mmss(r['time'])} | {r['detections']} | {int(r['damage_taken'])} | "
                 f"{r['kills_knife']}/{r['kills_pistol']} | {r['reinforcements']} | {r.get('waits',0)}/{r.get('retreats',0)} | "
                 f"{r.get('bodies_hidden',0)}/{r.get('bodies_found',0)} | {r.get('stones',0)} | {r['stuck']} | {r.get('reloads',0)} | {r.get('points','-')} | "
                 f"{', '.join(o['id'] for o in r['objectives'])} |")
    wins = [r for r in rs if r["result"] == "zafer"]
    L.append("")
    for st in styles:
        q = [r for r in rs if r["style"] == st]
        if q:
            w = [r for r in q if r["result"] == "zafer"]
            rl = sum(r.get("reloads", 0) for r in q)
            L.append(f"- {st}: {len(w)}/{len(q)} zafer" + (f" ({rl} kayıttan devamla)" if rl else "") + (f", ortalama zafer süresi {mmss(statistics.mean(r['time'] for r in w))}" if w else "")
                     + f", ortalama tespit {statistics.mean(r['detections'] for r in q):.1f}")
    L.append(f"Kazanma oranı: **{len(wins)}/{len(rs)}**" + (f", en hızlı zafer {mmss(min(r['time'] for r in wins))}" if wins else ""))
    # olum ve tespit noktalari
    spots = {}
    for r in rs:
        for s in r["detect_spots"]:
            spots[s[2]] = spots.get(s[2], 0) + 1
    if spots:
        top = sorted(spots.items(), key=lambda x: -x[1])[:6]
        L.append("En çok yakalanılan yerler: " + ", ".join(f"{k} ({v})" for k, v in top))
    deaths = {}
    for r in rs:
        if r["death_pos"]:
            deaths[r["death_pos"][2]] = deaths.get(r["death_pos"][2], 0) + 1
    if deaths:
        L.append("Ölüm yerleri: " + ", ".join(f"{k} ({v})" for k, v in sorted(deaths.items(), key=lambda x: -x[1])))
    stuck = [s for r in rs for s in r["stuck_spots"]]
    if stuck:
        L.append("Takılma noktaları: " + ", ".join(f"{s[2]} (hedef {s[3]})" for s in stuck[:8]))
    L.append("")
    # otomatik bulgular
    g = [r for r in rs if r["style"] == "gizli"]
    if wins and min(r["time"] for r in wins) < 600:
        findings.append(f"{lv}: bot {mmss(min(r['time'] for r in wins))}'da kazandı — bölüm çok kısa/kolay. Görev zincirini uzat, hedefleri birbirinden uzaklaştır, kilitli kapı/anahtar gibi ara adımlar ekle.")
    if g and statistics.mean(r["detections"] for r in g) < 2:
        findings.append(f"{lv}: gizli bot neredeyse hiç fark edilmiyor — devriye örtüşmesini ve algılamayı artır.")
    if g and all(r["result"] != "zafer" for r in g) and statistics.mean(r["time"] for r in g) < 120:
        findings.append(f"{lv}: gizli bot ilk 2 dakikada ölüyor — başlangıç bölgesi fazla sert olabilir (ilk devriyeler, kışla mesafesi).")
    s_ = [r for r in rs if r["style"] == "saldiri"]
    if s_ and any(r["result"] == "zafer" for r in s_):
        findings.append(f"{lv}: saldırı tarzı kazanabiliyor — tabanca/çatışma oyuncu lehine; asker isabeti, takviye hızı veya mermi kıtlığı ayarlanmalı.")
    if s_ and all(r["result"] != "zafer" and r["time"] < 60 for r in s_):
        findings.append(f"{lv}: saldırı tarzı 1 dakikada ölüyor — açık çatışma çok cezalandırıcı olabilir; siper/kaçış yolları ekle.")
    if any(r["stuck"] > 2 for r in rs):
        findings.append(f"{lv}: bot takılıyor ({sum(r['stuck'] for r in rs)} kez) — navigasyon/kapı geçişlerini kontrol et.")
    if wins and statistics.mean(r["kills_knife"] + r["kills_pistol"] for r in wins) > 0.6 * rs[0]["guards"]:
        findings.append(f"{lv}: kazanan oyunlarda askerlerin çoğu öldürülüyor — gizlilik ödüllendirilmiyor; ceset bulunması/alarm daha etkili olmalı.")
    if spots:
        k, v = max(spots.items(), key=lambda x: x[1])
        if v >= max(3, len(rs)):
            findings.append(f"{lv}: '{k}' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.")

L += ["## Bulgular ve öneriler (otomatik)", ""]
L += [f"- {f}" for f in findings] or ["- Belirgin sorun yok."]
L += ["", "Ham veriler: `build/bot/*.json` (CI'da `bot-raporu` artefaktı)."]
os.makedirs(os.path.dirname(out_md), exist_ok=True)
open(out_md, "w").write("\n".join(L) + "\n")
print("\n".join(L))
