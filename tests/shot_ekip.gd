extends SceneTree
## Tur 7 ekran goruntusu: Bolum 8, Sahin nisanci yerinde nisan aliyor, Reilly yaninda; ekip dugmeleri; 4 aci.
##   xvfb-run godot -s res://tests/shot_ekip.gd -- --out=/tmp/ekip

var main
var frame := 0
var out := "/tmp/ekip"
var sn
var gz


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	var M = load("res://scripts/main.gd")
	M.level_choice = "res://levels/bolum8.json"
	M.briefed = M.level_choice
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _process(_d: float) -> bool:
	frame += 1
	if frame == 10:
		var spot := Vector2(2330, 1500)
		for o in main.mission.objectives:
			if o.has("spot"):
				spot = Vector2(o["spot"][0], o["spot"][1])
		var rb = main.team[0]
		sn = main.team[1]
		rb.global_position = spot + Vector2(-50, 40)
		rb.move_to(rb.global_position)
		rb.crouch = true
		sn.global_position = spot
		sn.move_to(spot)
		sn.crouch = true
		for g in main.get_tree().get_nodes_in_group("guards"):
			g.set_physics_process(false)
			if g.tag == "gozcu" and gz == null:
				gz = g
		main.select_unit(1)
		main.cam.zoom = Vector2(0.9, 0.9)
		main.cam.position = spot.lerp(gz.global_position, 0.5)
		main._clamp_cam()
	if frame == 14:
		gz.set_physics_process(true)
		sn.attack(gz)
	if frame > 14 and frame < 40 and sn._aim_t > sn.RIFLE_AIM * 0.55:
		frame = 39
	if frame == 40:
		root.get_texture().get_image().save_png("%s_aci0.png" % out)
		sn.set_physics_process(false)       # nisan cizgisi ekranda kalsin
	for k in [1, 2, 3]:
		if frame == 40 + k * 30 - 20:
			main.level.set_view(k)
		if frame == 40 + k * 30:
			main.cam.position = sn.global_position.lerp(gz.global_position, 0.5)
			main._clamp_cam()
		if frame == 44 + k * 30:
			root.get_texture().get_image().save_png("%s_aci%d.png" % [out, k])
	if frame == 160:
		quit()
	return false
