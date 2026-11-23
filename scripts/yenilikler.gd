extends RefCounted
## Oyun ici "Yenilikler" ekrani: her gece turunda en uste 3-5 satir eklenir (en yeni once).

const LIST := [
	["Tur 9 – 23 Kasım 2026 (Oyuncu geri bildirimi)", [
		"Bölüm seçimi artık kaydırılıyor: liste parmakla ya da fareyle sürüklenir, tekerlek de çalışır; en son oynadığın bölüm görünür gelir.",
		"Çalı artık sihirli değil: asker seni gözünün önünde çalıya girerken gördüyse yerini bilir, çalıya ateş eder ve yaklaşır (yaklaşık 6 sn). Görülmeden girersen yine gizlenirsin; arayan asker önce kaybolduğun çalıya bakar.",
		"Bıçak dengelendi: kısa bir hamle ve her öldürmeden sonra toparlanma var, art arda hızlı öldürme yok. Seni fark etmiş ve sana bakan asker tek darbede ölmez: boğuşma çıkar.",
		"Pencere: tek dokunuş seni yalnız pencerenin önüne götürür; girmek için düğmeye bas. Çift dokunuş: koşup gir.",
	]],
	["Tur 8 – 23 Kasım 2026 (Sprite Atölye karakterleri)", [
		"Yeni bölüm: Bölüm 9 – Dağın İçindeki Fabrika (Salzkammergut: dağa oyulmuş jet fabrikası, iki tünel ağzı, işçi kampı, göl iskelesi).",
		"Yeni karakterler Sprite Atölye'de üretildi: dağ avcıları (Gebirgsjäger), beyaz önlüklü mühendisler, işçiler, maden ustabaşı Franz Hofer, Tadeusz Kowal.",
		"Şahin'in artık kendi görünüşü var (kamuflaj önlüğü, sırtında tüfek).",
		"Mühendisler zayıf ve kötü nişancı ama seni görürse alarm verir; baş mühendis ofis anahtarını taşır.",
	]],
	["Tur 7 – 16 Kasım 2026 (Komando: Şahin ekibe katıldı)", [
		"İki komando: Bölüm 8'de Reilly'nin yanında keskin nişancı Şahin (Yzb. Blake). Aralarında geç: sol alttaki ekip düğmeleri, PC'de 1 / 2 ya da Tab.",
		"Seçili olmayan komando seni izler (kapı ve pencereden birlikte geçer) ya da yerinde çömelip bekler: \"İzliyor / Bekliyor\" düğmesi, PC'de F.",
		"Şahin'in dürbünlü tüfeği: çok uzaktan, durup nişan alır (kırmızı nişan çizgisi), tek atışta vurur; mermisi az, sesi duyulur. Çalılıktan dışarı ateş edebilir.",
		"Yeni bölüm: Bölüm 8 – Alp Treni (Tirol, buzlu dere, taş viyadük, Brandt'ın zırhlı treni). Kaçışta iki komando da geçide varmalı.",
	]],
	["Tur 6 – 13 Kasım 2026 (Pencereler ve takip)", [
		"Pencereden gir / çık: her binada, haritadaki pencerelerin yerinde. Pencereye dokun ya da yanına gel; kapıdan biraz yavaş, kısa tırmanma ve ses.",
		"Kilitli binanın pencereleri de kilitli; anahtarla kapı ve pencereler birlikte açılır. Büyük haritada pencereler mavi (kilitliyse turuncu).",
		"Kapı deliğinden bakış gerçekçi: yalnız önündeki dar koni görünür, duvarlar görüşü keser. İçeriden \"Pencereden Bak\" da var.",
		"Seni görüp binaya girdiğini fark eden askerler aynı kapıdan / pencereden peşinden girer; görmediyse dışarıda arar.",
		"Askerler artık arkadan / yandan da yakında yürüyeni ya da koşanı fark eder (önce \"?\", sonra döner). Çömelip zamanlayan yine arkadan bıçaklayabilir.",
	]],
	["Tur 5 – 13 Kasım 2026 (Oynanış derinliği)", [
		"\"Çevir\" artık beklemesiz: her basışta aynı karede döner, \"Çevriliyor…\" yok. PC'de 4 açı yükleme ekranında belleğe alınır.",
		"Üniforma giyme kaldırıldı: gizlilik çalı, gölge, zamanlama ve dikkat dağıtmayla.",
		"Bölüm 6 kılıksız yeniden düzenlendi: yıkık drenaj kanalı, taşla dikkat dağıtma; yerde taş yığınları (üstünden geç, topla).",
		"Yeni bölüm: Bölüm 7 – Sisli Ada (Baltık roket deneme adası, kanal, sazlık, 7 projektör).",
		"Web sürümü kaldırıldı: PC (Windows + Linux) en kaliteli sürüm, Android ikinci sürüm.",
	]],
	["Tur 4 – 12 Kasım 2026 (Sistemler)", [
		"Bölüm içinde kaydet / yükle: 3 elle yuva + hızlı kayıt (F5 / F9) + otomatik kayıt (bölüm başı ve her görevden sonra).",
		"Öldüğünde \"Son kayıttan devam\" ya da istediğin yuvayı seç.",
		"Çatışmada, sirene koşan varken ya da takviye yoldayken kaydedilemez (adil oyun).",
		"Yeni bölüm: Bölüm 6 – Çelik Rampa (V-1 orman üssü, 2. perde başlıyor).",
		"Düzeltme: Bölüm 4–5'te \"önce anahtar\" koşulu artık işliyor.",
	]],
	["Tur 3 – 12 Kasım 2026", [
		"Yumruk + bağlama, ıslık, tel makası, projektörler.",
		"Yapay zekâ v4: tetikte kalma, iz sürme, el bombası, kule gözcüsü, ayılma.",
		"Bölüm 4 – Gece Treni ve Bölüm 5 – Kartal Yuvası.",
		"APK 724 → ~90 MB; \"Çevir\" artık anında.",
	]],
]
