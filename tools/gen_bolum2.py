"""
Bolum 2 - "Karlı Kale" (Norvec fiyordu, kis) harita ureticisi -> levels/bolum2.json

Bolum 1'den buyuk ve zor: 4800x3400, ~40 asker (kis askeri, SS, subay, 4 gozetleme kulesi),
4 kisla, 4 alarm sireni, kilitli hapishane (anahtar gardiyan subayda), sessiz sabotaj, derin kar.

    python3 tools/gen_bolum2.py
"""
import math
from bolum_lib import Lvl, rect

W, H = 4800, 3400
L = Lvl("Bölüm 2 – Karlı Kale", (W, H), 1942)
d = L.d
d["theme"] = "kar"
d["ambient"] = [0.84, 0.88, 1.0]
d["stones"] = 6
d["brief"] = "Lars ile buluş, köy telsizini sustur, Şahin'i hapishaneden çıkar, kodları çal, radarı uçur, fiyorttaki tekneye dön."
d["story"] = (
    "Norveç, Mayıs 1944. Köprü yıkıldı ama Carter'ın getirdiği planlar daha büyük bir şeyi ortaya çıkardı: Binbaşı Richter, "
    "çıkarma filosunu Kuzey Denizi'nde izleyecek bir radar ağı kuruyor. Ağın kalbi Skarvik fiyordundaki eski kalede.\n\n"
    "Keskin nişancı Yüzbaşı Edward 'Şahin' Blake radarı gözetlerken yakalandı ve kalenin hapishanesinde tutuluyor. "
    "Hücrenin anahtarı kale avlusunda devriye gezen gardiyan subayda.\n\n"
    "Reilly kayaklarla güneybatıdaki dağlardan iniyor. Norveçli direnişçi Lars av kulübesinde bekliyor. "
    "Önce balıkçı köyündeki telsizi sustur: kesilirse köy kışlası alarmda takviye gönderemez. Sonra Şahin'i kurtar, "
    "komutanlıktan radar kodlarını al ve tepedeki radarı havaya uçur. Kaçış: fiyordun kıyısındaki balıkçı teknesi.\n\n"
    "Dikkat: derin kar seni yavaşlatır ve iz bırakır. Kulelerdeki nöbetçiler çok uzağı görür. Bir asker alarm sirenine koşarsa "
    "onu yolda durdur.")
d["start"] = [260, 3200]
d["exit"] = [70, 400, 280, 210]

# ------------------------------------------------------------ fiyort (kuzey) ve nehir
# harita kenarini tasar (kenarla cakisan kenar navigasyonda "merge edge" hatasi verir)
fj = [[-60, -60], [W + 60, -60], [W + 60, 280]]
x = W + 60
while x > -60:
    x -= 300
    xx = max(-60, x)
    fj.append([xx, round(300 + 50 * math.sin(xx / 380.0) + (40 if 2300 < xx < 2900 else 0))])
L.ob("water", fj)


def rcx(y):
    return 1650 + 90 * math.sin(y / 500.0)


def rw(y):
    return 170 + 25 * math.sin(y / 300.0)


L.river(rcx, rw, 300, H + 40, [(640, 720), (1595, 1705), (2790, 2860)])
d["bridges"].append([round(rcx(1650) - 160), 1600, 320, 100])     # ana kopru
d["bridges"].append([round(rcx(2825) - 140), 2790, 280, 70])      # guney yaya koprusu
# buz gecidi (kuzey): kopru degil, donmus nehir - kar zemini
d["surfaces"].append({"type": "snow", "points": [[round(rcx(680) - 130), 640], [round(rcx(680) + 130), 640],
                                                 [round(rcx(680) + 130), 720], [round(rcx(680) - 130), 720]],
                      "footprints": True})

