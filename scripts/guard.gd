extends CharacterBody2D
## Dusman askeri.
## Durumlar: devriye -> suphe -> arastirma -> arama (cok noktali) -> catisma -> geri donus.
## Rutbeler (Commandos'taki gibi): er, elit (SS), subay. Rutbe algiyi, cani ve atis hizini degistirir.
## Yapay zeka v2: kademeli tespit (mesafe/comelme/rutbe), cevresel algi, catismada atis + siper yerine
## gorus kazanmak icin hareket, yakindakilere seslenme, ses/patlama duyma, cok noktali arama.
## Yapay zeka v4 (Tur 3): tetikte kalma (supheden sonra daha genis/hizli bakar), ayak izi takibi (iz surer),
## bogusma sesi + cinayete tanik olma, SS/subay el bombasi (siperdeki hedefe), kule gozcusunun isaret
## vermesi, paylasimli arama noktalari, uniformali komandoyu rutbeye gore tanima, bayilan askerin ayilmasi.

const SpriteSheet = preload("res://scripts/sprite_sheet.gd")
const Fx = preload("res://scripts/fx.gd")
const SHEET_FMT := "res://assets/sprites/alman_%s_sprite_sheet.png"   # Blender ciktisi
const SHEET_FALLBACK := "res://assets/sprites/enemy_sprite_sheet.png"   # elle eklenen
const VIEW_RANGE := 230.0
const VIEW_HALF := 0.56          # ~32 derece
const RAYS := 24
const NEAR_FRAC := 0.55          # koninin yakin kismi: comelen burada gorulur (Desperados III)
const BUSH_SEE := 105.0          # caliya saklanani bu mesafeden yakin gorur (comelikse x0.7)
const PERIPHERAL := 46.0         # arkasindan bile hissettigi mesafe (comelmeyen ve hareket eden)

# rutbe -> [can, gorus carpani, tespit hizi, atis araligi (sn), hasar, isabet]
const RANKS := {
	"er":    [60.0,  1.0,  1.0,  1.35, 11.0, 0.74],
	"kis":   [60.0,  1.0,  1.0,  1.35, 11.0, 0.74],
	"elit":  [110.0, 1.15, 1.25, 1.05, 14.0, 0.82],
	"subay": [80.0,  1.1,  1.35, 1.1,  13.0, 0.80],
	"kule":  [60.0,  1.55, 1.15, 1.5,  12.0, 0.70],   # gozetleme kulesi: uzagi gorur, yerinden ayrilmaz
}
const WHISTLE := 320.0           # catismaya giren askerin seslendigi mesafe (subay: duduk, x1.6)

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
# yapay zeka v3
var buddy = null                  # yakindaki nobet arkadasi: yoklugu fark edilir (Shadow Tactics)
var buddy_post := Vector2.ZERO
var _buddy_checked := false
var _buddy_dead_t := 0.0
var flank := 0.0                  # catismada kusatma yonu (-1..1): herkes ayni noktaya kosmaz
var _cover_pos = null             # yaralaninca siper alma
var _cover_t := 0.0
var _took_cover := false
var _last_dir := Vector2.ZERO     # hedefin son gorulen hareket yonu (tahminli arama)
var drops := ""                   # oldugunde dusen esya (anahtar)
var siren_pos := Vector2.ZERO
var _far_t := 0.0
var _slow := 1.0
var _slow_t := 0.0     # alarma kosarken hedef siren
# yapay zeka v4
var vigilant_t := 0.0             # tetikte kalma suresi (Shadow Tactics: suphelenen asker bir sure dikkatli)
var _trail := 0                   # ayak izi takibi: kalan adim
var _trail_age := 0.0
var _grenade_t := 0.0             # el bombasi bekleme (SS/subay)
var knocked := false              # bayiltildi (yumruk): ayilir, bagli degilse
var tied := false                 # baglandi: bir daha ayilmaz
var _wake_t := 0.0
var stripped := false             # uniformasi alindi
const VIGIL_TIME := 45.0
const GRENADE_R := 72.0


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
		if SpriteSheet.sheet_exists(path):
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
		if knocked and not tied and not carried and not main.game_over:
			_wake_t -= delta
			if _wake_t <= 0.0:
				_wake_up()
		return
	t += delta
	vigilant_t = maxf(0.0, vigilant_t - delta)
	_grenade_t -= delta
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
		if kind == "kule":
			sprite.position = Vector2(0, -46).rotated(SpriteSheet.view_rot)   # kulenin platformunda durur
	_cone_t -= delta
	if _cone_t <= 0.0:
		# sakin devriyede koni daha seyrek guncellenir (mobil/web performansi); tetikteyken akici
		_cone_t = 0.06 if (state != &"patrol" or suspicion > 0.0 or velocity.length() > 1.0 and main.alert_level > 0) else 0.11
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
					var amp := 0.8 if kind == "kule" else 0.9
					facing = lerp_angle(facing, base_facing + sin(t * (0.45 if kind == "kule" else 0.7)) * amp, minf(1.0, delta * 4.0))
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
		&"alarm_run":
			# Commandos / Desperados: asker sirene kosar; ulasirsa kirmizi alarm. Yolda durdurursan alarm calmaz.
			if _walk(delta, 1.75) or global_position.distance_to(siren_pos) < 26.0:
				main.siren_reached(self)
				_set_investigate(investigate_pos)


