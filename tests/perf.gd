extends SceneTree
## Performans olcumu: LVL=res://levels/bolum1.json CX=2400 CY=1250 godot --headless -s res://tests/perf.gd
## Kare suresi (duvar saati) + oyun mantigi (process + physics) suresi. ALARM=1: kirmizi alarm durumu.
var main; var f := 0; var t0 := 0
var proc := 0.0
var phys := 0.0
var n := 0


func _initialize():
	load("res://scripts/main.gd").level_choice = OS.get_environment("LVL")
	load("res://scripts/main.gd").briefed = load("res://scripts/main.gd").level_choice
	main = load("res://scenes/main.tscn").instantiate(); root.add_child(main)


func _process(_d):
	f += 1
	if f == 5:
		main.cam.position = Vector2(OS.get_environment("CX").to_float(), OS.get_environment("CY").to_float()); main.cam.zoom = Vector2(0.8, 0.8)
		main.commando.global_position = main.cam.position
		if OS.get_environment("ALARM") == "1":
			main.raise_alarm(main.cam.position, null)
	if f == 30: t0 = Time.get_ticks_usec()
	if f > 30:
		proc += Performance.get_monitor(Performance.TIME_PROCESS)
		phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
		n += 1
	if f == 630:
		print("ortalama kare: ", (Time.get_ticks_usec() - t0) / 600000.0, " ms")
		print("oyun mantigi: process %.3f ms + physics %.3f ms (asker %d)" % [proc / n * 1000.0, phys / n * 1000.0,
			main.get_tree().get_nodes_in_group("guards").size()])
		var G = load("res://scripts/guard.gd")
		if "PT" in G:
			for k in G.PT:
				print("  ", k, ": %.3f ms/kare" % (G.PT[k] / 600.0 / 1000.0))
		quit()
	return false
