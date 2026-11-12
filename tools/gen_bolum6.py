"""
Bolum 6 - "Çelik Rampa" (Pas-de-Calais ormaninda V-1 firlatma ussu, baraj vadisi, Temmuz 1944 gecesi)
harita ureticisi -> levels/bolum6.json

2. perdenin acilisi, Bolum 5'ten biraz zor: 6400x4200 (sanat butcesi icin ayni boyut), ~82 asker (SS agirlikli rampa),
9 gozetleme kulesi, 6 projektor, dikenli telli V-1 ussu (4 kapi + tel makasi), duvarli zorunlu calisma kampi
(kilitli gozalti bunkeri, Golge esir), baraj golu + nehir: 3 gecit (kopru, baraj seddi, camurlu sig gecit),
iki anahtar (kamp komutani, rampa subayi), 8 kisla, 9 siren. Kamp erleri ve baraj nobetcileri cogunlukla er:
uniforma giyen komando onlarin arasindan gecebilir, rampadaki SS'ler ve subaylar tanir.

    python3 tools/gen_bolum6.py      (GODOT=... verilirse navigasyon dogrulanir)
"""
import math
from bolum_lib import Lvl, rect

W, H = 6400, 4200
L = Lvl("Bölüm 6 – Çelik Rampa", (W, H), 1946)
d = L.d
d["theme"] = ""
d["ambient"] = [0.66, 0.68, 0.86]          # yaz gecesi, ay isigi
d["stones"] = 6
d["brief"] = ("Ormancı kulübesinde Jeanne ile buluş, baraj santralinin telefon hattını kes, kamp komutanından anahtarı alıp "
              "Gölge'yi gözaltı bunkerinden çıkar, rampa subayından komuta bunkerinin anahtarını al, hedef çizelgesini çal, "
              "V-1 rampasını ve harp başlığı deposunu uçur, Gölge ile kuzeybatıdaki Lysander tarlasına kaç.")
d["story"] = (
    "Temmuz 1944, Pas-de-Calais. Çıkarma başardı, Richter Londra'da sorguda. Ama onun lojistik ağı bir şeyi daha besliyordu: "
    "ormanlara gizlenmiş V-1 rampaları. Her gece Londra'ya uçan bombalar fırlatılıyor.\n\n"
    "Richter'in defterindeki son rampa, baraj gölünün doğusunda dikenli telle çevrili bir orman üssü. Komutanı SS albayı "
    "Wilhelm Brandt, Richter'in eski öğrencisi. Henri 'Gölge' Duval üssü keşfederken yakalandı; nehrin batısındaki "
    "zorunlu çalışma kampında, kilitli gözaltı bunkerinde tutuluyor. Anahtar kamp komutanında.\n\n"
    "Pikardi direnişinden Jeanne Morel ormancı kulübesinde bekliyor. Baraj santralinin telefon hattını kesersen rampanın "
    "batı kışlası çağrılamaz. Nehri üç yerden geçebilirsin: köprü, baraj seddi ya da güneydeki çamurlu sığlık.\n\n"
    "Kamptaki ve barajdaki nöbetçiler sıradan erler; onlardan birinin üniformasını giyersen aralarından geçersin. "
    "Rampayı ise Brandt'ın SS'leri tutuyor, onlar seni tanır. Hedef çizelgesi komuta bunkerinde, anahtarı rampa subayında. "
    "Rampayı ve harp başlıklarını uçur, Gölge'yi de alıp kuzeybatıdaki Lysander tarlasına koş. Uçak şafakta kalkar.")
d["start"] = [300, 4020]
d["exit"] = [60, 120, 260, 240]


def cx(y):
    return 3800 + 70 * math.sin(y / 550.0)


def wd(y):
    return 180 + 240 * max(0.0, 1.0 - abs(y - 1700) / 550.0)   # baraj golu (1150..2250)


