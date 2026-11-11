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
