extends SceneTree
## Otomatik oyuncu (bot): bolumu bastan sona oynar, olcer ve rapor yazar.
## Gece gelistirmesi bu rapora bakarak neyin gelismesi gerektigine karar verir.
##
##   godot --headless --fixed-fps 60 -s res://tests/bot.gd -- --level=res://levels/bolum1.json \
##         --style=gizli --seed=1 --limit=1500 --out=/tmp/bot_bolum1_gizli_1.json
##
## Tarzlar: gizli (comel, arkadan bicak, gerekirse tabanca), saldiri (tabancayla temizle),
##          tam (gizli + istege bagli gorevler)

var main
var opts := {"level": "res://levels/bolum1.json", "style": "gizli", "seed": "1", "limit": "1500", "out": ""}
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


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			var kv := a.substr(2).split("=", true, 1)
			opts[kv[0]] = kv[1]
	seed(int(opts["seed"]))
	var M = load("res://scripts/main.gd")
	M.level_choice = opts["level"]
	M.briefed = M.level_choice
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	rep = {"level": opts["level"], "style": opts["style"], "seed": int(opts["seed"]), "result": "", "reason": "",
		"time": 0.0, "objectives": [], "detections": 0, "detected_by": {}, "alarm_yellow": 0, "alarm_red": 0,
		"reinforcements": 0, "damage_taken": 0.0, "kills_knife": 0, "kills_pistol": 0, "kills_other": 0,
		"shots": 0, "medkits_used": 0, "stuck": 0, "stuck_spots": [], "detect_spots": [], "death_pos": null,
		"hp_end": 0.0, "waits": 0, "retreats": 0, "guards": 0, "time_crouched": 0.0, "time_in_combat": 0.0, "interior_visits": 0}


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
				rep["detect_spots"].append([int(c.global_position.x), int(c.global_position.y), _place(c.global_position), round(t)])
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


func _goal() -> Variant:
	## siradaki gorev noktasi (null: yapacak bir sey yok)
	var m = main.mission
	for o in m.objectives:
		if o["done"]:
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
			"destroy":
				if m.items.get("patlayici", 0) > 0 or m.bombs.size() > 0:
					return [o["id"], Vector2(o["pos"][0], o["pos"][1])]
			_:
				if o.has("pos"):
					return [o["id"], Vector2(o["pos"][0], o["pos"][1])]
	return null


func _go(target: Vector2) -> void:
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
	if repath_t <= 0.0 or c.navigation_agent.target_position.distance_to(dest) > 30.0:
		repath_t = 1.0
		c.move_to(dest)


func _sees_me(g) -> bool:
	var c = main.commando
	return g.can_see(c.global_position, c.is_crouching())


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
	for g in _guards():
		if not g.alive or g.carried:
			continue
		if g.global_position.distance_to(c.global_position) > 400.0:
			continue
		if main.level.interior_at(g.global_position) != main.cur_interior:
			continue
		var d: float = g.global_position.distance_to(c.global_position)
		var hostile: bool = g.state == &"combat"
		if opts["style"] == "saldiri" and d < 240.0 and c.ammo > 0 and main.level.has_los(c.global_position, g.global_position):
			if d < bd:
				best = g; bd = d; mode = "pistol"
		elif hostile and d <= c.PISTOL_RANGE and c.ammo > 0 and main.level.has_los(c.global_position, g.global_position):
			if d < bd:
				best = g; bd = d; mode = "pistol"
		elif hostile and d < 130.0:
			if d < bd:
				best = g; bd = d; mode = "knife"
		elif not hostile and d < 120.0 and not _sees_me(g):
			if d < bd:
				best = g; bd = d; mode = "knife"
	if best == null:
		return false
	c.weapon = mode
	last_weapon = mode
	if mode == "pistol":
		rep["shots"] += 1
	c.attack(best)
	return true


func _watcher(p: Vector2):
	var c = main.commando
	for g in _guards():
		if not g.alive or g.state == &"combat" or g.carried:
			continue
		if main.level.interior_at(g.global_position) != main.cur_interior:
			continue
		var d: Vector2 = p - g.global_position
		if d.length() > g.view_range() * 1.05:
			continue
		if absf(wrapf(d.angle() - g.facing, -PI, PI)) > g.VIEW_HALF + 0.25:
			continue
		if main.level.has_los(g.global_position, p):
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
	if _watcher(ahead) != null and wait_t < 7.0:
		if wait_t == 0.0:
			rep["waits"] += 1
		wait_t += dt
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
	if main.game_over or t > float(opts["limit"]):
		_finish()
		return false
	var c = main.commando
	var m = main.mission
	repath_t -= dt
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
	if m.plant_target != null and m.bombs.is_empty():
		m.start_planting()
		return false
	if _fight(dt):
		return false
	# comelme: yakinda devriye varsa
	var near := false
	for g in _guards():
		if g.alive and g.state != &"combat" and g.global_position.distance_to(c.global_position) < 380.0:
			near = true
			break
	c.crouch = near and opts["style"] != "saldiri"
	# gizli tarz: ilerideki noktayi goren devriye varsa bekle; supheleniyorsa geri cekil
	if opts["style"] != "saldiri" and _stealth_hold(dt):
		return false
	var gl = _goal()
	if gl == null:
		return false
	if gl[0] != goal_key:
		goal_key = gl[0]
		repath_t = 0.0
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


func _finish() -> void:
	finished = true
	var c = main.commando
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
	var js := JSON.stringify(rep, "  ")
	print("BOT_RAPOR ", JSON.stringify(rep))
	if opts["out"] != "":
		var f := FileAccess.open(opts["out"], FileAccess.WRITE)
		f.store_string(js)
		f.close()
	quit(0)
