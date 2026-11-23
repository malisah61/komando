extends SceneTree
## Tur 9 testi (oyuncu geri bildirimi): (1) gozunun onunde caliya girince asker seni hemen unutmaz,
## gormeden girersen gizlenirsin; (2) bicak "tak tak" degil: hamle + toparlanma, seni fark etmis ve sana
## bakan askere tek darbe yok; (3) pencereye tek dokunus yalniz onune goturur, icine sokmaz (cift dokunus girer).
##   godot --headless --script res://tests/sim_denge.gd -- --level=res://levels/bolum1.json

var main
var f := 0
var fails := 0
var step := 0
var wait := 0.0
var lvl_path := "res://levels/bolum1.json"
var g
var g2
var bush := Vector2.ZERO
var _t := 0.0
var _min_d := INF
var wi := -1


func _initialize() -> void:
	seed(9)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--level="):
			lvl_path = a.substr(8)
	var M = load("res://scripts/main.gd")
	M.level_choice = lvl_path
	M.briefed = lvl_path
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func check(cond: bool, msg: String) -> void:
	print(("  OK   " if cond else "  FAIL ") + msg)
	if not cond:
		fails += 1


func _map() -> RID:
	return main.commando.navigation_agent.get_navigation_map()


func _np(p: Vector2) -> Vector2:
	return NavigationServer2D.map_get_closest_point(_map(), p)


func _find_bush() -> Vector2:
	## acik arazide, cevresinde 200 px gorus olan bir cali
	var lvl = main.level
	for o in lvl.data.get("obstacles", []):
		if o.get("type", "") != "bush" or not o.has("circle"):
			continue
		var c := Vector2(o["circle"][0], o["circle"][1])
		if lvl.interior_at(c) >= 0 or not lvl.is_inside_view_blocker(c):
			continue
		if _np(c).distance_to(c) > 4.0:
			continue
		var q := _np(c + Vector2(180, 0))
		if q.distance_to(c + Vector2(180, 0)) < 6.0 and lvl.has_los(q, c, true) and not lvl.is_inside_view_blocker(q):
			return c
	return Vector2.ZERO


