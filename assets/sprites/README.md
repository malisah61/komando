# Sprite sheet'ler

Buraya atılan sheet'ler oyun açılırken otomatik tanımlanır (`scripts/sprite_sheet.gd`).

| Dosya | Kime bağlanır |
|---|---|
| `commandos_sprite_sheet.png` | Oyuncu komandosu (Yeşil Bere) |
| `enemy_sprite_sheet.png` | Alman askerleri |

## Varsayılan düzen: 4x4 grid, her kare 32x32 piksel (toplam 128x128)

| Satır | Animasyon | Döngü |
|---|---|---|
| 0 | `idle` – bekleme | evet |
| 1 | `walk` – yürüme | evet |
| 2 | `action` – bıçak / ateş | hayır |
| 3 | `death` – ölüm | hayır |

- Karakter **sağa bakmalı**; sola yürürken oyun otomatik aynalar.
- Ayaklar karenin **alt kenarına** değmeli, arka plan **saydam** olmalı.
- Tamamen boş kareler atlanır (3 kareli satır sorun değil).

## Farklı düzen
Aynı adla bir `.json` koy, örn. `commandos_sprite_sheet.json`:
```json
{"frame": 64, "cols": 6, "fps": 10,
 "anims": {"idle": [0], "walk": [1, 2], "action": [3], "death": [4]}}
```
`anims` içindeki sayılar satır numarasıdır.

Şu anki iki dosya yer tutucudur (geçici); kendi çizimlerinle üzerine yaz.
