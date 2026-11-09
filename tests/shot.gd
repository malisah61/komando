extends SceneTree
## Ekran goruntusu: xvfb-run godot --rendering-driver opengl3 --script res://tests/shot.gd

var main
var frame := 0


func _initialize() -> void:
	load("res://scripts/main.gd").level_choice = "res://levels/bolum1.json"
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 30:
		main.cam.zoom = Vector2(0.36, 0.36)
		main.cam.position = main.level.size / 2
	if frame == 40:
		root.get_texture().get_image().save_png("/tmp/shot_full.png")
		main.commando.global_position = Vector2(1250, 1050)
		main.commando.move_to(Vector2(1300, 1150))
		main.cam.zoom = Vector2(1.0, 1.0)
		main.cam.position = Vector2(1500, 900)
	if frame == 90:
		root.get_texture().get_image().save_png("/tmp/shot_hq.png")
		main.commando.global_position = Vector2(300, 2300)
		main.commando.move_to(Vector2(600, 2200))
		main.cam.zoom = Vector2(1.6, 1.6)
		main.cam.position = Vector2(380, 2260)
	if frame == 130:
		root.get_texture().get_image().save_png("/tmp/shot_sprite.png")
		quit()
	return false
