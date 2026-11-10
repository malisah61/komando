extends Node2D
## Oyun akisi, kamera, girdi ve arayuz. Dunya verisi levels/*.json dosyasindan gelir.

const Level = preload("res://scripts/level.gd")
const ConeLayer = preload("res://scripts/cone_layer.gd")
const Commando = preload("res://scripts/commando.gd")
const Guard = preload("res://scripts/guard.gd")
const Hud = preload("res://scripts/hud.gd")
const Mission = preload("res://scripts/mission.gd")
const Npc = preload("res://scripts/npc.gd")

const LEVELS := [
	["res://levels/bolum0.json", "Bölüm 0 – Normandiya Köyü", "Eğitim: küçük köy, 6 asker"],
	["res://levels/bolum1.json", "Bölüm 1 – Nehir Operasyonu", "Geniş harita: nehir, köprüler, köy, karargâh, 23 asker"],
]
static var level_choice := ""      # sahne yeniden yuklenince de hatirlanir
static var briefed := ""           # brifingi gosterilen son bolum (yeniden baslatinca tekrar gosterme)

var level_path := "res://levels/bolum1.json"

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
var mission


func _ready() -> void:
	if level_choice != "":
		level_path = level_choice
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
		g.kind = gd.get("type", "er")
		world.add_child(g)

	commando = Commando.new()
	commando.main = self
	commando.position = level.start
	world.add_child(commando)

	mission = Mission.new()
	mission.main = self
	mission.setup(level.data)
	add_child(mission)
	for nd in level.data.get("npcs", []):
		var n = Npc.new()
		n.main = self
		n.id = nd["id"]
		n.outfit = nd.get("outfit", "pilot")
		n.display_name = nd.get("name", "")
		n.position = Vector2(nd["pos"][0], nd["pos"][1])
		n.facing = deg_to_rad(nd.get("facing", 90.0))
		world.add_child(n)
		mission.npcs[n.id] = n

	cam = Camera2D.new()
	cam.position = commando.position
	add_child(cam)
	cam.make_current()
	_clamp_cam()
	hud = Hud.new()
	hud.main = self
	add_child(hud)
	if level_choice == "":
		hud.show_menu(LEVELS)
	elif briefed != level_path:
		briefed = level_path
		hud.show_briefing(level.data, mission.objectives)


func choose_level(path: String) -> void:
	level_choice = path
	briefed = ""
	get_tree().paused = false
	get_tree().reload_current_scene()


# ---------------- Oyun akisi ----------------
func win() -> void:
	var t: float = mission.elapsed
	_end("GÖREV TAMAMLANDI\nSüre %d:%02d" % [int(t) / 60, int(t) % 60], Color(0.5, 1, 0.5))


func lose(text: String) -> void:
	if game_over:
		return
	commando.alive = false
	_end(text, Color(1, 0.35, 0.3))


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
	# gorus alani harita disina tasmasin (harita ekrandan kucukse ortala)
	var half: Vector2 = get_viewport_rect().size / cam.zoom * 0.5
	var lo: Vector2 = half
	var hi: Vector2 = level.size - half
	if hi.x < lo.x:
		lo.x = level.size.x * 0.5
		hi.x = lo.x
	if hi.y < lo.y:
		lo.y = level.size.y * 0.5
		hi.y = lo.y
	cam.position = cam.position.clamp(lo, hi)


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
