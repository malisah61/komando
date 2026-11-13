extends SceneTree
## Tur 6 testi: pencereden giris/cikis (kapidan yavas), kilitli binanin pencereleri, gercekci anahtar deligi
## (dar koni + has_los), pesinden girme (gordu -> girdi, gormedi -> girmedi), koni disinda yakindan fark etme
## ve comelerek arkadan bicaklama.
##   godot --headless --script res://tests/sim_pencere.gd -- --level=res://levels/bolum1.json

var main
var f := 0
var fails := 0
var step := 0
var wait := 0.0
var g
var wi := -1
var bi := -1
var lvl_path := "res://levels/bolum1.json"
var _t := 0.0
var _seen_near := false
var _turned := false
var g2b


func _initialize() -> void:
	seed(61)
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


func _guards() -> Array:
	var out: Array = []
	for x in main.get_tree().get_nodes_in_group("guards"):
		if x.kind != "kule" and x.alive:
			out.append(x)
	return out


func _freeze_all() -> void:
	for x in _guards():
		x.set_physics_process(false)
		x.global_position = Vector2(-5000, -5000)


func _pick_window(locked: bool) -> int:
	## onu acik (150 px disari LOS'u olan) bir pencere
	var lvl = main.level
	for w in lvl.windows:
		var lk: bool = main.is_locked(w["b"])
		if lk != locked:
			continue
		var far: Vector2 = w["ext"] + w["out"] * 150.0
		if lvl.has_los(w["ext"], far) and not lvl.is_inside_view_blocker(far) and lvl.interior_of_ext(far) < 0:
			return w["i"]
	return -1


