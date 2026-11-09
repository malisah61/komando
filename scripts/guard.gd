extends CharacterBody2D
## Dusman askeri. Durumlar: devriye -> suphe -> arastirma -> arama -> geri donus.
## Kademeli tespit metresi, ?/! geri bildirimi, ceset ve ayak izi fark etme.

const SpriteSheet = preload("res://scripts/sprite_sheet.gd")
const SHEET := "res://assets/sprites/enemy_sprite_sheet.png"
const VIEW_RANGE := 230.0
const VIEW_HALF := 0.56          # ~32 derece
const RAYS := 30

var main
var navigation_agent: NavigationAgent2D
var waypoints: Array = []
var wp_i := 0
var speed := 55.0
var facing := 0.0
var base_facing := 0.0
var state := &"patrol"
var alive := true
var discovered := false           # cesedi bulundu mu
var suspicion := 0.0
var investigate_pos := Vector2.ZERO
var timer := 0.0
var t := 0.0
var cone := PackedVector2Array()  # dunya koordinatlari
var _cone_t := 0.0
var _scan_t := 0.0
var _ready_nav := false
var sprite: AnimatedSprite2D


func _ready() -> void:
	add_to_group("guards")
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
	sprite = SpriteSheet.attach(self, SHEET)
	base_facing = facing
	# navigasyon haritasi ilk fizik karesinden sonra hazir olur
	await get_tree().physics_frame
	await get_tree().physics_frame
	_ready_nav = true
	_go_patrol()


func view_range() -> float:
	return VIEW_RANGE * (1.25 if main.alert_level > 0 else 1.0)


func _physics_process(delta: float) -> void:
	if not alive:
		return
	t += delta
	if not main.game_over and _ready_nav:
		_think(delta)
		_watch(delta)
	if sprite != null:
		var anim := &"walk" if velocity.length() > 1.0 else &"idle"
		if sprite.animation != anim and sprite.sprite_frames.has_animation(anim):
			sprite.play(anim)
		sprite.flip_h = cos(facing) < 0.0
	_cone_t -= delta
	if _cone_t <= 0.0:
		_cone_t = 0.06
		_update_cone()
	queue_redraw()


# ---------------- Davranis ----------------
func _think(delta: float) -> void:
	match state:
		&"patrol":
			if waypoints.size() <= 1:
				if _walk(delta, 0.6):
					facing = lerp_angle(facing, base_facing + sin(t * 0.7) * 0.9, minf(1.0, delta * 4.0))
			elif timer > 0.0:
				timer -= delta
				facing += sin(t * 2.0) * delta * 0.8
			elif _walk(delta, 1.0):
				wp_i = (wp_i + 1) % waypoints.size()
				timer = 1.4
				navigation_agent.target_position = waypoints[wp_i]
		&"suspicious":
			velocity = Vector2.ZERO
			facing = lerp_angle(facing, (investigate_pos - global_position).angle(), minf(1.0, delta * 5.0))
			if suspicion <= 0.15:
				_set_investigate(investigate_pos)
		&"investigate":
			if _walk(delta, 1.25):
				state = &"search"
				timer = 3.5
		&"search":
			velocity = Vector2.ZERO
			facing += delta * 1.6
			timer -= delta
			if timer <= 0.0:
				_go_patrol()


func _walk(delta: float, speed_mul: float) -> bool:
	## hedefe yuru; vardiysa true dondur
	if navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return true
	var next: Vector2 = navigation_agent.get_next_path_position()
	var dir := global_position.direction_to(next)
	var mul := speed_mul * (1.3 if main.alert_level > 0 else 1.0)
	velocity = dir * speed * mul
	facing = lerp_angle(facing, dir.angle(), minf(1.0, delta * 5.0))
	move_and_slide()
	return false


func _go_patrol() -> void:
	state = &"patrol"
	if waypoints.size() > 0:
		navigation_agent.target_position = waypoints[wp_i]


func _set_investigate(p: Vector2) -> void:
	investigate_pos = p
	state = &"investigate"
	navigation_agent.target_position = p


func hear_alarm(p: Vector2) -> void:
	## main tarafindan call_group ile cagrilir
	if alive and state != &"suspicious":
		_set_investigate(p)


# ---------------- Algilama ----------------
func can_see(p: Vector2) -> bool:
	var d := p - global_position
	if d.length() > view_range():
		return false
	if absf(wrapf(d.angle() - facing, -PI, PI)) > VIEW_HALF:
		return false
	return main.level.has_los(global_position, p)


