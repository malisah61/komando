extends SceneTree
## Performans olcumu:
##   LVL=res://levels/bolum3.json CX=2700 CY=1900 xvfb-run godot -s res://tests/perf.gd   (doku bellegi icin xvfb + opengl3)
##   (headless da calisir; o zaman doku bellegi 0 gorunur)
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
var cy := 0.0


func _initialize():
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
	# aci degisimi
	if f == 331:
		rot_t = now
		main.rotate_view(1)
	if f > 331 and rot_ms < 0.0:
		rot_worst = maxf(rot_worst, dt)
		if main.level.view == 1 and main.level.view_loading < 0:
			rot_ms = (now - rot_t) / 1000.0
	# kamera kaydirma: zemin karolari akisla gelir/gider
	if f > 400 and f <= 640:
		var u := float(f - 400) / 240.0
		main.cam.position = Vector2(lerpf(cx * 0.3, cx * 1.6, u), lerpf(cy * 0.4, cy * 1.5, u))
		main._clamp_cam()
		pan_worst = maxf(pan_worst, dt)
	if f == 660:
		print("bolum acilisi (sahne kurulumu): %.0f ms" % load_ms)
		print("oyun mantigi: process %.3f ms + physics %.3f ms (asker %d)" % [proc / n * 1000.0, phys / n * 1000.0,
			main.get_tree().get_nodes_in_group("guards").size()])
		print("aci degisimi: %.0f ms (istek -> hazir), o arada en yavas kare %.1f ms" % [rot_ms, rot_worst])
		print("kamera kaydirma (zemin akisi): en yavas kare %.1f ms, yuklu karo %d / %d" % [pan_worst,
			main.level.loaded_ground_tiles(), main.level.ground_tiles.size()])
		print("doku bellegi: baslangic %.1f MB, en yuksek %.1f MB, simdi %.1f MB" % [mem_start, mem_max, _mem()])
		var G = load("res://scripts/guard.gd")
		if "PT" in G:
			for k in G.PT:
				print("  ", k, ": %.3f ms/kare" % (G.PT[k] / 600.0 / 1000.0))
		quit()
	return false
