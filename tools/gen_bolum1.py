"""
Bolum 1 - "Nehir Operasyonu" harita ureticisi.
Elle yerlestirilen ana yapilar + tohumlu rastgele orman/agaclar -> levels/bolum1.json

    python3 tools/gen_bolum1.py
"""
import json
import math
import random

W, H = 3600, 2600
rnd = random.Random(1944)

lvl = {
    "name": "Bölüm 1 – Nehir Operasyonu",
    "brief": "Direnişle buluş, pilotu kurtar, planları çal, köprüyü uçur, botlara dön.",
    "story": ("Normandiya, Haziran 1944. Müttefik çıkarmasına günler kala, Binbaşı Klaus Richter komutasındaki "
              "Alman birlikleri Orne nehri üzerindeki köprüyü tank takviyesi için kullanmaya hazırlanıyor.\n\n"
              "Çavuş Tom 'Bıçak' Reilly, gece yarısı sahile bir botla çıkarıldı. Görevi: çiftlikte saklanan direniş "
              "temsilcisi Pierre Lemaire'den patlayıcıları almak, köydeki belediye binasında tutulan RAF pilotu "
              "Yüzbaşı James Carter'ı kurtarmak, Richter'in karargâhından saldırı planlarını çalmak ve kuzey köprüsünü "
              "havaya uçurmak.\n\nKöprü yıkıldıktan sonra nehri yalnızca güneydeki dar yaya köprüsünden geçebilirsin. "
              "Şafak sökmeden pilotla birlikte botlara dön. Unutma: tek bir alarm, bütün vadiyi üstüne çeker."),
    "size": [W, H],
    "start": [230, 2400],
    "exit": [60, 2280, 260, 250],
    "document": [3230, 330],
    "roads": [],
    "bridges": [],
    "buildings": [],
    "obstacles": [],
    "surfaces": [],
    "guards": [],
}
R, B, O, S, G = lvl["roads"], lvl["buildings"], lvl["obstacles"], lvl["surfaces"], lvl["guards"]
blocked = []   # agac koymamak icin dolu alanlar (x0, y0, x1, y1)


def rect(x, y, w, h):
    return [[x, y], [x + w, y], [x + w, y + h], [x, y + h]]


def block(x, y, w, h, pad=30):
    blocked.append((x - pad, y - pad, x + w + pad, y + h + pad))


def road(x, y, w, h):
    R.append([x, y, w, h])
    block(x, y, w, h, 10)


def house(name, x, y, w, h, door="S", roof=None):
    b = {"name": name, "rect": [x, y, w, h], "door": door}
    if roof:
        b["roof"] = roof
    B.append(b)
    block(x, y, w, h, 50)


def ob(kind, pts=None, circle=None, **kw):
    o = {"type": kind}
    if pts:
        o["points"] = pts
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        block(min(xs), min(ys), max(xs) - min(xs), max(ys) - min(ys), 20)
    if circle:
        o["circle"] = circle
        block(circle[0] - circle[2], circle[1] - circle[2], circle[2] * 2, circle[2] * 2, 10)
    o.update(kw)
    O.append(o)


def guard(path, facing=None, kind=None, drops=None):
    g = {"path": path}
    if drops:
        g["drops"] = drops
    if facing is not None:
        g["facing"] = facing
    if kind:
        g["type"] = kind
    G.append(g)


# ------------------------------------------------------------ nehir ve kopruler
# nehir: kuzeyden guneye kivrilarak akar; iki kopru icin bosluk birakilir
def river_piece(y0, y1):
    pts_l, pts_r = [], []
    y = y0
    while True:
        cx = 1790 + 70 * math.sin(y / 420.0)
        wdt = 170 + 25 * math.sin(y / 260.0)
        pts_l.append([round(cx - wdt / 2), y])
        pts_r.append([round(cx + wdt / 2), y])
        if y >= y1:
            break
        y = min(y1, y + 250)
    return pts_r + pts_l[::-1]   # saat yonu (diger engellerle ayni sira)


def river_x(y):
    return 1790 + 70 * math.sin(y / 420.0)


for y0, y1 in ((-40, 700), (790, 1900), (1960, H + 40)):
    ob("water", river_piece(y0, y1))
    xs = [river_x(y) for y in range(y0, y1 + 1, 50)]
    block(min(xs) - 110, y0, max(xs) - min(xs) + 220, y1 - y0, 0)

# kuzey kopru (ana yol) ve guney yaya koprusu
nb_x = river_x(745)
lvl["bridges"].append([round(nb_x - 150), 700, 300, 90])
sb_x = river_x(1930)
lvl["bridges"].append([round(sb_x - 140), 1900, 280, 60])

