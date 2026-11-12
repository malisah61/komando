extends Control
## Sol ustteki mini harita. Dokun / surukle: kamerayi oraya tasi.

var main


var _static: Control      # zemin + engeller: sadece degisince cizilir (performans)


class StaticLayer extends Control:
	var mm
	func _draw() -> void:
		mm._draw_static(self)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_static = StaticLayer.new()
	_static.mm = self
	_static.show_behind_parent = true
	_static.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_static.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_static)
	main.level.changed_map.connect(func(): _static.queue_redraw())


var _t := 0.0


func _process(delta: float) -> void:
	# 10 Hz yeterli: her karede 200+ cokgen cizmek gereksiz
	_t -= delta
	if _t <= 0.0:
		_t = 0.1
		queue_redraw()


func _gui_input(e: InputEvent) -> void:
	# mini haritaya dokun: buyuk harita acilsin
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
		accept_event()
		main.hud.show_big_map()


func _scale() -> float:
	var s: Vector2 = size / main.level.size
	return minf(s.x, s.y)


func _draw() -> void:
	if main == null or main.level == null:
		return
	var lvl = main.level
	var k := _scale()
	draw_rect(Rect2(lvl.exit_rect.position * k, lvl.exit_rect.size * k), Color(0.3, 0.9, 0.4, 0.6))
	if not lvl.document_taken and lvl.interior_at(lvl.document_pos) < 0:
		draw_circle(lvl.document_pos * k, 3.5, Color(1, 0.9, 0.2))
	for sp in lvl.sirens:
		draw_circle(sp * k, 2.5, Color(1, 0.3, 0.9))
	for g in get_tree().get_nodes_in_group("guards"):
		if g.global_position.y > lvl.size.y:
			continue
		var col := Color(0.95, 0.25, 0.2) if g.alive else Color(0.35, 0.35, 0.35)
		if g.alive and g.suspicion > 0.0:
			col = Color(1, 0.85, 0.2)
		draw_circle(g.global_position * k, 3.0, col)
	if main.commando:
		var cp: Vector2 = main.commando.global_position
		if main.cur_interior >= 0:
			cp = main.level.interiors[main.cur_interior]["rect"].get_center()
		draw_circle(cp * k, 4.0, Color(0.4, 1, 0.4))
	# kamera gorus alani
	var vp: Vector2 = get_viewport_rect().size / main.cam.zoom
	var r := Rect2((main.cam.position - vp / 2) * k, vp * k)
	draw_rect(r, Color(1, 1, 1, 0.8), false, 1.5)
	draw_rect(Rect2(Vector2.ZERO, lvl.size * k), Color(0, 0, 0, 0.8), false, 2.0)


func _draw_static(c: Control) -> void:
	var lvl = main.level
	var k := _scale()
	if not lvl.ground_tiles0().is_empty():
		for t in lvl.ground_tiles0():
			var tr: Rect2 = t[1]
			c.draw_texture_rect(t[0], Rect2(tr.position * k, tr.size * k), false)
	elif lvl.ground_tex != null:
		c.draw_texture_rect(lvl.ground_tex, Rect2(Vector2.ZERO, lvl.size * k), false)
	else:
		c.draw_rect(Rect2(Vector2.ZERO, lvl.size * k), Color(0.3, 0.38, 0.22, 0.92))
		for r in lvl.roads:
			c.draw_rect(Rect2(r.position * k, r.size * k), Color(0.5, 0.43, 0.3))
		for s in lvl.surfaces:
			var pts := PackedVector2Array()
			for p in s["points"]:
				pts.append(p * k)
			c.draw_colored_polygon(pts, s["color"].darkened(0.1))
	for poly in lvl.move_polys:
		if poly[0].y > lvl.size.y:
			continue          # bina ici (harita disinda)
		var pts := PackedVector2Array()
		for p in poly:
			pts.append(p * k)
		c.draw_colored_polygon(pts, Color(0.2, 0.18, 0.14, 0.75) if lvl.art else Color(0.75, 0.68, 0.55))
