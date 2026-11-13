# Yol Haritası

İlke: her gece daha fazla değil, **daha iyi**. Öncelik sırası: Oyuncu Notları → kalite kapısı → haftalık tema → kalıcı odaklar → 1 yeni bölüm.
Son güncelleme: Tur 5 (13 Kasım 2026, Cuma – Oynanış derinliği).

## Kalıcı kurallar (12 Kasım 22:05 kararı)
- **Platformlar:** PC (Windows + Linux) en kaliteli sürüm (zip ≤ 300 MB); Android APK ikinci sürüm (≤ 200 MB, ana bölüm başına ≤ 15 MB, bonus ≤ 5 MB). **Web yok** – web için test, optimizasyon, iş yapılmaz.
- **"Çevir" beklemesiz:** her basışta tek karede, sert kesmeyle; "Çevriliyor…" yok. PC'de 4 açı bellekte; telefonda bulunulan + iki komşu açı + ortak düşük çözünürlüklü önizleme. `tests/sim_aci.gd` CI'da her derlemede.
- **Kılık / üniforma yok** (gelecekte de eklenmeyecek). Gizlilik: çalı/kamış, gölge, zamanlama, dikkat dağıtma (taş, ıslık), alternatif yollar.

## Kampanya durumu
| Bölüm | Durum |
|---|---|
| 0–5 | oynanabilir, 4 açı render'ı var |
| 6 – Çelik Rampa | Tur 5'te kılıksız yeniden düzenlendi (drenaj kanalı, taş yığını); v1 açısı Tur 4 CI'da zaman aşımına uğradı, Tur 5'te yeniden render ediliyor |
| 7 – Sisli Ada | Tur 5'te eklendi; harita CI'da render ediliyor (bitene kadar düz zemin) |
| 8–11 | sırayla, gecede 1 bölüm (8: Brandt'ın Alp treni) |
| Bonus görevler | 12 bölüm dolunca, gecede 1 |

## Öncelikler (bot ve oyuncu notlarından)
1. **Denge – gizli bot Bölüm 1, 2, 4–7'yi kazanamıyor.** Tur 5: bot artık öldüğü/yakalandığı yeri "tehlikeli" sayıyor ve aynı yerde üst üste ölünce daha eski kayda dönüyor (Bölüm 6: 3 → 4 görev). Sıradaki: anahtar taşıyan subaya arkadan yaklaşma (Bölüm 6 kamp komutanı, (1900,1950) tespit noktası), Bölüm 1 "Ev 3 yakını" için ikinci yol, bot için taşla dikkat dağıtma.
2. **Telefon kasması (açı çevirme):** llvmpipe'ta bellekte olmayan açıya geçişte atlas yüklemesi en yavaş kareyi ~95 ms'ye çıkarıyor (normal en yavaş ~55 ms). Gerçek telefonda ölçülmeli; gerekirse atlas sayfaları küçültülmeli (4096 → 2048 parçalar) ya da komşu açı atlasları VRAM sıkıştırmalı (ETC2) tutulmalı. Telefonda 3 açı ≈ +75 MB doku belleği.
3. **Bölüm 0 saldırı tarzı kazanıyor** (eğitim; 6 asker). Belgeyi kilitli dolaba koy ya da ilk takviyeyi erkene al.
4. **Bölüm 6 v1 render'ı** Tur 4'te 2,5 saatte iptal oldu; Tur 5 render'ı da kontrol edilmeli (gerekirse v1 için örnek sayısı 24 → 16).
5. **Kayıt sistemi v2:** kayıt anında küçük harita görüntüsü, yuva silme, ayarlardan otomatik kayıt sıklığı.
6. **Sistemler:** zorluk seviyesi (Er / Çavuş / Komando), ayarlar ekranı (PC çözünürlük/pencere/doku kalitesi, ses), eğitim ipuçları.
7. **PC kalite:** PC zip bütçesi 300 MB oldu (şu an ~120 MB): PC'ye özel daha yüksek kaliteli harita dokuları (ayrı import / paket) düşünülmeli.
8. **Görsel/animasyon:** çömelik yürüme, ceset taşıma, bıçak varyasyonları, vurulma.
9. **Ses (Çarşamba):** ayak sesleri, siren, Almanca bağırışlar (CC0).

## Bitenler
- Tur 5: web kaldırıldı (CI, preset, Pages, belgeler); açılar bellekte + beklemesiz "Çevir" (PC 4, telefon 3 + önizleme, `sim_aci.gd`, `perf.gd` art arda/ters/aynı kare basışları); kılık/üniforma sistemi kaldırıldı (eski kayıtlar sessizce açılır); Bölüm 6 kılıksız yeniden düzenlendi; taş yığını; bot: ölüm yerinden ders + eski kayda dönme + yuva sırası; Bölüm 7 – Sisli Ada.
- Tur 4: bölüm içi kayıt (5 yuva, sürümlü biçim, ölünce devam), bot kaydet/yükle, Yenilikler ekranı, Bölüm 6, "after" koşul hatası (Bölüm 4–5).
- Tur 3: AI v4, yumruk/ıslık/tel/projektör, Bölüm 4–5, boyut bütçesi (APK ~90 MB).
- Tur 1–2: temel oyun, Bölüm 0–3, bot raporu.
