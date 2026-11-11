extends SceneTree
## Bina ici testi: asker kapidan gecerek iceri kacan komandoyu izler; cali yakindan gorulur
##   godot --headless --script res://tests/sim4.gd

var main
var f := 0
var fails := 0
var step := 0
var wait := 0.0
var g
var bi := 0


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
	f += 1
	if wait > 0.0:
		wait -= d
		return false
	var lvl = main.level
	match step:
		0:
			if f < 5:
				return false
			main.commando.max_hp = 9999
			main.commando.hp = 9999
			var guards: Array = main.get_tree().get_nodes_in_group("guards")
			for x in guards:
				x.set_physics_process(false)
			var it: Dictionary = lvl.interiors[bi]
			g = guards[0]
			g.set_physics_process(true)
			g.global_position = it["ext_door"] + it["out"] * 160.0
			main.commando.global_position = it["ext_door"]
			main.enter_building(bi)
			g.investigate_pos = main.commando.global_position
			g.enter_combat(main.commando)
			g.target = main.commando
			step = 1
			wait = 8.0
		1:
			var it: Dictionary = lvl.interiors[bi]
			check(it["irect"].grow(40).has_point(g.global_position), "asker kapidan iceri girip takip etti (%s)" % str(g.global_position))
			# cali testi: komando calida, asker yakin / uzak
			var bush: Vector2 = Vector2.ZERO
			for o in lvl.data.get("obstacles", []):
				if o["type"] == "bush" and o.has("circle"):
					bush = Vector2(o["circle"][0], o["circle"][1])
					break
			if bush != Vector2.ZERO:
				g.global_position = bush + Vector2(300, 0)
				g.facing = PI
				check(not g.can_see(bush, true), "uzaktan calidaki komando gorunmez")
				g.global_position = bush + Vector2(60, 0)
				check(g.can_see(bush, false), "yakindan calidaki komando gorulur")
				g.global_position = bush + Vector2(160, 0)
				main.alert_level = 0
				check(not g.can_see(bush, false), "alarmsiz 160 px: calidaki gorunmez")
				main.alert_level = 2
				check(g.can_see(bush, false), "kirmizi alarmda 160 px: calidaki gorulur")
				main.alert_level = 0
			# cift dokunus: kos
			main.exit_building()
			var p0: Vector2 = main.commando.global_position + Vector2(80, 0)
			main._tap(p0)
			check(not main.commando.run_once, "tek dokunus: yuru")
			main._tap(p0)
			check(main.commando.run_once and main.commando.cur_speed() > main.commando.speed * 1.5, "cift dokunus: kos")
			print("SONUC: ", "BASARILI" if fails == 0 else "%d HATA" % fails)
			quit(1 if fails > 0 else 0)
	return false
