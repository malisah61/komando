# Bot oyun testi raporu

Tarih: 2026-11-12 15:42 — 63 oyun (gizli, saldiri, tam × 3 tohum).
Bot `tests/bot.gd`: gizli = çömel, devriye bakıyorsa bekle, şüphelenirse geri çekil, arkadan bıçakla; saldırı = tabancayla temizle; tam = gizli + isteğe bağlı görevler. Gizli/tam sakinken kaydeder, ölünce son kayıttan devam eder (en çok 4 kez, Tur 4); saldırı tarzı yüklemez.

## bolum0

| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Ceset sakl./bulundu | Taş | Takılma | Yükleme | Puan | Biten görevler |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gizli | 1 | zafer | 1:02 | 0 | 0 | 0/3 | 0 | 0/0 | 2/0 | 0 | 0 | 0 | 1005 | belge, kacis |
| gizli | 2 | zafer | 1:01 | 0 | 0 | 0/3 | 0 | 0/0 | 2/0 | 0 | 0 | 0 | 1005 | belge, kacis |
| gizli | 3 | zafer | 0:59 | 0 | 0 | 0/4 | 0 | 2/1 | 2/0 | 0 | 0 | 0 | 895 | belge, kacis |
| saldiri | 1 | zafer | 0:34 | 13 | 67 | 5/5 | 6 | 0/0 | 0/6 | 0 | 0 | 0 | 440 | belge, kacis |
| saldiri | 2 | zafer | 0:38 | 8 | 42 | 6/4 | 6 | 0/0 | 0/6 | 0 | 0 | 0 | 440 | belge, kacis |
| saldiri | 3 | zafer | 0:37 | 11 | 94 | 8/5 | 6 | 0/0 | 0/4 | 0 | 0 | 0 | 530 | belge, kacis |
| tam | 1 | zafer | 1:02 | 0 | 0 | 0/3 | 0 | 0/0 | 2/0 | 0 | 0 | 0 | 1005 | belge, kacis |
| tam | 2 | zafer | 1:01 | 0 | 0 | 0/3 | 0 | 0/0 | 2/0 | 0 | 0 | 0 | 1005 | belge, kacis |
| tam | 3 | zafer | 0:59 | 0 | 0 | 0/4 | 0 | 2/1 | 2/0 | 0 | 0 | 0 | 895 | belge, kacis |

- gizli: 3/3 zafer, ortalama zafer süresi 1:00, ortalama tespit 0.0
- saldiri: 3/3 zafer, ortalama zafer süresi 0:36, ortalama tespit 10.7
- tam: 3/3 zafer, ortalama zafer süresi 1:00, ortalama tespit 0.0
Kazanma oranı: **9/9**, en hızlı zafer 0:34
En çok yakalanılan yerler: Ahır yakını (18), Ev B yakını (7), Kilise yakını (6), Karargâh (içi) (1)

## bolum1

| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Ceset sakl./bulundu | Taş | Takılma | Yükleme | Puan | Biten görevler |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gizli | 1 | kayip (Çvş. Reilly vuruldu!) | 4:59 | 66 | 750 | 0/8 | 6 | 99/146 | 5/1 | 4 | 2 | 4 | - | temas |
| gizli | 2 | kayip (Çvş. Reilly vuruldu!) | 6:53 | 51 | 750 | 0/2 | 6 | 14/42 | 1/0 | 5 | 0 | 4 | - | temas |
| gizli | 3 | kayip (Yzb. Carter öldü! Görev başarısız.) | 6:26 | 45 | 432 | 6/5 | 6 | 27/10 | 4/0 | 0 | 0 | 4 | - | temas, anahtar, pilot |
| saldiri | 1 | kayip (Çvş. Reilly vuruldu!) | 0:48 | 11 | 150 | 0/8 | 6 | 0/0 | 0/3 | 0 | 0 | 0 | - |  |
| saldiri | 2 | kayip (Çvş. Reilly vuruldu!) | 0:28 | 9 | 150 | 0/2 | 0 | 0/0 | 0/0 | 0 | 0 | 0 | - |  |
| saldiri | 3 | kayip (Çvş. Reilly vuruldu!) | 0:29 | 7 | 150 | 0/2 | 0 | 0/0 | 0/0 | 0 | 0 | 0 | - |  |
| tam | 1 | kayip (Çvş. Reilly vuruldu!) | 4:59 | 66 | 750 | 0/8 | 6 | 99/146 | 5/1 | 4 | 2 | 4 | - | temas |
| tam | 2 | kayip (Çvş. Reilly vuruldu!) | 6:53 | 51 | 750 | 0/2 | 6 | 14/42 | 1/0 | 5 | 0 | 4 | - | temas |
| tam | 3 | kayip (Yzb. Carter öldü! Görev başarısız.) | 6:26 | 45 | 432 | 6/5 | 6 | 27/10 | 4/0 | 0 | 0 | 4 | - | temas, anahtar, pilot |

