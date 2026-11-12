extends SceneTree
## Kayit sistemi testi (Tur 4): durum degistir -> kaydet -> yeni sahnede yukle -> ayni mi?
## Ayrica: catismada kaydetme engeli, bozuk / gelecek surum / eski surum dosyalari, "after" metin duzeltmesi,
## yukleme suresi.
##   godot --headless -s res://tests/sim_kayit.gd -- --level=res://levels/bolum4.json

const Kayit = preload("res://scripts/kayit.gd")
var M
var main
var frame := 0
var fails := 0
var lvl_path := "res://levels/bolum4.json"
var phase := 0
var before := {}
var t_load := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--level="):
			lvl_path = a.substr(8)
	Kayit.dir_override = "user://test_kayit"
	DirAccess.make_dir_recursive_absolute(Kayit.dir_override)
	for s in Kayit.SLOTS:
		DirAccess.remove_absolute(Kayit.slot_path(s))
	M = load("res://scripts/main.gd")
	M.level_choice = lvl_path
	M.briefed = lvl_path
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func check(cond: bool, msg: String) -> void:
	print(("  OK   " if cond else "  FAIL ") + msg)
	if not cond:
		fails += 1


func _guards() -> Array:
	return main.get_tree().get_nodes_in_group("guards")


func _summary() -> Dictionary:
	var dead := 0
	var knocked := 0
	var pos_sum := Vector2.ZERO
	for g in _guards():
		if not g.alive:
			dead += 1
		if g.knocked:
			knocked += 1
		pos_sum += g.global_position
	var cut := 0
	for w in main.level.wires:
		if w["cut"]:
			cut += 1
	var done := []
	for o in main.mission.objectives:
		if o["done"]:
			done.append(o["id"])
	var taken := 0
	for pk in main.level.pickups:
		if pk["taken"]:
			taken += 1
	return {"guards": _guards().size(), "dead": dead, "knocked": knocked, "pos": (pos_sum / 5000.0).round(), "cut": cut,
		"done": done, "items": main.mission.items.duplicate(), "c_pos": main.commando.global_position.round(),
		"hp": main.commando.hp, "ammo": main.commando.ammo, "stones": main.commando.stones,
		"disguise": main.commando.disguise, "pickups": main.level.pickups.size(), "taken": taken,
		"alert": main.alert_level, "barracks": main.barracks.map(func(b): return b[1]),
		"elapsed": snappedf(main.mission.elapsed, 1.0)}


func _physics_process(_delta: float) -> bool:
	frame += 1
	if phase == 0 and frame == 6:
		print("Bolum: ", main.level.data["name"])
		# "after" metin duzeltmesi: tek metin listeye cevrildi
		var ok_after := true
		for o in main.mission.objectives:
			if o.has("after") and not (o["after"] is Array):
				ok_after = false
		check(ok_after, "\"after\" hep liste (metin olarak yazilanlar da)")
		# durumu degistir
		var gs := _guards()
		var c = main.commando
		gs[0].kill()
		gs[1].knock_out()
		gs[1].tied = true
		if gs.size() > 3:
			gs[3].stripped = true
			c.disguise = "er"
		gs[2].global_position += Vector2(30, 0)
		if main.level.wires.size() > 0:
			main.level.cut_wire(0)
		c.global_position = gs[2].global_position + Vector2(0, 60)
		c.hp = 61.0
		c.ammo = 5
		c.stones = 2
		var o0 = main.mission.objectives[0]
		main.mission._complete(o0)
		main.mission.items["patlayici"] = 2
		if main.level.pickups.size() > 0:
			main.level.pickups[0]["taken"] = true
		main.barracks[0][1] = 1
		main.set_alert_level(1)
		main.mission.elapsed = 100.0
		# catismada kaydedilemez
		gs[4].state = &"combat"
		check(Kayit.why_not(main) != "", "catismada kaydetme engelli: " + Kayit.why_not(main))
		gs[4].state = &"patrol"
		check(Kayit.why_not(main) == "", "sakinken kaydedilebilir")
		var err: String = Kayit.save(main, "1")
		check(err == "", "yuva 1'e kaydedildi " + err)
		before = _summary()
		var inf: Dictionary = Kayit.info("1")
		check(inf.get("surum", 0) == Kayit.VERSION and inf.get("bolum", "") == lvl_path, "ust bilgi: surum %s, gorev %s" % [inf.get("surum"), inf.get("gorev")])
		check(Kayit.latest(lvl_path) == "1", "en yeni kayit yuva 1")
		# bozuk / gelecek surum dosyalari
		var f := FileAccess.open(Kayit.slot_path("2"), FileAccess.WRITE)
		f.store_string("{bozuk")
		f.close()
		check(Kayit.read("2").has("hata"), "bozuk dosya reddedildi (cokmez)")
		var fut = JSON.parse_string(FileAccess.get_file_as_string(Kayit.slot_path("1")))
		fut["surum"] = Kayit.VERSION + 1
		f = FileAccess.open(Kayit.slot_path("3"), FileAccess.WRITE)
		f.store_string(JSON.stringify(fut))
		f.close()
		check(Kayit.read("3").has("hata"), "gelecek surum kaydi reddedildi: " + str(Kayit.read("3").get("hata")))
		# eski surum (0): eksik alanlarla bile yuklenir
		var old = JSON.parse_string(FileAccess.get_file_as_string(Kayit.slot_path("1")))
		old["surum"] = 0
		old["durum"] = var_to_str({"komando": {"pos": c.global_position}})
		f = FileAccess.open(Kayit.slot_path("hizli"), FileAccess.WRITE)
		f.store_string(JSON.stringify(old))
		f.close()
		check(not Kayit.read("hizli").has("hata"), "eski surum (0) kaydi okunur")
		# yeni sahnede yukle
		var e2: String = M.prepare_load("1")
		check(e2 == "", "yukleme hazir " + e2)
		t_load = Time.get_ticks_msec()
		root.remove_child(main)
		main.queue_free()
		main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		t_load = Time.get_ticks_msec() - t_load
		phase = 1
		frame = 0
	elif phase == 1 and frame == 4:
		var after := _summary()
		print("  yukleme (sahne kurulumu + kayit uygulama): %d ms" % t_load)
		for k in before:
			check(str(before[k]) == str(after[k]), "%s: %s == %s" % [k, before[k], after[k]])
		check(main.hud.toast_label.text.begins_with("Kayıt yüklendi") or main.hud.toast_label.text != "", "bildirim: " + main.hud.toast_label.text)
		# eski surum kaydini da yukle (cokmemeli)
		check(M.prepare_load("hizli") == "", "eski surum kaydi hazir")
		root.remove_child(main)
		main.queue_free()
		main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		phase = 2
		frame = 0
	elif phase == 2 and frame == 4:
		check(main.commando != null and main.mission != null, "eski surum kaydi yuklendi, oyun kuruldu")
		print("SONUC: ", "BASARILI" if fails == 0 else "%d HATA" % fails)
		quit(1 if fails > 0 else 0)
	return false
