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
	["res://levels/bolum1.json", "Bölüm 1 – Nehir Operasyonu", "Geniş harita: nehir, köprüler, köy, karargâh, kışlalar"],
]
static var level_choice := ""      # sahne yeniden yuklenince de hatirlanir
static var briefed := ""           # brifingi gosterilen son bolum (yeniden baslatinca tekrar gosterme)

var level_path := "res://levels/bolum1.json"

var level
var world: Node2D
var commando
var game_over := false
var alert_level := 0          # 0 sakin, 1 dikkat (sari), 2 alarm (kirmizi)
var alarm_t := 0.0
var barracks: Array = []      # [konum, kalan asker, tur, gecikme]
var _pending: Array = []      # [sure, kisla, adet, hedef]
var stats := {"kills": 0, "alarms": 0, "shots": 0}
var cur_interior := -1        # komando hangi bina icinde (-1: dis harita)
var pending_enter := -1       # kapiya yuruyup girilecek bina
var peeking := false          # kapidan disari bakiyor

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

	for bk in level.data.get("barracks", []):
		barracks.append([Vector2(bk["pos"][0], bk["pos"][1]), int(bk.get("count", 6)), bk.get("type", "er"), float(bk.get("delay", 6.0))])
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


func nearest_player(p: Vector2):
	var best = null
	var bd := INF
	for u in get_tree().get_nodes_in_group("player"):
		if u.alive and u.global_position.distance_to(p) < bd:
			bd = u.global_position.distance_to(p)
			best = u
	return best


func make_noise(p: Vector2, radius: float, src) -> void:
	## silah sesi: sadece yaricap icindeki askerler duyar (hepsi birden kosmaz)
	for g in get_tree().get_nodes_in_group("guards"):
		if g != src and g.alive and g.global_position.distance_to(p) < radius:
			g.hear_noise(p)
	if alert_level == 0:
		set_alert_level(1)


func raise_alarm(p: Vector2, _by) -> void:
	## kirmizi alarm: kislalardan takviye birlik cikar, alarm noktasina kosar
	alarm_t = maxf(alarm_t, 35.0)
	if alert_level < 2:
		stats["alarms"] += 1
		set_alert_level(2)
		var sent := 0
		var order := barracks.duplicate()
		order.sort_custom(func(a, b): return a[0].distance_to(p) < b[0].distance_to(p))
		for bk in order:
			if sent >= 2 or bk[1] <= 0:
				continue
			var n: int = mini(3, bk[1])
			bk[1] -= n
			_pending.append([bk[3], bk, n, p])
			sent += 1


func set_alert_level(l: int) -> void:
	alert_level = l
	if l == 2:
		hud.set_alarm(2, "ALARM! Takviye birlikler kışladan çıkıyor")
	elif l == 1:
		hud.set_alarm(1, "DİKKAT: Askerler tetikte")
	else:
		hud.set_alarm(0, "")


func body_found(p: Vector2) -> void:
	if alert_level < 1:
		set_alert_level(1)
	hud.toast("Bir asker ceset buldu!")
	make_noise(p, 350.0, null)


func _process(delta: float) -> void:
	if game_over:
		return
	# alarm sayaci: catisma surdukce kirmizi kalir, sonra sariya duser
	if alert_level == 2:
		var fighting := false
		for g in get_tree().get_nodes_in_group("guards"):
			if g.alive and g.state == &"combat":
				fighting = true
				break
		alarm_t -= delta * (0.25 if fighting else 1.0)
		if alarm_t <= 0.0:
			set_alert_level(1)
		elif not fighting:
			hud.set_alarm(2, "ALARM: Askerler arıyor (%d sn)" % ceili(alarm_t))
	# takviye cikislari
	var i := _pending.size() - 1
	while i >= 0:
		_pending[i][0] -= delta
		if _pending[i][0] <= 0.0:
			var pd: Array = _pending[i]
			_spawn_reinforcements(pd[1], pd[2], pd[3])
			_pending.remove_at(i)
		i -= 1
	_update_action()


func _spawn_reinforcements(bk: Array, n: int, target: Vector2) -> void:
	for k in n:
		var g = Guard.new()
		g.main = self
		g.kind = bk[2]
		g.reinforcement = true
		g.position = bk[0] + Vector2((k - 1) * 22, (k % 2) * 16)
		g.state = &"investigate"
		g.investigate_pos = target + Vector2(randf_range(-60, 60), randf_range(-60, 60))
		world.add_child(g)
		g.navigation_agent.target_position = g.investigate_pos
	hud.toast("Takviye birlik geldi: %d asker" % n)


