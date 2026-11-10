extends SceneTree
## Basit otomatik test: godot --headless --script res://tests/sim.gd
## Haritayi kurar, navigasyonu, devriyeleri, gorus hattini, ayak izlerini ve
## cati seffafligini kontrol eder.

var main
var frame := 0
var fails := 0
var g_start := {}


func _initialize() -> void:
	load("res://scripts/main.gd").level_choice = "res://levels/bolum0.json"
	load("res://scripts/main.gd").briefed = load("res://scripts/main.gd").level_choice
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func check(cond: bool, msg: String) -> void:
	print(("  OK   " if cond else "  FAIL ") + msg)
	if not cond:
		fails += 1


func _physics_process(_delta: float) -> bool:
	frame += 1
	if frame == 5:
		var lvl = main.level
		var map: RID = main.commando.navigation_agent.get_navigation_map()
		var path := NavigationServer2D.map_get_path(map, lvl.start, lvl.document_pos, true)
		check(path.size() > 1 and path[path.size() - 1].distance_to(lvl.document_pos) < 6, "baslangictan belgeye yol var (%d nokta)" % path.size())
		var p2 := NavigationServer2D.map_get_path(map, lvl.document_pos, lvl.exit_rect.get_center(), true)
		check(p2.size() > 1, "belgeden cikisa yol var")
		check(not lvl.has_los(Vector2(1000, 500), Vector2(1000, 700)), "Ev B duvari gorusu kesiyor")
		check(lvl.has_los(Vector2(970, 860), Vector2(970, 960)), "kum torbasi gorusu kesmiyor")
		check(lvl.is_inside_view_blocker(Vector2(500, 985)), "calilik gizliyor")
		check(lvl.leaves_footprints(Vector2(900, 950)), "camur ayak izi birakir")
		for g in main.get_tree().get_nodes_in_group("guards"):
			g_start[g] = g.global_position
		# komandoyu camurdan gecir
		main.commando.global_position = Vector2(720, 950)
		main.commando.move_to(Vector2(1080, 960))
	if frame == 240:
		for g in g_start:
			if g.waypoints.size() > 1:
				check(g.global_position.distance_to(g_start[g]) > 20, "devriye yuruyor: " + str(g.waypoints[0]))
		check(main.level.footprints.size() > 5, "ayak izleri olustu (%d)" % main.level.footprints.size())
		# komandoyu Ev A'nin icine isinla: cati seffaflasmali
		main.commando.global_position = Vector2(410, 210)
	if frame == 300:
		var roofs = main.get_child(3)
		var faded := false
		for r in roofs.get_children():
			if r.modulate.a < 0.5:
				faded = true
		check(faded, "bina icindeyken cati seffaflasti")
		print("game_over=", main.game_over, " alert=", main.alert_level)
		print("SONUC: ", "BASARILI" if fails == 0 else "%d HATA" % fails)
		quit(1 if fails > 0 else 0)
	return false
