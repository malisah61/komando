"""
Bolum 5 - "Kartal Yuvası" (Richter'in sato karargahi, Normandiya bocage'i, 5 Haziran 1944 safagi)
harita ureticisi -> levels/bolum5.json

Kampanyanin finali, Bolum 4'ten buyuk ve zor: 6400x4200, ~74 asker (SS agirlikli), 7 gozetleme kulesi,
5 projektor, dikenli telli havaalani, cit (bocage) labirenti, duvarli sato (kilitli), nehir + 2 kopru,
7 kisla, 8 siren. Richter esir alinir ve seni izler (askerler onu da gorur).

    python3 tools/gen_bolum5.py      (GODOT=... verilirse navigasyon dogrulanir)
"""
import math
from bolum_lib import Lvl, rect

W, H = 6400, 4200
L = Lvl("Bölüm 5 – Kartal Yuvası", (W, H), 1945)
d = L.d
d["theme"] = ""
d["ambient"] = [0.86, 0.8, 0.84]           # safak
d["stones"] = 6
d["brief"] = ("Değirmende Pierre ile buluş, telefon santralini sabote et, Richter'in kaçış uçağını ve radyo kulesini uçur, "
              "kâhyadan şato anahtarını al, karşı-çıkarma planlarını çal, Richter'i esir al ve nehirdeki tekneye kaç.")
d["story"] = (
    "5 Haziran 1944, şafak. Çıkarma birkaç saat sonra. Richter'in son karargâhı bocage çitleriyle çevrili eski bir şato: "
    "panzer tümenlerine karşı-çıkarma emrini buradan telsizle verecek.\n\n"
    "Pierre Lemaire nehir kıyısındaki değirmende bekliyor. Şatonun telefon santralini susturursan şato kışlası çağrılamaz. "
    "Havaalanındaki Fieseler Storch Richter'in kaçış uçağı; radyo kulesi ise emrin tek yolu. İkisi de gitmeli.\n\n"
    "Şato kilitli; anahtar avluda dolaşan kâhya subayda. İçeride Richter'in kasasında karşı-çıkarma planları var. "
    "Richter'i canlı istiyoruz: onu esir al, askerlerine göstermeden nehirdeki tekneye götür.\n\n"
    "Çitler hem saklanır hem yolu keser; projektörler ve kuleler açık tarlaları tarıyor. Bu son gece, çavuş.")
d["start"] = [3300, 4080]
d["exit"] = [60, 1900, 260, 260]

# ------------------------------------------------------------ nehir (bati) + 2 kopru
L.river(lambda y: 640 + 60 * math.sin(y / 500.0), lambda y: 170, -40, H + 40, [(1150, 1290), (2950, 3090)])
d["bridges"] = [[520, 1150, 260, 140], [520, 2950, 260, 140]]
L.road(0, 1180, 2400, 80)               # kuzey kopru yolu -> sato
L.road(0, 2980, 2000, 80)               # guney kopru yolu -> koy
L.road(2000, 1180, 80, 2900)            # bati-dogu baglanti (kuzey-guney)
L.road(3300, 1950, 80, 2250)            # sato guney yolu (baslangic)
L.road(2080, 1950, 4000, 80)            # orta yol (sato -> havaalani)
L.road(4900, 1200, 1300, 120)           # pist (havaalani)
L.road(4900, 2600, 1300, 120)           # ikinci pist
L.road(5560, 300, 80, 900)              # radyo kulesi yolu

# ------------------------------------------------------------ DEGIRMEN + KOY (guneybati)
L.house("Değirmen", 900, 3300, 220, 180, "E", [0.42, 0.3, 0.22])
L.house("Ev 1", 1400, 3500, 200, 150, "N")
L.house("Ev 2", 1700, 3200, 220, 150, "S", [0.38, 0.3, 0.26])
L.house("Kilise", 2400, 3300, 220, 320, "W", [0.42, 0.40, 0.38])
L.house("Fırın", 1300, 2700, 200, 150, "S", [0.5, 0.32, 0.24])
L.ob("truck", rect(1600, 3020, 120, 50))