# ------------------------------------------------------------ yollar
road(0, 700, W, 90)                 # dogu-bati ana yol (kuzey kopruden gecer)
road(2380, 790, 90, 1200)           # koy ana caddesi (kuzey-guney)
road(1950, 1180, 1100, 80)          # koy meydani caddesi
road(3020, 640, 80, 560)            # karargaha giden yol
road(1000, 790, 70, 700)            # ciftlik yolu
road(sb_x + 140, 1905, 600, 50)     # guney kopru -> depo
road(200, 2120, 900, 60)            # sahil yolu

# ------------------------------------------------------------ BATI YAKA
# ciftlik
house("Çiftlik evi", 820, 1350, 240, 170, "N")
house("Ambar", 1150, 1300, 220, 260, "W", [0.5, 0.36, 0.2])
ob("fence", rect(760, 1600, 680, 10))
ob("fence", rect(760, 1300, 10, 300))
ob("hedge", rect(300, 1050, 600, 26))
ob("hedge", rect(300, 1850, 26, 300))
ob("hedge", rect(450, 1700, 500, 26))
ob("sandbag", rect(1450, 640, 26, 60))
ob("sandbag", rect(1450, 790, 26, 60))
# kopru bati ucu kontrol noktasi
ob("sandbag", rect(1560, 610, 100, 26))
ob("sandbag", rect(1560, 865, 100, 26))
ob("crate", rect(1520, 900, 40, 40))
# sahil: kayalar
for c in ([420, 2250, 34], [640, 2450, 40], [900, 2300, 30]):
    ob("rock", circle=c)
S.append({"type": "mud", "points": [[1450, 1850], [1680, 1850], [1700, 2050], [1430, 2050]], "footprints": True})
S.append({"type": "mud", "points": [[700, 2060], [1150, 2060], [1150, 2200], [700, 2200]], "footprints": True})

# ------------------------------------------------------------ DOGU YAKA - KOY
house("Kilise", 2050, 880, 210, 280, "S", [0.42, 0.40, 0.38])
house("Fırın", 2520, 880, 200, 150, "W")
house("Ev 1", 2520, 1060, 180, 110, "W")
house("Ev 2", 2050, 1300, 220, 150, "N")
house("Ev 3", 2050, 1520, 180, 170, "E")
house("Ev 4", 2520, 1300, 200, 170, "W")
house("Belediye", 2520, 1530, 260, 190, "W", [0.32, 0.36, 0.42])
B[-1]["locked"] = "belediye_anahtari"      # Tur 2: kilitli kapi, anahtar meydan devriyesindeki subayda
house("Ev 5", 2780, 1290, 160, 140, "N")
ob("wall", rect(2300, 1450, 70, 16))
ob("crate", rect(2290, 1300, 36, 36))
ob("crate", rect(2290, 1340, 36, 36))
ob("truck", rect(2470, 1210, 120, 50))
S.append({"type": "mud", "points": [[2000, 1720], [2380, 1720], [2380, 1880], [2000, 1880]], "footprints": True})

# ------------------------------------------------------------ KARARGAH (kuzeydogu)
cx0, cy0, cx1, cy1 = 2800, 120, 3500, 640
gate0, gate1 = 3010, 3110
ob("wall", rect(cx0, cy0, cx1 - cx0, 16))                    # kuzey
ob("wall", rect(cx0, cy0, 16, cy1 - cy0))                    # bati
ob("wall", rect(cx1 - 16, cy0, 16, cy1 - cy0))               # dogu
ob("wall", rect(cx0, cy1 - 16, gate0 - cx0, 16))             # guney (kapi solu)
ob("wall", rect(gate1, cy1 - 16, cx1 - gate1, 16))           # guney (kapi sagi)
house("Karargâh", 3120, 220, 320, 200, "S", [0.35, 0.38, 0.30])
ob("tent", rect(2860, 200, 150, 100))
ob("tent", rect(2860, 380, 150, 100))
ob("tank", rect(3170, 480, 130, 70))
ob("truck", rect(3330, 470, 120, 50))
ob("crate", rect(3040, 170, 40, 40))
ob("crate", rect(3080, 170, 40, 40))
ob("sandbag", rect(gate0 - 70, cy1 + 20, 60, 26))
ob("sandbag", rect(gate1 + 10, cy1 + 20, 60, 26))
# gozetleme kulesi (gorusu engeller, ustunde nobetci yok - dekor)
ob("rock", circle=[2760, 640, 26])

