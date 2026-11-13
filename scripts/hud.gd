extends CanvasLayer
## Commandos tarzi taktik HUD.
## Sol ust: mini harita · Ust orta: gorev · Sol alt: komando portresi
## Sag alt: envanter + ozel yetenek butonlari · Orta: sonuc mesaji
## Tum parcalar capa (anchor) ile kenarlara yapisir: telefon ve PC'de ayni duzen.

const Minimap = preload("res://scripts/minimap.gd")
const Kayit = preload("res://scripts/kayit.gd")
const Yenilikler = preload("res://scripts/yenilikler.gd")

const BTN := 76          # dokunmatik icin en az ~10 mm
const PANEL_BG := Color(0.1, 0.11, 0.08, 0.82)
const ACCENT := Color(0.85, 0.75, 0.45)

var main
var _action_cb: Callable
var _action_cb2: Callable
var action_btn2: Button
var place_label: Label
var peek_rect: ColorRect
var peek_btn: Button
var _bigmap: Control

const KEYHOLE := """
shader_type canvas_item;
void fragment() {
	vec2 px = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 d = (SCREEN_UV - vec2(0.5, 0.48)) * vec2(px.x / px.y, 1.0);
	float circle = length(d - vec2(0.0, -0.06)) - 0.17;
	float slot = max(abs(d.x) - (0.06 + max(d.y, 0.0) * 0.32), max(-d.y - 0.02, d.y - 0.3));
	float inside = min(circle, slot);
	float a = smoothstep(-0.01, 0.01, inside);
	COLOR = vec4(0.02, 0.015, 0.01, a * 0.97);
}
"""
var _toast_t := 0.0
var toast_label: Label
var busy_label: Label             # genel "bekle" yazisi (Tur 5: aci cevirmede artik kullanilmaz)
var hp_bar: ProgressBar
var pistol_btn: Button
var med_btn: Button
var crouch_btn: Button
var stone_btn: Button
var alarm_label: Label
var _edges: Array = []
var _pulse := 0.0
var show_cones := true

