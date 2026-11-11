extends CharacterBody2D
## Dusman askeri.
## Durumlar: devriye -> suphe -> arastirma -> arama (cok noktali) -> catisma -> geri donus.
## Rutbeler (Commandos'taki gibi): er, elit (SS), subay. Rutbe algiyi, cani ve atis hizini degistirir.
## Yapay zeka v2: kademeli tespit (mesafe/comelme/rutbe), cevresel algi, catismada atis + siper yerine
## gorus kazanmak icin hareket, yakindakilere seslenme, ses/patlama duyma, cok noktali arama.

const SpriteSheet = preload("res://scripts/sprite_sheet.gd")
const Fx = preload("res://scripts/fx.gd")
const SHEET_FMT := "res://assets/sprites/alman_%s_sprite_sheet.png"   # Blender ciktisi
const SHEET_FALLBACK := "res://assets/sprites/enemy_sprite_sheet.png"   # elle eklenen
const VIEW_RANGE := 230.0
const VIEW_HALF := 0.56          # ~32 derece
const RAYS := 30
const NEAR_FRAC := 0.55          # koninin yakin kismi: comelen burada gorulur (Desperados III)
const PERIPHERAL := 46.0         # arkasindan bile hissettigi mesafe (comelmeyen ve hareket eden)

# rutbe -> [can, gorus carpani, tespit hizi, atis araligi (sn), hasar, isabet]
const RANKS := {
	"er":    [60.0,  1.0,  1.0,  1.5,  7.0,  0.75],
	"kis":   [60.0,  1.0,  1.0,  1.5,  7.0,  0.75],
	"elit":  [90.0,  1.15, 1.25, 1.2,  9.0,  0.82],
	"subay": [80.0,  1.1,  1.35, 1.2,  9.0,  0.80],
}

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
var hidden_body := false          # ceset calilikta saklandi
var suspicion := 0.0
var investigate_pos := Vector2.ZERO
var timer := 0.0
var t := 0.0
var cone := PackedVector2Array()  # dunya koordinatlari
var _cone_t := 0.0
var _scan_t := 0.0
var _ready_nav := false
var sprite: AnimatedSprite2D
var kind := "er"                  # er / elit / subay / kis (bolum dosyasindan)
var hp := 60.0
var max_hp := 60.0
var target = null                 # catismadaki hedef
var _fire_t := 0.0
var _lost_t := 0.0
var _search_pts: Array = []
var reinforcement := false        # kisladan gelen takviye
var carried := false              # komando tasiyor


func _stat(i: int) -> float:
	return float(RANKS.get(kind, RANKS["er"])[i])


func _ready() -> void:
	add_to_group("guards")
	collision_layer = 2
	collision_mask = 1
	max_hp = _stat(0)
	hp = max_hp
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
	for path in [SHEET_FMT % kind, SHEET_FMT % "er", SHEET_FALLBACK]:
		if ResourceLoader.exists(path):
			sprite = SpriteSheet.attach(self, path)
			break
	base_facing = facing
	_fire_t = randf() * 0.8
	# navigasyon haritasi ilk fizik karesinden sonra hazir olur
	await get_tree().physics_frame
	await get_tree().physics_frame
	_ready_nav = true
	if state == &"patrol":
		_go_patrol()


func view_range() -> float:
	var k := 1.0
	if main.alert_level == 1:
		k = 1.15
	elif main.alert_level >= 2:
		k = 1.3
	return VIEW_RANGE * _stat(1) * k


func _physics_process(delta: float) -> void:
	if not alive:
		return
	t += delta
	if not main.game_over and _ready_nav:
		_think(delta)
		_watch(delta)
	if sprite != null:
		var anim := &"idle"
		if state == &"combat" and target != null and velocity.length() < 1.0:
			anim = &"idle"
		if velocity.length() > 1.0:
			anim = &"run" if state == &"combat" or (main.alert_level > 0 and state == &"investigate") else &"walk"
		if SpriteSheet.base_anim(sprite) != "shoot" or not sprite.is_playing():
			SpriteSheet.play(sprite, anim, facing)
	_cone_t -= delta
	if _cone_t <= 0.0:
		_cone_t = 0.06
		if _near_camera():
			_update_cone()
		elif cone.size() > 0:
			cone.clear()
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
			if _walk(delta, 1.25 if main.alert_level == 0 else 1.6):
				_start_search()
		&"search":
			# cok noktali arama: cevredeki 3 noktayi tek tek kontrol et
			if timer > 0.0:
				timer -= delta
				velocity = Vector2.ZERO
				facing += delta * 2.0
			elif _walk(delta, 1.0):
				if _search_pts.is_empty():
					_go_patrol()
				else:
					navigation_agent.target_position = _search_pts.pop_front()
					timer = 1.2
		&"combat":
			_combat(delta)


