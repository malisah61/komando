extends Node2D
## Tur 6: disaridaki pencere isaretleri (cati ve duvar sprite'larinin ustunde cizilir, her acida gorunur).
## Komando yakindayken soluk; pencereye dokununca / girilemeyince yanip sonen halka + "pencere" / "kilitli".

var main
var _t := 0.0


func _process(delta: float) -> void:
	_t -= delta
	if _t <= 0.0 or not main.level.window_hint.is_empty():
		_t = 0.2
		queue_redraw()


func _draw() -> void:
	var lvl = main.level
	if main.cur_interior >= 0 and not main.peeking:
		return
	var cp: Vector2 = main.commando.global_position
	var font := ThemeDB.fallback_font
	for w in lvl.windows:
		var hint: float = lvl.window_hint.get(w["i"], 0.0)
		var e: Vector2 = w["ext"]
		if hint <= 0.0 and (main.cur_interior >= 0 or e.distance_to(cp) > 220.0):
			continue
		var o: Vector2 = w["out"]
		var along := Vector2(-o.y, o.x)
		var lk: bool = main.is_locked(w["b"])
		var col := Color(1.0, 0.6, 0.2, 0.9) if lk else Color(0.55, 0.85, 1.0, 0.85)
		var q: Vector2 = e - o * 6.0
		draw_line(q - along * 11.0, q + along * 11.0, col, 3.0)
		draw_line(q - along * 11.0, q - along * 11.0 + o * 7.0, col, 2.0)
		draw_line(q + along * 11.0, q + along * 11.0 + o * 7.0, col, 2.0)
		if hint > 0.0:
			draw_arc(e, 16.0 + 4.0 * sin(Time.get_ticks_msec() / 120.0), 0.0, TAU, 18, col, 2.0)
			draw_set_transform(e, lvl.view_rot, Vector2.ONE)
			draw_string(font, Vector2(-26, -22), "kilitli" if lk else "pencere", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
