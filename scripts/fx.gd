extends Node2D
## Kucuk gorsel efektler: mermi izi (tracer) + namlu alevi, kan/isabet bulutu, iyilesme.
## Havuzlama yerine kisa omurlu tek dugum: ekranda ayni anda birkac tane olur.

var kind := ""
var a := Vector2.ZERO
var b := Vector2.ZERO
var t := 0.0
var life := 0.15


static func tracer(parent: Node, from: Vector2, to: Vector2) -> void:
	var f = load("res://scripts/fx.gd").new()
	f.kind = "tracer"
	f.a = from
	f.b = to
	f.life = 0.12
	_z(f)
	parent.add_child(f)


static func blood(parent: Node, at: Vector2) -> void:
	var f = load("res://scripts/fx.gd").new()
	f.kind = "blood"
	f.a = at
	f.life = 0.45
	_z(f)
	parent.add_child(f)


static func heal(parent: Node, at: Vector2) -> void:
	var f = load("res://scripts/fx.gd").new()
	f.kind = "heal"
	f.a = at
	f.life = 0.8
	_z(f)
	parent.add_child(f)


static func stone(parent: Node, from: Vector2, to: Vector2) -> void:
	## atilan tas: kavis cizerek ucar, dustugu yerde ses halkasi
	var f = load("res://scripts/fx.gd").new()
	f.kind = "stone"
	f.a = from
	f.b = to
	f.life = 1.0
	_z(f)
	parent.add_child(f)


static func _z(f: Node2D) -> void:
	f.set_meta("static_z", true)
	f.z_index = 13 if load("res://scripts/sprite_sheet.gd").view_rot == 0.0 else 3400


func _process(delta: float) -> void:
	t += delta
	if t >= life:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := 1.0 - t / life
	match kind:
		"tracer":
			draw_line(a, b, Color(1.0, 0.92, 0.6, 0.85 * k), 2.0)
			draw_circle(a + (b - a).normalized() * 8.0, 5.0 * k + 1.0, Color(1.0, 0.75, 0.3, 0.9 * k))
		"blood":
			for i in 5:
				var off := Vector2.from_angle(i * 1.3 + a.x) * (4.0 + t * 40.0)
				draw_circle(a + off, 3.0 * k + 1.0, Color(0.55, 0.05, 0.05, 0.8 * k))
		"stone":
			var fl := 0.45
			if t < fl:
				var u := t / fl
				var p := a.lerp(b, u) + Vector2(0, -sin(u * PI) * 60.0).rotated(load("res://scripts/sprite_sheet.gd").view_rot)
				draw_circle(p, 3.5, Color(0.55, 0.53, 0.5))
			else:
				var u := (t - fl) / (life - fl)
				draw_arc(b, 20.0 + u * 160.0, 0, TAU, 32, Color(1, 1, 0.8, 0.6 * (1.0 - u)), 2.0)
				draw_circle(b, 3.0, Color(0.55, 0.53, 0.5))
		"heal":
			draw_string(ThemeDB.fallback_font, a + Vector2(-10, -40 - t * 30), "+", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0.4, 1, 0.4, k))
