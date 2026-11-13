extends SceneTree
## Otomatik oyuncu (bot): bolumu bastan sona oynar, olcer ve rapor yazar.
## Gece gelistirmesi bu rapora bakarak neyin gelismesi gerektigine karar verir.
##
##   godot --headless --fixed-fps 60 -s res://tests/bot.gd -- --level=res://levels/bolum1.json \
##         --style=gizli --seed=1 --limit=1500 --out=/tmp/bot_bolum1_gizli_1.json
##
## Tarzlar: gizli (comel, arkadan bicak, gerekirse tabanca), saldiri (tabancayla temizle),
##          tam (gizli + istege bagli gorevler)

const Kayit = preload("res://scripts/kayit.gd")
var main
var opts := {"level": "res://levels/bolum1.json", "style": "gizli", "seed": "1", "limit": "1500", "out": "", "reloads": ""}
var M
var max_reloads := 0
var _save_t := 30.0          # iyi oyuncu sakinken sik kaydeder (Tur 4)
var _slot_t := 60.0          # Tur 5: elle yuvaya (1/2/3) kaydetme araligi
var _slot_i := 0
var _last_death := Vector2(INF, INF)
var _last_slot := ""
var _same_deaths := 0
var t := 0.0
var started := false
var finished := false

# olcumler
var rep := {}
var prev_state := {}
var prev_alive := {}
var prev_hp := 100.0
var prev_alert := 0
var obj_done := {}

# bot durumu
var goal_key := ""
var repath_t := 0.0
var atk_t := 0.0
var stuck_ref := Vector2.ZERO
var stuck_t := 0.0
var flee_from = null
var last_weapon := "knife"
var wait_t := 0.0
var safe_pos := Vector2.ZERO
var key_guard = null           # anahtari tasiyan asker
var hide_spot = null           # cesedi saklayacagi cali
var _thrown_at := {}           # hangi izleyiciye tas atildi
var _carry_t := 0.0
var _wait_on := {}             # izleyici -> toplam bekleme
var chase_t := 0.0
var _wire_t := 0.0
var _lag_t := 0.0
var _had_cutter := false
var _dodge_t := 0.0
var _light_d := {}
var flee_t := 0.0
var flee_to := Vector2.ZERO
# gizli rota planlayici (Tur 2): 50 px izgarada A*, nobetci konileri ve devriye hatlari pahali, calilar ucuz
const CELL := 50.0
var astar: AStarGrid2D
var _danger_t := 0.0
var _route: PackedVector2Array = PackedVector2Array()
var _route_i := 0
var _route_dest := Vector2(INF, INF)
var _route_t := 0.0
var _dead_n := -1
var _use_route := false
var _want := Vector2(INF, INF)    # _go_dest'in istedigi nokta (rota ara noktasindan ayri)


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			var kv := a.substr(2).split("=", true, 1)
			opts[kv[0]] = kv[1]
	seed(int(opts["seed"]))
	# iyi oyuncu gibi: kaydeder, olunce son kayittan devam eder (saldiri tarzi pervasiz: yuklemez)
	max_reloads = int(opts["reloads"]) if opts["reloads"] != "" else (0 if opts["style"] == "saldiri" else 4)
	Kayit.dir_override = "user://bot_kayit/%s_%s_%s" % [opts["level"].get_file().get_basename(), opts["style"], opts["seed"]]
	DirAccess.make_dir_recursive_absolute(Kayit.dir_override)
	for sl in Kayit.SLOTS:
		DirAccess.remove_absolute(Kayit.slot_path(sl))
	M = load("res://scripts/main.gd")
	M.level_choice = opts["level"]
	M.briefed = M.level_choice
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	rep = {"level": opts["level"], "style": opts["style"], "seed": int(opts["seed"]), "result": "", "reason": "",
		"time": 0.0, "objectives": [], "detections": 0, "detected_by": {}, "alarm_yellow": 0, "alarm_red": 0,
		"reinforcements": 0, "damage_taken": 0.0, "kills_knife": 0, "kills_pistol": 0, "kills_other": 0,
		"shots": 0, "medkits_used": 0, "stuck": 0, "stuck_spots": [], "detect_spots": [], "death_pos": null,
		"hp_end": 0.0, "waits": 0, "retreats": 0, "guards": 0, "time_crouched": 0.0, "time_in_combat": 0.0, "interior_visits": 0,
		"stones": 0, "bodies_hidden": 0, "runners_shot": 0, "reloads": 0, "saves": 0, "deaths": [], "load_ms": []}


func _place(p: Vector2) -> String:
	var lvl = main.level
	var bi: int = lvl.interior_at(p)
	if bi >= 0:
		return lvl.interiors[bi]["name"] + " (içi)"
	var best := ""
	var bd := 260.0
	for it in lvl.interiors:
		var d: float = it["rect"].get_center().distance_to(p)
		if d < bd:
			bd = d
			best = it["name"] + " yakını"
	return best if best != "" else "açık arazi (%d,%d)" % [int(p.x / 100) * 100, int(p.y / 100) * 100]


func _guards() -> Array:
	return main.get_tree().get_nodes_in_group("guards")


