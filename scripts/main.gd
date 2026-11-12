extends Node2D
## Oyun akisi, kamera, girdi ve arayuz. Dunya verisi levels/*.json dosyasindan gelir.

const Level = preload("res://scripts/level.gd")
const ConeLayer = preload("res://scripts/cone_layer.gd")
const Commando = preload("res://scripts/commando.gd")
const Guard = preload("res://scripts/guard.gd")
const Hud = preload("res://scripts/hud.gd")
const Mission = preload("res://scripts/mission.gd")
const Npc = preload("res://scripts/npc.gd")
const Fx = preload("res://scripts/fx.gd")

const LEVELS := [
	["res://levels/bolum0.json", "Bölüm 0 – Normandiya Köyü", "Eğitim: küçük köy, 6 asker"],
	["res://levels/bolum1.json", "Bölüm 1 – Nehir Operasyonu", "Geniş harita: nehir, köprüler, köy, karargâh, kışlalar"],
	["res://levels/bolum2.json", "Bölüm 2 – Karlı Kale", "Norveç fiyordu: kale, hapishane, radar, kuleler, derin kar"],
	["res://levels/bolum3.json", "Bölüm 3 – Denizaltı Üssü", "Atlantik limanı: bunker, kontrol odası, demiryolu, 5 kışla"],
	["res://levels/bolum4.json", "Bölüm 4 – Gece Treni", "Gece, demiryolu kavşağı: projektörler, dikenli tel, mühimmat treni"],
	["res://levels/bolum5.json", "Bölüm 5 – Kartal Yuvası", "Final: Richter'in şatosu, havaalanı, bocage çitleri, 76 asker"],
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
var bodies: Array = []        # olu askerler (her asker her karede tum askerleri taramasin)
var players: Array = []       # oyuncu tarafindaki karakterler (komando + izleyenler)
var runner = null             # sirene kosan asker
var throw_mode := false       # tas atma: siradaki dokunus tasin dusecegi yer
var _cut_i := -1              # kesilen tel (Tur 3)
var _reinforced := false      # bu alarmda kisla takviyesi gonderildi mi
var _cut_t := 0.0
const CUT_TIME := 3.0
const SAVE_PATH := "user://kayit.cfg"

# kamera / girdi
var cam: Camera2D
var pressed := false
var dragging := false
var press_pos := Vector2.ZERO
var touches := {}
var last_pinch := 0.0

var hud
var mission
var cones
var roofs_node: Node2D
var _last_tap_t := -10.0
var _last_tap_p := Vector2.ZERO


func _ready() -> void:
	if level_choice != "":
		level_path = level_choice
	level = Level.new()
	add_child(level)
	cones = ConeLayer.new()
	add_child(cones)
	world = Node2D.new()
	world.y_sort_enabled = true      # asagidaki (Y'si buyuk) onde gorunur
	add_child(world)
	var roofs := Node2D.new()
	roofs.z_index = 10
	add_child(roofs)
	roofs_node = roofs

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
		g.drops = gd.get("drops", "")
		world.add_child(g)

	_pair_buddies()
	_assign_light_ops()
	commando = Commando.new()
	commando.main = self
	commando.stones = int(level.data.get("stones", 4))
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

	if level.data.has("ambient"):
		# gece / kar havasi: dunyayi renklendir (arayuz etkilenmez)
		var am: Array = level.data["ambient"]
		var cm := CanvasModulate.new()
		cm.color = Color(am[0], am[1], am[2])
		add_child(cm)
	cam = Camera2D.new()
	cam.ignore_rotation = false        # 4 yonlu bakis: kamera doner
	cam.position = commando.position
	add_child(cam)
	cam.make_current()
	level.view_ready.connect(_view_done)
	level.stream_ground()      # zemin karolari arka planda (brifing sirasinda) yuklenir
	_clamp_cam()
	hud = Hud.new()
	hud.main = self
	add_child(hud)
	if level_choice == "":
		hud.show_menu(LEVELS)
	elif briefed != level_path:
		briefed = level_path
		hud.show_briefing(level.data, mission.objectives)


func _pair_buddies() -> void:
	## her nobetci en yakin arkadasini bilir: arkadasi kaybolursa fark eder
	var gs: Array = get_tree().get_nodes_in_group("guards")
	for g in gs:
		var best = null
		var bd := 380.0
		for h in gs:
			if h == g or level.interior_at(h.position) != level.interior_at(g.position):
				continue
			var d: float = h.position.distance_to(g.position)
			if d < bd and level.has_los(g.position, h.position):
				bd = d
				best = h
		if best != null:
			g.buddy = best
			g.buddy_post = best.position


func _assign_light_ops() -> void:
	## her projektoru en yakin nobetci (tercihen kule) yonetir; o olurse isik soner
	for sl in level.searchlights:
		var best = null
		var bd := 320.0
		for g in get_tree().get_nodes_in_group("guards"):
			var d: float = g.position.distance_to(sl["pole"]) - (120.0 if g.kind == "kule" else 0.0)
			if d < bd:
				bd = d
				best = g
		sl["op"] = best


func _update_lights(delta: float) -> void:
	## projektor: isik yol boyunca gidip gelir; icinde kalan karakter ~0.5 sn'de fark edilir
	for sl in level.searchlights:
		if not sl["on"]:
			continue
		var op = sl["op"]
		if op != null and (not is_instance_valid(op) or not op.alive):
			sl["on"] = false
			hud.toast("Projektör söndü (operatör etkisiz)")
			continue
		var path: Array = sl["path"]
		var total := 0.0
		for i in path.size() - 1:
			total += path[i].distance_to(path[i + 1])
		if total <= 0.0:
			continue
		var spd: float = sl["speed"] * (1.4 if alert_level >= 1 else 1.0)
		sl["u"] = float(sl["u"]) + sl["dir"] * spd * delta / total
		if sl["u"] >= 1.0 or sl["u"] <= 0.0:
			sl["u"] = clampf(sl["u"], 0.0, 1.0)
			sl["dir"] = -sl["dir"]
		var dist: float = sl["u"] * total
		var p: Vector2 = path[0]
		for i in path.size() - 1:
			var l: float = path[i].distance_to(path[i + 1])
			if dist <= l:
				p = path[i].lerp(path[i + 1], dist / maxf(l, 0.001))
				break
			dist -= l
			p = path[i + 1]
		# alarmda isik oyuncuyu kovalar
		if alert_level >= 2 and op != null and op.target != null and is_instance_valid(op.target):
			p = sl["pos"].move_toward(op.target.global_position, spd * 1.5 * delta)
		sl["pos"] = p
		var lit = null
		for u in players:
			if u.alive and level.interior_at(u.global_position) < 0 and u.global_position.distance_to(p) < sl["r"]:
				if u.has_method("is_hidden") and u.is_hidden():
					continue
				lit = u
				break
		if lit != null:
			sl["heat"] = float(sl["heat"]) + delta
			if sl["heat"] > 0.5:
				sl["heat"] = 0.0
				stats["lit"] = stats.get("lit", 0) + 1
				hud.toast("Projektör seni gördü!")
				if op != null:
					op.enter_combat(lit)
				else:
					combat_alarm(lit.global_position, null)
		else:
			sl["heat"] = maxf(0.0, float(sl["heat"]) - delta)


func far_from_players(p: Vector2) -> bool:
	for u in players:
		if u.global_position.distance_squared_to(p) < 1500.0 * 1500.0:
			return false
	return true


func combat_alarm(p: Vector2, by) -> void:
	## catisma basladi: sireni olan bolumde biri sirene kosar (onu durdurabilirsin), yoksa telsizle kirmizi alarm
	if level.sirens.is_empty():
		raise_alarm(p, by)
		return
	if alert_level >= 2:
		alarm_t = maxf(alarm_t, 35.0)
		if not _reinforced:
			_dispatch_runner(p, by)       # takviye hala siren calinmasina bagli
		return
	# Tur 3c: asker "ALARM!" diye bagirir -> alarm hemen kirmizi (herkes tetikte, genis arama).
	# Kisla takviyesi icin biri yine sirene kosar: onu durdurursan takviye gelmez.
	alarm_t = maxf(alarm_t, 35.0)
	stats["alarms"] += 1
	set_alert_level(2)
	hud.set_alarm(2, "ALARM! Asker bağırdı – sirene koşanı durdur, yoksa takviye gelir")
	_sweep(p, by)
	_dispatch_runner(p, by)


func _dispatch_runner(p: Vector2, by) -> void:
	if runner != null and is_instance_valid(runner) and runner.alive and runner.state == &"alarm_run":
		return
	var sp: Vector2 = level.sirens[0]
	for q in level.sirens:
		if q.distance_to(p) < sp.distance_to(p):
			sp = q
	if sp.distance_to(p) > 1500.0:
		raise_alarm(p, by)
		return
	var best = null
	var bd := INF
	for g in get_tree().get_nodes_in_group("guards"):
		if not g.alive or g.carried or g.kind == "kule" or g.state == &"combat" and g != by:
			continue
		if g.global_position.distance_to(p) > 480.0:
			continue
		var d: float = g.global_position.distance_to(sp)
		if g == by:
			d += 250.0       # tercihen catismayan biri kossun
		if d < bd:
			bd = d
			best = g
	if best == null:
		if by != null and by.kind == "kule":
			raise_alarm(p, by)      # kule nobetcisi zil calar
		return
	runner = best
	best.run_to_siren(sp, p)
	hud.toast("Bir asker alarm sirenine koşuyor! Onu durdur!")


func siren_reached(g) -> void:
	runner = null
	level.siren_on = 30.0
	hud.toast("Siren çaldı!")
	raise_alarm(g.investigate_pos, g)


func runner_stopped(_g) -> void:
	runner = null
	hud.toast("Alarm koşucusu durduruldu")
	stats["runners_stopped"] = stats.get("runners_stopped", 0) + 1


func buddy_missing(g, post: Vector2) -> void:
	if alert_level < 1:
		set_alert_level(1)
	hud.toast("Bir nöbetçi arkadaşının kaybolduğunu fark etti!")
	stats["missed"] = stats.get("missed", 0) + 1
	# yakindakilere haber verir: birlikte ararlar
	for h in get_tree().get_nodes_in_group("guards"):
		if h != g and h.alive and h.state == &"patrol" and h.kind != "kule" and h.global_position.distance_to(post) < 420.0:
			h.hear_distraction(post + Vector2(randf_range(-80, 80), randf_range(-80, 80)))


func throw_grenade(g, from: Vector2, to: Vector2) -> void:
	## SS / subay el bombasi: 1.3 sn sonra patlar, yakindakilere hasar (siper korumaz, kac!)
	Fx.stone(world, from + Vector2(0, -20), to)
	hud.toast("El bombası!")
	stats["grenades"] = stats.get("grenades", 0) + 1
	get_tree().create_timer(1.3, false).timeout.connect(func():
		if game_over:
			return
		var fx = load("res://scripts/explosion.gd").new()
		fx.position = to
		fx.scale = Vector2(0.6, 0.6)
		world.add_child(fx)
		level.add_scorch(to, 40.0)
		for u in get_tree().get_nodes_in_group("player"):
			var d: float = u.global_position.distance_to(to)
			if u.alive and d < g.GRENADE_R and level.has_los(to, u.global_position):
				u.take_damage(70.0 * (1.0 - d / g.GRENADE_R * 0.6), to)
		for h in get_tree().get_nodes_in_group("guards"):
			if h.alive and h.global_position.distance_to(to) < g.GRENADE_R * 0.6:
				h.take_damage(60.0, to)
		make_noise(to, 600.0, null))


func scuffle(p: Vector2, killer) -> void:
	## bicak/yumruk: kisa bogusma sesi; olayi goren asker hemen catismaya girer (tanik)
	for g in get_tree().get_nodes_in_group("guards"):
		if not g.alive or g.state == &"combat":
			continue
		var d: float = g.global_position.distance_to(p)
		if d < 260.0 and g.can_see(killer.global_position, killer.is_crouching()):
			g.enter_combat(killer)
			stats["witnessed"] = stats.get("witnessed", 0) + 1
		elif d < 70.0 and level.interior_at(g.global_position) == level.interior_at(p):
			g.hear_distraction(p)


func guard_woke(g) -> void:
	hud.toast("Bayılan asker ayıldı!")
	if alert_level < 1:
		set_alert_level(1)
	for h in get_tree().get_nodes_in_group("guards"):
		if h != g and h.alive and h.state == &"patrol" and h.kind != "kule" and h.global_position.distance_to(g.global_position) < 360.0:
			h.hear_distraction(g.global_position + Vector2(randf_range(-60, 60), randf_range(-60, 60)))


func whistle(p: Vector2) -> int:
	## islik: yakindaki askerleri bulundugun yere cek (Shadow Tactics / Commandos 2 tuzagi)
	var n := 0
	for g in get_tree().get_nodes_in_group("guards"):
		if g.alive and g.kind != "kule" and g.state != &"combat" and g.global_position.distance_to(p) < 190.0 \
				and level.interior_at(g.global_position) == level.interior_at(p):
			g.hear_distraction(p)
			n += 1
	stats["whistles"] = stats.get("whistles", 0) + 1
	return n


func distract(p: Vector2, radius: float) -> void:
	## tas dustu: yakindaki askerler alarm vermeden bakmaya gider
	var n := 0
	for g in get_tree().get_nodes_in_group("guards"):
		if g.alive and g.global_position.distance_to(p) < radius and level.interior_at(g.global_position) == level.interior_at(p):
			g.hear_distraction(p)
			n += 1
	stats["distractions"] = stats.get("distractions", 0) + 1


func choose_level(path: String) -> void:
	level_choice = path
	briefed = ""
	get_tree().paused = false
	get_tree().reload_current_scene()


# ---------------- Oyun akisi ----------------
func score() -> Dictionary:
	## bolum sonu puani (Commandos tarzi istatistik): gizlilik odullendirilir
	var t: float = mission.elapsed
	var pts := 1000
	pts -= int(stats["alarms"]) * 150
	pts -= int(stats.get("bodies_found", 0)) * 60
	pts -= int(stats.get("missed", 0)) * 40
	var dead := 0
	for g in bodies:
		if not g.knocked:
			dead += 1
	pts -= dead * 10
	pts += int(stats.get("knockouts", 0)) * 15         # oldurmeden etkisiz birakmak odullendirilir
	pts += int(stats.get("runners_stopped", 0)) * 50
	pts -= int(stats.get("witnessed", 0)) * 40
	for o in mission.objectives:
		if o["done"] and o.get("optional", false):
			pts += 200
	pts = maxi(pts, 0)
	var rank := "Çaylak"
	if stats["alarms"] == 0 and stats.get("bodies_found", 0) == 0:
		rank = "Hayalet"
	elif pts >= 800:
		rank = "Usta"
	elif pts >= 500:
		rank = "Komando"
	return {"time": t, "points": pts, "rank": rank, "stars": 3 if pts >= 800 else (2 if pts >= 500 else 1)}


func save_result(sc: Dictionary) -> String:
	## en iyi sonucu kaydet (bolum menusunde gosterilir)
	var cf := ConfigFile.new()
	cf.load(SAVE_PATH)
	var best: int = cf.get_value(level_path, "points", -1)
	var rec := ""
	if sc["points"] > best:
		cf.set_value(level_path, "points", sc["points"])
		cf.set_value(level_path, "rank", sc["rank"])
		cf.set_value(level_path, "stars", sc["stars"])
		rec = "  YENİ REKOR!"
	var bt: float = cf.get_value(level_path, "time", INF)
	if sc["time"] < bt:
		cf.set_value(level_path, "time", sc["time"])
	cf.save(SAVE_PATH)
	return rec


static func best_of(path: String) -> Dictionary:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK or not cf.has_section(path):
		return {}
	return {"points": cf.get_value(path, "points", 0), "rank": cf.get_value(path, "rank", ""),
		"stars": cf.get_value(path, "stars", 0), "time": cf.get_value(path, "time", 0.0)}


func win() -> void:
	var sc := score()
	var rec := save_result(sc)
	var t: float = sc["time"]
	_end("GÖREV TAMAMLANDI\nSüre %d:%02d   Puan %d   %s%s\n%s\nAlarm %d · Ceset bulundu %d · Öldürülen %d · Bayıltılan %d" % [
		int(t) / 60, int(t) % 60, sc["points"], "★".repeat(sc["stars"]) + "☆".repeat(3 - sc["stars"]), rec, sc["rank"],
		stats["alarms"], stats.get("bodies_found", 0), bodies.filter(func(g): return not g.knocked).size(), int(stats.get("knockouts", 0))], Color(0.5, 1, 0.5))


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
		_sweep(p, _by)
	if not _reinforced:
		_reinforced = true
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


func _sweep(p: Vector2, by) -> void:
	## alarm: yakindaki (900 px) en fazla 8 asker olay yerinin genis cevresini tarar
	var cand: Array = []
	for g in get_tree().get_nodes_in_group("guards"):
		if g == by or not g.alive or g.carried or g.kind == "kule" or g.state == &"combat" or g.state == &"alarm_run":
			continue
		if level.interior_at(g.global_position) != level.interior_at(p):
			continue
		var d: float = g.global_position.distance_to(p)
		if d < 900.0:
			cand.append([d, g])
	cand.sort_custom(func(a, b): return a[0] < b[0])
	for i in mini(8, cand.size()):
		cand[i][1].sweep(p)


func set_alert_level(l: int) -> void:
	alert_level = l
	if l < 2:
		_reinforced = false
	if l == 2:
		hud.set_alarm(2, "ALARM! Takviye birlikler kışladan çıkıyor")
	elif l == 1:
		hud.set_alarm(1, "DİKKAT: Askerler tetikte")
	else:
		hud.set_alarm(0, "")


func body_found(p: Vector2, by = null) -> void:
	if alert_level < 1:
		set_alert_level(1)
	stats["bodies_found"] = stats.get("bodies_found", 0) + 1
	hud.toast("Bir asker ceset buldu!")
	make_noise(p, 350.0, null)
	# sireni olan bolumde ceset bulan asker alarma kosar
	if not level.sirens.is_empty() and by != null and alert_level < 2:
		_dispatch_runner(p, null)


func _process(delta: float) -> void:
	level.update_z()
	players = get_tree().get_nodes_in_group("player")
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
	if not level.searchlights.is_empty():
		_update_lights(delta)
	if _cut_i >= 0:
		_cut_t += delta
		if (_cut_t > 0.3 and commando.velocity.length() > 1.0) or not commando.alive:
			_cut_i = -1
		elif _cut_t >= CUT_TIME:
			level.cut_wire(_cut_i)
			stats["wires"] = stats.get("wires", 0) + 1
			hud.toast("Tel kesildi: yeni geçit açıldı")
			_cut_i = -1
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


func is_locked(i: int) -> bool:
	var lk: String = level.interiors[i]["locked"]
	return lk != "" and not mission.items.has(lk)


func enter_building(i: int) -> void:
	var it: Dictionary = level.interiors[i]
	if is_locked(i):
		pending_enter = -1
		commando.move_to(commando.global_position)
		hud.toast("%s kilitli: %s gerekli" % [it["name"], it["locked"].replace("_", " ")])
		return
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
				hud.set_action(("Kilitli: " if is_locked(i) else "Gir: ") + level.interiors[i]["name"], true, func(): enter_building(ii))
				return
	if c.carrying != null:
		hud.set_action("Cesedi Bırak", true, func(): c.drop_body())
		return
	if mission.plant_target != null:
		var planting: bool = mission.planting >= 0.0
		var sab: bool = mission.plant_target["type"] == "sabotage"
		hud.set_action(("%s... %d%%" % ["Sabote ediliyor" if sab else "Kuruluyor", int(mission.planting / mission.plant_time() * 100.0)]) if planting else ("Sabote Et" if sab else "Patlayıcı Kur"),
				not planting, func(): mission.start_planting())
		return
	if _cut_i >= 0:
		hud.set_action("Tel kesiliyor... %d%%" % int(_cut_t / CUT_TIME * 100.0), false)
		return
	var wi: int = level.wire_near(c.global_position)
	if wi >= 0 and cur_interior < 0:
		var has_cutter: bool = mission.items.get("tel_makasi", 0) > 0
		hud.set_action("Teli Kes" if has_cutter else "Tel makası gerekli", has_cutter, func():
			_cut_i = wi
			_cut_t = 0.0
			c.move_to(c.global_position))
		return
	var b = c.body_nearby()
	if b != null:
		var t2 := ""
		var cb2 := Callable()
		if b.knocked and not b.tied and c.ropes > 0:
			t2 = "Bağla (%d)" % c.ropes
			cb2 = func(): c.tie_up(b)
		elif not b.stripped and (b.kind == "er" or b.kind == "kis") and c.disguise == "":
			t2 = "Üniforma Giy"
			cb2 = func(): c.put_on_uniform(b)
		hud.set_action("Taşı" if t2 != "" else ("Baygını Taşı" if b.knocked else "Cesedi Taşı"), true, func(): c.pick_body(b), t2, cb2)
		return
	hud.set_action("", false)


var end_text := ""


func _end(text: String, col: Color) -> void:
	game_over = true
	end_text = text
	hud.show_end(text, col)


# ---------------- Girdi ----------------
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_Q:
			rotate_view(-1)
		elif e.keycode == KEY_E:
			rotate_view(1)
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
			cam.position -= e.relative.rotated(cam.rotation) / cam.zoom
			_clamp_cam()


func rotate_view(step := 1) -> void:
	## Commandos 2 gibi haritayi 90 derece cevir (her aci Blender'da ayri render)
	var k := posmod(level.view + step, 4)
	var tries := 0
	while not level.has_view(k) and tries < 3:
		k = posmod(k + step, 4)
		tries += 1
	if k == level.view or level.view_loading >= 0 or not level.request_view(k):
		if level.view_loading < 0:
			hud.toast("Bu bölümün diğer açıları henüz render edilmedi")
		return
	if level.view_loading >= 0:
		# dokular arka planda yukleniyor: hazir olunca _view_done
		hud.show_busy("Çevriliyor…")


func _view_done(k: int) -> void:
	hud.show_busy("")
	cam.rotation = level.view_rot
	cones.z_index = 0 if k == 0 else -3900
	_clamp_cam()
	hud.toast("Bakış açısı: %s" % ["Kuzey", "Doğu", "Güney", "Batı"][k])


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
	if level.view % 2 == 1:
		half = Vector2(half.y, half.x)
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
	# cift dokunus: kos (Kos secili olmasa da bu hareket icin)
	var now := Time.get_ticks_msec() / 1000.0
	var dbl := now - _last_tap_t < 0.35 and p.distance_to(_last_tap_p) < 60.0
	_last_tap_t = now
	_last_tap_p = p
	if throw_mode:
		throw_mode = false
		hud.refresh_items()
		commando.throw_stone(p)
		return
	# secili silahla askere saldir (secim kalici; yere dokunmak sadece yurutur)
	for g in get_tree().get_nodes_in_group("guards"):
		# govde ayaklarin ustunde cizildigi icin oraya da bak
		if g.alive and (p.distance_to(g.global_position) < 28 or p.distance_to(g.global_position + Vector2(0, -20)) < 26):
			commando.attack(g)
			return
	commando.move_to(p)
	commando.run_once = dbl
	if dbl:
		_last_tap_t = -10.0
