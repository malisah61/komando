extends SceneTree
## Bina ici / kapidan bakis / buyuk harita ekran goruntuleri

var main
var frame := 0
var bi := 0


func _initialize() -> void:
	var M = load("res://scripts/main.gd")
	M.level_choice = "res://levels/bolum1.json"
	M.briefed = M.level_choice
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 20:
		for i in main.level.interiors.size():
			if main.level.interiors[i]["name"] == "Karargâh":
				bi = i
		main.enter_building(bi)
	if frame == 60:
		root.get_texture().get_image().save_png("/tmp/shot_ic.png")
		main.toggle_peek()
	if frame == 100:
		root.get_texture().get_image().save_png("/tmp/shot_bak.png")
		main.toggle_peek()
		main.exit_building()
		main.hud.show_big_map()
	if frame == 140:
		root.get_texture().get_image().save_png("/tmp/shot_harita.png")
		quit()
	return false