func _measure(dt: float) -> void:
	var c = main.commando
	for g in _guards():
		var id: int = g.get_instance_id()
		var st: StringName = g.state if g.alive else &"dead"
		if prev_state.get(id, &"patrol") != &"combat" and st == &"combat":
			rep["detections"] += 1
			rep["detected_by"][g.kind] = rep["detected_by"].get(g.kind, 0) + 1
			if rep["detect_spots"].size() < 40:
				rep["detect_spots"].append([int(c.global_position.x), int(c.global_position.y), _place(c.global_position), round(t),
					"%s@%d,%d" % [g.kind, int(g.global_position.x), int(g.global_position.y)], g.waypoints.size()])
		prev_state[id] = st
		var was: bool = prev_alive.get(id, true)
		if was and not g.alive:
			if c.target_guard == g or c.global_position.distance_to(g.global_position) < 40.0:
				if last_weapon == "knife":
					rep["kills_knife"] += 1
				else:
					rep["kills_pistol"] += 1
			else:
				rep["kills_other"] += 1
		prev_alive[id] = g.alive
		if g.alive and g.state == &"combat" and g.target == c:
			pass
	if c.hp < prev_hp:
		rep["damage_taken"] += prev_hp - c.hp
	prev_hp = c.hp
	if main.alert_level != prev_alert:
		if main.alert_level == 1:
			rep["alarm_yellow"] += 1
		elif main.alert_level == 2:
			rep["alarm_red"] += 1
		prev_alert = main.alert_level
	if c.is_crouching():
		rep["time_crouched"] += dt
	for g in _guards():
		if g.alive and g.state == &"combat":
			rep["time_in_combat"] += dt
			break
	for o in main.mission.objectives:
		if o["done"] and not obj_done.has(o["id"]):
			obj_done[o["id"]] = true
			rep["objectives"].append({"id": o["id"], "text": o["text"], "t": round(t)})


func _key_for(p: Vector2) -> Variant:
	## hedef kilitli bir binadaysa once anahtar: yerdeki anahtar, onu tasiyan asker ya da anahtar gorevi
	var bi: int = main.level.interior_at(p)
	if bi < 0 or not main.is_locked(bi):
		return null
	return _key_item(main.level.interiors[bi]["locked"])


func _key_item(key: String) -> Variant:
	for pk in main.level.pickups:
		if not pk["taken"] and pk.get("item", "") == key:
			return ["anahtar", pk["pos"]]
	for g in _guards():
		if g.alive and g.drops == key:
			key_guard = g
			return ["anahtar_asker", g.global_position]
	for o in main.mission.objectives:
		if not o["done"] and o["type"] == "take" and o.get("item", "") == key:
			return ["anahtar_gorev", Vector2(o["pos"][0], o["pos"][1])]
	return null


func _goal() -> Variant:
	var g = _goal0()
	if g != null:
		var k = _key_for(g[1])
		if k != null:
			return k
	return g


func _goal0() -> Variant:
	## siradaki gorev noktasi (null: yapacak bir sey yok)
	var m = main.mission
	for o in m.objectives:
		if o["done"] or not m.available(o):
			continue
		if o.get("optional", false) and opts["style"] != "tam":
			continue
		match o["type"]:
			"exit":
				if m.required_left() == 0:
					return ["exit", main.level.exit_rect.get_center()]
			"rescue":
				var n = m.npcs.get(o["npc"])
				if n != null:
					return [o["id"], n.global_position]
			"have":
				var k = _key_item(o["item"])
				if k != null:
					return k
			"destroy":
				if m.items.get("patlayici", 0) > 0 or m.bombs.size() > 0:
					return [o["id"], Vector2(o["pos"][0], o["pos"][1])]
			_:
				if o.has("pos"):
					return [o["id"], Vector2(o["pos"][0], o["pos"][1])]
	return null


func _build_astar() -> void:
	var lvl = main.level
	var map: RID = main.commando.navigation_agent.get_navigation_map()
	astar = AStarGrid2D.new()
	var n := Vector2i(ceili(lvl.size.x / CELL), ceili(lvl.size.y / CELL))
	astar.region = Rect2i(Vector2i.ZERO, n)
	astar.cell_size = Vector2(CELL, CELL)
	astar.offset = Vector2(CELL, CELL) * 0.5
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	for x in n.x:
		for y in n.y:
			var c := Vector2(x + 0.5, y + 0.5) * CELL
			var q: Vector2 = NavigationServer2D.map_get_closest_point(map, c)
			if q.distance_to(c) > CELL * 0.45:
				astar.set_point_solid(Vector2i(x, y), true)
	# Tur 3: tel makasi varsa dikenli tel gecilebilir sayilir (yaklasinca kesilir)
	_had_cutter = main.mission.items.get("tel_makasi", 0) > 0
	if _had_cutter:
		for w in lvl.wires:
			if w["cut"]:
				continue
			var bb := Rect2(w["pts"][0], Vector2.ZERO)
			for q in w["pts"]:
				bb = bb.expand(q)
			bb = bb.grow(CELL * 0.6)
			for x in range(int(bb.position.x / CELL), int(bb.end.x / CELL) + 1):
				for y in range(int(bb.position.y / CELL), int(bb.end.y / CELL) + 1):
					if astar.is_in_boundsv(Vector2i(x, y)):
						astar.set_point_solid(Vector2i(x, y), false)
	_danger_t = 0.0