func _combat(delta: float) -> void:
	if target == null or not is_instance_valid(target) or not target.alive:
		target = null
		_start_search()
		return
	var tp: Vector2 = target.global_position
	var d := global_position.distance_to(tp)
	var sees: bool = d < view_range() * 1.25 and main.level.has_los(global_position, tp)
	if sees:
		_lost_t = 0.0
		investigate_pos = tp
		velocity = Vector2.ZERO
		facing = lerp_angle(facing, (tp - global_position).angle(), minf(1.0, delta * 10.0))
		_fire_t -= delta
		if _fire_t <= 0.0:
			_fire_t = _stat(3) * randf_range(0.85, 1.2)
			_shoot(target, d)
	else:
		# gorus kaybedildi: son gorulen yere kos, bulamazsa ara
		_lost_t += delta
		if navigation_agent.target_position.distance_to(investigate_pos) > 8.0:
			navigation_agent.target_position = investigate_pos
		if _walk(delta, 1.7) or _lost_t > 6.0:
			target = null
			_start_search()


func _shoot(tgt, dist: float) -> void:
	var acc := clampf(_stat(5) - dist / 700.0, 0.2, 0.9)
	if tgt.has_method("is_crouching") and tgt.is_crouching():
		acc *= 0.7
	if tgt.has_method("is_hidden") and tgt.is_hidden():
		acc *= 0.6
	var hit := randf() < acc
	if sprite != null:
		SpriteSheet.play(sprite, &"shoot", facing, true)
	var aim: Vector2 = tgt.global_position + Vector2(0, -16)
	if not hit:
		aim += Vector2(randf_range(-30, 30), randf_range(-30, 30))
	Fx.tracer(main.world, global_position + Vector2(0, -18), aim)
	main.make_noise(global_position, 600.0, self)
	if hit:
		tgt.take_damage(_stat(4) * randf_range(0.8, 1.2), global_position)


func _start_search() -> void:
	state = &"search"
	timer = 1.5
	_search_pts.clear()
	for i in 3:
		var p: Vector2 = investigate_pos + Vector2.from_angle(randf() * TAU) * randf_range(60, 150)
		_search_pts.append(NavigationServer2D.map_get_closest_point(navigation_agent.get_navigation_map(), p))
	navigation_agent.target_position = global_position


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
	if reinforcement and waypoints.is_empty():
		waypoints = [investigate_pos]
	if waypoints.size() > 0:
		navigation_agent.target_position = waypoints[wp_i]


func _set_investigate(p: Vector2) -> void:
	investigate_pos = p
	state = &"investigate"
	navigation_agent.target_position = p


func enter_combat(tgt) -> void:
	if not alive:
		return
	var was := state == &"combat"
	state = &"combat"
	target = tgt
	suspicion = 1.0
	investigate_pos = tgt.global_position
	if not was:
		_fire_t = 1.0      # tepki suresi: ilk atistan once oyuncuya kacma sansi
		main.raise_alarm(tgt.global_position, self)
		# yakindakilere seslen (duvar arkasi dahil, ama sadece yakindakiler)
		for g in get_tree().get_nodes_in_group("guards"):
			if g != self and g.alive and g.state != &"combat" and g.global_position.distance_to(global_position) < 320.0:
				g.alerted_by(tgt)


func alerted_by(tgt) -> void:
	## arkadasi seslendi: hedefi goruyorsa catisma, gormuyorsa oraya kos
	if main.level.has_los(global_position, tgt.global_position) and global_position.distance_to(tgt.global_position) < view_range() * 1.2:
		enter_combat(tgt)
	else:
		suspicion = 0.5
		_set_investigate(tgt.global_position)


func hear_noise(p: Vector2) -> void:
	## silah sesi / patlama: catismada degilse sesin geldigi yere git
	if not alive or state == &"combat" or carried:
		return
	_set_investigate(p)


func hear_alarm(p: Vector2) -> void:
	hear_noise(p)


func take_damage(amount: float, from: Vector2) -> void:
	if not alive:
		return
	hp -= amount
	Fx.blood(main.world, global_position + Vector2(0, -16))
	if hp <= 0.0:
		kill()
		return
	# vuruldu: saldirgana don
	var shooter = main.nearest_player(from)
	if shooter != null:
		enter_combat(shooter)


# ---------------- Algilama ----------------
func can_see(p: Vector2, crouched := false) -> bool:
	var d := p - global_position
	var r := view_range() * (NEAR_FRAC if crouched else 1.0)
	if d.length() > r:
		return false
	if absf(wrapf(d.angle() - facing, -PI, PI)) > VIEW_HALF:
		return false
	return main.level.has_los(global_position, p)


