# Bot oyun testi raporu

Tarih: 2026-11-13 00:55 — 72 oyun (gizli, saldiri, tam × 3 tohum).
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
| gizli | 1 | kayip (Çvş. Reilly vuruldu!) | 9:34 | 66 | 734 | 0/3 | 6 | 70/43 | 1/1 | 1 | 1 | 4 | - | temas |
| gizli | 2 | kayip (Çvş. Reilly vuruldu!) | 6:40 | 70 | 739 | 6/3 | 6 | 10/0 | 7/0 | 1 | 0 | 4 | - | temas |
| gizli | 3 | kayip (Çvş. Reilly vuruldu!) | 14:19 | 86 | 724 | 5/10 | 6 | 47/21 | 3/7 | 2 | 0 | 4 | - | temas, anahtar, pilot |
| saldiri | 1 | kayip (Çvş. Reilly vuruldu!) | 0:48 | 11 | 150 | 0/8 | 6 | 0/0 | 0/3 | 0 | 0 | 0 | - |  |
| saldiri | 2 | kayip (Çvş. Reilly vuruldu!) | 0:28 | 9 | 150 | 0/2 | 0 | 0/0 | 0/0 | 0 | 0 | 0 | - |  |
| saldiri | 3 | kayip (Çvş. Reilly vuruldu!) | 0:29 | 7 | 150 | 0/2 | 0 | 0/0 | 0/0 | 0 | 0 | 0 | - |  |
| tam | 1 | kayip (Çvş. Reilly vuruldu!) | 9:34 | 66 | 734 | 0/3 | 6 | 70/43 | 1/1 | 1 | 1 | 4 | - | temas |
| tam | 2 | kayip (Çvş. Reilly vuruldu!) | 6:40 | 70 | 739 | 6/3 | 6 | 10/0 | 7/0 | 1 | 0 | 4 | - | temas |
| tam | 3 | kayip (Çvş. Reilly vuruldu!) | 14:19 | 86 | 724 | 5/10 | 6 | 47/21 | 3/7 | 2 | 0 | 4 | - | temas, anahtar, pilot |

- gizli: 0/3 zafer (12 kayıttan devamla), ortalama tespit 74.0
- saldiri: 0/3 zafer, ortalama tespit 9.0
- tam: 0/3 zafer (12 kayıttan devamla), ortalama tespit 74.0
Kazanma oranı: **0/9**
En çok yakalanılan yerler: Ev 3 yakını (74), açık arazi (2700,500) (42), açık arazi (2200,2000) (32), Fırın yakını (24), açık arazi (2500,1900) (14), açık arazi (2000,1900) (12)
Ölüm yerleri: Fırın yakını (4), açık arazi (2700,500) (2), Kilise yakını (2), Ambar yakını (1)
Takılma noktaları: açık arazi (1800,1900) (hedef anahtar_asker), açık arazi (1800,1900) (hedef anahtar_asker)

## bolum2

| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Ceset sakl./bulundu | Taş | Takılma | Yükleme | Puan | Biten görevler |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gizli | 1 | kayip (Çvş. Reilly vuruldu!) | 4:41 | 42 | 623 | 4/6 | 6 | 13/0 | 4/1 | 0 | 1 | 4 | - | temas, telsiz, anahtar, sahin |
| gizli | 2 | kayip (Yzb. Blake öldü! Görev başarısız.) | 4:22 | 31 | 309 | 5/8 | 3 | 14/2 | 6/1 | 0 | 0 | 4 | - | temas, telsiz, anahtar, sahin |
| gizli | 3 | kayip (Yzb. Blake öldü! Görev başarısız.) | 7:27 | 36 | 527 | 14/8 | 6 | 75/3 | 13/2 | 2 | 0 | 4 | - | temas, telsiz, anahtar, sahin |
| saldiri | 1 | kayip (Çvş. Reilly vuruldu!) | 0:47 | 13 | 150 | 4/1 | 6 | 0/0 | 0/3 | 0 | 0 | 0 | - | temas, telsiz |
| saldiri | 2 | kayip (Çvş. Reilly vuruldu!) | 1:01 | 18 | 150 | 7/3 | 6 | 0/0 | 0/7 | 0 | 0 | 0 | - | temas, telsiz |
| saldiri | 3 | kayip (Çvş. Reilly vuruldu!) | 0:59 | 14 | 150 | 2/4 | 6 | 0/0 | 0/6 | 0 | 0 | 0 | - | temas, telsiz |
| tam | 1 | kayip (Çvş. Reilly vuruldu!) | 4:41 | 42 | 623 | 4/6 | 6 | 13/0 | 4/1 | 0 | 1 | 4 | - | temas, telsiz, anahtar, sahin |
| tam | 2 | kayip (Yzb. Blake öldü! Görev başarısız.) | 4:22 | 31 | 309 | 5/8 | 3 | 14/2 | 6/1 | 0 | 0 | 4 | - | temas, telsiz, anahtar, sahin |
| tam | 3 | kayip (Yzb. Blake öldü! Görev başarısız.) | 7:27 | 36 | 527 | 14/8 | 6 | 75/3 | 13/2 | 2 | 0 | 4 | - | temas, telsiz, anahtar, sahin |

- gizli: 0/3 zafer (12 kayıttan devamla), ortalama tespit 36.3
- saldiri: 0/3 zafer, ortalama tespit 15.0
- tam: 0/3 zafer (12 kayıttan devamla), ortalama tespit 36.3
Kazanma oranı: **0/9**
En çok yakalanılan yerler: açık arazi (2700,1200) (44), açık arazi (3400,1000) (38), Komutanlık yakını (34), açık arazi (3100,1200) (32), Kışla binası yakını (10), açık arazi (3000,400) (10)
Ölüm yerleri: açık arazi (3400,1000) (4), açık arazi (2700,1200) (2), açık arazi (1800,1500) (1), açık arazi (2600,1500) (1), açık arazi (2500,1400) (1)
Takılma noktaları: açık arazi (3400,1300) (hedef kodlar), açık arazi (3400,1300) (hedef kodlar)

## bolum3

| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Ceset sakl./bulundu | Taş | Takılma | Yükleme | Puan | Biten görevler |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gizli | 1 | kayip (Çvş. Reilly vuruldu!) | 9:39 | 55 | 509 | 10/11 | 12 | 217/43 | 5/2 | 3 | 0 | 4 | - | temas, golge, trafo, anahtar, sevkiyat, tarife, makas |
| gizli | 2 | kayip (Çvş. Reilly vuruldu!) | 10:21 | 42 | 741 | 11/14 | 12 | 237/11 | 2/5 | 1 | 0 | 4 | - | temas, golge, trafo, anahtar, sevkiyat, tarife, makas, kapi1, kapi2 |
| gizli | 3 | kayip (Çvş. Reilly vuruldu!) | 8:08 | 35 | 571 | 13/11 | 6 | 133/39 | 2/2 | 4 | 0 | 4 | - | temas, golge, trafo, anahtar, sevkiyat, tarife, makas |
| saldiri | 1 | kayip (Henri 'Gölge' Duval öldü! Görev başarısız.) | 0:55 | 12 | 56 | 2/4 | 6 | 0/0 | 0/5 | 0 | 0 | 0 | - | temas, golge, trafo |
| saldiri | 2 | kayip (Çvş. Reilly vuruldu!) | 0:59 | 15 | 150 | 7/2 | 6 | 0/0 | 0/5 | 0 | 0 | 0 | - | temas, golge, trafo, anahtar |
| saldiri | 3 | kayip (Çvş. Reilly vuruldu!) | 1:40 | 17 | 150 | 13/5 | 6 | 0/0 | 0/8 | 0 | 0 | 0 | - | temas, golge, trafo, anahtar, sevkiyat, tarife |
| tam | 1 | kayip (Çvş. Reilly vuruldu!) | 9:39 | 55 | 509 | 10/11 | 12 | 217/43 | 5/2 | 3 | 0 | 4 | - | temas, golge, trafo, anahtar, sevkiyat, tarife, makas |
| tam | 2 | kayip (Çvş. Reilly vuruldu!) | 10:21 | 42 | 741 | 11/14 | 12 | 237/11 | 2/5 | 1 | 0 | 4 | - | temas, golge, trafo, anahtar, sevkiyat, tarife, makas, kapi1, kapi2 |
| tam | 3 | kayip (Çvş. Reilly vuruldu!) | 11:33 | 26 | 532 | 10/7 | 12 | 99/45 | 2/9 | 4 | 0 | 4 | - | temas, golge, trafo, anahtar, sevkiyat, tarife, makas, kapi1, kapi2, yakit |