func _update_danger() -> void:
	## her hucrenin tehlikesi: sabit nobetcinin bakis konisi (en pahali), devriye hatti, askerin yakini
	var lvl = main.level
	var n: Vector2i = astar.region.size
	var w := PackedFloat32Array()
	w.resize(n.x * n.y)
	w.fill(2.0)
	for hz in lvl.hide_zones:
		if typeof(hz) == TYPE_ARRAY:
			var ci := Vector2i(hz[0] / CELL)
			if astar.is_in_boundsv(ci):
				w[ci.y * n.x + ci.x] = 1.0
	for g in _guards():
		if not g.alive or g.carried or lvl.interior_at(g.global_position) >= 0:
			continue
		var gp: Vector2 = g.global_position
		var static_post: bool = g.waypoints.size() <= 1 and g.state == &"patrol"
		var rng: float = g.view_range() * 1.05
		var r := ceili(rng / CELL) + 1
		var gc := Vector2i(gp / CELL)
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var ci := gc + Vector2i(dx, dy)
				if not astar.is_in_boundsv(ci):
					continue
				var cpos := (Vector2(ci) + Vector2(0.5, 0.5)) * CELL
				var d := cpos.distance_to(gp)
				if d > rng:
					continue
				var k := ci.y * n.x + ci.x
				if d < 90.0:
					w[k] += 14.0
				# sadece sabit nobetcinin konisi (devriyenin anlik bakisi rotayi titretir; devriye hatti ayrica pahali)
				if static_post and absf(wrapf((cpos - gp).angle() - g.base_facing, -PI, PI)) < g.VIEW_HALF + 0.95 \
						and lvl.has_los(gp, cpos):
					w[k] += 26.0
		# devriye hatti boyunca
		if g.waypoints.size() > 1:
			for i in g.waypoints.size():
				var a: Vector2 = g.waypoints[i]
				var b: Vector2 = g.waypoints[(i + 1) % g.waypoints.size()]
				var steps := int(a.distance_to(b) / CELL) + 1
				for j in steps + 1:
					var pc := Vector2i(a.lerp(b, float(j) / steps) / CELL)
					for dx in range(-2, 3):
						for dy in range(-2, 3):
							var ci := pc + Vector2i(dx, dy)
							if astar.is_in_boundsv(ci):
								w[ci.y * n.x + ci.x] += 5.0
	# Tur 3: projektor isik yollari pahali
	for sl in lvl.searchlights:
		if not sl["on"]:
			continue
		var lp: Array = sl["path"]
		for i in lp.size() - 1:
			var a: Vector2 = lp[i]
			var b: Vector2 = lp[i + 1]
			var steps := int(a.distance_to(b) / CELL) + 1
			for j in steps + 1:
				var pc := Vector2i(a.lerp(b, float(j) / steps) / CELL)
				for dx in range(-2, 3):
					for dy in range(-2, 3):
						var ci := pc + Vector2i(dx, dy)
						if astar.is_in_boundsv(ci):
							w[ci.y * n.x + ci.x] += 9.0
	# Tur 5: iyi oyuncu oldugu / yakalandigi yerden ders alir: o cevre pahali (kayittan donunce baska yol dener)
	var marks: Array = []
	for dd in rep["deaths"]:
		marks.append([Vector2(dd[0], dd[1]), 170.0, 18.0])
	if not rep["deaths"].is_empty():      # ilk canda rota degismesin: yalniz olup kayittan donunce
		for ds in rep["detect_spots"]:
			marks.append([Vector2(ds[0], ds[1]), 110.0, 4.0])
	for mk in marks:
		var r := ceili(mk[1] / CELL)
		var mc := Vector2i(mk[0] / CELL)
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var ci := mc + Vector2i(dx, dy)
				if astar.is_in_boundsv(ci) and Vector2(dx, dy).length() * CELL <= mk[1]:
					w[ci.y * n.x + ci.x] += mk[2]
	for x in n.x:
		for y in n.y:
			astar.set_point_weight_scale(Vector2i(x, y), w[y * n.x + x])


func _path_danger(from: Vector2, to: Vector2) -> float:
	var map: RID = main.commando.navigation_agent.get_navigation_map()
	var p := NavigationServer2D.map_get_path(map, from, to, true)
	var worst := 0.0
	for i in range(p.size() - 1):
		var n := int(p[i].distance_to(p[i + 1]) / (CELL * 0.5)) + 1
		for j in n:
			var ci := Vector2i(p[i].lerp(p[i + 1], float(j) / n) / CELL)
			if astar.is_in_boundsv(ci) and not astar.is_point_solid(ci):
				worst = maxf(worst, astar.get_point_weight_scale(ci))
	return worst


func _plan(from: Vector2, to: Vector2) -> void:
	_route = PackedVector2Array()
	_route_i = 0
	_route_dest = to
	_route_t = 6.0
	var a := Vector2i(from / CELL)
	var b := Vector2i(to / CELL)
	if not astar.is_in_boundsv(a) or not astar.is_in_boundsv(b) or astar.is_point_solid(a) or astar.is_point_solid(b):
		return
	_route = astar.get_point_path(a, b)
	if _route.size() > 0:
		_route[_route.size() - 1] = to


func _route_next(c) -> Vector2:
	## rotadaki siradaki ara nokta (yakindakileri atla)
	while _route_i < _route.size() - 1 and c.global_position.distance_to(_route[_route_i]) < 60.0:
		_route_i += 1
	# biraz ileriye bak: kose kesme
	var j := mini(_route_i + 1, _route.size() - 1)
	return _route[j]


func _go(target: Vector2) -> void:
	_go_dest(target)
	# gizli tarz: dis haritada uzun yolda tehlike haritali rota kullan
	var c = main.commando
	if opts["style"] == "saldiri" or main.cur_interior >= 0 or astar == null:
		return
	var dest: Vector2 = _want
	if dest.x == INF or main.level.interior_at(dest) >= 0:
		return
	if c.global_position.distance_to(dest) < 160.0:
		return
	_route_t -= 1.0 / 60.0
	if _route_dest.distance_to(dest) > 40.0:
		# yeni hedef: dogrudan yol tehlikeli mi? (sabit nobetci konisi / devriye hatti) - degilse dogrudan git
		_route = PackedVector2Array()
		_route_dest = dest
		_use_route = _path_danger(c.global_position, dest) >= 10.0
		_route_t = 0.0
	if _use_route and _route_t <= 0.0:
		_plan(c.global_position, dest)
		_route_t = 8.0
	if _route.size() < 2:
		return
	var wp: Vector2 = _route_next(c)
	if c.navigation_agent.target_position.distance_to(wp) > 20.0:
		c.navigation_agent.target_position = wp


