"""
Bolum 8 - "Alp Treni" (Tirol, Eylul 1944 gecesi) harita ureticisi -> levels/bolum8.json

2. perdenin ucuncu bolumu, Bolum 7'den biraz zor ve ilk IKI KOMANDOLU bolum (Tur 7):
Cvs. Reilly (Yesil Bere) + Yzb. Blake (Sahin, keskin nisanci). Oyuncu ikisi arasinda gecer (PC: 1/2, Tab;
telefonda sol alttaki ekip dugmeleri), secili olmayan ya izler ya bekler. Kacista ikisi de bota... burada
dag gecidine varmali.

6000x4000 karli vadi, ~92 asker, 8 kule, 5 projektor, buzlu dag deresi (kuzey-guney) uc yerden gecilir:
kuzeyde ahsap yaya koprusu, ortada demiryolu viyadugu (Brandt'in treni), guneyde donmus sig gecit (karda iz kalir).
Sahin'in isi: dere kayaligindaki iki gozcuyu karakolun dogusundaki caliliktan (nisanci yeri) uzaktan susturmak;
kis cizgisindeki gozculere bicakla ulasmak cok zor (viyadugun dogu ucunda, nobetcilerin gozu onunde).
Kilik/uniforma YOK (kalici kural): gizli yollar = cam koruluklari, kar yigini calilar, derenin kamislari,
tas yigini (dikkat dagitma), projektor araliklari. Binalarda pencereler otomatik (Tur 6 kurali).

    python3 tools/gen_bolum8.py      (GODOT=... verilirse navigasyon dogrulanir)
"""
import math
from bolum_lib import Lvl, rect

W, H = 6000, 4000
L = Lvl("Bölüm 8 – Alp Treni", (W, H), 1948)
d = L.d
d["theme"] = "kar"
d["ambient"] = [0.7, 0.76, 0.95]           # karli Alp gecesi, ay isigi
d["stones"] = 6
d["brief"] = ("Gruber çiftliğinde Lisl Gruber ile buluş. Şahin'le dere kayalığındaki iki gözcüyü uzaktan sustur, "
              "istasyon telsizini sessizce kes, istasyon subayından anahtarı al, kilitli istasyon şefliğinden "
              "Brandt'ın sevk dosyasını çal, Brandt'ın zırhlı lokomotifini uçur ve iki komandoyla birlikte "
              "kuzeybatıdaki dağ geçidine kaç.")
d["story"] = (
    "Eylül 1944, Tirol Alpleri. Brandt Baltık'tan kaçtı ve zırhlı bir trenle güneye, Alplerin içindeki gizli "
    "fabrikalara gidiyor. Tren bu gece karlı bir vadideki küçük istasyonda su ve kömür alacak.\n\n"
    "Bu kez yalnız değilsin: Yzb. Edward \"Şahin\" Blake telsizin başından kalktı, dürbünlü tüfeğini aldı ve "
    "seninle geldi. Komandolar arasında geçiş yapabilirsin: biri ilerlerken diğeri bekler ya da onu izler. "
    "Şahin bıçak kullanmaz; uzaktan, durup nişan alarak tek atışta vurur, ama mermisi az ve tüfek sesi duyulur.\n\n"
    "Vadiyi buzlu bir dağ deresi ikiye bölüyor. Kuzeyde ahşap bir yaya köprüsü, ortada Brandt'ın treninin "
    "geçeceği taş viyadük, güneyde donmuş bir sığlık var (karda iz kalır). Derenin doğu yakasındaki "
    "kayalıkta iki gözcü batı yamacını ve köprüleri kolluyor: önce onları Şahin'le, karakolun doğusundaki "
    "çalılıktan sustur.\n\n"
    "Tirollü direnişçi Lisl Gruber patlayıcıları çiftliğinin samanlığına sakladı. İstasyon telsizi vadinin "
    "kuzeyindeki dağ kışlasına bağlı: hattı kesersen oradan yardım gelmez. Brandt'ın sevk dosyası kilitli "
    "istasyon şefliğinde; anahtar peronda dolaşan subayda. Lokomotifi uçurduktan sonra ikiniz de "
    "kuzeybatıdaki dağ geçidine ulaşmalısınız.")
d["start"] = [300, 3760]
d["exit"] = [60, 80, 300, 240]
# Tur 7: ekip - Reilly'nin yaninda Sahin (keskin nisanci, 6 tufek mermisi). Baslangicta Reilly'yi izler.
d["team"] = [{"role": "nisanci", "pos": [250, 3830], "ammo": 6, "follow": True}]


