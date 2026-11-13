# Komando

Commandos 2: Men of Courage'dan esinlenen, 2. Dünya Savaşı'nda geçen gerçek zamanlı taktik / gizlilik oyunu.

- **Motor:** Godot 4.3 · **Dil:** GDScript
- **Platformlar:** PC (Windows + Linux, en kaliteli sürüm) ve Android APK. (Web sürümü 12 Kasım 2026'da kaldırıldı.)
- **Hepsini indir:** https://github.com/malisah61/komando/releases/tag/son-surum
- **APK indir:** https://github.com/malisah61/komando/releases/latest/download/komando.apk
- **Windows:** https://github.com/malisah61/komando/releases/latest/download/Komando-Windows.zip
- **Linux:** https://github.com/malisah61/komando/releases/latest/download/Komando-Linux.zip
- **Geliştirme günlüğü:** [docs/GELISTIRME.md](docs/GELISTIRME.md) (her tur: 5 yeni + 5 iyileştirilmiş özellik)

## Senaryo
Kampanya, karakterler ve bölüm planı: [docs/SENARYO.md](docs/SENARYO.md)

## Kontroller (ek)
- Aynı yere iki kez hızlı dokun: koşarak git.
- Sağ üstteki "Çevir" (PC: Q / E): haritayı 90° çevir, binaların öbür yüzünü gör (4 açı Blender'da ayrı render).
- Bot testi: `GODOT=godot python3 tools/bot/rapor.py` → `docs/BOT_RAPORU.md`.

## Tur 3 mekanikleri
- **Yumruk + Bağla:** SİLAH → Yumruk: arkadan yumruk askeri öldürmeden bayıltır (~40 sn). "Bağla" (ip) ile kalıcı etkisiz kalır; bağlanmazsa ayılır ve çevreyi arar. Öldürmeden etkisiz bırakmak puan kazandırır.
- **Islık:** 190 px içindeki askerleri bulunduğun yere çeker (5 sn bekleme). Tuzak kurmak için.
- **Dikenli tel + tel makası:** Tel örgü geçilmez ama görüşü kesmez. Tel makasın varsa telin yanında "Teli Kes" (3 sn): kendi kapını açarsın.
- **Projektör:** Işık yol boyunca gidip gelir; içinde yarım saniye kalan görülür. Kulesindeki nöbetçiyi susturursan söner. Alarmda ışık seni kovalar.
- **Asker yapay zekâsı v4:** tetikte kalma, ayak izini takip etme, bıçaklamaya tanık olma, SS/subay el bombası, kule gözcüsünün işareti, paylaşımlı arama.
- **ALARM!:** Seni gören asker bağırır, alarm hemen kırmızı olur ve yakındaki askerler geniş bir alanı tarar. Takviye ise ancak siren çalınca gelir: sirene koşanı durdur.
- **Açı değiştirme beklemesiz (Tur 5):** "Çevir" her basışta aynı karede, sert kesmeyle döner. PC'de 4 açı yükleme ekranında belleğe alınır; telefonda bulunulan açı + iki komşusu bellekte, kalan açıya art arda basılırsa önce zemin önizlemesi görünür, nesneler yarım saniye içinde gelir.

## Tur 2 mekanikleri
- **Taş at** (HAREKET → Taş, sonra yere dokun): düştüğü yerin 200 px çevresindeki askerler alarm vermeden bakmaya gider.
- **Alarm sireni:** Sireni olan bölümlerde seni gören ya da ceset bulan asker sirene koşar ("ALARM" yazar). Yolda durdurursan kırmızı alarm ve takviye olmaz.
- **Kilitli bina + anahtar:** Kilitli kapıda asma kilit görünür. Anahtar bir subayda (öldürünce düşer) ya da bir masada.
- **Gözetleme kulesi:** Kule nöbetçisi çok uzağı görür, yerinden ayrılmaz; taşla çevrilebilir.
- **Sessiz sabotaj:** Telsiz/trafo/makas gibi hedeflerde birkaç saniye hareketsiz kal; alarm çalmaz. Telsiz kesilince o kışla takviye gönderemez.
- **Siper:** Kum torbası, sandık, kaya, araç arkasında (özellikle çömelikken) daha zor vurulursun; askerler için de geçerli.
- **Kayıp nöbetçi:** Yanındaki nöbetçi kaybolursa (ceset saklansa bile) arkadaşı fark eder ve çevreyi arar.
- **Puan ve kayıt:** Bölüm sonunda süre, alarm, bulunan ceset, öldürülen asker ve rütbe (Hayalet / Usta / Komando / Çaylak). En iyi sonuç menüde görünür.

## Bina içleri ve harita
- Binaya dokun: komando kapıya yürür ve içeri girer. Bina içi ayrı bir haritadır (2 kat büyük, binaya özel eşyalar).
- **Pencereler (Tur 6):** her binada, Blender render'ındaki pencerelerin yerinde (`Level.window_spots` = `harita.py` yerleşimi). Pencereye dokun ya da yanına gel: "Pencereden Gir" / içeriden "Pencereden Çık". Kapıdan biraz yavaş (≈1,1 sn tırmanma + ses). Kilitli binanın pencereleri de kilitli; anahtar kapıyı ve pencereleri birlikte açar. Büyük haritada mavi çizgi (kilitliyse turuncu).
- İçeride "Kapıdan Bak" / "Pencereden Bak": yalnız açıklığın önündeki dar koni (~40°) görünür, duvar ve engeller görüşü keser, gerisi karanlık. "Dışarı Çık" ile çık.
- Askerler de kapıları kullanır. Seni görüp binaya (kapı ya da pencere) girdiğini fark eden askerler aynı yerden peşinden girer ve içeride arar; görmediyse son gördüğü yerde arar. Kilitli binaya yalnız anahtarı olan asker girer.
- **Yakından fark etme (Tur 6):** koninin dışından (yandan/arkadan) da: ayakta yürürken ~110 px, koşarken ~185 px (ses), çömelik yürürken ~50 px (çok yavaş), çömelik dururken hiç. Önce "?" belirir, şüphe dolunca asker döner (koni de döner). Alarm mesafeyi ve hızı artırır, duvar arkasından olmaz.
- Mini haritaya dokun: büyük harita açılır (binalar, kışlalar, görevler, eşyalar, çıkış).

## Görev sistemi
Bölüm dosyasındaki `objectives` listesi: `reach` (buluş/konuş, eşya ver), `take` (çal), `rescue` (esiri kurtar, seni izler),
`destroy` (patlayıcı kur: 2 sn kurulum + 8 sn fitil; `bridge` verilirse köprü yıkılır ve yollar değişir), `exit` (kaçış).
`optional: true` olanlar zorunlu değil. Bölüm başında brifing ekranı, görev sırasında diyaloglar (oyun duraklar).

## Bölümler
- **Bölüm 0 – Normandiya Köyü** (eğitim): küçük köy, 6 asker.
- **Bölüm 1 – Nehir Operasyonu**: 3600x2600 geniş harita, 25 asker. Direnişçi Pierre'den patlayıcı al, meydandaki subaydan belediye anahtarını al, kilitli belediyedeki pilot Carter'ı kurtar, karargâhtan planları çal, kuzey köprüsünü uçur (isteğe bağlı: yakıt deposu), pilotla botlara dön. Hedef süre 25–45 dk. Harita `tools/gen_bolum1.py` ile üretilir.
- **Bölüm 2 – Karlı Kale** (Tur 2): 4800x3400 Norveç fiyordu, ~50 asker (kış askeri, SS, subay), 4 gözetleme kulesi, 4 kışla, 5 siren. Lars ile buluş, köy telsizini sessizce kes, gardiyandan hücre anahtarını al, Şahin'i kurtar, kodları çal, uçaksavarı ve radarı uçur, kodları Lars'a teslim et, fiyorttaki tekneye kaç. Derin kar yavaşlatır ve iz bırakır. `tools/gen_bolum2.py`
- **Bölüm 3 – Denizaltı Üssü** (Tur 2): 5400x3800 Atlantik limanı, ~56 asker (SS ağırlıklı), 5 kule, 5 kışla, 6 siren, 13 bina. Gölge seni izler; trafoyu sabote et, liman anahtarıyla kilitli kontrol odasından sevkiyat defterini al, istasyondan tarifeyi çal, makası boz, bunkerdeki iki denizaltı kapısını uçur, doğu rıhtımına kaç. `tools/gen_bolum3.py`

- **Bölüm 4 – Gece Treni** (Tur 3): 6000x3800 gece demiryolu kavşağı, ~62 asker, 6 kule, 4 projektör, dikenli tel çevrili manevra sahası, kilitli nöbet barakası. Marie'den tel makası ve patlayıcı al, Kıvılcım'ı kurtar, sinyal kulübesini sabote et, sevk listesini çal, lokomotifi ve mühimmat vagonlarını uçur. `tools/gen_bolum4.py`
- **Bölüm 5 – Kartal Yuvası** (Tur 3, final): 6400x4200 şato + havaalanı + bocage çitleri, ~76 asker, 7 kule, 5 projektör, 7 kışla, 8 siren. Santrali kes, Storch'u ve radyo kulesini uçur, kâhyadan şato anahtarını al, planları çal, Richter'i esir alıp nehirdeki tekneye götür. `tools/gen_bolum5.py`
- **Bölüm 6 – Çelik Rampa** (Tur 4, Tur 5'te kılıksız yeniden düzenlendi): 6400x4200 V-1 orman üssü, baraj gölü, ~86 asker, 6 projektör. Kampa gizli giriş: kuzey duvardaki yıkık drenaj kanalı, taşla dikkat dağıtma, devriye zamanlaması. `tools/gen_bolum6.py`
- **Bölüm 7 – Sisli Ada** (Tur 5): 6400x4200 Baltık roket deneme adası, kanal (2 köprü + sazlık), ~88 asker, 9 kule, 7 projektör, 5 kapılı tel. `tools/gen_bolum7.py`

Yeni bölüm üreticileri `tools/bolum_lib.py` yardımcılarını kullanır (bina, asker, kule, çalı şeridi, nehir, duvarlı alan). Her bölüm için erişim testi: `godot --headless --script res://tests/sim_bolum.gd -- --level=res://levels/bolum2.json`.

## Varlık hattı ve boyut bütçesi
Tek hat: **render** (`tools/blender/harita.py`, kayıpsız PNG, `levels/<bölüm>_art/v0..v3/`) → **sıkıştırma** (`python3 tools/varlik/hat.py sikistir`, WebP + zemin önizlemesi) → **Godot import** (`hat.py ayarla`, ayarlar `tools/varlik_ayarlari.json`) → **export** (`export_presets.cfg`, test/araç/belge hariç). Her derlemede `hat.py butce` APK/zip boyutlarını yazar ve bütçe aşılırsa uyarır. Ayrıntı: `docs/GELISTIRME.md` → "Varlık ve boyut bütçesi".

## Harita render hattı (Blender)
`tools/blender/harita.py` bölüm dosyasından 3D sahneyi kurar (kiremit çatılı evler, pencereler, ağaçlar, çitler, kum torbaları, çadırlar, kamyonlar, tank, nehir, köprüler, çimen detayları) ve oyunun eğik bakış açısıyla render alır:
- `levels/<bölüm>_art/v<açı>/ground_X_Y.webp` – zemin karoları (nesnelerin gölgeleri dahil), `ground_mini.webp` (v0) mini/büyük harita
- `objects_N.webp` – her nesne ayrı parça; oyunda Y-Sort ile karakterlerle doğru sıralanır
- `roofs_N.webp` – çatılar; binaya girince şeffaflaşır
- `manifest.json` – parçaların atlas ve dünya konumları

Bölüm dosyası ya da script değişip push edilince GitHub Actions haritaları yeniden render eder. Komando bir nesnenin arkasında kalınca yeşil silüeti görünür.

## Asker modeli ve sprite hattı (Blender)
`tools/blender/asker.py` tek bir iskelet ve tek bir animasyon setiyle (bekleme, yürüme, koşma, bıçak, ölüm) her kıyafet için 8 yönlü sprite sheet üretir:
`komando`, `alman_er`, `alman_subay`, `alman_kis`. Yeni kıyafet = `OUTFITS` sözlüğüne bir kayıt; yeni hareket = `ANIMS` + `pose()`. Hepsi tüm askerlere otomatik geçer.
`tools/blender/` değişip push edilince GitHub Actions render alır ve `assets/sprites/` klasörüne yazar (commit mesajında `[render-yok]` varsa atlar).
Bölüm dosyasında askerin türü: `{"path": [...], "type": "subay"}` → `alman_subay_sprite_sheet.png`.

| Kontrol | İşlev |
|---|---|
| Dokun / tıkla | Yürü |
| **Bıçak** düğmesi + askere dokun | Yaklaşıp bıçakla |
| **Koş** | Hızlı ama gürültülü: yakındaki askerler sesi duyar |
| **Koni** / **Odak** | Görüş konilerini aç-kapa / kamerayı komandoya getir |
| Mini haritaya dokun | Kamerayı oraya taşı |
| Sürükle | Kamera |
| İki parmak / tekerlek | Yakınlaştır |

## Tasarım ilkeleri (rtte motorundan alınan 4 fikir)
1. **Hareket / görüş ayrımı:** her engelin `move` ve `view` özelliği var. Çalılık görüşü keser ama içinden geçilir; kum torbası geçişi engeller ama üstünden görülür.
2. **Çokgen engeller:** engeller serbest şekilli (`points`) ya da daire (`circle`).
3. **Ayak izi zeminleri:** `footprints: true` olan çamurda iz kalır; askerler izi görürse takip eder.
4. **Veri dosyasında bölümler:** her harita `levels/*.json` içinde, koddan bağımsız.

Ek olarak: NavigationAgent2D ile yol bulma, Y-Sort derinlik sıralaması, girilince şeffaflaşan çatılar, kademeli şüphe metresi (?/!), ceset ve ayak izi araştırma, ceset bulununca alarm seviyesi.

## Bölüm dosyası biçimi
```json
{"type": "bush", "circle": [500, 985, 38]}                     // görüşü keser, geçilir
{"type": "sandbag", "points": [[880,900],[1060,900],[1060,926],[880,926]]}
{"type": "hedge", "points": [...], "move": true, "view": false} // varsayılanı ezmek için
{"name": "Karargâh", "rect": [1120, 90, 300, 200], "door": "W"} // bina: N/S/E/W kapı
{"path": [[1190, 195]], "facing": 0}                           // tek noktalı = nöbetçi
```
Türler: `hedge`, `wall`, `sandbag`, `bush`, `crate`.

## Klasörler
- `scripts/level.gd` – bölüm yükleme, engeller, binalar, navigasyon, görüş hattı, ayak izleri
- `scripts/guard.gd` – düşman yapay zekâsı (devriye → şüphe → araştırma → arama)
- `scripts/commando.gd` – oyuncu (CharacterBody2D + NavigationAgent2D)
- `scripts/prop.gd` – yarı izometrik yükseltilmiş çizim
- `scripts/roof.gd` – şeffaflaşan çatı
- `tests/sim.gd` – otomatik test: `godot --headless --script res://tests/sim.gd`

## Araştırılan kaynaklar
- [martinstarman/rtte](https://github.com/martinstarman/rtte) (MIT) – 4 tasarım ilkesi
- [thedivergentai/gd-agentic-skills](https://github.com/thedivergentai/gd-agentic-skills) – gizlilik yapay zekâsı ilkeleri (kademeli tespit, araştırma, ceset katmanı, gruplar)
- [elyar-jamali/TopDown_Stealth_Game](https://github.com/elyar-jamali/TopDown_Stealth_Game) – yalnızca fikir (ticari olmayan lisans, kod alınmadı)