func _go_dest(target: Vector2) -> void:
	## kapilardan gecerek hedefe git
	var lvl = main.level
	var c = main.commando
	var here: int = main.cur_interior
	var there: int = lvl.interior_at(target)
	var dest := target
	if here != there:
		if here >= 0:
			dest = lvl.interiors[here]["int_door"]
			if c.global_position.distance_to(dest) < 34.0:
				main.exit_building()
				repath_t = 0.0
				return
		else:
			dest = lvl.interiors[there]["ext_door"]
			if c.global_position.distance_to(dest) < 30.0:
				main.enter_building(there)
				rep["interior_visits"] += 1
				repath_t = 0.0
				return
	if repath_t <= 0.0 or _want.distance_to(dest) > 30.0:
		repath_t = 1.0
		_want = dest
		c.move_to(dest)


func _sees_me(g) -> bool:
	var c = main.commando
	return g.can_see(c.global_position, c.is_crouching())


func _escaping() -> bool:
	return opts["style"] != "saldiri" and main.alert_level >= 2 and main.commando.hp > 35.0


func _flee(dt: float) -> bool:
	## gizli tarz: cok kisi ates ediyorsa savasma, gorus hattini kir ve calilikta saklan (Commandos: kac ve saklan)
	var c = main.commando
	if opts["style"] == "saldiri":
		return false
	if flee_t > 0.0:
		flee_t -= dt
		if c.global_position.distance_to(flee_to) < 14.0:
			c.crouch = true
			c.navigation_agent.target_position = c.global_position
			# kimse gormuyorsa saklanmaya devam (biraz bekle)
			return flee_t > 0.0
		if repath_t <= 0.0:
			repath_t = 0.6
			c.move_to(flee_to)
			c.run_once = true
		return true
	var hostile: Array = []
	for g in _guards():
		if g.alive and g.state == &"combat" and g.global_position.distance_to(c.global_position) < 380.0 \
				and main.level.has_los(g.global_position, c.global_position):
			hostile.append(g)
	if hostile.size() < 2 and not (hostile.size() >= 1 and c.hp < 35.0):
		return false
	var cen := Vector2.ZERO
	for g in hostile:
		cen += g.global_position
	cen /= hostile.size()
	var away: Vector2 = (c.global_position - cen).normalized()
	var best = null
	var bs := -INF
	for hz in main.level.hide_zones:
		if typeof(hz) != TYPE_ARRAY or main.level.interior_at(hz[0]) != main.cur_interior:
			continue
		var v: Vector2 = hz[0] - c.global_position
		var dd := v.length()
		if dd < 80.0 or dd > 520.0:
			continue
		var sc: float = v.normalized().dot(away) * 2.0 - dd / 400.0
		for g in hostile:
			if main.level.has_los(g.global_position, hz[0]):
				sc -= 0.6
		if sc > bs:
			bs = sc
			best = hz[0]
	if best == null:
		return false
	rep["flees"] = rep.get("flees", 0) + 1
	flee_to = best
	flee_t = 14.0
	c.target_guard = null
	c.move_to(best)
	c.run_once = true
	repath_t = 0.6
	return true


func _fight(dt: float) -> bool:
	## tehdit varsa saldir; saldiriyorsa true
	var c = main.commando
	if c.target_guard != null and is_instance_valid(c.target_guard) and c.target_guard.alive:
		atk_t += dt
		if atk_t < 5.0:
			return true
		c.target_guard = null
	atk_t = 0.0
	var best = null
	var bd := INF
	var mode := ""
	# once sirene kosan askeri durdur (Commandos: alarm verilmeden sustur)
	for g in _guards():
		if g.alive and g.state == &"alarm_run" and main.level.interior_at(g.global_position) == main.cur_interior:
			var d0: float = g.global_position.distance_to(c.global_position)
			if d0 <= c.PISTOL_RANGE and c.ammo > 0 and main.level.has_los(c.global_position, g.global_position):
				c.weapon = "pistol"
				last_weapon = "pistol"
				rep["shots"] += 1
				rep["runners_shot"] += 1
				c.attack(g)
				return true
			elif d0 < 600.0 and chase_t < 8.0:
				chase_t += dt
				c.move_to(g.global_position)
				c.run_once = true
				return true
	chase_t = 0.0
	for g in _guards():
		if not g.alive or g.carried:
			continue
		if g.global_position.distance_to(c.global_position) > 400.0:
			continue
		if main.level.interior_at(g.global_position) != main.cur_interior:
			continue
		var d: float = g.global_position.distance_to(c.global_position)
		var hostile: bool = g.state == &"combat"
		# kacis modu: kirmizi alarmda hedefe kosarken uzaktakilerle oyalanma (yolu kesmiyorsa)
		if _escaping() and d > 150.0 and not _in_way(g):
			continue
		if opts["style"] == "saldiri" and d < 240.0 and c.ammo > 0 and main.level.has_los(c.global_position, g.global_position):
			if d < bd:
				best = g; bd = d; mode = "pistol"
		elif hostile and d <= c.PISTOL_RANGE and c.ammo > 0 and main.level.has_los(c.global_position, g.global_position):
			if d < bd:
				best = g; bd = d; mode = "pistol"
		elif hostile and d < 130.0:
			if d < bd:
				best = g; bd = d; mode = "knife"
		elif not hostile and d < 120.0 and not _sees_me(g) and main.level.has_los(c.global_position, g.global_position):
			if d < bd:
				best = g; bd = d; mode = "fist" if (c.ropes > 0 and opts["style"] != "saldiri") else "knife"
	if best == null:
		return false
	c.weapon = mode
	last_weapon = mode
	if mode == "pistol":
		rep["shots"] += 1
	c.attack(best)
	return true


