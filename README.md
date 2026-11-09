# Komando

Commandos 2: Men of Courage'dan esinlenen, 2. Dünya Savaşı'nda geçen gerçek zamanlı taktik / gizlilik oyunu.

- **Motor:** Godot 4.3 · **Dil:** GDScript
- **Tarayıcıda oyna:** https://malisah61.github.io/komando/
- **APK indir:** https://github.com/malisah61/komando/releases/latest/download/komando.apk

## Bölümler
- **Bölüm 0 – Normandiya Köyü** (eğitim): küçük köy, 6 asker.
- **Bölüm 1 – Nehir Operasyonu**: 3600x2600 geniş harita. Nehir ve iki köprü, çiftlik, köy, duvarlı karargâh, yakıt deposu, ormanlar; 23 asker (er + subay). Planları çal, sahildeki botlara dön. Harita `tools/gen_bolum1.py` ile üretilir.

## Harita render hattı (Blender)
`tools/blender/harita.py` bölüm dosyasından 3D sahneyi kurar (kiremit çatılı evler, pencereler, ağaçlar, çitler, kum torbaları, çadırlar, kamyonlar, tank, nehir, köprüler, çimen detayları) ve oyunun eğik bakış açısıyla render alır:
- `levels/<bölüm>_art/ground.jpg` – zemin (nesnelerin gölgeleri dahil)
- `objects.png` – her nesne ayrı parça; oyunda Y-Sort ile karakterlerle doğru sıralanır
- `roofs.png` – çatılar; binaya girince şeffaflaşır
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
