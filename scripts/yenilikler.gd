extends RefCounted
## Oyun ici "Yenilikler" ekrani: her gece turunda en uste 3-5 satir eklenir (en yeni once).

const LIST := [
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
