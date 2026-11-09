extends Node2D
## Dusman askeri: devriye, gorus konisi, supheleme, ceset fark etme.

const VIEW_RANGE := 230.0
const VIEW_HALF := 0.56          # ~32 derece
const RAYS := 28

var main
var waypoints: Array = []
var wp_i := 0
var speed := 55.0
var facing := 0.0
var base_facing := 0.0
var wait := 0.0
var t := 0.0
var alive := true
var discovered := false          # cesedi bulundu mu
var suspicion := 0.0
var cone := PackedVector2Array()


func _process(delta: float) -> void:
	if not alive:
		return
	t += delta
	if not main.game_over:
		_patrol(delta)
		_watch(delta)
	_update_cone()
	queue_redraw()


func _patrol(delta: float) -> void:
	if waypoints.size() <= 1:
		# sabit nobetci: saga sola bakar
		facing = base_facing + sin(t * 0.7) * 0.9
		return
	if wait > 0.0:
		wait -= delta
		facing += sin(t * 2.0) * delta * 0.8
		return
	var target: Vector2 = waypoints[wp_i]
	var to := target - position
	if to.length() < 3.0:
		wp_i = (wp_i + 1) % waypoints.size()
		wait = 1.4
		return
	facing = lerp_angle(facing, to.angle(), minf(1.0, delta * 5.0))
	position += to.normalized() * minf(speed * delta, to.length())


func can_see(p: Vector2) -> bool:
	var d := p - position
	if d.length() > VIEW_RANGE:
		return false
	if absf(wrapf(d.angle() - facing, -PI, PI)) > VIEW_HALF:
		return false
	return main.has_los(position, p)


func _watch(delta: float) -> void:
	var seen := false
	var c = main.commando
	if c.alive and can_see(c.position):
		seen = true
		var close := position.distance_to(c.position) < 120.0
		suspicion += delta * (2.5 if close else 1.1)
	for g in main.guards:
		if g != self and not g.alive and not g.discovered and can_see(g.position):
			seen = true
			suspicion += delta * 1.5
			if suspicion >= 1.0:
				g.discovered = true
	if not seen:
		suspicion = maxf(0.0, suspicion - delta * 0.4)
	if suspicion >= 1.0:
		main.alarm()


func _update_cone() -> void:
	cone.clear()
	cone.append(Vector2.ZERO)
	for i in RAYS + 1:
		var a := facing - VIEW_HALF + (VIEW_HALF * 2.0) * float(i) / RAYS
		var end: Vector2 = main.ray_end(position, position + Vector2.from_angle(a) * VIEW_RANGE)
		cone.append(end - position)


func kill() -> void:
	alive = false
	suspicion = 0.0
	queue_redraw()


func _draw() -> void:
	if not alive:
		# ceset
		draw_set_transform(Vector2.ZERO, facing, Vector2.ONE)
		draw_rect(Rect2(-16, -8, 32, 16), Color(0.3, 0.32, 0.28))
		draw_circle(Vector2(14, 0), 6, Color(0.25, 0.27, 0.23))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var col := Color(0.4, 0.8, 1.0, 0.18)
	if suspicion > 0.0:
		col = Color(1.0, 0.85, 0.2, 0.22 + suspicion * 0.2)
	if main.game_over and suspicion >= 1.0:
		col = Color(1.0, 0.2, 0.15, 0.4)
	if cone.size() >= 3:
		draw_colored_polygon(cone, col)
	# govde: Alman askeri (feldgrau)
	draw_circle(Vector2.ZERO, 12, Color(0.15, 0.16, 0.13))
	draw_circle(Vector2.ZERO, 10, Color(0.45, 0.48, 0.4))
	draw_circle(Vector2.from_angle(facing) * 4, 6, Color(0.3, 0.33, 0.28))   # kask
	draw_line(Vector2.ZERO, Vector2.from_angle(facing + 0.4) * 18, Color(0.2, 0.15, 0.1), 3.0)  # tufek
	if suspicion > 0.0:
		draw_arc(Vector2(0, -24), 8, -PI / 2, -PI / 2 + TAU * minf(suspicion, 1.0), 20, Color(1, 0.8, 0.2), 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(-4, -19), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
