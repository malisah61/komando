extends SceneTree
## Kayit arayuzu ekran goruntuleri (Tur 4): xvfb-run godot -s res://tests/shot_kayit.gd -- --level=res://levels/bolum4.json --out=/tmp/k
##   1) oyun + "Kayit" dugmesi  2) kayit paneli  3) olum ekrani + "Son kayittan devam"
const Kayit = preload("res://scripts/kayit.gd")
var main
var frame := 0
var opts := {"level": "res://levels/bolum4.json", "out": "/tmp/kayit"}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			var kv := a.substr(2).split("=", true, 1)
			opts[kv[0]] = kv[1]
	Kayit.dir_override = "user://shot_kayit"
	DirAccess.make_dir_recursive_absolute(Kayit.dir_override)
	var M = load("res://scripts/main.gd")
	M.level_choice = opts["level"]
	M.briefed = M.level_choice
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _shot(name: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	img.save_jpg(opts["out"] + "_" + name + ".jpg", 0.85)
	print("kaydedildi ", opts["out"] + "_" + name + ".jpg")


func _process(_d: float) -> bool:
	frame += 1
	if frame == 40:
		main.mission.elapsed = 200.0
		Kayit.save(main, "1")
		main.mission.elapsed = 260.0
		Kayit.save(main, "hizli")
	if frame == 60:
		_shot("1_oyun")
		main.hud.show_saves()
	if frame == 75:
		_shot("2_panel")
		main.hud._close_saves()
		main.lose("Çvş. Reilly vuruldu!")
	if frame == 90:
		_shot("3_olum")
		quit()
	return false