func _blocker(target: Vector2) -> Variant:
	## hedef noktayi (bina hedefinde dis kapiyi) goren sabit nobetci: arkasindaki noktayi dondur
	var lvl = main.level
	var c = main.commando
	var dest := target
	var ti: int = lvl.interior_at(target)
	if ti != main.cur_interior:
		dest = lvl.interiors[ti]["ext_door"] if ti >= 0 else lvl.interiors[main.cur_interior]["int_door"]
	if c.global_position.distance_to(dest) > 700.0:
		return null
	var map: RID = c.navigation_agent.get_navigation_map()
	for g in _guards():
		if not g.alive or g.kind == "kule" or g.state != &"patrol" or g.waypoints.size() > 1:
			continue
		if lvl.interior_at(g.global_position) != main.cur_interior:
			continue
		var gp: Vector2 = g.global_position
		var dd: Vector2 = dest - gp
		if dd.length() > 120.0 or absf(wrapf(dd.angle() - g.base_facing, -PI, PI)) > g.VIEW_HALF + 1.0:
			continue
		for side in [PI, PI * 0.75, -PI * 0.75]:
			var q: Vector2 = NavigationServer2D.map_get_closest_point(map, gp + Vector2.from_angle(g.base_facing + side) * 46.0)
			if q.distance_to(gp) > 20.0 and q.distance_to(gp) < 80.0:
				return [q, g]
	return null


func _in_way(g) -> bool:
	## gizli tarz gereksiz oldurmez: sadece yolu kesen ya da bize donebilecek yakin askeri bicaklar
	var c = main.commando
	if g.global_position.distance_to(c.global_position) < 60.0:
		return true
	var path: PackedVector2Array = c.navigation_agent.get_current_navigation_path()
	var i0: int = c.navigation_agent.get_current_navigation_path_index()
	for i in range(i0, mini(i0 + 4, path.size())):
		if path[i].distance_to(g.global_position) < 110.0:
			return true
	return false


func _hide_body(dt: float) -> bool:
	## gizli tarz: cesedi en yakin caliya tasir (Commandos: ceset saklama)
	var c = main.commando
	if opts["style"] == "saldiri":
		return false
	# Tur 3: bayilttigi askeri hemen bagla (yoksa ~40 sn sonra ayilir)
	var kb = c.body_nearby()
	if kb != null and kb.knocked and not kb.tied and c.ropes > 0:
		c.tie_up(kb)
		rep["tied"] = rep.get("tied", 0) + 1
	if c.carrying != null:
		for g in _guards():
			if g.alive and g.state == &"combat" and g.global_position.distance_to(c.global_position) < 300.0:
				c.drop_body()
				hide_spot = null
				return false
		_carry_t += dt
		if hide_spot == null or c.global_position.distance_to(hide_spot[0]) < maxf(8.0, hide_spot[1] * 0.45) \
				or _carry_t > 25.0 or (c.navigation_agent.is_navigation_finished() and repath_t < 0.5):
			var b = c.carrying
			c.drop_body()
			if b.hidden_body:
				rep["bodies_hidden"] += 1
			hide_spot = null
			return false
		if repath_t <= 0.0:
			repath_t = 0.8
			c.move_to(hide_spot[0])
		return true
	var b = c.body_nearby()
	if b == null or b.hidden_body or b.discovered:
		return false
	var best = null
	var bd := 300.0
	for hz in main.level.hide_zones:
		if typeof(hz) != TYPE_ARRAY:
			continue
		var d: float = hz[0].distance_to(b.global_position)
		if d < bd and main.level.interior_at(hz[0]) == main.cur_interior:
			bd = d
			best = hz
	if best == null:
		return false
	c.pick_body(b)
	_carry_t = 0.0
	hide_spot = best
	c.move_to(best[0])
	repath_t = 0.8
	return true


func _watcher(p: Vector2):
	var c = main.commando
	for g in _guards():
		if not g.alive or g.state == &"combat" or g.carried:
			continue
		if main.level.interior_at(g.global_position) != main.cur_interior:
			continue
		var d: Vector2 = p - g.global_position
		var cr: bool = c.is_crouching()
		if d.length() > g.view_range() * (g.NEAR_FRAC * 1.25 if cr else 1.05):
			continue
		if absf(wrapf(d.angle() - g.facing, -PI, PI)) > g.VIEW_HALF + 0.25:
			continue
		if main.level.has_los(g.global_position, p):
			return g
		# calidan da yakindan gorur (alarmda daha uzaktan)
		var br: float = g.BUSH_SEE * 1.25 * [1.0, 1.35, 1.75][clampi(main.alert_level, 0, 2)]
		if d.length() < br and main.level.has_los(g.global_position, p, true):
			return g
	return null