var goal_label: Label
var alert_label: Label
var status_label: Label
var msg_label: Label
var restart_btn: Button
var continue_btn: Button          # Tur 4: olunce son kayittan devam
var pick_btn: Button
var _continue_slot := ""
var _saves_panel: Control = null
var knife_btn: Button
var run_btn: Button
var cone_btn: Button
var slots: Array[Label] = []
var obj_box: VBoxContainer
var action_btn: Button
var timer_label: Label
var dialog_panel: PanelContainer
var dialog_name: Label
var dialog_text: Label
var _dialog_lines: Array = []
var _overlay: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS     # diyalog sirasinda oyun duraklar, arayuz calisir
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- alarm kenar parlamasi (kirmizi alarmda nabiz gibi atar) ---
	for i in 4:
		var e := ColorRect.new()
		e.color = Color(1, 0.1, 0.05, 0.0)
		e.mouse_filter = Control.MOUSE_FILTER_IGNORE
		match i:
			0: e.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE); e.offset_bottom = 10
			1: e.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); e.offset_top = -10
			2: e.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE); e.offset_right = 10
			3: e.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE); e.offset_left = -10
		root.add_child(e)
		_edges.append(e)

	# --- sol ust: mini harita ---
	var mm_panel := _panel()
	mm_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	mm_panel.position = Vector2(10, 10)
	root.add_child(mm_panel)
	var mm_box := VBoxContainer.new()
	mm_panel.add_child(mm_box)
	mm_box.add_child(_label("HARİTA", 13, ACCENT))
	var mm = Minimap.new()
	mm.main = main
	var k: float = 230.0 / main.level.size.x
	mm.custom_minimum_size = main.level.size * k
	mm_box.add_child(mm)

	# --- ust orta: gorev ---
	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top.grow_horizontal = Control.GROW_DIRECTION_BOTH
	top.position.y = 10
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	var title := _label(main.level.data.get("name", ""), 14, Color(1, 1, 1, 0.7))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(title)
	goal_label = _label("", 20)
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(goal_label)
	alert_label = _label("", 18, Color(1, 0.5, 0.3))
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label.visible = false
	top.add_child(alert_label)
	alarm_label = _label("", 20, Color(1, 0.3, 0.25))
	alarm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alarm_label.visible = false
	top.add_child(alarm_label)
	toast_label = _label("", 18, Color(1, 1, 0.8))
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.visible = false
	top.add_child(toast_label)
	busy_label = _label("", 26, Color(1, 1, 0.85))
	busy_label.set_anchors_preset(Control.PRESET_CENTER)
	busy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	busy_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	busy_label.add_theme_constant_override("outline_size", 6)
	busy_label.visible = false
	add_child(busy_label)
	timer_label = _label("", 30, Color(1, 0.4, 0.25))
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(timer_label)

	# --- sol: gorev listesi (mini haritanin altinda) ---
	var obj_panel := _panel()
	obj_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	obj_panel.position = Vector2(10, 222)
	obj_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(obj_panel)
	obj_box = VBoxContainer.new()
	obj_box.add_theme_constant_override("separation", 2)
	obj_panel.add_child(obj_box)

	# --- sol alt: portre ---
	var por := _panel()
	por.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	por.grow_vertical = Control.GROW_DIRECTION_BEGIN
	por.position = Vector2(10, -10)
	root.add_child(por)
	var por_row := HBoxContainer.new()
	por.add_child(por_row)
	var face := ColorRect.new()
	face.color = Color(0.25, 0.4, 0.2)
	face.custom_minimum_size = Vector2(58, 58)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var beret := _label("YB", 24, Color(0.85, 1, 0.8))
	beret.set_anchors_preset(Control.PRESET_CENTER)
	beret.grow_horizontal = Control.GROW_DIRECTION_BOTH
	beret.grow_vertical = Control.GROW_DIRECTION_BOTH
	face.add_child(beret)
	por_row.add_child(face)
	var por_txt := VBoxContainer.new()
	por_row.add_child(por_txt)
	por_txt.add_child(_label("Yeşil Bere", 18, ACCENT))
	status_label = _label("Görünür", 15)
	por_txt.add_child(status_label)
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(130, 12)
	hp_bar.show_percentage = false
	hp_bar.max_value = 100
	hp_bar.value = 100
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.35, 0.85, 0.35)
	hp_bar.add_theme_stylebox_override("fill", fill)
	var bgs := StyleBoxFlat.new()
	bgs.bg_color = Color(0.15, 0.05, 0.05)
	hp_bar.add_theme_stylebox_override("background", bgs)
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	por_txt.add_child(hp_bar)

	# --- sag alt: envanter + yetenekler ---
	var br := _panel()
	br.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	br.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	br.grow_vertical = Control.GROW_DIRECTION_BEGIN
	br.position = Vector2(-10, -10)
	root.add_child(br)
	var br_box := VBoxContainer.new()
	br_box.add_theme_constant_override("separation", 6)
	br.add_child(br_box)
	br_box.add_child(_label("ENVANTER", 13, ACCENT))
	var inv := HBoxContainer.new()
	br_box.add_child(inv)
	for i in 4:
		var slot := _label("", 13)
		slot.custom_minimum_size = Vector2(BTN, 40)
		slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0.2, 0.2, 0.17)
		bg.border_color = Color(0.4, 0.38, 0.3)
		bg.set_border_width_all(1)
		slot.add_theme_stylebox_override("normal", bg)
		inv.add_child(slot)
		slots.append(slot)
	slots[0].text = "BIÇAK"
	_build_dialog(root)
	place_label = _label("", 18, Color(0.85, 0.9, 1.0))
	place_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	place_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	place_label.position.y = 150
	place_label.visible = false
	root.add_child(place_label)
	peek_rect = ColorRect.new()
	peek_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	peek_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var psh := Shader.new()
	psh.code = KEYHOLE
	var pm := ShaderMaterial.new()
	pm.shader = psh
	peek_rect.material = pm
	peek_rect.visible = false
	root.add_child(peek_rect)
	peek_btn = _button("Kapıdan Çekil", false)
	peek_btn.custom_minimum_size = Vector2(220, 60)
	peek_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	peek_btn.grow_horizontal = Control.GROW_DIRECTION_BOTH
	peek_btn.offset_left = -120
	peek_btn.offset_right = 120
	peek_btn.offset_top = -96
	peek_btn.offset_bottom = -36
	peek_btn.visible = false
	peek_btn.pressed.connect(func(): main.toggle_peek())
	root.add_child(peek_btn)
	refresh_objectives()
	action_btn = _button("", false)
	action_btn.custom_minimum_size = Vector2(BTN * 4 + 12, 60)
	action_btn.add_theme_font_size_override("font_size", 22)
	action_btn.visible = false
	action_btn.pressed.connect(func():
		if _action_cb.is_valid():
			_action_cb.call())
	var arow := HBoxContainer.new()
	br_box.add_child(arow)
	action_btn.custom_minimum_size = Vector2(BTN * 2 + 4, 60)
	arow.add_child(action_btn)
	action_btn2 = _button("", false)
	action_btn2.custom_minimum_size = Vector2(BTN * 2 + 4, 60)
	action_btn2.add_theme_font_size_override("font_size", 20)
	action_btn2.visible = false
	action_btn2.pressed.connect(func():
		if _action_cb2.is_valid():
			_action_cb2.call())
	arow.add_child(action_btn2)
	br_box.add_child(_label("SİLAH  (seçim kalıcı - askere dokun: saldır)", 13, ACCENT))
	var weap := HBoxContainer.new()
	br_box.add_child(weap)
	var group := ButtonGroup.new()
	knife_btn = _button("Bıçak", true)
	knife_btn.button_group = group
	knife_btn.button_pressed = true
	knife_btn.toggled.connect(func(on):
		if on:
			main.commando.weapon = "knife")
	weap.add_child(knife_btn)
	# Tur 3: yumruk (bayilt, oldurmez) ve islik (yakindaki askerleri cek)
	var fist_btn := _button("Yumruk", true)
	fist_btn.button_group = group
	fist_btn.toggled.connect(func(on):
		if on:
			main.commando.weapon = "fist")
	weap.add_child(fist_btn)
	pistol_btn = _button("Tabanca", true)
	pistol_btn.button_group = group
	pistol_btn.toggled.connect(func(on):
		if on:
			main.commando.weapon = "pistol")
	weap.add_child(pistol_btn)
	med_btn = _button("Sağlık", false)
	med_btn.pressed.connect(func(): main.commando.use_medkit())
	weap.add_child(med_btn)
	var wh_btn := _button("Islık", false)
	wh_btn.pressed.connect(func(): main.commando.do_whistle())
	weap.add_child(wh_btn)
	br_box.add_child(_label("HAREKET", 13, ACCENT))
	var abil := HBoxContainer.new()
	br_box.add_child(abil)
	crouch_btn = _button("Çömel", true)
	crouch_btn.toggled.connect(func(on):
		main.commando.crouch = on
		if on:
			run_btn.button_pressed = false)
	abil.add_child(crouch_btn)
	run_btn = _button("Koş", true)
	run_btn.toggled.connect(func(on):
		main.commando.run = on
		if on:
			crouch_btn.button_pressed = false)
	abil.add_child(run_btn)
	stone_btn = _button("Taş", true)
	stone_btn.toggled.connect(func(on):
		main.throw_mode = on and main.commando.stones > 0
		if on and main.commando.stones > 0:
			toast("Taşı atacağın yere dokun (askerler bakmaya gelir)")
		refresh_items())
	abil.add_child(stone_btn)
	cone_btn = _button("Koni", true)
	cone_btn.button_pressed = true
	cone_btn.toggled.connect(func(on): show_cones = on)
	abil.add_child(cone_btn)
	var center_btn := _button("Odak", false)
	center_btn.pressed.connect(func():
		main.cam.position = main.commando.global_position
		main._clamp_cam())
	abil.add_child(center_btn)

	# --- sag ust: menu ---
	var menu_btn := _button("Menü", false)
	menu_btn.custom_minimum_size = Vector2(84, 52)
	menu_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	menu_btn.offset_left = -94
	menu_btn.offset_right = -10
	menu_btn.offset_top = 10
	menu_btn.offset_bottom = 62
	menu_btn.pressed.connect(func(): show_menu(main.LEVELS))
	root.add_child(menu_btn)
	# kayit (Tur 4): PC'de F5 hizli kaydet, F9 hizli yukle, Esc/K kayit paneli
	var save_btn := _button("Kayıt", false)
	save_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	save_btn.offset_left = -294
	save_btn.offset_right = -204
	save_btn.offset_top = 10
	save_btn.offset_bottom = 62
	save_btn.pressed.connect(func(): show_saves())
	root.add_child(save_btn)
	# 4 yonlu bakis: haritayi 90 derece cevir (PC: Q / E)
	var rot_btn := _button("Çevir", false)
	rot_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	rot_btn.offset_left = -194
	rot_btn.offset_right = -104
	rot_btn.offset_top = 10
	rot_btn.offset_bottom = 62
	rot_btn.pressed.connect(func(): main.rotate_view(1))
	root.add_child(rot_btn)

	# --- orta: sonuc ---
	var mid := VBoxContainer.new()
	mid.set_anchors_preset(Control.PRESET_CENTER)
	mid.grow_horizontal = Control.GROW_DIRECTION_BOTH
	mid.grow_vertical = Control.GROW_DIRECTION_BOTH
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(mid)
	msg_label = _label("", 56)
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.visible = false
	mid.add_child(msg_label)
	restart_btn = Button.new()
	restart_btn.text = "  Yeniden Başla  "
	restart_btn.add_theme_font_size_override("font_size", 30)
	restart_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart_btn.visible = false
	restart_btn.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene())
	mid.add_child(restart_btn)
	continue_btn = Button.new()
	continue_btn.add_theme_font_size_override("font_size", 26)
	continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continue_btn.visible = false
	continue_btn.pressed.connect(func():
		if _continue_slot != "":
			main.load_slot(_continue_slot))
	mid.add_child(continue_btn)
	pick_btn = Button.new()
	pick_btn.text = "  Kayıt seç…  "
	pick_btn.add_theme_font_size_override("font_size", 22)
	pick_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pick_btn.visible = false
	pick_btn.pressed.connect(func(): show_saves(true))
	mid.add_child(pick_btn)