def cx(y):
    return 2700 + 70 * math.sin(y / 520.0)


def wd(y):
    return 210 + 40 * max(0.0, 1.0 - abs(y - 3360) / 400.0)


# ------------------------------------------------------------ buzlu dere (kuzey-guney): 3 gecit
L.river(cx, wd, -20, H + 40, [(690, 830), (1900, 2040), (3290, 3430)], step=160)
d["bridges"] = [[round(cx(1970)) - 170, 1900, 340, 140], [round(cx(760)) - 150, 690, 300, 140]]   # 0: viyaduk, 1: yaya koprusu
d["surfaces"] = [
    {"type": "snow", "points": rect(round(cx(3360)) - 150, 3290, 300, 140), "footprints": True, "slow": 0.7},   # donmus sig
    {"type": "snow", "points": rect(80, 3000, 1500, 900), "footprints": True, "slow": 0.85},       # derin kar (baslangic)
    {"type": "snow", "points": rect(300, 300, 1300, 600), "footprints": True, "slow": 0.8},        # gecide cikan yamac
    {"type": "beton", "points": rect(3300, 1820, 1900, 300)},                                       # istasyon peronu
    {"type": "snow", "points": rect(3800, 3100, 1400, 700), "footprints": True, "slow": 0.85},     # guneydogu yamac
]
L.road(0, 1960, 2560, 40)              # demiryolu (bati kol, viyaduge)
L.road(2860, 1960, 3140, 40)           # demiryolu (dogu kol, istasyon)
L.road(3300, 2060, 2400, 40)           # istasyon yan hatti
L.road(1500, 400, 60, 3300)            # kuy yolu (kuzey-guney)
L.road(1560, 740, 1000, 50)            # yaya koprusune giden patika
L.road(2850, 740, 1800, 50)            # koprunun dogusu -> dag kislasi
L.road(300, 3640, 1200, 50)            # baslangic -> koy

# ------------------------------------------------------------ BATI YAKA: Gruber ciftligi + Hochtal koyu
L.house("Gruber çiftliği", 520, 2620, 240, 160, "E", [0.42, 0.3, 0.22])
L.house("Samanlık", 900, 2900, 260, 170, "N", [0.4, 0.33, 0.26], style="sade")
L.house("Köy kilisesi", 1050, 1500, 220, 300, "S", [0.55, 0.52, 0.5])
L.house("Han", 1700, 2200, 300, 180, "W", [0.45, 0.3, 0.24])
L.house("Köy evi", 1050, 2150, 220, 150, "E")
L.house("Köy karakolu", 1750, 1450, 260, 170, "W", [0.36, 0.38, 0.32], style="sade")
L.house("Oduncu kulübesi", 2000, 3000, 200, 130, "N", [0.38, 0.3, 0.24], style="sade")
L.ob("crate", rect(800, 2700, 50, 50))
L.ob("fence", rect(450, 2860, 10, 300))
L.ob("truck", rect(1300, 2500, 120, 50))
L.tower(1980, 1250, 150)                # karakol kulesi (koye ve yola bakar)

# ------------------------------------------------------------ VIYADUK: bati ve dogu uc
L.ob("sandbag", rect(2420, 1880, 26, 70))
L.ob("sandbag", rect(2420, 2050, 26, 70))
L.ob("sandbag", rect(2890, 1660, 80, 26))         # gozcu 1 yuvasi
L.ob("sandbag", rect(2960, 1380, 80, 26))         # gozcu 2 yuvasi
L.ob("rock", circle=[3010, 1600, 40])
L.ob("rock", circle=[3060, 1430, 40])
L.ob("rock", circle=[2900, 1535, 30])                     # iki gozcu arasindaki kaya: birbirlerini gormezler