func _stealth_hold(dt: float) -> bool:
	var c = main.commando
	var w = _watcher(c.global_position)
	if w == null:
		safe_pos = c.global_position
	if w != null and w.suspicion > 0.35 and safe_pos != Vector2.ZERO and safe_pos.distance_to(c.global_position) > 20.0:
		rep["retreats"] += 1
		c.move_to(safe_pos)
		c.run_once = true
		wait_t = 0.0
		return true
	if c.navigation_agent.is_navigation_finished():
		return false
	var path: PackedVector2Array = c.navigation_agent.get_current_navigation_path()
	var i: int = c.navigation_agent.get_current_navigation_path_index()
	if i >= path.size():
		return false
	var ahead: Vector2 = c.global_position + (path[i] - c.global_position).limit_length(70.0)
	var wa = _watcher(ahead)
	if wa == null and _route.size() > _route_i + 1 and main.cur_interior < 0:
		var ahead2: Vector2 = c.global_position + (_route[mini(_route_i + 1, _route.size() - 1)] - c.global_position).limit_length(140.0)
		wa = _watcher(ahead2)
	# yol ustundeki sabit nobetciyi tasla uzaklastir (Commandos: dikkat dagit, arkadan gec)
	if c.stones > 0 and main.alert_level < 2 and wait_t > 0.8:
		for g in _guards():
			if not g.alive or g.state != &"patrol" or g.waypoints.size() > 1 or g.kind == "kule" or _thrown_at.has(g.get_instance_id()):
				continue
			var dg: float = g.global_position.distance_to(c.global_position)
			if dg > 260.0 or dg < 90.0 or main.level.interior_at(g.global_position) != main.cur_interior:
				continue
			var on_route := false
			for j in range(_route_i, mini(_route_i + 5, _route.size())):
				if _route[j].distance_to(g.global_position) < 130.0:
					on_route = true
			if on_route or (main.cur_interior >= 0 and dg < 200.0):
				_thrown_at[g.get_instance_id()] = true
				var dir: Vector2 = (g.global_position - c.global_position).normalized()
				var to: Vector2 = g.global_position + dir.rotated(0.6) * 150.0
				if c.throw_stone(to):
					rep["stones"] += 1
					wait_t = 0.1
				break
	# Tur 3: projektor isigi yolun ustundeyse/yaklasiyorsa bekle (isik gecsin)
	if wa == null and main.cur_interior < 0:
		for sl in main.level.searchlights:
			if sl["on"] and (sl["pos"].distance_to(ahead) < sl["r"] + 45.0 or sl["pos"].distance_to(c.global_position) < sl["r"] + 25.0):
				wa = sl["op"] if sl["op"] != null else _guards()[0]
				rep["light_waits"] = rep.get("light_waits", 0) + (1 if wait_t == 0.0 else 0)
				break
	if wa != null and wait_t < 7.0:
		if wait_t == 0.0:
			rep["waits"] += 1
		wait_t += dt
		# 1.2 sn bekledikten sonra izleyicinin arkasina tas at: o tarafa donup bakar
		var wid: int = wa.get_instance_id()
		_wait_on[wid] = _wait_on.get(wid, 0.0) + dt
		if _wait_on[wid] > 1.2 and c.stones > 0 and not _thrown_at.has(wid):
			_thrown_at[wid] = true
			var away: Vector2 = wa.global_position + (wa.global_position - c.global_position).normalized() * 130.0
			if c.throw_stone(away):
				rep["stones"] += 1
		c.navigation_agent.target_position = c.global_position
		repath_t = 0.0
		return true
	if wait_t >= 7.0:
		wait_t = -3.0      # cok bekledi: 3 sn risk al
	elif wait_t < 0.0:
		wait_t += dt
	else:
		wait_t = 0.0
	return false


