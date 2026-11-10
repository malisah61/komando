extends CharacterBody2D
## Dost karakter: direnisci (yerinde bekler) ya da kurtarilan esir (komandoyu izler).

const SpriteSheet = preload("res://scripts/sprite_sheet.gd")

var main
var id := ""
var outfit := "pilot"
var display_name := ""
var facing := PI / 2
var following := false
var alive := true
var navigation_agent: NavigationAgent2D
var sprite: AnimatedSprite2D
var _repath := 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 8.0
	shape.shape = c
	add_child(shape)
	navigation_agent = NavigationAgent2D.new()
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 30.0
	navigation_agent.radius = 10.0
	add_child(navigation_agent)
	var path := "res://assets/sprites/%s_sprite_sheet.png" % outfit
	if ResourceLoader.exists(path):
		sprite = SpriteSheet.attach(self, path)


func start_following() -> void:
	following = true
	add_to_group("player")        # askerler artik onu da gorebilir


func is_hidden() -> bool:
	return main.level.is_inside_view_blocker(global_position)


func _physics_process(delta: float) -> void:
	if not alive or main.game_over or not following:
		velocity = Vector2.ZERO
		SpriteSheet.play(sprite, &"idle", facing)
		queue_redraw()
		return
	var c = main.commando
	var dist := global_position.distance_to(c.global_position)
	_repath -= delta
	if _repath <= 0.0:
		_repath = 0.3
		navigation_agent.target_position = c.global_position
	if dist < 42.0 or navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		SpriteSheet.play(sprite, &"idle", facing)
	else:
		var next := navigation_agent.get_next_path_position()
		var dir := global_position.direction_to(next)
		var spd: float = c.speed * (1.6 if c.run else 1.0) * (1.15 if dist > 120.0 else 1.0)
		velocity = dir * spd
		facing = lerp_angle(facing, dir.angle(), minf(1.0, delta * 10.0))
		move_and_slide()
		SpriteSheet.play(sprite, &"run" if c.run else &"walk", facing)
	queue_redraw()


func _draw() -> void:
	if sprite == null:
		draw_circle(Vector2(0, -12), 9.5, Color(0.4, 0.3, 0.2))
	if display_name != "":
		var col := Color(0.7, 0.9, 1.0) if following else Color(1, 1, 0.7)
		draw_string(ThemeDB.fallback_font, Vector2(-40, -58), display_name, HORIZONTAL_ALIGNMENT_CENTER, 80, 13, col)
	if following:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.5))
		draw_arc(Vector2.ZERO, 15, 0, TAU, 24, Color(0.5, 0.8, 1.0, 0.8), 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
