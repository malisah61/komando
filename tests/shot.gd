extends SceneTree
## Ekran goruntusu: xvfb-run godot --rendering-driver opengl3 --script res://tests/shot.gd

var main
var frame := 0


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 30:
		main.cam.zoom = Vector2(0.62, 0.62)
		main.cam.position = main.level.size / 2
	if frame == 40:
		root.get_texture().get_image().save_png("/tmp/shot_full.png")
		main.commando.global_position = Vector2(1250, 200)
		main.cam.zoom = Vector2(1.3, 1.3)
		main.cam.position = Vector2(1200, 260)
	if frame == 90:
		root.get_texture().get_image().save_png("/tmp/shot_hq.png")
		main.commando.global_position = Vector2(620, 440)
		main.commando.move_to(Vector2(900, 470))
		main.cam.zoom = Vector2(1.6, 1.6)
		main.cam.position = Vector2(640, 430)
	if frame == 130:
		root.get_texture().get_image().save_png("/tmp/shot_sprite.png")
		quit()
	return false