func _process(dt: float) -> bool:
	if finished:
		return false
	if main == null or main.level == null or main.commando == null:
		return false
	if not started:
		started = true
		if rep["guards"] == 0:
			rep["guards"] = _guards().size()
		for g in _guards():
			prev_state[g.get_instance_id()] = g.state
			prev_alive[g.get_instance_id()] = true
	var hud = main.hud
	var n := 0
	while hud.dialog_panel.visible and n < 30:
		hud._next_line()
		n += 1
	if main.get_tree().paused and not hud.dialog_panel.visible and not main.game_over:
		main.get_tree().paused = false
	t += dt
	_measure(dt)
	if main.game_over and not main.commando.alive and rep["reloads"] < max_reloads and t < float(opts["limit"]) and _reload():
		return false
	if main.game_over or t > float(opts["limit"]):
		_finish()
		return false
	_save_t -= dt
	_slot_t -= dt
	if _save_t <= 0.0 and max_reloads > 0:
		_save_t = 5.0
		if _calm():
			# Tur 5: iyi oyuncu gibi hizli kayda ek olarak arada elle yuvalara da kaydeder (1 -> 2 -> 3),
			# boylece hizli kayit kotu bir ana dustuyse daha eski, guvenli bir kayda donebilir
			var slot := "hizli"
			if _slot_t <= 0.0:
				slot = ["1", "2", "3"][_slot_i % 3]
			if Kayit.save(main, slot) == "":
				rep["saves"] += 1
				_save_t = 40.0
				if slot != "hizli":
					_slot_i += 1
					_slot_t = 75.0
	var c = main.commando
	var m = main.mission
	if opts.has("trace") and int(t * 2.0) != int((t - dt) * 2.0):
		print("T %.1f pos %s goal %s carry %s alert %d hp %d wait %.1f tgt %s" % [t, c.global_position.round(), goal_key, c.carrying != null, main.alert_level, c.hp, wait_t, c.target_guard != null])
	repath_t -= dt
	if astar == null and opts["style"] != "saldiri":
		_build_astar()
		main.level.changed_map.connect(func(): _build_astar())
	if astar != null and (m.items.get("tel_makasi", 0) > 0) != _had_cutter:
		_build_astar()
	if astar != null:
		_danger_t -= dt
		if _danger_t <= 0.0 or main.bodies.size() != _dead_n:
			_danger_t = 2.0
			_dead_n = main.bodies.size()
			_update_danger()
	# saglik
	if c.hp < 45.0 and c.medkits > 0:
		c.use_medkit()
		rep["medkits_used"] += 1
	# patlayici: kurulduysa uzaklas
	if m.bombs.size() > 0:
		var bp: Vector2 = m.bombs[0][0]
		var far := true
		for u in main.get_tree().get_nodes_in_group("player"):
			if u.global_position.distance_to(bp) < m.BLAST_R + 120.0:
				far = false
		if not far:
			var away: Vector2 = bp + (c.global_position - bp).normalized() * (m.BLAST_R + 260.0)
			var map: RID = c.navigation_agent.get_navigation_map()
			c.crouch = false
			if repath_t <= 0.0:
				repath_t = 0.5
				c.move_to(NavigationServer2D.map_get_closest_point(map, away))
				c.run_once = true
			return false
		# guvenli mesafede patlamayi bekle (saldiri olursa savun)
		_fight(dt)
		return false
	if m.planting >= 0.0:
		return false
	if m.plant_target != null and m.bombs.is_empty() and m.plant_target["id"] == goal_key:
		m.start_planting()
		return false
	# tel kesiliyor: tehlike yoksa yerinde kal (hareket kesmeyi bozar)
	if main._cut_i >= 0 and main.alert_level < 2 and c.target_guard == null:
		c.navigation_agent.target_position = c.global_position
		return false
	if _flee(dt):
		return false
	if _fight(dt):
		return false
	if _hide_body(dt):
		return false
	# comelme: yakinda devriye varsa
	var near := false
	for g in _guards():
		if g.alive and g.state != &"combat" and g.global_position.distance_to(c.global_position) < 380.0:
			near = true
			break
	c.crouch = near and opts["style"] != "saldiri"
	# Tur 3: projektor isigi yaklasiyorsa yolundan cekil (isikta beklemek yakalatir)
	if opts["style"] != "saldiri" and main.cur_interior < 0 and _dodge_t <= 0.0:
		for sl in main.level.searchlights:
			if not sl["on"]:
				continue
			var lp: Vector2 = sl["pos"]
			var dl: float = lp.distance_to(c.global_position)
			if dl < sl["r"] + 90.0:
				var prev: float = _light_d.get(sl["pole"], INF)
				_light_d[sl["pole"]] = dl
				if dl <= prev + 1.0:
					var away: Vector2 = (c.global_position - lp).normalized()
					if away == Vector2.ZERO:
						away = Vector2.RIGHT
					var map1: RID = c.navigation_agent.get_navigation_map()
					c.move_to(NavigationServer2D.map_get_closest_point(map1, c.global_position + away * (sl["r"] + 120.0)))
					c.run_once = true
					_dodge_t = 1.2
					rep["light_dodges"] = rep.get("light_dodges", 0) + 1
					return false
			else:
				_light_d.erase(sl["pole"])
	if _dodge_t > 0.0:
		_dodge_t -= dt
		return false
	# gizli tarz: ilerideki noktayi goren devriye varsa bekle; supheleniyorsa geri cekil
	if opts["style"] != "saldiri" and _stealth_hold(dt):
		return false
	# Tur 3: takipciyi koru: geride kaldiysa bekle (onu da gorebilirler), kosma
	var lag := false
	for id in m.npcs:
		var fn = m.npcs[id]
		if fn.following and fn.alive and fn.global_position.distance_to(c.global_position) > 190.0 \
				and main.level.interior_at(fn.global_position) == main.cur_interior and not _escaping():
			lag = true
	_lag_t = (_lag_t + dt) if lag else 0.0
	if _lag_t > 8.0:
		_lag_t = -4.0            # takipci takildi: biraz ilerle, yeniden bekle
	if lag and opts["style"] != "saldiri" and _lag_t >= 0.0:
		c.navigation_agent.target_position = c.global_position
		rep["follower_waits"] = rep.get("follower_waits", 0) + 1
		return false
	var gl = _goal()
	if gl == null:
		return false
	# Tur 3: tel makasi: yol tel orgu yuzunden cok dolaniyorsa yakindaki teli kes
	if main._cut_i >= 0:
		return false
	_wire_t -= dt
	if _wire_t <= 0.0 and m.items.get("tel_makasi", 0) > 0 and main.cur_interior < 0:
		_wire_t = 1.5
		var wi: int = main.level.wire_near(c.global_position, 40.0)
		# rota telin icinden geciyorsa kes
		if wi >= 0 and _use_route:
			var wb := Rect2(main.level.wires[wi]["pts"][0], Vector2.ZERO)
			for q in main.level.wires[wi]["pts"]:
				wb = wb.expand(q)
			for j in range(_route_i, mini(_route_i + 3, _route.size())):
				if wb.grow(CELL * 0.7).has_point(_route[j]):
					main._cut_i = wi
					main._cut_t = 0.0
					c.move_to(c.global_position)
					rep["wires_cut"] = rep.get("wires_cut", 0) + 1
					return false
		if wi >= 0:
			var map0: RID = c.navigation_agent.get_navigation_map()
			var pth := NavigationServer2D.map_get_path(map0, c.global_position, gl[1], true)
			var plen := 0.0
			for k in range(pth.size() - 1):
				plen += pth[k].distance_to(pth[k + 1])
			if plen > c.global_position.distance_to(gl[1]) * 1.5 + 250.0:
				main._cut_i = wi
				main._cut_t = 0.0
				c.move_to(c.global_position)
				rep["wires_cut"] = rep.get("wires_cut", 0) + 1
				return false
	if gl[0] != goal_key:
		goal_key = gl[0]
		repath_t = 0.0
	# hedefi (ya da kapisini) bekleyen sabit nobetci varsa once onun arkasina dolan ve bicakla
	if _escaping() and not c.run_once and c.carrying == null:
		c.run_once = true          # alarmda gurultu onemsiz: kos
	var blk = _blocker(gl[1]) if opts["style"] != "saldiri" and main.alert_level < 2 else null
	if blk != null:
		var bg = blk[1]
		# onundeysek once tasla yuzunu cevir (Commandos: dikkat dagit, arkadan bicakla)
		var dme: float = bg.global_position.distance_to(c.global_position)
		if dme < 280.0 and dme > 70.0 and c.stones > 0 and not _thrown_at.has(bg.get_instance_id()) \
				and absf(wrapf((c.global_position - bg.global_position).angle() - bg.facing, -PI, PI)) < 1.3:
			_thrown_at[bg.get_instance_id()] = true
			var side: Vector2 = (bg.global_position - c.global_position).normalized().rotated(1.2) * 140.0
			if c.throw_stone(bg.global_position + side):
				rep["stones"] += 1
		_go(blk[0])
	else:
		_go(gl[1])
	# takilma
	stuck_t += dt
	if stuck_t > 6.0:
		if c.global_position.distance_to(stuck_ref) < 12.0 and m.planting < 0.0:
			rep["stuck"] += 1
			if rep["stuck_spots"].size() < 20:
				rep["stuck_spots"].append([int(c.global_position.x), int(c.global_position.y), _place(c.global_position), goal_key])
			var map: RID = c.navigation_agent.get_navigation_map()
			c.move_to(NavigationServer2D.map_get_closest_point(map, c.global_position + Vector2.from_angle(randf() * TAU) * 120.0))
			repath_t = 1.5
		stuck_ref = c.global_position
		stuck_t = 0.0
	return false


