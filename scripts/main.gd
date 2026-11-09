extends Node2D
## Bolum 0 - "Normandiya Koyu" prototipi.
## Harita, yol bulma, gorus hatti, kamera, girdi ve arayuz burada yonetilir.

const Commando = preload("res://scripts/commando.gd")
const Guard = preload("res://scripts/guard.gd")

const CELL := 32
const MAP_W := 50   # hucre
const MAP_H := 34
const MAP_SIZE := Vector2(MAP_W * CELL, MAP_H * CELL)

# --- Harita verisi (Bolum Tasarimcisi) ---
var buildings: Array[Rect2] = [
	Rect2(300, 120, 260, 180),   # ev A
	Rect2(760, 80, 200, 240),    # kilise
	Rect2(1100, 100, 180, 160),  # karargah
	Rect2(380, 520, 220, 160),   # ahir
	Rect2(820, 560, 160, 200),   # ev B
	Rect2(1180, 480, 240, 140),  # ev C
]
var hedges: Array[Rect2] = [
	Rect2(0, 760, 420, 28),
	Rect2(1300, 300, 28, 120),
]
var sandbags: Array[Rect2] = [
	Rect2(860, 880, 160, 26),
	Rect2(560, 860, 26, 140),
]
var walls: Array[Rect2] = []   # hepsi + harita kenarlari (carpisma ve gorus icin)

var document_pos := Vector2(1450, 180)
var exit_rect := Rect2(30, 900, 170, 150)
var has_document := false
var game_over := false

var astar := AStarGrid2D.new()
var commando
var guards: Array = []

# --- Kamera / girdi ---
var cam: Camera2D
var pressed := false
var dragging := false
var press_pos := Vector2.ZERO
var touches := {}
var last_pinch := 0.0

# --- Arayuz ---
var goal_label: Label
var msg_label: Label
var restart_btn: Button


func _ready() -> void:
	walls.append_array(buildings)
	walls.append_array(hedges)
	walls.append_array(sandbags)
	# harita kenarlari
	walls.append(Rect2(-40, -40, MAP_SIZE.x + 80, 40))
	walls.append(Rect2(-40, MAP_SIZE.y, MAP_SIZE.x + 80, 40))
	walls.append(Rect2(-40, 0, 40, MAP_SIZE.y))
	walls.append(Rect2(MAP_SIZE.x, 0, 40, MAP_SIZE.y))
	_build_astar()

	_add_guard([Vector2(480, 410), Vector2(1040, 410)], 0.0)
	_add_guard([Vector2(690, 470), Vector2(690, 820)], PI / 2)
	_add_guard([Vector2(1450, 340)], PI)                       # karargah nobetcisi
	_add_guard([Vector2(1100, 700), Vector2(1520, 700), Vector2(1520, 960), Vector2(1100, 960)], 0.0)
	_add_guard([Vector2(240, 450)], 0.0)                        # yol nobetcisi

	commando = Commando.new()
	commando.main = self
	commando.position = Vector2(110, 990)
	add_child(commando)

	cam = Camera2D.new()
	cam.position = commando.position
	add_child(cam)
	cam.make_current()
	_build_ui()


func _add_guard(points: Array, facing: float) -> void:
	var g = Guard.new()
	g.main = self
	g.waypoints = points
	g.position = points[0]
	g.facing = facing
	g.base_facing = facing
	add_child(g)
	guards.append(g)


# ---------------- Yol bulma ----------------
func _build_astar() -> void:
	astar.region = Rect2i(0, 0, MAP_W, MAP_H)
	astar.cell_size = Vector2(CELL, CELL)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	for x in MAP_W:
		for y in MAP_H:
			var r := Rect2(x * CELL, y * CELL, CELL, CELL)
			for w in walls:
				if w.grow(8).intersects(r):
					astar.set_point_solid(Vector2i(x, y), true)
					break


func _cell(p: Vector2) -> Vector2i:
	return Vector2i(clampi(int(p.x / CELL), 0, MAP_W - 1), clampi(int(p.y / CELL), 0, MAP_H - 1))


func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var a := _cell(from)
	var b := _cell(to)
	if astar.is_point_solid(b) or astar.is_point_solid(a):
		return PackedVector2Array()
	var pts := astar.get_point_path(a, b)
	var out := PackedVector2Array()
	for i in pts.size():
		out.append(pts[i] + Vector2(CELL, CELL) * 0.5)
	if out.size() > 0:
		out[out.size() - 1] = to
	return out


