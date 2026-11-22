"""
Bolum 9 - "Dagin Icindeki Fabrika" (Salzkammergut, Ekim 1944 aksami) harita ureticisi -> levels/bolum9.json

2. perdenin dorduncu bolumu. Brandt'in sevk dosyasindaki ilk fabrika: bir dagin icine oyulmus tunellerde
jet motoru parcasi ureten yeralti fabrikasi. Iki komando (Reilly + Sahin). YENI KARAKTERLER Sprite Atolye'de
uretildi (gorsel -> 3D -> Quaternius UAL iskeleti -> 8 yon sprite sayfasi, assets/siparis.json):
  - alman_dag   : Gebirgsjager (dag avcisi, edelweiss'li kasket) - bolumun ana askeri ("dag")
  - alman_muhendis : beyaz onluklu fabrika muhendisi ("muhendis"; zayif, silahi kotu ama alarm verir)
  - isci        : zorunlu calistirilan isci (kampta bekleyenler + kurtarilan Tadeusz)
  - madenci     : temas, maden ustabasi Franz Hofer
  - komando_nisanci : Sahin'in kendi sprite'i (Tur 8'den itibaren tum bolumlerde)

6000x4200: kuzeyde dag kitlesi (kayalik + yar), yarin dibinde iki tunel agzi; ortada fabrika avlusu
(trafo, kompresor, muhendislik ofisi, atolyeler, SS kislasi); batida Bergdorf koyu; doguda tel orgulu isci
kampi; guneyde gol kiyisi (baslangic batida, kacis dogudaki iskelede). Kilik/uniforma YOK (kalici kural).

    python3 tools/gen_bolum9.py      (GODOT=... verilirse navigasyon dogrulanir)
"""
import math
from bolum_lib import Lvl, rect

W, H = 6000, 4200
L = Lvl("Bölüm 9 – Dağın İçindeki Fabrika", (W, H), 1949)
d = L.d
d["ambient"] = [0.74, 0.68, 0.8]           # Ekim aksami, alacakaranlik
d["stones"] = 6
d["brief"] = ("Bergdorf'ta maden ustabaşı Franz Hofer ile buluş. Şahin'le tünel üstündeki iki makineli tüfek "
              "yuvasını uzaktan sustur, trafoyu sessizce kes, baş mühendisten ofis anahtarını alıp jet motoru "
              "çizimlerini çal, kamp subayından baraka anahtarını alıp Tadeusz Kowal'ı kurtar, iki tünel ağzını "
              "uçur ve herkesle doğudaki göl iskelesine kaç.")
d["story"] = (
    "Ekim 1944, Salzkammergut. Brandt'ın sevk dosyasındaki ilk adres bir dağın içi: Alman mühendisler kayaya "
    "oyulmuş tünellerde jet motoru parçası üretiyor. Fabrikayı zorla çalıştırılan işçiler kazdı; tünelleri "
    "dağ avcıları (Gebirgsjäger) ve SS koruyor.\n\n"
    "Köyde maden ustabaşı Franz Hofer seni bekliyor: patlayıcı ve tel makası onda. Tünellerin havası ve ışığı "
    "avludaki trafodan geliyor; trafoyu sessizce kesersen fabrikanın SS kışlası yardım çağıramaz.\n\n"
    "Yarın dibinde, iki tünel ağzını kollayan makineli tüfek yuvaları var. Onlara bıçakla ulaşmak imkânsız: "
    "Şahin'i kompresör istasyonunun kuzeyindeki çalılığa götür, oradan sustursun.\n\n"
    "Polonyalı mühendis Tadeusz Kowal tünellerin planını ezbere biliyor; kampın ceza barakasında kilitli. "
    "Anahtar kampta dolaşan subayda. Jet motoru çizimleri mühendislik ofisinde; ofisin anahtarı avluda dolaşan "
    "beyaz önlüklü baş mühendiste. İki tünel ağzını uçurduktan sonra herkesle doğudaki iskeledeki tekneye koş.")