func show_menu(levels: Array) -> void:
	get_tree().paused = true
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.72)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP     # oyuna dokunus gecmesin
	add_child(shade)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 14)
	shade.add_child(box)
	var t := _label("KOMANDO", 54, ACCENT)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var st := _label("Görev seç", 20, Color(1, 1, 1, 0.8))
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(st)
	for lv in levels:
		var best: Dictionary = main.best_of(lv[0])
		var extra := ""
		if not best.is_empty():
			var bt: float = best["time"]
			extra = "   %s %s · %d puan · %d:%02d" % ["★".repeat(best["stars"]) + "☆".repeat(3 - best["stars"]), best["rank"], best["points"], int(bt) / 60, int(bt) % 60]
		var b := _button("%s%s\n%s" % [lv[1], extra, lv[2]], false)
		b.custom_minimum_size = Vector2(520, 84)
		b.add_theme_font_size_override("font_size", 20)
		var path: String = lv[0]
		b.pressed.connect(func(): main.choose_level(path))
		box.add_child(b)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var lb := _button("Kayıtlı oyunu yükle", false)
	lb.custom_minimum_size = Vector2(250, 56)
	lb.pressed.connect(func(): show_saves(true))
	row.add_child(lb)
	var nb := _button("Yenilikler", false)
	nb.custom_minimum_size = Vector2(250, 56)
	nb.pressed.connect(func(): show_news())
	row.add_child(nb)
	if main.level_choice != "":
		var back := _button("Geri dön", false)
		back.custom_minimum_size = Vector2(200, 56)
		back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		back.pressed.connect(func():
			shade.queue_free()
			get_tree().paused = false)
		box.add_child(back)


