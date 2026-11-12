"""
Bolum 4 - "Gece Treni" (Normandiya demiryolu kavsagi, gece) harita ureticisi -> levels/bolum4.json

Bolum 3'ten buyuk ve zor: 6000x3800, ~66 asker, 6 gozetleme kulesi, 4 PROJEKTOR (Tur 3),
dikenli tel orguyle cevrili manevra sahasi (TEL MAKASIYLA kesilir, Tur 3), 6 kisla, 7 siren,
kilitli nobet barakasi (anahtar subayda), takip eden istihkamci (Kivilcim), gece (karanlik ambiyans).

    python3 tools/gen_bolum4.py      (GODOT=... verilirse navigasyon dogrulanir)
"""
import math
from bolum_lib import Lvl, rect

W, H = 6000, 3800
L = Lvl("Bölüm 4 – Gece Treni", (W, H), 1944)
d = L.d
d["theme"] = ""
d["ambient"] = [0.58, 0.62, 0.86]          # gece
d["stones"] = 6
d["brief"] = ("Marie ile buluş (tel makası ve patlayıcı), kamp karargâhından baraka anahtarını al, Kıvılcım'ı kurtar, sinyal kulübesini sabote et, "
              "sevk listesini çal, lokomotifi ve mühimmat vagonlarını uçur, kuzeydoğudaki kamyona kaç.")
d["story"] = (
    "Haziran 1944'ün ilk gecesi, Normandiya'da bir demiryolu kavşağı. Denizaltılar battı; Richter'in elinde artık trenler var. "
    "Şafakta kavşaktan geçecek mühimmat treni, çıkarma kıyısına giden panzer tümeninin cephanesini taşıyor.\n\n"
    "Demiryolcu direnişçi Marie Lefèvre köydeki lamba evinde bekliyor: tel makası ve patlayıcı getirdi. "
    "Manevra sahası dikenli tel örgüyle çevrili; kapılar tutuluyor ama teli kesersen kendi kapını açarsın.\n\n"
    "İstihkamcı Onb. Sam 'Kıvılcım' Kowalski kuzeybatıdaki kampta, kilitli nöbet barakasında tutuluyor. Anahtar kamp karargâhındaki masada. "
    "Sinyal kulübesinde makinistlere giden sinyali bozarsan tren sahada durur ve sahanın telsiz hattı kesilir.\n\n"
    "Projektörler sahayı tarıyor: ışığa yakalanma, ya da kulesindeki nöbetçiyi sustur. "
    "Lokomotifi ve mühimmat vagonlarını uçurduktan sonra kuzeydoğudaki ormanda bekleyen kamyona koş.")
d["start"] = [160, 3480]
d["exit"] = [5640, 120, 300, 220]

# ------------------------------------------------------------ yollar, raylar
L.road(0, 3300, 2200, 80)               # guney koy yolu
L.road(2150, 2700, 80, 680)             # koyden sahaya
L.road(1100, 300, 80, 2950)             # bati yol (kamp - koy)
L.road(1100, 260, 4800, 80)             # kuzey yol (cikis)
L.road(5560, 300, 80, 1000)             # kuzeydogu orman yolu
for y in (1480, 1700, 1920, 2140, 2360):                 # manevra sahasi raylari
    L.road(1900, y, 2900, 44)
L.road(0, 1920, 1900, 44)               # bati ana hat
L.road(4800, 1920, 1200, 44)            # dogu ana hat

# ------------------------------------------------------------ KOY (guneybati)
L.house("Lamba evi", 820, 2900, 240, 160, "S", [0.45, 0.3, 0.22])
L.house("Ev 1", 300, 2950, 200, 150, "E")
L.house("Ev 2", 1350, 2950, 220, 150, "S", [0.38, 0.3, 0.26])
L.house("Kafe", 1650, 3480, 240, 160, "N", [0.5, 0.3, 0.24])
L.house("Ambar", 420, 2500, 260, 180, "S", [0.36, 0.33, 0.28], style="sade")
L.ob("truck", rect(1700, 3180, 120, 50))
L.ob("fence", rect(250, 2850, 700, 10))

