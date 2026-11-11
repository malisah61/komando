extends Area2D
## Bina ici alani: komando icerideyken cati seffaflasir (Commandos 2'deki gibi iceriyi gorursun).

var roof_node: Node2D
var wall_nodes: Array = []     # iceride duvarlar da yari saydam olur
var _inside := 0
var _tween: Tween


func _ready() -> void:
	# binalar artik ayri ic haritada (kapidan girilir): dis binada cati seffaflasmaz
	monitoring = false
	collision_layer = 0
	collision_mask = 2          # karakterler
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_inside += 1
		_fade(0.15)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_inside = maxi(0, _inside - 1)
		if _inside == 0:
			_fade(1.0)


func _fade(alpha: float) -> void:
	if roof_node == null:
		return
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(roof_node, "modulate:a", alpha, 0.3)
	var wall_alpha := 1.0 if alpha >= 1.0 else 0.45
	for w in wall_nodes:
		_tween.tween_property(w, "modulate:a", wall_alpha, 0.3)
