extends Control
## Buyuk harita: zemin + binalarin adlari, kislalar, gorevler, esyalar, cikis, komando.
## Dokunulan yere kamerayi gotur.

var main
var hud
var _k := 1.0
var _off := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _fit() -> void:
	var lvl = main.level
	_k = minf(size.x / lvl.size.x, size.y / lvl.size.y)
	_off = (size - lvl.size * _k) * 0.5


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
		_fit()
		var w: Vector2 = (e.position - _off) / _k
		if main.cur_interior < 0:
			main.cam.position = w
			main._clamp_cam()
		hud.close_big_map()


func _label(p: Vector2, text: String, col: Color, fs := 14) -> void:
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_rect(Rect2(p + Vector2(-w / 2 - 4, -fs - 2), Vector2(w + 8, fs + 8)), Color(0, 0, 0, 0.6))
	draw_string(font, p + Vector2(-w / 2, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _draw() -> void:
	_fit()
	var lvl = main.level
	var k := _k
	var o := _off
	if not lvl.ground_tiles0().is_empty():
		for t in lvl.ground_tiles0():
			var tr: Rect2 = t[1]
			draw_texture_rect(t[0], Rect2(o + tr.position * k, tr.size * k), false)
	else:
		draw_rect(Rect2(o, lvl.size * k), Color(0.3, 0.38, 0.22))
		for r in lvl.roads:
			draw_rect(Rect2(o + r.position * k, r.size * k), Color(0.5, 0.43, 0.3))
	draw_rect(Rect2(o, lvl.size * k), Color(0, 0, 0, 0.18))
	for poly in lvl.move_polys:
		var pts := PackedVector2Array()
		var inside := false
		for p in poly:
			if p.y > lvl.size.y:
				inside = true
			pts.append(o + p * k)
		if not inside:
			draw_colored_polygon(pts, Color(0.12, 0.1, 0.08, 0.55))
	# bina adlari
	for it in lvl.interiors:
		var r: Rect2 = it["rect"]
		draw_rect(Rect2(o + r.position * k, r.size * k), Color(0.95, 0.85, 0.5, 0.9), false, 2.0)
		_label(o + r.get_center() * k, it["name"], Color(1, 0.95, 0.75), 13)
	# kislalar
	for bk in main.barracks:
		_label(o + bk[0] * k + Vector2(0, 18), "Kışla (%d)" % bk[1], Color(1, 0.5, 0.4), 12)
	# kopruler
	for i in lvl.bridges.size():
		var br: Rect2 = lvl.bridges[i]
		var broken: bool = lvl.broken_bridges.has(br)
		_label(o + br.get_center() * k + Vector2(0, -12), "Köprü" + (" (yıkık)" if broken else ""), Color(0.85, 0.85, 1), 12)
	# esyalar
	for pk in lvl.pickups:
		if pk["taken"] or pk["pos"].y > lvl.size.y:
			continue
		draw_circle(o + pk["pos"] * k, 5, Color(1, 1, 1) if pk["type"] == "medkit" else Color(0.85, 0.75, 0.3))
	# cikis + baslangic
	_label(o + lvl.exit_rect.get_center() * k, "ÇIKIŞ", Color(0.5, 1, 0.5), 14)
	# gorevler (bitmemis olanlar, numarali)
	var n := 1
	for ob in main.mission.objectives:
		if ob["done"] or not ob.has("pos"):
			n += 1
			continue
		var p := Vector2(ob["pos"][0], ob["pos"][1])
		var bi: int = lvl.interior_at(p)
		if bi >= 0:
			p = lvl.interiors[bi]["rect"].get_center()
		draw_circle(o + p * k, 9, Color(1, 0.85, 0.2))
		draw_string(ThemeDB.fallback_font, o + p * k + Vector2(-4, 5), str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.BLACK)
		_label(o + p * k + Vector2(0, -16), ob["text"], Color(1, 0.9, 0.4), 12)
		n += 1
	# komando
	var cp: Vector2 = main.commando.global_position
	if main.cur_interior >= 0:
		cp = lvl.interiors[main.cur_interior]["rect"].get_center()
	draw_circle(o + cp * k, 7, Color(0.3, 1, 0.3))
	draw_arc(o + cp * k, 11, 0, TAU, 24, Color(1, 1, 1), 2.0)