func _process(delta: float) -> void:
	var c = main.commando
	if c == null:
		return
	if _toast_t > 0.0:
		_toast_t -= delta
		if _toast_t <= 0.0:
			toast_label.visible = false
	hp_bar.value = c.hp * 100.0 / c.max_hp
	_pulse += delta * 4.0
	var ea := (0.25 + 0.2 * sin(_pulse)) if main.alert_level >= 2 else 0.0
	for e in _edges:
		e.color.a = ea
	pistol_btn.text = "Tabanca\n%d" % c.ammo
	med_btn.text = "Sağlık x%d" % c.medkits
	med_btn.disabled = c.medkits <= 0
	if not c.alive:
		status_label.text = "Vuruldu"
		status_label.add_theme_color_override("font_color", Color(1, 0.4, 0.3))
	elif c.is_hidden():
		status_label.text = "Gizli (çalılıkta)"
		status_label.add_theme_color_override("font_color", Color(0.6, 1, 0.6))
	else:
		var watched := false
		for g in get_tree().get_nodes_in_group("guards"):
			if g.alive and g.suspicion > 0.0:
				watched = true
		status_label.text = "Fark ediliyor!" if watched else ("Koşuyor (gürültülü)" if c.run else "Görünür")
		status_label.add_theme_color_override("font_color", Color(1, 0.8, 0.3) if watched or c.run else Color.WHITE)