# ------------------------------------------------------------ ISTASYON (dogu orta): peron, zirhli tren
L.house("İstasyon binası", 3500, 1550, 420, 200, "S", [0.46, 0.32, 0.26])
L.house("İstasyon şefliği", 4100, 1560, 240, 170, "S", [0.4, 0.3, 0.26], locked="istasyon_anahtari")
L.house("Telsiz kulübesi", 4550, 1500, 200, 140, "S", [0.36, 0.38, 0.34], style="sade")
L.house("Su kulesi", 5050, 1560, 150, 150, "S", [0.5, 0.48, 0.46], style="sade")
L.house("Kömür deposu", 3600, 2300, 360, 170, "N", [0.3, 0.3, 0.3], style="sade")
L.house("Makas kulübesi", 5400, 2300, 180, 120, "N", [0.4, 0.34, 0.28], style="sade")
L.ob("tank", rect(4400, 1940, 170, 80))                       # Brandt'in zirhli lokomotifi
for k in range(4):
    L.ob("truck", rect(3480 + k * 220, 1946, 200, 64))        # zirhli vagonlar
L.ob("truck", rect(4800, 2052, 200, 56))                      # yan hatta bos vagon
L.ob("truck", rect(5050, 2052, 200, 56))
L.ob("crate", rect(4000, 2240, 60, 60))
L.ob("sandbag", rect(4300, 1780, 140, 26))
L.tower(3300, 1760, 180)
L.tower(5600, 1760, 270)
L.tower(4500, 2600, 0)

# ------------------------------------------------------------ DAG KISLASI (kuzeydogu): duvarli
KX0, KY0, KX1, KY1 = 4300, 200, 5700, 1100
L.walls_box(KX0, KY0, KX1, KY1, {"S": [(4920, 5040)], "W": [(720, 800)]}, 18, "wall")
L.house("Dağ kışlası", 4450, 330, 460, 180, "S", [0.36, 0.38, 0.32], style="sade")
L.house("Subay evi", 5150, 330, 300, 170, "S", [0.44, 0.32, 0.26])
L.house("Cephanelik", 5250, 800, 240, 150, "W", [0.34, 0.34, 0.32], style="sade")
L.ob("tent", rect(4500, 800, 160, 100))
L.ob("truck", rect(4800, 900, 140, 50))
L.tower(4340, 240, 135)
L.tower(5600, 1030, 315)

# ------------------------------------------------------------ KUZEYBATI: dag gecidi (cikis)
L.house("Gümrük kulübesi", 700, 420, 220, 140, "S", [0.4, 0.34, 0.28], style="sade")
L.ob("fence", rect(380, 620, 800, 10))
L.ob("sandbag", rect(1000, 560, 26, 70))
L.tower(1250, 330, 225)

# projektorler: viyaduk, yaya koprusu, istasyon peronu, kisla kapisi, donmus sig
for pole, path, sp in (([2560, 1780], [[2300, 1960], [2700, 1960], [2900, 2100]], 75),
                       ([2550, 620], [[2350, 760], [2850, 760], [3000, 880]], 80),
                       ([4000, 1800], [[3400, 1900], [4200, 1900], [5000, 2000]], 85),
                       ([4980, 1180], [[4700, 1150], [5300, 1150], [5300, 1400]], 75),
                       ([2950, 3200], [[2550, 3360], [2850, 3360], [3100, 3500]], 70)):
    L.ob("projektor", circle=[pole[0], pole[1], 10])
    d.setdefault("searchlights", []).append({"pole": pole, "path": path, "speed": sp, "r": 64})

