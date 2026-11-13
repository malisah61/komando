extends SceneTree
## Performans olcumu:
##   LVL=res://levels/bolum3.json CX=2700 CY=1900 xvfb-run godot -s res://tests/perf.gd   (doku bellegi icin xvfb + opengl3)
##   (headless da calisir; o zaman doku bellegi 0 gorunur)
##   KIP=mobil | pc : aci bellegi kipini zorla (Tur 5; varsayilan: bu makinenin kipi = pc)
## Olcer: bolum acilisi (sahne kurulumu), ortalama ve EN YAVAS kare, oyun mantigi (process + physics),
## aci degisimi (istek -> hazir suresi ve o arada en yavas kare), kamera kaydirmada zemin akisi,
## doku bellegi (RENDER_TEXTURE_MEM_USED) ve yuklu zemin karosu sayisi. ALARM=1: kirmizi alarm durumu.
var main; var f := 0; var t0 := 0
var proc := 0.0
var phys := 0.0
var n := 0
var last := 0
var worst := 0.0
var load_ms := 0.0
var rot_t := 0
var rot_worst := 0.0
var rot_ms := -1.0
var pan_worst := 0.0
var mem_start := 0.0
var mem_max := 0.0
var cx := 0.0
var load_t := 0
var load_worst := 0.0
var cy := 0.0


const PRESS := {331: 1, 345: 1, 352: -1, 353: -1, 370: 1, 371: 1, 390: -1, 391: -1, 392: -1, 410: 1}
var press_worst := 0.0            # basistan sonraki karenin en yavasi
var press_n := 0
var press_ready := 0              # basildiginda hedef aci zaten bellekteydi
var _pressed_last := false


func _initialize():
	var kip := OS.get_environment("KIP")
	if kip != "":
		load("res://scripts/level.gd").mode_override = kip
	load("res://scripts/main.gd").level_choice = OS.get_environment("LVL")
	load("res://scripts/main.gd").briefed = load("res://scripts/main.gd").level_choice
	load_ms = Time.get_ticks_usec()
	main = load("res://scenes/main.tscn").instantiate(); root.add_child(main)
	cx = OS.get_environment("CX").to_float()
	cy = OS.get_environment("CY").to_float()


func _mem() -> float:
	return Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0