# ------------------------------------------------------------ nehir + baraj golu: kopru, baraj seddi, sig gecit
L.river(cx, wd, -40, H + 40, [(880, 1020), (2250, 2400), (3500, 3640)], step=150)
L.block(3500, 1100, 600, 1200, 0)                              # gol (river() bloku dar kalir)
d["bridges"] = [[3740, 880, 260, 140]]
d["surfaces"] = [
    {"type": "beton", "points": rect(3540, 2245, 420, 160)},                   # baraj seddi
    {"type": "mud", "points": rect(3680, 3490, 280, 160), "footprints": True, "slow": 0.8},   # sig gecit
    {"type": "beton", "points": rect(5250, 1780, 950, 260)},                   # firlatma platformu
    {"type": "mud", "points": rect(3000, 3420, 560, 100), "footprints": True},  # gecide inen patika
]
L.road(0, 260, 2070, 60)                # kuzey orman yolu (Lysander tarlasi)
L.road(2000, 300, 70, 3240)             # bati yol (kamp icinden gecer)
L.road(2070, 915, 3200, 70)             # kopru yolu -> rampa
L.road(2600, 2290, 1700, 60)            # baraj yolu (seddin ustu)
L.road(300, 3540, 5000, 60)             # guney yol (sig gecitten)
L.road(5200, 985, 70, 2555)             # rampa ici kuzey-guney yol

# ------------------------------------------------------------ KOY (guneybati)
L.house("Ormancı kulübesi", 700, 3150, 240, 160, "E", [0.42, 0.3, 0.22])
L.house("Çiftlik evi", 1300, 3700, 220, 150, "N")
L.house("Ahır", 1650, 3700, 260, 170, "N", [0.36, 0.33, 0.28], style="sade")
L.house("Şapel", 2400, 3700, 200, 280, "N", [0.42, 0.40, 0.38])
L.house("Han", 2800, 3250, 240, 160, "S", [0.5, 0.32, 0.24])
L.ob("truck", rect(1000, 3420, 120, 50))
L.ob("fence", rect(1250, 3940, 700, 10))

# ------------------------------------------------------------ ZORUNLU CALISMA KAMPI (bati orta): duvarli
KX0, KY0, KX1, KY1 = 800, 1500, 2600, 2700
L.walls_box(KX0, KY0, KX1, KY1, {"N": [(1980, 2090)], "S": [(1980, 2090)], "E": [(2240, 2360)]}, 18, "wall")
L.house("Kamp karargâhı", 1000, 1650, 300, 180, "S", [0.34, 0.36, 0.3], style="sade")
L.house("Kamp kışlası", 1000, 2350, 340, 180, "N", [0.36, 0.34, 0.3], style="sade")
L.house("Gözaltı bunkeri", 2250, 1650, 240, 160, "W", [0.4, 0.4, 0.4], locked="hucre_anahtari", style="sade")
L.ob("tent", rect(1500, 1650, 160, 100))
L.ob("tent", rect(1500, 2400, 160, 100))
L.ob("tent", rect(1720, 2400, 160, 100))
L.ob("truck", rect(2250, 2450, 120, 55))
L.ob("crate", rect(2300, 2100, 60, 60))
L.tower(860, 1560, 45)
L.tower(2540, 2640, 225)

# ------------------------------------------------------------ BARAJ SANTRALI (seddin bati ayagi)
L.house("Baraj santrali", 3100, 2430, 260, 170, "N", [0.38, 0.38, 0.36], style="sade")
L.ob("sandbag", rect(3440, 2200, 26, 70))
L.ob("sandbag", rect(3990, 2380, 26, 70))
L.tower(3450, 2130, 0)

# ------------------------------------------------------------ KOPRU KONTROL NOKTASI
L.ob("sandbag", rect(3620, 820, 26, 70))
L.ob("sandbag", rect(4100, 1010, 26, 70))
L.tower(3600, 740, 0)

# ------------------------------------------------------------ V-1 USSU (dogu): dikenli tel, 4 kapi
AX0, AY0, AX1, AY1 = 4300, 600, 6300, 3300


def tel_line(horiz, c, a, b, gaps):
    cuts = [a] + [v for g in sorted(gaps) for v in g] + [b]
    for i in range(0, len(cuts), 2):
        s, e = cuts[i], cuts[i + 1]
        while e - s > 4:
            s2 = min(e, s + 200)
            L.ob("tel", rect(s, c, s2 - s, 12) if horiz else rect(c, s, 12, s2 - s))
            s = s2


