extends SceneTree
## 4 yonlu bakis ekran goruntuleri (bolum0)

var main
var frame := 0


func _initialize() -> void:
	var M = load("res://scripts/main.gd")
	M.level_choice = "res://levels/bolum0.json"
	M.briefed = M.level_choice
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 20:
		main.cam.zoom = Vector2(0.9, 0.9)
		main.cam.position = Vector2(800, 600)
		main.commando.global_position = Vector2(760, 640)
		main.commando.move_to(Vector2(900, 640))
	for k in 4:
		if frame == 40 + k * 40:
			root.get_texture().get_image().save_png("/tmp/aci%d.png" % k)
			main.rotate_view(1)
			main.cam.position = Vector2(800, 600)
			main._clamp_cam()
	if frame == 40 + 4 * 40 + 5:
		print("view=", main.level.view)
		quit()
	return false