func _combat(delta: float) -> void:
	if target == null or not is_instance_valid(target) or not target.alive:
		target = null
		_start_search()
		return
	var tp: Vector2 = target.global_position
	var d := global_position.distance_to(tp)
	var sees: bool = d < view_range() * 1.25 and main.level.has_los(global_position, tp)
	# yaralandi: bir kez siper al, kisa sure bekle, sonra yeniden catis
	if _cover_pos != null:
		if _walk(delta, 1.8) or global_position.distance_to(_cover_pos) < 10.0:
			velocity = Vector2.ZERO
			_cover_t -= delta
			facing = lerp_angle(facing, (tp - global_position).angle(), minf(1.0, delta * 6.0))
			if _cover_t <= 0.0:
				_cover_pos = null
		return
	if sees and not _took_cover and hp < max_hp * 0.4 and kind != "kule":
		_took_cover = true
		var cp = _find_cover(tp)
		if cp != null:
			_cover_pos = cp
			_cover_t = 3.0
			_goal = null
			navigation_agent.target_position = cp
			return
	if sees:
		_lost_t = 0.0
		investigate_pos = tp
		if target.velocity.length() > 5.0:
			_last_dir = target.velocity.normalized()
		velocity = Vector2.ZERO
		var want := (tp - global_position).angle()
		facing = lerp_angle(facing, want, minf(1.0, delta * 10.0))
		_fire_t -= delta
		# once namluyu hedefe cevir, sonra ates (refleks: alarm seviyesine bagli)
		if _fire_t <= 0.0 and absf(wrapf(want - facing, -PI, PI)) < 0.3:
			var iv := _stat(3) * randf_range(0.85, 1.2)
			if main.alert_level >= 2:
				iv *= 0.85
			_fire_t = iv
			_shoot(target, d)
	else:
		# gorus kaybedildi: son gorulen yere kos, bulamazsa ara
		_lost_t += delta
		# kusatma: son gorulen noktanin yanina, her asker farkli taraftan
		var to_me := global_position - investigate_pos
		var side := investigate_pos + to_me.normalized().orthogonal() * flank * 80.0 if to_me.length() > 120.0 else investigate_pos
		if _dest().distance_to(side) > 30.0:
			_goal = null
			navigation_agent.target_position = side
		if _walk(delta, 1.7) or _lost_t > 6.0:
			target = null
			_start_search()


func _find_cover(tp: Vector2):
	## hedefin goremeyecegi, yakindaki bir nokta (siper)
	var map: RID = navigation_agent.get_navigation_map()
	var away := (global_position - tp).angle()
	for r in [90.0, 160.0]:
		for i in 9:
			var a := away + (i - 4) * 0.55
			var q: Vector2 = NavigationServer2D.map_get_closest_point(map, global_position + Vector2.from_angle(a) * r)
			if q.distance_to(global_position) > 40.0 and not main.level.has_los(q, tp):
				return q
	return null