d["start"] = [260, 3560]
d["exit"] = [5560, 3700, 380, 220]
d["team"] = [{"role": "nisanci", "pos": [210, 3630], "ammo": 6, "follow": True}]

# ------------------------------------------------------------ GOL (guney kiyi) + derecik
L.ob("water", [[0, 3960], [1400, 3920], [2600, 3990], [3800, 3930], [5000, 3990], [6000, 3950],
               [6000, 4200], [0, 4200]])
L.block(0, 3900, W, 300, 0)
L.ob("water", [[1560, 2400], [1640, 2400], [1660, 3000], [1620, 3920], [1540, 3920], [1580, 3000]])   # dere (kuzey-guney)
L.block(1500, 2400, 200, 1520, 0)
d["bridges"] = [[1480, 3120, 240, 110]]           # derecik uzerinde koy koprusu
d["surfaces"] = [
    {"type": "mud", "points": rect(1660, 2400, 4100, 120), "footprints": True},          # avlu - kamp arasi camurlu yol
    {"type": "beton", "points": rect(2200, 1000, 2600, 260)},                           # tunel onu beton saha
    {"type": "mud", "points": rect(4700, 1350, 1200, 900), "footprints": True},          # isci kampi
    {"type": "mud", "points": rect(80, 3300, 1300, 560), "footprints": True, "slow": 0.9},  # gol kiyisi (baslangic)
]
L.road(0, 3380, 1500, 50)              # kiyi yolu -> koy
L.road(1720, 3160, 4280, 50)           # kiyi yolu (dogu) -> iskele
L.road(1200, 1300, 60, 2080)           # koy yolu (kuzey-guney)
L.road(1260, 1600, 4400, 50)           # koy -> fabrika -> kamp ana yolu
L.road(3100, 1260, 50, 340)            # fabrika avlusu ic yolu
L.road(2550, 1260, 40, 2000)           # fabrika -> kiyi yolu (dar ray yolu)

# ------------------------------------------------------------ DAG KITLESI (kuzey): kayalik + yar, iki tunel agzi
TUN = [(2420, 2880), (3920, 4380)]                 # tunel agizlarinin x araliklari
for x in range(60, 5960, 110):
    if any(a - 60 < x < b + 60 for a, b in TUN):
        continue
    L.ob("rock", circle=[x, 520 + 30 * math.sin(x / 300.0), 85])   # dag kitlesi (birbirine gecen kayalar)
L.ob("wall", rect(1700, 580, 720, 40))            # yar duvari (tunel agizlari arasi; kayalara biner)
L.ob("wall", rect(2880, 580, 1040, 40))
L.ob("wall", rect(4380, 580, 1020, 40))
L.house("Tünel A ağzı", 2420, 470, 460, 250, "S", [0.42, 0.42, 0.42], style="sade")
L.house("Tünel B ağzı", 3920, 470, 460, 250, "S", [0.42, 0.42, 0.42], style="sade")
L.ob("sandbag", rect(2580, 800, 140, 26))         # tunel onu siperleri
L.ob("sandbag", rect(4080, 800, 140, 26))
L.ob("sandbag", rect(3140, 735, 120, 24))         # makineli tufek yuvasi 1
L.ob("sandbag", rect(3500, 755, 120, 24))         # makineli tufek yuvasi 2

# ------------------------------------------------------------ BATI: Bergdorf koyu (temas)
L.house("Hofer evi", 420, 2700, 240, 160, "E", [0.42, 0.3, 0.22])
L.house("Maden ambarı", 760, 2980, 260, 170, "N", [0.38, 0.33, 0.28], style="sade")
L.house("Köy kilisesi", 700, 1700, 220, 300, "S", [0.55, 0.52, 0.5])
L.house("Gasthaus", 300, 2150, 300, 180, "E", [0.45, 0.3, 0.24])
L.house("Köy evi", 760, 2350, 220, 150, "W")
L.house("Jandarma karakolu", 1350, 1900, 260, 170, "E", [0.36, 0.38, 0.32], style="sade")
L.ob("crate", rect(700, 2880, 50, 50))
L.ob("fence", rect(330, 2920, 10, 300))
L.ob("truck", rect(950, 2600, 120, 50))
L.tower(1450, 1700, 120)