# ------------------------------------------------------------ KAMP (kuzeybati): kilitli nobet barakasi
L.house("Nöbet barakası", 700, 620, 240, 160, "E", [0.32, 0.34, 0.3], locked="baraka_anahtari", style="sade")
L.house("Kamp karargâhı", 300, 900, 260, 180, "N", [0.34, 0.36, 0.3], style="sade")
L.ob("tent", rect(300, 500, 160, 100))
L.ob("tent", rect(300, 660, 160, 100))
L.ob("tent", rect(700, 960, 160, 100))
L.ob("sandbag", rect(1000, 560, 26, 120))
L.ob("truck", rect(500, 1180, 130, 55))
L.walls_box(220, 420, 1060, 1300, {"E": [(800, 920)], "S": [(560, 700)]}, 14, "tel")
L.tower(1000, 1240, 300)

# ------------------------------------------------------------ SINYAL KULUBESI (sahanin batisi)
L.house("Sinyal kulübesi", 1500, 1560, 200, 160, "S", [0.4, 0.28, 0.24])
L.ob("sandbag", rect(1460, 1800, 80, 24))

# ------------------------------------------------------------ MANEVRA SAHASI (dikenli tel cevrili)
YX0, YY0, YX1, YY1 = 1840, 1300, 4860, 2620
# tel orgu: 200'luk parcalar (her biri ayri kesilebilir), kapilar: bati (ana hat), guney (yol), kuzey (yol), dogu (ana hat)
def tel_h(y, x0, x1, gaps):
    x = x0
    while x < x1:
        x2 = min(x1, x + 200)
        if not any(a < (x + x2) / 2 < b for a, b in gaps):
            L.ob("tel", rect(x, y, x2 - x, 12))
        x = x2
def tel_v(x, y0, y1, gaps):
    y = y0
    while y < y1:
        y2 = min(y1, y + 200)
        if not any(a < (y + y2) / 2 < b for a, b in gaps):
            L.ob("tel", rect(x, y, 12, y2 - y))
        y = y2
tel_h(YY0, YX0, YX1, [(3200, 3400)])
tel_h(YY1, YX0, YX1, [(2100, 2300)])
tel_v(YX0, YY0 + 12, YY1, [(1880, 2000)])
tel_v(YX1, YY0 + 12, YY1, [(1880, 2000)])
L.house("Depo ofisi", 2300, 1360, 280, 100, "S", [0.36, 0.32, 0.3])
L.house("Lokomotif hangarı", 4200, 2440, 440, 150, "N", [0.4, 0.4, 0.42], style="sade")
# mühimmat treni (orta ray): lokomotif + 6 vagon
L.ob("tank", rect(3900, 1906, 160, 72))                       # lokomotif
for k in range(6):
    L.ob("truck", rect(2560 + k * 210, 1912, 190, 60))        # muhimmat vagonlari
# diger raylarda bos vagonlar
for k in range(5):
    L.ob("truck", rect(2000 + k * 300, 1488, 220, 50))
    L.ob("truck", rect(2200 + k * 300, 2368, 220, 50))
L.ob("rock", circle=[4560, 1540, 50])                         # su kulesi
for i in range(4):
    L.ob("crate", rect(3000 + i * 46, 2200, 40, 40))
    L.ob("crate", rect(3700 + i * 46, 1760, 40, 40))
L.ob("sandbag", rect(2160, 2500, 120, 26))
L.ob("sandbag", rect(3240, 1380, 120, 26))
L.tower(1960, 1420, 0)
L.tower(4740, 1420, 225)
L.tower(1960, 2500, 0)
L.tower(4740, 2500, 135)
# projektorler: direk + isik yolu (sahanin disindaki yaklasimlari tarar)
for pole, path, sp in (([1880, 1250], [[1300, 1100], [1700, 1250], [1700, 2700], [1300, 2900]], 80),
                       ([4820, 1250], [[5050, 1100], [5000, 2100], [5300, 2700]], 75),
                       ([2200, 2660], [[1950, 2800], [3000, 2850], [4600, 2800]], 90),
                       ([3500, 1260], [[2000, 1150], [3500, 1050], [4700, 1150]], 85)):
    L.ob("projektor", circle=[pole[0], pole[1], 10])
    d.setdefault("searchlights", []).append({"pole": pole, "path": path, "speed": sp, "r": 62})