# ---------------- Disaridan cagrilanlar ----------------
const ITEM_NAMES := {"patlayici": "PATLAYICI", "belge": "BELGE", "planlar": "PLANLAR", "hucre_anahtari": "HÜCRE ANAHT.",
	"kodlar": "KODLAR", "liman_anahtari": "LİMAN ANAHT.", "sevkiyat": "SEVKİYAT", "anahtar": "ANAHTAR", "belediye_anahtari": "BELEDİYE ANAHT.", "tarife": "TARİFE", "tel_makasi": "TEL MAKASI", "liste": "SEVK LİSTESİ", "baraka_anahtari": "BARAKA ANAHT.", "sato_anahtari": "ŞATO ANAHT.", "pusula": "PUSULA", "rota": "ROTA", "sifre": "ŞİFRE"}


func refresh_objectives() -> void:
	for ch in obj_box.get_children():
		ch.queue_free()
	obj_box.add_child(_label("GÖREVLER", 13, ACCENT))
	var current := ""
	# uzun gorev zincirinde liste tasmasin: biten gorevler tek satirda sayilir, en fazla 5 acik gorev
	var ndone := 0
	var shown := 0
	for o in main.mission.objectives:
		if o["done"]:
			ndone += 1
	if ndone > 0 and main.mission.objectives.size() > 5:
		obj_box.add_child(_label("[X] %d görev tamamlandı" % ndone, 13, Color(0.55, 0.85, 0.55)))
	for o in main.mission.objectives:
		var done: bool = o["done"]
		var opt: bool = o.get("optional", false)
		if main.mission.objectives.size() > 5 and (done or shown >= 5):
			if current == "" and not done and not opt:
				current = o["text"]
			continue
		shown += 1
		var txt: String = ("[X] " if done else "[  ] ") + o["text"] + (" (isteğe bağlı)" if opt else "")
		var col := Color(0.55, 0.85, 0.55) if done else (Color(0.8, 0.8, 0.7) if opt else Color.WHITE)
		if not done and not main.mission.available(o):
			col = Color(0.6, 0.6, 0.6)
			txt += " (sonra)"
		var l := _label(txt, 14, col)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 260
		obj_box.add_child(l)
		if current == "" and not done and not opt and main.mission.available(o):
			current = o["text"]
	goal_label.text = ("Hedef: " + current) if current != "" else ""


