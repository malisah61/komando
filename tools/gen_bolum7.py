"""
Bolum 7 - "Sisli Ada" (Baltik kiyisinda roket deneme ussu, Usedom benzeri ada, Agustos 1944 gecesi)
harita ureticisi -> levels/bolum7.json

2. perdenin ikinci bolumu, Bolum 6'dan biraz zor: 6400x4200 (sanat butcesi icin ayni boyut), ~88 asker,
9 gozetleme kulesi, 7 projektor, dikenli telli deneme sahasi (5 kapi + tel makasi), duvarli zorunlu calisma kampi,
ada ortasinda kanal: 3 gecit (demiryolu koprusu, yol koprusu, sazlik sig gecit), kuzeyde deniz ve kumul.
Kilik/uniforma YOK (kalici kural): gizli yollar = sazlik + kumul calilari, kanal boyu kamis seridi, kamp arkasindaki
kanalizasyon hendegi, taş yigini (dikkat dagitma), projektor araliklarini kollama (zamanlama).

    python3 tools/gen_bolum7.py      (GODOT=... verilirse navigasyon dogrulanir)
"""
import math
from bolum_lib import Lvl, rect

W, H = 6400, 4200
L = Lvl("Bölüm 7 – Sisli Ada", (W, H), 1947)
d = L.d
d["theme"] = ""
d["ambient"] = [0.62, 0.66, 0.8]           # sisli Baltik gecesi
d["stones"] = 7
d["brief"] = ("Balıkçı kulübesinde Jan Nowak ile buluş, kanalın batısındaki trafo istasyonunu sessizce kes, deneme sahası "
              "subayından laboratuvar anahtarını al, laboratuvardan A-4 çizimlerini çal, VII numaralı deneme kulesindeki "
              "roketi ve sıvı oksijen tesisini uçur, kuzeybatı kumsalındaki Kowalski'nin motorbotuna kaç.")
d["story"] = (
    "Ağustos 1944, Baltık kıyısı. Henri'nin Brandt'ın çizelgesinde bulduğu isim bir adaya çıkıyor: sisle örtülü, "
    "ormanlık bir kum adası. Ormanın içinde Almanların en gizli silahını, ses hızını aşan A-4 roketini denedikleri "
    "dev beton kuleler var.\n\n"
    "Adadaki zorunlu çalışma kampında tutulan Polonyalı işçiler aylardır roketin parçalarını ezberleyip Londra'ya "
    "bilgi kaçırıyor. Onlardan biri, Jan Nowak, kamptan kaçtı ve kuzeydeki balıkçı kulübesinde saklanıyor. "
    "Kowalski'nin bıraktığı patlayıcılar onda.\n\n"
    "Ada ortadan bir kanalla bölünmüş. Kanalı üç yerden geçebilirsin: kuzeydeki demiryolu köprüsü, ortadaki yol "
    "köprüsü ya da güneydeki sazlık sığlık (çamurda iz kalır). Batı kıyıdaki trafo istasyonu deneme sahasının batı "
    "kışlasına telefonla bağlı: hattı kesersen o kışla çağrılamaz.\n\n"
    "Deneme sahası dikenli telle çevrili ve projektörler ışığı yol boyunca gezdiriyor. Işıklar arasındaki boşluğu kolla, "
    "kamışların ve kumul çalılarının içinden ilerle. Laboratuvarın anahtarı sahada dolaşan subayda. Çizimleri al, "
    "roketi kulesinde ve oksijen tesisini havaya uçur, sonra kuzeybatı kumsalına koş: Kowalski motorbotla bekliyor, "
    "ama gün doğmadan kalkacak.")
d["start"] = [300, 4020]
d["exit"] = [60, 240, 300, 220]


def cx(y):
    return 3300 + 80 * math.sin(y / 600.0)


def wd(y):
    return 200 + 60 * max(0.0, 1.0 - abs(y - 2900) / 500.0)    # sazlik oncesi genisler


# ------------------------------------------------------------ deniz (kuzey) + kanal (orta): 3 gecit
sea = []
for x in range(700, W + 1, 200):
    sea.append([x, 200 + round(30 * math.sin(x / 300.0))])
