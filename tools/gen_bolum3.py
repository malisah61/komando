"""
Bolum 3 - "Denizaltı Üssü" (Saint-Nazaire benzeri liman, Fransa) harita ureticisi -> levels/bolum3.json

Bolum 2'den buyuk ve zor: 5400x3800, ~55 asker (SS agirlikli, subaylar, 5 gozetleme kulesi),
5 kisla, 6 alarm sireni, kilitli kontrol odasi, sessiz sabotaj, takip eden direnisci (Golge),
denizalti bunkeri (ic harita) ve demiryolu deposu.

    python3 tools/gen_bolum3.py
"""
import math
from bolum_lib import Lvl, rect

W, H = 5400, 3800
L = Lvl("Bölüm 3 – Denizaltı Üssü", (W, H), 1943)
d = L.d
d["theme"] = "liman"
d["ambient"] = [0.78, 0.8, 0.94]
d["stones"] = 6
d["brief"] = "Gölge ile buluş, trafoyu sabote et, liman anahtarını al, sevkiyat defterini çal, denizaltı kapılarını uçur, doğu rıhtımındaki tekneye kaç."
d["story"] = (
    "Saint-Nazaire benzeri bir Atlantik limanı, Haziran 1944. Norveç radarı sustu ama Richter'in son kozu denizaltılar: "
    "çıkarma filosuna saldırmak için beton bunkerde hazır bekliyorlar.\n\n"
    "Fransız direnişçi Henri 'Gölge' Duval eski kasabadaki kafede bekliyor. Limanı avucunun içi gibi biliyor ve "
    "artık ekibe katılıyor: onu yanından ayırma, askerler onu da görebilir.\n\n"
    "Önce trafo binasında sigortaları sök: liman kışlasının telsiz hattı kesilir. Liman ofisinden kontrol odasının anahtarını al, "
    "kontrol odasından Richter'in sevkiyat defterini çal. Sonra bunkere gir ve iki denizaltı kapısının mekanizmasına patlayıcı kur.\n\n"
    "Patlamalar bütün limanı ayağa kaldıracak. Doğu rıhtımındaki balıkçı teknesi tek çıkış yolu. "
    "Kulelerdeki nöbetçiler rıhtımı tarıyor; siren direklerine koşan askeri yolda durdur.")
d["start"] = [140, 2300]
d["exit"] = [5060, 2880, 300, 220]

# ------------------------------------------------------------ deniz (guney) ve ic havuz
sea = [[W + 60, H + 60], [-60, H + 60]]
x = -60
while x < W + 60:
    sea.append([x, round(3180 + 40 * math.sin(x / 300.0))])
    x += 300
sea.append([W + 60, 3180])
L.ob("water", sea)
basin = [[2600, 2000], [4400, 2000], [4400, 2860], [3700, 2860], [3700, 2700], [3300, 2700], [3300, 2860], [2600, 2860]]
L.ob("water", basin)
# rihtimlar (beton)
for pts in ([[2450, 1900], [4550, 1900], [4550, 2000], [2450, 2000]],
            [[2450, 2000], [2600, 2000], [2600, 3000], [2450, 3000]],
            [[4400, 2000], [4550, 2000], [4550, 3000], [4400, 3000]],
            [[2450, 2860], [4550, 2860], [4550, 3060], [2450, 3060]],
            [[4550, 2800], [5400, 2800], [5400, 3150], [4550, 3150]]):
    d["surfaces"].append({"type": "beton", "points": pts})

# ------------------------------------------------------------ yollar ve demiryolu
L.road(0, 2250, 2450, 90)              # bati giris -> liman
L.road(1700, 300, 90, 1950)            # kasaba - liman caddesi
L.road(200, 1300, 1500, 80)            # kasaba ana caddesi
L.road(2450, 1380, 2900, 80)           # liman ust yolu (bunker onu kuzey)
L.road(3400, 700, 2000, 60)            # demiryolu 1
L.road(3400, 860, 2000, 60)            # demiryolu 2
L.road(4600, 1440, 80, 1400)           # dogu rihtim yolu