# ------------------------------------------------------------ ORTA: fabrika avlusu
L.house("Mühendislik ofisi", 2000, 1350, 300, 180, "S", [0.36, 0.36, 0.38], locked="ofis_anahtari")
L.house("Trafo binası", 2300, 1950, 200, 150, "W", [0.34, 0.34, 0.32], style="sade")
L.house("Kompresör istasyonu", 3300, 1350, 340, 190, "S", [0.36, 0.36, 0.36], style="sade")
L.house("Atölye", 3850, 1350, 360, 200, "S", [0.4, 0.36, 0.32], style="sade")
L.house("SS kışlası", 2850, 2000, 460, 190, "N", [0.32, 0.34, 0.3], style="sade")
L.house("Yemekhane", 3600, 2000, 300, 170, "N", [0.44, 0.34, 0.28])
L.house("Depo", 4300, 2000, 260, 160, "W", [0.38, 0.36, 0.34], style="sade")
L.ob("truck", rect(2620, 1300, 140, 50))
L.ob("truck", rect(3080, 1700, 140, 50))
L.ob("crate", rect(3720, 1700, 60, 60))
L.ob("crate", rect(3800, 1700, 60, 60))
L.ob("crate", rect(4500, 1420, 60, 60))
L.ob("sandbag", rect(2150, 1680, 26, 90))
L.ob("tank", rect(4200, 1720, 170, 80))           # tunelden cikan kucuk lokomotif
L.tower(1980, 1100, 150)
L.tower(4600, 1150, 210)
L.tower(3400, 2400, 0)

# ------------------------------------------------------------ DOGU: isci kampi (tel orgu)
CX0, CY0, CX1, CY1 = 4700, 1300, 5900, 2300
L.walls_box(CX0, CY0, CX1, CY1, {"W": [(260, 360)], "S": [(5250, 5350)]}, 12, "tel")
L.house("Barakalar", 4850, 1420, 440, 160, "S", [0.34, 0.3, 0.26], style="sade")
L.house("Ceza barakası", 5450, 1430, 260, 150, "S", [0.3, 0.28, 0.26], locked="baraka_anahtari", style="sade")
L.house("Kamp ofisi", 5450, 1950, 260, 150, "W", [0.36, 0.38, 0.32], style="sade")
L.ob("tent", rect(4900, 1900, 160, 100))
L.tower(4740, 1340, 135)
L.tower(5860, 2260, 315)

# ------------------------------------------------------------ GUNEY: kiyi, iskele (kacis)
L.house("Kayıkhane", 4900, 3560, 240, 150, "S", [0.4, 0.32, 0.26], style="sade")
L.house("Balıkçı kulübesi", 2900, 3500, 200, 130, "S", [0.4, 0.34, 0.28], style="sade")
L.ob("fence", rect(5450, 3640, 10, 240))
L.ob("crate", rect(5300, 3800, 50, 50))
L.tower(5300, 3300, 200)

# projektorler: tunel onu, avlu, kamp, kiyi yolu
for pole, path, sp in (([3200, 1000], [[2500, 940], [3200, 1000], [4300, 940]], 80),
                       ([3000, 1800], [[2400, 1750], [3500, 1750], [3900, 1900]], 75),
                       ([5300, 1700], [[4800, 1700], [5800, 1700], [5800, 2200]], 70),
                       ([4400, 3000], [[3900, 3190], [4900, 3190], [5300, 3400]], 75)):
    L.ob("projektor", circle=[pole[0], pole[1], 10])
    d.setdefault("searchlights", []).append({"pole": pole, "path": path, "speed": sp, "r": 64})

