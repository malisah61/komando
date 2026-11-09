extends Node2D
## Tum gorus konilerini zeminin ustune, engellerin altina cizer.

func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var main = get_parent()
	if main.hud != null and not main.hud.show_cones:
		return
	for g in get_tree().get_nodes_in_group("guards"):
		if g.alive and g.cone.size() >= 3:
			draw_colored_polygon(g.cone, g.cone_color())
