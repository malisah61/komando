extends SceneTree
## Tur 7 testi: ekip (Reilly + Sahin). Karakter gecisi, izle/bekle, Sahin'in durbunlu tufegi (nisan alma,
## menzil, tek atis, ses), nisanci yerinden gozculer (gorus var, gozculer nisanciyi goremez), "eliminate" gorevi,
## kacista ikisi de gerekli, Sahin olurse gorev biter, kayit (ekip + secili komando) ve eski kayitlarla uyum.
##   godot --headless --script res://tests/sim_ekip.gd -- --level=res://levels/bolum8.json

const Kayit = preload("res://scripts/kayit.gd")
var main
var f := 0
var fails := 0
var step := 0
var wait := 0.0
var lvl_path := "res://levels/bolum8.json"
var sn
var rb
var gz: Array = []
var _t := 0.0
var _aimed := false
var _shots0 := 0


func _initialize() -> void:
	seed(7)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--level="):
			lvl_path = a.substr(8)
	Kayit.dir_override = "user://test_ekip"
	DirAccess.make_dir_recursive_absolute(Kayit.dir_override)
	var M = load("res://scripts/main.gd")
	M.level_choice = lvl_path
	M.briefed = lvl_path
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func check(cond: bool, msg: String) -> void:
	print(("  OK   " if cond else "  FAIL ") + msg)
	if not cond:
		fails += 1


func _end() -> void:
	print("SONUC: ", "BASARILI" if fails == 0 else "%d HATA" % fails)
	quit(1 if fails > 0 else 0)


func _obj(id: String) -> Dictionary:
	for o in main.mission.objectives:
		if o["id"] == id:
			return o
	return {}