func _calm() -> bool:
	## kaydetmek icin guvenli an: alarm yok, kimse suphelenmiyor, cevrede beni goren yok
	if main.alert_level > 0 or main.commando.carrying != null:
		return false
	for g in _guards():
		if g.alive and (g.state != &"patrol" or g.suspicion > 0.15):
			return false
	return Kayit.why_not(main) == ""


func _pick_slot(death: Vector2) -> String:
	## Tur 5: ayni yerde ust uste olduysen (kayit kotu bir ana dusmus) bir onceki, daha eski kayda don
	var slot: String = Kayit.latest(opts["level"])
	if death.distance_to(_last_death) < 250.0 and _last_slot != "":
		_same_deaths += 1
		var cur := float(Kayit.info(_last_slot).get("sure", 0.0))
		var best := ""
		var bs := -1.0
		for sl in Kayit.SLOTS:
			var d: Dictionary = Kayit.info(sl)
			if d.is_empty() or d.get("bozuk", false) or d.get("bolum", "") != opts["level"]:
				continue
			var su := float(d.get("sure", 0.0))
			if su < cur - 5.0 and su > bs:
				bs = su
				best = sl
		if best != "":
			slot = best
			rep["older_loads"] = rep.get("older_loads", 0) + 1
	else:
		_same_deaths = 0
	_last_death = death
	_last_slot = slot
	return slot


func _reload() -> bool:
	## olum: son kayittan devam (insan oyuncu gibi). Bot durumu yeni sahneye gore sifirlanir.
	var c = main.commando
	var slot: String = _pick_slot(c.global_position)
	if slot == "" or M.prepare_load(slot) != "":
		return false
	rep["deaths"].append([int(c.global_position.x), int(c.global_position.y), _place(c.global_position), round(t), main.end_text, slot])
	rep["reloads"] += 1
	var t0 := Time.get_ticks_msec()
	root.remove_child(main)
	main.queue_free()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	rep["load_ms"].append(Time.get_ticks_msec() - t0)
	started = false
	prev_state = {}
	prev_alive = {}
	prev_hp = 100.0
	goal_key = ""
	repath_t = 0.0
	stuck_t = 0.0
	flee_from = null
	wait_t = 0.0
	key_guard = null
	hide_spot = null
	_thrown_at = {}
	_carry_t = 0.0
	_wait_on = {}
	chase_t = 0.0
	_light_d = {}
	flee_t = 0.0
	astar = null
	_route = PackedVector2Array()
	_route_i = 0
	_route_dest = Vector2(INF, INF)
	_dead_n = -1
	_want = Vector2(INF, INF)
	_save_t = 20.0
	_slot_t = 60.0
	obj_done = {}
	for o in main.mission.objectives:
		if o["done"]:
			obj_done[o["id"]] = true
	return true


func _finish() -> void:
	finished = true
	var c = main.commando
	# yuklemeden sonra kaybedilen gorevler sayilmasin: son durumda bitmis olanlar
	var now_done := {}
	for o in main.mission.objectives:
		if o["done"]:
			now_done[o["id"]] = true
	rep["objectives"] = rep["objectives"].filter(func(o): return now_done.has(o["id"]))
	var seen := {}
	rep["objectives"] = rep["objectives"].filter(func(o):
		if seen.has(o["id"]):
			return false
		seen[o["id"]] = true
		return true)
	rep["time"] = round(t)
	rep["hp_end"] = round(c.hp)
	if main.game_over and c.alive:
		rep["result"] = "zafer"
	elif main.game_over:
		rep["result"] = "kayip"
		rep["reason"] = main.end_text
		rep["death_pos"] = [int(c.global_position.x), int(c.global_position.y), _place(c.global_position)]
	else:
		rep["result"] = "zaman_doldu"
		var g = _goal()
		rep["reason"] = "kalan hedef: " + (str(g[0]) if g != null else "?")
	var alive := 0
	for g in _guards():
		if g.alive:
			alive += 1
	rep["reinforcements"] = _guards().size() - rep["guards"]
	rep["guards_alive_end"] = alive
	rep["bodies_found"] = main.stats.get("bodies_found", 0)
	rep["missed_noticed"] = main.stats.get("missed", 0)
	rep["runners_stopped"] = main.stats.get("runners_stopped", 0)
	for k in ["knockouts", "witnessed", "lit", "grenades", "wires"]:
		rep["st_" + k] = main.stats.get(k, 0)
	if main.game_over and c.alive:
		var sc: Dictionary = main.score()
		rep["points"] = sc["points"]
		rep["rank"] = sc["rank"]
	var js := JSON.stringify(rep, "  ")
	print("BOT_RAPOR ", JSON.stringify(rep))
	if opts["out"] != "":
		var f := FileAccess.open(opts["out"], FileAccess.WRITE)
		f.store_string(js)
		f.close()
	quit(0)
