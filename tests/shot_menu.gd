extends SceneTree
## Tur 9: bolum secim menusu kaydirma testi + ekran goruntusu.
##   xvfb-run godot -s res://tests/shot_menu.gd -- --out=/tmp/menu      (headless da calisir, goruntu almaz)
## Kontrol: tum bolumler listede, liste ekrandan uzunsa kaydirilabilir, surukleyip birakmak bolum SECMEZ,
## kaydirdiktan sonra son bolume dokunmak onu secer.

var main
var f := 0
var fails := 0
var out := ""
var scroll
var chosen := ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	var M = load("res://scripts/main.gd")
	M.level_choice = ""
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func check(cond: bool, msg: String) -> void:
	print(("  OK   " if cond else "  FAIL ") + msg)
	if not cond:
		fails += 1


func _find_scroll(n: Node):
	for ch in n.get_children():
		if ch is ScrollContainer and ch.has_method("tap_ok"):
			return ch
		var r = _find_scroll(ch)
		if r != null:
			return r
	return null


func _mouse(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	root.push_input(e)


func _motion(pos: Vector2, rel: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos
	e.global_position = pos
	e.relative = rel
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(e)


func _shot(name: String) -> void:
	if out != "" and DisplayServer.get_name() != "headless":
		root.get_texture().get_image().save_png("%s_%s.png" % [out, name])


func _process(_d: float) -> bool:
	f += 1
	if f == 8:
		scroll = _find_scroll(main.hud)
		check(scroll != null, "bolum listesi kaydirilabilir kapta")
		var list: Control = scroll.get_child(0)
		var n: int = list.get_child_count()
		check(n == main.LEVELS.size(), "listede tum bolumler (%d)" % n)
		var vh: float = root.get_visible_rect().size.y
		check(scroll.get_global_rect().end.y <= vh + 1.0, "liste ekranin icinde bitiyor (alt dugmeler gorunur)")
		check(list.size.y > scroll.size.y, "liste ekrandan uzun: kaydirma gerekli (%d > %d px)" % [list.size.y, scroll.size.y])
		# bolum secimini yakala (sahne yeniden yuklenmesin)
		for b in list.get_children():
			for c in b.pressed.get_connections():
				b.pressed.disconnect(c["callable"])
			var bb: Button = b
			b.pressed.connect(func():
				if scroll.tap_ok():
					chosen = bb.text.get_slice("\n", 0))
		_shot("1_ust")
	if f == 10 and DisplayServer.get_name() == "headless":
		print("  (headless: dokunus olaylari islenmez, kaydirma adimlari atlandi - xvfb-run ile calistir)")
		print("SONUC: ", "BASARILI" if fails == 0 else "%d HATA" % fails)
		quit(1 if fails > 0 else 0)
		return false
	if f == 10:
		# surukle: listenin ortasindan yukari 400 px
		var c: Vector2 = scroll.get_global_rect().get_center()
		_mouse(c, true)
		for k in 20:
			_motion(c - Vector2(0, 20 * (k + 1)), Vector2(0, -20))
		_mouse(c - Vector2(0, 400), false)
	if f == 14:
		check(scroll.scroll_vertical > 150, "surukleyince liste kaydi (%d px)" % scroll.scroll_vertical)
		check(chosen == "", "surukleyip birakmak bolum secmedi")
		scroll.scroll_vertical = 100000
	if f == 18:
		_shot("2_alt")
		var list: Control = scroll.get_child(0)
		var last: Button = list.get_child(list.get_child_count() - 1)
		var p: Vector2 = last.get_global_rect().get_center()
		check(scroll.get_global_rect().has_point(p), "son bolum kaydirinca gorunur")
		_mouse(p, true)
	if f == 19:
		var list: Control = scroll.get_child(0)
		var last: Button = list.get_child(list.get_child_count() - 1)
		_mouse(last.get_global_rect().get_center(), false)
	if f == 22:
		check(chosen.begins_with(main.LEVELS[main.LEVELS.size() - 1][1]), "son bolume dokununca secildi (%s)" % chosen)
		print("SONUC: ", "BASARILI" if fails == 0 else "%d HATA" % fails)
		quit(1 if fails > 0 else 0)
	return false
