extends SceneTree
## Yeni bolumler icin erisim testi (Level.reach): baslangic -> her gorev -> cikis, devriye noktalari,
## karakterler, esyalar, kislalar, sirenler. Kilitli binalar anahtar varmis gibi kontrol edilir.
##   godot --headless --script res://tests/sim_bolum.gd -- --level=res://levels/bolum2.json

var main
var frame := 0
var fails := 0
var lvl_path := "res://levels/bolum2.json"


func _initialize() -> void:
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


func _inside_solid(v: Vector2) -> bool:
	for poly in main.level.move_polys:
		if Geometry2D.is_point_in_polygon(v, poly):
			return true
	return false


func _physics_process(_delta: float) -> bool:
	frame += 1
	if frame != 5:
		if frame == 12:
			print("SONUC: ", "BASARILI" if fails == 0 else "%d HATA" % fails)
			quit(1 if fails > 0 else 0)
		return false
	var lvl = main.level
	var map: RID = main.commando.navigation_agent.get_navigation_map()
	print("Bolum: ", lvl.data["name"], "  boyut ", lvl.size, "  asker ", lvl.data["guards"].size(),
		"  bina ", lvl.interiors.size(), "  kisla ", main.barracks.size(), "  siren ", lvl.sirens.size())
	# gorev zinciri sirayla
	var prev: Vector2 = lvl.start
	for o in main.mission.objectives:
		var p = null
		if o.has("pos"):
			p = Vector2(o["pos"][0], o["pos"][1])
		elif o["type"] == "rescue":
			p = main.mission.npcs[o["npc"]].global_position
		elif o["type"] == "exit":
			p = lvl.exit_rect.get_center()
		elif o["type"] == "have":
			for gd in main.get_tree().get_nodes_in_group("guards"):
				if gd.drops == o["item"]:
					p = gd.global_position
		if p == null:
			continue
		if o["type"] == "destroy" or o["type"] == "sabotage":
			# patlayici/sabotaj: yaricap icinde ulasilabilir bir nokta yeter
			var q: Vector2 = NavigationServer2D.map_get_closest_point(map, p)
			check(q.distance_to(p) < float(o.get("radius", 80)) - 8.0, "gorev noktasina yaklasilabilir: %s" % o["id"])
			p = q
		else:
			check(not _inside_solid(p), "gorev noktasi engel disinda: %s" % o["id"])
		check(lvl.reach(map, prev, p), "gorev zinciri: -> %s %s" % [o["id"], p])
		prev = p
	# devriyeler
	var bad := 0
	var gi := 0
	for gd in lvl.data["guards"]:
		for q in gd["path"]:
			var v := Vector2(q[0], q[1])
			if _inside_solid(v):
				print("    devriye noktasi engel icinde: asker ", gi, " ", v)
				bad += 1
			elif not lvl.reach(map, lvl.start, v):
				print("    devriye noktasina yol yok: asker ", gi, " ", v)
				bad += 1
		var areas := {}
		for q in gd["path"]:
			areas[lvl.interior_at(Vector2(q[0], q[1]))] = true
		if areas.size() > 1:
			print("    devriye ic/dis karisik: asker ", gi)
			bad += 1
		gi += 1
	check(bad == 0, "tum devriye noktalari gecerli (%d asker)" % gi)
	bad = 0
	for pk in lvl.pickups:
		if not lvl.reach(map, lvl.start, pk["pos"]):
			print("    esyaya yol yok: ", pk)
			bad += 1
	for bk in main.barracks:
		if not lvl.reach(map, bk[0], lvl.start):
			print("    kislaya yol yok: ", bk[0])
			bad += 1
	for sp in lvl.sirens:
		if not lvl.reach(map, lvl.start, sp):
			print("    sirene yol yok: ", sp)
			bad += 1
	for i in lvl.interiors.size():
		var it: Dictionary = lvl.interiors[i]
		if not lvl.reach(map, lvl.start, it["ext_door"]):
			print("    bina kapisina yol yok: ", it["name"])
			bad += 1
	check(bad == 0, "esya, kisla, siren ve bina kapilari erisilebilir")
	# zorluk olcutu: bir onceki bolumden buyuk ve kalabalik
	check(lvl.data["guards"].size() >= 30, "yeterli asker (%d)" % lvl.data["guards"].size())
	return false
