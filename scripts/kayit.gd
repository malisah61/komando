extends RefCounted
## Bolum ici kayit sistemi (Tur 4).
##
## Yuvalar: "1", "2", "3" (elle), "hizli" (F5 / hizli kaydet), "oto" (bolum basi + her gorevden sonra).
## Dosya: user://kayitlar/<yuva>.json
##   {"surum": 1, "bolum": "res://levels/bolumN.json", "ad": "...", "tarih": "...", "unix": ..., "sure": sn,
##    "gorev": "3/9", "durum": "<var_to_str metni>"}
## Ust bilgi JSON (yuva listesi durumu acmadan okur); oyun durumu Godot var_to_str metni (Vector2 vb. korunur).
## Bicim surumludur: eski surumler _migrate ile yukseltilir, alan eksikse varsayilan kullanilir,
## bolum dosyasi kayittan sonra degistiyse (asker sayisi farkli) eslesen askerler uygulanir.
##
## Kural (adalet): catisma sirasinda ya da sirene kosan varken kaydedilemez - "kaydet, cik, gec" hilesi olmasin.

const Guard = preload("res://scripts/guard.gd")
const VERSION := 1
const DIR := "user://kayitlar"
const SLOTS := ["hizli", "oto", "1", "2", "3"]
const SLOT_NAMES := {"hizli": "Hızlı kayıt", "oto": "Otomatik kayıt", "1": "Yuva 1", "2": "Yuva 2", "3": "Yuva 3"}
const MANUAL := ["hizli", "1", "2", "3"]

static var dir_override := ""     # testler kendi klasorunu kullanir


static func _dir() -> String:
	return dir_override if dir_override != "" else DIR


static func slot_path(slot: String) -> String:
	return "%s/%s.json" % [_dir(), slot]


# ---------------------------------------------------------------- kaydedilebilir mi
static func why_not(main) -> String:
	## bos metin: kaydedilebilir; degilse sebep
	if main.game_over:
		return "Bölüm bitti"
	if main.mission == null:
		return "Bölüm yüklenmedi"
	for g in main.get_tree().get_nodes_in_group("guards"):
		if g.alive and (g.state == &"combat" or g.state == &"alarm_run" or g.state == &"pursue"):
			if g.state == &"pursue":
				return "Peşinde asker var: kaydedilemez"
			return "Çatışmada kaydedilemez" if g.state == &"combat" else "Sirene koşan var: kaydedilemez"
	if not main.climb.is_empty():
		return "Pencereden tırmanırken kaydedilemez"
	if main._pending.size() > 0:
		return "Takviye yolda: kaydedilemez"
	if main.mission.bombs.size() > 0:
		return "Patlayıcı kuruluyken kaydedilemez"
	return ""


# ---------------------------------------------------------------- yakala
static func _guard_state(g) -> Dictionary:
	var st := "patrol"
	if g.alive and g.state != &"patrol":
		st = "investigate"
	return {
		"pos": g.global_position, "alive": g.alive, "hp": g.hp, "wp_i": g.wp_i, "facing": g.facing,
		"base_facing": g.base_facing, "state": st, "inv": g.investigate_pos, "knocked": g.knocked, "tied": g.tied,
		"wake_t": g._wake_t, "discovered": g.discovered, "hidden_body": g.hidden_body,
		"vigilant_t": g.vigilant_t, "kind": g.kind, "drops": g.drops, "waypoints": g.waypoints,
	}