- gizli: 0/3 zafer (12 kayıttan devamla), ortalama tespit 54.0
- saldiri: 0/3 zafer, ortalama tespit 9.0
- tam: 0/3 zafer (12 kayıttan devamla), ortalama tespit 54.0
Kazanma oranı: **0/9**
En çok yakalanılan yerler: açık arazi (2500,1900) (80), açık arazi (2500,2000) (62), Ev 3 yakını (60), açık arazi (2000,1900) (12), açık arazi (2500,2300) (10), Kilise yakını (10)
Ölüm yerleri: açık arazi (2500,2300) (2), açık arazi (2500,2000) (2), Ev 3 yakını (2), Kilise yakını (2), Ambar yakını (1)
Takılma noktaları: açık arazi (2400,2000) (hedef anahtar_asker), açık arazi (2400,2000) (hedef anahtar_asker), açık arazi (2400,2000) (hedef anahtar_asker), açık arazi (2400,2000) (hedef anahtar_asker)

## bolum2

| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Ceset sakl./bulundu | Taş | Takılma | Yükleme | Puan | Biten görevler |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gizli | 1 | kayip (Çvş. Reilly vuruldu!) | 6:06 | 43 | 482 | 13/6 | 6 | 76/0 | 9/7 | 0 | 0 | 4 | - | temas, telsiz, anahtar, sahin, kodlar, radar |
| gizli | 2 | kayip (Çvş. Reilly vuruldu!) | 5:54 | 51 | 609 | 7/9 | 6 | 32/2 | 7/2 | 0 | 0 | 4 | - | temas, telsiz, anahtar, sahin, kodlar, radar |
| gizli | 3 | kayip (Çvş. Reilly vuruldu!) | 3:44 | 45 | 660 | 8/5 | 6 | 15/1 | 4/3 | 0 | 0 | 4 | - | temas, telsiz, anahtar, sahin, kodlar |
| saldiri | 1 | kayip (Çvş. Reilly vuruldu!) | 0:47 | 13 | 150 | 4/1 | 6 | 0/0 | 0/3 | 0 | 0 | 0 | - | temas, telsiz |
| saldiri | 2 | kayip (Çvş. Reilly vuruldu!) | 1:01 | 18 | 150 | 7/3 | 6 | 0/0 | 0/7 | 0 | 0 | 0 | - | temas, telsiz |
| saldiri | 3 | kayip (Çvş. Reilly vuruldu!) | 0:59 | 14 | 150 | 2/4 | 6 | 0/0 | 0/6 | 0 | 0 | 0 | - | temas, telsiz |
| tam | 1 | kayip (Çvş. Reilly vuruldu!) | 6:06 | 43 | 482 | 13/6 | 6 | 76/0 | 9/7 | 0 | 0 | 4 | - | temas, telsiz, anahtar, sahin, kodlar, radar |
| tam | 2 | kayip (Çvş. Reilly vuruldu!) | 5:54 | 51 | 609 | 7/9 | 6 | 32/2 | 7/2 | 0 | 0 | 4 | - | temas, telsiz, anahtar, sahin, kodlar, radar |
| tam | 3 | kayip (Çvş. Reilly vuruldu!) | 3:44 | 45 | 660 | 8/5 | 6 | 15/1 | 4/3 | 0 | 0 | 4 | - | temas, telsiz, anahtar, sahin, kodlar |