func refresh_items() -> void:
	if stone_btn != null:
		stone_btn.text = "Taş\n%d" % main.commando.stones
		stone_btn.set_pressed_no_signal(main.throw_mode)
		stone_btn.disabled = main.commando.stones <= 0
	var i := 1
	for k in main.mission.items:
		var n: int = main.mission.items[k]
		if n <= 0 or i >= slots.size():
			continue
		slots[i].text = ITEM_NAMES.get(k, k.to_upper()) + (" x%d" % n if n > 1 else "")
		slots[i].add_theme_color_override("font_color", Color(1, 0.9, 0.3))
		i += 1
	while i < slots.size():
		slots[i].text = ""
		i += 1


func set_action(text: String, enabled: bool, cb := Callable(), text2 := "", cb2 := Callable()) -> void:
	action_btn.visible = text != ""
	action_btn.text = text
	action_btn.disabled = not enabled
	action_btn.custom_minimum_size.x = (BTN * 2 + 4) if text2 != "" else (BTN * 4 + 12)
	_action_cb = cb
	action_btn2.visible = text2 != ""
	action_btn2.text = text2
	_action_cb2 = cb2


func set_place(text: String) -> void:
	place_label.text = text
	place_label.visible = text != ""


func show_peek(on: bool) -> void:
	## anahtar deligi gorunumu: disaridaki askerleri izle
	peek_rect.visible = on
	peek_btn.visible = on


# ---------------- Buyuk harita ----------------
func show_big_map() -> void:
	if _bigmap != null:
		return
	get_tree().paused = true
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.05, 0.04, 0.93)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	_bigmap = shade
	var bm = load("res://scripts/bigmap.gd").new()
	bm.main = main
	bm.hud = self
	bm.set_anchors_preset(Control.PRESET_FULL_RECT)
	bm.offset_left = 20
	bm.offset_top = 50
	bm.offset_right = -20
	bm.offset_bottom = -20
	shade.add_child(bm)
	var title := _label("HARİTA – %s   (bir yere dokun: kamerayı oraya götür)" % main.level.data.get("name", ""), 18, ACCENT)
	title.position = Vector2(24, 12)
	shade.add_child(title)
	var close := _button("Kapat", false)
	close.custom_minimum_size = Vector2(120, 50)
	close.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	close.position = Vector2(-16, 8)
	close.pressed.connect(close_big_map)
	shade.add_child(close)


func close_big_map() -> void:
	if _bigmap != null:
		_bigmap.queue_free()
		_bigmap = null
	get_tree().paused = false


func toast(text: String) -> void:
	toast_label.text = text
	toast_label.visible = true
	_toast_t = 2.5


func show_busy(text: String) -> void:
	busy_label.text = text
	busy_label.visible = text != ""
	if busy_label.visible:
		busy_label.position = get_viewport().get_visible_rect().size * 0.5 - Vector2(120, 20)
		busy_label.size = Vector2(240, 40)


func set_alarm(level: int, text: String) -> void:
	alarm_label.visible = level > 0
	alarm_label.text = text
	alarm_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3) if level == 1 else Color(1, 0.3, 0.25))


func set_timer_text(t: String) -> void:
	timer_label.text = t


func show_dialog(lines: Array) -> void:
	## lines: [["Konusan", "Metin"], ...]  -- oyun duraklar
	_dialog_lines.append_array(lines)
	if not dialog_panel.visible:
		_next_line()


func _next_line() -> void:
	if _dialog_lines.is_empty():
		dialog_panel.visible = false
		get_tree().paused = false
		return
	var ln: Array = _dialog_lines.pop_front()
	dialog_name.text = ln[0]
	dialog_text.text = ln[1]
	dialog_panel.visible = true
	get_tree().paused = true