func _watch(delta: float) -> void:
	if state == &"combat":
		return
	var spotted = null
	var sd := 0.0
	for u in get_tree().get_nodes_in_group("player"):
		if not u.alive:
			continue
		var cr: bool = u.has_method("is_crouching") and u.is_crouching()
		var dd := global_position.distance_to(u.global_position)
		# cevresel algi: cok yakinda, ayakta ve hareket ediyorsa arkadan da hisseder
		var feel: bool = dd < PERIPHERAL and not cr and u.velocity.length() > 1.0
		if feel or can_see(u.global_position, cr):
			spotted = u
			sd = dd
			break
	if spotted != null:
		var near := clampf(1.0 - sd / view_range(), 0.15, 1.0)
		var rate := (0.7 + near * 2.6) * _stat(2)
		if main.alert_level == 1:
			rate *= 1.4
		elif main.alert_level >= 2:
			rate *= 2.0
		suspicion += delta * rate
		investigate_pos = spotted.global_position
		if state != &"suspicious":
			state = &"suspicious"
			velocity = Vector2.ZERO
		if suspicion >= 1.0:
			enter_combat(spotted)
			return
	else:
		suspicion = maxf(0.0, suspicion - delta * 0.35)

	_scan_t -= delta
	if _scan_t > 0.0:
		return
	_scan_t = 0.25
	var c = main.commando
	# kosan komandonun ayak sesi (duvar arkasindan da duyulur, ama yakindan)
	if c.alive and c.run and c.velocity.length() > 1.0 and (state == &"patrol" or state == &"search"):
		if global_position.distance_to(c.global_position) < 150.0:
			_set_investigate(c.global_position)
			return
	# ceset (calilikta saklanan ve tasinan gorulmez)
	for g in get_tree().get_nodes_in_group("guards"):
		if g != self and not g.alive and not g.discovered and not g.hidden_body and not g.carried and can_see(g.global_position):
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


func _near_camera() -> bool:
	var cam: Camera2D = main.cam
	if cam == null:
		return true
	var half: Vector2 = get_viewport_rect().size / cam.zoom * 0.5 + Vector2(320, 320)
	var d := (global_position - cam.position).abs()
	return d.x < half.x and d.y < half.y


func kill() -> void:
	alive = false
	hp = 0.0
	suspicion = 0.0
	target = null
	cone.clear()
	velocity = Vector2.ZERO
	if sprite != null:
		SpriteSheet.play(sprite, &"death", facing, true)
	# ceset hareketi engellemesin
	collision_layer = 0
	for ch in get_children():
		if ch is CollisionShape2D:
			ch.set_deferred("disabled", true)
	queue_redraw()


func cone_color() -> Color:
	if state == &"combat":
		return Color(1.0, 0.2, 0.15, 0.32)
	if state == &"investigate" or state == &"search":
		return Color(1.0, 0.6, 0.2, 0.22)
	if suspicion > 0.0:
		return Color(1.0, 0.85, 0.2, 0.2 + suspicion * 0.2)
	return Color(0.4, 0.8, 1.0, 0.16)


# ---------------- Cizim ----------------
func _draw() -> void:
	if not alive and sprite != null and SpriteSheet.base_anim(sprite) == "death":
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
	var body := Vector2(0, -12)
	if sprite != null:
		_draw_alert(Vector2(0, -44))
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.5))
	draw_circle(Vector2.ZERO, 12, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(body, 11, Color(0.12, 0.13, 0.1))
	draw_circle(body, 9.5, Color(0.45, 0.48, 0.4))                                     # feldgrau
	draw_circle(body + Vector2.from_angle(facing) * 3 + Vector2(0, -3), 6.5, Color(0.3, 0.33, 0.28))  # kask
	draw_line(body, body + Vector2.from_angle(facing + 0.4) * 17, Color(0.2, 0.15, 0.1), 3.0)          # tufek
	_draw_alert(body)


func _draw_alert(body: Vector2) -> void:
	var font := ThemeDB.fallback_font
	if hp < max_hp:
		var w := 30.0
		draw_rect(Rect2(-w / 2, body.y - 34, w, 4), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-w / 2, body.y - 34, w * hp / max_hp, 4), Color(0.9, 0.2, 0.15))
	if state == &"combat":
		draw_string(font, body + Vector2(-5, -19), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 0.25, 0.2))
	elif suspicion > 0.0:
		draw_arc(body + Vector2(0, -24), 8, -PI / 2, -PI / 2 + TAU * minf(suspicion, 1.0), 20, Color(1, 0.8, 0.2), 3.0)
		draw_string(font, body + Vector2(-4, -19), "!" if suspicion > 0.6 else "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	elif state == &"investigate" or state == &"search":
		draw_string(font, body + Vector2(-4, -19), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.6, 0.2))
	if kind == "subay" or kind == "elit":
		draw_string(font, body + Vector2(-14, 26), "Subay" if kind == "subay" else "SS", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 0.9, 0.6, 0.8))