- gizli: 0/3 zafer (12 kayıttan devamla), ortalama tespit 46.3
- saldiri: 0/3 zafer, ortalama tespit 15.0
- tam: 0/3 zafer (12 kayıttan devamla), ortalama tespit 46.3
Kazanma oranı: **0/9**
En çok yakalanılan yerler: açık arazi (2700,1200) (62), açık arazi (3400,1000) (38), açık arazi (3100,1200) (36), Komutanlık yakını (36), açık arazi (3200,1300) (10), açık arazi (3300,1200) (8)
Ölüm yerleri: açık arazi (2900,400) (2), açık arazi (2600,1200) (2), açık arazi (2700,1200) (2), açık arazi (1800,1500) (1), açık arazi (2600,1500) (1), açık arazi (2500,1400) (1)

## bolum3

| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Ceset sakl./bulundu | Taş | Takılma | Yükleme | Puan | Biten görevler |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gizli | 1 | kayip (Çvş. Reilly vuruldu!) | 8:20 | 45 | 524 | 8/18 | 6 | 269/24 | 3/4 | 2 | 0 | 4 | - | temas, golge, trafo, anahtar, sevkiyat, tarife, makas |
| gizli | 2 | zafer | 7:05 | 20 | 251 | 9/11 | 6 | 173/10 | 3/8 | 2 | 0 | 1 | 195 | temas, golge, trafo, anahtar, sevkiyat, tarife, makas, kapi1, kapi2, kacis |
| gizli | 3 | kayip (Çvş. Reilly vuruldu!) | 6:59 | 26 | 550 | 12/7 | 12 | 82/18 | 2/8 | 4 | 2 | 4 | - | temas, golge, trafo, anahtar, sevkiyat, tarife, makas, kapi1, kapi2 |
| saldiri | 1 | kayip (Henri 'Gölge' Duval öldü! Görev başarısız.) | 0:55 | 12 | 56 | 2/4 | 6 | 0/0 | 0/5 | 0 | 0 | 0 | - | temas, golge, trafo |
| saldiri | 2 | kayip (Çvş. Reilly vuruldu!) | 0:59 | 15 | 150 | 7/2 | 6 | 0/0 | 0/5 | 0 | 0 | 0 | - | temas, golge, trafo, anahtar |
| saldiri | 3 | kayip (Çvş. Reilly vuruldu!) | 1:40 | 17 | 150 | 13/5 | 6 | 0/0 | 0/8 | 0 | 0 | 0 | - | temas, golge, trafo, anahtar, sevkiyat, tarife |
| tam | 1 | kayip (Çvş. Reilly vuruldu!) | 8:20 | 45 | 524 | 8/18 | 6 | 269/24 | 3/4 | 2 | 0 | 4 | - | temas, golge, trafo, anahtar, sevkiyat, tarife, makas |
| tam | 2 | kayip (Henri 'Gölge' Duval öldü! Görev başarısız.) | 8:26 | 43 | 472 | 18/11 | 12 | 146/14 | 4/11 | 3 | 0 | 4 | - | temas, golge, trafo, anahtar, sevkiyat, tarife, makas, kapi1, kapi2, yakit |
| tam | 3 | kayip (Çvş. Reilly vuruldu!) | 11:16 | 33 | 550 | 10/7 | 12 | 99/31 | 2/8 | 4 | 0 | 4 | - | temas, golge, trafo, anahtar, sevkiyat, tarife, makas, kapi1, kapi2, yakit |