- gizli: 0/3 zafer (12 kayıttan devamla), ortalama tespit 44.0
- saldiri: 0/3 zafer, ortalama tespit 14.7
- tam: 0/3 zafer (12 kayıttan devamla), ortalama tespit 41.0
Kazanma oranı: **0/9**
En çok yakalanılan yerler: açık arazi (3800,1200) (18), açık arazi (2600,1100) (16), Liman ofisi yakını (15), Denizaltı Bunkeri (içi) (14), açık arazi (4600,500) (12), açık arazi (3200,200) (10)
Ölüm yerleri: açık arazi (2300,1200) (2), Denizaltı Bunkeri yakını (2), açık arazi (5000,1100) (1), Liman ofisi (içi) (1), Liman ofisi yakını (1), açık arazi (4800,600) (1), açık arazi (4600,600) (1)

## bolum4

| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Ceset sakl./bulundu | Taş | Takılma | Yükleme | Puan | Biten görevler |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gizli | 1 | kayip (Çvş. Reilly vuruldu!) | 5:48 | 41 | 583 | 12/4 | 6 | 16/0 | 7/4 | 0 | 0 | 4 | - | temas, anahtar, kivilcim, sinyal |
| gizli | 2 | zafer | 8:20 | 38 | 587 | 16/8 | 6 | 115/0 | 9/3 | 0 | 0 | 4 | 425 | temas, anahtar, kivilcim, sinyal, liste, lokomotif, muhimmat, kacis |
| gizli | 3 | kayip (Onb. Sam 'Kıvılcım' Kowalski öldü! Görev başarısız.) | 5:51 | 39 | 641 | 11/5 | 0 | 17/0 | 7/4 | 0 | 0 | 4 | - | temas, anahtar, kivilcim, sinyal |
| saldiri | 1 | kayip (Çvş. Reilly vuruldu!) | 1:27 | 23 | 200 | 10/4 | 6 | 0/0 | 0/9 | 0 | 0 | 0 | - | temas, anahtar, kivilcim, sinyal |
| saldiri | 2 | kayip (Çvş. Reilly vuruldu!) | 0:43 | 12 | 150 | 7/3 | 6 | 0/0 | 0/8 | 0 | 0 | 0 | - | temas, anahtar |
| saldiri | 3 | kayip (Onb. Sam 'Kıvılcım' Kowalski öldü! Görev başarısız.) | 1:26 | 22 | 172 | 10/4 | 6 | 0/0 | 0/11 | 0 | 0 | 0 | - | temas, anahtar, kivilcim, sinyal |
| tam | 1 | kayip (Çvş. Reilly vuruldu!) | 5:48 | 41 | 583 | 12/4 | 6 | 16/0 | 7/4 | 0 | 0 | 4 | - | temas, anahtar, kivilcim, sinyal |
| tam | 2 | kayip (Çvş. Reilly vuruldu!) | 7:00 | 45 | 800 | 15/5 | 6 | 39/0 | 7/1 | 0 | 0 | 4 | - | temas, anahtar, kivilcim, sinyal, liste, lokomotif, muhimmat |
| tam | 3 | kayip (Onb. Sam 'Kıvılcım' Kowalski öldü! Görev başarısız.) | 5:51 | 39 | 641 | 11/5 | 0 | 17/0 | 7/4 | 0 | 0 | 4 | - | temas, anahtar, kivilcim, sinyal |

