# Bot oyun testi raporu

> Tur 6 notu: bu koşu pencereler + peşinden girme + koni dışı yakından fark etme (ilk değerler: yürüme 120 px, koşma 200 px, çömelik 55 px) ile alındı. "tam" tarzı bu gece çalıştırılmadı (gizli ile aynı karar ağacı, süre). Koşudan sonra yakından fark etme değerleri önerilen aralığın alt ucuna çekildi (110 / 185 / 50 px, hız ×0,9): Bölüm 4 tohum 2 4 → 7 görev. Önce/sonra karşılaştırması: `docs/GELISTIRME.md` → Tur 6.

Tarih: 2026-11-13 09:45 — 48 oyun (gizli, saldiri × 3 tohum).
Bot `tests/bot.gd`: gizli = çömel, devriye bakıyorsa bekle, şüphelenirse geri çekil, arkadan bıçakla; saldırı = tabancayla temizle; tam = gizli + isteğe bağlı görevler. Gizli/tam sakinken kaydeder, ölünce son kayıttan devam eder (en çok 4 kez, Tur 4); saldırı tarzı yüklemez.

## bolum0

| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Ceset sakl./bulundu | Taş | Takılma | Yükleme | Pencere/Takip | Puan | Biten görevler |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gizli | 1 | zafer | 0:59 | 0 | 0 | 0/2 | 0 | 0/0 | 2/0 | 0 | 0 | 0 | 2/0 | 990 | belge, kacis |
| gizli | 2 | zafer | 1:02 | 0 | 0 | 0/2 | 0 | 0/0 | 2/0 | 0 | 0 | 0 | 2/0 | 990 | belge, kacis |
| gizli | 3 | zafer | 0:56 | 0 | 0 | 0/3 | 0 | 1/0 | 2/0 | 0 | 0 | 0 | 2/0 | 880 | belge, kacis |
| saldiri | 1 | zafer | 0:34 | 13 | 67 | 5/5 | 6 | 0/0 | 0/6 | 0 | 0 | 0 | 0/0 | 440 | belge, kacis |
| saldiri | 2 | zafer | 0:38 | 13 | 91 | 9/4 | 6 | 0/0 | 0/4 | 0 | 0 | 0 | 0/0 | 530 | belge, kacis |
| saldiri | 3 | zafer | 0:37 | 12 | 93 | 8/5 | 6 | 0/0 | 0/4 | 0 | 0 | 0 | 0/0 | 530 | belge, kacis |

- gizli: 3/3 zafer, ortalama zafer süresi 0:59, ortalama tespit 0.0
- saldiri: 3/3 zafer, ortalama zafer süresi 0:36, ortalama tespit 12.7
Kazanma oranı: **6/6**, en hızlı zafer 0:34
En çok yakalanılan yerler: Ahır yakını (16), Ev B yakını (11), Kilise yakını (7), Karargâh (içi) (3), Karargâh yakını (1)

## bolum1

| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Ceset sakl./bulundu | Taş | Takılma | Yükleme | Pencere/Takip | Puan | Biten görevler |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gizli | 1 | kayip (Çvş. Reilly vuruldu!) | 11:16 | 76 | 750 | 4/6 | 6 | 82/154 | 3/3 | 4 | 0 | 4 | 2/0 | - | temas, anahtar |
| gizli | 2 | kayip (Çvş. Reilly vuruldu!) | 9:04 | 58 | 750 | 6/6 | 6 | 26/9 | 8/1 | 3 | 0 | 4 | 2/0 | - | temas, anahtar, pilot |
| gizli | 3 | kayip (Çvş. Reilly vuruldu!) | 7:31 | 77 | 739 | 1/8 | 6 | 121/339 | 2/2 | 2 | 1 | 4 | 0/0 | - | temas |
| saldiri | 1 | kayip (Çvş. Reilly vuruldu!) | 0:30 | 11 | 150 | 0/3 | 0 | 0/0 | 0/1 | 0 | 0 | 0 | 0/0 | - |  |
| saldiri | 2 | kayip (Çvş. Reilly vuruldu!) | 0:28 | 10 | 150 | 0/1 | 0 | 0/0 | 0/1 | 0 | 0 | 0 | 0/0 | - |  |
| saldiri | 3 | kayip (Çvş. Reilly vuruldu!) | 0:28 | 9 | 150 | 0/2 | 0 | 0/0 | 0/0 | 0 | 0 | 0 | 0/0 | - |  |