sea += [[W, -20], [700, -20]]
L.ob("water", sea)
L.block(700, 0, W - 700, 260, 0)
L.river(cx, wd, 230, H + 40, [(700, 840), (2000, 2140), (3500, 3660)], step=150)
d["bridges"] = [[3240, 700, 280, 140], [3140, 2000, 280, 140]]
d["surfaces"] = [
    {"type": "mud", "points": rect(3130, 3490, 290, 180), "footprints": True, "slow": 0.8},    # sazlik sig gecit
    {"type": "beton", "points": rect(5000, 1300, 800, 520)},                                   # deneme kulesi platformu
    {"type": "mud", "points": rect(2500, 3520, 620, 110), "footprints": True},                 # gecide inen patika
    {"type": "beton", "points": rect(4300, 2700, 600, 300)},                                   # oksijen tesisi avlusu
]
L.road(0, 300, 3500, 60)                 # kuzey yol (kumsal boyu)
L.road(3500, 740, 2900, 60)              # demiryolu koprusu -> saha
L.road(1800, 360, 70, 3300)              # bati yol (kamp)
L.road(1870, 2040, 4400, 60)             # yol koprusu -> saha ortasi
L.road(300, 3580, 4600, 60)              # guney yol (sazliktan)
L.road(4700, 800, 70, 2800)              # saha ici kuzey-guney yol

# ------------------------------------------------------------ BALIKCI KOYU (kuzeybati, kumsal)
L.house("Balıkçı kulübesi", 420, 700, 220, 150, "S", [0.4, 0.32, 0.24])
L.house("Ağ deposu", 800, 560, 200, 130, "S", [0.38, 0.34, 0.28], style="sade")
L.house("Deniz feneri", 1300, 420, 140, 140, "S", [0.7, 0.7, 0.68], style="sade")
L.ob("crate", rect(700, 860, 60, 50))
L.ob("fence", rect(380, 960, 600, 10))

# ------------------------------------------------------------ GUNEYBATI: inis koyu + ciftlik
L.house("Çiftlik evi", 900, 3300, 220, 150, "N")
L.house("Samanlık", 1250, 3300, 240, 160, "N", [0.36, 0.33, 0.28], style="sade")
L.ob("truck", rect(700, 3600, 120, 50))

# ------------------------------------------------------------ ZORUNLU CALISMA KAMPI (bati orta): duvarli
KX0, KY0, KX1, KY1 = 700, 1400, 1700, 2600
L.walls_box(KX0, KY0, KX1, KY1, {"E": [(1940, 2060)], "S": [(1100, 1200)], "W": [(2300, 2360)]}, 18, "wall")
L.house("Kamp barakası A", 800, 1500, 320, 160, "S", [0.36, 0.34, 0.3], style="sade")
L.house("Kamp barakası B", 800, 2250, 320, 160, "N", [0.36, 0.34, 0.3], style="sade")
L.house("Kamp nöbet evi", 1350, 1500, 240, 160, "S", [0.34, 0.36, 0.3], style="sade")
L.ob("tent", rect(1300, 2300, 160, 100))
L.ob("crate", rect(1500, 1950, 60, 60))
L.tower(740, 1440, 225)
L.tower(1630, 2520, 45)

# ------------------------------------------------------------ TRAFO ISTASYONU (kanal bati kiyisi)
L.house("Trafo istasyonu", 2500, 1100, 260, 170, "S", [0.38, 0.38, 0.36], style="sade")
L.ob("sandbag", rect(2450, 1320, 26, 70))
L.ob("crate", rect(2800, 1150, 50, 50))
L.tower(2900, 1450, 0)

# ------------------------------------------------------------ KOPRU KONTROL NOKTALARI
L.ob("sandbag", rect(3080, 1960, 26, 70))
L.ob("sandbag", rect(3500, 2180, 26, 70))
L.ob("sandbag", rect(3190, 640, 26, 70))
L.tower(3050, 2300, 0)

# ------------------------------------------------------------ DENEME SAHASI (dogu): dikenli tel, 5 kapi
AX0, AY0, AX1, AY1 = 3800, 500, 6300, 3500