func _build_dialog(root: Control) -> void:
	dialog_panel = _panel()
	dialog_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dialog_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dialog_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dialog_panel.position.y = -170
	dialog_panel.visible = false
	root.add_child(dialog_panel)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(620, 0)
	dialog_panel.add_child(box)
	dialog_name = _label("", 18, ACCENT)
	box.add_child(dialog_name)
	dialog_text = _label("", 18)
	dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_text.custom_minimum_size = Vector2(600, 0)
	box.add_child(dialog_text)
	var nb := _button("Devam  >", false)
	nb.custom_minimum_size = Vector2(160, 52)
	nb.size_flags_horizontal = Control.SIZE_SHRINK_END
	nb.pressed.connect(_next_line)
	box.add_child(nb)


func show_briefing(data: Dictionary, objectives: Array) -> void:
	get_tree().paused = true
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.05, 0.04, 0.9)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 60
	scroll.offset_right = -60
	scroll.offset_top = 30
	scroll.offset_bottom = -30
	shade.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	scroll.add_child(box)
	box.add_child(_label("GÖREV BRİFİNGİ", 16, ACCENT))
	box.add_child(_label(data.get("name", ""), 34))
	var story := _label(data.get("story", data.get("brief", "")), 18, Color(0.92, 0.9, 0.82))
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(story)
	box.add_child(_label("Görevler:", 18, ACCENT))
	for o in objectives:
		var l := _label("•  " + o["text"] + ("  (isteğe bağlı)" if o.get("optional", false) else ""), 17)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(l)
	var go := _button("Göreve Başla", false)
	go.custom_minimum_size = Vector2(260, 64)
	go.add_theme_font_size_override("font_size", 24)
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.pressed.connect(func():
		shade.queue_free()
		get_tree().paused = false)
	box.add_child(go)


func set_alert(text: String) -> void:
	alert_label.text = text
	alert_label.visible = true


func show_end(text: String, col: Color) -> void:
	msg_label.text = text
	msg_label.add_theme_font_size_override("font_size", 56 if text.count("\n") < 2 else 34)
	msg_label.add_theme_color_override("font_color", col)
	msg_label.visible = true
	restart_btn.visible = true
	# kaybettiysen: son kayittan devam (once bu bolumun kaydi)
	_continue_slot = ""
	if not main.commando.alive or col.r > col.g:
		_continue_slot = Kayit.latest(main.level_path)
	if _continue_slot != "":
		var inf: Dictionary = Kayit.info(_continue_slot)
		var t: float = float(inf.get("sure", 0))
		continue_btn.text = "  Son kayıttan devam: %s (%d:%02d)  " % [Kayit.SLOT_NAMES.get(_continue_slot, _continue_slot), int(t) / 60, int(t) % 60]
		continue_btn.visible = true
		pick_btn.visible = true
		# sira: once "devam", sonra "kayit sec", en son "yeniden basla"
		var mid: Node = restart_btn.get_parent()
		mid.move_child(continue_btn, restart_btn.get_index())
		mid.move_child(pick_btn, restart_btn.get_index())


func used_knife() -> void:
	pass   # silah secimi artik kalici


# ---------------- Yardimcilar ----------------
func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.border_color = Color(0.45, 0.4, 0.28)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(8)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _label(text: String, font_size: int, col := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 5)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, toggle: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = toggle
	b.custom_minimum_size = Vector2(BTN, BTN)
	b.add_theme_font_size_override("font_size", 17)
	b.focus_mode = Control.FOCUS_NONE
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.22, 0.24, 0.18)
	normal.border_color = Color(0.5, 0.45, 0.3)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	var on := normal.duplicate()
	on.bg_color = Color(0.55, 0.45, 0.15)
	on.border_color = Color(1, 0.85, 0.4)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", on)
	b.add_theme_stylebox_override("hover_pressed", on)
	return b