tel_line(True, AY0, AX0, AX1, [(5800, 5900)])                  # kuzey kapi (orman)
tel_line(True, AY1, AX0, AX1, [(5180, 5290)])                  # guney kapi
tel_line(False, AX0, AY0 + 12, AY1, [(900, 1000), (2260, 2380)])   # bati: kopru ve baraj kapilari
tel_line(False, AX1 - 12, AY0 + 12, AY1, [])
L.house("Montaj binası", 4600, 1300, 440, 220, "S", [0.36, 0.38, 0.34], style="sade")
L.house("Komuta bunkeri", 5600, 900, 320, 200, "S", [0.4, 0.4, 0.4], locked="bunker_anahtari", style="sade")
L.house("Harp başlığı deposu", 5500, 2550, 320, 180, "N", [0.38, 0.38, 0.36], style="sade")
L.house("Yemekhane", 4500, 2700, 280, 160, "E", [0.42, 0.34, 0.26])
L.ob("wall", rect(5350, 1880, 700, 56))                       # Walter firlatma rampasi (beton)
L.ob("truck", rect(6080, 1860, 60, 100))                       # buhar jeneratoru (rampanin dibi)
for i in range(3):
    L.ob("crate", rect(5520 + i * 140, 1700, 70, 40))           # arabadaki V-1 govdeleri
L.ob("sandbag", rect(5500, 2060, 140, 26))                      # atis kontrol siperi
for i in range(3):
    L.ob("rock", circle=[6050, 2700 + i * 110, 44])             # T-Stoff yakit tanklari
L.ob("truck", rect(4800, 1600, 140, 50))
L.ob("tank", rect(4500, 2050, 130, 70))
L.ob("sandbag", rect(4400, 1100, 26, 120))
L.tower(4360, 660, 45)
L.tower(6240, 660, 135)
L.tower(6240, 3240, 225)
L.tower(4360, 3240, 315)
L.tower(5250, 2220, 0)                                          # rampa kulesi

for pole, path, sp in (([3480, 2440], [[3250, 2310], [3740, 2320], [4200, 2320]], 80),          # baraj seddi
                       ([3640, 1080], [[3400, 950], [3870, 950], [4220, 950], [4180, 1350]], 80),  # kopru
                       ([4380, 1650], [[4150, 1200], [4150, 2100], [4200, 2700]], 85),         # bati tel boyu
                       ([5300, 1760], [[5300, 1720], [6050, 1720], [6050, 2100], [5300, 2120]], 75),  # rampa
                       ([5130, 3220], [[4500, 3430], [5230, 3420], [6000, 3440]], 80),         # guney kapi
                       ([1700, 1560], [[1000, 2000], [1700, 2060], [2450, 2000]], 70)):        # kamp
    L.ob("projektor", circle=[pole[0], pole[1], 10])
    d.setdefault("searchlights", []).append({"pole": pole, "path": path, "speed": sp, "r": 64})