# ------------------------------------------------------------ TELEFON SANTRALI (kuzeybati)
L.house("Telefon santrali", 1500, 500, 260, 170, "S", [0.34, 0.36, 0.3], style="sade")
L.ob("sandbag", rect(1460, 720, 120, 26))
L.ob("truck", rect(1850, 520, 55, 130))

# ------------------------------------------------------------ SATO (orta kuzey): duvarli avlu
SX0, SY0, SX1, SY1 = 2500, 500, 4300, 1850
L.walls_box(SX0, SY0, SX1, SY1, {"S": [(3300, 3420)], "W": [(1180, 1290)], "N": [(3800, 3900)]}, 20, "wall")
L.house("Şato", 2950, 750, 820, 460, "S", [0.3, 0.32, 0.38], locked="sato_anahtari")
L.house("Kâhya evi", 2650, 1450, 240, 160, "E", [0.42, 0.32, 0.26])
L.house("Ahır", 3900, 1450, 280, 180, "W", [0.36, 0.33, 0.28], style="sade")
L.house("Muhafız odası", 2620, 600, 220, 160, "S", [0.34, 0.36, 0.3], style="sade")
L.ob("tank", rect(3550, 1500, 130, 70))
L.ob("truck", rect(3150, 1480, 120, 55))
for i in range(4):
    L.ob("hedge", rect(2950 + i * 220, 1300, 160, 26))          # bahce citleri
L.tower(2560, 560, 135)
L.tower(4240, 560, 45)
L.tower(2560, 1790, 225)
L.tower(4240, 1790, 315)

# ------------------------------------------------------------ BOCAGE (cit labirenti): sato ile koy arasi
for row, y in enumerate((2250, 2550, 2850)):
    for k in range(7):
        x = 2200 + k * 260 + (row % 2) * 120
        if 3240 < x + 90 < 3460:
            continue                                         # sato yolu acik
        L.ob("hedge", rect(x, y, 170, 26))

# ------------------------------------------------------------ HAVAALANI (dogu): tel orgu
AX0, AY0, AX1, AY1 = 4700, 1000, 6300, 3000
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
tel_h(AY0, AX0, AX1, [(5500, 5700)])
tel_h(AY1, AX0, AX1, [(5300, 5500)])
tel_v(AX0, AY0 + 12, AY1, [(1940, 2060)])
tel_v(AX1 - 12, AY0 + 12, AY1, [])
L.house("Hangar", 5300, 1500, 500, 260, "S", [0.4, 0.4, 0.42], style="sade")
L.house("Uçuş kulesi", 4900, 2200, 220, 160, "N", [0.36, 0.34, 0.32])
L.ob("truck", rect(5150, 1360, 150, 40))                     # Fieseler Storch (pistte)
L.ob("truck", rect(5700, 2760, 160, 50))                     # nakliye ucagi
for i in range(3):
    L.ob("rock", circle=[6000, 2200 + i * 110, 44])          # yakit tanklari
L.ob("sandbag", rect(4760, 1600, 26, 140))
L.ob("sandbag", rect(5900, 1800, 140, 26))
L.tower(4760, 1060, 20)
L.tower(6240, 1060, 225)
L.tower(6240, 2940, 135)
L.tower(4620, 1450, 270)                                     # bati projektor kulesi
L.tower(1950, 1050, 200)                                     # santral projektor kulesi
for pole, path, sp in (([4690, 1500], [[4500, 1100], [4450, 2000], [4500, 2900]], 85),
                       ([5600, 990], [[4900, 800], [5600, 700], [6200, 850]], 80),
                       ([5400, 3010], [[4800, 3200], [5600, 3300], [6200, 3150]], 80),
                       ([2550, 1900], [[2300, 2050], [3000, 2120], [3700, 2100], [4300, 2050]], 90),
                       ([1900, 1150], [[1500, 1000], [1900, 1600], [1500, 2200]], 75)):
    L.ob("projektor", circle=[pole[0], pole[1], 10])
    d.setdefault("searchlights", []).append({"pole": pole, "path": path, "speed": sp, "r": 64})