func _shoot(tgt, dist: float) -> void:
	var acc := clampf(_stat(5) - dist / 700.0 + (0.05 if main.alert_level >= 2 else 0.0), 0.2, 0.92)
	# siper: alcak engelin (kum torbasi, sandik) arkasindaki hedef zor vurulur, comelikse daha da zor
	if main.level.in_cover(tgt.global_position, global_position):
		acc *= 0.45 if (tgt.has_method("is_crouching") and tgt.is_crouching()) else 0.7
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
	var map0: RID = navigation_agent.get_navigation_map()
	if _last_dir != Vector2.ZERO:
		# tahminli arama: hedefin kactigi yone dogru once bak
		_search_pts.append(NavigationServer2D.map_get_closest_point(map0, investigate_pos + _last_dir * 160.0))
		_last_dir = Vector2.ZERO
	# paylasimli arama: yakinda arayan arkadaslarin baktigi noktalara bakma, alani bolusun
	var claimed: Array = []
	for g in get_tree().get_nodes_in_group("guards"):
		if g != self and g.alive and g.state == &"search" and g.global_position.distance_to(global_position) < 400.0:
			claimed.append_array(g._search_pts)
			claimed.append(g._dest())
	var tries := 0
	while _search_pts.size() < (4 if vigilant_t > 0.0 else 3) and tries < 14:
		tries += 1
		var p: Vector2 = investigate_pos + Vector2.from_angle(randf() * TAU) * randf_range(60, 170)
		var q: Vector2 = NavigationServer2D.map_get_closest_point(map0, p)
		var ok := true
		for c in claimed:
			if c.distance_to(q) < 75.0:
				ok = false
				break
		if ok or tries > 10:
			_search_pts.append(q)
			claimed.append(q)
	vigilant_t = maxf(vigilant_t, VIGIL_TIME * 0.5)
	navigation_agent.target_position = global_position


var _goal = null                   # kapidan gecerken asil hedef


func _dest() -> Vector2:
	return _goal if _goal != null else navigation_agent.target_position


func _door_hop() -> void:
	## hedef baska bir alanda (bina ici / disi): once kapiya git, kapidan gec
	var lvl = main.level
	var goal: Vector2 = _dest()
	var here: int = lvl.interior_at(global_position)
	var there: int = lvl.interior_at(goal)
	if here == there:
		if _goal != null:
			navigation_agent.target_position = _goal
			_goal = null
		return
	var door: Vector2 = lvl.interiors[here]["int_door"] if here >= 0 else lvl.interiors[there]["ext_door"]
	if global_position.distance_to(door) < 30.0:
		# kapidan gec
		global_position = lvl.interiors[here]["ext_door"] if here >= 0 else lvl.interiors[there]["int_door"]
		navigation_agent.target_position = goal
		_goal = null
		return
	if _goal == null:
		_goal = goal
	if navigation_agent.target_position.distance_to(door) > 2.0:
		navigation_agent.target_position = door


func _walk(delta: float, speed_mul: float) -> bool:
	## hedefe yuru; vardiysa true dondur
	if kind == "kule":
		# kule nobetcisi yerinden ayrilmaz: sadece o yone bakar
		velocity = Vector2.ZERO
		var tgt: Vector2 = _dest()
		if tgt.distance_to(global_position) > 4.0:
			facing = lerp_angle(facing, (tgt - global_position).angle(), minf(1.0, delta * 3.0))
		return true
	if _goal != null or main.level.interiors.size() > 0:
		_door_hop()
	if navigation_agent.is_navigation_finished():
		_goal = null      # kapiya ulasilamadi: vazgec
		velocity = Vector2.ZERO
		return true
	var next: Vector2 = navigation_agent.get_next_path_position()
	var dir := global_position.direction_to(next)
	_slow_t -= delta
	if _slow_t <= 0.0:
		_slow_t = 0.25
		_slow = main.level.speed_mul(global_position)
	var mul := speed_mul * (1.3 if main.alert_level > 0 else 1.0) * _slow
	velocity = dir * speed * mul
	facing = lerp_angle(facing, dir.angle(), minf(1.0, delta * 5.0))
	move_and_slide()
	return false


