extends SceneTree
var main; var f := 0; var t0 := 0
func _initialize():
	load("res://scripts/main.gd").level_choice = OS.get_environment("LVL")
	load("res://scripts/main.gd").briefed = load("res://scripts/main.gd").level_choice
	main = load("res://scenes/main.tscn").instantiate(); root.add_child(main)
func _process(_d):
	f += 1
	if f == 5:
		main.cam.position = Vector2(OS.get_environment("CX").to_float(), OS.get_environment("CY").to_float()); main.cam.zoom = Vector2(0.8, 0.8)
	if f == 30: t0 = Time.get_ticks_usec()
	if f == 330:
		print("ortalama kare: ", (Time.get_ticks_usec() - t0) / 300000.0, " ms")
		quit()
	return false
