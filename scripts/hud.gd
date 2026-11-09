extends CanvasLayer
## Commandos tarzi taktik HUD.
## Sol ust: mini harita · Ust orta: gorev · Sol alt: komando portresi
## Sag alt: envanter + ozel yetenek butonlari · Orta: sonuc mesaji
## Tum parcalar capa (anchor) ile kenarlara yapisir: telefon ve PC'de ayni duzen.

const Minimap = preload("res://scripts/minimap.gd")

const BTN := 76          # dokunmatik icin en az ~10 mm
const PANEL_BG := Color(0.1, 0.11, 0.08, 0.82)
const ACCENT := Color(0.85, 0.75, 0.45)

var main
var knife_mode := false
var show_cones := true

var goal_label: Label
var alert_label: Label
var status_label: Label
var msg_label: Label
var restart_btn: Button
var knife_btn: Button
var run_btn: Button
var cone_btn: Button
var slots: Array[Label] = []


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

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
	goal_label = _label("Hedef: " + main.level.data.get("brief", ""), 20)
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(goal_label)
	alert_label = _label("", 18, Color(1, 0.5, 0.3))
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label.visible = false
	top.add_child(alert_label)

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
	br_box.add_child(_label("YETENEKLER", 13, ACCENT))
	var abil := HBoxContainer.new()
	br_box.add_child(abil)
	knife_btn = _button("Bıçak", true)
	knife_btn.toggled.connect(func(on): knife_mode = on)
	abil.add_child(knife_btn)
	run_btn = _button("Koş", true)
	run_btn.toggled.connect(func(on): main.commando.run = on)
	abil.add_child(run_btn)
	cone_btn = _button("Koni", true)
	cone_btn.button_pressed = true
	cone_btn.toggled.connect(func(on): show_cones = on)
	abil.add_child(cone_btn)
	var center_btn := _button("Odak", false)
	center_btn.pressed.connect(func(): main.cam.position = main.commando.global_position)
	abil.add_child(center_btn)

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
	restart_btn.pressed.connect(func(): get_tree().reload_current_scene())
	mid.add_child(restart_btn)


func _process(_delta: float) -> void:
	var c = main.commando
	if c == null:
		return
	if not c.alive:
		status_label.text = "Yakalandı"
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
func on_document() -> void:
	slots[1].text = "BELGE"
	slots[1].add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	goal_label.text = "Belge alındı! ÇIKIŞ bölgesine dön (sol alt)"


func set_alert(text: String) -> void:
	alert_label.text = text
	alert_label.visible = true


func show_end(text: String, col: Color) -> void:
	msg_label.text = text
	msg_label.add_theme_color_override("font_color", col)
	msg_label.visible = true
	restart_btn.visible = true


func used_knife() -> void:
	knife_btn.button_pressed = false


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
