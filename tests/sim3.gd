extends SceneTree
## Catisma testi (Bolum 1): yakalaninca oyun bitmez; askerler ates eder, can azalir,
## kirmizi alarmda kisladan takviye cikar, tabanca ile asker vurulur, ceset tasinir.
##   godot --headless --script res://tests/sim3.gd

var main
var step := 0
var wait := 0.0
var fails := 0
var g0
var hp0 := 0.0
var n0 := 0


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


func _process(d: float) -> bool:
	if wait > 0.0:
		wait -= d
		return false
	match step:
		0:
			wait = 0.3
			step = 1
		1:
			# kisla konumlari gezilebilir mi
			var map: RID = main.commando.navigation_agent.get_navigation_map()
			for bk in main.barracks:
				var cp := NavigationServer2D.map_get_closest_point(map, bk[0])
				check(cp.distance_to(bk[0]) < 20.0, "kisla gezilebilir alanda %s" % bk[0])
			# karargah kapisindaki nobetcinin onune cik
			var gate: Vector2 = Vector2(2990, 710)
			for g in main.get_tree().get_nodes_in_group("guards"):
				if g.global_position.distance_to(gate) < 20.0:
					g0 = g
			check(g0 != null, "kapi nobetcisi bulundu")
			main.commando.global_position = g0.global_position + Vector2(0, 120)
			main.commando.move_to(main.commando.global_position)
			main.commando.max_hp = 5000.0
			main.commando.hp = 5000.0
			hp0 = main.commando.hp
			n0 = main.get_tree().get_nodes_in_group("guards").size()
			step = 2
			wait = 12.0      # Tur 2: once bir asker sirene kosar, sonra takviye cikar
		2:
			check(not main.game_over or main.commando.hp <= 0.0, "fark edilince oyun bitmedi")
			check(g0.state == &"combat", "asker catismaya girdi")
			check(main.alert_level == 2, "kirmizi alarm caldi")
			check(main.commando.hp < hp0, "komando vuruldu (can %d)" % main.commando.hp)
			var n1: int = main.get_tree().get_nodes_in_group("guards").size()
			check(n1 > n0, "kisladan takviye cikti (%d -> %d)" % [n0, n1])
			var far := 0
			for g in main.get_tree().get_nodes_in_group("guards"):
				if not g.reinforcement and g.state == &"patrol":
					far += 1
			check(far > 8, "uzaktaki askerler yerinde kaldi (%d devriyede)" % far)
			# tabanca ile karsilik ver
			main.commando.weapon = "pistol"
			main.commando.attack(g0)
			step = 3
			wait = 3.0
		3:
			check(not g0.alive or g0.hp < g0.max_hp, "tabanca ile asker vuruldu (can %d)" % g0.hp)
			if g0.alive:
				g0.kill()
			# ceset tasima
			main.commando.global_position = g0.global_position + Vector2(10, 0)
			var b = main.commando.body_nearby()
			check(b != null, "yakindaki ceset bulundu")
			main.commando.pick_body(b)
			main.commando.global_position = Vector2(3200, 1500)
			main.commando._carry_follow()
			main.commando.drop_body()
			check(b.global_position.distance_to(Vector2(3200, 1500)) < 30.0, "ceset tasinip birakildi")
			print("SONUC: ", "BASARILI" if fails == 0 else "%d HATA" % fails)
			quit(1 if fails > 0 else 0)
	return false