def tel_line(horiz, c, a, b, gaps):
    cuts = [a] + [v for g in sorted(gaps) for v in g] + [b]
    for i in range(0, len(cuts), 2):
        s, e = cuts[i], cuts[i + 1]
        while e - s > 4:
            s2 = min(e, s + 200)
            L.ob("tel", rect(s, c, s2 - s, 12) if horiz else rect(c, s, 12, s2 - s))
            s = s2


tel_line(True, AY0, AX0, AX1, [(5400, 5500)])                       # kuzey kapi (kumul)
tel_line(True, AY1, AX0, AX1, [(4680, 4790)])                       # guney kapi
tel_line(False, AX0, AY0 + 12, AY1, [(720, 860), (2000, 2120), (3000, 3080)])   # bati: demiryolu, yol, sazlik kapisi
tel_line(False, AX1 - 12, AY0 + 12, AY1, [])
L.house("Laboratuvar", 4100, 900, 380, 220, "S", [0.4, 0.4, 0.4], locked="lab_anahtari", style="sade")
L.house("Montaj hangarı", 5500, 2300, 480, 260, "N", [0.36, 0.38, 0.34], style="sade")
L.house("Ölçüm bunkeri", 5900, 1000, 260, 180, "W", [0.42, 0.42, 0.4], style="sade")
L.house("Sıvı oksijen tesisi", 4400, 2750, 300, 180, "N", [0.38, 0.4, 0.42], style="sade")
L.house("Yemekhane", 4100, 3150, 260, 150, "E", [0.42, 0.34, 0.26])
L.ob("wall", rect(5150, 1380, 60, 360))                        # deneme kulesi: bati beton perde
L.ob("wall", rect(5590, 1380, 60, 360))                        # dogu beton perde
L.ob("truck", rect(5330, 1500, 100, 160))                      # roket (Meillerwagen uzerinde)
L.ob("sandbag", rect(5250, 1840, 300, 26))                     # atis kontrol siperi
for i in range(3):
    L.ob("rock", circle=[4900, 2800 + i * 110, 44])            # oksijen tanklari
L.ob("truck", rect(5000, 2050, 140, 50))
L.ob("tank", rect(4300, 1600, 130, 70))
L.ob("sandbag", rect(3900, 1250, 26, 120))
L.tower(3860, 560, 45)
L.tower(6240, 560, 135)
L.tower(6240, 3440, 225)
L.tower(3860, 3440, 315)
L.tower(5400, 1920, 0)                                          # deneme kulesi gozcusu

for pole, path, sp in (([3200, 900], [[2950, 780], [3550, 780], [3780, 900]], 80),                  # demiryolu koprusu
                       ([3100, 2250], [[2900, 2070], [3450, 2070], [3780, 2200]], 80),              # yol koprusu
                       ([3950, 1700], [[3900, 1100], [3900, 1900], [3950, 2600]], 85),              # bati tel boyu
                       ([5100, 1300], [[5250, 1330], [5550, 1330], [5550, 1800], [5250, 1800]], 70),  # deneme kulesi
                       ([4650, 3420], [[4000, 3420], [4800, 3420], [5600, 3440]], 80),              # guney kapi
                       ([5450, 620], [[4600, 620], [5450, 640], [6200, 620]], 85),                  # kuzey tel boyu
                       ([1200, 1950], [[800, 1950], [1300, 1950], [1600, 2100]], 70)):              # kamp
    L.ob("projektor", circle=[pole[0], pole[1], 10])
    d.setdefault("searchlights", []).append({"pole": pole, "path": path, "speed": sp, "r": 64})

