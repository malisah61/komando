extends Node
## Gorev sistemi: bolum dosyasindaki "objectives" listesini yurutur.
##
## Gorev turleri:
##   reach    - bir yere ulas (istersen konusma "say" ve esya "gives")
##   take     - bir esyayi al (planlar)
##   rescue   - esiri kurtar, seni izlemeye baslar ("npc")
##   destroy  - patlayici kur ve havaya uçur ("bridge": kopru indeksi istege bagli)
##   have     - bir esyayi edin ("item": askerden dusen anahtar gibi)
##   sabotage - sessiz sabotaj: noktada "time" sn hareketsiz kal (kablo kes); "disables_barracks": kisla indeksi
##   exit     - cikisa don (kurtarilanlar yaninda olmali)
## "optional": true olanlar bitis icin zorunlu degil.

const Explosion = preload("res://scripts/explosion.gd")

const PLANT_TIME := 2.0
const FUSE_TIME := 8.0
const BLAST_R := 110.0

var main
var objectives: Array = []
var items := {}                   # esya adi -> adet
var bombs: Array = []             # [konum, kalan sure, gorev]
var planting := -1.0              # kurulum suresi (>=0 iken kuruluyor)
var plant_target = null
var elapsed := 0.0
var npcs := {}                    # id -> npc dugumu


func setup(level_data: Dictionary) -> void:
	var src: Array = level_data.get("objectives", [])
	if src.is_empty():
		src = [
			{"id": "belge", "type": "take", "text": "Gizli BELGEYİ çal", "pos": level_data["document"]},
			{"id": "kacis", "type": "exit", "text": "ÇIKIŞ bölgesine dön"},
		]
	for o in src:
		var d: Dictionary = o.duplicate(true)
		d["done"] = false
		# "after": "anahtar" (tek metin) de kabul edilir; eskiden harf harf dolasilip kosul hic islemiyordu
		if d.get("after") is String:
			d["after"] = [d["after"]]
		objectives.append(d)


func available(o: Dictionary) -> bool:
	## "after": [id...] - once bu gorevler bitmeli (or. kodlari teslim etmek icin once radar)
	for id in o.get("after", []):
		for p in objectives:
			if p["id"] == id and not p["done"]:
				return false
	return true


func required_left() -> int:
	var n := 0
	for o in objectives:
		if not o["done"] and not o.get("optional", false) and o["type"] != "exit":
			n += 1
	return n


func _v(a) -> Vector2:
	return Vector2(a[0], a[1])


func _complete(o: Dictionary) -> void:
	o["done"] = true
	main.hud.refresh_objectives()
	main.objective_done(o)
	if o.has("done_say"):
		main.hud.show_dialog(o["done_say"])


