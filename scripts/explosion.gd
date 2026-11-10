extends Node2D
## Patlama efekti: parlama + genisleyen ates halkasi + duman bulutlari.

var t := 0.0
var puffs: Array = []


func _ready() -> void:
	z_index = 12
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 14:
		puffs.append([Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(10, 70), rng.randf_range(18, 40), rng.randf_range(0.0, 0.5)])


func _process(delta: float) -> void:
	t += delta
	if t > 3.5:
		queue_free()
	queue_redraw()


func _draw() -> void:
	if t < 0.25:
		draw_circle(Vector2.ZERO, 40 + t * 600, Color(1, 0.95, 0.7, 0.9 - t * 3.0))
	if t < 0.9:
		var k := t / 0.9
		draw_circle(Vector2.ZERO, 30 + k * 110, Color(1.0, 0.55 - k * 0.3, 0.1, 0.85 * (1.0 - k)))
	for p in puffs:
		var lt: float = t - p[2]
		if lt < 0.0:
			continue
		var a := clampf(1.0 - lt / 3.0, 0.0, 1.0)
		var c := Color(0.25, 0.23, 0.22, 0.65 * a)
		draw_circle(p[0] * (1.0 + lt * 0.8) + Vector2(0, -lt * 30), p[1] * (1.0 + lt * 0.6), c)
