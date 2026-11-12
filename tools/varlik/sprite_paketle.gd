extends SceneTree
## Karakter sprite'larini platforma gore VRAM bicimine (ETC2 = telefon, S3TC = PC/Web) sikistirip
## zstd ile sikistirilmis .res olarak paketler. Godot APK'da .ctex dosyalarini sikistirmadan sakliyor
## (8,4 MB/sayfa); ayni veri .res icinde zstd ile ~1,4 MB. Bellekte yine VRAM bicimi (telefonda 4x az).
##   godot --headless -s res://tools/varlik/sprite_paketle.gd      (CI: import'tan sonra, export'tan once)
## Cikti: res://assets/sprites/paket/<ad>_etc2.res ve <ad>_s3tc.res (git'e girmez, CI uretir)

var hata := 0


func _initialize() -> void:
	var dir := "res://assets/sprites/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir + "paket"))
	var total := [0, 0]
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with("_sprite_sheet.png"):
			continue
		var src := Image.load_from_file(ProjectSettings.globalize_path(dir + f))
		if src == null or src.is_empty():
			push_error("okunamadi: " + f)
			hata += 1
			continue
		src.convert(Image.FORMAT_RGBA8)
		src.fix_alpha_edges()           # Godot import'undaki "fix_alpha_border": saydam kenarda hale olmasin
		for fmt in [["etc2", Image.COMPRESS_ETC2], ["s3tc", Image.COMPRESS_S3TC]]:
			var img := src.duplicate()
			var err: int = img.compress(fmt[1], Image.COMPRESS_SOURCE_GENERIC)
			if err != OK:
				push_error("sikistirilamadi %s %s" % [f, fmt[0]])
				hata += 1
				continue
			var tex := ImageTexture.create_from_image(img)
			var out: String = dir + "paket/" + f.get_basename() + "_" + fmt[0] + ".res"
			ResourceSaver.save(tex, out, ResourceSaver.FLAG_COMPRESS)
			var sz := FileAccess.get_file_as_bytes(out).size()
			total[0 if fmt[0] == "etc2" else 1] += sz
			print("%s -> %s %.2f MB (bicim %d)" % [f, out.get_file(), sz / 1048576.0, img.get_format()])
	print("TOPLAM etc2 %.1f MB, s3tc %.1f MB" % [total[0] / 1048576.0, total[1] / 1048576.0])
	quit(1 if hata > 0 else 0)
