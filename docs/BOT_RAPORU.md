# Bot oyun testi raporu

Tarih: 2026-11-12 00:09 — 12 oyun (gizli, saldiri, tam × 2 tohum).
Bot `tests/bot.gd`: gizli = çömel, devriye bakıyorsa bekle, şüphelenirse geri çekil, arkadan bıçakla; saldırı = tabancayla temizle; tam = gizli + isteğe bağlı görevler.

## bolum0

| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Takılma | Biten görevler |
|---|---|---|---|---|---|---|---|---|---|---|
| gizli | 1 | zafer | 0:40 | 6 | 20 | 3/5 | 3 | 5/20 | 0 | belge, kacis |
| gizli | 2 | zafer | 0:38 | 2 | 8 | 5/2 | 3 | 3/1 | 0 | belge, kacis |
| saldiri | 1 | zafer | 0:33 | 10 | 39 | 3/4 | 3 | 0/0 | 0 | belge, kacis |
| saldiri | 2 | zafer | 0:33 | 9 | 71 | 4/4 | 3 | 0/0 | 0 | belge, kacis |
| tam | 1 | zafer | 0:40 | 6 | 20 | 3/5 | 3 | 5/20 | 0 | belge, kacis |
| tam | 2 | zafer | 0:38 | 2 | 8 | 5/2 | 3 | 3/1 | 0 | belge, kacis |

Kazanma oranı: **6/6**, en hızlı zafer 0:33
En çok yakalanılan yerler: Kilise yakını (20), Ev B yakını (9), Ahır yakını (4), Karargâh (içi) (1), açık arazi (700,400) (1)

## bolum1

| Tarz | Tohum | Sonuç | Süre | Tespit | Hasar | Bıçak/Tabanca | Takviye | Bekleme/Geri | Takılma | Biten görevler |
|---|---|---|---|---|---|---|---|---|---|---|
| gizli | 1 | kayip (Çvş. Reilly vuruldu!) | 2:19 | 19 | 150 | 12/5 | 12 | 33/31 | 0 | temas, pilot, planlar, kopru |
| gizli | 2 | zafer | 2:31 | 17 | 148 | 14/5 | 6 | 35/45 | 0 | temas, pilot, planlar, kopru, kacis |
| saldiri | 1 | kayip (Çvş. Reilly vuruldu!) | 0:34 | 14 | 150 | 7/5 | 6 | 0/0 | 0 | temas |
| saldiri | 2 | kayip (Çvş. Reilly vuruldu!) | 0:32 | 14 | 150 | 0/6 | 6 | 0/0 | 0 | temas |
| tam | 1 | zafer | 3:21 | 10 | 131 | 18/5 | 12 | 41/46 | 0 | temas, pilot, planlar, kopru, depo, kacis |
| tam | 2 | zafer | 3:18 | 9 | 112 | 18/5 | 6 | 27/40 | 0 | temas, pilot, planlar, kopru, depo, kacis |

Kazanma oranı: **3/6**, en hızlı zafer 2:31
En çok yakalanılan yerler: açık arazi (1700,1900) (14), açık arazi (2900,700) (10), Ev 3 yakını (9), açık arazi (1800,1600) (9), Ambar yakını (8), açık arazi (1800,1500) (5)
Ölüm yerleri: açık arazi (1800,1800) (1), açık arazi (2000,1900) (1), açık arazi (1900,1800) (1)

## Bulgular ve öneriler (otomatik)

- bolum0: bot 0:33'da kazandı — bölüm çok kısa/kolay. Görev zincirini uzat, hedefleri birbirinden uzaklaştır, kilitli kapı/anahtar gibi ara adımlar ekle.
- bolum0: saldırı tarzı kazanabiliyor — tabanca/çatışma oyuncu lehine; asker isabeti, takviye hızı veya mermi kıtlığı ayarlanmalı.
- bolum0: saldırı tarzı 1 dakikada ölüyor — açık çatışma çok cezalandırıcı olabilir; siper/kaçış yolları ekle.
- bolum0: kazanan oyunlarda askerlerin çoğu öldürülüyor — gizlilik ödüllendirilmiyor; ceset bulunması/alarm daha etkili olmalı.
- bolum0: 'Kilise yakını' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.
- bolum1: bot 2:31'da kazandı — bölüm çok kısa/kolay. Görev zincirini uzat, hedefleri birbirinden uzaklaştır, kilitli kapı/anahtar gibi ara adımlar ekle.
- bolum1: saldırı tarzı 1 dakikada ölüyor — açık çatışma çok cezalandırıcı olabilir; siper/kaçış yolları ekle.
- bolum1: kazanan oyunlarda askerlerin çoğu öldürülüyor — gizlilik ödüllendirilmiyor; ceset bulunması/alarm daha etkili olmalı.
- bolum1: 'açık arazi (1700,1900)' tespit noktası — buraya alternatif gizli yol (çalı, siper, arka kapı) ekle ya da kasıtlı darboğaz olduğunu belgele.

Ham veriler: `build/bot/*.json` (CI'da `bot-raporu` artefaktı).
