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

---

## Varlık ve boyut bütçesi

Varlık hattı tek yerde ve belgeli (kod: `tools/varlik/hat.py`, ayarlar: `tools/varlik_ayarlari.json`):

1. **Render** – `tools/blender/harita.py <bölüm>.json --view K` → `levels/<bölüm>_art/vK/` (v0..v3 hep aynı düzen; kayıpsız PNG karolar ve atlaslar + `manifest.json`).
2. **Sıkıştırma** – `python3 tools/varlik/hat.py sikistir levels/<bölüm>_art/vK` → zemin 1024 px WebP karolar (bölüme özel çözünürlük ölçeği), nesne/çatı atlasları saydamlığı koruyan kayıplı WebP (sağ/alt boş alan kırpılır), v0 için 2048 px zemin önizlemesi (`ground_mini.webp`: mini harita, büyük harita, açı yüklenirken yer tutucu).
3. **Godot import** – `hat.py ayarla` ayarlardan `project.godot [importer_defaults]` ve `.import` dosyalarını yazar: harita = Lossy WebP (kalite 0,82, mipmap yok); karakter sprite'ları = VRAM (ETC2/S3TC; her an ekranda olduklarından telefonda 4 kat az bellek).
4. **Sprite paketi** – `godot -s res://tools/varlik/sprite_paketle.gd` (CI'da import'tan sonra): karakter sprite'ları platform biçimine (ETC2 telefon, S3TC PC/Web) sıkıştırılıp zstd'li `.res` olarak paketlenir. Godot APK'da `.ctex` dosyalarını sıkıştırmadan saklıyordu (sayfa başına 8,4 MB); paket 1,8 MB. Bellekte yine VRAM biçimi.
5. **Export** – `export_presets.cfg`: `tests/ tools/ docs/ kaynak/ *.glb *.md` hariç; her platform yalnız kendi sprite biçimini alır (`export_haric_platform`); Android yalnız ETC2/ASTC ve yalnız arm64-v8a, PC yalnız S3TC, Web yalnız masaüstü biçimi; Android release şablonu; proje ikonu.
6. **Bütçe** – `hat.py butce` her derlemede bölüm × açı MB'ını ve APK/zip boyutlarını yazar (Actions özeti + sürüm notu); bütçe aşılırsa `::warning::`.

Hedefler: **APK ≤ 200 MB**, **PC zip ≤ 120 MB**, **yeni bölüm ≤ 15 MB** (4 açı toplamı), Web .pck ≤ 150 MB.

| Bölüm | v0 | v1 | v2 | v3 | Toplam MB (Godot .ctex) |
|---|---|---|---|---|---|
| bolum0 | 0,8 | 0,6 | 0,7 | 0,7 | 2,8 |
| bolum1 | 3,3 | 3,0 | 3,1 | 3,1 | 12,5 |
| bolum2 | 3,0 | 2,9 | 3,0 | 2,8 | 11,7 |
| bolum3 | 5,5 | 5,2 | 5,4 | 5,4 | 21,6 (zemin 3,9 MB/açı; eski bölüm, bütçe öncesi) |
| bolum4, bolum5 | | | | | render sonrası CI'da ölçülür (zemin ölçeği 0,75) |
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
