# Geliştirme Günlüğü

Her geliştirme turunda hedef: **5 yeni oynanış özelliği**, **5 mevcut özelliğin iyileştirilmesi**, **yapay zekâda yaklaşık %25 ilerleme**, görsel kalite ve performans iyileştirmesi.
Gece görevi bu dosyaya her turun sonunda yeni bir bölüm ekler.

---

## Tur 1 – 11 Kasım 2026

### Araştırma özeti
- **Commandos serisi:** Alarm çalınca garnizon binalarından takviye askerler çıkar ve devriyeye başlar. Commandos 2'de kışla binaları kaldırılıp iç mekânlar getirildi. Düşman rütbeleri: er, elit (SS), teğmen, subay, Gestapo çavuşu. Rütbe yükseldikçe kılık değiştirmiş komandoyu fark etme ve alarm verme yeteneği artıyor.
- **Desperados III / Shadow Tactics (Mimimi):** Görüş konisi iki bölümlü. Konunun dolu (yakın) kısmında her şey görülür. Kesik çizgili (uzak) kısmında ise çömelen ve yerde yatan karakterler ile cesetler görülmez. Fark edilince koni sarıyla dolar, dolarsa alarm çalar ve asker ateş açar. Çömelmek yavaşlatır, bu yüzden "çömelmek mi, hızlı mı geçmek?" bir karar anı yaratır.
- **Godot 4 performansı:** Gevşek sprite yerine atlas kullanmak, VRAM sıkıştırmalı dokular, öncelik sırasına göre yükleme. Sahneye `add_child` sırasında oluşan takılmayı en aza indirmek için ağır kaynakların önceden hazırlanıp paylaşılması.

### 5 yeni özellik
1. **Can sistemi ve sağlık çantası:** Komando 100, pilot 60 can. Haritada sağlık çantaları ve mermi kutuları var. Sağlık düğmesi +50 can verir.
2. **Tabanca ve kalıcı silah seçimi:** Bıçak (sessiz, anında) veya tabanca (270 px menzil, mermi, ses yapar). Seçilen silah, sen değiştirene kadar seçili kalır. Askere dokunmak seçili silahla saldırır.
3. **Çatışma:** Fark edilince oyun bitmez. Askerler ateş eder (mermi izi, isabet olasılığı mesafeye bağlı). Komando ancak canı biterse ölür.
4. **Kırmızı alarm ve kışladan takviye:** Alarmda bütün askerler toplanmaz. Sadece sesi duyan yakındakiler gelir. En yakın 2 kışladan 3'er kişilik takviye birlik çıkar ve alarm noktasına koşar. Alarm, çatışma bitince sayaçla sarıya döner.
5. **Çömelme (Desperados kuralı):** Çömelen karakter koninin yalnızca yakın %55'lik kısmında görülür. Yavaş hareket eder ve askerlerin isabet oranı düşer.

### 5 iyileştirilen özellik
1. **Bıçak:** Seçim kalıcı, tek dokunuşla saldırı.
2. **Ceset sistemi:** Ceset taşınabilir. Çalılığa bırakılan ceset bulunamaz.
3. **Ses/alarm:** Silah sesi 420–600 px, patlama 800 px yarıçapta duyulur. Alarmı tüm harita değil, sadece duyanlar duyar.
4. **Görev arayüzü:** Duruma göre değişen aksiyon düğmesi (Patlayıcı Kur / Cesedi Taşı / Bırak), alarm göstergesi, kırmızı kenar parlaması, can çubukları, kısa bildirimler.
5. **Bölüm 1:** Elit SS askerleri, 3 kışla, 6 eşya.

### Yapay zekâ (+%25)
- Kademeli tespit artık mesafeye (yakında 3,3 kat hızlı), rütbeye (subay 1,35 kat, elit 1,25 kat) ve alarm seviyesine (sarı 1,4 kat, kırmızı 2 kat) bağlı.
- Çevresel algı: 46 px içinde ayakta hareket eden komandoyu arkasından da hisseder.
- Çatışma davranışı: hedefi görüyorsa ateş eder, görmüyorsa son görülen yere koşar, bulamazsa arar.
- Seslenme: çatışmaya giren asker 320 px içindekileri uyarır.
- Çok noktalı arama: şüpheli noktanın çevresinde 3 ayrı noktayı kontrol eder.
- Vurulan asker saldırgana döner.

### Görsel
- Bütün karakterler Quaternius UAL (CC0) hareketleriyle yeniden render ediliyor (7 kıyafet, 8 hareket: bekleme, yürüme, koşma, çömelme, bıçak, bomba kurma, ateş, ölüm). Yeni kıyafet: **elit SS**.
- Mermi izi, namlu alevi, kan, iyileşme efekti, can çubukları, alarm kenar parlaması.

### Performans
- **Yeniden başlatmadaki takılma giderildi.** Her asker kendi SpriteFrames'ini kuruyordu (yaklaşık 100 ms × 27 karakter ≈ 2,8 sn). Artık tek seferlik ve paylaşımlı. Yeniden başlatma **~2,8 sn → 0,04 sn**.
- Navigasyon ağı önbellekte, yeniden başlatmada tekrar hesaplanmıyor.
- Mini harita saniyede 10 kez çiziliyor (önceden her karede).

### Platformlar
- **PC (Windows + Linux)** en kaliteli sürüm, **Android APK** ikinci sürüm. Hepsi GitHub Release'te. (Web sürümü 12 Kasım 2026'da kaldırıldı; web için iş yapılmaz.)

### Kaynaklar
- Commandos Fandom – Barracks: https://commandos.fandom.com/wiki/Barracks
- Desperados III ipuçları (koni, çömelme): https://www.player2.net.au/2020/06/14-darn-tootin-tips-for-desperados-iii/
- Shadow Tactics dinamik tespit: https://gamedeveloper.com/design/game-design-deep-dive-dynamic-detection-in-i-shadow-tactics-i-
- Godot web/mobil performans: https://forum.godotengine.org/t/godot-4-web-export-stutters-on-mobile-its-probably-your-art-pipeline-not-your-code-31fps-to-60fps-benchmarks-inside/143268

## Tur 1b – Oyuncu geri bildirimi (11 Kasım 2026, 22:44)

Oyuncu Bölüm 1'i bıçakla 6:50'de bitirdi. Çalıdan yaptığı bıçak saldırıları fazla güçlüydü.