# ------------------------------------------------------------ ASKERLER
G = L.guard
# baslangic ve ciftlik
G([[700, 3500], [1400, 3500]], None, "er")
G([[1100, 3800]], 0, "er")
G([[660, 2860]], 90, "er")                                           # ciftlik kapisi (avlu)
G([[1000, 2800], [1300, 2800], [1300, 3100]], None, "er")
G([[400, 2300], [400, 3000]], None, "er")
# koy
G([[1160, 1830]], 90, "er")                                          # kilise kapisi
G([[900, 1400], [900, 2000], [1350, 2000]], None, "subay")           # koy devriyesi
G([[1640, 2290]], 180, "er")                                          # han kapisi
G([[1800, 2280], [1950, 2280]], None, "er")                           # han ici
G([[1700, 1540]], 180, "er")                                          # karakol kapisi
G([[1820, 1500], [1950, 1580]], None, "er")                           # karakol ici
G([[1530, 1200], [1530, 2600]], None, "er")                           # koy yolu
G([[1200, 2400], [1600, 2600]], None, "er")
G([[2100, 3180]], 270, "er")                                          # oduncu
G([[1800, 3400], [2400, 3400]], None, "er")
# bati yamac (dere boyu)
G([[2080, 880], [2080, 1180]], None, "er")
G([[2300, 2300], [2300, 2900]], None, "er")
# viyaduk: bati uc + dogu uc + GOZCULER (Sahin'in hedefi)
G([[2470, 1940]], 0, "er")                                           # viyaduk bati ucu: viyadugu kollar
G([[2470, 2030]], 0, "elit")
G([[2950, 1940]], 180, "er")
G([[2950, 2030]], 180, "subay")
G([[2860, 1620]], 190, "er")["tag"] = "gozcu"                       # gozcu 1: kayalikta, bati yamaci kollar
G([[2930, 1450]], 170, "er")["tag"] = "gozcu"                       # gozcu 2: yaya koprusune giden yamac
G([[3150, 1820], [3150, 2500]], None, "er")                           # dogu kiyi devriyesi
# yaya koprusu
G([[2460, 760]], 180, "er")
G([[2940, 760]], 0, "er")
G([[2950, 900], [3500, 900]], None, "er")
# donmus sig gecit
G([[2500, 3300]], 0, "er")
G([[2900, 3460]], 180, "elit")
G([[3100, 2900], [3100, 3700]], None, "er")
# istasyon: binalar
G([[3600, 1640], [3820, 1640]], None, "er")                           # istasyon binasi ici
G([[3700, 1770]], 90, "elit")                                         # istasyon kapisi
G([[4200, 1620]], 0, "subay")                                         # sefllik ici
G([[4220, 1750]], 90, "elit")                                         # seflik kapisi
G([[4620, 1560]], 0, "er")                                            # telsizci
G([[4650, 1660]], 90, "er")                                           # telsiz kapisi
G([[5120, 1730]], 90, "er")                                           # su kulesi
G([[3780, 2290]], 270, "er")                                          # komur deposu kapisi
G([[3700, 2380], [3880, 2380]], None, "er")                           # komur deposu ici
G([[5480, 2290]], 270, "er")                                          # makas kulubesi
# istasyon: peron ve tren
G([[3400, 1880], [5200, 1880]], None, "subay", "istasyon_anahtari")   # peron subayi (anahtar)
G([[3400, 2140], [5200, 2140]], None, "elit")
G([[4600, 1880]], 270, "elit")                                        # lokomotif nobetcisi (kuzey)
G([[4500, 2060]], 90, "elit")                                         # lokomotif nobetcisi (guney)
G([[4300, 1880]], 0, "er")
G([[3300, 2000]], 0, "elit")                                          # istasyon bati girisi
G([[3300, 2100]], 0, "er")
G([[5300, 1880], [5900, 1880]], None, "er")
G([[5700, 2100], [5700, 2700]], None, "er")
G([[3400, 2600], [4300, 2600]], None, "er")
G([[4700, 2400], [5300, 2400]], None, "elit")
G([[4000, 1400], [5400, 1400]], None, "er")
# dag kislasi
G([[4920, 1140]], 90, "elit")                                         # guney kapi
G([[5040, 1140]], 90, "er")
G([[4260, 720]], 0, "er")                                             # bati kapi
G([[4260, 800]], 0, "elit")
G([[4500, 600], [5600, 600]], None, "subay")
G([[4550, 400], [4850, 400]], None, "er")                             # kisla ici
G([[4680, 560]], 90, "er")                                            # kisla kapisi
G([[5250, 400]], 0, "subay")                                          # subay evi ici
G([[5300, 540]], 90, "er")                                            # subay evi kapisi
G([[5230, 870]], 180, "elit")                                         # cephanelik kapisi
G([[4400, 1000], [5600, 1000]], None, "er")
G([[3600, 700], [3600, 1300]], None, "er")                            # kisla - istasyon arasi
G([[3900, 300], [4200, 1200]], None, "er")
# kuzeybati gecit
G([[810, 600]], 90, "elit")                                           # gumruk kulubesi kapisi
G([[500, 720], [1400, 720]], None, "er")
G([[1100, 250], [1100, 560]], None, "er")
G([[300, 400]], 0, "elit")                                            # gecit agzi
G([[2000, 500], [2000, 1100]], None, "er")
# guneydogu yamac
G([[4000, 3300], [5600, 3300]], None, "er")
G([[5200, 3000], [5200, 3700]], None, "elit")
G([[4400, 3700], [5800, 3700]], None, "er")
G([[3600, 3200]], 270, "er")
# ek devriyeler (Bolum 7'den biraz zor)
G([[2420, 2150], [2420, 2600]], None, "er")                           # viyaduk guneyi bati kiyi (zamanla)
G([[2500, 1960], [2900, 1960]], None, "er")                           # viyaduk uzerinde devriye
G([[3450, 1700], [3450, 2250]], None, "elit")
G([[4150, 2110], [4150, 2280]], None, "er")
G([[4900, 1950], [5400, 1950]], None, "elit")
G([[5550, 1500], [5550, 2200]], None, "er")
G([[4400, 2800], [5000, 2800]], None, "er")
G([[700, 1300], [1200, 1300]], None, "er")
G([[1300, 900], [1300, 1250]], None, "elit")
G([[3300, 2700], [3300, 3200]], None, "er")                           # dogu kiyi guneyi (kuzey koprunun ardi bos birakildi: ikinci gizli yol)
G([[3700, 1000]], 270, "subay")