func _go_patrol() -> void:
	_goal = null
	state = &"patrol"
	if reinforcement and waypoints.is_empty():
		waypoints = [investigate_pos]
	if waypoints.size() > 0:
		navigation_agent.target_position = waypoints[wp_i]


func _set_investigate(p: Vector2) -> void:
	_goal = null
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
		flank = randf_range(-1.0, 1.0)
		# tepki suresi (refleks): habersiz 1.0 sn, sari alarm 0.7 sn, kirmizi alarm 0.45 sn; SS %15 daha hizli
		_fire_t = [1.0, 0.7, 0.45][clampi(main.alert_level, 0, 2)] * (0.85 if kind == "elit" else 1.0)
		# yakindakilere seslen (duvar arkasi dahil, ama sadece yakindakiler); subay duduk calar
		var wr := WHISTLE * (1.6 if kind == "subay" else 1.0)
		for g in get_tree().get_nodes_in_group("guards"):
			if g != self and g.alive and g.state != &"combat" and g.state != &"alarm_run" and g.global_position.distance_to(global_position) < wr:
				g.alerted_by(tgt)
		main.combat_alarm(tgt.global_position, self)


func alerted_by(tgt) -> void:
	## arkadasi seslendi: hedefi goruyorsa catisma, gormuyorsa oraya kos
	if main.level.has_los(global_position, tgt.global_position) and global_position.distance_to(tgt.global_position) < view_range() * 1.2:
		enter_combat(tgt)
	else:
		suspicion = 0.5
		_set_investigate(tgt.global_position)


func hear_noise(p: Vector2) -> void:
	## silah sesi / patlama: catismada degilse sesin geldigi yere git
	if not alive or state == &"combat" or state == &"alarm_run" or carried:
		return
	_set_investigate(p)


func hear_distraction(p: Vector2) -> void:
	## atilan tas: alarm vermeden bakmaya gider (Commandos / Desperados III dikkat dagitma)
	if not alive or carried or state == &"combat" or state == &"alarm_run":
		return
	suspicion = maxf(suspicion, 0.25)
	_set_investigate(p)


func run_to_siren(sp: Vector2, incident: Vector2) -> void:
	_goal = null
	state = &"alarm_run"
	siren_pos = sp
	investigate_pos = incident
	navigation_agent.target_position = sp


func hear_alarm(p: Vector2) -> void:
	hear_noise(p)


func _follow_trail() -> bool:
	## ayak izi takibi: buradan daha yeni bir iz yakindaysa ona git
	if _trail <= 0:
		return false
	var best = null
	var bd := 150.0
	for fp in main.level.footprints:
		if fp["age"] < _trail_age and not fp["noticed"]:
			var d: float = fp["pos"].distance_to(global_position)
			if d < bd and main.level.has_los(global_position, fp["pos"]):
				bd = d
				best = fp
	if best == null:
		_trail = 0
		return false
	_trail -= 1
	best["noticed"] = true
	_trail_age = best["age"]
	_set_investigate(best["pos"])
	return true


func _try_grenade() -> bool:
	## SS / subay: siperde saklanan hedefe el bombasi (Commandos / Partisans)
	if kind != "elit" and kind != "subay" or _grenade_t > 0.0:
		return false
	if _lost_t < 1.2:
		return false
	var p := investigate_pos
	var d := global_position.distance_to(p)
	if d < 110.0 or d > 300.0 or main.level.interior_at(p) != main.level.interior_at(global_position):
		return false
	for g in get_tree().get_nodes_in_group("guards"):
		if g != self and g.alive and g.global_position.distance_to(p) < GRENADE_R + 20.0:
			return false      # arkadasini vurmaz
	_grenade_t = 14.0
	velocity = Vector2.ZERO
	facing = (p - global_position).angle()
	if sprite != null:
		SpriteSheet.play(sprite, &"shoot", facing, true)
	main.throw_grenade(self, global_position, p)
	return true


