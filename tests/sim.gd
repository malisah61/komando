extends SceneTree
## Basit otomatik test: godot --headless --script res://tests/sim.gd
## Haritayi kurar, navigasyonu, devriyeleri, gorus hattini, ayak izlerini ve
## cati seffafligini kontrol eder.

var main
var frame := 0
var fails := 0
var g_start := {}
var had := false


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
		check(lvl.reach(map, lvl.start, lvl.document_pos), "baslangictan belgeye yol var (kapilardan)")
		check(lvl.reach(map, lvl.document_pos, lvl.exit_rect.get_center()), "belgeden cikisa yol var")
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
		# bina ici artik ayri harita: Ev A'ya kapidan gir
		var bi: int = main.level.interior_of_ext(Vector2(410, 210))
		check(bi >= 0, "Ev A'nin ic haritasi var")
		if bi >= 0:
			main.enter_building(bi)
	if frame == 300:
		check(main.cur_interior >= 0 and main.level.interiors[main.cur_interior]["irect"].has_point(main.commando.global_position), "Ev A'nin icindeyiz (ayri ekran)")
		# 4 yonlu bakis: aci yoksa cevirme reddedilir, varsa doner
		had = main.level.has_view(1)
		main.rotate_view(1)
	if frame == 330:
		check(main.level.view == (1 if had else 0), "bakis acisi cevirme (%s)" % ("render var" if had else "render yok, reddedildi"))
	if frame == 330:
		print("game_over=", main.game_over, " alert=", main.alert_level)
		print("SONUC: ", "BASARILI" if fails == 0 else "%d HATA" % fails)
		quit(1 if fails > 0 else 0)
	return false
