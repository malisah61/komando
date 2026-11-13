extends SceneTree
## Tur 6 ekran goruntusu: pencere isareti (4 aci), pencereden girince ic harita, kapi deliginden dar koni.
##   xvfb-run godot -s res://tests/shot_pencere.gd -- --level=res://levels/bolum1.json --out=/tmp/pen

var main
var frame := 0
var opts := {"level": "res://levels/bolum1.json", "out": "/tmp/pen", "w": "-1"}
var wi := -1


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			var kv := a.substr(2).split("=", true, 1)
			opts[kv[0]] = kv[1]
	var M = load("res://scripts/main.gd")
	M.level_choice = opts["level"]
	M.briefed = M.level_choice
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _shot(name: String) -> void:
	root.get_texture().get_image().save_png("%s_%s.png" % [opts["out"], name])


func _process(_delta: float) -> bool:
	frame += 1
	var lvl = main.level
	var c = main.commando
	if frame == 10:
		c.max_hp = 99999
		c.hp = 99999
		wi = int(opts["w"])
		if wi < 0:
			for w in lvl.windows:
				var far: Vector2 = w["ext"] + w["out"] * 200.0
				if lvl.has_los(w["ext"], far) and lvl.interior_of_ext(far) < 0:
					wi = w["i"]
					break
		var w: Dictionary = lvl.windows[wi]
		c.global_position = w["ext"] + w["out"] * 30.0
		c.move_to(c.global_position)
		lvl.window_hint[wi] = 30.0
		main.cam.zoom = Vector2(1.3, 1.3)
		main.cam.position = w["ext"]
		# bir asker pencerenin onunde (kapidan bakista konide gorunsun)
		for g in main.get_tree().get_nodes_in_group("guards"):
			g.set_physics_process(false)
	for k in 4:
		if frame == 20 + k * 20:
			lvl.set_view(k)
			main._view_done(k)
			main.cam.position = lvl.windows[wi]["ext"]
		if frame == 30 + k * 20:
			_shot("disari_aci%d" % k)
	if frame == 100:
		lvl.set_view(0)
		main._view_done(0)
		main.use_window(wi)
	if frame == 190:
		main.cam.zoom = Vector2(0.9, 0.9)
		main.cam.position = c.global_position
		main._clamp_cam()
	if frame == 200:
		_shot("ic")
	if frame == 210:
		var it: Dictionary = lvl.interiors[main.cur_interior]
		c.global_position = it["int_door"]
		var gs: Array = main.get_tree().get_nodes_in_group("guards")
		gs[0].global_position = it["ext_door"] + it["out"] * 180.0
		gs[1].global_position = it["ext_door"] + it["out"] * 200.0 + it["out"].orthogonal() * 260.0
		main.cam.zoom = Vector2(0.9, 0.9)
		main.toggle_peek()
	if frame == 230:
		_shot("delik")
		quit()
	return false