# ------------------------------------------------------------ ASKERLER
G = L.guard
# koy ve guney
G([[1200, 3460], [2600, 3460]], None, "er")
G([[1500, 4080], [2900, 4080]], None, "er")
G([[2560, 3660]], 270, "er")                                       # sapel kapisi
G([[2500, 3880]], 270, "er")                                       # sapel ici
G([[1840, 3660]], 0, "subay")                                      # ahir onu
G([[600, 2850], [600, 3550]], None, "er")
G([[2860, 3450]], 90, "er")                                        # han kapisi
G([[2900, 3320]], 0, "subay")                                      # han ici
G([[3150, 3150], [3150, 3420], [3150, 3900]], None, "er")
G([[3560, 3570]], 0, "elit")                                       # sig gecit bati
G([[4100, 3610]], 180, "er")                                       # sig gecit dogu
G([[3580, 2700], [3580, 3400]], None, "er")
G([[4200, 3900], [5600, 3900]], None, "er")
# kamp
G([[1950, 1460]], 270, "er")                                       # kuzey kapi
G([[2120, 1460]], 270, "er")
G([[1950, 2740]], 90, "er")                                        # guney kapi
G([[2120, 2740]], 90, "elit")
G([[2640, 2215]], 0, "er")                                         # dogu kapi
G([[2640, 2390]], 0, "er")
G([[1000, 1950], [1850, 1950], [1850, 2200], [1450, 2200]], None, "subay", "hucre_anahtari")   # kamp komutani
G([[1100, 1720], [1200, 1760]], None, "er")                        # karargah ici
G([[1220, 1870]], 90, "er")                                        # karargah kapisi
G([[2400, 1700]], 180, "er")                                       # gozalti ici
G([[2210, 1790]], 180, "elit")                                     # gozalti kapisi
G([[1250, 2440]], 0, "er")                                         # kisla ici
G([[900, 1620], [900, 2600]], None, "er")
G([[1400, 2620], [2500, 2620]], None, "er")
G([[2150, 1600], [2150, 2300]], None, "er")
# baraj ve santral
G([[3170, 2520]], 180, "er")                                       # santral ici (panolara sirtini doner)
G([[3290, 2395]], 270, "er")                                       # santral kapisi
G([[3510, 2330]], 0, "elit")                                       # sed bati ucu
G([[3960, 2330]], 180, "er")                                       # sed dogu ucu
G([[2700, 2450], [2700, 2800], [3400, 2800]], None, "er")
G([[3000, 1300], [3000, 2200]], None, "er")
# kopru
G([[3690, 870]], 0, "elit")
G([[3690, 1040]], 0, "er")
G([[4050, 870]], 180, "er")
G([[4050, 1040]], 180, "subay")
G([[3450, 400], [3450, 1500]], None, "er")
G([[4150, 1150], [4150, 2180]], None, "er")                        # dogu kiyi seridi
G([[4150, 2450], [4150, 3400]], None, "er")
# kuzey orman
G([[400, 620], [1800, 620]], None, "er")
G([[2400, 420], [3300, 420]], None, "er")
G([[4500, 380], [6100, 380]], None, "er")
G([[2300, 1110], [3300, 1110]], None, "er")
G([[620, 420]], 180, "er")                                         # Lysander tarlasi
# V-1 ussu: kapilar
G([[4255, 870]], 180, "elit")                                      # bati kopru kapisi
G([[4255, 1030]], 180, "er")
G([[4255, 2235]], 180, "elit")                                     # bati baraj kapisi
G([[4255, 2405]], 180, "er")
G([[5160, 3345]], 90, "elit")                                      # guney kapi
G([[5310, 3345]], 90, "er")
G([[5780, 560]], 270, "er")                                        # kuzey kapi
G([[5920, 560]], 270, "elit")
# V-1 ussu: binalar
G([[4700, 1400], [4950, 1400]], None, "er")                        # montaj ici
G([[4880, 1555]], 90, "elit")                                      # montaj kapisi
G([[5680, 960], [5850, 960]], None, "elit")                        # komuta bunkeri ici
G([[5700, 1050]], 0, "subay")
G([[5820, 1135]], 90, "elit")                                      # komuta bunkeri kapisi
G([[5720, 2515]], 270, "er")                                       # depo kapisi
G([[5600, 2640]], 0, "er")                                         # depo ici
G([[4600, 2780]], 0, "subay")                                      # yemekhane ici
G([[4815, 2840]], 0, "er")                                         # yemekhane kapisi
# V-1 ussu: devriyeler
G([[4400, 720], [6200, 720]], None, "elit")
G([[4400, 3200], [6200, 3200]], None, "er")
G([[6200, 760], [6200, 3150]], None, "er")
G([[4420, 1600], [4420, 2600]], None, "elit")
G([[5350, 1810], [6050, 1810]], None, "elit")                      # rampa kuzey
G([[5350, 2010], [6050, 2010]], None, "er")                        # rampa guney
G([[5150, 1200], [5150, 2500]], None, "er")
G([[5400, 1300], [6100, 1300], [6100, 1600], [5400, 1600]], None, "subay", "bunker_anahtari")   # rampa subayi
G([[5900, 2300], [5900, 2950]], None, "er")
G([[4700, 1720], [5000, 1720]], None, "er")
G([[4700, 2450], [5300, 2450]], None, "elit")
G([[5400, 3000], [6100, 3000]], None, "elit")
G([[6200, 1880]], 180, "elit")                                     # buhar jeneratoru nobetcisi
# baslangic cevresi
G([[900, 3900], [900, 4100], [1400, 4100]], None, "er")

