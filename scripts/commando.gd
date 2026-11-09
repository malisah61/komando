extends Node2D
## Oyuncu komandosu (Yesil Bere): yuru ve bicakla.

var main
var path := PackedVector2Array()
var speed := 115.0
var facing := 0.0
var alive := true
var target_guard = null
var repath := 0.0


func move_to(p: Vector2) -> void:
	target_guard = null
	path = main.find_path(position, p)


func attack(g) -> void:
	target_guard = g
	path = main.find_path(position, g.position)


func _process(delta: float) -> void:
	if main.game_over or not alive:
		queue_redraw()
		return
	if target_guard != null:
		if not target_guard.alive:
			target_guard = null
			path.clear()
		elif position.distance_to(target_guard.position) < 34.0:
			target_guard.kill()
			target_guard = null
			path.clear()
		else:
			repath -= delta
			if repath <= 0.0:
				repath = 0.3
				path = main.find_path(position, target_guard.position)
	if path.size() > 0:
		var d := path[0] - position
		if d.length() < 3.0:
			path.remove_at(0)
		else:
			facing = d.angle()
			position += d.normalized() * minf(speed * delta, d.length())
	queue_redraw()


func _draw() -> void:
	# hedef yolu
	for p in path:
		draw_circle(p - position, 3, Color(1, 1, 1, 0.5))
	if path.size() > 0:
		draw_arc(path[path.size() - 1] - position, 10, 0, TAU, 20, Color(1, 1, 1, 0.7), 2.0)
	# secili halkasi
	draw_arc(Vector2.ZERO, 17, 0, TAU, 28, Color(0.4, 1, 0.4, 0.9), 2.0)
	# govde
	draw_circle(Vector2.ZERO, 12, Color(0.1, 0.12, 0.08))
	draw_circle(Vector2.ZERO, 10, Color(0.3, 0.42, 0.2) if alive else Color(0.5, 0.2, 0.2))
	draw_circle(Vector2.from_angle(facing) * 3 + Vector2(-2, -2), 6, Color(0.15, 0.4, 0.15))   # yesil bere
	draw_line(Vector2.ZERO, Vector2.from_angle(facing - 0.5) * 16, Color(0.8, 0.8, 0.85), 2.0)  # bicak