# ------------------------------------------------------------ yollar
L.road(0, 1605, 2620, 90)              # bati - kale bati kapisi (ana kopruden gecer)
L.road(3200, 2000, 120, 700)           # kale guney kapisi -> guney karakol
L.road(1820, 2700, 1500, 70)           # guney karakol yolu
L.road(500, 600, 90, 1000)             # koy yolu
L.road(3700, 400, 60, 320)             # arka kapi -> radar patikasi

# ------------------------------------------------------------ derin kar (yavaslatir, iz birakir)
for pts in ([[900, 1950], [1450, 1950], [1480, 2650], [880, 2700]],
            [[1900, 2150], [2550, 2150], [2550, 2600], [1900, 2600]],
            [[3950, 1000], [4700, 1000], [4700, 1600], [3950, 1600]],
            [[2100, 380], [2550, 380], [2550, 640], [2100, 640]]):
    d["surfaces"].append({"type": "snow", "points": pts, "footprints": True, "slow": 0.72})

# ------------------------------------------------------------ BATI: av kulubesi ve balikci koyu
L.house("Av kulübesi", 620, 2280, 200, 140, "E", [0.36, 0.26, 0.18])
L.house("Balıkçı evi 1", 300, 760, 200, 140, "E")
L.house("Balıkçı evi 2", 700, 720, 220, 150, "W", [0.3, 0.32, 0.36])
L.house("Telsiz kulübesi", 300, 1080, 170, 130, "E", [0.28, 0.3, 0.26])
L.house("Ağ deposu", 760, 1120, 240, 160, "W", [0.4, 0.34, 0.26])
L.ob("fence", rect(260, 1320, 800, 10))
L.ob("crate", rect(640, 960, 40, 40))
L.ob("crate", rect(690, 960, 40, 40))
L.ob("truck", rect(1050, 1500, 130, 55))
L.ob("tower", rect(1180, 900, 44, 44))       # telsiz diregi (dekor)

# ------------------------------------------------------------ KALE (dogu)
kx0, ky0, kx1, ky1 = 2600, 700, 4000, 2000
L.walls_box(kx0, ky0, kx1, ky1, {"S": [(3200, 3320)], "W": [(1600, 1700)], "N": [(3690, 3770)]}, th=20)
L.house("Komutanlık", 2760, 820, 340, 220, "S", [0.32, 0.34, 0.38])
L.house("Hapishane", 3520, 820, 300, 220, "S", [0.3, 0.3, 0.3], locked="hucre_anahtari", style="sade")
L.house("Kışla binası", 2760, 1420, 280, 170, "E", [0.36, 0.3, 0.26])
L.house("Garaj", 3540, 1460, 300, 200, "W", [0.34, 0.36, 0.3], style="sade")
L.ob("truck", rect(3280, 1500, 130, 55))
L.ob("tank", rect(3260, 1640, 130, 70))
for i in range(5):
    L.ob("crate", rect(3050 + i * 46, 1840, 40, 40))     # yakit varilleri
L.ob("sandbag", rect(3150, 2030, 50, 26))
L.ob("sandbag", rect(3330, 2030, 50, 26))
L.ob("sandbag", rect(2520, 1560, 26, 40))
L.ob("sandbag", rect(2520, 1700, 26, 40))
L.ob("tent", rect(3150, 820, 140, 90))
L.ob("crate", rect(3320, 1180, 40, 40))
L.ob("crate", rect(2940, 1200, 40, 40))
# avlu icinde siper ve golge
L.bushes([[3120, 1300], [3420, 1060], [2700, 1250], [3880, 1300]], 28)
L.tower(2700, 1880, 200)
L.tower(3900, 1880, 75)
L.tower(2700, 800, 160)
L.tower(3900, 800, 80)

# ------------------------------------------------------------ RADAR (kuzeydogu tepe)
L.ob("sandbag", rect(4180, 440, 26, 120))
L.ob("sandbag", rect(4180, 440, 160, 26))
L.ob("tent", rect(4450, 440, 140, 90))
L.ob("truck", rect(4420, 700, 130, 55))
L.ob("tower", rect(4330, 520, 44, 44))       # radar anteni (dekor)
L.tower(4100, 860, 120)
L.ob("rock", circle=[3980, 520, 40])
L.ob("rock", circle=[4060, 580, 30])

