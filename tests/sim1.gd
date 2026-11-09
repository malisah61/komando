extends SceneTree
## Bolum 1 (genis harita) testi: yollar, devriye noktalari, performans.
##   godot --headless --script res://tests/sim1.gd

var main
var frame := 0
var fails := 0
var t0 := 0
var times: Array = []


func _initialize() -> void:
	load("res://scripts/main.gd").level_choice = "res://levels/bolum1.json"
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func check(cond: bool, msg: String) -> void:
	print(("  OK   " if cond else "  FAIL ") + msg)
	if not cond:
		fails += 1


func _reach(map: RID, a: Vector2, b: Vector2) -> bool:
	var p := NavigationServer2D.map_get_path(map, a, b, true)
	return p.size() > 1 and p[p.size() - 1].distance_to(b) < 14.0


func _physics_process(_delta: float) -> bool:
	frame += 1
	var lvl = main.level
	if frame == 5:
		var map: RID = main.commando.navigation_agent.get_navigation_map()
		check(_reach(map, lvl.start, lvl.document_pos), "baslangic -> planlar")
		check(_reach(map, lvl.document_pos, lvl.exit_rect.get_center()), "planlar -> botlar")
		var bad := 0
		var gi := 0
		for gd in lvl.data["guards"]:
			for p in gd["path"]:
				var v := Vector2(p[0], p[1])
				for poly in lvl.move_polys:
					if Geometry2D.is_point_in_polygon(v, poly):
						print("    devriye noktasi engel icinde: asker ", gi, " ", v)
						bad += 1
				if not _reach(map, lvl.start, v):
					print("    devriye noktasina yol yok: asker ", gi, " ", v)
					bad += 1
			gi += 1
		check(bad == 0, "tum devriye noktalari gecerli (%d asker)" % gi)
		# kamerayi en kalabalik yere (koy) al
		main.cam.position = Vector2(2400, 1200)
		main.cam.zoom = Vector2(0.8, 0.8)
	if frame == 40:
		print("SONUC: ", "BASARILI" if fails == 0 else "%d HATA" % fails)
		quit(1 if fails > 0 else 0)
	return false