- gizli: 0/3 zafer (12 kayıttan devamla), ortalama tespit 70.3
- saldiri: 0/3 zafer, ortalama tespit 10.0
Kazanma oranı: **0/6**
En çok yakalanılan yerler: Ev 3 yakını (36), Kilise yakını (20), açık arazi (2500,2000) (17), Ev 2 yakını (11), açık arazi (3200,1200) (9), açık arazi (2400,2000) (6)
Ölüm yerleri: Kilise yakını (3), açık arazi (2800,1000) (1), açık arazi (3100,800) (1), Fırın yakını (1)
Takılma noktaları: Ev 1 yakını (hedef anahtar_asker)

## bolum2

| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Ceset sakl./bulundu | Taş | Takılma | Yükleme | Pencere/Takip | Puan | Biten görevler |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gizli | 1 | kayip (Yzb. Blake öldü! Görev başarısız.) | 7:29 | 47 | 560 | 11/11 | 6 | 165/31 | 12/2 | 2 | 1 | 4 | 5/0 | - | temas, telsiz, anahtar, sahin, kodlar |
| gizli | 2 | kayip (Yzb. Blake öldü! Görev başarısız.) | 4:42 | 40 | 600 | 1/8 | 6 | 49/9 | 5/1 | 3 | 0 | 4 | 6/0 | - | temas, telsiz, anahtar, sahin, kodlar |
| gizli | 3 | kayip (Çvş. Reilly vuruldu!) | 5:56 | 58 | 613 | 3/9 | 6 | 27/17 | 7/4 | 2 | 0 | 4 | 6/0 | - | temas, telsiz, anahtar, sahin, kodlar, radar |
| saldiri | 1 | kayip (Çvş. Reilly vuruldu!) | 0:37 | 13 | 150 | 3/1 | 6 | 0/0 | 0/2 | 0 | 0 | 0 | 0/0 | - | temas, telsiz |
| saldiri | 2 | kayip (Çvş. Reilly vuruldu!) | 0:59 | 21 | 150 | 7/3 | 6 | 0/0 | 0/10 | 0 | 0 | 0 | 0/1 | - | temas, telsiz |
| saldiri | 3 | kayip (Çvş. Reilly vuruldu!) | 0:59 | 17 | 150 | 5/5 | 6 | 0/0 | 0/6 | 0 | 0 | 0 | 0/0 | - | temas, telsiz |

- gizli: 0/3 zafer (12 kayıttan devamla), ortalama tespit 48.3
- saldiri: 0/3 zafer, ortalama tespit 17.0
Kazanma oranı: **0/6**
En çok yakalanılan yerler: açık arazi (3800,1200) (27), açık arazi (3400,1000) (18), Hapishane yakını (14), açık arazi (4000,700) (10), Telsiz kulübesi yakını (10), açık arazi (3400,1100) (8)
Ölüm yerleri: açık arazi (3400,2300) (1), açık arazi (3600,400) (1), açık arazi (4500,900) (1), Ağ deposu yakını (1), açık arazi (2600,1600) (1), açık arazi (2500,1300) (1)
Takılma noktaları: Hapishane (içi) (hedef kodlar)

## bolum3

| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Ceset sakl./bulundu | Taş | Takılma | Yükleme | Pencere/Takip | Puan | Biten görevler |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gizli | 1 | kayip (Henri 'Gölge' Duval öldü! Görev başarısız.) | 9:06 | 42 | 646 | 6/7 | 6 | 152/1 | 4/1 | 4 | 0 | 4 | 10/0 | - | temas, golge, trafo, anahtar, sevkiyat, tarife, makas, kapi1, kapi2 |
| gizli | 2 | kayip (Çvş. Reilly vuruldu!) | 7:16 | 46 | 662 | 5/7 | 6 | 225/35 | 2/4 | 4 | 0 | 4 | 7/0 | - | temas, golge, trafo, anahtar, sevkiyat, tarife, makas, kapi1 |
| gizli | 3 | kayip (Çvş. Reilly vuruldu!) | 8:02 | 51 | 526 | 8/9 | 6 | 145/2 | 2/2 | 4 | 0 | 4 | 7/0 | - | temas, golge, trafo, anahtar, sevkiyat, tarife, makas |
| saldiri | 1 | kayip (Çvş. Reilly vuruldu!) | 2:11 | 26 | 150 | 15/5 | 6 | 0/0 | 0/11 | 0 | 0 | 0 | 0/1 | - | temas, golge, trafo, anahtar, sevkiyat, tarife, makas |
| saldiri | 2 | kayip (Henri 'Gölge' Duval öldü! Görev başarısız.) | 0:38 | 18 | 111 | 3/2 | 6 | 0/0 | 0/3 | 0 | 0 | 0 | 0/0 | - | temas, golge |
| saldiri | 3 | kayip (Henri 'Gölge' Duval öldü! Görev başarısız.) | 1:47 | 20 | 109 | 14/4 | 6 | 0/0 | 0/9 | 0 | 0 | 0 | 0/1 | - | temas, golge, trafo, anahtar, sevkiyat, tarife |