# ------------------------------------------------------------ ASKERLER (dag avcilari agirlikli)
G = L.guard
# baslangic kiyisi ve koy
G([[600, 3460], [1300, 3460]], None, "dag")
G([[1000, 3750]], 0, "dag")
G([[560, 2950]], 90, "dag")                                           # Hofer evinin arkasi
G([[900, 3200], [1300, 3200], [1300, 2900]], None, "dag")
G([[150, 2600], [150, 3100]], None, "dag")
G([[810, 2030]], 90, "dag")                                           # kilise kapisi
G([[500, 1500], [500, 2050], [1000, 2050]], None, "subay")            # koy devriyesi
G([[640, 2240]], 0, "dag")                                            # gasthaus kapisi
G([[400, 2220], [550, 2220]], None, "dag")                            # gasthaus ici
G([[1330, 1990]], 180, "dag")                                         # karakol kapisi
G([[1420, 1950], [1550, 2000]], None, "dag")                          # karakol ici
G([[1230, 1300], [1230, 2700]], None, "dag")                          # koy yolu
G([[900, 2500], [1350, 2650]], None, "dag")
G([[1450, 2300], [1450, 3000]], None, "dag")
G([[1700, 3000], [1700, 3500]], None, "dag")                          # dere dogusu
# avlu: ofis, trafo, kompresor, atolye, kisla
G([[2150, 1560]], 90, "elit")                                         # ofis kapisi
G([[2050, 1420], [2250, 1420]], None, "muhendis")                     # ofis ici
G([[2000, 1700], [3000, 1700], [3000, 1880], [2000, 1880]], None, "muhendis", "ofis_anahtari")   # BAS MUHENDIS (anahtar)
G([[2280, 2030]], 180, "dag")                                         # trafo kapisi
G([[2380, 2150], [2600, 2150]], None, "dag")
G([[3470, 1560]], 90, "dag")                                          # kompresor kapisi
G([[3350, 1420], [3600, 1420]], None, "muhendis")                     # kompresor ici
G([[4030, 1580]], 90, "dag")                                          # atolye kapisi
G([[3900, 1420], [4150, 1420]], None, "muhendis")                     # atolye ici
G([[3080, 1980]], 270, "elit")                                        # kisla kapisi
G([[2900, 2080], [3250, 2080]], None, "elit")                         # kisla ici
G([[3750, 1980]], 270, "dag")                                         # yemekhane kapisi
G([[4280, 2080]], 180, "dag")                                         # depo kapisi
G([[2400, 1640], [4600, 1640]], None, "subay")                        # ana yol subayi
G([[2600, 2300], [4400, 2300]], None, "dag")
G([[3300, 1800], [3300, 2300]], None, "elit")
G([[4500, 1700], [4500, 2300]], None, "dag")
G([[3900, 1880]], 180, "muhendis")
G([[2700, 1500]], 270, "dag")
# tunel onu ve YUVALAR (Sahin'in hedefi)
G([[2650, 860]], 90, "elit")                                          # tunel A girisi
G([[2780, 860]], 90, "dag")
G([[4150, 860]], 90, "elit")                                          # tunel B girisi
G([[4280, 860]], 90, "dag")
G([[2300, 960], [3000, 960]], None, "dag")
G([[3800, 960], [4600, 960]], None, "dag")                          # beton saha devriyesi
G([[3200, 700]], 90, "dag")["tag"] = "gozcu"                           # yuva 1: yar dibinde, tunel A - B arasi
G([[3560, 720]], 80, "dag")["tag"] = "gozcu"                           # yuva 2
G([[1950, 700], [1950, 1250]], None, "dag")
G([[5200, 700], [5200, 1200]], None, "dag")
# isci kampi
G([[4690, 1590]], 0, "dag")                                           # kamp bati kapisi
G([[4690, 1680]], 0, "dag")
G([[5300, 2330]], 270, "dag")                                         # kamp guney kapisi
G([[4850, 1700], [5700, 1700]], None, "subay", "baraka_anahtari")     # KAMP SUBAYI (anahtar)
G([[5580, 1620]], 90, "elit")                                         # ceza barakasi kapisi
G([[5000, 1460], [5200, 1460]], None, "dag")                          # barakalar ici
G([[5560, 2020]], 180, "dag")                                         # kamp ofisi ici
G([[5440, 2050]], 180, "dag")                                         # kamp ofisi kapisi
G([[4800, 2200], [5800, 2200]], None, "dag")
G([[4600, 1250], [5900, 1250]], None, "dag")                          # kamp kuzeyi (yar dibi)
# kiyi ve iskele
G([[2000, 3100], [3000, 3100]], None, "dag")
G([[3000, 3600]], 0, "dag")                                           # balikci kulubesi
G([[3400, 3260], [4400, 3260]], None, "dag")
G([[5000, 3740]], 270, "elit")                                        # kayikhane
G([[5450, 3560]], 180, "dag")                                         # iskele ucu
G([[4800, 3400], [5800, 3400]], None, "subay")
G([[5900, 2500], [5900, 3500]], None, "dag")
G([[3800, 2700], [4800, 2700]], None, "dag")
G([[2700, 2600], [2700, 3000]], None, "dag")
G([[2000, 2600], [2400, 2900]], None, "dag")
# ek devriyeler (Bolum 8'den biraz zor)
G([[3600, 2900], [3600, 3500]], None, "elit")
G([[5600, 2600], [5600, 3100]], None, "dag")
G([[2200, 2300], [2200, 2700]], None, "elit")
G([[1800, 1300], [1800, 1550]], None, "dag")
G([[4600, 2600], [5200, 2900]], None, "dag")
G([[900, 1300], [1100, 1600]], None, "dag")
G([[2050, 1100], [2350, 1250]], None, "elit")                         # ofisin kuzeyi
G([[2500, 1450], [2900, 1450]], None, "dag")
G([[3700, 1150], [3700, 1300]], None, "dag")                          # nisanci yerinin dogusu (zamanla)
G([[4400, 1300], [4400, 1600]], None, "elit")
G([[4900, 1100], [5800, 1100]], None, "dag")
G([[5100, 2000], [5300, 2000]], None, "dag")                          # kamp avlusu
G([[4300, 3000], [4300, 3500]], None, "dag")
G([[2400, 3400], [3300, 3400]], None, "dag")
G([[3300, 3700]], 90, "dag")
G([[1900, 3600], [1900, 3300]], None, "dag")
G([[700, 1150], [1150, 1150]], None, "dag")
G([[2700, 2450]], 0, "dag")
G([[5750, 1500], [5750, 1900]], None, "elit")                         # ceza barakasinin dogusu
G([[4100, 2200], [4100, 2500]], None, "dag")
G([[3500, 2600], [3500, 2400]], None, "muhendis")