- gizli: 1/3 zafer (9 kayıttan devamla), ortalama zafer süresi 7:05, ortalama tespit 30.3
- saldiri: 0/3 zafer, ortalama tespit 14.7
- tam: 0/3 zafer (12 kayıttan devamla), ortalama tespit 40.3
Kazanma oranı: **1/9**, en hızlı zafer 7:05
En çok yakalanılan yerler: açık arazi (4600,500) (24), açık arazi (3200,200) (16), Denizaltı Bunkeri yakını (14), açık arazi (2600,1100) (12), açık arazi (4800,500) (12), açık arazi (2700,500) (10)
Ölüm yerleri: Denizaltı Bunkeri (içi) (2), açık arazi (3400,1900) (1), Liman ofisi (içi) (1), Liman ofisi yakını (1), açık arazi (4800,600) (1), açık arazi (5000,500) (1), açık arazi (4600,500) (1)
Takılma noktaları: Denizaltı Bunkeri (içi) (hedef exit), Denizaltı Bunkeri (içi) (hedef exit)

## bolum4

| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Ceset sakl./bulundu | Taş | Takılma | Yükleme | Puan | Biten görevler |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gizli | 1 | kayip (Onb. Sam 'Kıvılcım' Kowalski öldü! Görev başarısız.) | 5:16 | 41 | 578 | 8/3 | 6 | 5/0 | 5/0 | 0 | 0 | 4 | - | temas, anahtar, kivilcim, sinyal |
| gizli | 2 | kayip (Onb. Sam 'Kıvılcım' Kowalski öldü! Görev başarısız.) | 5:14 | 38 | 529 | 8/3 | 3 | 5/0 | 5/0 | 0 | 0 | 4 | - | temas, anahtar, kivilcim, sinyal |
| gizli | 3 | kayip (Onb. Sam 'Kıvılcım' Kowalski öldü! Görev başarısız.) | 5:22 | 39 | 638 | 8/3 | 3 | 5/0 | 5/0 | 0 | 0 | 4 | - | temas, anahtar, kivilcim, sinyal |
| saldiri | 1 | kayip (Çvş. Reilly vuruldu!) | 1:27 | 23 | 200 | 10/4 | 6 | 0/0 | 0/9 | 0 | 0 | 0 | - | temas, anahtar, kivilcim, sinyal |
| saldiri | 2 | kayip (Çvş. Reilly vuruldu!) | 0:43 | 12 | 150 | 7/3 | 6 | 0/0 | 0/8 | 0 | 0 | 0 | - | temas, anahtar |
| saldiri | 3 | kayip (Onb. Sam 'Kıvılcım' Kowalski öldü! Görev başarısız.) | 1:26 | 22 | 172 | 10/4 | 6 | 0/0 | 0/11 | 0 | 0 | 0 | - | temas, anahtar, kivilcim, sinyal |
| tam | 1 | kayip (Onb. Sam 'Kıvılcım' Kowalski öldü! Görev başarısız.) | 5:16 | 41 | 578 | 8/3 | 6 | 5/0 | 5/0 | 0 | 0 | 4 | - | temas, anahtar, kivilcim, sinyal |
| tam | 2 | kayip (Onb. Sam 'Kıvılcım' Kowalski öldü! Görev başarısız.) | 5:14 | 38 | 529 | 8/3 | 3 | 5/0 | 5/0 | 0 | 0 | 4 | - | temas, anahtar, kivilcim, sinyal |
| tam | 3 | kayip (Onb. Sam 'Kıvılcım' Kowalski öldü! Görev başarısız.) | 5:22 | 39 | 638 | 8/3 | 3 | 5/0 | 5/0 | 0 | 0 | 4 | - | temas, anahtar, kivilcim, sinyal |

- gizli: 0/3 zafer (12 kayıttan devamla), ortalama tespit 39.3
- saldiri: 0/3 zafer, ortalama tespit 19.0
- tam: 0/3 zafer (12 kayıttan devamla), ortalama tespit 39.3
Kazanma oranı: **0/9**
En çok yakalanılan yerler: açık arazi (1700,2500) (122), açık arazi (1700,2400) (50), açık arazi (2000,2600) (36), Kamp karargâhı yakını (17), açık arazi (1500,2500) (14), açık arazi (2000,2500) (12)
Ölüm yerleri: açık arazi (1700,2500) (4), açık arazi (1700,2400) (2), açık arazi (3000,1200) (1), Nöbet barakası yakını (1), açık arazi (3100,1200) (1)