func knock_out() -> void:
	## yumrukla bayiltildi: ~40 sn sonra ayilir (baglanmazsa), ceset gibi bulunabilir
	if not alive:
		return
	knocked = true
	_wake_t = 40.0
	kill()


func _wake_up() -> void:
	knocked = false
	alive = true
	hp = max_hp * 0.6
	main.bodies.erase(self)
	discovered = false
	hidden_body = false
	collision_layer = 2
	for ch in get_children():
		if ch is CollisionShape2D:
			ch.set_deferred("disabled", false)
	vigilant_t = VIGIL_TIME * 2.0
	suspicion = 0.6
	investigate_pos = global_position
	if sprite != null:
		sprite.visible = true
	main.guard_woke(self)
	_start_search()


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
	if absf(wrapf(d.angle() - facing, -PI, PI)) > VIEW_HALF * (1.2 if vigilant_t > 0.0 else 1.0):
		return false
	if main.level.has_los(global_position, p):
		return true
	# cali gorusu engeller ama yakindan delip gecer
	var bush_r := BUSH_SEE * (0.7 if crouched else 1.0) * _stat(1)
	# alarmda askerler calilari dikkatle tarar: sari x1.35, kirmizi x1.75
	bush_r *= [1.0, 1.35, 1.75][clampi(main.alert_level, 0, 2)]
	if state == &"search" or state == &"investigate":
		bush_r *= 1.15
	return d.length() < bush_r and main.level.has_los(global_position, p, true)


func _watch(delta: float) -> void:
	if state == &"combat" or state == &"alarm_run":
		return
	# uzaktaki askerler (her oyuncudan 1500 px+) daha seyrek dusunur: buyuk haritada performans
	if main.far_from_players(global_position):
		_far_t -= delta
		if _far_t > 0.0:
			return
		delta = 0.2 - _far_t
		_far_t = 0.2
	var spotted = null
	var sd := 0.0
	for u in main.players:
		if not u.alive:
			continue
		var cr: bool = u.has_method("is_crouching") and u.is_crouching()
		var dd := global_position.distance_to(u.global_position)
		# uniforma (Commandos 2 kilik): erler ancak cok yakindan ya da kosarken fark eder,
		# SS ve subay koninin yakin kisminda tanir
		var dis: String = u.get("disguise") if u.get("disguise") != null else ""
		if dis != "":
			if kind == "elit" or kind == "subay":
				cr = true
			elif not (dd < 52.0 and (u.velocity.length() > 1.0 or cr)) and not u.get("run"):
				continue
		# cevresel algi: cok yakinda, ayakta ve hareket ediyorsa arkadan da hisseder
		var feel: bool = dd < PERIPHERAL and not cr and u.velocity.length() > 1.0
		if feel or can_see(u.global_position, cr):
			spotted = u
			sd = dd
			break
	if spotted != null:
		var near := clampf(1.0 - sd / view_range(), 0.15, 1.0)
		var rate := (0.7 + near * 2.6) * _stat(2)
		if vigilant_t > 0.0:
			rate *= 1.25
		var sdis = spotted.get("disguise")
		if sdis != null and sdis != "":
			rate *= 0.6
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
	for g in main.bodies:
		if not g.discovered and not g.hidden_body and not g.carried and can_see(g.global_position):
			g.discovered = true
			_set_investigate(g.global_position)
			main.body_found(g.global_position, self)
			return
	# kayip nobet arkadasi: arkadasinin yerine bakinca orada yoksa supheleniyor (ceset saklansa bile)
	if buddy != null and not _buddy_checked and (state == &"patrol" or state == &"search"):
		if not buddy.alive:
			_buddy_dead_t += 0.25
			if _buddy_dead_t > 6.0 and can_see(buddy_post):
				_buddy_checked = true
				main.buddy_missing(self, buddy_post)
				_set_investigate(buddy_post)
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
	if not alive:
		return
	alive = false
	main.bodies.append(self)
	if drops != "":
		main.level.add_pickup({"type": "key", "item": drops, "pos": global_position + Vector2(14, 6), "taken": false, "count": 1})
		main.hud.toast("Asker bir anahtar düşürdü!")
	if state == &"alarm_run":
		main.runner_stopped(self)
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
	if state == &"combat" or state == &"alarm_run":
		return Color(1.0, 0.2, 0.15, 0.32)
	if state == &"investigate" or state == &"search":
		return Color(1.0, 0.6, 0.2, 0.22)
	if suspicion > 0.0:
		return Color(1.0, 0.85, 0.2, 0.2 + suspicion * 0.2)
	return Color(0.4, 0.8, 1.0, 0.16)