# ------------------------------------------------------------ KARAKTERLER VE GOREVLER
d["npcs"] = [
    {"id": "jeanne", "outfit": "direnisci", "name": "Jeanne Morel", "pos": [800, 3230], "facing": 0},
    {"id": "henri", "outfit": "direnisci", "name": "Henri 'Gölge' Duval", "pos": [2420, 1760], "facing": 180},
]
d["document"] = [5860, 1050]
d["objectives"] = [
    {"id": "temas", "type": "reach", "text": "Ormancı kulübesinde Jeanne Morel ile buluş", "pos": [800, 3240],
     "radius": 70, "gives": {"patlayici": 3, "tel_makasi": 1},
     "say": [["Jeanne Morel", "Sen Reilly olmalısın. Henri senden çok bahsederdi... yakalanmadan önce."],
             ["Jeanne Morel", "Üç patlayıcı ve bir tel makası. Santralin hattını kes, rampanın batı kışlası çağrılamaz."],
             ["Jeanne Morel", "Kamptaki erler yorgun ve dikkatsiz. Birinin üniformasını giy; ama SS'lere yaklaşma."],
             ["Yzb. Blake (telsiz)", "Tepedeyim, Reilly. Köprü de baraj da tutuluyor. Güneydeki sığlık çamurlu ama boş."]]},
    {"id": "santral", "type": "sabotage", "text": "Baraj santralinde telefon hattını sessizce kes", "pos": [3300, 2500],
     "radius": 60, "time": 6.0, "disables_barracks": 3,
     "done_say": [["Çvş. Reilly", "Hat koptu. Rampanın batı kışlası artık yardım çağıramaz."]]},
    {"id": "anahtar", "type": "have", "item": "hucre_anahtari", "text": "Kamp komutanından gözaltı bunkerinin anahtarını al"},
    {"id": "golge", "type": "rescue", "npc": "henri", "after": ["anahtar"],
     "text": "Gölge'yi gözaltı bunkerinden çıkar (seni izler, onu da görebilirler)",
     "say": [["Henri Duval", "Bonsoir, çavuş. Biraz geç kaldın; ama Brandt'ın planlarını ezberledim."],
             ["Henri Duval", "Çizelge komuta bunkerinde. Anahtar, rampanın etrafında dönüp duran subayda."],
             ["Çvş. Reilly", "Arkamda kal Henri. Bu sefer seni bırakmam."]]},
    {"id": "anahtar2", "type": "have", "item": "bunker_anahtari", "text": "Rampa subayından komuta bunkerinin anahtarını al"},
    {"id": "cizelge", "type": "take", "item": "cizelge", "text": "Komuta bunkerinden V-1 hedef çizelgesini çal",
     "pos": [5860, 1050], "after": ["anahtar2"],
     "done_say": [["Çvş. Reilly", "Londra, Southampton, Portsmouth... ve öteki rampaların yerleri. Hepsi burada."]]},
    {"id": "rampa", "type": "destroy", "text": "V-1 fırlatma rampasının buhar jeneratörünü uçur", "pos": [6040, 1990],
     "radius": 100,
     "done_say": [["Henri Duval", "Bu gece Londra'ya hiçbir şey uçmayacak!"]]},
    {"id": "depo", "type": "destroy", "text": "Harp başlığı deposunu uçur", "pos": [5660, 2470], "radius": 110,
     "done_say": [["Çvş. Reilly", "Bütün orman ayağa kalktı. Şimdi koş!"]]},
    {"id": "yakit", "type": "destroy", "optional": True, "text": "T-Stoff yakıt tanklarını uçur",
     "pos": [6050, 2810], "radius": 110},
    {"id": "kacis", "type": "exit", "text": "Gölge ile birlikte kuzeybatıdaki Lysander tarlasına kaç"},
]