func _process(d: float) -> bool:
	f += 1
	if main.hud != null and main.hud.dialog_panel.visible:
		main.hud._next_line()
		main.get_tree().paused = false
	if wait > 0.0:
		wait -= d
		return false
	var c = main.commando
	var lvl = main.level
	match step:
		0:
			if f < 6:
				return false
			c.max_hp = 99999
			c.hp = 99999
			var gs: Array = []
			for x in main.get_tree().get_nodes_in_group("guards"):
				x.set_physics_process(false)
				x.global_position = Vector2(-9000, -9000)
				if x.kind == "er" and gs.size() < 2:
					gs.append(x)
			g = gs[0]
			g2 = gs[1]
			for u in main.team:
				if u != c:
					u.follow = false
					u.set_physics_process(false)
					u.global_position = Vector2(-8000, -8000)
			bush = _find_bush()
			check(bush != Vector2.ZERO, "test icin acik arazide cali bulundu %s" % bush)
			if bush == Vector2.ZERO:
				print("SONUC: %d HATA" % fails)
				quit(1)
				return false
			# (1a) gozunun onunde caliya gir: asker catismada seni gorurken caliya kos
			var gp := _np(bush + Vector2(180, 0))
			g.global_position = gp
			g.facing = PI
			g.base_facing = PI
			g.waypoints = [gp]
			c.global_position = _np(bush + Vector2(50, 50))
			c.move_to(c.global_position)
			# sirene kosan yer tutucu: bu asker alarma kosmasin, catismada kalsin
			g2.state = &"alarm_run"
			g2.alive = true
			main.runner = g2
			g.set_physics_process(true)
			g.enter_combat(c)
			g.investigate_pos = c.global_position
			wait = 0.4
			step = 1
		1:
			# caliya yurur (komando 70 px uzaklikta, asker gozunun onunde)
			c.move_to(bush)
			c.crouch = true
			wait = 1.6
			step = 11
		11:
			check(c.is_hidden(), "komando calida (gizli)")
			_t = 0.0
			_min_d = INF
			step = 2
		2:
			_t += d
			_min_d = minf(_min_d, g.global_position.distance_to(bush))
			if _t > 2.5:
				check(g.state == &"combat" and g.target == c, "gozu onunde caliya giren: asker catismayi birakmadi (2,5 sn)")
				check(_min_d < 150.0, "asker caliya dogru ilerledi (%d px)" % int(_min_d))
				# (1b) hatirlama suresi sinirli: calidan uzaklasinca (calinin icinden) izini kaybeder
				g.set_physics_process(false)
				main.set_alert_level(0)
				g.vigilant_t = 0.0
				g.target = null
				g.state = &"patrol"
				g.suspicion = 0.0
				g._mem_t = 0.0
				g.global_position = _np(bush + Vector2(180, 0))
				g.facing = 0.0             # arkasi caliya donuk: gormeden caliya gir
				g.base_facing = 0.0
				c.global_position = bush
				c.move_to(bush)
				c.crouch = true
				g.set_physics_process(true)
				_t = 0.0
				step = 3
		3:
			_t += d
			if _t > 2.0:
				check(g.state != &"combat" and g.suspicion < 0.3, "gormeden caliya giren gizli kaldi (fark edilmedi) [%s %.2f alarm %d]" % [g.state, g.suspicion, main.alert_level])
				# (1c) arama: calida kaybolan hedef icin ilk arama noktasi cali
				g.investigate_pos = bush
				g._last_dir = Vector2.ZERO
				g._start_search()
				check(g._search_pts.size() > 0 and g._search_pts[0].distance_to(bush) < 20.0, "arama once kaybolunan caliya bakar")
				# (2) bicak: arkadan, habersiz asker -> hamle sonra olur
				g.set_physics_process(false)
				g.state = &"patrol"
				g.suspicion = 0.0
				g.vigilant_t = 0.0
				var p0 := _np(bush + Vector2(300, 200))
				g.global_position = p0
				g.facing = 0.0
				g.base_facing = 0.0
				g.waypoints = [p0]
				c.crouch = true
				c.weapon = "knife"
				c.global_position = _np(p0 + Vector2(-26, 0))      # arkasinda
				c.move_to(c.global_position)
				c._cool = 0.0
				c.attack(g)
				_t = 0.0
				step = 4
		4:
			_t += d
			if _t > 0.12 and not has_meta("h1"):
				set_meta("h1", true)
				check(g.alive, "bicak: hamle suresi var (0,12 sn'de hala ayakta)")
			if not g.alive or _t > 1.5:
				check(not g.alive, "arkadan habersiz asker bicakla oldu (%.2f sn)" % _t)
				check(c._cool > 0.3, "oldurmeden sonra toparlanma suresi (%.2f sn)" % c._cool)
				# hemen yanindaki ikinci asker: toparlanma bitmeden olmez
				var p1: Vector2 = _np(c.global_position + Vector2(0, 26))
				g2.global_position = p1
				g2.facing = PI * 0.5
				g2.base_facing = g2.facing
				g2.waypoints = [p1]
				g2.state = &"patrol"
				main.runner = null
				c.attack(g2)
				_t = 0.0
				step = 5
		5:
			_t += d
			if _t > 0.5 and not has_meta("h2"):
				set_meta("h2", true)
				check(g2.alive, "art arda: toparlanma bitmeden ikinci asker olmedi")
			if not g2.alive or _t > 2.5:
				check(not g2.alive and _t > 0.8, "ikinci asker ancak toparlanmadan sonra (%.2f sn)" % _t)
				# (2b) seni fark etmis ve sana bakan asker: tek darbe yok, bogusma + catisma
				g2.set_physics_process(false)
				var p2 := _np(bush + Vector2(-300, 250))
				var g3 = null
				for x in main.get_tree().get_nodes_in_group("guards"):
					if x.alive and x.kind == "er" and x != g2:
						g3 = x
						break
				g = g3
				g.global_position = p2
				g.waypoints = [p2]
				c.global_position = _np(p2 + Vector2(26, 0))
				c.move_to(c.global_position)
				g.facing = (c.global_position - p2).angle()      # sana bakiyor
				g.base_facing = g.facing
				g.state = &"suspicious"
				g.suspicion = 0.6
				g.investigate_pos = c.global_position
				c._cool = 0.0
				c.attack(g)
				_t = 0.0
				step = 6
		6:
			_t += d
			if _t > 1.0:
				check(g.alive and g.hp < g.max_hp, "fark etmis ve sana bakan askere tek darbe yok: bogusma, yaralandi (%d)" % int(g.hp))
				check(g.state == &"combat" or g.state == &"alarm_run", "bogusma catisma baslatti (%s)" % g.state)
				g.set_physics_process(false)
				g.alive = false
				g.global_position = Vector2(-9000, -9000)
				# (3) pencere: tek dokunus yalniz onune goturur
				main.set_alert_level(0)
				wi = -1
				for w in lvl.windows:
					if not main.is_locked(w["b"]) and _np(w["ext"]).distance_to(w["ext"]) < 4.0:
						wi = w["i"]
						break
				var w: Dictionary = lvl.windows[wi]
				c.global_position = _np(w["ext"] + w["out"] * 120.0)
				c.move_to(c.global_position)
				main._last_tap_t = -10.0
				main._tap(w["pos"])
				_t = 0.0
				step = 7
		7:
			_t += d
			var w: Dictionary = lvl.windows[wi]
			if _t > 3.0:
				check(c.global_position.distance_to(w["ext"]) < 30.0, "tek dokunus: pencerenin onune yurudu")
				check(not c.climbing and main.cur_interior < 0, "tek dokunus: iceri GIRMEDI (girmek icin dugme)")
				# cift dokunus: kos ve gir
				c.global_position = _np(w["ext"] + w["out"] * 120.0)
				c.move_to(c.global_position)
				main._last_tap_t = -10.0
				main._tap(w["pos"])
				main._tap(w["pos"])
				_t = 0.0
				step = 8
		8:
			_t += d
			if _t > 4.0:
				var w: Dictionary = lvl.windows[wi]
				check(main.cur_interior == w["b"], "cift dokunus: kosup pencereden girdi")
				print("SONUC: ", "BASARILI" if fails == 0 else "%d HATA" % fails)
				quit(1 if fails > 0 else 0)
	return false