# ------------------------------------------------------------ ESKI KASABA (kuzeybati)
L.house("Kafe", 560, 620, 260, 170, "S", [0.5, 0.28, 0.22])
L.house("Ev 1", 300, 300, 200, 150, "S")
L.house("Ev 2", 900, 300, 220, 160, "S", [0.36, 0.3, 0.26])
L.house("Ev 3", 1250, 600, 200, 160, "W")
L.house("Kilise", 260, 900, 220, 320, "E", [0.42, 0.40, 0.38])
L.house("Garnizon", 900, 980, 300, 200, "N", [0.34, 0.36, 0.3], style="sade")
L.house("Trafo", 1200, 2000, 220, 160, "N", [0.3, 0.3, 0.32], style="sade")
L.ob("wall", rect(560, 1200, 300, 16))
L.ob("truck", rect(1300, 1180, 120, 50))
L.ob("crate", rect(1500, 1000, 40, 40))
L.ob("crate", rect(1500, 1045, 40, 40))
L.ob("fence", rect(1100, 1950, 400, 10))
L.ob("sandbag", rect(1640, 2180, 26, 60))
L.ob("sandbag", rect(1640, 2350, 26, 60))

# ------------------------------------------------------------ LIMAN (orta)
L.house("Liman ofisi", 1950, 1500, 280, 180, "N", [0.32, 0.36, 0.42])
L.house("Ambar A", 2000, 1800, 300, 200, "E", [0.36, 0.34, 0.3], style="sade")
L.house("Denizaltı Bunkeri", 2900, 1480, 1000, 400, "S", [0.45, 0.45, 0.45], style="sade")
L.house("Kontrol odası", 3980, 1500, 300, 220, "W", [0.38, 0.38, 0.4], locked="liman_anahtari", style="sade")
L.house("Gümrük", 2700, 3080, 300, 140, "N", [0.4, 0.36, 0.3])
for i in range(6):
    L.ob("crate", rect(2480 + (i % 3) * 46, 2100 + (i // 3) * 46, 40, 40))
for i in range(6):
    L.ob("crate", rect(4430 + (i % 2) * 46, 2300 + (i // 2) * 46, 40, 40))
L.ob("truck", rect(2480, 2600, 55, 130))
L.ob("truck", rect(4440, 2100, 55, 130))
L.ob("tank", rect(3100, 2920, 130, 70))
L.ob("sandbag", rect(3200, 1950, 120, 26))
L.ob("sandbag", rect(3500, 1950, 120, 26))
L.tower(2520, 1960, 300)
L.tower(4480, 1960, 240)
L.tower(3500, 3010, 270)
L.tower(2300, 2850, 330)

# ------------------------------------------------------------ DEMIRYOLU DEPOSU (kuzeydogu)
for row, y in ((0, 640), (1, 940)):
    for k in range(6):
        L.ob("truck", rect(3600 + k * 260, y, 220, 50))       # vagonlar
L.ob("tent", rect(3500, 300, 160, 100))
L.ob("tent", rect(3700, 300, 160, 100))
L.house("İstasyon", 4100, 260, 320, 180, "S", [0.4, 0.3, 0.26])
for i in range(3):
    L.ob("rock", circle=[4850 + i * 110, 450, 46])            # yakit tanklari
L.ob("fence", rect(4700, 330, 520, 10))
L.ob("fence", rect(4700, 590, 520, 10))
L.tower(5250, 1100, 180)

# ------------------------------------------------------------ ASKERLER
G = L.guard
# bati giris + kasaba
G([[500, 2100], [500, 2500], [1100, 2500]], None, "er")
G([[300, 1700], [1500, 1700]], None, "er")
G([[900, 1420], [900, 1900]], None, "er")
G([[590, 845]], 20, "subay")                                          # kafe onu
G([[690, 690]], 0, "er")                                              # kafe ici
G([[1000, 520], [1600, 520], [1600, 900]], None, "er")
G([[300, 520], [800, 520]], None, "er")
G([[1090, 935]], 270, "elit")                                        # garnizon kapisi
G([[1000, 1060], [1100, 1100]], None, "er")                           # garnizon ici
G([[1350, 1945]], 270, "er")                                           # trafo kapisi
G([[1300, 2100]], 180, "er")                                          # trafo ici
G([[1580, 2200]], 0, "er")                                            # giris kontrol
G([[1580, 2400]], 0, "er")
G([[1860, 600], [1860, 2150]], None, "er")                            # liman caddesi
# liman
G([[2130, 1445]], 270, "subay")                                        # liman ofisi kapisi
G([[2080, 1580], [2150, 1600]], None, "subay")                        # liman ofisi ici
G([[2360, 1300], [3900, 1300]], None, "elit")                         # ust yol devriyesi
G([[2400, 1950], [2400, 2900]], None, "er")                           # bati rihtim
G([[2330, 1900]], 0, "er")                                            # ambar A kapisi
G([[3300, 1940]], 90, "elit")                                         # bunker kapisi
G([[3460, 1940]], 90, "elit")
G([[2700, 1940], [4300, 1940]], None, "elit")                         # bunker onu rihtim
G([[3050, 1600], [3750, 1600]], None, "elit")                         # bunker ici
G([[3400, 1700]], 90, "subay")                                        # bunker ici subay
G([[3940, 1610]], 180, "elit")                                        # kontrol kapisi
G([[4060, 1560], [4200, 1660]], None, "subay")                        # kontrol ici
G([[4500, 2000], [4500, 2850]], None, "er")                           # dogu rihtim
G([[2700, 2960], [4300, 2960]], None, "er")                           # guney rihtim
G([[3500, 2780]], 270, "elit")                                        # havuz agzi
G([[2890, 3040]], 270, "er")                                           # gumruk kapisi
G([[4620, 1500], [4620, 2700]], None, "elit")                         # dogu rihtim yolu
G([[4800, 2900], [5300, 2900]], None, "er")                           # tekne rihtimi
G([[5150, 2780]], 90, "subay")
G([[4950, 2760]], 270, "er")
G([[4200, 1320], [5200, 1320], [5200, 2500]], None, "er")             # dogu cevre
G([[2600, 1100], [3300, 1100]], None, "er")                           # bunker kuzeyi
# demiryolu
G([[3450, 800], [5300, 800]], None, "elit")                           # raylar arasi
G([[3450, 1080], [5300, 1080]], None, "er")
G([[3600, 470]], 0, "er")
G([[4260, 510]], 90, "subay")                                         # istasyon kapisi
G([[4200, 320], [4350, 380]], None, "er")                             # istasyon ici
G([[4700, 270], [5300, 270]], None, "elit")                           # yakit tanklari
G([[5040, 545]], 180, "er")
G([[3300, 400], [3300, 1200]], None, "er")
G([[2200, 400], [3200, 400]], None, "er")                             # kuzey bos arazi
G([[2200, 900], [2200, 1250]], None, "er")
# guneybati sahil
G([[400, 2900], [1900, 2900]], None, "er")
G([[2000, 2600]], 0, "er")
G([[1500, 2700], [2100, 2700], [2100, 3000]], None, "elit")

# ------------------------------------------------------------ KARAKTERLER VE GOREVLER
d["npcs"] = [
    {"id": "henri", "outfit": "direnisci", "name": "Henri 'Gölge' Duval", "pos": [760, 700], "facing": 180},
]
d["document"] = [4180, 1600]
d["objectives"] = [
    {"id": "temas", "type": "reach", "text": "Eski kasabadaki kafede Henri 'Gölge' Duval ile buluş", "pos": [740, 700],
     "radius": 70, "gives": {"patlayici": 3},
     "say": [["Henri Duval", "Bonsoir, çavuş. Üç patlayıcı ve bir harita getirdim. Bundan sonra seninle geliyorum."],
             ["Henri Duval", "Trafo binasındaki sigortaları sökersek liman kışlasının telsizi susar."],
             ["Henri Duval", "Kontrol odası kilitli. Anahtar liman ofisinde, masanın çekmecesinde."]]},
    {"id": "golge", "type": "rescue", "npc": "henri", "text": "Gölge'yi yanına al (seni izler, onu da görebilirler)",
     "say": [["Çvş. Reilly", "Arkamda kal Henri. Ben durunca dur."]]},
    {"id": "trafo", "type": "sabotage", "text": "Trafo binasında sigortaları sök (sessiz sabotaj)", "pos": [1310, 2100],
     "radius": 60, "time": 6.0, "disables_barracks": 1,
     "done_say": [["Henri Duval", "Liman kışlasının hattı koptu. Alarm olursa oradan kimse gelmeyecek."]]},
    {"id": "anahtar", "type": "take", "item": "liman_anahtari", "text": "Liman ofisinden kontrol odasının anahtarını al",
     "pos": [2180, 1640]},
    {"id": "sevkiyat", "type": "take", "item": "sevkiyat", "text": "Kontrol odasından Richter'in sevkiyat defterini çal",
     "pos": [4180, 1600],
     "done_say": [["Çvş. Reilly", "Bütün denizaltıların rotaları... ve Richter'in imzası."]]},
    {"id": "kapi1", "type": "destroy", "text": "Bunkerdeki 1. denizaltı kapısının mekanizmasını uçur", "pos": [3050, 1800],
     "radius": 95},
    {"id": "kapi2", "type": "destroy", "text": "Bunkerdeki 2. denizaltı kapısının mekanizmasını uçur", "pos": [3750, 1800],
     "radius": 95,
     "done_say": [["Henri Duval", "İkisi de gitti! Şimdi koş çavuş, doğu rıhtımına!"]]},
    {"id": "yakit", "type": "destroy", "optional": True, "text": "Demiryolu deposundaki yakıt tanklarını uçur",
     "pos": [4960, 520], "radius": 110},
    {"id": "kacis", "type": "exit", "text": "Gölge ile birlikte doğu rıhtımındaki balıkçı teknesine kaç"},
]

# ------------------------------------------------------------ KISLALAR, SIRENLER, ESYALAR
d["barracks"] = [
    {"pos": [1050, 1300], "count": 6, "type": "er", "delay": 6},      # kasaba garnizonu
    {"pos": [2350, 1450], "count": 8, "type": "elit", "delay": 5},    # liman (trafo kesilince bos)
    {"pos": [3400, 1300], "count": 8, "type": "elit", "delay": 4},    # bunker
    {"pos": [4000, 520], "count": 6, "type": "er", "delay": 6},       # demiryolu
    {"pos": [4800, 2700], "count": 6, "type": "elit", "delay": 6},    # dogu rihtim
]
d["sirens"] = [[1200, 1400], [1750, 2160], [2650, 1450], [3800, 1950], [4300, 1100], [4700, 2650]]
d["pickups"] = [
    {"type": "medkit", "pos": [400, 2200]},
    {"type": "medkit", "pos": [1450, 1500]},
    {"type": "medkit", "pos": [2500, 2400]},
    {"type": "medkit", "pos": [4350, 1800]},
    {"type": "medkit", "pos": [4900, 2500]},
    {"type": "ammo", "pos": [1400, 820]},
    {"type": "ammo", "pos": [2550, 1800]},
    {"type": "ammo", "pos": [3700, 1200]},
    {"type": "ammo", "pos": [4500, 1200]},
    {"type": "item", "item": "patlayici", "count": 1, "pos": [3720, 400]},
]

# ------------------------------------------------------------ GIZLI YOLLAR (her darbogaz icin alternatif)
L.bush_line([200, 2000], [1100, 1880], 70, 30)        # baslangictan kasabaya
L.bush_line([1500, 1450], [1500, 1880], 60, 28)       # kasabadan trafoya
L.bush_line([2350, 800], [2350, 1250], 60, 28)        # kuzeyden bunkere
L.bush_line([2600, 1180], [3300, 1180], 70, 28)       # bunker kuzey duvari boyunca
L.bush_line([4350, 1150], [4350, 1450], 60, 28)       # kontrol odasina kuzeyden
L.bush_line([4800, 1500], [4800, 2600], 70, 30)       # dogu rihtima
L.bushes([[1650, 2650], [1750, 2750], [2300, 2450], [2300, 2550], [5000, 1200], [5100, 1300], [3900, 1250]], 30)
L.bushes([[480, 1100], [700, 1100], [1550, 300], [1550, 400]], 28)

# ------------------------------------------------------------ AGAC / CALI DOLGU
L.scatter(40, 80, 1500, 1400, 2150, "tree", 24, 38)
L.scatter(30, 80, 2450, 1500, 3050, "tree", 24, 36)
L.scatter(26, 1900, 200, 3300, 1150, "tree", 24, 36)
L.scatter(14, 4700, 1250, 5350, 2700, "tree", 24, 34)
L.scatter(14, 80, 1450, 1600, 2100, "bush", 26, 34)
L.scatter(10, 2000, 2400, 2420, 3000, "bush", 24, 32)
L.scatter(10, 1900, 250, 3300, 1150, "bush", 24, 32)
L.scatter(8, 4700, 1300, 5350, 2700, "bush", 24, 32)

L.save("levels/bolum3.json")