### Düzeltmeler
- **Çalı yakın mesafede görülür:** Çalı görüşü keser ama asker **105 px** (çömelikse **74 px**) içindeyse çalının içini görür (Desperados III / Shadow Tactics'teki "yakın mesafe saklanmayı bozar" kuralı).
- **Bıçak kuralı:** Tetikte (çatışmada) ve yüzü sana dönük askere bıçak tek darbede öldürmez: 35 hasar verir, çatışma sürer. Arkadan ya da habersiz askere tek darbe.
- **Silah gücü:** Er 11 hasar / 1,35 sn, SS elit 14 hasar / 1,05 sn ve 110 can, Subay 13 hasar / 1,1 sn.

### Yeni özellikler
1. **Büyük harita:** Mini haritaya dokununca tam ekran açılır. Bina adları, kışlalar (asker sayısıyla), köprüler (yıkıldıysa "yıkık"), numaralı görev noktaları, eşyalar, ÇIKIŞ ve komandonun konumu gösterilir. Bir yere dokununca kamera oraya gider.
2. **Bina içleri ayrı harita:** Her binanın iç haritası 2 kat büyüklükte, dış haritadan bağımsız. Kapıdan girilir ve çıkılır (binaya dokun, komando kapıya yürür ve girer). İçeride kamera sadece iç haritayı gösterir. Binaya göre eşya var: karargâhta masa, harita ve dolap; ambarda saman ve sandık; kilisede sıralar; geniş binalarda ara duvar.
3. **Kapıdan bakma:** İçerideyken "Kapıdan Bak" ile anahtar deliği görünümünden dışarıdaki askerler izlenir (Commandos 2'deki anahtar deliği).
4. **Askerler kapıları kullanır:** Kovalayan, araştıran ya da devriye gezen asker hedef başka bir alandaysa kapıya gidip geçer. Binaya kaçmak artık kesin kurtuluş değil.
5. **Takım geçişi:** Komandoyu izleyen karakterler (pilot) ve taşınan ceset kapıdan birlikte geçer.

### Testler
- `tests/sim4.gd`: Asker kapıdan girip takip ediyor. Uzaktaki asker çalıdakini görmüyor, yakındaki görüyor.
- `tests/sim2.gd`: Gir, kapıdan bak, çık ve büyük harita adımları eklendi.
- `Level.reach()`: Kapılardan geçerek erişilebilirlik kontrolü. Bütün devriye noktaları ve görev zinciri bununla doğrulanıyor.

## Tur 1c – Oyuncu geri bildirimi (12 Kasım 2026, 00:00)

### İstenenler
1. **Alarmda çalı daha tehlikeli:** Çalıdakini görme mesafesi sarı alarmda ×1,35, kırmızı alarmda ×1,75 (ayakta: 105 → 142 → 184 px). Arayan ya da araştıran asker ayrıca ×1,15.
2. **Çift dokunuş = koş:** Aynı yere 0,35 sn içinde iki kez dokununca komando o hareket için koşar. "Koş" seçili olmasa da, çömelikken bile.
3. **4 yönlü bakış (Commandos 2):** Sağ üstteki "Çevir" düğmesi (PC'de Q/E) haritayı 90° çevirir.
   - Her açı Blender'da ayrı render ediliyor (`harita.py --view 0..3`). Binaların öbür cepheleri görünür, güneş dünyaya sabit kalır, gölgeler her açıda tutarlıdır.
   - Oyunda kamera döner, karakterler dik kalır ve yön kareleri açıya göre kayar.
   - Döndürülmüş açıda Y-Sort yerine z sırası kullanılıyor (Godot Y-Sort yerel y'ye göre sıralar).
   - `harita.yml` artık bölüm × 4 açı paralel render alıyor.
4. **Kırmızı alarmda ateş refleksi:**
   - İlk atış gecikmesi: habersiz 1,0 sn, sarı 0,7 sn, kırmızı 0,45 sn. SS askerleri %15 daha hızlı.
   - Kırmızıda atış aralığı ×0,85, isabet +%5.
   - Asker namluyu hedefe çevirmeden (±17°) ateş etmez, arkadan yakalanınca dönme süresi kazanırsın.
5. **Bot oyuncu + analiz:**
   - `tests/bot.gd` her bölümü 3 tarzda oynar: gizli, saldırı ve tam (isteğe bağlı görevler dahil).
     - Gizli tarz çömelir; ilerideki noktayı gören devriye varsa bekler, şüphelenirse geri çekilir; arkadan bıçaklar; çatışmada tabanca kullanır.
   - Ölçtükleri: süre, tespit sayısı ve yerleri, hasar, bıçak/tabanca öldürmeleri, takviye, bekleme, takılma, ölüm yeri.
   - `tools/bot/rapor.py` sonuçları toplar ve `docs/BOT_RAPORU.md`'ye otomatik bulgu ve öneri yazar. `bot.yml` her push'ta CI'da çalışır.
   - Oyun `--fixed-fps 60` ile hızlandırılmış simüle edilir (yaklaşık 10 kat hızlı).

### Bot raporundan ilk bulgular
- Bölüm 0: bot 0:33'te kazanıyor, çok kısa.
- Bölüm 1: gizli bot 2:31'de kazanıyor, saldırı tarzı 30 sn'de ölüyor.
- Kazanan oyunlarda askerlerin çoğu öldürülüyor; gizlilik yeterince ödüllendirilmiyor.
- Gece geliştirmesi bu bulgulardan başlayacak.

## Tur 2 – Gece turu (12 Kasım 2026)

### 1. Bot analizi (turun başı)
Önceki rapor (`--seeds 3`, Tur 1c sonu):

| Bölüm | Gizli | Saldırı | Tam | Öne çıkan bulgu |
|---|---|---|---|---|
| Bölüm 0 | 3/3 zafer, 0:38–0:41, ort. 4,7 tespit | 3/3 zafer, 0:33 | 3/3 | çok kısa; saldırı kazanıyor; "Kilise yakını" darboğazı |
| Bölüm 1 | 1/3 zafer (2:31), ort. 16 tespit | 0/3 (0:32–0:34'te ölüm) | 2/3 (3:18) | "Ev 3 yakını" (29) ve güney yaya köprüsü (21) tespit noktaları; kazanan oyunlarda askerlerin çoğu öldürülüyor |

Son "Bot oyun testi" CI çalışması da aynı tabloyu verdi (başarılı, 12 oyun). Bulgulara göre geliştirme listesi:
1. **Gizlilik ödüllendirilmiyor** (her şeyi öldürüp kazanıyor) → kayıp nöbetçiyi fark etme, ceset bulana sirene koşturma, puan tablosu.
2. **Darboğazlar** (Ev 3, yaya köprüsü, karargâh kapısı) → Bölüm 1'e çalı/sandık siperi ve devriye değişikliği; dikkat dağıtmak için taş.
3. **Bölüm çok kısa** → kilitli kapı + anahtar ara adımı (Bölüm 1 belediyesi), yeni bölümlerde uzun zincir.
4. **Saldırı tarzı 30 sn'de ölüyor** → siper sistemi (kum torbası/sandık arkası).
5. **Bot zayıf** (her yere düz gidiyor) → tehlike haritalı A* rota, kapı nöbetçisinin arkasına dolanma, taş, ceset saklama, sirene koşanı vurma, kaçıp saklanma.

### 2. Yapay zekâ v3 (~%25)
- **Kayıp nöbet arkadaşı (Shadow Tactics):** Her nöbetçi en yakın arkadaşını bilir. Arkadaşı öldükten 6 sn sonra yerine bakınca orada yoksa (ceset saklansa bile) sarı alarm verir, yakındaki devriyeleri çağırır ve çevreyi arar.
- **Alarm sireni koşucusu (Commandos/Desperados III):** Sireni olan bölümde çatışma başlayınca ya da ceset bulununca bir asker en yakın sirene koşar. Ulaşırsa kırmızı alarm + takviye; yolda durdurursan alarm çalmaz.
- **Kuşatma:** Hedefi kaybeden askerler son görülen noktaya değil, her biri farklı yandan (±80 px) yaklaşır.
- **Siper alma:** Canı %40'ın altına düşen asker bir kez hedefin göremediği bir noktaya çekilir, 3 sn bekleyip yeniden çatışır.
- **Tahminli arama:** Arama ilk önce hedefin kaçtığı yöne (son hareket yönü ×160 px) bakar.
- **Subay düdüğü:** Subay çatışmaya girince 1,6 kat uzaktaki askerleri çağırır.
- **Gözetleme kulesi nöbetçisi:** 1,55× görüş, yerinden ayrılmaz, yavaş tarar.
- **Takip eden karakter siper alır:** Kurtarılan Şahin/Gölge ateş altında komandonun yakınındaki, nişancının göremediği çalıya geçip çömelir.
- **Taşa tepki:** Taş düşen yere alarm vermeden bakmaya gider (Desperados III'teki dikkat dağıtma).
- **Kapı/alan:** Askerler kilitli kapılardan geçebilir (anahtarları var).
- **Performans LOD'u:** Her oyuncudan 1500 px uzaktaki asker algıyı 5 Hz'de yapar.

Ölçüm (aynı bot, Bölüm 0): gizli bot artık 0 tespitle kazanıyor (önce ort. 4,7 tespit), saldırı yine 34 sn. Bölüm 1'de anahtar + kilitli belediye + kayıp nöbetçi + siren ile gizli bot 0/3'e düştü. Botun ilk tespiti 2:12–8:22 arasında; öncesinde ilk tespit ~0:30–1:10 idi. Bölüm 1 artık daha zor bir bölüm; bot iyileştirmesi sürecek.

### 3. 5 yeni özellik
1. **Taş atma (dikkat dağıtma):** "Taş" düğmesi + dokunuş. 320 px menzil, 200 px ses. Bölüm başına 4–6 taş.
2. **Alarm sireni + koşucu:** Haritada direk ve kırmızı lamba, çalınca yanıp söner. Koşan askerin üstünde "ALARM" yazar.
3. **Kilitli bina + anahtar düşüren subay:** `"locked": "anahtar"` bina alanı, `"drops"` asker alanı, `have` görev türü. Kapıda asma kilit, büyük haritada "kilitli".
4. **Gözetleme kulesi:** `tower` engel türü (Blender'da 4 dikmeli kule, platform z=46) ve üstünde `kule` nöbetçisi.
5. **Sessiz sabotaj:** `sabotage` görev türü (N sn hareketsiz kal). `disables_barracks` ile o kışla alarmda takviye gönderemez (köy telsizi, trafo, makas).

Ek olarak: **derin kar** (`slow` zemin: ×0,72 hız, iz bırakır), **görev önkoşulu** (`after`), **bölüm sonu puanı ve kayıt** (Hayalet/Usta/Komando/Çaylak, menüde en iyi sonuç).

### 4. 5 iyileştirilen özellik
1. **Çatışma/siper:** Kum torbası, sandık, kaya, araç, duvar arkasındaki hedefe isabet ×0,7 (çömelikse ×0,45); komandonun tabancası için de ×0,6.
2. **Ceset sistemi:** Ceset bulan asker sirene koşar; ceset saklamak kayıp nöbetçi fark edilmesini engellemez (sadece geciktirir). Tüm askerlerin tüm askerleri taraması yerine tek ceset listesi.
3. **Bölüm 1:** Bot tespit noktalarına çalı/siper (yaya köprüsü iki yaka, Ev 3, karargâh kapısı), güney köprü nöbetçisi devriyeye çevrildi, 3 siren, belediye kilitli (anahtar meydan subayında).
4. **Arayüz:** Uzun görev listesi sıkışık (biten görevler tek satır, en fazla 5 açık), önkoşullu görev gri "(sonra)", sabotaj ilerleme düğmesi, büyük haritada siren/kilit/kule/anahtar, menüde en iyi puan.
5. **Bot oyuncu:** tehlike haritalı A* gizli rota (sabit nöbetçi konileri ve devriye hatları pahalı, çalılar ucuz), kapı nöbetçisinin arkasına dolanma, taşla çevirme, ceset saklama, sirene koşanı vurma, çok kişi ateş ederken kaçıp çalıya saklanma, alarmda koşarak kaçış. `rapor.py` paralel çalışıyor (CI'da 4 iş).

### 5. Yeni bölümler
| | Bölüm 1 | **Bölüm 2 – Karlı Kale** | **Bölüm 3 – Denizaltı Üssü** |
|---|---|---|---|
| Harita | 3600x2600 | 4800x3400 | 5400x3800 |
| Asker | 25 | 49 (kış, SS, subay, 4 kule) | 56 (SS ağırlıklı, 5 kule) |
| Kışla / siren | 3 / 3 | 4 / 5 | 5 / 6 |
| Bina (iç harita) | 12 | 10 | 13 |
| Görev | 7 | 10 | 11 |
| Yeni öğeler | | fiyort, nehir + buz geçidi, duvarlı kale, radar tepesi, derin kar, kilitli hapishane | iç havuz, beton rıhtım, bunker iç haritası, demiryolu deposu, takip eden Gölge |

Üreticiler: `tools/gen_bolum2.py`, `tools/gen_bolum3.py` ortak `tools/bolum_lib.py` ile. Dolgu (ağaç/çalı/kaya) askerlerden sonra hesaplanıyor; sonradan eklenen devriyeler dolgudan sonra eklenir ki render edilen geometri değişmesin.
Blender: `harita.py` artık `theme: "kar"` (kar zemin, karlı ağaç/kaya, çamurlu kar yollar), `beton` zemin ve `tower` nesnesi destekliyor.

### 6. Performans
- `tests/perf.gd` artık oyun mantığını (process + physics) ve asker başına maliyeti ölçüyor.
- Bölüm 1, köy (25 asker): `_process` **1,29 ms → 0,79 ms** (mini harita statik katmanı: zemin ve engeller sadece köprü yıkılınca yeniden çizilir).
- Asker yapay zekâsı toplamı **0,62 → 0,47 ms/kare** (sakin devriyede koni 9 Hz, ışın 30 → 24, ceset listesi, uzak askerde 5 Hz algı). Bölüm 3'te 56 askerle 0,41 ms/kare.
- Navigasyon: büyük haritada "merge edge" hatası `map_set_merge_rasterizer_cell_scale(0.001)` ile giderildi (2D harita 4.3'te 3D sunucunun haritası). Bütün bölümler hatasız.

### 7. Testler
- `tests/sim.gd`, `sim1–4.gd` geçiyor (sim2 görev kimliğiyle, sim3 siren gecikmesine göre güncellendi).
- `tests/sim_bolum.gd`: yeni bölümler için `Level.reach` erişim testi (başlangıç → her görev sırayla → çıkış, bütün devriye noktaları, eşya, kışla, siren, bina kapıları). Bölüm 2 ve 3 başarılı.
- `tests/shot_bolum.gd`: xvfb ile 4 açıdan ekran görüntüsü.

### 8. Bot önce / sonra
(Tablo `docs/BOT_RAPORU.md` sonu ile aynı; bot da bu turda değişti.)

| Bölüm | Gizli (önce → sonra) | Saldırı (önce → sonra) | Not |
|---|---|---|---|
| Bölüm 0 | 3/3, 0:40, 4,7 tespit → **3/3, 1:01, 0 tespit** | 3/3 (0:33) → 3/3 (0:34) | bot artık hiç görülmeden bitiriyor; eğitim bölümü kısa kalıyor |
| Bölüm 1 | 1/3 (2:31), 16 tespit → **0/3**, 13 tespit; en uzun oyun 8:22 | 0/3 (0:33) → 0/3 (0:30) | anahtar + kilitli belediye + siren + kayıp nöbetçi bölümü zorlaştırdı; tespit "Ev 3 yakını"nda toplanıyor |
| Bölüm 2 (yeni) | **1/3 zafer (5:02)**, ort. 4,3 tespit; diğer ikisi 4:22–4:43'te 6–8 görevle | 0/3 (0:59–1:12) | saldırı zorlanıyor ✔; gizli kazanabiliyor ✔; süre hedefi (≥10 dk) henüz değil ✘ |
| Bölüm 3 (yeni) | 0/3, 7 görev bitiyor (4:28–4:59), Gölge kaçışta ölüyor | 0/3 (0:40–0:55) | takipçiyi koruyan bot davranışı eksik |

Bot zaferinin süresi insan süresi değildir: bot mükemmel yolu bilir ve hiç keşif yapmaz. Oyuncu bölüm 1'i 6:50'de bitirmişti (bot 2:31). Bölüm 2 için tahmini insan süresi 20–30 dk.

### Ekran görüntüleri (render sonrası, xvfb)
- Bölüm 2 kuzey açı: `docs/ekran/tur2_bolum2_kuzey.jpg` · doğu (döndürülmüş): `docs/ekran/tur2_bolum2_dogu.jpg`
- Bölüm 3 güney (döndürülmüş, alarm koşucusu): `docs/ekran/tur2_bolum3_guney.jpg`
- Bölüm 1 batı (döndürülmüş, siren direği dik): `docs/ekran/tur2_bolum1_bati.jpg`
Render: Bölüm 1–3 × 4 açı paralel (Bölüm 2 ~95 dk, Bölüm 3 ~120 dk). Siren direği döndürülmüş açıda yan yatıyordu, düzeltildi.

### 9. Sonraki tur için öncelikler (bot raporundan)
1. Bot: takip eden karakteri (Şahin/Gölge) koruma ve çalılardan geçirme; Bölüm 1 "Ev 3" ve Bölüm 3 "Trafo" darboğazlarına ek gizli yol.
2. Bölüm 2/3'ü bot için ≥10 dk yap: dönüş yolunda ek ara görev, kaçışta devriye artışı.
3. Bölüm 0: saldırı tarzı hâlâ kazanıyor (eğitim bölümü) → siren ve 2. kışla.
4. Bölüm 2–3 render'ı bittikten sonra 4 açıdan görsel kontrol (z sırası, kule platformu).

### Kaynaklar
- Desperados III gerçek zamanlı gizlilik ve çatışma tasarımı (Mimimi): https://gamedeveloper.com/design/designing-the-real-time-stealth-and-combat-of-i-desperados-iii-i-
- Desperados III alarm ve keşif rehberi (alarm askeri, dikkat dağıtma): https://www.gamepressure.com/desperados-iii/exploration-and-sneaking/zdd045
- Desperados III – nöbetçinin yerinden ayrılmaması: https://www.gamepressure.com/desperados-iii/enemy-why-does-not-leave-the-post/z9d04a
- Shadow Tactics düşman türleri ve davranışları: https://www.gamepressure.com/shadowtactics/types-of-enemies/z4941f
- Shadow Tactics düşman analizi: https://vigaroeentertainment.blogspot.com/2024/11/shadow-tactics-blades-of-shogun-enemy.html
- Stealth oyunlarında alarm sistemi (tartışma): https://forums.unrealengine.com/t/tips-for-implementing-an-ai-alarm-system-in-a-stealth-game/2325182
- Commandos 2 (kışla, iç mekân, 4 yönlü kamera): https://commandos.shoutwiki.com/wiki/Commandos_2
- Partisans 1941 (siper, takım, gizlilik + çatışma dengesi): https://www.pcgamer.com/partisans-1941-review/
- Godot AStarGrid2D (bot rota planlayıcısı) ve NavigationServer merge rasterizer ayarı: Godot 4.3 belgeleri

---

## Varlık ve boyut bütçesi

Varlık hattı tek yerde ve belgeli (kod: `tools/varlik/hat.py`, ayarlar: `tools/varlik_ayarlari.json`):

1. **Render** – `tools/blender/harita.py <bölüm>.json --view K` → `levels/<bölüm>_art/vK/` (v0..v3 hep aynı düzen; kayıpsız PNG karolar ve atlaslar + `manifest.json`).
2. **Sıkıştırma** – `python3 tools/varlik/hat.py sikistir levels/<bölüm>_art/vK` → zemin 1024 px WebP karolar (bölüme özel çözünürlük ölçeği), nesne/çatı atlasları saydamlığı koruyan kayıplı WebP (sağ/alt boş alan kırpılır), v0 için 2048 px zemin önizlemesi (`ground_mini.webp`: mini harita, büyük harita, açı yüklenirken yer tutucu).
3. **Godot import** – `hat.py ayarla` ayarlardan `project.godot [importer_defaults]` ve `.import` dosyalarını yazar: harita = Lossy WebP (kalite 0,82, mipmap yok); karakter sprite'ları = VRAM (ETC2/S3TC; her an ekranda olduklarından telefonda 4 kat az bellek).
4. **Sprite paketi** – `godot -s res://tools/varlik/sprite_paketle.gd` (CI'da import'tan sonra): karakter sprite'ları platform biçimine (ETC2 telefon, S3TC PC) sıkıştırılıp zstd'li `.res` olarak paketlenir. Godot APK'da `.ctex` dosyalarını sıkıştırmadan saklıyordu (sayfa başına 8,4 MB); paket 1,8 MB. Bellekte yine VRAM biçimi.
5. **Export** – `export_presets.cfg`: `tests/ tools/ docs/ kaynak/ *.glb *.md` hariç; her platform yalnız kendi sprite biçimini alır (`export_haric_platform`); Android yalnız ETC2/ASTC ve yalnız arm64-v8a, PC yalnız S3TC; Android release şablonu; proje ikonu.
6. **Bütçe** – `hat.py butce` her derlemede bölüm × açı MB'ını ve APK/zip boyutlarını yazar (Actions özeti + sürüm notu); bütçe aşılırsa `::warning::`.

Hedefler (12 Kasım 22:05 kararı): **APK ≤ 200 MB**, **PC zip ≤ 300 MB** (PC en kaliteli sürüm), ana bölüm başına telefonda **≤ 15 MB** (4 açı toplamı), bonus görev ≤ 5 MB. Web yok.

**Açılar bellekte (Tur 5):** PC'de 4 açının atlasları ve sprite'ları yükleme ekranında kurulur (paralel iş parçacığı yükleme); telefonda bulunulan açı + iki komşusu kurulu, karşı açı ilk basışta arka planda sırayla (sayfa sayfa, kare başına 48 sprite) kurulur. Komşu açıların zemin karoları da kamera çevresinde akar (yalnız ekran alanı, 0,1 sn'de 1 karo). Dört açının ortak düşük çözünürlüklü önizlemesi `ground_mini` (v0, dünya yönünde çizilir) her zaman bellekte.

| Bölüm | v0 | v1 | v2 | v3 | Toplam MB (Godot .ctex) |
|---|---|---|---|---|---|
| bolum0 | 0,8 | 0,6 | 0,7 | 0,7 | 2,8 |
| bolum1 | 3,3 | 3,0 | 3,1 | 3,1 | 12,5 |
| bolum2 | 3,0 | 2,9 | 3,0 | 2,8 | 11,7 |
| bolum3 | 5,5 | 5,2 | 5,4 | 5,4 | 21,6 (zemin 3,9 MB/açı; eski bölüm, bütçe öncesi) |
| bolum4 | 3,8 | 3,6 | 3,6 | 3,6 | **14,6** ✔ (zemin 0,75 ölçek + Godot kalite 0,62, skyline atlas) |
| bolum5 | 3,9 | 3,6 | 3,7 | 3,7 | **14,9** ✔ (zemin 0,75 ölçek + kalite 0,55, nesne kalite 0,66, skyline atlas) |
| karakter sprite'ları | | | | | 56,0 |

Önce (Tur 2, açı başına bölüm 3'te ~27 MB) → sonra (5,4 MB). Bölüm 3'te zemin açı başına 2048² DXT1/ETC2 yerine 1024 px WebP.

## Tur 3 – Gece turu (12 Kasım 2026)

### 0. Boyut, akıcılık ve düzen (öncelik)
Sebep: haritaların 4 açısı VRAM sıkıştırmayla (DXT/ETC2, 4–8 bit/piksel) paketleniyordu; Web paketine iki biçim birden giriyordu; `kaynak/*.glb` ve testler de export ediliyordu.

| Paket | Önce (Tur 2) | Sonra (Tur 3, CI ölçümü) |
|---|---|---|
| APK | 723,7 MiB | **148,9 MiB** (debug → release şablonu, yalnız ETC2) |
| Windows zip | 267,8 MiB | **88,3 MiB** |
| Linux zip | 262,0 MiB | **82,6 MiB** |
| Web .pck | 1342 MiB (iki doku biçimi) | **106,0 MiB** |
| Bölüm 3, açı başına | ~27 MB | **5,4 MB** |

(Bölüm 4–5'in render'ı CI'da sürüyor; render sonrası paket boyutu `build.yml` sürüm notunda.)

Yapılanlar:
- Harita atlasları ve zemin **kayıplı WebP** (Godot Lossy 0,82), zemin 1024 px karolar, atlasların boş sağ/alt kenarı kırpıldı, mipmap kapalı. Karakter sprite'ları VRAM'de kaldı (telefonda 4× az bellek).
- `levels/<bölüm>_art/v0..v3` tek düzen (v0 artık kökte değil). `harita.py` kayıpsız PNG verir, `hat.py sikistir` WebP'ye çevirir, `hat.py ayarla` import ayarlarını tek dosyadan (`tools/varlik_ayarlari.json`) yazar.
- `harita.yml` artık sadece değişen bölümleri render eder; render işinde sıkıştırma adımı var. `build.yml` her derlemede bölüm × açı MB'ını ve paket boyutlarını yazar, bütçe aşılırsa uyarır.
- **Bellek:** görünmeyen açının dokuları tutulmuyor. Açı değişince eskisi bırakılır, yenisi `ResourceLoader.load_threaded_request` ile arka planda yüklenir, bu sırada "Çevriliyor…" ve zemin önizlemesi görünür. Zemin karoları kamera yakınında akışla yüklenir, uzaktakiler bırakılır (0,1 sn'de en fazla 3 karo).

Ölçüm (`tests/perf.gd`, Bölüm 3, 56 asker, xvfb + llvmpipe yazılım GPU; gerçek GPU'da kare süreleri çok daha kısa, oranlar önemli):

| | Önce | Sonra |
|---|---|---|
| Bölüm açılışı (sahne kurulumu + ilk kare) | 1081 ms | **747 ms** |
| Ortalama / en yavaş kare (sabit kamera) | 51,8 / 78,8 ms | 50,2 / 75,8 ms |
| Açı değişimi: en yavaş kare | 351 ms (tek karede donma) | **92 ms** (yükleme arka planda, toplam 689 ms) |
| Kamera kaydırma: en yavaş kare | 60 ms | 79 ms (karo GPU'ya yüklenirken; yazılım GPU'da abartılı) |
| Doku belleği başlangıç / en yüksek | 236 / 325 MB (her gezilen açı +~90 MB, birikir) | 268 / **352 MB** (birikmez) |

Telefonda doku belleği: bu ortamda gerçek telefon yok; GL Compatibility sürücüsünde aynı ölçüm sprite'lar ETC2 olduğu için telefonla aynı büyüklükte (~270–350 MB). Gerçek cihaz ölçümü sonraki tura not.

Görüntü: 4 açıdan aynı yerlerden önce/sonra (yakınlaştırma 2,0) yan yana karşılaştırıldı (`docs/ekran/tur3_sikistirma_*.jpg`). Bantlaşma ya da kenar halesi yok; kardaki ince doku çok az yumuşadı, eski DXT/ETC2 blok gürültüsü kayboldu.

### 1. Bot analizi (turun başı)
Turun başında rapor (Tur 2 sonu ile aynı): Bölüm 0 saldırı 0:34'te kazanıyor; Bölüm 1 "Ev 3 yakını" darboğazı (44 tespit); Bölüm 2 gizli 1/3 (5:02); Bölüm 3 Gölge kaçışta ölüyor (3/3); "tam" tarzı isteğe bağlı görev yapmıyor. CI "Bot oyun testi" son çalışması başarılıydı.
Geliştirme listesi bu bulgulardan: takipçiyi koruyan bot, Bölüm 0'a siren + 2. kışla, Ev 3 darboğazında kapı nöbetçisinin yönü, yeni bölümlerde birden çok yaklaşım (tel kesme, çalı şeritleri).

### 2. Yapay zekâ v4
- **Tetikte kalma (Shadow Tactics):** şüphelenen, ceset ya da iz bulan asker 45 sn boyunca %20 daha geniş bakar, %25 daha hızlı fark eder; arama nokta sayısı artar.
- **İz sürme (Commandos 2):** fark edilen ayak izinden sonra daha yeni izleri takip eder (8 adıma kadar).
- **Tanık + boğuşma sesi:** bıçak/yumruk sırasında komandoyu gören asker anında çatışmaya girer; 70 px içindekiler sesi duyar.
- **El bombası:** SS ve subay, siperde kaybolan hedefe 110–300 px'ten el bombası atar (70 px, siper korumaz, arkadaşına atmaz).
- **Kule gözcüsü:** kule nöbetçisi çatışmaya girince 2× uzaklıktaki askerleri çağırır; projektör operatörü ışığı hedefe çevirir.
- **Paylaşımlı arama:** yakında arayan askerler birbirinin baktığı noktaya bakmaz, alanı bölüşür.
- **Kılık tanıma:** üniformalı komandoyu erler ancak çok yakından ya da koşarken, SS/subay koninin yakın kısmında tanır.
- **Ayılma:** bayıltılan asker ~40 sn sonra ayılır, çevreyi arar, yakındakileri uyarır; baygını bulan asker onu ayıltır.

Ölçüm (aynı bölümler, gizli bot, 3 tohum, ortalama tespit): Bölüm 1 13,0 → 17,3 (+%33), Bölüm 2 4,3 → 7,0 (+%63), Bölüm 3 8,7 → 12,3 (+%41). Bölüm 2'de gizli bot zaferi 1/3 → 0/3. Artış hedeflenen %25'in üstünde; bir sonraki turda denge ayarı gerekiyor.

### 3. 5 yeni özellik
1. **Üniforma (kılık değiştirme, Commandos 2 casusu):** er/kış askerinin cesedinden "Üniforma Giy"; komandonun sprite'ı Alman eri olur.
2. **Yumruk + Bağla:** öldürmeden bayılt, ip ile bağla (3 ip); bayıltma puan kazandırır.
3. **Islık:** 190 px içindeki askerleri bulunduğun yere çeker (5 sn bekleme).
4. **Dikenli tel + tel makası:** yeni `tel` engeli (Blender'da kazık + sarmal tel), "Teli Kes" 3 sn; navigasyon yeniden hesaplanır, kesilen parça 4 açıda da gizlenir.
5. **Projektör:** yeni `projektor` engeli + `searchlights` bölüm alanı; ışık yol boyunca gidip gelir, 0,5 sn içinde kalanı operatör görür; operatör düşerse ışık söner, alarmda ışık hedefi kovalar.

### 4. 5 iyileştirilen özellik
1. **4 yönlü bakış:** arka planda yükleme, "Çevriliyor…", açı başına bellek bırakma, zemin akışı (yukarıda).
2. **Mini harita / büyük harita:** 88 zemin karosunu çizmek yerine tek 2048 px önizleme (daha hızlı, açı değişince de bozulmaz).
3. **Bölüm 0:** 2 siren, 2. kışla, ek devriye (saldırı tarzı sirene koşanı durdurmak zorunda).
4. **Bölüm 1:** belediye kapısı nöbetçisi güneybatıya bakıyor; kuzeyden (Ev 2 tarafı) arkasından yaklaşılabilir.
5. **Bot:** takipçi geride kalırsa bekler; projektör ışığı yaklaşırsa yolundan çekilir (Bölüm 4'te ışığa yakalanma 11–12 → 0); tel makasıyla rotasındaki teli keser; yumrukla bayıltıp bağlar; duvar arkasındaki askere saldırmaya çalışıp takılma hatası giderildi. Puan: öldürülen/bayıltılan ayrı, tanık cezası.

### 5. Yeni bölümler
| | Bölüm 3 | **Bölüm 4 – Gece Treni** | **Bölüm 5 – Kartal Yuvası** |
|---|---|---|---|
| Harita | 5400x3800 | 6000x3800 | 6400x4200 |
| Asker | 56 | 61 | 76 |
| Kule / projektör | 5 / 0 | 6 / 4 | 7 / 5 |
| Kışla / siren | 5 / 6 | 6 / 7 | 7 / 8 |
| Görev | 11 | 9 | 9 |
| Yeni öğeler | | gece, tel çevrili manevra sahası, mühimmat treni, kilitli baraka, Kıvılcım | şato (kilitli), havaalanı (telli), bocage çit labirenti, nehir + 2 köprü, Richter esir |

Üreticiler `tools/gen_bolum4.py`, `tools/gen_bolum5.py` (`bolum_lib.py`). `sim_bolum.gd` erişim testi ikisinde de başarılı, "merge edge" yok. Boyut bütçesi için zemin 1,5 px/birim (`bolum_ozel`), nesne/çatı 2 px/birim.

### 6. Bot önce / sonra (3 tohum)
| Bölüm | Gizli (önce → sonra) | Saldırı (önce → sonra) | Not |
|---|---|---|---|
| Bölüm 0 | 3/3, 1:01, 0 tespit → 3/3, 1:01, 0 | 3/3 (0:34) → 3/3 (0:34) | sirenler saldırı botunu durdurmadı: kışla takviyesi gelmeden bitiyor |
| Bölüm 1 | 0/3, 13,0 tespit → 0/3, 17,3 | 0/3 → 0/3 | "Ev 3 yakını" 44 → 24 tespit; "Ev 5" ve güney köprüsü öne çıktı |
| Bölüm 2 | 1/3 (5:02) → 0/3, 6/9 görev | 0/3 → 0/3 | AI v4 sonrası kodlar/radar sonrası dönüşte ölüyor |
| Bölüm 3 | 0/3 → 0/3, 7/11 görev | 0/3 → 0/3 | Gölge ölümü 3/3 → 2/3 (takipçi bekleme); "(2300,1200)" darboğazı |
| Bölüm 4 (yeni) | 0/3, 4/9 görev (3:45), 4,7 tespit | 0/3 (0:37–1:41) | saldırı zorlanıyor ✔, gizli kazanamıyor ✘ (saha güneybatı köşesi) |
| Bölüm 5 (yeni) | 0/3, 2–4/9 görev (~3:00) | 0/3 (~1:30) | saldırı zorlanıyor ✔, gizli kazanamıyor ✘ (radyo kulesi çevresi) |

### 7. Sonraki tur için öncelikler
1. **Denge:** AI v4 gizli botu fazla cezalandırıyor. Bölüm 2–5'te gizli botun kazanabilmesi için tanık mesafesi/tetikte kalma çarpanı ya da darboğazlara ikinci yol.
2. Bot: Bölüm 4 saha güneybatısı (kule + kapı) ve Bölüm 5 radyo kulesi için yaklaşım; üniforma ve ıslık kullanımı.
3. Bölüm 0 saldırı tarzı: takviye gecikmesi kısalt ya da belge kilitli dolapta.
4. Gerçek telefonda doku belleği ve kare süresi ölçümü.

### Kaynaklar
- Commandos 2 (casus kılığı, tel makası, bayıltma/bağlama, projektörler): https://commandos.shoutwiki.com/wiki/Commandos_2 · https://www.gamespot.com/reviews/commandos-2-men-of-courage-review/1900-2879150/ · https://download.gamestar.de/public/31600/31689/11_2001_tipps_commandos2.pdf
- Shadow Tactics düşman türleri (tetikte kalma, arama): https://www.gamepressure.com/shadowtactics/types-of-enemies/z4941f
- Desperados III (nöbet yeri, dikkat dağıtma): https://www.gamepressure.com/desperados-iii/enemy-why-does-not-leave-the-post/z9d04a · https://www.player2.net.au/2020/06/14-darn-tootin-tips-for-desperados-iii/
- Godot görüntü içe aktarma (Lossy / VRAM / Basis): https://docs.godotengine.org/en/4.3/tutorials/assets_pipeline/importing_images.html
- Godot web/mobil sanat hattı: https://forum.godotengine.org/t/godot-4-web-export-stutters-on-mobile-its-probably-your-art-pipeline-not-your-code-31fps-to-60fps-benchmarks-inside/143268

### Tur 3b – Elle başlatılan tur (12 Kasım 10:01): ADIM 0 ikinci geçiş
Öncelik yine boyut, kasma, düzen.
- **APK içeriği doğrulandı:** release APK'da yalnız `.etc2.ctex` var, S3TC yok; test/araç/belge/kaynak dosyası yok. En büyük kalemler Godot kütüphanesi (iki mimari 125 MB açık) ve sıkıştırmasız saklanan 7 sprite sayfası (59 MB) idi.
- **Sprite paketi:** zstd'li `.res` (ETC2 12,8 MB / S3TC 13,5 MB). APK 156 MB → **111 MB** (yerel export, aynı içerik).
- **Yalnız arm64-v8a:** 32 bit (armeabi-v7a) kütüphanesi çıkarıldı (~21 MB sıkıştırılmış). 2017 öncesi 32 bit telefonlarda çalışmaz; bu bölümlerin bellek ihtiyacı zaten bu cihazların üstünde. Beklenen APK ≈ 90 MB.
- **Proje ikonu** eklendi (export uyarısı gitti).
- **Zemin akışı:** 0,1 sn'de en fazla 2 karo, karolar ekrandan 320 px önce istenir (kaydırmada GPU yüklemesi dağılır).
- Ölçüm (llvmpipe): sabit kamerada en yavaş kare 64,8 ms (önce 75,8), açı değişiminde en yavaş kare 91,6 ms; bölüm açılışı ~1,1 sn (paketten sprite açma +~0,3 sn; zstd), doku belleği aynı (264 / 352 MB).
- **Atlas yeniden paketleme (skyline):** `hat.py sikistir` nesne/çatı parçalarını raf yerine skyline yöntemiyle yeniden diziyor (boş saydam alan → daha az GPU belleği). Bölüm 2 nesne atlası 21,6 → 13,3 Mpx, Bölüm 3 (doğu) çatı 11,8 → 5,9 Mpx. Bölüm 3'te doku belleği en yüksek 352 → **291 MB**, açılışta 264 → 249 MB. 4 açı görüntü karşılaştırması: fark yok.
- **Bölüm 5 render'ı:** 2 açı CI makinesinde bellek yetmediği için düştü (12800x8400 piksel). `harita.py` artık render'ı kopyasız ve yarım hassasiyetle tutuyor (~3,4 GB → ~0,9 GB); `harita.yml`'a `aci` girdisi eklendi, düşen açılar ayrıca render ediliyor.

### Tur 3c – Oyuncu geri bildirimi (12 Kasım)
1. **"ALARM!" diye bağıran asker alarmı hemen verir:** Çatışmaya giren askerin üstünde "ALARM!" yazar ve alarm anında kırmızıya geçer (herkes tetikte, isabet ve refleks artar). Kışladan takviye ise hâlâ siren çalınca gelir: sirene koşanı durdurursan takviye gelmez. Önce: alarm koşucu sirene varana kadar (10–20 sn) sarı kalıyordu.
2. **Geniş alan araması:** Alarmda olay yerine 900 px içindeki en yakın 8 asker gönderilir; her biri olay yerinin 80–320 px çevresinde rastgele bir noktaya koşar, sonra arar. Arama yarıçapı sarı alarmda ×1,6, kırmızıda ×2,6; nokta sayısı 3 → 4 → 6.
3. **"Çevir" artık anında:** Bir sonraki açının atlasları arka planda önceden yükleniyor; zemin karoları beklenmiyor (önizleme görünür, karolar akışla gelir). Bölüm 3'te açı değişimi 689–820 ms → **72 ms** (tek kare). Bedeli: önceden yüklenen açı için ~85 MB doku belleği (en yüksek 291 → 379 MB).
Bot (tohum 1): Bölüm 0 saldırı tarzı artık kaybediyor (önce 0:34'te kazanıyordu), gizli tarz yine 1:02'de kazanıyor; Bölüm 2 gizli bot daha erken yakalanıyor (4:30 → 2:51).

### Tur 3d – Render kontrolü (11:40)
- **Bölüm 4** render edildi (4 açı). Atlaslar skyline ile yeniden paketlendi (nesne 19,5 → 14,6 Mpx, çatı 5,9 → 3,0 Mpx). İlk ölçüm 19,9 MB idi (bütçe 15); bu bölümün zemini için Godot kalitesi 0,62'ye indirildi (`bolum_ozel.bolum4.godot_zemin_kalite`) → **14,6 MB** ✔. 2× yakınlaştırmada zemin biraz yumuşak ama bant/hale yok (gece ambiyansında fark edilmiyor).
- 4 açı görüntüsü: `docs/ekran/tur3_bolum4_4aci.jpg`; dikenli tel, kule ve projektör ışığı: `docs/ekran/tur3_bolum4_tel_projektor.jpg` ("Tel makası gerekli" düğmesi görünür).
- **Bölüm 5:** dört açının hepsi CI'da bellek yetmediğinden düşmüştü; `harita.py` bellek düzeltmesiyle 0 ve 1–3 açıları yeniden render ediliyor.

### Tur 3e – Bölüm 5 render'ı (14:00)
- Bellek düzeltmesiyle (`harita.py`: kopyasız ters çevirme + yarım hassasiyet) Bölüm 5'in 4 açısı CI'da sorunsuz render edildi (açı başına ~1,5–2 sa).
- İlk ölçüm 16,4 MB → bölüme özel Godot kalitesi (zemin 0,55, nesne 0,66; `bolum_ozel.bolum5`) → **14,9 MB** ✔. 2× yakınlaştırmada nesnelerde hale/bant yok, zemin biraz yumuşak.
- 4 açı görüntüsü: `docs/ekran/tur3_bolum5_4aci.jpg` (şato avlusu, bahçe çitleri, tank, kamyon).
- `hat.py ayarla` artık `godot_nesne_kalite` de destekliyor.
- Son derlemede Windows zip 121,0 MB (bütçe 120) çıktı → Bölüm 3 zemini için Godot kalitesi 0,70 (`bolum_ozel.bolum3`): 21,6 → **16,1 MB**, 2× yakınlaştırmada fark yok denecek kadar az.

## Tur 4 – Gece turu (12 Kasım 2026, Perşembe: SİSTEMLER)

### 0. Oyuncu Notları
Tek gerçek istek "Kaydet / yükle (görev ortasında)" idi; gecenin ana işi oldu (✅ belgeye yazıldı). Hata bölümünde yalnız örnek satır vardı.

### 1. Ana iş: bölüm içi kayıt sistemi (`scripts/kayit.gd`)
- **5 yuva:** Hızlı kayıt, Otomatik kayıt, Yuva 1–3. Sağ üstte **Kayıt** düğmesi; PC'de **F5** hızlı kaydet, **F9** hızlı yükle, **Esc / K** panel. Ana menüde "Kayıtlı oyunu yükle".
- **Otomatik kayıt:** bölüm başında ve her görev tamamlanınca (çatışma bitince, 0,5 sn'de bir dener).
- **Ölünce devam:** sonuç ekranında "Son kayıttan devam: <yuva> (m:ss)" + "Kayıt seç…" + "Yeniden Başla".
- **Biçim:** `user://kayitlar/<yuva>.json` = JSON üst bilgi (`surum`, bölüm, ad, tarih, süre, görev x/y) + Godot `var_to_str` oyun durumu. Kaydedilen: komando (konum, can, mermi, taş, ip, silah, çömelme, kılık, taşınan ceset), her asker (bölüm dosyasındaki sırasıyla: konum, devriye noktası, ölü/baygın/bağlı, ayılma sayacı, üniforması alındı mı, ceset bulundu/saklandı, tetikte kalma), takviye askerler, yardımcı karakterler (izliyor mu), görevler, eşyalar, yerdeki eşyalar (düşen anahtarlar dahil), kesilen teller, patlama izleri, yıkılan köprüler, kışlalarda kalan asker, alarm düzeyi ve süresi, istatistikler, kamera.
- **Sürüm güvenliği:** `surum` alanı; eski sürüm `_migrate` ile yükseltilir, eksik alanlar varsayılan alır, daha yeni sürümün kaydı ve bozuk dosya nazikçe reddedilir; bölüm dosyası kayıttan sonra değiştiyse eşleşen askerler uygulanır ve uyarı çıkar. Yazma önce `.tmp` dosyasına, sonra yer değiştirme (yarım yazılan dosya eski kaydı bozmaz). Kayıt metni nesne/kaynak oluşturamaz (`Object(`, `Resource(` reddedilir).
- **Adalet kuralı (oyun mantığı):** çatışma sürerken, sirene koşan varken, takviye yoldayken ya da patlayıcı kuruluyken kaydedilemez – "kaydet, gör, geri al" hilesi ve kaydedip alarmı silme açığı yok. Gizlen → planla → kaydet → uygula döngüsü.
- **Test:** `tests/sim_kayit.gd` (CI'da `build.yml` "Kayıt sistemi testi"): durumu değiştir → kaydet → yeni sahnede yükle → 17 alan aynı mı; çatışmada kaydetme engeli; bozuk / gelecek sürüm / eski sürüm (0) dosyaları. Bölüm 0–6'nın hepsinde BAŞARILI.

### 2. Genel oynanış zekâsı, oyun mantığı, senaryo
- En zayıf alan bu gece **oyun mantığı** idi: (a) kayıt yoktu, ölüm = bölümü baştan oynamak; (b) Bölüm 4–5'te `"after": "anahtar"` tek metin olarak yazılmıştı, `mission.available` metni harf harf dolaştığı için "önce anahtar" koşulu **hiç işlemiyordu** (görevler sırasız yapılabiliyordu). `mission.setup` artık tek metni listeye çeviriyor.
- **Denge:** Tur 3'te AI v4 tespiti hedefin (+%25) üstündeydi (+%33–63). Tetikte kalan askerin fark etme hızı ×1,25 → **×1,15**, bakış açısı ×1,2 → **×1,12**.
- **Senaryo:** 2. perde başladı (Bölüm 5 "1. perde finali"); Bölüm 6 – Çelik Rampa (Temmuz 1944, Pas-de-Calais V-1 orman üssü, Gölge zorunlu çalışma kampında, SS Albay Brandt). `docs/SENARYO.md`.

### 3. İyi oyuncu bot
- Bot sakinken (alarm yok, kimse şüphelenmiyor, ceset taşımıyor) en geç 40 sn'de bir **hızlı kayıt** alır; otomatik kayıtlar da oyunda kendiliğinden. Ölünce **son kayıttan devam** eder (gizli/tam en çok 4 kez; saldırı tarzı pervasız, yüklemez). Rapor tablosunda "Yükleme" sütunu; ölüm yerleri ve yükleme süreleri JSON'da.
- Yükleme sahneyi baştan kurar (oyundaki `reload_current_scene` ile aynı yol), bot durumu sıfırlanır.

### 4. Bot önce / sonra (3 tohum, gizli tarz; önce = Tur 3 botu, kayıtsız)
| Bölüm | Önce: zafer / ort. görev | Sonra: zafer / ort. görev | Yükleme | Not |
|---|---|---|---|---|
| 0 | 3/3 · 2 | 3/3 · 2 | 0 | saldırı 2/3 → 3/3 (eğitimde pervasızlık hâlâ kazanıyor ✘) |
| 1 | 0/3 · 1,0 | 0/3 · 1,7 | 12 | "Ev 3" darboğazı + açık arazi (2500,2000–2300) |
| 2 | 0/3 · 4,0 | 0/3 · 5,7 | 12 | |
| 3 | 0/3 · 7,7 | **1/3 · 8,7** (7:05) | 9 | Tur 2'den beri ilk gizli zafer |
| 4 | 0/3 · 4,0 | 0/3 · 4,0 | 12 | açık arazi (1700,2400–2500) |
| 5 | 0/3 · 3,0 | 0/3 · 2,7 | 12 | açık arazi (4900–5100,600) |
| 6 (yeni) | – | 0/3 · 3,0 | 12 | açık arazi (1500–1700,1800–1900) |
Saldırı tarzı Bölüm 1–6'da 0/3 (pervasızlık cezalandırılıyor ✔). Tespit sayıları artık yüklemeler boyunca toplandığından önceki turla karşılaştırılamaz.

### 5. Ölçümler
- Kayıt dosyası ~25 KB (Bölüm 3, 56 asker), **kaydetme 2 ms**.
- Kayıt yükleme (llvmpipe, xvfb): Bölüm 3 **303 ms** (sahne kurulumu + uygulama + ilk kare; normal bölüm açılışı 778 ms), sonrasındaki 60 karede en yavaş kare 44–91 ms (zemin karoları akışla geliyor). Bot (headless): 43–74 ms; Bölüm 4 kesilen teller için navigasyon tek seferde: **640 → 190 ms**.
- `tests/perf.gd` Bölüm 3: ortalama kare 37,1 ms, en yavaş 53,3 ms; açı değişimi 71 ms; doku belleği 310 / 379 MB (Tur 3 ile aynı).
- Testler: sim, sim1–4, sim_bolum (0–6, "merge edge" yok; Bölüm 0–1'de "yeterli asker" eşiği eski bölümler için önceden de başarısız), sim_kayit (0–6) geçti.
- Ekran: `docs/ekran/tur4_kayit.jpg` (panel, ölüm ekranı, oyun), `docs/ekran/tur4_bolum3_4aci.jpg` (4 açı).

- **CI (Derle, e4d32dc):** APK 108,8 MB ✔ · Windows zip 115,5 MB ✔ · Linux zip 109,7 MB ✔ · Web .pck 88,5 MB ✔. Gece sürümü: `gece-2026-11-12` etiketi (APK + 2 zip); `son-surum` güncel. Bölüm 3 haritası 16,1 MB (bütçe 15; eski bölüm, uyarı sürüyor).
- **Risk:** Bölüm 6 render'ı (~15 MB) gelince Windows zip ~130 MB olur (bütçe 120). Render bitince Bölüm 6 / Bölüm 3 kalitesi düşürülmeli ya da PC paketinde açı başına zemin önizlemesi paylaşılmalı.

### 6. Sonraki tur
0. Bölüm 6 render'ı sonrası PC zip bütçesi (yukarıdaki risk).
1. Gizli bot Bölüm 1, 2, 4, 5, 6'yı kazanamıyor: ölüm noktalarına ikinci yol / çalı / siper; bot için taşla dikkat dağıtma ve üniforma.
2. Zorluk seviyesi (Er/Çavuş/Komando) + ayarlar ekranı (Sistemler gecesi devamı).
3. Bölüm 0 saldırı tarzı kazanıyor.

### Kaynaklar
- Godot 4.3 `var_to_str` / `str_to_var`, `FileAccess`, `DirAccess.rename_absolute`: https://docs.godotengine.org/en/4.3/classes/class_%40globalscope.html · https://docs.godotengine.org/en/4.3/tutorials/io/saving_games.html
- Önce geçici dosyaya yazıp yer değiştirme: https://docs.godotengine.org/en/4.3/classes/class_diraccess.html
- Commandos 2 (bölüm içi hızlı kayıt) tasarım referansı: https://commandos.shoutwiki.com/wiki/Commandos_2

## Tur 5 – Gece turu (13 Kasım 2026, Cuma: OYNANIŞ DERİNLİĞİ)

### 0. Oyuncu Notları
Yeni not yoktu (Hatalar/Zorluk bölümlerindeki satırlar örnek). Kullanıcının 12 Kasım 22:05 öncelikli istekleri yapıldı (aşağıda 1–3).

### 1. Web kaldırıldı
- `build.yml`: Web derlemesi, gh-pages yayını, Pages paketi ve `pages` işi silindi; iş akışı adı "Derle (Android + Windows + Linux)". PC derlemesi artık `continue-on-error` değil (PC ana sürüm).
- `export_presets.cfg`: Web preset'i silindi (Android = 0, Windows = 1, Linux = 2). `varlik_ayarlari.json`: Web filtresi ve `web_pck` bütçesi silindi, **PC zip bütçesi 120 → 300 MB**. `hat.py butce` Web satırı yok. Web'e özel yorumlar temizlendi.
- README'den `github.io` linki çıkarıldı. **Not:** `gh-pages` dalını silmek oturum izinleri tarafından engellendi; eski web derlemesi depo ayarlarında Pages kapatılana kadar yayında kalabilir.

### 2. "Çevir" beklemesiz (açılar bellekte)
- `level.gd` açı önbelleği: her açı kendi sprite kümesi (`_views[k]`), geçiş = görünürlük değiştirme (sert kesme, aynı kare). `request_view` artık hiç beklemez; `view_loading` hep -1, "Çevriliyor…" hiç gösterilmez (`main.rotate_view`).
- **PC** (`OS.has_feature("pc")`): 4 açının atlasları yükleme ekranında paralel iş parçacıklarıyla istenir, sprite'lar kurulur. **Telefon:** bulunulan + iki komşu açı kurulu; karşı açıya art arda iki basışta hemen geçilir, zemin önizlemesi (`ground_mini`, 4 açının ortak düşük çözünürlüklü yer tutucusu) görünür, atlas sayfaları **sırayla** yüklenir (her GPU yüklemesi ayrı kareye düşsün), sprite'lar kare başına 160 (bakılan) / 48 (komşu) kurulur. Bırakılan açının sprite'ları kare başına 64 silinir; yüklenmekte olan dokular ana iş parçacığını bekletmeden toplanır.
- Komşu açıların zemin karoları da kamera çevresinde akar (yalnız ekran alanı, 0,1 sn'de en çok 1 karo): çevrilince ilk kare dolu.
- Testler: **`tests/sim_aci.gd`** (CI'da her derlemede, PC ve telefon kipi): ileri, geri, aynı karede iki geri, art arda üçüncü, iki adım; her basışta aynı karede geçiş, "Çevriliyor…" yok, yalnız bakılan açının sprite'ları görünür, çatılar doğru açıya bağlı, bellekteki açılar doğru. **`tests/perf.gd`**: 10 basışlık dizi (art arda, ters yön, aynı karede), `KIP=pc|mobil`.

| Bölüm 5, llvmpipe (yazılım GPU, xvfb) | Önce (Tur 4) | PC kipi | Telefon kipi |
|---|---|---|---|
| Normal oynanış en yavaş kare | 50,5 ms | 55–61 ms | 56–70 ms |
| Çevir: bekleme | 72 ms ("Çevriliyor…") | **0 (aynı kare)** | **0 (aynı kare)** |
| Basıştan sonraki en yavaş kare | 71,9 ms | **44,6–60 ms** (normal kare düzeyi) | 95–99 ms (bellekte olmayan açıya hızlı basışta atlas yüklemesi) |
| Bölüm açılışı | 1059 ms | 1440–1570 ms (+4 açı) | 1320 ms |
| Doku belleği (en yüksek) | 359 MB | 784 MB | 556–620 MB |
| Kayıt yükleme | 385 ms | 190 ms | 157–169 ms |

Not: bu makinede GPU yok (llvmpipe her doku yüklemesini işlemciyle yapar, normal kare zaten ~38 ms). 33 ms hedefi telefonda gerçek cihazda ölçülmeli; PC kipinde çevirme normal kareden yavaş değil.

### 3. Kılık / üniforma sistemi kaldırıldı
- Silindi: `commando.disguise`, `put_on_uniform`, `blow_disguise`, `_set_outfit`, "Üniforma Giy" düğmesi (`main.gd`), `guard.gd`'de üniformalı komandoyu tanıma ve 0,6 şüphe çarpanı, `guard.stripped`, `stats.disguises`, bot istatistiği, Yenilikler ve README satırları.
- Kayıt: biçim sürümü aynı; eski kayıtlardaki `komando.disguise` ve `askerler[].stripped` alanları sessizce yok sayılır. `sim_kayit.gd` eski "disguise" alanlı kaydı yükleyip oyunun kurulduğunu doğrular.
- **Bölüm 6 kılıksız** (`tools/gen_bolum6.py`): kampın kuzey duvarında gözaltı bunkerinin arkasında **yıkık drenaj kanalı** (ormandan çalı şeridi + kanal ağzında çalı), kulübe önünde **taş yığını** (+3) ve başlangıç taşı 6 → 8, kapı nöbetçilerini taşla çevirme ipucu, devriye **zamanlaması** (kamp içi devriye bunker önünden düzenli geçer). Brifing ve Jeanne'nin diyalogları kılıksız. `SENARYO.md`'de Gölge artık "hırsız/izci" (kilit, yol, dikkat dağıtma); kalıcı kural yazıldı.

### 4. Tema (Oynanış derinliği): taş yığını
Yeni etkileşim: haritada **taş yığını** (`pickups` `type: "stones"`), üstünden geçince taş toplanır, büyük haritada gri nokta. Kılıksız gizliliğin ana aracı olan dikkat dağıtmayı haritaya bağlar (Bölüm 6 ve 7'de darboğaz önlerinde).

### 5. Genel oynanış zekâsı / bot
- **Bot ölümden ders alır:** öldüğü yerin 170 px çevresi ve yakalandığı noktalar rota maliyetine eklenir; kayıttan dönünce aynı tuzağa yürümez, başka yol dener.
- **Eski kayda dönme:** aynı yerde (250 px) üst üste ölünce bir önceki, daha eski kayda döner (oyuncunun "Kayıt seç…" kullanması gibi); hızlı kayda ek olarak 75 sn'de bir elle yuvalara (1 → 2 → 3) kaydeder.
- Bölüm 6 (gizli, 3 tohum): Tur 4 = 3 görev (temas, santral, anahtar), değişiklikler sonrası eski bot = 2 görev (hızlı kayıt kamp ortasındaki takviye tuzağına düşmüştü: 4 yüklemenin hepsi aynı yerde öldü), yeni bot = **4 görev (+ Gölge kurtarıldı)**, 3 tohumun 3'ünde.

### 6. Yeni bölüm: Bölüm 7 – Sisli Ada
`tools/gen_bolum7.py` → `levels/bolum7.json`: 6400x4200 Baltık roket deneme adası (2. perde), 88 asker, 9 kule, **7 projektör**, 5 kapılı dikenli telli deneme sahası, duvarlı kamp, kanal (demiryolu köprüsü, yol köprüsü, sazlık sığlık), kuzeyde deniz. Görevler: Jan Nowak (Polonyalı kaçak işçi) → trafo sabotajı → laboratuvar anahtarı (saha subayı) → A-4 çizimleri → roket + sıvı oksijen tesisi → (isteğe bağlı) ölçüm bunkeri → Kowalski'nin motorbotu. Kılıksız gizli yollar: kamış şeritleri, kumul çalıları, iki taş yığını. Zemin 0,75 ölçek + kalite 0,55 (bütçe ≤ 15 MB). `sim_bolum` geçti (devriye/siren erişimi düzeltildi). Harita CI'da render ediliyor; o zamana kadar düz zemin (yeni bölümde sahte `objects.png` arama hatası da düzeltildi).

### 7. Bot önce / sonra (gizli tarz, 3 tohum; önce = Tur 4 raporu)
| Bölüm | Zafer önce → sonra | Ort. tespit | Ort. biten görev |
|---|---|---|---|
| 0 | 3/3 → 3/3 | 0 → 0 | 2,0 → 2,0 |
| 1 | 0/3 → 0/3 | 54 → 74 | 1,7 → 1,7 |
| 2 | 0/3 → 0/3 | 46 → 36 | 5,7 → 4,0 |
| 3 | 1/3 → 0/3 | 30 → 44 | 8,7 → 7,7 |
| 4 | 0/3 → **1/3** (8:20, Bölüm 4'te ilk zafer) | 39 → 39 | 4,0 → 5,3 |
| 5 | 0/3 → 0/3 | 69 → 68 | 2,7 → 2,7 |
| 6 | 0/3 → 0/3 | 60 → 46 | 3,0 → **4,0** |
| 7 (yeni) | – → 0/3 | 58 | 2,0 |

Toplam (0–6): zafer 4 → 4, biten görev 27,8 → 27,4 (aynı düzey). Açıklama: kılık kaldırılması botu etkilemedi (bot kılık kullanmıyordu; değişiklik öncesi ara koşuda Bölüm 0–5 birebir aynı çıktı). Farklar botun yeni kayıt/ölüm davranışından: ilk ölümden sonra rota değişiyor; Bölüm 4 ve 6'da işe yaradı, Bölüm 3 tohum 2'de (eskiden 1 yüklemeyle kazanıyordu) yeni rota bunkerde öldü, Bölüm 2'de "açık arazi (3400,1000)" tuzağı sürüyor. Saldırı tarzı her yerde (Bölüm 0 hariç) 1 dakikada ölüyor: pervasızlık cezalandırılıyor.

### 8. Ölçümler ve kalite kapısı
- Testler: sim, sim1–4, sim_kayit (2, 3, 6, 7), **sim_aci** (PC + telefon), sim_bolum 2–7 geçti; "merge edge" yok. sim_bolum 0–1 "yeterli asker" eşiği eski bölümler için önceden de başarısız (değişmedi).
- CI (Derle, e4947d2): **APK 120,6 MB** ✔ (200) · **Windows zip 127,1 MB** ✔ (300) · **Linux zip 121,4 MB** ✔ (300). Bölüm 6: 11,6 MB (v1 eksik), Bölüm 3: 16,1 MB (eski bölüm, telefonda 15 MB bütçesinin 1,1 MB üstünde). Bölüm 6 v1 + Bölüm 7 render'ı gelince ~+18 MB beklenir (APK ~139, Windows ~145).
- Gece sürümü: `gece-2026-11-13` (APK + 2 zip), `son-surum` güncel.
- Ekran: Bölüm 5'te 4 açı (PC kipi, sert kesme) kontrol edildi; Bölüm 7 düz zeminle açılıyor.

### 9. Sonraki tur
1. Bölüm 6 v1 ve Bölüm 7 render'larını kontrol et (Bölüm 6 v1 Tur 4'te iptal olmuştu).
2. Bot: anahtar taşıyan subaya arkadan yaklaşma; Bölüm 2 (3400,1000) ve Bölüm 3 bunker ölüm noktaları.
3. Telefonda açı geçişi kasması gerçek cihazda ölçülmeli; gerekirse komşu açı atlasları ETC2.
4. PC'ye özel yüksek kaliteli harita dokuları (300 MB bütçe içinde).

### Kaynaklar
- Godot 4.3 `ResourceLoader.load_threaded_request` / `load_threaded_get_status`: https://docs.godotengine.org/en/4.3/classes/class_resourceloader.html
- Godot özellik etiketleri (`pc`, `mobile`): https://docs.godotengine.org/en/4.3/tutorials/export/feature_tags.html
- Commandos 2'de 4 yönlü kamera (anında dönüş) referansı: https://commandos.shoutwiki.com/wiki/Commandos_2
- Peenemünde ve Polonya direnişinin V-2 istihbaratı (Bölüm 7 arka planı): https://en.wikipedia.org/wiki/Peenem%C3%BCnde_Army_Research_Center · https://en.wikipedia.org/wiki/Home_Army_and_V-1_and_V-2

## Tur 6 – Gündüz turu (13 Kasım 2026, Cuma: OYNANIŞ DERİNLİĞİ – pencereler, takip, yakından fark etme)

Kullanıcının 13 Kasım 10:38–10:43 öncelikli istekleri (4 ve 5) bu turun ana işi; Cuma teması (oynanış derinliği: pencere etkileşimi) ile örtüşüyor. Öncelikli 1–3 (web, açılar, kılık) Tur 5'te bitmişti ve korunuyor (testler geçti). **Yeni bölüm bu tur yok** (öncelikli işler uzun sürdü; Bölüm 8 bir sonraki tura).

### 0. Oyuncu Notları
Yeni hata/istek yok (Hatalar ve Zorluk bölümündeki satırlar örnek). İstekler görev metninden geldi.

### 1. Pencereden giriş / çıkış (her bölüm, her bina)
- **Yerleşim render ile aynı:** `tools/blender/harita.py` her duvar parçasına `n = int((L − 20) / 64)` pencere koyuyordu. Aynı formül `Level.window_spots()` (duvarlar `Level.wall_rects()`, `harita.py building_walls` ile aynı sıra/ölçü). Böylece haritaları yeniden render etmeden pencereler dış sanattaki yerinde; iç haritadaki karşılığı ölçekle (`ISCALE`) hesaplanır, iç duvarda ışık lekesi + çerçeve olarak çizilir, mobilya pencere önüne konmaz, ara duvara denk gelen kaydırılır.
- Önü kapalı pencere (duvardan 24 px dışarıdaki nokta engelde, başka binada, harita dışında ya da kapının dibinde) oyunda kullanılmaz. Sonuç: Bölüm 0–7'de **745 pencere**, her binada en az bir tane, hepsi dışarıdan ve içeriden erişilebilir (`sim_bolum.gd`).
- Kullanım: pencereye (ya da duvardaki yerine) dokun → komando önüne yürür ve tırmanır; yanındayken eylem düğmesi "Pencereden Gir: <bina>" / içeride "Pencereden Çık" + "Pencereden Bak". Çift dokunuşla koşarak gider.
- **Kapıdan yavaş:** 1,1 sn (iki yarı: tutun-tırman / diğer tarafa in). Kapı anında. Tırmanırken komando çömelip kalkar (plant animasyonu) ve gövdesi 14 px yükselip iner; kısa **tırmanma ve iniş sesi** (`scripts/ses.gd`, kodla sentezlenen ses: lisans sorunu yok). Ses yalnız 55 px içindeki askerin dikkatini çeker (alarm seviyesini değiştirmez). Cesetle pencereden geçilmez. Tırmanırken ya da peşinde asker varken kaydedilemez.
- **Belli olsun:** komando yakındayken pencerelerin önünde mavi çerçeve işareti; dokununca yanıp sönen halka + "pencere"/"kilitli" (`scripts/win_marks.gd`, çatıların üstünde çizilir, 4 açıda da görünür). Büyük haritada her pencere mavi çizgi (kilitliyse turuncu).
- Yeni bölümler: pencereler otomatik (`bolum_lib.py` notu, `SENARYO.md` kalıcı kural).

### 2. Kilitli binalar
Kilitli binanın pencereleri de kilitli: "Pencereler de kilitli: <anahtar> gerekli". Kilit tek yerde (`main.is_locked`): anahtar alınınca kapı ve pencereler birlikte açılır. Asker tarafında: takip/arama sırasında kilitli binaya yalnız anahtarı taşıyan asker girer (`guard._door_hop`, devriye düzeni bozulmasın diye devriye hariç).

### 3. Kapı deliğinden gerçekçi bakış
`scripts/peek_mask.gd`: kapının (pencerenin) önünden dışarı **~40° (±0,35 rad) koni, 520 px menzil**, 48 ışın `Level.ray_end` ile (= `has_los`): duvar/ağaç/engel görüşü keser. Koninin dışı ve engelin arkası %96 karanlık (koninin dışı tek çokgen + her ışın aralığında engelin arkası dörtgen; delikli çokgen gerekmez). Konideki askerler canlı hareket eder; anahtar deliği çerçevesi (`hud.KEYHOLE`) korunur; bakarken kamera sürüklenemez. İçeride pencere yanında "Pencereden Bak" aynı kuralla. Düğme: "Bakmayı Bırak".

### 4. Peşinden girme
`main._notify_entry` (kapı ve pencere girişlerinde): **çatışmadaki** asker komandoyu görüyorsa (menzil × 1,25 + `has_los`) ya da **fark etmiş** asker (şüphe ≥ 0,3 veya araştırma/aramada ve tetikte) komandoyu konisinde görüyorsa `pursue_into`: aynı açıklığa koşar, pencereyse 1,25 sn tırmanır (kapı 0,25 sn), içeri girer ve görürse çatışır, görmezse içeride arar (arama noktaları iç haritaya sıkıştırılır). En çok 4 asker birlikte. Görmeyen girmez: son gördüğü yerde (dışarıda) arar. Takipteki asker sirene koşucu seçilmez.

### 5. Koni dışında yakından fark etme
Eski 46 px "çevresel algı" kaldırıldı. `guard.near_sense()` — [yarıçap, koni hızına oran]:

| Duruş | Yarıçap | Hız (koni = 1) |
|---|---|---|
| Koşarken (ayak sesi) | 185 px | 0,40 |
| Ayakta yürürken | 112 px | 0,30 |
| Ayakta dururken | 45 px | 0,12 |
| Çömelik yürürken | 52 px | 0,10 |
| Çömelik dururken | – | fark etmez |

Yaklaştıkça hızlanır (`0,35 + 1,3 × yakınlık`), alarm yarıçapı ×1,2 / ×1,4 ve kırmızıda hızı ×1,25 artırır, tetikteki asker ×1,1. Duvar/bina arkasından olmaz (`has_los`); çalı kuralı: çalı görüşü keserse yalnız yarıçapın yarısında. Önce yalnız "?" belirir ve asker yoluna devam eder; şüphe 0,3'ü geçince durur, sana döner (sprite yönü ve koni 0,06 sn'de bir güncellenir), sonra normal görüş kuralları. **Arkadan bıçaklama korunuyor:** çömelip arkadan yaklaşan 52 px'e girdiğinde bıçak menziline (30 px) ~0,35 sn kalır, şüphe ~0,05 artar.

### 6. Testler
- **`tests/sim_pencere.gd`** (her bölümde geçti, 0–7): pencereden gir (0,3 sn'de hâlâ dışarıda → kapıdan yavaş), çık, kilitli binanın penceresi, anahtarla kapı+pencere açılması; kapı deliği: önü görünür, yanı/45° yanı/uzağı/binanın içi/engelin arkası karanlık; **gördü → girdi** (iki asker pencereden peşinden girip içeride arıyor), **görmedi → girmedi** (binanın arkasındaki asker dışarıda arıyor); yakından fark etme (yürüme 90 px evet / 150 px hayır, koşma 175 px, çömelik çok yavaş, çömelik duran hiç, yaklaştıkça hızlanır, kırmızı alarmda 140 px, duvar arkası hayır); **çömelerek arkadan bıçaklama alarmsız** ve ayakta yaklaşanı "?" ile fark edip dönme.
- `sim_bolum.gd`: pencereler geçerli + her binada dışarıdan ulaşılabilir pencere. Bölüm 0–1'in eski "yeterli asker ≥ 30" eşiği eğitim/ilk bölüm için 5'e indirildi (bilinen başarısızlık kapandı).
- sim, sim1–4, sim_kayit (2, 6, 7), sim_aci (PC + telefon), sim_bolum 0–7: hepsi geçti; "merge edge" yok.
- Ekran: `tests/shot_pencere.gd` (xvfb): Bölüm 1'de pencere işareti 4 açıda, pencereden girince iç harita (ışık lekeleri), kapı deliğinden dar koni (ağaç görüşü kesiyor, konideki asker görünüyor).

### 7. Bot (iyi oyuncu) ve denge
- Bot pencereleri alternatif giriş olarak kullanır (`_pick_opening`): kapı ve kilitsiz pencereler arasında yol uzunluğu + tehlike haritası + "bakan asker var mı" ile seçer; pencereye +140 (yavaş/sesli), önünde/içinde 200–260 px'te asker varsa +600.
- Bot yakından fark edilmeyi anlar: koni dışından sezen asker ("?") da "izleyen" sayılır; geri çekilirken artık hep koşmuyor (koşmak 185 px'ten duyulur): yalnız konide şüphe > 0,6 ise koşar, yoksa çömelerek çekilir.
- Önce (Tur 5 raporu) → sonra (gizli, 3 tohum; ilk değerlerle tam koşu, `docs/BOT_RAPORU.md`):

| Bölüm | Tarz | Zafer | Ort. tespit | Ort. biten görev | Pencere | Takip |
|---|---|---|---|---|---|---|
| 0 | gizli | 3/3 → 3/3 | 0 → 0 | 2,0 → 2,0 | 6 | 0 |
| 1 | gizli | 0/3 → 0/3 | 74 → 70 | 1,7 → 2,0 | 4 | 0 |
| 2 | gizli | 0/3 → 0/3 | 36 → 48 | 4,0 → **5,3** | 17 | 0 |
| 3 | gizli | 0/3 → 0/3 | 44 → 46 | 7,7 → **8,0** | 24 | 0 |
| 4 | gizli | 1/3 → 0/3 | 39 → 55 | 5,3 → 4,3 | 36 | 0 |
| 5 | gizli | 0/3 → 0/3 | 68 → 63 | 2,7 → 2,7 | 6 | 0 |
| 6 | gizli | 0/3 → 0/3 | 46 → 45 | 4,0 → 4,0 | 15 | 0 |
| 7 | gizli | 0/3 → 0/3 | 58 → 65 | 2,0 → 2,7 | 3 | 0 |
| 2–5 | saldırı | 0/12 → 0/12 | | | 0 | 11 (askerler peşinden girdi) |

Toplam (gizli): zafer 4 → 3, biten görev 29,3 → **31,0**. Açıklama: yakından fark etme oyunu bilerek zorlaştırıyor (kullanıcı isteği). Bölüm 4'teki tek zafer (tohum 2) kayboldu; deneyle ayrıştırıldı (yalnız pencere kapalı: 6 görev; yalnız yakından fark etme kapalı: 6 görev; ikisi açık ilk değerler: 4 görev). Bunun üzerine değerler önerilen aralığın alt ucuna çekildi (yukarıdaki tablo) → aynı tohum **7 görev**. Bot ilk versiyonunda pencereleri gelişigüzel kullanıyordu (Bölüm 3: 7,7 → 3,7 görev); asker-yakınlığı cezası ve çömelerek geri çekilme ile 8,0'a çıktı. Saldırı tarzı her yerde (Bölüm 0 hariç) kaybediyor: pervasızlık cezalandırılıyor; takip sistemi saldırı oyunlarında 11 kez devreye girdi.

### 8. Ölçümler (llvmpipe, xvfb, GPU yok – Bölüm 5, 76 asker)
| | PC kipi | Telefon kipi |
|---|---|---|
| Ortalama kare | 35–38 ms (Tur 5 kodu aynı makinede 34–35) | 36 ms |
| En yavaş kare (normal) | 53–61 ms | 56 ms |
| Çevir: geçiş | aynı karede, "Çevriliyor…" yok | aynı karede |
| Basıştan sonraki en yavaş kare | 107–268 ms (Tur 5 kodu aynı makinede 94–97 ms; eski guard.gd ile 107 ms → fark gürültü düzeyinde) | 105 ms |
| Bölüm açılışı | 1856 ms | 1423 ms |
| Doku belleği en yüksek | 635 MB | 534 MB |
| Kayıt yükleme | 385 ms | 293 ms |

Not: bu makinede her kare işlemciyle çiziliyor (llvmpipe); 33 ms hedefi gerçek telefonda ölçülmeli. Pencere/koni/yakından fark etme ek yükü ölçüm gürültüsünün içinde (pencere çizimleri kapatılınca da 36 ms). Kapı deliği maskesi 0,5 sn'de bir 48 ışın.

### 9. Sorunlar / sonraki tur
1. **Bölüm 7 v3 açısı yok** (render tamamlanmamış): `harita.yml` ile `bolum7` `[3]` yeniden render edilmeli.
2. Bölüm 8 (Brandt'ın Alp treni) bir sonraki tura kaldı.
3. Bot: gizli bot hâlâ Bölüm 1–7'yi kazanamıyor. Sıradaki: taşla dikkat dağıtma kullanımı, anahtar taşıyan subaya arkadan yaklaşma, "Ev 3 yakını" / "Kontrol odası yakını" / "Depo ofisi yakını" tespit noktaları.
4. Görsel: pencereden tırmanma için gerçek animasyon (Quaternius UAL'da tırmanma klibi var mı bakılacak), başını çevirip bakma.

### Kaynaklar
- Commandos 2 pencereler ve anahtar deliği: https://commandos.fandom.com/wiki/Commandos_2:_Men_of_Courage
- Shadow Tactics / Desperados III yakın algı ("hearing range", çömelik yürüyüş) tasarım notları: https://www.gamedeveloper.com/design/the-stealth-design-of-shadow-tactics-blades-of-the-shogun
- Godot 4.3 `AudioStreamWAV` (kodla ses üretimi): https://docs.godotengine.org/en/4.3/classes/class_audiostreamwav.html
