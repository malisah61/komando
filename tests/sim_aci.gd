extends SceneTree
## Tur 5: aci cevirme onbellegi testi (headless).
##   godot --headless -s res://tests/sim_aci.gd -- --level=res://levels/bolum5.json --kip=mobil|pc
## PC: dort aci da ilk karede bellekte. Telefon: bulunulan + iki komsu. Her basis ayni karede gecer,
## "Cevriliyor..." hic gorunmez, art arda / ters yon / ayni karede iki basis dogru aciya gelir,
## bellekte olmayan aciya basinca nesneler birkac kare icinde gelir.

var main
var frame := 0
var fails := 0
var kip := "mobil"
var _wait := 0


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FAIL ") + msg)
	if not ok:
		fails += 1


func _initialize() -> void:
	var lv := "res://levels/bolum5.json"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--level="):
			lv = a.substr(8)
		if a.begins_with("--kip="):
			kip = a.substr(6)
	load("res://scripts/level.gd").mode_override = kip
	var M = load("res://scripts/main.gd")
	M.level_choice = lv
	M.briefed = lv
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _press(step: int, want: int, what: String) -> void:
	var before: int = main.level.view
	main.rotate_view(step)
	check(main.level.view == want, "%s: %d -> %d (beklenen %d), ayni karede" % [what, before, main.level.view, want])
	check(not main.hud.busy_label.visible, "%s: \"Çevriliyor…\" yok" % what)
	check(is_equal_approx(main.cam.rotation, main.level.view_rot), "%s: kamera ayni karede dondu" % what)


func _visible_view_nodes(k: int) -> int:
	var n := 0
	for kk in main.level._views:
		for nd in main.level._views[kk]["nodes"]:
			if nd.visible and kk != k:
				n += 1000000
			elif nd.visible:
				n += 1
	return n


func _process(_d: float) -> bool:
	frame += 1
	var L = main.level
	if frame == 3:
		print("Bolum: %s  kip: %s" % [L.data["name"], kip])
		if not L.art or not L.has_view(1):
			print("  (render yok, test atlandi)")
			quit(0)
			return false
		var res: Array = L.views_resident()
		if kip == "pc":
			check(res == [0, 1, 2, 3], "PC: dort aci yukleme ekraninda bellekte %s" % str(res))
		else:
			check(res == [0, 1, 3], "telefon: bulunulan + iki komsu bellekte %s" % str(res))
		_press(1, 1, "ileri")
	elif frame == 4:
		check(_visible_view_nodes(1) > 0 and _visible_view_nodes(1) < 1000000, "yalniz bakilan acinin sprite'lari gorunur (sert kesme)")
	elif frame == 40:
		_wait += 1
		if kip != "pc" and L.views_resident() != [0, 1, 2] and _wait < 3000:
			frame -= 1          # arka planda kurulmasini bekle (headless kareler cok hizli)
			return false
		if kip != "pc":
			check(L.views_resident() == [0, 1, 2], "telefon: komsular guncellendi %s" % str(L.views_resident()))
		_press(-1, 0, "geri")
		_press(-1, 3, "ayni karede ikinci geri")
	elif frame == 41:
		_press(-1, 2, "art arda ucuncu geri")
	elif frame == 42:
		var vs: Dictionary = L._views.get(2, {})
		check(not vs.is_empty(), "bellekte olmayan aci bile hemen gosterildi (zemin onizlemesi)")
	elif frame == 120:
		_wait += 1
		if not (L._views.has(2) and L._views[2]["ready"]) and _wait < 6000:
			frame -= 1
			return false
		check(L._views.has(2) and L._views[2]["ready"], "onizlemeden sonra nesneler geldi (aci 2 kurulu)")
		check(_visible_view_nodes(2) > 0 and _visible_view_nodes(2) < 1000000, "aci 2 sprite'lari gorunur, digerleri gizli")
		var roofs_ok := true
		for a in L._areas:
			if a.roof_node != null and not L._views[2]["nodes"].has(a.roof_node):
				roofs_ok = false
		check(roofs_ok, "catilar bakilan aciya bagli")
		_press(2, 0, "iki adim (2)")
	elif frame == 200:
		_wait += 1
		if kip != "pc" and L.views_resident() != [0, 1, 3] and _wait < 9000:
			frame -= 1
			return false
		var want: Array = [0, 1, 2, 3] if kip == "pc" else [0, 1, 3]
		check(L.views_resident() == want, "sonunda bellekteki acilar %s" % str(L.views_resident()))
		print("SONUC: ", "BASARILI" if fails == 0 else "%d HATA" % fails)
		quit(1 if fails > 0 else 0)
	return false
