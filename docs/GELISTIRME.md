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
- Android APK, Web (GitHub Pages), **Windows** ve **Linux** sürümleri. Hepsi GitHub Release'te.

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