# ---------------- Gorus hatti ----------------
func ray_end(from: Vector2, to: Vector2) -> Vector2:
	var best := to
	var best_d := from.distance_to(to)
	for w in walls:
		var c := [w.position, Vector2(w.end.x, w.position.y), w.end, Vector2(w.position.x, w.end.y)]
		for i in 4:
			var hit = Geometry2D.segment_intersects_segment(from, to, c[i], c[(i + 1) % 4])
			if hit != null:
				var d: float = from.distance_to(hit)
				if d < best_d:
					best_d = d
					best = hit
	return best


func has_los(a: Vector2, b: Vector2) -> bool:
	return ray_end(a, b).distance_to(b) < 1.0


# ---------------- Oyun akisi ----------------
func _process(_delta: float) -> void:
	if game_over:
		return
	if not has_document and commando.position.distance_to(document_pos) < 30:
		has_document = true
		goal_label.text = "Hedef: Belgeyi ÇIKIŞ bölgesine götür (sol alt)"
		queue_redraw()
	if has_document and exit_rect.has_point(commando.position):
		_end("GÖREV TAMAMLANDI", Color(0.5, 1, 0.5))


func alarm() -> void:
	if game_over:
		return
	commando.alive = false
	_end("ALARM! Yakalandın", Color(1, 0.35, 0.3))


func _end(text: String, col: Color) -> void:
	game_over = true
	msg_label.text = text
	msg_label.add_theme_color_override("font_color", col)
	msg_label.visible = true
	restart_btn.visible = true


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
	cam.position = cam.position.clamp(Vector2.ZERO, MAP_SIZE)


func _tap(p: Vector2) -> void:
	if game_over:
		return
	for g in guards:
		if g.alive and p.distance_to(g.position) < 30:
			commando.attack(g)
			return
	commando.move_to(p)


# ---------------- Arayuz ----------------
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	goal_label = _make_label(22)
	goal_label.position = Vector2(16, 12)
	goal_label.text = "Hedef: Karargahtaki gizli BELGEYİ çal (sağ üst)"
	layer.add_child(goal_label)

	var hint := _make_label(16)
	hint.text = "Dokun: yürü  •  Askere dokun: arkasından bıçakla  •  Sürükle: kamera  •  İki parmak / tekerlek: yakınlaştır"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.position = Vector2(16, -36)
	layer.add_child(hint)

	msg_label = _make_label(56)
	msg_label.set_anchors_preset(Control.PRESET_CENTER)
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	msg_label.position.y -= 80
	msg_label.visible = false
	layer.add_child(msg_label)

	restart_btn = Button.new()
	restart_btn.text = "  Yeniden Başla  "
	restart_btn.add_theme_font_size_override("font_size", 30)
	restart_btn.set_anchors_preset(Control.PRESET_CENTER)
	restart_btn.grow_horizontal = Control.GROW_DIRECTION_BOTH
	restart_btn.position.y += 10
	restart_btn.visible = false
	restart_btn.pressed.connect(func(): get_tree().reload_current_scene())
	layer.add_child(restart_btn)


func _make_label(size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	return l


# ---------------- Cizim (gecici grafikler) ----------------
func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color(0.36, 0.45, 0.26))
	# yollar
	var road := Color(0.55, 0.47, 0.34)
	draw_rect(Rect2(0, 360, MAP_SIZE.x, 100), road)
	draw_rect(Rect2(640, 0, 100, MAP_SIZE.y), road)
	draw_rect(Rect2(1060, 650, 500, 30), road)
	# cikis
	draw_rect(exit_rect, Color(0.3, 0.9, 0.4, 0.25))
	draw_rect(exit_rect, Color(0.3, 0.9, 0.4, 0.8), false, 3.0)
	draw_string(font, exit_rect.position + Vector2(36, 30), "ÇIKIŞ", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	# binalar (catilar)
	for b in buildings:
		draw_rect(b.grow(4), Color(0.2, 0.12, 0.1))
		draw_rect(b, Color(0.58, 0.3, 0.24))
		var mid := b.position.y + b.size.y / 2
		draw_line(Vector2(b.position.x, mid), Vector2(b.end.x, mid), Color(0.38, 0.18, 0.14), 4.0)
	for h in hedges:
		draw_rect(h, Color(0.18, 0.32, 0.14))
	for s in sandbags:
		draw_rect(s, Color(0.72, 0.64, 0.45))
		draw_rect(s, Color(0.45, 0.38, 0.25), false, 2.0)
	# belge
	if not has_document:
		draw_rect(Rect2(document_pos - Vector2(12, 9), Vector2(24, 18)), Color(1, 0.9, 0.3))
		draw_string(font, document_pos + Vector2(-26, -16), "BELGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