# ------------------------------------------------------------ RADYO KULESI (kuzeydogu)
L.ob("tower", rect(5560, 380, 70, 70))
L.house("Telsiz binası", 5800, 300, 240, 150, "W", [0.34, 0.36, 0.3], style="sade")
L.ob("sandbag", rect(5450, 560, 120, 26))

# ------------------------------------------------------------ ASKERLER
G = L.guard
# nehir, kopruler, koy
G([[860, 1120]], 0, "elit")                                        # kuzey kopru dogu ucu
G([[860, 1340]], 0, "er")
G([[860, 2920]], 0, "er")                                          # guney kopru
G([[860, 3140]], 0, "subay")
G([[300, 1000], [300, 2900]], None, "er")                          # bati kiyi
G([[1000, 1500], [1000, 2800]], None, "er")                        # dogu kiyi
G([[1150, 3430]], 0, "er")                                         # degirmen kapisi
G([[1300, 3100], [2300, 3100]], None, "er")
G([[1500, 3800], [2900, 3800]], None, "er")
G([[2350, 3480]], 180, "er")                                       # kilise kapisi
G([[2510, 3340]], 90, "er")                                         # kilise ici
G([[1400, 2900]], 270, "subay")                                    # firin
G([[3000, 3600], [3000, 4000], [3700, 4000]], None, "er")
G([[3600, 3200], [4600, 3200]], None, "elit")
# santral
G([[1630, 730]], 90, "elit")                                       # santral kapisi
G([[1560, 560]], 180, "er")                                        # santral ici (bati panolarina bakar)
G([[1300, 300], [2300, 300]], None, "er")
G([[1400, 800], [1400, 1100], [2400, 1100]], None, "er")
# sato disi
G([[3360, 1910]], 270, "elit")                                     # guney kapi
G([[3360, 2000]], 90, "er")
G([[2440, 1235]], 180, "elit")                                     # bati kapi
G([[3850, 440]], 270, "er")                                        # kuzey kapi
G([[2400, 400], [3300, 400]], None, "er")
G([[4400, 500], [4400, 1900]], None, "elit")
G([[2400, 1400], [2400, 1900]], None, "er")
# sato ici (avlu)
G([[2700, 1300], [4100, 1300], [4100, 1700], [2700, 1700]], None, "subay", "sato_anahtari")  # kahya
G([[2800, 1250], [4000, 1250]], None, "elit")
G([[3350, 1260]], 270, "elit")                                     # sato kapisi
G([[3500, 1700], [3500, 1365]], None, "er")
G([[2900, 700], [4100, 700]], None, "elit")
G([[2770, 1530]], 90, "er")                                        # kahya evi ici
G([[2925, 1530]], 0, "er")                                         # kahya kapisi
G([[4040, 1560]], 180, "er")                                       # ahir ici
G([[2730, 780]], 0, "er")                                          # muhafiz odasi kapisi
G([[2700, 650], [2780, 700]], None, "elit")                        # muhafiz odasi ici
# sato ici (bina)
G([[3050, 850], [3650, 850]], None, "elit")
G([[3200, 1100]], 270, "subay")
G([[3600, 1050], [3700, 1150]], None, "elit")
# bocage
G([[2200, 2400], [4100, 2400]], None, "er")
G([[2300, 2700], [4200, 2700]], None, "er")
G([[2700, 2200], [2700, 3000]], None, "er")
G([[3900, 2200], [3900, 3000]], None, "elit")
G([[3340, 2500]], 90, "er")
# havaalani
G([[4640, 2000]], 180, "elit")                                     # bati kapi
G([[4640, 2080]], 180, "er")
G([[5600, 940]], 270, "er")                                        # kuzey kapi
G([[5400, 3060]], 90, "er")                                        # guney kapi
G([[4800, 1150], [6200, 1150]], None, "elit")                      # pist devriyesi
G([[4800, 1380], [6200, 1380]], None, "er")
G([[5225, 1440]], 90, "subay")                                     # Storch nobetcisi
G([[5550, 1800]], 90, "elit")                                      # hangar kapisi
G([[5400, 1580], [5700, 1680]], None, "er")                        # hangar ici
G([[5010, 2180]], 270, "er")                                       # ucus kulesi kapisi
G([[4960, 2260], [5060, 2300]], None, "subay")                     # ucus kulesi ici
G([[4800, 2500], [6200, 2500]], None, "er")
G([[4800, 2800], [6200, 2800]], None, "elit")
G([[5950, 2100], [5950, 2500]], None, "er")                        # yakit
G([[5200, 1900], [6100, 1900]], None, "er")
# radyo kulesi
G([[5600, 470]], 90, "elit")
G([[5760, 375]], 180, "er")                                        # telsiz binasi kapisi
G([[5850, 340], [5950, 400]], None, "er")                          # telsiz binasi ici
G([[4600, 300], [6200, 300]], None, "er")
G([[4600, 700], [5300, 700]], None, "er")
G([[6200, 400], [6200, 900]], None, "er")
# baslangic cevresi
G([[3000, 3350], [3800, 3350]], None, "er")
G([[4200, 3500], [5200, 3500], [5200, 4000]], None, "er")
G([[2000, 2000], [2000, 2800]], None, "elit")