func _process(delta: float) -> void:
	if main.game_over:
		return
	elapsed += delta
	var c = main.commando
	var cp: Vector2 = c.global_position
	# yerdeki esyalar: saglik cantasi, mermi
	for pk in main.level.pickups:
		if not pk["taken"] and cp.distance_to(pk["pos"]) < 26.0:
			pk["taken"] = true
			if pk["type"] == "key" or pk["type"] == "item":
				var it: String = pk.get("item", "anahtar")
				items[it] = items.get(it, 0) + int(pk.get("count", 1))
				main.hud.refresh_items()
				main.hud.toast(main.hud.ITEM_NAMES.get(it, it.to_upper()) + " alındı")
			elif pk["type"] == "stones":
				var n := int(pk.get("count", 2))
				c.stones += n
				main.hud.refresh_items()
				main.hud.toast("Taş toplandı (+%d)" % n)
			elif pk["type"] == "medkit":
				c.medkits += 1
				main.hud.toast("Sağlık çantası alındı")
			else:
				c.ammo += 8
				main.hud.toast("Mermi alındı (+8)")
			main.level.queue_redraw()
	var action_text := ""
	plant_target = null
	for o in objectives:
		if o["done"] or not available(o):
			continue
		match o["type"]:
			"reach":
				if cp.distance_to(_v(o["pos"])) < float(o.get("radius", 60)):
					if o.has("gives"):
						var g: Dictionary = o["gives"]
						for k in g:
							items[k] = items.get(k, 0) + int(g[k])
						main.hud.refresh_items()
					_complete(o)
					if o.has("say"):
						main.hud.show_dialog(o["say"])
			"take":
				if cp.distance_to(_v(o["pos"])) < 28.0:
					items[o.get("item", "belge")] = 1
					if _v(o["pos"]).distance_to(main.level.document_pos) < 2.0:
						main.level.document_taken = true
					main.level.queue_redraw()
					main.hud.refresh_items()
					_complete(o)
			"have":
				# bir esyaya sahip ol (anahtar: askerden dusen ya da yerde)
				if items.get(o["item"], 0) > 0:
					_complete(o)
			"rescue":
				var n = npcs.get(o["npc"])
				if n != null and cp.distance_to(n.global_position) < 40.0:
					n.start_following()
					_complete(o)
					if o.has("say"):
						main.hud.show_dialog(o["say"])
			"sabotage":
				if cp.distance_to(_v(o["pos"])) < float(o.get("radius", 60)) and c.carrying == null:
					plant_target = o
			"destroy":
				var tp := _v(o["pos"])
				var planted := false
				for b in bombs:
					if b[2] == o:
						planted = true
				if not planted and cp.distance_to(tp) < float(o.get("radius", 80)):
					if items.get("patlayici", 0) > 0 and c.carrying == null:
						plant_target = o
			"exit":
				if required_left() == 0 and main.level.exit_rect.has_point(cp):
					var ok := true
					for id in npcs:
						var n = npcs[id]
						if n.following and n.global_position.distance_to(cp) > 160.0:
							ok = false
					if ok:
						_complete(o)
						main.win()

	# patlayici kurulumu: komando dururken PLANT_TIME saniye
	if planting >= 0.0:
		if plant_target == null or c.velocity.length() > 1.0:
			planting = -1.0
		else:
			planting += delta
			if plant_target["type"] == "sabotage":
				if planting >= float(plant_target.get("time", 4.0)):
					planting = -1.0
					_sabotage(plant_target)
			elif planting >= PLANT_TIME:
				planting = -1.0
				items["patlayici"] = items["patlayici"] - 1
				main.hud.refresh_items()
				bombs.append([_v(plant_target["pos"]), FUSE_TIME, plant_target])

	# geri sayim
	var i := bombs.size() - 1
	var status := ""
	while i >= 0:
		bombs[i][1] -= delta
		status = "Patlama: %d" % ceili(bombs[i][1])
		if bombs[i][1] <= 0.0:
			_explode(bombs[i])
			bombs.remove_at(i)
		i -= 1
	main.hud.set_timer_text(status)


func plant_time() -> float:
	if plant_target != null and plant_target["type"] == "sabotage":
		return float(plant_target.get("time", 4.0))
	return PLANT_TIME


func _sabotage(o: Dictionary) -> void:
	## sessiz sabotaj: alarm yok. Telsiz kesilirse o kisla kirmizi alarmda takviye gonderemez.
	if o.has("disables_barracks"):
		var bi: int = int(o["disables_barracks"])
		if bi >= 0 and bi < main.barracks.size():
			main.barracks[bi][1] = 0
	main.hud.toast("Sabotaj tamam: " + o["text"])
	_complete(o)


func start_planting() -> void:
	if plant_target != null:
		planting = 0.0
		main.commando.move_to(main.commando.global_position)


func _explode(b: Array) -> void:
	var pos: Vector2 = b[0]
	var o: Dictionary = b[2]
	var fx = Explosion.new()
	fx.position = pos
	main.world.add_child(fx)
	main.level.add_scorch(pos, BLAST_R * 0.8)
	if o.has("bridge"):
		main.level.destroy_bridge(int(o["bridge"]))
	_complete(o)
	# patlama alanindaki herkes
	for g in get_tree().get_nodes_in_group("guards"):
		if g.alive and g.global_position.distance_to(pos) < BLAST_R:
			g.kill()
	for u in get_tree().get_nodes_in_group("player"):
		if u.alive and u.global_position.distance_to(pos) < BLAST_R:
			u.alive = false
			main.lose("Patlamada öldün!")
	# patlama sesi: yakindaki askerler kosar, kirmizi alarm -> takviye
	main.make_noise(pos, 800.0, null)
	main.raise_alarm(pos, null)