# ------------------------------------------------------------ DOGU: ana hat + kontrol noktasi, kuzey orman
L.house("Makas kulübesi", 5200, 1700, 180, 140, "S", [0.38, 0.3, 0.26])
L.ob("sandbag", rect(5000, 1850, 26, 160))
L.ob("truck", rect(5400, 520, 55, 130))
L.tower(5450, 1000, 200)
L.house("Orman kulübesi", 4300, 500, 200, 150, "S", [0.36, 0.3, 0.24])

# ------------------------------------------------------------ ASKERLER
G = L.guard
# koy
G([[500, 3250], [1500, 3250]], None, "er")
G([[1250, 2850], [1250, 3200]], None, "er")
G([[940, 3110]], 270, "er")                                        # lamba evi onu (disarida)
G([[1780, 3420]], 270, "subay")                                    # kafe kapisi
G([[2000, 3000], [2000, 3500]], None, "er")
G([[300, 2350], [900, 2350]], None, "er")
# bati yol + kamp
G([[1180, 1400], [1180, 2800]], None, "er")
G([[985, 700]], 0, "elit")                                          # baraka kapisi
G([[820, 700]], 180, "er")                                         # baraka ici (Kivilcim'i bekler)
G([[600, 520], [600, 860]], None, "subay")                         # kamp subayi
G([[340, 940]], 180, "er")                                         # kamp karargahi ici (haritaya bakar)
G([[630, 860]], 270, "er")                                         # karargah kapisi
G([[520, 700], [520, 1150]], None, "er")                           # kamp ici bati
G([[1100, 860]], 0, "er")                                          # kamp dogu kapisi
G([[630, 1330]], 90, "er")                                         # kamp guney kapisi
G([[1300, 500], [1300, 1200]], None, "er")
# sinyal kulubesi
G([[1600, 1780]], 90, "er")
G([[1530, 1600]], 180, "er")                                       # sinyal kulubesi ici (panoya bakar)
G([[1450, 1450], [1750, 1450]], None, "elit")
# saha kapilari ve ici
G([[1790, 1940]], 0, "elit")                                       # bati kapi
G([[1790, 2010]], 0, "er")
G([[2200, 2690]], 270, "elit")                                     # guney kapi
G([[3300, 1250]], 90, "elit")                                      # kuzey kapi
G([[4920, 1940]], 180, "er")                                       # dogu kapi
G([[2440, 1480]], 270, "subay")                                    # depo ofisi kapisi
G([[2380, 1400], [2500, 1420]], None, "er")                        # depo ofisi ici
G([[1950, 1620], [4750, 1620]], None, "elit")                      # saha ici devriyeler
G([[3000, 1840], [4750, 1840]], None, "er")
G([[1950, 2280], [4750, 2280]], None, "elit")
G([[2520, 1960]], 0, "er")                                         # tren basi/arkasi
G([[4100, 1960]], 180, "elit")
G([[3300, 1990]], 270, "subay")                                    # tren ortasi
G([[4420, 2500]], 270, "er")                                       # hangar kapisi
G([[4300, 2520], [4560, 2540]], None, "er")                        # hangar ici
G([[2000, 1700]], 90, "er")
G([[4700, 1400], [4700, 2500]], None, "er")
G([[3600, 2560], [4100, 2560]], None, "er")
# saha cevresi (dis)
G([[1800, 1200], [4900, 1200]], None, "er")
G([[1800, 2720], [4900, 2720]], None, "er")
G([[2600, 3000], [4600, 3000]], None, "elit")
G([[4950, 1300], [4950, 2600]], None, "er")
# dogu
G([[5290, 1880]], 270, "er")                                       # makas kulubesi
G([[5150, 2000], [5800, 2000]], None, "elit")
G([[5200, 2400], [5800, 2400], [5800, 3200]], None, "er")
G([[5000, 3300], [5800, 3300]], None, "er")
G([[3200, 3300], [4800, 3300]], None, "er")
# kuzey yol ve orman
G([[1300, 330], [3000, 330]], None, "er")
G([[3000, 330], [5400, 330]], None, "elit")
G([[4400, 680]], 270, "er")
G([[2200, 700], [3400, 700]], None, "er")
G([[3600, 900], [5000, 900]], None, "er")
G([[5600, 650]], 270, "subay")                                     # cikis kontrol noktasi
G([[5480, 650]], 270, "er")
G([[5800, 500], [5800, 1400]], None, "er")
G([[2400, 1000], [2400, 1250]], None, "er")

