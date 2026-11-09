extends CharacterBody2D
## Oyuncu komandosu (Yesil Bere). NavigationAgent2D ile tikla-yuru, bicakla.

const SpriteSheet = preload("res://scripts/sprite_sheet.gd")
# once elle eklenen sheet, yoksa Blender'da render edilen
const SHEETS := ["res://assets/sprites/commandos_sprite_sheet.png", "res://assets/sprites/komando_sprite_sheet.png"]

@export var speed: float = 120.0

var main
var navigation_agent: NavigationAgent2D
var facing := 0.0
var alive := true
var target_guard = null
var _repath := 0.0
var _step := 0.0
var sprite: AnimatedSprite2D      # sprite sheet varsa dolu, yoksa sekillerle cizilir
var run := false                  # HUD'daki Kos dugmesi


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 9.0
	shape.shape = c
	add_child(shape)
	navigation_agent = NavigationAgent2D.new()
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0
	navigation_agent.radius = 10.0
	add_child(navigation_agent)
	for path in SHEETS:
		if ResourceLoader.exists(path):
			sprite = SpriteSheet.attach(self, path)
			break


func nav_ready() -> bool:
	return NavigationServer2D.map_get_iteration_id(navigation_agent.get_navigation_map()) > 0


func move_to(p: Vector2) -> void:
	target_guard = null
	navigation_agent.target_position = p


func attack(g) -> void:
	target_guard = g
	navigation_agent.target_position = g.global_position


func _physics_process(delta: float) -> void:
	if not alive or main.game_over or not nav_ready():
		velocity = Vector2.ZERO
		queue_redraw()
		return
	if target_guard != null:
		if not target_guard.alive:
			target_guard = null
			navigation_agent.target_position = global_position
		elif global_position.distance_to(target_guard.global_position) < 30.0:
			target_guard.kill()
			target_guard = null
			_play(&"action", true)
			navigation_agent.target_position = global_position
		else:
			_repath -= delta
			if _repath <= 0.0:
				_repath = 0.25
				navigation_agent.target_position = target_guard.global_position

	if navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		_play(&"idle")
		queue_redraw()
		return

	var current_agent_position: Vector2 = global_position
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var direction: Vector2 = current_agent_position.direction_to(next_path_position)
	velocity = direction * speed * (1.6 if run else 1.0)
	_play(&"walk")
	facing = lerp_angle(facing, direction.angle(), minf(1.0, delta * 12.0))
	var before := global_position
	move_and_slide()

	# Ilke 3: camurda ayak izi
	_step += before.distance_to(global_position)
	if _step > 22.0:
		_step = 0.0
		if main.level.leaves_footprints(global_position):
			main.level.add_footprint(global_position, facing)
	queue_redraw()


func _play(anim: StringName, force := false) -> void:
	if sprite == null:
		return
	# tek seferlik animasyon (bicak) bitene kadar bozma
	if not force and SpriteSheet.base_anim(sprite) == "action" and sprite.is_playing():
		return
	if anim == &"walk" and run:
		anim = &"run"
	SpriteSheet.play(sprite, anim, facing, force)


func is_hidden() -> bool:
	return main.level.is_inside_view_blocker(global_position)


func _draw() -> void:
	# hedef yolu
	if alive and nav_ready() and not navigation_agent.is_navigation_finished():
		var pts := navigation_agent.get_current_navigation_path()
		var idx := navigation_agent.get_current_navigation_path_index()
		for i in range(idx, pts.size()):
			draw_circle(pts[i] - global_position, 2.5, Color(1, 1, 1, 0.5))
		if pts.size() > 0:
			draw_arc(pts[pts.size() - 1] - global_position, 9, 0, TAU, 20, Color(1, 1, 1, 0.7), 2.0)
	# golge + secim halkasi
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.5))
	if sprite == null:
		draw_circle(Vector2.ZERO, 12, Color(0, 0, 0, 0.35))
	draw_arc(Vector2.ZERO, 18, 0, TAU, 28, Color(0.4, 1, 0.4, 0.9), 2.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if sprite != null:
		sprite.modulate = Color(1, 0.6, 0.6) if not alive else (Color(1, 1, 1, 0.6) if is_hidden() else Color.WHITE)
		if is_hidden():
			draw_string(ThemeDB.fallback_font, Vector2(-22, -48), "gizli", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 1, 0.7))
		return
	# govde (ayaklar orijinde, govde yukarida)
	var body := Vector2(0, -12)
	var col := Color(0.3, 0.42, 0.2) if alive else Color(0.55, 0.2, 0.2)
	draw_circle(body, 11, Color(0.08, 0.1, 0.06))
	draw_circle(body, 9.5, col)
	draw_circle(body + Vector2.from_angle(facing) * 3 + Vector2(0, -3), 6, Color(0.12, 0.38, 0.12))  # yesil bere
	draw_line(body, body + Vector2.from_angle(facing - 0.5) * 15, Color(0.85, 0.85, 0.9), 2.0)         # bicak
	if is_hidden():
		draw_string(ThemeDB.fallback_font, Vector2(-22, -30), "gizli", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 1, 0.7))