- gizli: 1/3 zafer (12 kayıttan devamla), ortalama zafer süresi 8:20, ortalama tespit 39.3
- saldiri: 0/3 zafer, ortalama tespit 19.0
- tam: 0/3 zafer (12 kayıttan devamla), ortalama tespit 41.7
Kazanma oranı: **1/9**, en hızlı zafer 8:20
En çok yakalanılan yerler: açık arazi (1700,2500) (68), açık arazi (1700,2400) (50), Kamp karargâhı yakını (17), açık arazi (2000,2600) (16), açık arazi (1500,2500) (14), açık arazi (1700,2300) (14)
Ölüm yerleri: açık arazi (1600,2300) (2), açık arazi (1700,2300) (2), açık arazi (3000,1200) (1), Nöbet barakası yakını (1), açık arazi (3100,1200) (1), açık arazi (3500,1500) (1)

## bolum5

| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Ceset sakl./bulundu | Taş | Takılma | Yükleme | Puan | Biten görevler |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gizli | 1 | kayip (Çvş. Reilly vuruldu!) | 7:36 | 74 | 1000 | 5/11 | 6 | 141/54 | 5/1 | 5 | 0 | 4 | - | temas, santral, ucak |
| gizli | 2 | kayip (Çvş. Reilly vuruldu!) | 7:03 | 65 | 1000 | 6/9 | 6 | 148/34 | 4/1 | 4 | 0 | 4 | - | temas, santral |
| gizli | 3 | kayip (Çvş. Reilly vuruldu!) | 7:13 | 64 | 1000 | 6/8 | 6 | 166/34 | 4/3 | 3 | 0 | 4 | - | temas, santral, ucak |
| saldiri | 1 | kayip (Çvş. Reilly vuruldu!) | 0:52 | 10 | 150 | 4/4 | 6 | 0/0 | 0/2 | 0 | 0 | 0 | - | temas |
| saldiri | 2 | kayip (Çvş. Reilly vuruldu!) | 0:50 | 13 | 150 | 7/3 | 6 | 0/0 | 0/7 | 0 | 0 | 0 | - | temas |
| saldiri | 3 | kayip (Çvş. Reilly vuruldu!) | 0:28 | 8 | 150 | 0/4 | 6 | 0/0 | 0/2 | 0 | 0 | 0 | - | temas |
| tam | 1 | kayip (Çvş. Reilly vuruldu!) | 7:36 | 74 | 1000 | 5/11 | 6 | 141/54 | 5/1 | 5 | 0 | 4 | - | temas, santral, ucak |
| tam | 2 | kayip (Çvş. Reilly vuruldu!) | 7:03 | 65 | 1000 | 6/9 | 6 | 148/34 | 4/1 | 4 | 0 | 4 | - | temas, santral |
| tam | 3 | kayip (Çvş. Reilly vuruldu!) | 7:13 | 64 | 1000 | 6/8 | 6 | 166/34 | 4/3 | 3 | 0 | 4 | - | temas, santral, ucak |

- gizli: 0/3 zafer (12 kayıttan devamla), ortalama tespit 67.7
- saldiri: 0/3 zafer, ortalama tespit 10.3
- tam: 0/3 zafer (12 kayıttan devamla), ortalama tespit 67.7
Kazanma oranı: **0/9**
En çok yakalanılan yerler: açık arazi (5200,600) (86), açık arazi (5000,1300) (24), açık arazi (5000,1700) (22), açık arazi (5200,1400) (16), açık arazi (5100,1700) (14), açık arazi (5000,600) (14)
Ölüm yerleri: açık arazi (5200,600) (2), açık arazi (5000,1600) (2), açık arazi (5000,1700) (2), Telefon santrali yakını (1), açık arazi (1400,1100) (1), Değirmen yakını (1)