# ------------------------------------------------------------ dogu yaka: ucaksavar ve guney karakol
L.ob("sandbag", rect(2150, 1300, 120, 26))
L.ob("sandbag", rect(2150, 1420, 120, 26))
L.ob("sandbag", rect(2150, 1300, 26, 146))
L.ob("tank", rect(2190, 1340, 80, 60))       # ucaksavar topu
L.house("Karakol", 2150, 2840, 240, 160, "N", [0.3, 0.34, 0.28])
L.ob("tent", rect(2500, 2860, 140, 90))
L.ob("tent", rect(2700, 2860, 140, 90))
L.ob("fence", rect(2080, 2800, 900, 10))

# ------------------------------------------------------------ ASKERLER
G = L.guard
# bati: kulube ve koy
G([[400, 2650], [1100, 2650], [1100, 2950]], None, "kis")              # guney orman devriyesi
G([[900, 2100], [900, 1800], [1300, 1800]], None, "kis")              # kulube kuzeyi
G([[1000, 2360]], 180, "kis")                                         # kulubeye bakan nobetci
G([[350, 1400], [1150, 1400]], None, "kis")                           # koy guney devriyesi (dolgudan sonra kisaltilir)
G([[640, 900], [1000, 900]], None, "kis")                             # koy ici
G([[540, 1190]], 0, "subay")                                          # telsiz kulubesi onu (disari bakar)
G([[360, 1150]], 180, "kis")                                            # telsiz ici
G([[1100, 700]], 90, "kis")                                           # koy dogu
G([[200, 560], [1250, 560]], None, "kis")                             # kiyi devriyesi
# nehir gecitleri
G([[1300, 640], [2100, 760]], None, "kis")                            # buz gecidi devriyesi
G([[1430, 1560]], 0, "kis")                                           # ana kopru bati
G([[1430, 1740]], 0, "kis")
G([[1900, 1560]], 180, "subay")                                       # ana kopru dogu
G([[1900, 1740]], 180, "kis")
G([[1480, 2880]], 0, "kis")                                           # yaya koprusu bati
G([[1950, 2990], [2100, 2400]], None, "kis")                          # yaya koprusu dogu
# dogu yaka
G([[2100, 1250], [2100, 1500]], None, "elit")                         # ucaksavar
G([[2250, 1480]], 90, "kis")
G([[2000, 2050], [2500, 2050], [2500, 2650]], None, "kis")            # derin kar devriyesi
G([[2270, 2780]], 0, "kis")                                           # karakol kapisi
G([[2600, 2780], [3150, 2780]], None, "kis")
G([[2900, 650], [2300, 650]], None, "kis")                            # kale kuzey dis
G([[2560, 1000], [2560, 1450]], None, "kis")                          # kale bati dis
# kale
G([[2560, 1600]], 180, "elit")                                        # bati kapi
G([[2560, 1720]], 180, "elit")
G([[3180, 2080]], 90, "kis")                                          # guney kapi
G([[3340, 2080]], 90, "kis")
G([[2900, 1150], [3450, 1150], [3450, 1330], [2900, 1330]], None, "subay", "hucre_anahtari")  # gardiyan
G([[2800, 1700], [3400, 1700], [3400, 1950]], None, "elit")           # avlu guney
G([[2930, 1100]], 90, "kis")                                          # komutanlik kapisi
G([[3670, 1100]], 90, "elit")                                         # hapishane kapisi
G([[2850, 900], [3000, 980]], None, "subay")                          # komutanlik ici
G([[3600, 880]], 0, "kis")                                            # hapishane ici
G([[3790, 655]], 0, "kis")                                           # arka kapi disi
G([[3600, 1600]], 180, "kis")                                         # garaj
# radar
G([[4250, 650], [4650, 650], [4650, 380]], None, "elit")
G([[4280, 400]], 180, "kis")
G([[3900, 360], [4600, 300]], None, "kis")
G([[4400, 1100], [4400, 1800], [4100, 1800]], None, "kis")            # dogu plato