# ------------------------------------------------------------ KARAKTERLER VE GOREVLER
d["npcs"] = [
    {"id": "pierre", "outfit": "direnisci", "name": "Pierre Lemaire", "pos": [1000, 3380], "facing": 0},
    {"id": "richter", "outfit": "alman_subay", "name": "Binbaşı Klaus Richter", "pos": [3500, 900], "facing": 90},
]
d["document"] = [3100, 900]
d["objectives"] = [
    {"id": "temas", "type": "reach", "text": "Nehir kıyısındaki değirmende Pierre Lemaire ile buluş", "pos": [1000, 3390],
     "radius": 70, "gives": {"patlayici": 3, "tel_makasi": 1},
     "say": [["Pierre Lemaire", "Sonunda geldin, Reilly. İşte üç patlayıcı ve bir tel makası."],
             ["Pierre Lemaire", "Telefon santralini susturursan şato kışlası çağrılamaz."],
             ["Pierre Lemaire", "Şatonun anahtarı kâhyada; avluda dolaşır. Richter'i canlı istiyorlar."]]},
    {"id": "santral", "type": "sabotage", "text": "Telefon santralinde hatları sessizce kes", "pos": [1630, 590],
     "radius": 60, "time": 6.0, "disables_barracks": 2,
     "done_say": [["Çvş. Reilly", "Şato artık kışlayı arayamaz."]]},
    {"id": "ucak", "type": "destroy", "text": "Havaalanındaki Fieseler Storch'u (Richter'in kaçış uçağı) uçur",
     "pos": [5225, 1380], "radius": 100},
    {"id": "radyo", "type": "destroy", "text": "Radyo kulesini uçur (karşı-çıkarma emri gidemesin)", "pos": [5595, 415],
     "radius": 100},
    {"id": "anahtar", "type": "have", "item": "sato_anahtari", "text": "Kâhyadan şatonun anahtarını al"},
    {"id": "plan", "type": "take", "item": "rota", "text": "Şatodaki kasadan karşı-çıkarma planlarını çal",
     "pos": [3100, 900], "after": "anahtar",
     "done_say": [["Çvş. Reilly", "Panzer tümenlerinin bütün rotaları... Londra bunu çok sevecek."]]},
    {"id": "richter", "type": "rescue", "npc": "richter", "after": "anahtar",
     "text": "Richter'i esir al (seni izler, askerlerine gösterme)",
     "say": [["Klaus Richter", "Demek sonunda yüz yüzeyiz, çavuş. Buradan asla çıkamazsınız."],
             ["Çvş. Reilly", "Yürü, binbaşı. Ağzını açarsan ilk kurşun senin."]]},
    {"id": "yakit", "type": "destroy", "optional": True, "text": "Havaalanının yakıt tanklarını uçur",
     "pos": [6000, 2310], "radius": 110},
    {"id": "kacis", "type": "exit", "text": "Richter ile birlikte nehrin batısındaki tekneye kaç"},
]