# ---------------- Kayit paneli (Tur 4) ----------------
func show_saves(load_only := false) -> void:
	## 5 yuva: hizli, otomatik, 1-3. Elle yuvalara ve hizliya kaydedilir; hepsi yuklenebilir.
	if _saves_panel != null and is_instance_valid(_saves_panel):
		_close_saves()
		return
	var was_paused := get_tree().paused
	get_tree().paused = true
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.78)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.set_meta("was_paused", was_paused)
	add_child(shade)
	_saves_panel = shade
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 10)
	shade.add_child(box)
	box.add_child(_label("KAYIT", 36, ACCENT))
	var why: String = "" if load_only else Kayit.why_not(main)
	if why != "" and not main.game_over:
		box.add_child(_label("Şu an kaydedilemez: " + why, 17, Color(1, 0.6, 0.4)))
	for slot in Kayit.SLOTS:
		var inf: Dictionary = Kayit.info(slot)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		box.add_child(row)
		var txt: String = Kayit.SLOT_NAMES[slot] + "\n"
		if inf.is_empty():
			txt += "boş"
		elif inf.get("bozuk", false):
			txt += "okunamadı"
		else:
			var t: float = float(inf.get("sure", 0))
			txt += "%s · %d:%02d · görev %s · %s" % [inf.get("ad", "?"), int(t) / 60, int(t) % 60, inf.get("gorev", "?"), str(inf.get("tarih", "")).replace("T", " ").left(16)]
		var l := _label(txt, 17)
		l.custom_minimum_size = Vector2(470, 52)
		row.add_child(l)
		if slot in Kayit.MANUAL and not load_only:
			var sb := _button("Kaydet", false)
			sb.custom_minimum_size = Vector2(110, 52)
			sb.disabled = why != ""
			sb.pressed.connect(func():
				if main.save_slot(slot):
					_close_saves())
			row.add_child(sb)
		elif not load_only:
			var gap := Control.new()      # otomatik kayda elle kaydedilmez: sutunlar hizali kalsin
			gap.custom_minimum_size = Vector2(110, 52)
			row.add_child(gap)
		var yb := _button("Yükle", false)
		yb.custom_minimum_size = Vector2(110, 52)
		yb.disabled = inf.is_empty() or inf.get("bozuk", false)
		yb.pressed.connect(func(): main.load_slot(slot))
		row.add_child(yb)
	var hint := _label("PC: F5 hızlı kaydet · F9 hızlı yükle · Esc bu panel", 14, Color(1, 1, 1, 0.6))
	box.add_child(hint)
	var close := _button("Kapat", false)
	close.custom_minimum_size = Vector2(180, 52)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func(): _close_saves())
	box.add_child(close)


func _close_saves() -> void:
	if _saves_panel == null or not is_instance_valid(_saves_panel):
		return
	var was: bool = _saves_panel.get_meta("was_paused", false)
	_saves_panel.queue_free()
	_saves_panel = null
	get_tree().paused = was


func show_news() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.04, 0.03, 0.92)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 60
	scroll.offset_right = -60
	scroll.offset_top = 30
	scroll.offset_bottom = -30
	shade.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	scroll.add_child(box)
	box.add_child(_label("YENİLİKLER", 34, ACCENT))
	for entry in Yenilikler.LIST:
		box.add_child(_label(entry[0], 20, ACCENT))
		for line in entry[1]:
			var l := _label("•  " + line, 17)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			box.add_child(l)
	var close := _button("Kapat", false)
	close.custom_minimum_size = Vector2(180, 52)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func(): shade.queue_free())
	box.add_child(close)


func _unhandled_key_input(e: InputEvent) -> void:
	## oyun duraklamisken (kayit paneli acik) Esc paneli kapatir
	if e.pressed and not e.echo and e.keycode == KEY_ESCAPE and _saves_panel != null and is_instance_valid(_saves_panel):
		_close_saves()
		get_viewport().set_input_as_handled()