static func capture(main) -> Dictionary:
	var c = main.commando
	var m = main.mission
	var lv = main.level
	var level_guards := []
	var extra := []
	var carried_i := -1
	var all: Array = main.get_tree().get_nodes_in_group("guards")
	for g in all:
		var d := _guard_state(g)
		if g == c.carrying:
			d["carried"] = true
		if g.has_meta("gi"):
			var gi: int = g.get_meta("gi")
			while level_guards.size() <= gi:
				level_guards.append(null)
			level_guards[gi] = d
		else:
			extra.append(d)
	var npcs := {}
	for id in m.npcs:
		var n = m.npcs[id]
		npcs[id] = {"pos": n.global_position, "following": n.following, "alive": n.alive, "hp": n.hp, "facing": n.facing}
	var done := []
	for o in m.objectives:
		if o["done"]:
			done.append(o["id"])
	var cut := []
	for i in lv.wires.size():
		if lv.wires[i]["cut"]:
			cut.append(i)
	var pickups := []
	for pk in lv.pickups:
		pickups.append(pk.duplicate())
	var bk := []
	for b in main.barracks:
		bk.append(b[1])
	return {
		"main": {"alert": main.alert_level, "alarm_t": main.alarm_t, "barracks": bk, "reinforced": main._reinforced,
			"stats": main.stats.duplicate(true), "cam": main.cam.position, "zoom": main.cam.zoom.x,
			"interior": main.cur_interior, "guards_n": main.level.data.get("guards", []).size()},
		"komando": {"pos": c.global_position, "hp": c.hp, "ammo": c.ammo, "medkits": c.medkits, "stones": c.stones,
			"ropes": c.ropes, "weapon": c.weapon, "crouch": c.crouch, "facing": c.facing},
		"askerler": level_guards,
		"takviye": extra,
		"npc": npcs,
		"gorev": {"done": done, "items": m.items.duplicate(true), "elapsed": m.elapsed},
		"harita": {"pickups": pickups, "document_taken": lv.document_taken, "scorches": lv.scorches.duplicate(true),
			"wires_cut": cut},
	}


# ---------------------------------------------------------------- dosya
static func save(main, slot: String) -> String:
	## bos metin: basarili; degilse hata
	var why := why_not(main)
	if why != "":
		return why
	DirAccess.make_dir_recursive_absolute(_dir())
	var done := 0
	var total := 0
	for o in main.mission.objectives:
		if o.get("optional", false):
			continue
		total += 1
		if o["done"]:
			done += 1
	var head := {
		"surum": VERSION, "bolum": main.level_path, "ad": main.level.data.get("name", main.level_path.get_file()),
		"tarih": Time.get_datetime_string_from_system(false, true), "unix": Time.get_unix_time_from_system(),
		"sure": main.mission.elapsed, "gorev": "%d/%d" % [done, total], "durum": var_to_str(capture(main)),
	}
	var tmp := slot_path(slot) + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return "Kayıt yazılamadı"
	f.store_string(JSON.stringify(head))
	f.close()
	# yarim yazilmis dosya eski kaydi bozmasin: once gecici dosya, sonra yer degistir
	DirAccess.rename_absolute(tmp, slot_path(slot))
	return ""


static func info(slot: String) -> Dictionary:
	## yuva ust bilgisi (durum metni haric); yoksa ya da bozuksa {}
	var p := slot_path(slot)
	if not FileAccess.file_exists(p):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(p))
	if typeof(d) != TYPE_DICTIONARY or not d.has("bolum"):
		return {"bozuk": true}
	d.erase("durum")
	d["slot"] = slot
	return d


static func latest(level_path := "") -> String:
	## en yeni kayit yuvasi (istersen yalniz bu bolum)
	var best := ""
	var bt := -1.0
	for s in SLOTS:
		var d := info(s)
		if d.is_empty() or d.get("bozuk", false):
			continue
		if level_path != "" and d["bolum"] != level_path:
			continue
		if float(d.get("unix", 0)) > bt:
			bt = float(d.get("unix", 0))
			best = s
	return best