func _process(_d):
	f += 1
	var now := Time.get_ticks_usec()
	var dt := (now - last) / 1000.0 if last > 0 else 0.0
	last = now
	mem_max = maxf(mem_max, _mem())
	if f == 1:
		load_ms = (now - load_ms) / 1000.0     # sahne kurulumu + ilk kare
	if f == 5:
		main.cam.position = Vector2(cx, cy); main.cam.zoom = Vector2(0.8, 0.8)
		main.commando.global_position = main.cam.position
		if OS.get_environment("ALARM") == "1":
			main.raise_alarm(main.cam.position, null)
	if f == 30:
		t0 = now
		mem_start = _mem()
	if f > 30 and f <= 330:
		worst = maxf(worst, dt)
		proc += Performance.get_monitor(Performance.TIME_PROCESS)
		phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
		n += 1
	if f == 330:
		print("ortalama kare: %.2f ms, en yavas kare: %.1f ms" % [(now - t0) / 300000.0, worst])
	# aci degisimi (Tur 5): art arda, ters yonde ve ayni karede iki kez basis; her basis tek karede gecmeli
	if _pressed_last:
		press_worst = maxf(press_worst, dt)
		_pressed_last = false
	if f >= 331 and f < 430:
		rot_worst = maxf(rot_worst, dt)
		if OS.get_environment("VDEBUG") != "" and dt > 45.0:
			print("  yavas kare f=%d %.1f ms" % [f, dt])
	if PRESS.has(f):
		var want: int = posmod(main.level.view + PRESS[f], 4)
		if main.level.views_resident().has(want):
			press_ready += 1
		var v0: int = main.level.view
		var _tr := Time.get_ticks_usec()
		main.rotate_view(PRESS[f])
		if OS.get_environment("VDEBUG") != "":
			print("  basis f=%d -> aci %d, rotate_view %.1f ms" % [f, main.level.view, (Time.get_ticks_usec() - _tr) / 1000.0])
		press_n += 1
		_pressed_last = true
		if main.level.view == v0 or main.level.view_loading >= 0:
			rot_ms = 9999.0      # gecmedi / bekliyor: hata
		elif rot_ms < 0.0:
			rot_ms = 0.0
	if f == 300 or f == 429:
		print("  bellekteki acilar (f=%d): %s" % [f, str(main.level.views_resident())])
	# kamera kaydirma: zemin karolari akisla gelir/gider
	if f > 430 and f <= 640:
		var u := float(f - 430) / 210.0
		main.cam.position = Vector2(lerpf(cx * 0.3, cx * 1.6, u), lerpf(cy * 0.4, cy * 1.5, u))
		main._clamp_cam()
		pan_worst = maxf(pan_worst, dt)
	if f == 660:
		print("bolum acilisi (sahne kurulumu): %.0f ms" % load_ms)
		print("oyun mantigi: process %.3f ms + physics %.3f ms (asker %d)" % [proc / n * 1000.0, phys / n * 1000.0,
			main.get_tree().get_nodes_in_group("guards").size()])
		print("aci degisimi (kip %s): %d basis, %d'inde hedef aci bellekteydi; gecis %s; basistan sonraki en yavas kare %.1f ms; cevirme suresince en yavas kare %.1f ms" % [
			"pc" if main.level.pc_mode() else "mobil", press_n, press_ready, "AYNI KAREDE" if rot_ms == 0.0 else "BEKLEDI (hata)",
			press_worst, rot_worst])
		print("kamera kaydirma (zemin akisi): en yavas kare %.1f ms, yuklu karo %d / %d" % [pan_worst,
			main.level.loaded_ground_tiles(), main.level.ground_tiles.size()])
		print("doku bellegi: baslangic %.1f MB, en yuksek %.1f MB, simdi %.1f MB" % [mem_start, mem_max, _mem()])
		# kayit (Tur 4): kaydetme suresi + yukleme (sahne yeniden kurulumu + uygulama) ve sonrasi en yavas kare
		var K = load("res://scripts/kayit.gd")
		K.dir_override = "user://perf_kayit"
		DirAccess.make_dir_recursive_absolute(K.dir_override)
		main.game_over = false    # olcum: komando vurulduysa da kaydedebilsin
		for g in main.get_tree().get_nodes_in_group("guards"):
			if g.state == &"combat" or g.state == &"alarm_run":
				g.state = &"search"
		main._pending.clear()
		var ts := Time.get_ticks_usec()
		var err: String = K.save(main, "1")
		print("kayit: kaydetme %.1f ms %s, dosya %.0f KB" % [(Time.get_ticks_usec() - ts) / 1000.0, err,
			FileAccess.get_file_as_bytes(K.slot_path("1")).size() / 1024.0])
		var M = load("res://scripts/main.gd")
		ts = Time.get_ticks_usec()
		M.prepare_load("1")
		root.remove_child(main)
		main.queue_free()
		main = load("res://scenes/main.tscn").instantiate(); root.add_child(main)
		load_t = ts
		f = 10000
		return false
	if f > 10000 and f <= 10060:
		if f == 10001:
			print("kayit yukleme (sahne kurulumu + uygulama + ilk kare): %.0f ms" % ((now - load_t) / 1000.0))
		else:
			load_worst = maxf(load_worst, dt)
	if f == 10060:
		print("kayit yukleme sonrasi 60 karede en yavas kare: %.1f ms" % load_worst)
		var G = load("res://scripts/guard.gd")
		if "PT" in G:
			for k in G.PT:
				print("  ", k, ": %.3f ms/kare" % (G.PT[k] / 600.0 / 1000.0))
		quit()
	return false