# ------------------------------------------------------------ KARAKTERLER VE GOREVLER
d["npcs"] = [
    {"id": "lisl", "outfit": "direnisci", "name": "Lisl Gruber", "pos": [640, 2720], "facing": 0},
]
d["document"] = [4220, 1640]
d["objectives"] = [
    {"id": "temas", "type": "reach", "text": "Gruber çiftliğinde Lisl Gruber ile buluş", "pos": [640, 2720],
     "radius": 70, "gives": {"patlayici": 2},
     "say": [["Lisl Gruber", "Sonunda geldiniz. Patlayıcıları samanlıktan aldım, al bunları. İki tane, idareli kullan."],
             ["Lisl Gruber", "Derenin öbür yakasındaki kayalıkta iki gözcü var. Batı yamacını ve iki köprüyü kolluyorlar."],
             ["Yzb. Blake", "Karakolun doğusundaki çalılıktan ikisini de görebilirim. Sen beni oraya götür, Reilly."],
             ["Lisl Gruber", "İstasyon telsizi dağ kışlasına bağlı. Hattı keserseniz kışladan kimse inmez."]]},
    {"id": "gozcu", "type": "eliminate", "tag": "gozcu", "spot": [2330, 1500],
     "text": "Şahin: dere kayalığındaki iki gözcüyü uzaktan sustur",
     "done_say": [["Yzb. Blake", "İkisi de sustu. Derenin doğusu artık kör, Reilly."]]},
    {"id": "telsiz", "type": "sabotage", "text": "İstasyon telsizini sessizce kes", "pos": [4650, 1640],
     "radius": 60, "time": 5.0, "disables_barracks": 0,
     "done_say": [["Çvş. Reilly", "Hat koptu. Dağ kışlası istasyonu duyamaz."]]},
    {"id": "anahtar", "type": "have", "item": "istasyon_anahtari", "text": "Peron subayından istasyon anahtarını al"},
    {"id": "dosya", "type": "take", "item": "sevk_dosyasi", "text": "İstasyon şefliğinden Brandt'ın sevk dosyasını çal",
     "pos": [4220, 1640], "after": ["anahtar"],
     "done_say": [["Çvş. Reilly", "Fabrikaların yerleri, tren saatleri... Brandt'ın bütün yolu burada."]]},
    {"id": "lokomotif", "type": "destroy", "text": "Brandt'ın zırhlı lokomotifini uçur", "pos": [4480, 1980],
     "radius": 110,
     "done_say": [["Yzb. Blake", "Brandt bu gece hiçbir yere gidemez. Geçide, Reilly, ikimiz birden!"]]},
    {"id": "viyaduk", "type": "destroy", "optional": True, "bridge": 0, "text": "Viyadüğü uçur (yedek tren gelemesin)",
     "pos": [round(cx(1970)), 1970], "radius": 120},
    {"id": "kacis", "type": "exit", "text": "İki komandoyla kuzeybatıdaki dağ geçidine kaç"},
]

# ------------------------------------------------------------ KISLALAR, SIRENLER, ESYALAR
d["barracks"] = [
    {"pos": [4950, 700], "count": 8, "type": "elit", "delay": 5},     # 0: dag kislasi (telsiz kesilince bos)
    {"pos": [1900, 1700], "count": 6, "type": "er", "delay": 6},      # koy karakolu
    {"pos": [3800, 2500], "count": 6, "type": "er", "delay": 6},      # istasyon
    {"pos": [800, 900], "count": 6, "type": "er", "delay": 7},        # gecit
    {"pos": [4800, 3400], "count": 6, "type": "er", "delay": 7},      # guneydogu
]
d["sirens"] = [[1250, 2050], [1850, 1700], [2400, 2200], [3420, 1480], [4000, 1500], [5000, 1700],
               [4700, 1050], [900, 800], [3300, 3100]]