# ------------------------------------------------------------ YAKIT DEPOSU (guneydogu)
ob("fence", rect(2700, 1980, 600, 10))
ob("fence", rect(2700, 1980, 10, 420))
ob("tent", rect(2780, 2060, 140, 90))
ob("truck", rect(2980, 2050, 130, 55))
ob("truck", rect(2980, 2150, 130, 55))
for i in range(4):
    for j in range(2):
        ob("crate", rect(3180 + i * 46, 2080 + j * 46, 40, 40))
house("Depo", 2780, 2220, 260, 150, "N", [0.4, 0.42, 0.36])

# ------------------------------------------------------------ ASKERLER
# bati yaka
guard([[300, 745], [1400, 745]])                                   # ana yol devriyesi
guard([[1600, 680]], 180, "er")                                    # kopru bati ucu
guard([[1620, 830]], 180)                                          # kopru bati ucu 2
guard([[700, 1250], [1300, 1250], [1300, 1650], [700, 1650]])      # ciftlik cevresi
guard([[1100, 1460]], 90)                                          # ciftlik nobetcisi
guard([[1030, 900]], 270)                                          # ciftlik yolu
guard([[500, 1950], [1200, 1950]])                                 # sahil arkasi
guard([[1560, 1980]], 0)                                           # guney kopru bati
# kopru dogu ucu + koy
guard([[2000, 680]], 180, "subay")                                 # kontrol noktasi subayi
guard([[2000, 830]], 180)
guard([[2420, 840], [2420, 1900]])                                 # ana cadde devriyesi
guard([[1980, 1220], [2960, 1220]], None, "subay", "belediye_anahtari")  # meydan devriyesi: belediye anahtari onda
guard([[2330, 1280]], 0)                                           # meydan nobetcisi
guard([[2300, 1760]], 270)                                         # camur nobetcisi
guard([[2000, 1990], [2180, 2120]])                                # guney kopru dogu (Tur 2: devriye, kopruye bakmayan anlar var)
# karargah
guard([[gate0 - 20, cy1 + 70]], 90)                                # kapi
guard([[gate1 + 20, cy1 + 70]], 90)                                # kapi
guard([[2900, 560], [3420, 560]], None, "elit")                    # avlu devriyesi (SS)
guard([[3060, 250], [3060, 560]], None, "elit")                    # avlu devriyesi 2 (SS)
guard([[3200, 300]], 90, "subay")                                  # karargah ici
guard([[3460, 700], [3460, 1100], [2780, 1100]])                   # dis cevre devriyesi
# depo
guard([[2650, 2000], [2650, 2450], [3400, 2450]])
guard([[3000, 2280]], 0)

# ------------------------------------------------------------ GOREVLER VE KARAKTERLER
guard([[2470, 1625]], 180)                                         # belediye kapisi nobetcisi
guard([[2600, 1572]], 90)                                          # belediye ici
lvl["npcs"] = [
    {"id": "pierre", "outfit": "direnisci", "name": "Pierre", "pos": [1300, 1430], "facing": 180},
    {"id": "carter", "outfit": "pilot", "name": "Yzb. Carter", "pos": [2700, 1665], "facing": 180},
]
lvl["objectives"] = [
    {"id": "temas", "type": "reach", "text": "Çiftlikteki ambarda direnişçi Pierre ile buluş",
     "pos": [1300, 1430], "radius": 70, "gives": {"patlayici": 2},
     "say": [["Pierre Lemaire", "Sonunda geldiniz! Almanlar kuzey köprüsünü yarın sabah tank takviyesi için kullanacak."],
             ["Pierre Lemaire", "İşte iki patlayıcı. Biri köprü için. Diğeri... güneydoğudaki yakıt deposu da güzel yanar."],
             ["Pierre Lemaire", "Bir şey daha: dün düşen İngiliz pilotu köydeki belediye binasında tutuyorlar. Onu geride bırakmayın."]]},
    {"id": "anahtar", "type": "have", "item": "belediye_anahtari",
     "text": "Meydanda devriye gezen subaydan belediye anahtarını al (sessizce bıçakla)"},
    {"id": "pilot", "type": "rescue", "npc": "carter", "text": "Belediye binasında tutulan pilot Carter'ı kurtar",
     "say": [["Yzb. James Carter", "Tanrıya şükür! Richter'in haritalarını gördüm, kuzeydoğudaki duvarlı karargâhta duruyorlar."],
             ["Çvş. Reilly", "Arkamda kal, çalılıklardan ayrılma. Seni görürlerse ikimiz de biteriz."]]},
    {"id": "planlar", "type": "take", "item": "planlar", "text": "Richter'in karargâhından saldırı planlarını çal",
     "pos": lvl["document"],
     "done_say": [["Çvş. Reilly", "Richter'in saldırı planları... Londra bunları görmeli."]]},
    {"id": "kopru", "type": "destroy", "text": "Kuzey köprüsüne patlayıcı kur ve havaya uçur",
     "pos": [round(nb_x), 745], "radius": 95, "bridge": 0,
     "done_say": [["Çvş. Reilly", "Köprü gitti. Takviye artık nehri geçemez. Dönüş için güneydeki yaya köprüsünü kullanmalıyım."]]},
    {"id": "depo", "type": "destroy", "optional": True, "text": "Yakıt deposunu havaya uçur",
     "pos": [3045, 2130], "radius": 95},
    {"id": "kacis", "type": "exit", "text": "Pilot Carter ile birlikte sahildeki botlara dön"},
]