- gizli: 0/3 zafer (12 kayıttan devamla), ortalama tespit 46.3
- saldiri: 0/3 zafer, ortalama tespit 21.3
Kazanma oranı: **0/6**
En çok yakalanılan yerler: Kontrol odası yakını (25), Liman ofisi yakını (14), açık arazi (4300,1400) (11), açık arazi (2500,1100) (11), açık arazi (2300,1200) (10), açık arazi (2600,1100) (9)
Ölüm yerleri: açık arazi (5300,2500) (1), Denizaltı Bunkeri (içi) (1), açık arazi (2400,1300) (1), Kontrol odası yakını (1), Trafo yakını (1), açık arazi (4900,500) (1)

## bolum4

| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Ceset sakl./bulundu | Taş | Takılma | Yükleme | Pencere/Takip | Puan | Biten görevler |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gizli | 1 | kayip (Onb. Sam 'Kıvılcım' Kowalski öldü! Görev başarısız.) | 6:48 | 61 | 751 | 5/9 | 6 | 49/46 | 4/0 | 1 | 1 | 4 | 14/0 | - | temas, anahtar, kivilcim, sinyal |
| gizli | 2 | kayip (Onb. Sam 'Kıvılcım' Kowalski öldü! Görev başarısız.) | 6:43 | 57 | 803 | 5/14 | 6 | 88/7 | 3/1 | 1 | 0 | 4 | 11/0 | - | temas, anahtar, kivilcim, sinyal, liste |
| gizli | 3 | kayip (Onb. Sam 'Kıvılcım' Kowalski öldü! Görev başarısız.) | 7:15 | 46 | 424 | 8/10 | 0 | 28/31 | 4/0 | 2 | 0 | 4 | 11/0 | - | temas, anahtar, kivilcim, sinyal |
| saldiri | 1 | kayip (Çvş. Reilly vuruldu!) | 0:54 | 19 | 150 | 9/4 | 6 | 0/0 | 0/8 | 0 | 0 | 0 | 0/3 | - | temas, anahtar, kivilcim |
| saldiri | 2 | kayip (Çvş. Reilly vuruldu!) | 0:43 | 12 | 150 | 7/3 | 6 | 0/0 | 0/8 | 0 | 0 | 0 | 0/0 | - | temas, anahtar |
| saldiri | 3 | kayip (Çvş. Reilly vuruldu!) | 0:54 | 15 | 150 | 8/4 | 6 | 0/0 | 0/10 | 0 | 0 | 0 | 0/0 | - | temas, anahtar, kivilcim |

- gizli: 0/3 zafer (12 kayıttan devamla), ortalama tespit 54.7
- saldiri: 0/3 zafer, ortalama tespit 15.3
Kazanma oranı: **0/6**
En çok yakalanılan yerler: Depo ofisi yakını (27), açık arazi (3300,1600) (19), Kamp karargâhı yakını (17), açık arazi (3900,1700) (11), açık arazi (3800,1500) (11), Depo ofisi (içi) (9)
Ölüm yerleri: açık arazi (2400,2700) (1), açık arazi (2900,1100) (1), açık arazi (1400,2600) (1), açık arazi (1100,900) (1), Nöbet barakası yakını (1), açık arazi (1200,1000) (1)
Takılma noktaları: Depo ofisi (içi) (hedef lokomotif)

## bolum5

| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Ceset sakl./bulundu | Taş | Takılma | Yükleme | Pencere/Takip | Puan | Biten görevler |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gizli | 1 | kayip (Çvş. Reilly vuruldu!) | 6:51 | 53 | 750 | 4/15 | 6 | 283/131 | 3/2 | 8 | 0 | 4 | 2/0 | - | temas, santral |
| gizli | 2 | kayip (Çvş. Reilly vuruldu!) | 7:56 | 69 | 750 | 5/14 | 6 | 351/104 | 5/2 | 6 | 0 | 4 | 2/0 | - | temas, santral, ucak |
| gizli | 3 | kayip (Çvş. Reilly vuruldu!) | 5:45 | 67 | 750 | 8/12 | 6 | 271/74 | 2/3 | 8 | 0 | 4 | 2/0 | - | temas, santral, ucak |
| saldiri | 1 | kayip (Çvş. Reilly vuruldu!) | 1:25 | 15 | 150 | 8/4 | 6 | 0/0 | 0/5 | 0 | 0 | 0 | 0/3 | - | temas, santral |
| saldiri | 2 | kayip (Çvş. Reilly vuruldu!) | 1:30 | 23 | 150 | 10/3 | 6 | 0/0 | 0/7 | 0 | 0 | 0 | 0/1 | - | temas, santral |
| saldiri | 3 | kayip (Çvş. Reilly vuruldu!) | 0:27 | 9 | 150 | 0/4 | 6 | 0/0 | 0/2 | 0 | 0 | 0 | 0/1 | - | temas |

- gizli: 0/3 zafer (12 kayıttan devamla), ortalama tespit 63.0
- saldiri: 0/3 zafer, ortalama tespit 15.7
Kazanma oranı: **0/6**
En çok yakalanılan yerler: açık arazi (5000,600) (21), Telsiz binası yakını (16), açık arazi (4800,600) (13), açık arazi (5200,600) (9), açık arazi (5100,600) (8), açık arazi (1200,3000) (8)
Ölüm yerleri: açık arazi (5000,1700) (1), açık arazi (5700,700) (1), açık arazi (5500,1100) (1), açık arazi (4300,500) (1), açık arazi (4700,900) (1), Değirmen yakını (1)

## bolum6

| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Ceset sakl./bulundu | Taş | Takılma | Yükleme | Pencere/Takip | Puan | Biten görevler |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gizli | 1 | kayip (Çvş. Reilly vuruldu!) | 9:49 | 60 | 750 | 6/4 | 12 | 63/132 | 8/2 | 2 | 4 | 4 | 5/0 | - | temas, santral, anahtar, golge |
| gizli | 2 | kayip (Henri 'Gölge' Duval öldü! Görev başarısız.) | 10:16 | 30 | 260 | 6/5 | 12 | 216/38 | 3/5 | 1 | 5 | 4 | 5/0 | - | temas, santral, anahtar, golge |
| gizli | 3 | kayip (Henri 'Gölge' Duval öldü! Görev başarısız.) | 9:32 | 45 | 531 | 5/7 | 12 | 74/24 | 7/2 | 2 | 4 | 4 | 5/0 | - | temas, santral, anahtar, golge |
| saldiri | 1 | kayip (Çvş. Reilly vuruldu!) | 0:29 | 8 | 150 | 0/1 | 0 | 0/0 | 0/1 | 0 | 0 | 0 | 0/0 | - | temas |
| saldiri | 2 | kayip (Çvş. Reilly vuruldu!) | 0:31 | 10 | 150 | 0/2 | 0 | 0/0 | 0/2 | 0 | 0 | 0 | 0/0 | - | temas |
| saldiri | 3 | kayip (Çvş. Reilly vuruldu!) | 0:33 | 11 | 150 | 0/4 | 3 | 0/0 | 0/2 | 0 | 0 | 0 | 0/0 | - | temas |

- gizli: 0/3 zafer (12 kayıttan devamla), ortalama tespit 45.0
- saldiri: 0/3 zafer, ortalama tespit 9.7
Kazanma oranı: **0/6**
En çok yakalanılan yerler: Baraj santrali yakını (23), açık arazi (4400,3600) (16), açık arazi (4200,2800) (12), açık arazi (4100,3500) (9), açık arazi (1500,3200) (8), açık arazi (3400,2700) (6)
Ölüm yerleri: açık arazi (1500,3200) (2), açık arazi (4600,3800) (1), açık arazi (4300,3500) (1), açık arazi (4500,3700) (1), açık arazi (1600,3100) (1)
Takılma noktaları: Gözaltı bunkeri yakını (hedef anahtar_asker), Gözaltı bunkeri yakını (hedef anahtar_asker), Gözaltı bunkeri yakını (hedef anahtar_asker), Gözaltı bunkeri yakını (hedef anahtar_asker), Gözaltı bunkeri yakını (hedef anahtar_asker), Gözaltı bunkeri yakını (hedef anahtar_asker), Gözaltı bunkeri yakını (hedef anahtar_asker), Gözaltı bunkeri yakını (hedef anahtar_asker)