# ------------------------------------------------------------ ASKERLER
G = L.guard
# balikci koyu ve kumsal (cikis)
G([[300, 420], [1500, 420]], None, "er")
G([[1380, 600]], 90, "er")                                          # fener kapisi
G([[900, 760]], 90, "er")                                           # ag deposu
G([[2000, 300], [3000, 300]], None, "er")
G([[260, 520]], 180, "er")                                          # kumsal (Kowalski'nin botu yakini)
# guneybati
G([[600, 3500], [1600, 3500]], None, "er")
G([[1100, 3720]], 0, "er")
G([[1400, 3250]], 270, "subay")                                     # samanlik onu
G([[400, 2800], [400, 3400]], None, "er")
G([[2000, 3700], [2900, 3700]], None, "er")
G([[3000, 3450]], 0, "elit")                                         # sig gecit bati
G([[3550, 3600]], 180, "er")                                         # sig gecit dogu
G([[2300, 2800], [2300, 3400]], None, "er")
# kamp
G([[1760, 1940]], 0, "er")                                           # dogu kapi
G([[1760, 2060]], 0, "elit")
G([[1100, 2650]], 90, "er")                                          # guney kapi
G([[1200, 2650]], 90, "er")
G([[880, 1800], [1550, 1800], [1550, 2150], [880, 2150]], None, "subay")   # kamp komutani
G([[1400, 1560]], 180, "er")                                         # nobet evi ici
G([[1450, 1690]], 90, "er")                                          # nobet evi kapisi
G([[900, 2320]], 0, "er")                                            # baraka ici
G([[760, 1500], [760, 2500]], None, "er")
G([[1650, 1500], [1650, 1900]], None, "er")
# trafo
G([[2580, 1180]], 0, "er")                                           # trafo ici (panolara sirtini doner)
G([[2640, 1290]], 90, "er")                                          # trafo kapisi
G([[2300, 900], [2300, 1600]], None, "er")
G([[2500, 1700], [3000, 1700]], None, "er")
# kopruler
G([[3150, 690]], 0, "elit")
G([[3150, 850]], 0, "er")
G([[3600, 690]], 180, "er")
G([[3600, 850]], 180, "subay")
G([[3060, 2000]], 0, "elit")
G([[3060, 2150]], 0, "er")
G([[3500, 2000]], 180, "er")
G([[3500, 2150]], 180, "subay")
G([[3600, 1000], [3600, 1850]], None, "er")                          # dogu kiyi seridi
G([[3600, 2300], [3600, 3350]], None, "er")
G([[2900, 2500], [2900, 3300]], None, "er")
# kuzey kumul
G([[3800, 300], [6000, 300]], None, "er")
G([[5000, 380], [6200, 380]], None, "elit")
# deneme sahasi: kapilar
G([[3750, 720]], 180, "elit")                                        # bati demiryolu kapisi
G([[3750, 860]], 180, "er")
G([[3750, 2000]], 180, "elit")                                       # bati yol kapisi
G([[3750, 2120]], 180, "er")
G([[3750, 3040]], 180, "er")                                         # sazlik kapisi
G([[4680, 3545]], 90, "elit")                                        # guney kapi
G([[4790, 3545]], 90, "er")
G([[5400, 460]], 270, "er")                                          # kuzey kapi
G([[5500, 460]], 270, "elit")
# deneme sahasi: binalar
G([[4180, 980], [4400, 980]], None, "elit")                          # laboratuvar ici
G([[4300, 1050]], 0, "subay")
G([[4290, 1160]], 90, "elit")                                        # laboratuvar kapisi
G([[5600, 2380], [5900, 2380]], None, "er")                          # hangar ici
G([[5740, 2270]], 270, "elit")                                       # hangar kapisi
G([[5980, 1080]], 180, "er")                                         # olcum bunkeri ici
G([[5870, 1090]], 180, "elit")                                       # olcum bunkeri kapisi
G([[4550, 2720]], 270, "er")                                         # oksijen kapisi
G([[4500, 2850]], 0, "er")                                           # oksijen ici
G([[4200, 3220]], 0, "subay")                                        # yemekhane ici
G([[4400, 3240]], 0, "er")                                           # yemekhane kapisi
# deneme sahasi: devriyeler
G([[3900, 620], [6200, 620]], None, "elit")
G([[3900, 3380], [6200, 3380]], None, "er")
G([[6200, 660], [6200, 3300]], None, "er")
G([[3970, 1400], [3970, 2900]], None, "elit")
G([[5250, 1290], [5550, 1290]], None, "elit")                        # deneme kulesi kuzey
G([[5250, 1880], [5550, 1880]], None, "er")                          # deneme kulesi guney
G([[5100, 1250], [5100, 1950]], None, "elit")
G([[5700, 1250], [5700, 1950]], None, "er")
G([[4500, 1400], [5000, 1400], [5000, 2400], [4500, 2400]], None, "subay", "lab_anahtari")   # saha subayi
G([[5000, 2650], [5000, 3200]], None, "er")
G([[4800, 900], [5600, 900]], None, "er")
G([[5300, 2150], [6100, 2150]], None, "elit")
G([[5300, 3000], [6100, 3000]], None, "elit")
G([[4150, 1500], [4150, 2600]], None, "er")
G([[5900, 1300], [5900, 2000]], None, "elit")                        # olcum bunkeri - kule arasi
G([[4500, 3000], [4500, 3300]], None, "er")
G([[5300, 2500], [5300, 2900]], None, "er")
G([[6000, 3200]], 270, "elit")                                       # guneydogu kose
# baslangic cevresi
G([[800, 3900], [800, 4100], [1300, 4100]], None, "er")