static func read(slot: String) -> Dictionary:
	## {"bolum", "durum"} ya da {"hata": "..."}
	var p := slot_path(slot)
	if not FileAccess.file_exists(p):
		return {"hata": "Bu yuvada kayıt yok"}
	var d = JSON.parse_string(FileAccess.get_file_as_string(p))
	if typeof(d) != TYPE_DICTIONARY or not d.has("durum") or not d.has("bolum"):
		return {"hata": "Kayıt dosyası bozuk"}
	var v := int(d.get("surum", 0))
	if v > VERSION:
		return {"hata": "Bu kayıt oyunun daha yeni bir sürümünden"}
	var txt: String = d["durum"]
	# guvenlik: kayit metni nesne/kaynak olusturamasin (yalniz duz veri)
	if "Object(" in txt or "Resource(" in txt or "SubResource(" in txt or "ExtResource(" in txt:
		return {"hata": "Kayıt dosyası geçersiz"}
	var st = str_to_var(txt)
	if typeof(st) != TYPE_DICTIONARY:
		return {"hata": "Kayıt dosyası bozuk"}
	d["durum"] = _migrate(st, v)
	if not ResourceLoader.exists(d["bolum"]) and not FileAccess.file_exists(d["bolum"]):
		return {"hata": "Kayıttaki bölüm bulunamadı"}
	return d


static func _migrate(st: Dictionary, from_v: int) -> Dictionary:
	## eski bicimleri yukselt (her adim bir surum). Surum 0 = Tur 4 oncesi deneme bicimi (yok); yine de guvenli.
	if from_v < 1:
		for k in ["main", "komando", "gorev", "harita", "npc"]:
			if not st.has(k):
				st[k] = {}
		for k in ["askerler", "takviye"]:
			if not st.has(k):
				st[k] = []
	return st


# ---------------------------------------------------------------- uygula
static func apply(main, st: Dictionary) -> String:
	## main._ready sonunda cagrilir (askerler, komando, gorevler kurulduktan sonra). Uyari metni doner.
	var warn := ""
	var c = main.commando
	var m = main.mission
	var lv = main.level
	var ms: Dictionary = st.get("main", {})
	var gn := int(ms.get("guards_n", -1))
	if gn != -1 and gn != lv.data.get("guards", []).size():
		warn = "Bölüm kayıttan sonra güncellendi: bazı askerler yeni yerlerinde olabilir"
	# --- harita ---
	var hs: Dictionary = st.get("harita", {})
	var cut_any := false
	for i in hs.get("wires_cut", []):
		if i >= 0 and i < lv.wires.size():
			lv.cut_wire(i, false)
			cut_any = true
	if cut_any:
		lv._build_navigation(false)    # tum teller icin tek navigasyon yeniden hesabi
		lv.changed_map.emit()
	if hs.has("pickups"):
		lv.pickups = hs["pickups"]
	lv.document_taken = hs.get("document_taken", false)
	lv.scorches = hs.get("scorches", [])
	# --- gorevler ---
	var gs: Dictionary = st.get("gorev", {})
	var done: Array = gs.get("done", [])
	for o in m.objectives:
		o["done"] = o["id"] in done
		if o["done"] and o.has("bridge"):
			lv.destroy_bridge(int(o["bridge"]))
	m.items = gs.get("items", {})
	m.elapsed = float(gs.get("elapsed", 0.0))
	# --- askerler ---
	var by_gi := {}
	for g in main.get_tree().get_nodes_in_group("guards"):
		if g.has_meta("gi"):
			by_gi[int(g.get_meta("gi"))] = g
	var saved: Array = st.get("askerler", [])
	var carried = null
	for gi in by_gi:
		if gi < saved.size() and saved[gi] != null:
			if _apply_guard(main, by_gi[gi], saved[gi]):
				carried = by_gi[gi]
	for d in st.get("takviye", []):
		var g = Guard.new()
		g.main = main
		g.kind = d.get("kind", "er")
		g.reinforcement = true
		g.waypoints = d.get("waypoints", [])
		g.position = d.get("pos", Vector2.ZERO)
		g.investigate_pos = d.get("inv", g.position)
		g.state = &"investigate" if d.get("state", "patrol") != "patrol" else &"patrol"
		main.world.add_child(g)
		if _apply_guard(main, g, d):
			carried = g
	# operatoru olen projektorler kapali baslar (yuklemede "sondu" bildirimi cikmasin)
	for sl in lv.searchlights:
		var op = sl.get("op")
		if op != null and is_instance_valid(op) and not op.alive:
			sl["on"] = false
	# --- komando ---
	var cs: Dictionary = st.get("komando", {})
	c.global_position = cs.get("pos", c.global_position)
	c.hp = float(cs.get("hp", c.hp))
	c.ammo = int(cs.get("ammo", c.ammo))
	c.medkits = int(cs.get("medkits", c.medkits))
	c.stones = int(cs.get("stones", c.stones))
	c.ropes = int(cs.get("ropes", c.ropes))
	c.weapon = cs.get("weapon", c.weapon)
	c.crouch = cs.get("crouch", false)
	c.facing = float(cs.get("facing", c.facing))
	# Tur 5: kilik sistemi kaldirildi; eski kayitlardaki "disguise" alani sessizce yok sayilir
	c.move_to(c.global_position)
	if carried != null:
		c.pick_body(carried)
		c._carry_follow()
	# --- yardimci karakterler ---
	var ns: Dictionary = st.get("npc", {})
	for id in ns:
		var n = m.npcs.get(id)
		if n == null:
			continue
		var d: Dictionary = ns[id]
		n.global_position = d.get("pos", n.global_position)
		n.facing = float(d.get("facing", n.facing))
		n.hp = float(d.get("hp", n.hp))
		n.alive = d.get("alive", true)
		if d.get("following", false) and not n.following:
			n.start_following()
		if n.navigation_agent != null:
			n.navigation_agent.target_position = n.global_position
	# --- genel durum ---
	var bk: Array = ms.get("barracks", [])
	for i in mini(bk.size(), main.barracks.size()):
		main.barracks[i][1] = int(bk[i])
	if ms.has("stats"):
		main.stats = ms["stats"]
	main.set_alert_level(int(ms.get("alert", 0)))
	main.alarm_t = float(ms.get("alarm_t", 0.0))
	main._reinforced = ms.get("reinforced", false)
	main.cur_interior = int(ms.get("interior", -1))
	if main.cur_interior >= lv.interiors.size():
		main.cur_interior = -1
	if main.cur_interior >= 0:
		main.hud.set_place("Bina içi: " + lv.interiors[main.cur_interior]["name"])
	main.cam.position = ms.get("cam", c.global_position)
	var z := float(ms.get("zoom", main.cam.zoom.x))
	main.cam.zoom = Vector2(z, z)
	main._clamp_cam()
	main.hud.crouch_btn.set_pressed_no_signal(c.crouch)
	main.hud.refresh_objectives()
	main.hud.refresh_items()
	lv.queue_redraw()
	return warn