# ------------------------------------------------------------ KARAKTERLER VE GOREVLER
d["npcs"] = [
    {"id": "lars", "outfit": "direnisci", "name": "Lars", "pos": [760, 2350], "facing": 180},
    {"id": "blake", "outfit": "komando", "name": "Yzb. Blake", "pos": [3740, 900], "facing": 180},
]
d["document"] = [2900, 880]
d["objectives"] = [
    {"id": "temas", "type": "reach", "text": "Av kulübesinde direnişçi Lars ile buluş", "pos": [760, 2350], "radius": 70,
     "gives": {"patlayici": 3},
     "say": [["Lars", "Kayaklarını sakla, burada iz bırakmak ölüm demek. Üç patlayıcı getirdim."],
             ["Lars", "Önce balıkçı köyündeki telsizi sustur. Telsiz kesilirse köy kışlası alarmda yardıma gelemez."],
             ["Lars", "Şahin'in hücre anahtarı avluda devriye gezen gardiyan subayda. Kuzeydeki buz geçidi en sessiz yol."]]},
    {"id": "telsiz", "type": "sabotage", "text": "Köydeki telsiz kulübesinde kabloları kes (sessiz sabotaj)",
     "pos": [400, 1120], "radius": 60, "time": 5.0, "disables_barracks": 0,
     "done_say": [["Çvş. Reilly", "Telsiz sustu. Köy kışlası artık kaleye haber veremez."]]},
    {"id": "anahtar", "type": "have", "item": "hucre_anahtari",
     "text": "Kale avlusundaki gardiyan subaydan hücre anahtarını al"},
    {"id": "sahin", "type": "rescue", "npc": "blake", "text": "Hapishanedeki Yzb. Blake'i (Şahin) kurtar",
     "say": [["Yzb. Edward Blake", "Reilly! Tüfeğimi aldılar ama gözlerim yerinde. Radar tepede, arka kapıdan çıkan patikanın sonunda."],
             ["Çvş. Reilly", "Önce komutanlıktaki kodlar. Sonra radar. Yakınımda kal."]]},
    {"id": "kodlar", "type": "take", "item": "kodlar", "text": "Komutanlıktan radar frekans kodlarını çal",
     "pos": [2900, 880], "done_say": [["Çvş. Reilly", "Frekans kodları... Londra bununla bütün ağı körleştirebilir."]]},
    {"id": "radar", "type": "destroy", "text": "Tepedeki radar antenini havaya uçur", "pos": [4352, 600], "radius": 95,
     "done_say": [["Yzb. Edward Blake", "Radar gitti! Şimdi bütün kale peşimizde. Fiyorda, tekneye!"]]},
    {"id": "flak", "type": "destroy", "text": "Doğu yakadaki uçaksavar topunu uçur (kaçış uçağının yolu)", "pos": [2230, 1372],
     "radius": 90},
    {"id": "teslim", "type": "reach", "text": "Kodları av kulübesindeki Lars'a teslim et", "pos": [760, 2350], "radius": 70,
     "after": ["kodlar", "radar"],
     "say": [["Lars", "Kodlar elimde. Bu gece Londra'ya telsizle geçeceğim. Şimdi fiyorda, tekne sizi bekliyor!"]]},
    {"id": "yakit", "type": "destroy", "optional": True, "text": "Kale avlusundaki yakıt varillerini uçur", "pos": [3150, 1800],
     "radius": 95},
    {"id": "kacis", "type": "exit", "text": "Şahin ile birlikte fiyorttaki balıkçı teknesine dön"},
]

