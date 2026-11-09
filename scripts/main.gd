extends Node2D
## Oyun akisi, kamera, girdi ve arayuz. Dunya verisi levels/*.json dosyasindan gelir.

const Level = preload("res://scripts/level.gd")
const ConeLayer = preload("res://scripts/cone_layer.gd")
const Commando = preload("res://scripts/commando.gd")
const Guard = preload("res://scripts/guard.gd")
const Hud = preload("res://scripts/hud.gd")

@export var level_path := "res://levels/bolum0.json"

var level
var world: Node2D
var commando
var game_over := false
var alert_level := 0

# kamera / girdi
var cam: Camera2D
var pressed := false
var dragging := false
var press_pos := Vector2.ZERO
var touches := {}
var last_pinch := 0.0

var hud


func _ready() -> void:
	level = Level.new()
	add_child(level)
	var cones = ConeLayer.new()
	add_child(cones)
	world = Node2D.new()
	world.y_sort_enabled = true      # asagidaki (Y'si buyuk) onde gorunur
	add_child(world)
	var roofs := Node2D.new()
	roofs.z_index = 10
	add_child(roofs)

	if not level.load_level(level_path, world, roofs):
		return

	for gd in level.data.get("guards", []):
		var g = Guard.new()
		g.main = self
		for p in gd["path"]:
			g.waypoints.append(Vector2(p[0], p[1]))
		g.position = g.waypoints[0]
		g.facing = deg_to_rad(gd.get("facing", 0.0))
		world.add_child(g)

	commando = Commando.new()
	commando.main = self
	commando.position = level.start
	world.add_child(commando)

	cam = Camera2D.new()
	cam.position = commando.position
	add_child(cam)
	cam.make_current()
	hud = Hud.new()
	hud.main = self
	add_child(hud)


# ---------------- Oyun akisi ----------------
func _process(_delta: float) -> void:
	if game_over or commando == null:
		return
	if not level.document_taken and commando.global_position.distance_to(level.document_pos) < 26:
		level.document_taken = true
		level.queue_redraw()
		hud.on_document()
	if level.document_taken and level.exit_rect.has_point(commando.global_position):
		_end("GÖREV TAMAMLANDI", Color(0.5, 1, 0.5))


func caught(_by) -> void:
	if game_over:
		return
	commando.alive = false
	_end("ALARM! Yakalandın", Color(1, 0.35, 0.3))


func body_found(p: Vector2) -> void:
	alert_level = 1
	hud.set_alert("ALARM: Ceset bulundu! Askerler daha dikkatli.")
	get_tree().call_group("guards", "hear_alarm", p)


func _end(text: String, col: Color) -> void:
	game_over = true
	hud.show_end(text, col)


# ---------------- Girdi ----------------
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed:
			touches[e.index] = e.position
		else:
			touches.erase(e.index)
		last_pinch = 0.0
	elif e is InputEventScreenDrag:
		touches[e.index] = e.position
		if touches.size() == 2:
			dragging = true
			var k := touches.keys()
			var d: float = touches[k[0]].distance_to(touches[k[1]])
			if last_pinch > 0.0:
				_zoom(d / last_pinch)
			last_pinch = d
	elif e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				pressed = true
				dragging = false
				press_pos = e.position
			else:
				if pressed and not dragging and touches.size() <= 1:
					_tap(get_global_mouse_position())
				pressed = false
		elif e.pressed and e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(1.1)
		elif e.pressed and e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(1.0 / 1.1)
	elif e is InputEventMouseMotion and pressed:
		if e.position.distance_to(press_pos) > 14:
			dragging = true
		if dragging and touches.size() < 2:
			cam.position -= e.relative / cam.zoom
			_clamp_cam()


func _zoom(f: float) -> void:
	var z := clampf(cam.zoom.x * f, 0.5, 2.2)
	cam.zoom = Vector2(z, z)
	_clamp_cam()


func _clamp_cam() -> void:
	cam.position = cam.position.clamp(Vector2.ZERO, level.size)


func _tap(p: Vector2) -> void:
	if game_over:
		return
	# Bicak yetenegi secili ise askere dokununca saldir (Commandos'taki gibi)
	if hud.knife_mode:
		for g in get_tree().get_nodes_in_group("guards"):
			# govde ayaklarin ustunde cizildigi icin oraya da bak
			if g.alive and (p.distance_to(g.global_position) < 28 or p.distance_to(g.global_position + Vector2(0, -16)) < 24):
				commando.attack(g)
				hud.used_knife()
				return
	commando.move_to(p)