# ------------------------------------------------------------ Tur 2: bot bulgulari icin gizli yollar
# guney yaya koprusu (en cok yakalanilan yer): iki yakada saz/cali, dogu yakada sandik siperi
for c in ([1610, 1780, 30], [1660, 1730, 28], [1985, 2075, 30], [1960, 2140, 30], [2060, 1790, 32], [2010, 1740, 30]):
    ob("bush", circle=c)
ob("crate", rect(1930, 1860, 36, 36))
# Ev 3 yakini: cali seridi + alcak duvar
for c in ([2000, 1600, 30], [2000, 1660, 30], [2260, 1520, 28]):
    ob("bush", circle=c)
# karargah kapisi (2900,700): koruluktan duvar boyunca calilar
for c in ([2760, 560, 30], [2760, 470, 30], [2760, 380, 30]):
    ob("bush", circle=c)
lvl["sirens"] = [[2330, 1180], [2930, 700], [2660, 1990]]
lvl["stones"] = 5

# ------------------------------------------------------------ KISLALAR (kirmizi alarmda takviye) VE ESYALAR
lvl["barracks"] = [
    {"pos": [2950, 300], "count": 6, "type": "elit", "delay": 5},    # karargah avlusu
    {"pos": [2900, 1470], "count": 6, "type": "er", "delay": 7},     # koy
    {"pos": [2900, 2420], "count": 5, "type": "er", "delay": 8},     # depo
]
lvl["pickups"] = [
    {"type": "medkit", "pos": [1240, 1500]},
    {"type": "medkit", "pos": [600, 950]},
    {"type": "medkit", "pos": [2660, 1690]},
    {"type": "ammo", "pos": [1500, 960]},
    {"type": "ammo", "pos": [2280, 1700]},
    {"type": "ammo", "pos": [2960, 520]},
]

# ------------------------------------------------------------ AGACLAR / CALILAR
def free(x, y, r):
    for (x0, y0, x1, y1) in blocked:
        if x0 - r < x < x1 + r and y0 - r < y < y1 + r:
            return False
    for g in G:
        for p in g["path"]:
            if math.hypot(p[0] - x, p[1] - y) < r + 40:
                return False
    if math.hypot(x - lvl["start"][0], y - lvl["start"][1]) < 150:
        return False
    return True


def scatter(n, x0, y0, x1, y1, kind, rmin, rmax):
    placed = 0
    tries = 0
    while placed < n and tries < n * 40:
        tries += 1
        x, y, r = rnd.uniform(x0, x1), rnd.uniform(y0, y1), rnd.uniform(rmin, rmax)
        if free(x, y, r):
            ob(kind, circle=[round(x), round(y), round(r)])
            placed += 1


# guzergah ayrimi icin yollari agacla kapatmayalim; ormanlar:
scatter(55, 80, 80, 1500, 620, "tree", 26, 40)          # kuzeybati ormani
scatter(18, 80, 820, 700, 1300, "tree", 24, 36)
scatter(16, 1950, 60, 2700, 560, "tree", 24, 36)        # karargah bati koruluk
scatter(14, 3150, 1300, 3550, 1900, "tree", 24, 36)
scatter(16, 80, 1100, 650, 1800, "bush", 26, 38)        # gizlenme calilari
scatter(10, 1950, 1950, 2600, 2550, "bush", 26, 38)
scatter(10, 3100, 700, 3550, 1250, "bush", 26, 36)
scatter(8, 2700, 700, 2950, 1050, "bush", 26, 34)
scatter(10, 1200, 2050, 1650, 2550, "bush", 24, 34)

with open("levels/bolum1.json", "w") as f:
    json.dump(lvl, f, ensure_ascii=False, indent=1)
print("yazildi: levels/bolum1.json", len(O), "engel,", len(B), "bina,", len(G), "asker")