func _watch(delta: float) -> void:
	var c = main.commando
	if c.alive and can_see(c.global_position):
		var close := global_position.distance_to(c.global_position) < 110.0
		suspicion += delta * (2.6 if close else 1.0) * (1.5 if main.alert_level > 0 else 1.0)
		investigate_pos = c.global_position
		if state != &"suspicious":
			state = &"suspicious"
			velocity = Vector2.ZERO
	else:
		suspicion = maxf(0.0, suspicion - delta * 0.35)
	if suspicion >= 1.0:
		main.caught(self)
		return

	_scan_t -= delta
	if _scan_t > 0.0:
		return
	_scan_t = 0.25
	# kosan komandonun ayak sesi (duvar arkasindan da duyulur, ama yakindan)
	if c.alive and c.run and c.velocity.length() > 1.0 and (state == &"patrol" or state == &"search"):
		if global_position.distance_to(c.global_position) < 150.0:
			_set_investigate(c.global_position)
			return
	# ceset
	for g in get_tree().get_nodes_in_group("guards"):
		if g != self and not g.alive and not g.discovered and can_see(g.global_position):
			g.discovered = true
			_set_investigate(g.global_position)
			main.body_found(g.global_position)
			return
	# ayak izi
	if state == &"patrol" or state == &"search":
		for fp in main.level.footprints:
			if not fp["noticed"] and can_see(fp["pos"]):
				fp["noticed"] = true
				_set_investigate(fp["pos"])
				return


func _update_cone() -> void:
	cone.clear()
	if not alive:
		return
	cone.append(global_position)
	var r := view_range()
	for i in RAYS + 1:
		var a := facing - VIEW_HALF + (VIEW_HALF * 2.0) * float(i) / RAYS
		cone.append(main.level.ray_end(global_position, global_position + Vector2.from_angle(a) * r))


func kill() -> void:
	alive = false
	suspicion = 0.0
	cone.clear()
	velocity = Vector2.ZERO
	if sprite != null and sprite.sprite_frames.has_animation(&"death"):
		sprite.play(&"death")
	# ceset hareketi engellemesin
	collision_layer = 0
	for ch in get_children():
		if ch is CollisionShape2D:
			ch.set_deferred("disabled", true)
	queue_redraw()


func cone_color() -> Color:
	if main.game_over and suspicion >= 1.0:
		return Color(1.0, 0.2, 0.15, 0.4)
	if state == &"investigate" or state == &"search":
		return Color(1.0, 0.6, 0.2, 0.22)
	if suspicion > 0.0:
		return Color(1.0, 0.85, 0.2, 0.2 + suspicion * 0.2)
	return Color(0.4, 0.8, 1.0, 0.16)


# ---------------- Cizim ----------------
func _draw() -> void:
	if not alive and sprite != null and sprite.sprite_frames.has_animation(&"death"):
		return
	if not alive:
		if sprite != null:
			sprite.visible = false
		draw_set_transform(Vector2.ZERO, facing, Vector2.ONE)
		draw_rect(Rect2(-14, -7, 28, 14), Color(0.32, 0.34, 0.3))
		draw_circle(Vector2(13, 0), 6, Color(0.25, 0.27, 0.23))
		draw_rect(Rect2(-18, -9, 4, 18), Color(0.4, 0.1, 0.1, 0.7))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.5))
	draw_circle(Vector2.ZERO, 12, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var body := Vector2(0, -12)
	if sprite != null:
		_draw_alert(Vector2(0, -36))
		return
	draw_circle(body, 11, Color(0.12, 0.13, 0.1))
	draw_circle(body, 9.5, Color(0.45, 0.48, 0.4))                                     # feldgrau
	draw_circle(body + Vector2.from_angle(facing) * 3 + Vector2(0, -3), 6.5, Color(0.3, 0.33, 0.28))  # kask
	draw_line(body, body + Vector2.from_angle(facing + 0.4) * 17, Color(0.2, 0.15, 0.1), 3.0)          # tufek
	_draw_alert(body)


func _draw_alert(body: Vector2) -> void:
	var font := ThemeDB.fallback_font
	if suspicion > 0.0:
		draw_arc(body + Vector2(0, -24), 8, -PI / 2, -PI / 2 + TAU * minf(suspicion, 1.0), 20, Color(1, 0.8, 0.2), 3.0)
		draw_string(font, body + Vector2(-4, -19), "!" if suspicion > 0.6 else "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	elif state == &"investigate" or state == &"search":
		draw_string(font, body + Vector2(-4, -19), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.6, 0.2))