func _process(d: float) -> bool:
	f += 1
	if main.hud != null:
		var n := 0
		while main.hud.dialog_panel.visible and n < 30:
			main.hud._next_line()
			n += 1
		if main.get_tree().paused and not main.hud.dialog_panel.visible:
			main.get_tree().paused = false
	if wait > 0.0:
		wait -= d
		return false
	var lvl = main.level
	match step:
		0:
			if f < 6:
				return false
			check(main.team.size() == 2, "ekipte iki komando (%d)" % main.team.size())
			rb = main.team[0]
			sn = main.team[1]
			check(rb.role == "bere" and sn.role == "nisanci" and main.commando == rb, "Reilly secili, Sahin nisanci")
			check(sn.weapon == "rifle" and not ("knife" in sn.allowed_weapons()) and sn.rifle_ammo == 6, "Sahin: tufek (6 mermi), bicak yok")
			check(sn in main.players or sn.is_in_group("player"), "Sahin de askerlerin gordugu oyuncu karakteri")
			for x in main.get_tree().get_nodes_in_group("guards"):
				x.set_physics_process(false)
				if x.tag == "gozcu":
					gz.append(x)
				else:
					x.global_position = Vector2(-9000, -9000)
			check(gz.size() == 2, "iki gozcu (tag=gozcu)")
			for u in main.team:
				u.max_hp = 99999
				u.hp = 99999
			# izle: Reilly yurur, Sahin arkasindan gelir
			check(sn.follow, "Sahin baslangicta Reilly'yi izliyor")
			rb.move_to(rb.global_position + Vector2(260, -200))
			wait = 5.0
			step = 1
		1:
			check(sn.global_position.distance_to(rb.global_position) < 70.0, "izleyen Sahin Reilly'nin yaninda (%d px)" % int(sn.global_position.distance_to(rb.global_position)))
			# bekle: Sahin yerinde kalir ve comelir
			main.set_team_follow(false)
			check(not sn.follow and sn.crouch, "bekle: Sahin comeldi")
			_t = 0.0
			rb.move_to(rb.global_position + Vector2(300, 0))
			gz[0].set_meta("p0", sn.global_position)
			wait = 4.0
			step = 2
		2:
			check(sn.global_position.distance_to(gz[0].get_meta("p0")) < 8.0, "bekleyen Sahin yerinden oynamadi")
			# gecis: 2 -> Sahin secili, kamera ona doner, HUD tufek
			var ok: bool = main.select_unit(1)
			check(ok and main.commando == sn and sn.selected and not rb.selected, "karakter gecisi: Sahin secildi")
			check(main.cam.position.distance_to(sn.global_position) < 400.0, "kamera Sahin'e gecti")
			check(main.hud.knife_btn.text.begins_with("Tüfek") and main.hud.pistol_btn.disabled, "HUD: Sahin'de Tufek dugmesi, tabanca yok")
			main.cycle_unit()
			check(main.commando == rb and main.hud.knife_btn.text == "Bıçak", "Tab: Reilly'ye geri dondu, HUD Bicak")
			main.select_unit(1)
			main.set_team_follow(true)
			# nisanci yeri: iki gozcuyu gorur, menzil icinde; gozculer onu goremez
			var spot := Vector2(_obj("gozcu")["spot"][0], _obj("gozcu")["spot"][1])
			sn.global_position = spot
			sn.move_to(spot)
			sn.crouch = true
			rb.global_position = spot + Vector2(-40, 30)
			rb.move_to(rb.global_position)
			for g in gz:
				var dd: float = spot.distance_to(g.global_position)
				check(dd <= sn.RIFLE_RANGE and lvl.has_los(spot, g.global_position, true), "nisanci yerinden gozcu gorunuyor ve menzilde (%d px)" % int(dd))
				check(not g.can_see(spot, true), "gozcu comelik nisanciyi goremez")
				g.set_physics_process(true)
			check(lvl.is_inside_view_blocker(spot), "nisanci yeri calilikta (gizli)")
			_shots0 = int(main.stats.get("rifle", 0))
			sn.attack(gz[0])
			_t = 0.0
			_aimed = false
			step = 3
		3:
			_t += d
			if sn._aim_t > 0.3:
				_aimed = true
			if sn.global_position.distance_to(Vector2(_obj("gozcu")["spot"][0], _obj("gozcu")["spot"][1])) > 6.0:
				gz[0].set_meta("moved", true)
			if not gz[0].alive or _t > 12.0:
				check(_aimed, "Sahin durup nisan aldi")
				check(not gz[0].has_meta("moved"), "Sahin calidan cikmadan (yerinden) vurdu")
				check(not gz[0].alive, "gozcu 1 vuruldu (%.1f sn)" % _t)
				check(_t >= sn.RIFLE_AIM * 0.9, "nisan suresi bekledi (aninda ates yok)")
				check(sn.rifle_ammo < 6, "tufek mermisi azaldi (%d)" % sn.rifle_ammo)
				check(not _obj("gozcu")["done"], "tek gozcuyle gorev bitmedi")
				check(main.alert_level <= 1 and int(main.stats.get("sniped_seen", 0)) == 0 and main.runner == null, "taniksiz uzak atis: ceset bulunmadi, kirmizi alarm yok (silah sesi yalniz sari) (alarm %d, tanik %d)" % [main.alert_level, int(main.stats.get("sniped_seen", 0))])
				sn.attack(gz[1])
				_t = 0.0
				step = 4
		4:
			_t += d
			if not gz[1].alive or _t > 14.0:
				check(not gz[1].alive, "gozcu 2 vuruldu")
				wait = 0.3
				step = 5
		5:
			check(_obj("gozcu")["done"], "eliminate gorevi tamam: gozculer susturuldu")
			check(int(main.stats.get("rifle", 0)) - _shots0 >= 2, "tufek atislari sayildi")
			# tanik: vurulan askerin dustugunu goren arkadasi cesedi bulur ve atisin geldigi yone dogru arar
			var others: Array = []
			for x in main.get_tree().get_nodes_in_group("guards"):
				if x.alive and x.tag == "" and x.kind != "kule" and others.size() < 2:
					others.append(x)
			var v = others[0]
			var h = others[1]
			var vp: Vector2 = sn.global_position + Vector2(480, 120)
			var map: RID = sn.navigation_agent.get_navigation_map()
			vp = NavigationServer2D.map_get_closest_point(map, vp)
			v.global_position = vp
			h.global_position = NavigationServer2D.map_get_closest_point(map, vp + Vector2(150, 30))
			h.facing = (vp - h.global_position).angle()
			h.base_facing = h.facing
			h.state = &"patrol"
			gz.append(v)
			gz.append(h)
			sn._cool = 0.0
			sn.rifle_ammo = 3
			sn.attack(v)
			_t = 0.0
			step = 50
		50:
			_t += d
			if not gz[2].alive or _t > 10.0:
				var h = gz[3]
				var vp: Vector2 = gz[2].global_position
				check(not gz[2].alive, "tanikli atis: hedef vuruldu")
				check(int(main.stats.get("sniped_seen", 0)) == 1 and main.alert_level >= 1, "tanik dusmeyi gordu: ceset bulundu, sari alarm")
				check(h.state == &"investigate" and h.investigate_pos.distance_to(sn.global_position) < vp.distance_to(sn.global_position) - 100.0,
						"tanik atisin geldigi yone dogru arar (%d px nisanciya yaklasti)" % int(vp.distance_to(sn.global_position) - h.investigate_pos.distance_to(sn.global_position)))
				main.set_alert_level(0)
				main.alarm_t = 0.0
				main.runner = null
				step = 51
		51:
			# kayit: ekip + secili komando
			for x in main.get_tree().get_nodes_in_group("guards"):
				if x.alive:
					x.state = &"patrol"
					x.suspicion = 0.0
			var st: Dictionary = Kayit.capture(main)
			check(st.has("ekip") and st["ekip"].size() == 1 and int(st["secili"]) == 1, "kayit: ekip ve secili komando yazildi")
			var sp: Vector2 = sn.global_position
			var am: int = sn.rifle_ammo
			main.select_unit(0)
			sn.global_position = Vector2(100, 100)
			sn.rifle_ammo = 0
			Kayit.apply(main, st)
			check(sn.global_position.distance_to(sp) < 1.0 and sn.rifle_ammo == am, "yukle: Sahin'in yeri ve mermisi geri geldi")
			check(main.commando == sn, "yukle: secili komando (Sahin) geri geldi")
			# eski kayit (Tur 6 bicimi: ekip/secili yok) sorunsuz acilir
			var old: Dictionary = st.duplicate(true)
			old.erase("ekip")
			old.erase("secili")
			old["komando"]["disguise"] = true
			main.select_unit(0)
			var warn: String = Kayit.apply(main, old)
			check(main.commando == rb and warn == "", "eski kayit (ekip yok, disguise var) sessizce acildi")
			# kacis: ikisi de gecitte olmali
			for o in main.mission.objectives:
				if o["type"] != "exit":
					o["done"] = true
			var ex: Rect2 = lvl.exit_rect
			rb.global_position = ex.get_center()
			rb.move_to(rb.global_position)
			main.set_team_follow(false)
			sn.global_position = ex.get_center() + Vector2(900, 900)
			sn.move_to(sn.global_position)
			wait = 1.0
			step = 6
		6:
			check(not main.game_over, "Sahin gecitte degilken kacis olmadi")
			sn.global_position = ex_center() + Vector2(20, 10)
			sn.move_to(sn.global_position)
			wait = 0.6
			step = 7
		7:
			if not main.game_over:
				print("    dbg: req_left=%d rb_in=%s sn_in=%s rb=%s ex=%s" % [main.mission.required_left(), main.level.exit_rect.has_point(rb.global_position), main.level.exit_rect.has_point(sn.global_position), rb.global_position, main.level.exit_rect])
			check(main.game_over and main.end_text.begins_with("GÖREV TAMAMLANDI"), "ikisi de gecitte: gorev tamamlandi")
			_end()
	return false


func ex_center() -> Vector2:
	return main.level.exit_rect.get_center()