# ------------------------------------------------------------ KISLALAR, SIRENLER, ESYALAR
d["barracks"] = [
    {"pos": [1900, 3300], "count": 6, "type": "er", "delay": 7},      # koy
    {"pos": [1600, 2200], "count": 8, "type": "er", "delay": 5},      # kamp
    {"pos": [2850, 2150], "count": 6, "type": "er", "delay": 6},      # baraj
    {"pos": [4600, 1950], "count": 8, "type": "elit", "delay": 4},    # rampa batisi (santral kesilince bos)
    {"pos": [5800, 1550], "count": 8, "type": "elit", "delay": 4},    # rampa
    {"pos": [3300, 1250], "count": 6, "type": "er", "delay": 6},      # kopru
    {"pos": [4800, 250], "count": 6, "type": "er", "delay": 7},       # kuzey orman
    {"pos": [4600, 3800], "count": 6, "type": "er", "delay": 7},      # guney
]
d["sirens"] = [[1300, 3450], [1450, 1950], [2500, 2550], [3420, 2380], [3540, 1060], [4450, 1250],
               [5450, 2150], [5950, 1200], [5000, 3150]]
d["pickups"] = [
    {"type": "medkit", "pos": [1100, 3950]},
    {"type": "medkit", "pos": [2700, 1700]},
    {"type": "medkit", "pos": [3300, 3050]},
    {"type": "medkit", "pos": [4900, 2950]},
    {"type": "medkit", "pos": [4600, 900]},
    {"type": "ammo", "pos": [1500, 1550]},
    {"type": "ammo", "pos": [3200, 2000]},
    {"type": "ammo", "pos": [5050, 2100]},
    {"type": "ammo", "pos": [6000, 2400]},
    {"type": "item", "item": "patlayici", "count": 1, "pos": [4900, 1460]},   # montaj binasinda yedek
]

# ------------------------------------------------------------ GIZLI YOLLAR
L.bush_line([460, 3900], [460, 3300], 70, 28)                 # baslangictan kulubeye
L.bush_line([700, 2800], [700, 1400], 80, 30)                 # kampin bati duvari disi
L.bush_line([700, 1300], [700, 500], 80, 28)                  # kuzeye, Lysander tarlasina
L.bush_line([2750, 3000], [3450, 3380], 75, 28)               # han -> sig gecit
L.bush_line([2750, 1400], [2750, 2150], 80, 28)               # kamp dogusu -> baraj
L.bush_line([4220, 2550], [4220, 3250], 80, 28)               # dogu kiyi seridi
L.bush_line([4450, 470], [5650, 470], 80, 28)                 # kuzey ormandan kuzey kapiya
L.bush_line([4500, 3420], [5050, 3420], 80, 28)               # guney tel boyu
L.bushes([[1400, 2000], [2400, 1950], [1750, 1850], [2300, 2300]], 28)                  # kamp ici siper
L.bushes([[4500, 1650], [4900, 2250], [5450, 1450], [6150, 2250], [5300, 2800],
          [4800, 3100], [6000, 1100], [4650, 2550]], 30)                                 # rampa ici kamuflaj
L.bushes([[3300, 2650], [2900, 2300], [3350, 1700]], 28)                                # santral cevresi

for p in d["sirens"] + [b["pos"] for b in d["barracks"]] + [k["pos"] for k in d["pickups"]]:
    L.block(p[0], p[1], 0, 0, 60)                              # dolgu agaclari bunlarin ustune gelmesin

# ------------------------------------------------------------ AGAC / CALI DOLGU (V-1 rampalari ormana gizlenir)
L.scatter(42, 80, 420, 1950, 1400, "tree", 24, 38)            # kuzeybati orman
L.scatter(18, 80, 2800, 650, 4150, "tree", 24, 34)            # baslangic ormani
L.scatter(24, 2650, 1180, 3450, 2150, "tree", 24, 36)         # kamp - gol arasi
L.scatter(20, 2150, 80, 3550, 820, "tree", 24, 36)            # kuzey orta
L.scatter(18, 4400, 80, 6350, 330, "tree", 24, 34)            # kuzeydogu orman
L.scatter(12, 4450, 2450, 5350, 3150, "tree", 24, 32)         # us ici
L.scatter(26, 4250, 3650, 6350, 4150, "tree", 24, 36)         # guneydogu orman
L.scatter(10, 2650, 3700, 3600, 4150, "tree", 24, 32)
L.scatter(14, 80, 420, 1950, 1400, "bush", 24, 32)
L.scatter(14, 4250, 3650, 6350, 4150, "bush", 24, 32)
L.scatter(10, 2650, 1180, 3450, 2150, "bush", 24, 30)
L.scatter(8, 2150, 80, 3550, 820, "bush", 24, 30)
L.save("levels/bolum6.json")
