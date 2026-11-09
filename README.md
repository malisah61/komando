# Komando

Commandos 2: Men of Courage'dan esinlenen, 2. Dünya Savaşı'nda geçen gerçek zamanlı taktik / gizlilik oyunu.

- **Motor:** Godot 4.3 · **Dil:** GDScript (sonra gerekirse performans kritik kısımlar C++ GDExtension)
- **Platformlar:** Web (tarayıcı) ve Android
- **Tarayıcıda oyna:** https://malisah61.github.io/komando/
- **APK:** Actions sekmesi → son "Derle" çalışması → `komando-apk`

## Bölüm 0 – Normandiya Köyü (prototip)
Hedef: Karargâhtaki gizli belgeyi çal ve çıkış bölgesine dön.

| Kontrol | İşlev |
|---|---|
| Dokun / tıkla | Yürü |
| Askere dokun | Arkasından yaklaşıp bıçakla |
| Sürükle | Kamerayı kaydır |
| İki parmak / tekerlek | Yakınlaştır |

Görüş konisine girersen asker şüphelenir (sarı halka). Halka dolarsa alarm çalar. Cesetler de fark edilir.

## Klasörler
- `scripts/main.gd` – harita, yol bulma, görüş hattı, kamera, arayüz
- `scripts/guard.gd` – düşman yapay zekâsı (devriye, görüş, şüphe)
- `scripts/commando.gd` – oyuncu komandosu
- `.github/workflows/build.yml` – otomatik Web + Android derleme