# ------------------------------------------------------------ KARAKTERLER VE GOREVLER
d["npcs"] = [
    {"id": "franz", "outfit": "madenci", "name": "Franz Hofer", "pos": [520, 2780], "facing": 0},
    {"id": "tadeusz", "outfit": "isci", "name": "Tadeusz Kowal", "pos": [5580, 1500], "facing": 90},
    {"id": "isci1", "outfit": "isci", "name": "İşçi", "pos": [5100, 1800], "facing": 90},
    {"id": "isci2", "outfit": "isci", "name": "İşçi", "pos": [5160, 1830], "facing": 200},
    {"id": "isci3", "outfit": "isci", "name": "İşçi", "pos": [4980, 2100], "facing": 0},
]
d["document"] = [2150, 1440]
d["objectives"] = [
    {"id": "temas", "type": "reach", "text": "Bergdorf'ta maden ustabaşı Franz Hofer ile buluş", "pos": [520, 2780],
     "radius": 70, "gives": {"patlayici": 3, "tel_makasi": 1},
     "say": [["Franz Hofer", "Grüß Gott, çavuş. Üç patlayıcı ve bir tel makası. Madenden aşırdım, kimse saymaz."],
             ["Franz Hofer", "Yarın dibinde iki makineli tüfek yuvası var. Tünel ağızlarına bakıyorlar; aşağıdan kimse yaklaşamaz."],
             ["Yzb. Blake", "Kompresör binasının kuzeyindeki çalılıktan ikisini de görürüm. Beni oraya götür, Reilly."],
             ["Franz Hofer", "Tünellerin ışığı ve havası avludaki trafodan. Onu kesersen SS kışlası telefonu da susar."],
             ["Franz Hofer", "Tadeusz'u unutma. Tünelleri o kazdırdı, her köşesini bilir. Ceza barakasında."]]},
    {"id": "gozcu", "type": "eliminate", "tag": "gozcu", "spot": [3380, 1240],
     "text": "Şahin: yarın dibindeki iki makineli tüfek yuvasını uzaktan sustur",
     "done_say": [["Yzb. Blake", "İki yuva da sustu. Tünel ağızları artık kör, Reilly."]]},
    {"id": "trafo", "type": "sabotage", "text": "Trafo binasında hattı sessizce kes", "pos": [2400, 2025],
     "radius": 60, "time": 6.0, "disables_barracks": 0,
     "done_say": [["Çvş. Reilly", "Tünellerin ışığı titredi. SS kışlası artık kimseyi çağıramaz."]]},
    {"id": "anahtar", "type": "have", "item": "ofis_anahtari", "text": "Avludaki baş mühendisten ofis anahtarını al"},
    {"id": "cizim", "type": "take", "item": "jet_cizimleri", "text": "Mühendislik ofisinden jet motoru çizimlerini çal",
     "pos": [2150, 1440], "after": ["anahtar"],
     "done_say": [["Çvş. Reilly", "Jet motoru... Londra'dakiler bunu görünce inanmayacak."]]},
    {"id": "anahtar2", "type": "have", "item": "baraka_anahtari", "text": "Kamp subayından ceza barakasının anahtarını al"},
    {"id": "tadeusz", "type": "rescue", "npc": "tadeusz", "after": ["anahtar2"],
     "text": "Tadeusz Kowal'ı ceza barakasından çıkar (seni izler, onu da görebilirler)",
     "say": [["Tadeusz Kowal", "Dziękuję... Sizi bekliyordum ama bu kadar çabuk değil."],
             ["Tadeusz Kowal", "İki tünel ağzı da çökerse içerisi aylarca kazılamaz. Patlayıcıyı ağzın tam ortasına koyun."]]},
    {"id": "tunelA", "type": "destroy", "text": "Tünel A ağzını uçur", "pos": [2650, 940], "radius": 110},
    {"id": "tunelB", "type": "destroy", "text": "Tünel B ağzını uçur", "pos": [4150, 940], "radius": 110,
     "done_say": [["Yzb. Blake", "Dağ kapandı! Şimdi iskeleye, hepimiz!"]]},
    {"id": "kompresor", "type": "destroy", "optional": True, "text": "Kompresör istasyonunu uçur",
     "pos": [3470, 1600], "radius": 110},
    {"id": "kacis", "type": "exit", "text": "Herkesle birlikte doğudaki göl iskelesine kaç"},
]