## bolum6

| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Ceset sakl./bulundu | Taş | Takılma | Yükleme | Puan | Biten görevler |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gizli | 1 | kayip (Çvş. Reilly vuruldu!) | 10:38 | 46 | 510 | 12/8 | 12 | 185/43 | 8/4 | 2 | 0 | 4 | - | temas, santral, anahtar, golge |
| gizli | 2 | kayip (Henri 'Gölge' Duval öldü! Görev başarısız.) | 8:28 | 52 | 338 | 14/5 | 6 | 160/25 | 8/1 | 3 | 0 | 4 | - | temas, santral, anahtar, golge |
| gizli | 3 | kayip (Henri 'Gölge' Duval öldü! Görev başarısız.) | 8:31 | 39 | 494 | 9/4 | 6 | 237/30 | 5/2 | 5 | 0 | 4 | - | temas, santral, anahtar, golge |
| saldiri | 1 | kayip (Çvş. Reilly vuruldu!) | 0:29 | 8 | 150 | 0/1 | 0 | 0/0 | 0/1 | 0 | 0 | 0 | - | temas |
| saldiri | 2 | kayip (Çvş. Reilly vuruldu!) | 0:31 | 10 | 150 | 0/2 | 0 | 0/0 | 0/2 | 0 | 0 | 0 | - | temas |
| saldiri | 3 | kayip (Çvş. Reilly vuruldu!) | 0:33 | 11 | 150 | 0/4 | 3 | 0/0 | 0/2 | 0 | 0 | 0 | - | temas |
| tam | 1 | kayip (Çvş. Reilly vuruldu!) | 10:38 | 46 | 510 | 12/8 | 12 | 185/43 | 8/4 | 2 | 0 | 4 | - | temas, santral, anahtar, golge |
| tam | 2 | kayip (Henri 'Gölge' Duval öldü! Görev başarısız.) | 8:28 | 52 | 338 | 14/5 | 6 | 160/25 | 8/1 | 3 | 0 | 4 | - | temas, santral, anahtar, golge |
| tam | 3 | kayip (Henri 'Gölge' Duval öldü! Görev başarısız.) | 8:31 | 39 | 494 | 9/4 | 6 | 237/30 | 5/2 | 5 | 0 | 4 | - | temas, santral, anahtar, golge |

- gizli: 0/3 zafer (12 kayıttan devamla), ortalama tespit 45.7
- saldiri: 0/3 zafer, ortalama tespit 9.7
- tam: 0/3 zafer (12 kayıttan devamla), ortalama tespit 45.7
Kazanma oranı: **0/9**
En çok yakalanılan yerler: açık arazi (1700,1800) (52), açık arazi (2200,2300) (42), açık arazi (2100,2600) (20), açık arazi (4200,2900) (12), açık arazi (3300,3300) (12), açık arazi (1800,1900) (10)
Ölüm yerleri: açık arazi (3300,3300) (4), açık arazi (6300,4100) (2), açık arazi (1500,3200) (2), açık arazi (1600,3100) (1)

## bolum7

| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Ceset sakl./bulundu | Taş | Takılma | Yükleme | Puan | Biten görevler |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gizli | 1 | kayip (Çvş. Reilly vuruldu!) | 7:45 | 54 | 900 | 3/7 | 6 | 16/17 | 6/0 | 3 | 0 | 4 | - | temas, trafo |
| gizli | 2 | kayip (Çvş. Reilly vuruldu!) | 7:20 | 55 | 790 | 1/5 | 6 | 16/6 | 5/0 | 2 | 0 | 4 | - | temas, trafo |
| gizli | 3 | kayip (Çvş. Reilly vuruldu!) | 6:13 | 66 | 750 | 7/12 | 6 | 45/25 | 10/1 | 2 | 0 | 4 | - | temas, trafo |
| saldiri | 1 | kayip (Çvş. Reilly vuruldu!) | 1:00 | 8 | 150 | 2/4 | 6 | 0/0 | 0/4 | 0 | 0 | 0 | - | temas, trafo |
| saldiri | 2 | kayip (Çvş. Reilly vuruldu!) | 0:56 | 7 | 150 | 0/4 | 6 | 0/0 | 0/3 | 0 | 0 | 0 | - | temas, trafo |
| saldiri | 3 | kayip (Çvş. Reilly vuruldu!) | 0:57 | 8 | 150 | 0/4 | 6 | 0/0 | 0/2 | 0 | 0 | 0 | - | temas, trafo |
| tam | 1 | kayip (Çvş. Reilly vuruldu!) | 7:45 | 54 | 900 | 3/7 | 6 | 16/17 | 6/0 | 3 | 0 | 4 | - | temas, trafo |
| tam | 2 | kayip (Çvş. Reilly vuruldu!) | 7:20 | 55 | 790 | 1/5 | 6 | 16/6 | 5/0 | 2 | 0 | 4 | - | temas, trafo |
| tam | 3 | kayip (Çvş. Reilly vuruldu!) | 6:13 | 66 | 750 | 7/12 | 6 | 45/25 | 10/1 | 2 | 0 | 4 | - | temas, trafo |

- gizli: 0/3 zafer (12 kayıttan devamla), ortalama tespit 58.3
- saldiri: 0/3 zafer, ortalama tespit 7.7
- tam: 0/3 zafer (12 kayıttan devamla), ortalama tespit 58.3
Kazanma oranı: **0/9**
En çok yakalanılan yerler: açık arazi (4100,400) (94), açık arazi (3800,700) (24), açık arazi (3700,700) (24), Trafo istasyonu yakını (15), açık arazi (3700,500) (14), açık arazi (4000,400) (12)
Ölüm yerleri: açık arazi (3400,2900) (2), açık arazi (4000,400) (2), açık arazi (2300,2800) (2), Trafo istasyonu yakını (2), açık arazi (2600,1400) (1)

## Bulgular ve öneriler (otomatik)

- bolum0: bot 0:34'da kazandı — bölüm çok kısa/kolay. Görev zincirini uzat, hedefleri birbirinden uzaklaştır, kilitli kapı/anahtar gibi ara adımlar ekle.
- bolum0: gizli bot neredeyse hiç fark edilmiyor — devriye örtüşmesini ve algılamayı artır.
- bolum0: saldırı tarzı kazanabiliyor — tabanca/çatışma oyuncu lehine; asker isabeti, takviye hızı veya mermi kıtlığı ayarlanmalı.
- bolum0: kazanan oyunlarda askerlerin çoğu öldürülüyor — gizlilik ödüllendirilmiyor; ceset bulunması/alarm daha etkili olmalı.
- bolum0: 'Ahır yakını' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.
- bolum1: saldırı tarzı 1 dakikada ölüyor — açık çatışma çok cezalandırıcı olabilir; siper/kaçış yolları ekle.
- bolum1: 'Ev 3 yakını' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.
- bolum2: 'açık arazi (2700,1200)' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.
- bolum3: 'açık arazi (3800,1200)' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.
- bolum4: bot 8:20'da kazandı — bölüm çok kısa/kolay. Görev zincirini uzat, hedefleri birbirinden uzaklaştır, kilitli kapı/anahtar gibi ara adımlar ekle.
- bolum4: 'açık arazi (1700,2500)' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.
- bolum5: saldırı tarzı 1 dakikada ölüyor — açık çatışma çok cezalandırıcı olabilir; siper/kaçış yolları ekle.
- bolum5: 'açık arazi (5200,600)' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.
- bolum6: saldırı tarzı 1 dakikada ölüyor — açık çatışma çok cezalandırıcı olabilir; siper/kaçış yolları ekle.
- bolum6: 'açık arazi (1700,1800)' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.
- bolum7: 'açık arazi (4100,400)' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.

Ham veriler: `build/bot/*.json` (CI'da `bot-raporu` artefaktı).