## bolum5

| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Ceset sakl./bulundu | Taş | Takılma | Yükleme | Puan | Biten görevler |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gizli | 1 | kayip (Çvş. Reilly vuruldu!) | 5:42 | 76 | 1000 | 3/12 | 6 | 108/68 | 3/3 | 3 | 0 | 4 | - | temas, santral |
| gizli | 2 | kayip (Çvş. Reilly vuruldu!) | 5:37 | 63 | 1000 | 5/6 | 6 | 193/43 | 3/4 | 3 | 0 | 4 | - | temas, santral, ucak |
| gizli | 3 | kayip (Çvş. Reilly vuruldu!) | 5:35 | 68 | 1000 | 5/6 | 6 | 168/43 | 3/4 | 3 | 0 | 4 | - | temas, santral, ucak |
| saldiri | 1 | kayip (Çvş. Reilly vuruldu!) | 0:52 | 10 | 150 | 4/4 | 6 | 0/0 | 0/2 | 0 | 0 | 0 | - | temas |
| saldiri | 2 | kayip (Çvş. Reilly vuruldu!) | 0:50 | 13 | 150 | 7/3 | 6 | 0/0 | 0/7 | 0 | 0 | 0 | - | temas |
| saldiri | 3 | kayip (Çvş. Reilly vuruldu!) | 0:28 | 8 | 150 | 0/4 | 6 | 0/0 | 0/2 | 0 | 0 | 0 | - | temas |
| tam | 1 | kayip (Çvş. Reilly vuruldu!) | 5:42 | 76 | 1000 | 3/12 | 6 | 108/68 | 3/3 | 3 | 0 | 4 | - | temas, santral |
| tam | 2 | kayip (Çvş. Reilly vuruldu!) | 5:37 | 63 | 1000 | 5/6 | 6 | 193/43 | 3/4 | 3 | 0 | 4 | - | temas, santral, ucak |
| tam | 3 | kayip (Çvş. Reilly vuruldu!) | 5:35 | 68 | 1000 | 5/6 | 6 | 168/43 | 3/4 | 3 | 0 | 4 | - | temas, santral, ucak |

- gizli: 0/3 zafer (12 kayıttan devamla), ortalama tespit 69.0
- saldiri: 0/3 zafer, ortalama tespit 10.3
- tam: 0/3 zafer (12 kayıttan devamla), ortalama tespit 69.0
Kazanma oranı: **0/9**
En çok yakalanılan yerler: açık arazi (5200,600) (86), açık arazi (5000,1300) (24), açık arazi (5000,1700) (22), açık arazi (5100,1700) (14), açık arazi (5000,600) (14), açık arazi (5200,1400) (12)
Ölüm yerleri: açık arazi (5100,600) (4), açık arazi (4900,600) (2), Telefon santrali yakını (1), açık arazi (1400,1100) (1), Değirmen yakını (1)

## bolum6

| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Ceset sakl./bulundu | Taş | Takılma | Yükleme | Puan | Biten görevler |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gizli | 1 | kayip (Çvş. Reilly vuruldu!) | 5:14 | 59 | 750 | 2/7 | 6 | 3/0 | 2/0 | 0 | 0 | 4 | - | temas, santral, anahtar |
| gizli | 2 | kayip (Çvş. Reilly vuruldu!) | 5:22 | 60 | 750 | 2/7 | 6 | 3/0 | 2/0 | 0 | 0 | 4 | - | temas, santral, anahtar |
| gizli | 3 | kayip (Çvş. Reilly vuruldu!) | 5:18 | 62 | 738 | 3/7 | 6 | 3/12 | 3/0 | 0 | 0 | 4 | - | temas, santral, anahtar |
| saldiri | 1 | kayip (Çvş. Reilly vuruldu!) | 0:29 | 8 | 150 | 0/1 | 0 | 0/0 | 0/1 | 0 | 0 | 0 | - | temas |
| saldiri | 2 | kayip (Çvş. Reilly vuruldu!) | 0:31 | 10 | 150 | 0/2 | 0 | 0/0 | 0/2 | 0 | 0 | 0 | - | temas |
| saldiri | 3 | kayip (Çvş. Reilly vuruldu!) | 0:33 | 11 | 150 | 0/4 | 3 | 0/0 | 0/2 | 0 | 0 | 0 | - | temas |
| tam | 1 | kayip (Çvş. Reilly vuruldu!) | 5:14 | 59 | 750 | 2/7 | 6 | 3/0 | 2/0 | 0 | 0 | 4 | - | temas, santral, anahtar |
| tam | 2 | kayip (Çvş. Reilly vuruldu!) | 5:22 | 60 | 750 | 2/7 | 6 | 3/0 | 2/0 | 0 | 0 | 4 | - | temas, santral, anahtar |
| tam | 3 | kayip (Çvş. Reilly vuruldu!) | 5:18 | 62 | 738 | 3/7 | 6 | 3/12 | 3/0 | 0 | 0 | 4 | - | temas, santral, anahtar |

- gizli: 0/3 zafer (12 kayıttan devamla), ortalama tespit 60.3
- saldiri: 0/3 zafer, ortalama tespit 9.7
- tam: 0/3 zafer (12 kayıttan devamla), ortalama tespit 60.3
Kazanma oranı: **0/9**
En çok yakalanılan yerler: açık arazi (1700,1800) (110), açık arazi (1300,1900) (38), açık arazi (1500,1900) (28), açık arazi (1600,1900) (16), Kamp karargâhı yakını (14), açık arazi (1600,1800) (12)
Ölüm yerleri: açık arazi (1700,1800) (4), açık arazi (1500,1900) (2), açık arazi (1500,3200) (2), açık arazi (1600,3100) (1)

## Bulgular ve öneriler (otomatik)

- bolum0: bot 0:34'da kazandı — bölüm çok kısa/kolay. Görev zincirini uzat, hedefleri birbirinden uzaklaştır, kilitli kapı/anahtar gibi ara adımlar ekle.
- bolum0: gizli bot neredeyse hiç fark edilmiyor — devriye örtüşmesini ve algılamayı artır.
- bolum0: saldırı tarzı kazanabiliyor — tabanca/çatışma oyuncu lehine; asker isabeti, takviye hızı veya mermi kıtlığı ayarlanmalı.
- bolum0: kazanan oyunlarda askerlerin çoğu öldürülüyor — gizlilik ödüllendirilmiyor; ceset bulunması/alarm daha etkili olmalı.
- bolum0: 'Ahır yakını' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.
- bolum1: saldırı tarzı 1 dakikada ölüyor — açık çatışma çok cezalandırıcı olabilir; siper/kaçış yolları ekle.
- bolum1: 'açık arazi (2500,1900)' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.
- bolum2: 'açık arazi (2700,1200)' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.
- bolum3: bot 7:05'da kazandı — bölüm çok kısa/kolay. Görev zincirini uzat, hedefleri birbirinden uzaklaştır, kilitli kapı/anahtar gibi ara adımlar ekle.
- bolum3: 'açık arazi (4600,500)' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.
- bolum4: 'açık arazi (1700,2500)' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.
- bolum5: saldırı tarzı 1 dakikada ölüyor — açık çatışma çok cezalandırıcı olabilir; siper/kaçış yolları ekle.
- bolum5: 'açık arazi (5200,600)' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.
- bolum6: saldırı tarzı 1 dakikada ölüyor — açık çatışma çok cezalandırıcı olabilir; siper/kaçış yolları ekle.
- bolum6: 'açık arazi (1700,1800)' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.

Ham veriler: `build/bot/*.json` (CI'da `bot-raporu` artefaktı).