# ------------------------------------------------------------ KISLALAR, SIRENLER, ESYALAR
d["barracks"] = [
    {"pos": [1900, 3500], "count": 6, "type": "er", "delay": 7},      # koy
    {"pos": [1700, 900], "count": 6, "type": "er", "delay": 6},       # santral
    {"pos": [3360, 1650], "count": 8, "type": "elit", "delay": 4},    # sato (santral kesilince bos)
    {"pos": [4600, 1950], "count": 8, "type": "elit", "delay": 5},    # havaalani batisi
    {"pos": [5500, 2300], "count": 8, "type": "elit", "delay": 5},    # havaalani
    {"pos": [5300, 600], "count": 6, "type": "er", "delay": 6},       # radyo
    {"pos": [4300, 3600], "count": 6, "type": "er", "delay": 7},      # guney tarlalar
]
d["sirens"] = [[1250, 3000], [2100, 1050], [3200, 1900], [2700, 1250], [4500, 1900], [5900, 1700], [5450, 650], [3800, 3300]]
d["pickups"] = [
    {"type": "medkit", "pos": [1200, 3700]},
    {"type": "medkit", "pos": [2200, 2000]},
    {"type": "medkit", "pos": [3700, 2600]},
    {"type": "medkit", "pos": [4600, 3300]},
    {"type": "medkit", "pos": [4500, 800]},
    {"type": "ammo", "pos": [1800, 2400]},
    {"type": "ammo", "pos": [3000, 1550]},
    {"type": "ammo", "pos": [5100, 2600]},
    {"type": "ammo", "pos": [4200, 2300]},
    {"type": "item", "item": "patlayici", "count": 1, "pos": [5480, 1650]},
]

# ------------------------------------------------------------ GIZLI YOLLAR
L.bush_line([3150, 4000], [2500, 3700], 75, 30)               # baslangictan koye
L.bush_line([1300, 3250], [1300, 3000], 70, 28)
L.bush_line([1200, 2500], [1200, 1400], 80, 30)               # dogu kiyi boyunca kuzeye
L.bush_line([1300, 900], [1300, 400], 70, 28)                 # santrale
L.bush_line([2300, 450], [2300, 1050], 75, 28)                # sato bati duvari disi
L.bush_line([4450, 2200], [4450, 3000], 80, 30)               # havaalani batisi
L.bush_line([2100, 3000], [4380, 3000], 85, 30)               # bocage'in guneyinden havaalanina gizli yol
L.bush_line([4650, 600], [5300, 600], 80, 28)                 # radyo yolu
L.bushes([[2700, 1100], [4100, 1100], [3000, 1700], [3800, 1180]], 28)    # avlu ici siper
L.bushes([[5000, 1700], [5100, 1800], [6100, 1650], [6100, 2700], [5200, 2900]], 30)  # havaalani ici
L.bushes([[2550, 2400], [3100, 2650], [3700, 2400], [4000, 2900]], 30)    # bocage

# ------------------------------------------------------------ AGAC / CALI DOLGU
L.scatter(40, 1050, 1400, 1950, 2900, "tree", 24, 38)
L.scatter(30, 80, 80, 1400, 1100, "tree", 24, 38)
L.scatter(30, 3500, 3200, 6300, 4150, "tree", 24, 36)
L.scatter(24, 4450, 80, 6350, 950, "tree", 24, 34)
L.scatter(16, 80, 3200, 560, 4150, "tree", 24, 34)
L.scatter(16, 1050, 1400, 1950, 2900, "bush", 26, 34)
L.scatter(14, 3500, 3200, 6300, 4150, "bush", 24, 32)
L.scatter(10, 80, 80, 1400, 1100, "bush", 24, 32)
L.save("levels/bolum5.json")