# ------------------------------------------------------------ KARAKTERLER VE GOREVLER
d["npcs"] = [
    {"id": "jan", "outfit": "direnisci", "name": "Jan Nowak", "pos": [520, 880], "facing": 90},
]
d["document"] = [4300, 1000]
d["objectives"] = [
    {"id": "temas", "type": "reach", "text": "Balıkçı kulübesinde Jan Nowak ile buluş", "pos": [520, 880],
     "radius": 70, "gives": {"patlayici": 3, "tel_makasi": 1},
     "say": [["Jan Nowak", "Çavuş Reilly? Kowalski seni anlatmıştı. Patlayıcıları kumun altına gömdüm, al."],
             ["Jan Nowak", "Trafo istasyonu kanalın batısında. Hattı kes, sahanın batı kışlası telefonla çağrılamaz."],
             ["Jan Nowak", "Projektörleri saydım: kule ışığı on iki saniyede bir döner. Arada kamışlardan geç."],
             ["Yzb. Blake (telsiz)", "Kowalski kuzeybatı kumsalında, motorbotla. Şafaktan önce kalkıyor, Reilly."]]},
    {"id": "trafo", "type": "sabotage", "text": "Trafo istasyonunda telefon hattını sessizce kes", "pos": [2630, 1300],
     "radius": 60, "time": 6.0, "disables_barracks": 3,
     "done_say": [["Çvş. Reilly", "Hat koptu. Sahanın batı kışlası artık yardım çağıramaz."]]},
    {"id": "anahtar", "type": "have", "item": "lab_anahtari", "text": "Saha subayından laboratuvar anahtarını al"},
    {"id": "cizim", "type": "take", "item": "cizimler", "text": "Laboratuvardan A-4 çizimlerini çal",
     "pos": [4300, 1000], "after": ["anahtar"],
     "done_say": [["Çvş. Reilly", "Yakıt pompası, yönlendirme kanatçıkları... Londra bunları görünce inanmayacak."]]},
    {"id": "roket", "type": "destroy", "text": "VII numaralı deneme kulesindeki roketi uçur", "pos": [5380, 1700],
     "radius": 110,
     "done_say": [["Kowalski (telsiz)", "Bunu buradan duydum, çavuş! Kumsala gel, motor ısınıyor."]]},
    {"id": "oksijen", "type": "destroy", "text": "Sıvı oksijen tesisini uçur", "pos": [4550, 2700], "radius": 110,
     "done_say": [["Çvş. Reilly", "Bütün ada uyandı. Şimdi koş!"]]},
    {"id": "olcum", "type": "destroy", "optional": True, "text": "Ölçüm bunkerindeki telemetri cihazlarını uçur",
     "pos": [5860, 1090], "radius": 100},
    {"id": "kacis", "type": "exit", "text": "Kuzeybatı kumsalındaki Kowalski'nin motorbotuna kaç"},
]

# ------------------------------------------------------------ KISLALAR, SIRENLER, ESYALAR
d["barracks"] = [
    {"pos": [1200, 3000], "count": 6, "type": "er", "delay": 7},      # ciftlik
    {"pos": [1200, 2000], "count": 8, "type": "er", "delay": 5},      # kamp
    {"pos": [2600, 1600], "count": 6, "type": "er", "delay": 6},      # trafo
    {"pos": [4100, 1900], "count": 8, "type": "elit", "delay": 4},    # saha batisi (trafo kesilince bos)
    {"pos": [5600, 2050], "count": 8, "type": "elit", "delay": 4},    # deneme kulesi
    {"pos": [2400, 600], "count": 6, "type": "er", "delay": 6},       # kuzey
    {"pos": [5000, 3700], "count": 6, "type": "er", "delay": 7},      # guney
    {"pos": [900, 1000], "count": 6, "type": "er", "delay": 7},       # balikci koyu
]
d["sirens"] = [[1000, 3200], [1300, 1700], [2400, 1250], [3000, 2250], [3620, 1150], [4050, 1600],
               [5200, 2050], [5800, 1300], [4900, 3250]]