static func _apply_guard(main, g, d: Dictionary) -> bool:
	## asker durumunu uygula; komando bu cesedi tasiyorsa true
	g.global_position = d.get("pos", g.global_position)
	g.facing = float(d.get("facing", g.facing))
	g.base_facing = float(d.get("base_facing", g.base_facing))
	g.wp_i = clampi(int(d.get("wp_i", 0)), 0, maxi(g.waypoints.size() - 1, 0))
	# eski "stripped" alani (kilik, Tur 5'te kaldirildi) yok sayilir
	g.vigilant_t = float(d.get("vigilant_t", 0.0))
	if d.get("alive", true):
		g.hp = float(d.get("hp", g.hp))
		if d.get("state", "patrol") != "patrol":
			g._set_investigate(d.get("inv", g.global_position))
			g.suspicion = 0.5
		return false
	# olu ya da baygin: kill() ile ayni gorunum, ama anahtar tekrar dusmesin (yerdeki esyalar kayittan gelir)
	var drops: String = g.drops
	g.drops = ""
	g.state = &"patrol"
	g.kill()
	g.drops = drops
	g.knocked = d.get("knocked", false)
	g.tied = d.get("tied", false)
	g._wake_t = float(d.get("wake_t", 0.0))
	g.discovered = d.get("discovered", false)
	g.hidden_body = d.get("hidden_body", false)
	if g.sprite != null and g.sprite.sprite_frames != null:
		g.sprite.frame = maxi(g.sprite.sprite_frames.get_frame_count(g.sprite.animation) - 1, 0)
	return d.get("carried", false)