# ------------------------------------------------------------ KISLALAR, SIRENLER, ESYALAR
d["barracks"] = [
    {"pos": [3080, 2300], "count": 8, "type": "elit", "delay": 5},     # 0: SS kislasi (trafo kesilince bos)
    {"pos": [1480, 2200], "count": 6, "type": "dag", "delay": 6},      # jandarma karakolu
    {"pos": [5600, 2100], "count": 6, "type": "dag", "delay": 6},      # kamp
    {"pos": [4300, 1250], "count": 6, "type": "dag", "delay": 7},      # tunel onu
    {"pos": [5000, 3300], "count": 6, "type": "dag", "delay": 7},      # kiyi
]
d["sirens"] = [[900, 2150], [1550, 1800], [2300, 1300], [3000, 1600], [3700, 1250], [4400, 1900],
               [5000, 2250], [3200, 3200], [5200, 3500]]
d["pickups"] = [
    {"type": "medkit", "pos": [800, 3300]},
    {"type": "medkit", "pos": [2100, 2500]},
    {"type": "medkit", "pos": [4200, 2600]},
    {"type": "medkit", "pos": [5500, 2900]},
    {"type": "ammo", "pos": [1100, 2800]},
    {"type": "ammo", "pos": [3500, 2700]},
    {"type": "ammo", "pos": [4600, 2450]},
    {"type": "stones", "count": 3, "pos": [1850, 2800]},
    {"type": "stones", "count": 2, "pos": [4400, 2500]},
    {"type": "item", "item": "patlayici", "count": 1, "pos": [4380, 2140]},     # depoda yedek
]