# ------------------------------------------------------------ KISLALAR, SIRENLER, ESYALAR
d["barracks"] = [
    {"pos": [880, 1000], "count": 6, "type": "kis", "delay": 6},      # koy (telsiz kesilince bos)
    {"pos": [3100, 1480], "count": 8, "type": "elit", "delay": 4},    # kale
    {"pos": [4500, 560], "count": 5, "type": "kis", "delay": 6},      # radar
    {"pos": [2600, 2950], "count": 6, "type": "kis", "delay": 7},     # guney karakol
]
d["sirens"] = [[850, 640], [3250, 1240], [3260, 2120], [4250, 760], [2400, 2760]]
d["pickups"] = [
    {"type": "medkit", "pos": [700, 2500]},
    {"type": "medkit", "pos": [1250, 1150]},
    {"type": "medkit", "pos": [3820, 1700]},
    {"type": "medkit", "pos": [2380, 1900]},
    {"type": "ammo", "pos": [1080, 1450]},
    {"type": "ammo", "pos": [2300, 1250]},
    {"type": "ammo", "pos": [3460, 1880]},
    {"type": "item", "item": "patlayici", "count": 1, "pos": [870, 1200]},   # ag deposunda yedek patlayici
]

# ------------------------------------------------------------ GIZLI YOLLAR (bot bulgulari: alternatif rota her zaman olsun)
L.bush_line([1450, 2150], [1450, 2650], 60, 30)       # nehir bati kiyisi (yaya koprusune)
L.bush_line([1350, 900], [1350, 1400], 60, 28)        # koyden buz gecidine
L.bush_line([2350, 900], [2350, 1200], 60, 28)        # buz gecidinden kale bati duvarina
L.bush_line([2700, 480], [3600, 480], 70, 28)         # kale kuzey duvari boyunca (arka kapiya)
L.bushes([[3820, 600], [3880, 520], [4000, 760], [1150, 2250], [1250, 2350], [300, 1950], [200, 1700]], 30)
L.bush_line([2050, 1850], [2050, 2100], 60, 28)
L.ob("rock", circle=[3600, 560, 34])
L.ob("rock", circle=[2500, 560, 30])

# ------------------------------------------------------------ AGACLAR (karli orman)
L.scatter(70, 80, 1900, 1450, 3350, "tree", 26, 40)   # guneybati orman
L.scatter(30, 1850, 2050, 2600, 3350, "tree", 26, 38)
L.scatter(28, 3400, 2100, 4750, 3350, "tree", 26, 40)
L.scatter(22, 4050, 1650, 4750, 2100, "tree", 24, 36)
L.scatter(20, 1850, 800, 2500, 1250, "tree", 24, 34)
L.scatter(18, 80, 1450, 1350, 1850, "bush", 26, 36)
L.scatter(10, 2700, 2100, 3600, 2650, "bush", 26, 34)
L.scatter(8, 4050, 1000, 4700, 1600, "bush", 26, 34)
L.scatter(10, 2800, 360, 4700, 620, "rock", 18, 30)

# (dolgudan sonra eklenir: harita geometrisi ve render degismesin)
# Tur 2 bot bulgusu (gizli bot 5:11'de 0 tespitle kazandi): ek devriyeler, rotalari kesen
L.guard([[1250, 450], [1250, 1000], [1550, 1000]], None, "kis")              # buz gecidi bati
L.guard([[2650, 664], [3450, 664]], None, "elit")                           # kale kuzey duvari
L.guard([[3150, 1080], [3450, 1080], [3450, 1250]], None, "elit")           # avlu kuzey
L.guard([[700, 1700], [1300, 1700], [1300, 2100]], None, "kis")             # kulube-koy arasi
L.guard([[1700, 2000], [2000, 1900], [2400, 1900]], None, "kis")            # dogu yaka orta

# bot bulgusu: koy guney devriyesi telsize giden bati yolunu tamamen kesiyordu -> kisaltildi (dolgu ayni kalsin diye burada)
for g in d["guards"]:
    if g["path"] == [[350, 1400], [1150, 1400]]:
        g["path"] = [[700, 1430], [1150, 1430]]
L.save("levels/bolum2.json")
