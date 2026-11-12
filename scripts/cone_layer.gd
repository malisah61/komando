extends Node2D
## Tum gorus konilerini zeminin ustune, engellerin altina cizer.

func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var main = get_parent()
	var cones_on: bool = main.hud == null or main.hud.show_cones
	# projektor isiklari (Tur 3): direkten isik demeti + yerde aydinlik daire
	for sl in main.level.searchlights:
		if not sl["on"]:
			continue
		var p: Vector2 = sl["pos"]
		var r: float = sl["r"]
		var hot := clampf(float(sl["heat"]) * 2.0, 0.0, 1.0)
		var dir: Vector2 = (p - sl["pole"]).normalized().orthogonal() * r * 0.8
		draw_colored_polygon(PackedVector2Array([sl["pole"], p + dir, p - dir]), Color(1, 0.97, 0.75, 0.07))
		draw_circle(p, r, Color(1, 0.96, 0.7, 0.22 + hot * 0.2))
		draw_circle(p, r * 0.6, Color(1, 1, 0.85, 0.16))
		draw_arc(p, r, 0, TAU, 32, Color(1, 0.9, 0.5, 0.5 + hot * 0.4), 2.0)
	for g in get_tree().get_nodes_in_group("guards"):
		if cones_on and g.alive and g.cone.size() >= 3:
			draw_colored_polygon(g.cone, g.cone_color())
