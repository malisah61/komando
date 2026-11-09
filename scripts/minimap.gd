extends Control
## Sol ustteki mini harita. Dokun / surukle: kamerayi oraya tasi.

var main


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true


func _process(_delta: float) -> void:
	queue_redraw()


func _gui_input(e: InputEvent) -> void:
	var down := false
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
		down = true
	elif e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		down = true
	if down:
		main.cam.position = (e.position / _scale()).clamp(Vector2.ZERO, main.level.size)
		accept_event()


func _scale() -> float:
	var s: Vector2 = size / main.level.size
	return minf(s.x, s.y)


func _draw() -> void:
	if main == null or main.level == null:
		return
	var lvl = main.level
	var k := _scale()
	draw_rect(Rect2(Vector2.ZERO, lvl.size * k), Color(0.3, 0.38, 0.22, 0.92))
	for r in lvl.roads:
		draw_rect(Rect2(r.position * k, r.size * k), Color(0.5, 0.43, 0.3))
	for s in lvl.surfaces:
		var pts := PackedVector2Array()
		for p in s["points"]:
			pts.append(p * k)
		draw_colored_polygon(pts, s["color"].darkened(0.1))
	for poly in lvl.move_polys:
		var pts := PackedVector2Array()
		for p in poly:
			pts.append(p * k)
		draw_colored_polygon(pts, Color(0.75, 0.68, 0.55))
	draw_rect(Rect2(lvl.exit_rect.position * k, lvl.exit_rect.size * k), Color(0.3, 0.9, 0.4, 0.6))
	if not lvl.document_taken:
		draw_circle(lvl.document_pos * k, 3.5, Color(1, 0.9, 0.2))
	for g in get_tree().get_nodes_in_group("guards"):
		var col := Color(0.95, 0.25, 0.2) if g.alive else Color(0.35, 0.35, 0.35)
		if g.alive and g.suspicion > 0.0:
			col = Color(1, 0.85, 0.2)
		draw_circle(g.global_position * k, 3.0, col)
	if main.commando:
		draw_circle(main.commando.global_position * k, 4.0, Color(0.4, 1, 0.4))
	# kamera gorus alani
	var vp: Vector2 = get_viewport_rect().size / main.cam.zoom
	var r := Rect2((main.cam.position - vp / 2) * k, vp * k)
	draw_rect(r, Color(1, 1, 1, 0.8), false, 1.5)
	draw_rect(Rect2(Vector2.ZERO, lvl.size * k), Color(0, 0, 0, 0.8), false, 2.0)