d["pickups"] = [
    {"type": "medkit", "pos": [1100, 3300]},
    {"type": "medkit", "pos": [2100, 2700]},
    {"type": "medkit", "pos": [3400, 1450]},
    {"type": "medkit", "pos": [5300, 2650]},
    {"type": "ammo", "pos": [1900, 2100]},
    {"type": "ammo", "pos": [3900, 2200]},
    {"type": "ammo", "pos": [5300, 950]},
    {"type": "stones", "count": 3, "pos": [2150, 2500]},                  # dere bati yamaci
    {"type": "stones", "count": 2, "pos": [3300, 1400]},                  # istasyon kuzeyi
    {"type": "item", "item": "patlayici", "count": 1, "pos": [5340, 860]},    # cephanelikte yedek
]

# ------------------------------------------------------------ GIZLI YOLLAR (kiliksiz: koruluk, kar yigini, kamis)
L.bush_line([300, 3550], [300, 2400], 70, 28)                 # baslangictan ciftlige
L.bush_line([560, 2300], [560, 1100], 80, 30)                 # ciftlik -> gecit (bati koruluk)
L.bush_line([2150, 2450], [2150, 1620], 70, 28)               # dere bati yamaci -> nisanci yeri
L.bushes([[2330, 1500], [2270, 1450], [2260, 1560], [2340, 1580], [2210, 1500]], 30)   # NISANCI YERI (Sahin burada saklanir)
L.bush_line([2560, 3100], [2560, 2400], 75, 24)               # dere kenari kamislari
L.bush_line([2860, 3200], [2860, 2500], 75, 24)               # dogu kiyi kamislari
L.bush_line([3250, 3000], [3250, 2400], 75, 26)
L.bush_line([3500, 1350], [4000, 1350], 80, 28)               # istasyonun kuzeyi
L.bush_line([2990, 880], [2990, 1300], 70, 28)                # yaya koprusunden istasyona inen kar yigini seridi
L.bush_line([3060, 1330], [3450, 1330], 75, 28)
L.bush_line([5800, 2900], [5800, 1300], 80, 28)               # dogu kenar
L.bushes([[3450, 2250], [4100, 2450], [4900, 2250], [5200, 1500], [4350, 1450], [3550, 2700]], 30)
L.bushes([[1300, 1350], [1400, 2350], [1650, 2700], [850, 2450]], 28)    # koy ici
L.bushes([[1350, 450], [1700, 900], [400, 900]], 30)                      # gecit cevresi

for p in d["sirens"] + [b["pos"] for b in d["barracks"]] + [k["pos"] for k in d["pickups"]]:
    L.block(p[0], p[1], 0, 0, 60)
for o in d["objectives"]:
    if "spot" in o:
        L.block(o["spot"][0], o["spot"][1], 0, 0, 90)         # nisanci yerinin gorusunu agac kapatmasin

# ------------------------------------------------------------ AGAC / CALI DOLGU (cam ormani)
L.scatter(24, 80, 1000, 900, 2300, "tree", 24, 36)            # bati koruluk
L.scatter(18, 80, 3000, 1400, 3950, "tree", 24, 34)           # baslangic ormani
L.scatter(18, 1700, 2600, 2450, 3900, "tree", 24, 34)         # dere bati yamaci (guney)
L.scatter(14, 1600, 900, 2400, 1250, "tree", 24, 32)          # koy kuzeyi
L.scatter(14, 3100, 200, 4200, 1300, "tree", 24, 34)          # kisla - istasyon arasi
L.scatter(22, 3300, 2800, 5950, 3950, "tree", 24, 36)         # guneydogu orman
L.scatter(8, 5750, 1200, 5980, 3000, "tree", 24, 30)
L.scatter(12, 80, 1000, 900, 2300, "bush", 24, 32)
L.scatter(12, 3300, 2800, 5950, 3950, "bush", 24, 32)
L.scatter(8, 1700, 2600, 2450, 3900, "bush", 24, 30)
L.scatter(6, 3100, 200, 4200, 1300, "bush", 24, 30)
L.save("levels/bolum8.json")
