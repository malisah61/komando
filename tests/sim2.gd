extends SceneTree
## Bolum 1 gorev zinciri testi (askerler devre disi):
##   direnisci -> patlayici, pilot -> takip, planlar, kopru patlatma (yol kesilir), cikis -> zafer
##   godot --headless --script res://tests/sim2.gd

var main
var f := 0
var fails := 0
var step := 0
var wait := 0.0


func _initialize() -> void:
	var M = load("res://scripts/main.gd")
	M.level_choice = "res://levels/bolum1.json"
	M.briefed = M.level_choice
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func check(cond: bool, msg: String) -> void:
	print(("  OK   " if cond else "  FAIL ") + msg)
	if not cond:
		fails += 1


func _skip_dialog() -> void:
	var guard := 0
	while main.hud.dialog_panel.visible and guard < 20:
		main.hud._next_line()
		guard += 1


func _tp(p: Vector2) -> void:
	main.commando.global_position = p
	main.commando.move_to(p)


func _process(_d: float) -> bool:
	f += 1
	if wait > 0.0:
		wait -= _d
		return false
	var m = main.mission
	match step:
		0:
			if f > 5:
				for g in main.get_tree().get_nodes_in_group("guards"):
					g.set_physics_process(false)
				# bina ici: gir / kapidan bak / cik
				var bi := -1
				for i in main.level.interiors.size():
					if main.level.interiors[i]["name"] == "Karargâh":
						bi = i
				if bi < 0:
					bi = 0
				var it: Dictionary = main.level.interiors[bi]
				main.enter_building(bi)
				check(main.cur_interior == bi and it["irect"].has_point(main.commando.global_position), "binaya girildi: %s (ayri ic harita)" % it["name"])
				check(not Rect2(Vector2.ZERO, main.level.size).has_point(main.cam.position), "kamera ic haritada (dis harita gorunmuyor)")
				main.toggle_peek()
				check(main.peeking and main.cam.position.distance_to(it["ext_door"]) < 400.0 and main.hud.peek_rect.visible, "kapidan bakis disariyi gosteriyor")
				main.toggle_peek()
				main.exit_building()
				check(main.cur_interior < 0 and main.commando.global_position.distance_to(it["ext_door"]) < 20.0, "binadan cikildi")
				main.hud.show_big_map()
				check(main.hud._bigmap != null and main.get_tree().paused, "buyuk harita acildi")
				main.hud.close_big_map()
				_tp(m.npcs["pierre"].global_position + Vector2(24, 0))
				step = 1
				wait = 0.17
		1:
			check(main.hud.dialog_panel.visible, "Pierre ile konusma acildi (oyun durdu: %s)" % main.get_tree().paused)
			_skip_dialog()
			check(m.items.get("patlayici", 0) == 2, "2 patlayici alindi")
			m.items["belediye_anahtari"] = 1     # Tur 2: belediye kilitli (anahtar subayda)
			_tp(m.npcs["carter"].global_position + Vector2(24, 0))
			step = 2
			wait = 0.17
		2:
			_skip_dialog()
			check(m.npcs["carter"].following, "pilot takip ediyor")
			_tp(_ob("planlar")["pos"][0] * Vector2.RIGHT + _ob("planlar")["pos"][1] * Vector2.DOWN)
			step = 3
			wait = 0.17
		3:
			_skip_dialog()
			check(_ob("planlar")["done"], "planlar alindi")
			var bp: Vector2 = Vector2(_ob("kopru")["pos"][0], _ob("kopru")["pos"][1])
			_tp(bp + Vector2(-60, 0))
			main.mission.npcs["carter"].global_position = bp + Vector2(-400, 300)
			step = 4
			wait = 0.08
		4:
			check(m.plant_target != null, "kopru menzilinde 'Patlayici Kur' cikti")
			m.start_planting()
			step = 45
			wait = 0.05
		45:
			print("    planting=", m.planting, " vel=", main.commando.velocity, " target=", m.plant_target != null, " paused=", main.get_tree().paused)
			step = 5
			wait = 2.50
		5:
			check(m.bombs.size() == 1, "patlayici kuruldu, geri sayim basladi")
			_tp(Vector2(1300, 1000))
			main.mission.npcs["carter"].global_position = Vector2(1330, 1000)
			step = 6
			wait = 9.33
		6:
			_skip_dialog()
			check(_ob("kopru")["done"], "kopru havaya ucuruldu")
			var map: RID = main.commando.navigation_agent.get_navigation_map()
			var p := NavigationServer2D.map_get_path(map, Vector2(1500, 745), Vector2(2100, 745), true)
			var len := 0.0
			for i in range(1, p.size()):
				len += p[i - 1].distance_to(p[i])
			check(len > 1500.0, "kopru yikilinca yol uzadi (guneyden dolasma: %d px)" % len)
			check(not main.game_over, "komando patlamadan sag kurtuldu")
			var ex: Vector2 = main.level.exit_rect.get_center()
			_tp(ex)
			main.mission.npcs["carter"].global_position = ex + Vector2(30, 0)
			step = 7
			wait = 0.33
		7:
			check(main.game_over and main.commando.alive, "gorev tamamlandi (zafer)")
			print("SONUC: ", "BASARILI" if fails == 0 else "%d HATA" % fails)
			quit(1 if fails > 0 else 0)
	return false


func _ob(id: String) -> Dictionary:
	for o in main.mission.objectives:
		if o["id"] == id:
			return o
	return {}