# ------------------------------------------------------------ KARAKTERLER VE GOREVLER
d["npcs"] = [
    {"id": "marie", "outfit": "direnisci", "name": "Marie Lefèvre", "pos": [940, 2980], "facing": 90},
    {"id": "sam", "outfit": "pilot", "name": "Onb. Sam 'Kıvılcım' Kowalski", "pos": [760, 690], "facing": 0},
]
d["document"] = [2440, 1400]
d["objectives"] = [
    {"id": "temas", "type": "reach", "text": "Köydeki lamba evinde Marie Lefèvre ile buluş", "pos": [920, 2980],
     "radius": 70, "gives": {"patlayici": 3, "tel_makasi": 1},
     "say": [["Marie Lefèvre", "Geç kaldın çavuş. Tren şafakta geçiyor. Üç patlayıcı ve bir tel makası."],
             ["Marie Lefèvre", "Saha dikenli telle çevrili. Kapılar tutuluyor ama tel her yerde kesilebilir."],
             ["Marie Lefèvre", "Projektörlere dikkat. Kulesindeki nöbetçi düşerse ışık söner."],
             ["Marie Lefèvre", "Amerikalı istihkamcınız kampta, kilitli barakada. Anahtar kamp karargâhında, masada."]]},
    {"id": "anahtar", "type": "take", "item": "baraka_anahtari", "pos": [480, 1000],
     "text": "Kamp karargâhındaki masadan nöbet barakasının anahtarını al"},
    {"id": "kivilcim", "type": "rescue", "npc": "sam", "after": "anahtar",
     "text": "Nöbet barakasındaki Kıvılcım'ı kurtar (seni izler)",
     "say": [["Sam Kowalski", "Tam zamanında! Bana bir patlayıcı göster, gerisini ben hallederim."],
             ["Çvş. Reilly", "Arkamda kal, ışıklara girme."]]},
    {"id": "sinyal", "type": "sabotage", "text": "Sinyal kulübesinde sinyal hattını sessizce boz", "pos": [1600, 1640],
     "radius": 60, "time": 6.0, "disables_barracks": 2,
     "done_say": [["Sam Kowalski", "Tren sahada duracak. Sahanın telsiz hattı da gitti."]]},
    {"id": "liste", "type": "take", "item": "liste", "text": "Depo ofisinden mühimmat sevk listesini çal", "pos": [2440, 1400]},
    {"id": "lokomotif", "type": "destroy", "text": "Mühimmat treninin lokomotifini uçur", "pos": [3980, 1940], "radius": 100,
     "after": "sinyal"},
    {"id": "muhimmat", "type": "destroy", "text": "Mühimmat vagonlarını uçur", "pos": [3100, 1940], "radius": 110,
     "after": "sinyal",
     "done_say": [["Sam Kowalski", "Bum! Bütün kavşak aydınlandı. Koş, çavuş!"]]},
    {"id": "su", "type": "destroy", "optional": True, "text": "Su kulesini uçur (lokomotifler su alamaz)",
     "pos": [4560, 1540], "radius": 100},
    {"id": "kacis", "type": "exit", "text": "Kıvılcım ile birlikte kuzeydoğu ormanındaki kamyona kaç"},
]