d["pickups"] = [
    {"type": "medkit", "pos": [1000, 3900]},
    {"type": "medkit", "pos": [2000, 1300]},
    {"type": "medkit", "pos": [2700, 3200]},
    {"type": "medkit", "pos": [4600, 3100]},
    {"type": "medkit", "pos": [4400, 700]},
    {"type": "ammo", "pos": [1500, 2400]},
    {"type": "ammo", "pos": [2800, 1000]},
    {"type": "ammo", "pos": [5000, 1150]},
    {"type": "ammo", "pos": [6000, 2700]},
    {"type": "stones", "count": 3, "pos": [2500, 3400]},                  # sazliga inen patikada tas yigini
    {"type": "stones", "count": 2, "pos": [3700, 1500]},                  # kanal dogu kiyisi
    {"type": "item", "item": "patlayici", "count": 1, "pos": [5700, 2420]},   # hangarda yedek
]

# ------------------------------------------------------------ GIZLI YOLLAR (kiliksiz: kamis, kumul, hendek)
L.bush_line([420, 3900], [420, 3000], 70, 28)                 # baslangictan kuzeye
L.bush_line([420, 2900], [420, 1100], 80, 30)                 # kampin bati disi -> balikci koyu
L.bush_line([2400, 3400], [3050, 3480], 70, 26)               # sazliga kamislar
L.bush_line([3480, 3300], [3480, 2400], 75, 26)               # kanal dogu kiyisi kamis seridi
L.bush_line([3480, 1800], [3480, 1000], 75, 26)
L.bush_line([2200, 1700], [2200, 2700], 80, 28)               # kamp dogusu -> trafo
L.bush_line([4000, 400], [5300, 400], 80, 28)                 # kuzey kumul calilari
L.bush_line([3950, 3300], [4600, 3300], 80, 26)               # guney tel ici
L.bushes([[1000, 2000], [1400, 2200], [1500, 1750]], 26)                          # kamp ici siper
L.bushes([[4200, 1350], [4600, 1900], [4950, 1250], [5850, 1700], [4800, 2600],
          [5300, 2700], [6050, 2000], [4350, 2350]], 30)                           # saha ici kamuflaj
L.bushes([[2400, 1000], [2850, 1350], [2350, 1450]], 28)                          # trafo cevresi

for p in d["sirens"] + [b["pos"] for b in d["barracks"]] + [k["pos"] for k in d["pickups"]]:
    L.block(p[0], p[1], 0, 0, 60)                              # dolgu agaclari bunlarin ustune gelmesin

# ------------------------------------------------------------ AGAC / CALI DOLGU (cam ormani + kumul)
L.scatter(26, 80, 1100, 650, 2900, "tree", 24, 36)            # bati orman
L.scatter(18, 80, 3000, 650, 4150, "tree", 24, 34)            # baslangic ormani
L.scatter(22, 1900, 2300, 2900, 3400, "tree", 24, 34)         # kamp - kanal arasi
L.scatter(18, 1700, 500, 3000, 900, "tree", 24, 34)           # kuzey orta
L.scatter(10, 4300, 2300, 5100, 2650, "tree", 24, 30)         # saha ici
L.scatter(24, 3700, 3650, 6350, 4150, "tree", 24, 36)         # guneydogu orman
L.scatter(10, 1900, 3750, 3000, 4150, "tree", 24, 32)
L.scatter(14, 80, 1100, 650, 2900, "bush", 24, 32)
L.scatter(14, 3700, 3650, 6350, 4150, "bush", 24, 32)
L.scatter(10, 1900, 2300, 2900, 3400, "bush", 24, 30)
L.scatter(8, 1700, 500, 3000, 900, "bush", 24, 30)
L.save("levels/bolum7.json")