func enter_building(i: int) -> void:
	var it: Dictionary = level.interiors[i]
	_move_party(it["int_door"])
	cur_interior = i
	pending_enter = -1
	cam.position = commando.global_position
	_clamp_cam()
	hud.set_place("Bina içi: " + it["name"])
	hud.toast(it["name"] + " – içeri girdin")


func exit_building() -> void:
	if cur_interior < 0:
		return
	var it: Dictionary = level.interiors[cur_interior]
	cur_interior = -1
	peeking = false
	hud.show_peek(false)
	_move_party(it["ext_door"] + it["out"] * 6.0)
	cam.position = commando.global_position
	_clamp_cam()
	hud.set_place("")


func _move_party(p: Vector2) -> void:
	## komando + onu izleyen karakterler + tasinan ceset birlikte gecer
	var c = commando
	for id in mission.npcs:
		var n = mission.npcs[id]
		if n.following and n.alive and n.global_position.distance_to(c.global_position) < 180.0:
			n.global_position = p + Vector2(24, 10)
			n.navigation_agent.target_position = n.global_position
	c.global_position = p
	c.move_to(p)
	c._carry_follow()


func toggle_peek() -> void:
	## kapidan / anahtar deliginden disari bak (Commandos 2)
	if cur_interior < 0:
		return
	peeking = not peeking
	var it: Dictionary = level.interiors[cur_interior]
	if peeking:
		cam.position = it["ext_door"] + it["out"] * 150.0
	else:
		cam.position = commando.global_position
	_clamp_cam()
	hud.show_peek(peeking)


func _update_action() -> void:
	## baglama gore tek aksiyon dugmesi: patlayici kur / cesedi tasi / birak / gir / cik
	var c = commando
	if not c.alive:
		hud.set_action("", false)
		return
	# kapi gecisleri
	if pending_enter >= 0 and c.global_position.distance_to(level.interiors[pending_enter]["ext_door"]) < 24.0:
		enter_building(pending_enter)
		return
	if cur_interior >= 0:
		var it: Dictionary = level.interiors[cur_interior]
		if c.global_position.distance_to(it["int_door"]) < 60.0:
			hud.set_action("Dışarı Çık", true, func(): exit_building(), "Kapıdan Bak", func(): toggle_peek())
			return
	else:
		for i in level.interiors.size():
			if c.global_position.distance_to(level.interiors[i]["ext_door"]) < 46.0:
				var ii: int = i
				hud.set_action("Gir: " + level.interiors[i]["name"], true, func(): enter_building(ii))
				return
	if c.carrying != null:
		hud.set_action("Cesedi Bırak", true, func(): c.drop_body())
		return
	if mission.plant_target != null:
		var planting: bool = mission.planting >= 0.0
		hud.set_action(("Kuruluyor... %d%%" % int(mission.planting / mission.PLANT_TIME * 100.0)) if planting else "Patlayıcı Kur",
				not planting, func(): mission.start_planting())
		return
	var b = c.body_nearby()
	if b != null:
		hud.set_action("Cesedi Taşı", true, func(): c.pick_body(b))
		return
	hud.set_action("", false)


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
	var area := Rect2(Vector2.ZERO, level.size)
	if cur_interior >= 0 and not peeking:
		area = level.interiors[cur_interior]["irect"].grow(90)
	var half: Vector2 = get_viewport_rect().size / cam.zoom * 0.5
	var lo: Vector2 = area.position + half
	var hi: Vector2 = area.end - half
	if hi.x < lo.x:
		lo.x = area.get_center().x
		hi.x = lo.x
	if hi.y < lo.y:
		lo.y = area.get_center().y
		hi.y = lo.y
	cam.position = cam.position.clamp(lo, hi)


func _tap(p: Vector2) -> void:
	if game_over or peeking:
		return
	# dis haritada bir binaya dokunuldu: kapiya yuru ve gir
	if cur_interior < 0:
		var bi: int = level.interior_of_ext(p)
		if bi >= 0:
			pending_enter = bi
			commando.move_to(level.interiors[bi]["ext_door"])
			return
	pending_enter = -1
	# secili silahla askere saldir (secim kalici; yere dokunmak sadece yurutur)
	for g in get_tree().get_nodes_in_group("guards"):
		# govde ayaklarin ustunde cizildigi icin oraya da bak
		if g.alive and (p.distance_to(g.global_position) < 28 or p.distance_to(g.global_position + Vector2(0, -20)) < 26):
			commando.attack(g)
			return
	commando.move_to(p)