# ------------------------------------------------------------ KISLALAR, SIRENLER, ESYALAR
d["barracks"] = [
    {"pos": [1450, 3300], "count": 6, "type": "er", "delay": 7},      # koy
    {"pos": [640, 1220], "count": 8, "type": "er", "delay": 5},       # kamp
    {"pos": [3300, 1560], "count": 8, "type": "elit", "delay": 4},    # saha (sinyal bozulunca bos)
    {"pos": [5300, 2200], "count": 6, "type": "elit", "delay": 5},    # dogu hat
    {"pos": [3800, 560], "count": 6, "type": "er", "delay": 6},       # kuzey orman
    {"pos": [4300, 3050], "count": 6, "type": "er", "delay": 6},      # guney
]
d["sirens"] = [[1250, 3150], [1120, 1100], [1780, 1700], [2700, 2560], [4300, 1360], [5100, 1500], [5300, 700]]
d["pickups"] = [
    {"type": "medkit", "pos": [600, 3150]},
    {"type": "medkit", "pos": [1400, 1250]},
    {"type": "medkit", "pos": [2900, 2200]},
    {"type": "medkit", "pos": [4400, 2200]},
    {"type": "medkit", "pos": [5100, 900]},
    {"type": "ammo", "pos": [1500, 2600]},
    {"type": "ammo", "pos": [3500, 1450]},
    {"type": "ammo", "pos": [4900, 3100]},
    {"type": "ammo", "pos": [2700, 800]},
    {"type": "item", "item": "patlayici", "count": 1, "pos": [4380, 2560]},
]

# ------------------------------------------------------------ GIZLI YOLLAR
L.bush_line([300, 3300], [300, 2750], 70, 30)                # baslangictan koye
L.bush_line([1450, 2700], [1700, 2150], 70, 30)             # koyden sinyal kulubesine
L.bush_line([1300, 1350], [1300, 2000], 70, 28)             # bati yol yaninda
L.bush_line([1150, 400], [1150, 200], 70, 26)
L.bush_line([170, 1250], [170, 520], 70, 30)                 # kampin bati teli disi (tel makasiyla gir)
L.bushes([[300, 1150], [330, 820], [640, 1120]], 28)          # kamp ici siper
L.bush_line([2700, 2800], [4400, 2800], 85, 30)             # sahanin guneyi (isik yolu!)
L.bush_line([1960, 1100], [3100, 1100], 85, 28)             # sahanin kuzeyi
L.bush_line([5100, 1200], [5100, 400], 80, 30)              # dogudan cikisa
L.bush_line([1780, 2150], [1780, 2550], 70, 28)             # sahanin bati teli disi (kes ve gir)
L.bushes([[2150, 1800], [2150, 2240], [3550, 1560], [3550, 2240], [4600, 1760], [4600, 2240]], 28)   # saha ici siper
L.bushes([[700, 1500], [800, 1600], [900, 1500], [560, 2200], [700, 2250]], 30)

# ------------------------------------------------------------ AGAC / CALI DOLGU
L.scatter(40, 80, 1350, 1050, 2250, "tree", 24, 38)
L.scatter(30, 1250, 400, 5300, 1120, "tree", 24, 38)
L.scatter(30, 2400, 2780, 5800, 3700, "tree", 24, 36)
L.scatter(20, 5050, 1100, 5900, 1800, "tree", 24, 36)
L.scatter(12, 80, 3550, 1500, 3750, "tree", 24, 34)
L.scatter(16, 80, 1350, 1050, 2250, "bush", 26, 34)
L.scatter(14, 1250, 400, 5300, 1120, "bush", 24, 32)
L.scatter(12, 2400, 2780, 5800, 3700, "bush", 24, 32)
L.save("levels/bolum4.json")
