extends SceneTree
## Bolum ekran goruntusu (4 aci): xvfb-run godot -s res://tests/shot_bolum.gd -- --level=res://levels/bolum2.json
##   --cx=3200 --cy=1300 --zoom=0.8 --out=/tmp/b2 --views=0,1
## Kamera noktasina komandoyu da koyar; askerler, koniler, sirenler, kuleler gorunur.

var main
var frame := 0
var opts := {"level": "res://levels/bolum2.json", "cx": "1600", "cy": "1200", "zoom": "0.8", "out": "/tmp/shot", "views": "0,1"}
var views: Array = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			var kv := a.substr(2).split("=", true, 1)
			opts[kv[0]] = kv[1]
	for v in opts["views"].split(","):
		views.append(int(v))
	var M = load("res://scripts/main.gd")
	M.level_choice = opts["level"]
	M.briefed = M.level_choice
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _cam() -> void:
	main.cam.zoom = Vector2(float(opts["zoom"]), float(opts["zoom"]))
	main.cam.position = Vector2(float(opts["cx"]), float(opts["cy"]))
	main._clamp_cam()


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 10:
		var p := Vector2(float(opts["cx"]), float(opts["cy"]))
		var map: RID = main.commando.navigation_agent.get_navigation_map()
		main.commando.global_position = NavigationServer2D.map_get_closest_point(map, p + Vector2(-60, 80))
		main.commando.move_to(main.commando.global_position)
		main.commando.crouch = true
		_cam()
	for i in views.size():
		var at := 40 + i * 40
		if frame == at - 20:
			while main.level.view != views[i]:
				var before: int = main.level.view
				main.rotate_view(1)
				if main.level.view == before:
					break
			_cam()
		if frame == at:
			root.get_texture().get_image().save_png("%s_aci%d.png" % [opts["out"], main.level.view])
	if frame == 40 + views.size() * 40:
		quit()
	return false