# ------------------------------------------------------------ GIZLI YOLLAR (kamis, koruluk, kaya)
L.bush_line([200, 3480], [200, 2400], 70, 28)                 # baslangictan koye
L.bush_line([1450, 3800], [1450, 3200], 70, 26)               # dere bati kiyisi kamislari
L.bush_line([1780, 3850], [3700, 3850], 75, 26)               # gol kiyisi kamisligi
L.bushes([[3380, 1240], [3320, 1210], [3440, 1210], [3300, 1280], [3460, 1280]], 28)   # NISANCI YERI (kompresorun kuzeyi)
L.bush_line([3700, 1290], [3780, 1290], 70, 26)               # atolye bati kosesi
L.bush_line([1850, 2600], [1850, 1950], 70, 28)               # dere dogusu -> trafo arkasi
L.bush_line([2050, 2250], [2250, 2250], 70, 26)
L.bush_line([4650, 3050], [4650, 2450], 75, 28)               # kiyi -> kamp guneyi
L.bush_line([4650, 2400], [4650, 2380], 75, 28)
L.bushes([[5950, 1300], [5950, 1450], [5950, 1600]], 26)
L.bushes([[2450, 2400], [3600, 2550], [4250, 2350], [2000, 1200], [1700, 1150]], 30)
L.bushes([[600, 1450], [1000, 1250], [300, 1800]], 30)

for p in d["sirens"] + [b["pos"] for b in d["barracks"]] + [k["pos"] for k in d["pickups"]] + [n["pos"] for n in d["npcs"]]:
    L.block(p[0], p[1], 0, 0, 60)
for o in d["objectives"]:
    if "spot" in o:
        L.block(o["spot"][0], o["spot"][1], 0, 0, 90)

# nisanci yeri -> yuvalar gorus hatti agacsiz kalsin
for t in (0.25, 0.5, 0.75):
    for (gx, gy) in ((3200, 700), (3560, 720)):
        L.block(3380 + (gx - 3380) * t, 1240 + (gy - 1240) * t, 0, 0, 40)

# ------------------------------------------------------------ AGAC / CALI DOLGU (karisik orman, sonbahar)
L.scatter(22, 80, 1000, 1100, 2000, "tree", 24, 36)           # koy kuzeyi
L.scatter(16, 80, 3000, 1400, 3850, "tree", 24, 34)           # baslangic korulugu
L.scatter(16, 1700, 2500, 2500, 3800, "tree", 24, 34)         # dere dogusu
L.scatter(14, 2600, 2500, 4500, 3000, "tree", 24, 32)         # avlu guneyi
L.scatter(16, 4500, 2400, 5950, 3600, "tree", 24, 36)         # kamp guneyi
L.scatter(8, 1500, 900, 2400, 1300, "tree", 24, 30)
L.scatter(12, 80, 1000, 1100, 2000, "bush", 24, 32)
L.scatter(10, 1700, 2500, 2500, 3800, "bush", 24, 30)
L.scatter(10, 4500, 2400, 5950, 3600, "bush", 24, 32)
L.scatter(6, 2600, 2500, 4500, 3000, "bush", 24, 30)
L.save("levels/bolum9.json")