func _process(d: float) -> bool:
	f += 1
	if wait > 0.0:
		wait -= d
		return false
	var lvl = main.level
	var c = main.commando
	match step:
		0:
			if f < 6:
				return false
			c.max_hp = 99999
			c.hp = 99999
			_freeze_all()
			wi = _pick_window(false)
			check(wi >= 0, "acik onu olan kilitsiz pencere var (%d pencere)" % lvl.windows.size())
			var w: Dictionary = lvl.windows[wi]
			bi = w["b"]
			c.global_position = w["ext"]
			c.move_to(w["ext"])
			main.use_window(wi)
			check(c.climbing, "pencereye tirmaniyor")
			wait = 0.3
			step = 1
		1:
			check(main.cur_interior < 0, "0,3 sn sonra hala disarida (pencere kapidan yavas)")
			wait = 1.2
			step = 2
		2:
			var w: Dictionary = lvl.windows[wi]
			check(main.cur_interior == bi and c.global_position.distance_to(w["int"]) < 30.0, "pencereden iceri girdi (%s)" % lvl.interiors[bi]["name"])
			check(not c.climbing, "tirmanma bitti")
			# icten pencereden cik
			main.use_window(wi)
			wait = 1.4
			step = 3
		3:
			var w: Dictionary = lvl.windows[wi]
			check(main.cur_interior < 0 and c.global_position.distance_to(w["ext"]) < 30.0, "pencereden disari cikti")
			# kilitli bina: pencere de kilitli; anahtarla kapi + pencereler birlikte acilir
			var lwi := -1
			for w2 in lvl.windows:
				if main.is_locked(w2["b"]):
					lwi = w2["i"]
					break
			if lwi < 0:
				print("  (bu bolumde kilitli bina yok: kilit testi atlandi)")
				step = 5
				return false
			var lw: Dictionary = lvl.windows[lwi]
			c.global_position = lw["ext"]
			main.use_window(lwi)
			check(not c.climbing and main.cur_interior < 0, "kilitli binanin penceresinden girilmez")
			var lk: String = lvl.interiors[lw["b"]]["locked"]
			main.mission.items[lk] = 1
			check(not main.is_locked(lw["b"]) and not main.window_locked(lwi), "anahtarla kapi ve pencereler birlikte acildi")
			main.use_window(lwi)
			wi = lwi
			bi = lw["b"]
			wait = 1.4
			step = 4
		4:
			check(main.cur_interior == bi, "anahtardan sonra pencereden girildi")
			main.use_window(wi)
			wait = 1.4
			step = 5
		5:
			# ---------------- anahtar deligi: dar koni + duvarlar keser ----------------
			wi = _pick_window(false)
			var w: Dictionary = lvl.windows[wi]
			bi = w["b"]
			var it: Dictionary = lvl.interiors[bi]
			c.global_position = it["int_door"]
			main.cur_interior = bi
			main.toggle_peek()
			var pm = main.peek_mask
			check(main.peeking and pm != null and pm.visible, "kapidan bakis acildi")
			var o: Vector2 = it["out"]
			var from: Vector2 = pm.from
			var ahead: Vector2 = from + o * 140.0
			if lvl.has_los(from, ahead):
				check(pm.lit(ahead), "kapinin tam onu gorunur")
			check(not pm.lit(from + o.orthogonal() * 200.0), "kapinin yani (koni disi) karanlik")
			check(not pm.lit(from + (o + o.orthogonal()).normalized() * 220.0), "45 derece yan karanlik (koni ~40 derece)")
			check(not pm.lit(from + o * 900.0), "cok uzak karanlik (menzil)")
			check(not pm.lit(it["rect"].get_center()), "binanin ici / duvar arkasi karanlik")
			# duvarin arkasi: konideki ilk engel
			var hit: Vector2 = lvl.ray_end(from, from + o * 520.0)
			if hit.distance_to(from + o * 520.0) > 30.0:
				check(not pm.lit(hit + o * 40.0), "engelin arkasi karanlik (has_los)")
			var cam0: Vector2 = main.cam.position
			check(cam0.distance_to(from) < 400.0, "kamera delikten bakilan yere bagli")
			main.toggle_peek()
			check(not main.peeking and not pm.visible, "bakis kapandi")
			main.cur_interior = -1
			# ---------------- pesinden girme: gordu -> girdi ----------------
			g = _guards()[0]
			g.set_physics_process(true)
			g.global_position = w["ext"] + w["out"] * 150.0
			g.waypoints = [g.global_position]
			c.global_position = w["ext"]
			c.move_to(w["ext"])
			g.enter_combat(c)
			g.state = &"combat"
			g.target = c
			var gb = _guards()[4]
			gb.set_physics_process(true)
			gb.global_position = w["ext"] + w["out"] * 120.0
			if not lvl.has_los(gb.global_position, w["ext"]):
				gb.global_position = w["ext"] + w["out"] * 100.0
			gb.waypoints = [gb.global_position]
			gb.enter_combat(c)
			gb.state = &"combat"
			gb.target = c
			main.runner = null
			lvl.sirens.clear()        # sirene kosmasin: yalniz takip olculsun
			main.use_window(wi)
			check(g.state == &"pursue" and gb.state == &"pursue", "goren iki asker pesinden geliyor (durum %s, %s)" % [g.state, gb.state])
			g2b = gb
			wait = 7.0
			_t = 0.0
			step = 6
		6:
			check(lvl.interior_at(g.global_position) == bi and lvl.interior_at(g2b.global_position) == bi, "iki asker de pencereden pesinden iceri girdi (%s)" % str(g.global_position))
			check(g.state != &"patrol", "iceride ariyor / catisiyor (%s)" % g.state)
			g2b.global_position = Vector2(-5000, -5000)
			g2b.set_physics_process(false)
			# ---------------- gormedi -> girmedi ----------------
			main.use_window(wi)
			wait = 1.4
			step = 7
		7:
			var w: Dictionary = lvl.windows[wi]
			var it: Dictionary = lvl.interiors[bi]
			g.global_position = Vector2(-5000, -5000)
			g.set_physics_process(false)
			var g2 = _guards()[1]
			g2.set_physics_process(true)
			# binanin karsi tarafinda: bina gorusu keser
			var back: Vector2 = it["rect"].get_center() - w["out"] * (maxf(it["rect"].size.x, it["rect"].size.y) * 0.5 + 70.0)
			back = NavigationServer2D.map_get_closest_point(c.navigation_agent.get_navigation_map(), back)
			g2.global_position = back
			g2.waypoints = [back]
			check(not lvl.has_los(back, c.global_position), "ikinci asker binanin arkasinda (gorus yok)")
			g2.enter_combat(c)
			g2.investigate_pos = back + (c.global_position - back).normalized() * 40.0
			main.use_window(wi)
			check(g2.state != &"pursue", "gormeyen asker pesinden gelmiyor")
			g = g2
			wait = 9.0
			step = 8
		8:
			check(lvl.interior_at(g.global_position) < 0, "gormeyen asker iceri girmedi, disarida ariyor (%s)" % g.state)
			main.use_window(wi)
			wait = 1.4
			step = 9
		9:
			# ---------------- koni disinda yakindan fark etme ----------------
			_freeze_all()
			main.alert_level = 0
			c.set_physics_process(false)
			g = _guards()[2]
			var o := Vector2.RIGHT
			var spot: Vector2 = Vector2.ZERO
			# acik bir yer bul
			for tr in 60:
				var q := Vector2(randf_range(200, lvl.size.x - 200), randf_range(200, lvl.size.y - 200))
				q = NavigationServer2D.map_get_closest_point(c.navigation_agent.get_navigation_map(), q)
				if lvl.has_los(q, q - o * 230.0) and lvl.has_los(q, q + o * 60.0) and not lvl.is_inside_view_blocker(q - o * 100.0) \
						and lvl.interior_of_ext(q) < 0 and lvl.has_los(q - o * 230.0, q):
					spot = q
					break
			check(spot != Vector2.ZERO, "acik test alani bulundu")
			g.global_position = spot
			g.facing = 0.0
			g.vigilant_t = 0.0
			var behind := func(dd: float) -> float:
				return g.global_position.distance_to(spot - o * dd)
			c.crouch = false
			c.run = false
			c.global_position = spot - o * 90.0
			c.velocity = o * 120.0
			check(not g.can_see(c.global_position, false), "komando koninin disinda (arkasinda)")
			check(g.near_sense(c, behind.call(90.0), false) > 0.0, "ayakta yuruyen 90 px arkadan fark edilir")
			c.global_position = spot - o * 150.0
			check(g.near_sense(c, behind.call(150.0), false) == 0.0, "ayakta yuruyen 150 px: fark edilmez")
			c.velocity = o * 192.0
			c.global_position = spot - o * 175.0
			check(g.near_sense(c, behind.call(175.0), false) > 0.0, "kosan 175 px arkadan duyulur")
			c.velocity = o * 66.0
			c.global_position = spot - o * 45.0
			var kc: float = g.near_sense(c, behind.call(45.0), true)
			c.velocity = o * 120.0
			var kw: float = g.near_sense(c, behind.call(45.0), false)
			check(kc > 0.0 and kc < kw * 0.6, "comelik yuruyen 45 px: cok yavas fark edilir (%.2f < %.2f)" % [kc, kw])
			c.velocity = Vector2.ZERO
			check(g.near_sense(c, behind.call(45.0), true) == 0.0, "hareketsiz comelik: fark edilmez")
			c.velocity = o * 120.0
			c.global_position = spot - o * 60.0
			var k1: float = g.near_sense(c, behind.call(60.0), false)
			c.global_position = spot - o * 100.0
			var k2: float = g.near_sense(c, behind.call(100.0), false)
			check(k1 > k2, "yaklastikca hizlanir (%.2f > %.2f)" % [k1, k2])
			main.alert_level = 2
			c.global_position = spot - o * 140.0
			check(g.near_sense(c, behind.call(140.0), false) > 0.0, "kirmizi alarmda 140 px: fark edilir")
			main.alert_level = 0
			# duvar arkasi: bir binanin duvari ardinda
			var it0: Dictionary = lvl.interiors[0]
			var wall_p: Vector2 = it0["ext_door"] + it0["out"].orthogonal() * 70.0
			var in_p: Vector2 = wall_p - it0["out"] * 60.0
			g.global_position = wall_p
			g.facing = (wall_p - in_p).angle()
			c.global_position = in_p
			if not lvl.has_los(wall_p, in_p, true):
				check(g.near_sense(c, wall_p.distance_to(in_p), false) == 0.0, "duvar arkasindan fark edilmez")
			# ---------------- arkadan bicaklama: comelik + zamanlama ----------------
			c.set_physics_process(true)
			g.global_position = spot
			g.set_physics_process(true)
			g.state = &"patrol"
			g.waypoints = []
			g.facing = 0.0
			g.base_facing = 0.0
			g.suspicion = 0.0
			g.navigation_agent.target_position = spot
			c.global_position = spot - o * 220.0
			c.crouch = true
			c.weapon = "knife"
			c.attack(g)
			_t = 0.0
			step = 10
		10:
			_t += d
			if g.suspicion > 0.0:
				_seen_near = true
			if not g.alive or g.state == &"combat" or _t > 12.0:
				print("    bicak: t=%.1f durum %s suphe %.2f alarm %d mesafe %.0f" % [_t, g.state, g.suspicion, main.alert_level, c.global_position.distance_to(g.global_position)])
				check(not g.alive, "comelerek arkadan yaklasan bicakladi (fark edilmeden)")
				check(main.alert_level == 0, "alarm yok")
				# ayakta yururken yaklasan: once "?" sonra doner
				var g3 = _guards()[3]
				g3.global_position = g.global_position + Vector2(0, 0)
				g3.set_physics_process(true)
				g3.state = &"patrol"
				g3.waypoints = []
				g3.facing = 0.0
				g3.base_facing = 0.0
				g3.suspicion = 0.0
				g3.navigation_agent.target_position = g3.global_position
				g = g3
				c.crouch = false
				c.global_position = g.global_position - Vector2.RIGHT * 200.0
				c.move_to(g.global_position - Vector2.RIGHT * 30.0)
				_t = 0.0
				_seen_near = false
				step = 11
		11:
			_t += d
			if g.suspicion > 0.0 and g.sensed_near:
				_seen_near = true
			if g.state == &"suspicious" and absf(wrapf(g.facing - PI, -PI, PI)) < 1.0:
				_turned = true
			if _t > 6.0 or g.state == &"combat":
				check(_seen_near, "ayakta yuruyen arkadan fark edildi (\"?\")")
				check(_turned, "asker sana dondu (koni de doner)")
				print("SONUC: ", "BASARILI" if fails == 0 else "%d HATA" % fails)
				quit(1 if fails > 0 else 0)
	return false