# ---------------- Cizim ----------------
func _draw() -> void:
	if not alive and knocked:
		draw_set_transform(Vector2.ZERO, SpriteSheet.view_rot, Vector2.ONE)
		draw_string(ThemeDB.fallback_font, Vector2(-14, -18), "bağlı" if tied else "zzz", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.9, 1.0, 0.85))
	if not alive and sprite != null and SpriteSheet.base_anim(sprite) == "death":
		return
	if not alive:
		if sprite != null:
			sprite.visible = false
		draw_set_transform(Vector2.ZERO, facing, Vector2.ONE)
		draw_rect(Rect2(-14, -7, 28, 14), Color(0.32, 0.34, 0.3))
		draw_circle(Vector2(13, 0), 6, Color(0.25, 0.27, 0.23))
		draw_rect(Rect2(-18, -9, 4, 18), Color(0.4, 0.1, 0.1, 0.7))
		draw_set_transform(Vector2.ZERO, SpriteSheet.view_rot, Vector2.ONE)
		return
	var body := Vector2(0, -12)
	if sprite != null:
		_draw_alert(Vector2(0, -90 if kind == "kule" else -44))
		return
	draw_set_transform(Vector2.ZERO, SpriteSheet.view_rot, Vector2(1, 0.5))
	draw_circle(Vector2.ZERO, 12, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, SpriteSheet.view_rot, Vector2.ONE)
	draw_circle(body, 11, Color(0.12, 0.13, 0.1))
	draw_circle(body, 9.5, Color(0.45, 0.48, 0.4))                                     # feldgrau
	draw_circle(body + Vector2.from_angle(facing) * 3 + Vector2(0, -3), 6.5, Color(0.3, 0.33, 0.28))  # kask
	draw_line(body, body + Vector2.from_angle(facing + 0.4) * 17, Color(0.2, 0.15, 0.1), 3.0)          # tufek
	_draw_alert(body)


func _draw_alert(body: Vector2) -> void:
	draw_set_transform(Vector2.ZERO, SpriteSheet.view_rot, Vector2.ONE)
	var font := ThemeDB.fallback_font
	if hp < max_hp:
		var w := 30.0
		draw_rect(Rect2(-w / 2, body.y - 34, w, 4), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-w / 2, body.y - 34, w * hp / max_hp, 4), Color(0.9, 0.2, 0.15))
	if state == &"alarm_run":
		draw_string(font, body + Vector2(-16, -19), "ALARM", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 0.2, 0.15))
	elif state == &"combat":
		draw_string(font, body + Vector2(-5, -19), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 0.25, 0.2))
	elif suspicion > 0.0:
		draw_arc(body + Vector2(0, -24), 8, -PI / 2, -PI / 2 + TAU * minf(suspicion, 1.0), 20, Color(1, 0.8, 0.2), 3.0)
		draw_string(font, body + Vector2(-4, -19), "!" if suspicion > 0.6 else "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	elif state == &"investigate" or state == &"search":
		draw_string(font, body + Vector2(-4, -19), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.6, 0.2))
	if kind == "subay" or kind == "elit":
		draw_string(font, body + Vector2(-14, 26), "Subay" if kind == "subay" else "SS", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 0.9, 0.6, 0.8))