## bolum7

| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Ceset sakl./bulundu | Taş | Takılma | Yükleme | Pencere/Takip | Puan | Biten görevler |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gizli | 1 | kayip (Çvş. Reilly vuruldu!) | 8:27 | 73 | 800 | 0/8 | 6 | 10/17 | 4/0 | 1 | 0 | 4 | 0/0 | - | temas, trafo |
| gizli | 2 | kayip (Çvş. Reilly vuruldu!) | 7:11 | 60 | 800 | 0/6 | 6 | 45/53 | 4/0 | 2 | 0 | 4 | 0/0 | - | temas, trafo |
| gizli | 3 | kayip (Çvş. Reilly vuruldu!) | 7:49 | 61 | 850 | 9/9 | 6 | 129/42 | 9/1 | 3 | 0 | 4 | 3/0 | - | temas, trafo, anahtar, cizim |
| saldiri | 1 | kayip (Çvş. Reilly vuruldu!) | 1:00 | 8 | 150 | 2/4 | 6 | 0/0 | 0/4 | 0 | 0 | 0 | 0/0 | - | temas, trafo |
| saldiri | 2 | kayip (Çvş. Reilly vuruldu!) | 0:56 | 7 | 150 | 0/4 | 6 | 0/0 | 0/3 | 0 | 0 | 0 | 0/0 | - | temas, trafo |
| saldiri | 3 | kayip (Çvş. Reilly vuruldu!) | 0:57 | 8 | 150 | 0/4 | 6 | 0/0 | 0/2 | 0 | 0 | 0 | 0/0 | - | temas, trafo |

- gizli: 0/3 zafer (12 kayıttan devamla), ortalama tespit 64.7
- saldiri: 0/3 zafer, ortalama tespit 7.7
Kazanma oranı: **0/6**
En çok yakalanılan yerler: açık arazi (4100,400) (48), açık arazi (3800,700) (16), Trafo istasyonu yakını (15), açık arazi (3700,700) (12), açık arazi (3800,400) (7), açık arazi (4000,400) (6)
Ölüm yerleri: açık arazi (4200,400) (2), Trafo istasyonu yakını (2), açık arazi (4200,1300) (1), açık arazi (2600,1400) (1)

## Bulgular ve öneriler (otomatik)

- bolum0: bot 0:34'da kazandı — bölüm çok kısa/kolay. Görev zincirini uzat, hedefleri birbirinden uzaklaştır, kilitli kapı/anahtar gibi ara adımlar ekle.
- bolum0: gizli bot neredeyse hiç fark edilmiyor — devriye örtüşmesini ve algılamayı artır.
- bolum0: saldırı tarzı kazanabiliyor — tabanca/çatışma oyuncu lehine; asker isabeti, takviye hızı veya mermi kıtlığı ayarlanmalı.
- bolum0: kazanan oyunlarda askerlerin çoğu öldürülüyor — gizlilik ödüllendirilmiyor; ceset bulunması/alarm daha etkili olmalı.
- bolum0: 'Ahır yakını' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.
- bolum1: saldırı tarzı 1 dakikada ölüyor — açık çatışma çok cezalandırıcı olabilir; siper/kaçış yolları ekle.
- bolum1: 'Ev 3 yakını' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.
- bolum2: saldırı tarzı 1 dakikada ölüyor — açık çatışma çok cezalandırıcı olabilir; siper/kaçış yolları ekle.
- bolum2: 'açık arazi (3800,1200)' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.
- bolum3: 'Kontrol odası yakını' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.
- bolum4: saldırı tarzı 1 dakikada ölüyor — açık çatışma çok cezalandırıcı olabilir; siper/kaçış yolları ekle.
- bolum4: 'Depo ofisi yakını' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.
- bolum5: 'açık arazi (5000,600)' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.
- bolum6: saldırı tarzı 1 dakikada ölüyor — açık çatışma çok cezalandırıcı olabilir; siper/kaçış yolları ekle.
- bolum6: bot takılıyor (13 kez) — navigasyon/kapı geçişlerini kontrol et.
- bolum6: 'Baraj santrali yakını' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.
- bolum7: 'açık arazi (4100,400)' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.

Ham veriler: `build/bot/*.json` (CI'da `bot-raporu` artefaktı).
