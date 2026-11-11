extends Node2D
## Yari izometrik "yukseltilmis" cokgen: tabani carpisma izidir,
## ustu `height` kadar yukari kaydirilip cizilir, guneye bakan yuzler golgeli.
## Node konumu cokgenin en alt noktasidir -> Y-Sort dogru calisir.

const SpriteSheet = preload("res://scripts/sprite_sheet.gd")

var lvl                              # Level (donuk acida z sirasi icin)
var poly := PackedVector2Array()   # yerel koordinatlar
var height := 20.0
var top_color := Color.WHITE
var side_color := Color.GRAY
var line_color := Color(0, 0, 0, 0.35)
var ridge := false                  # cati mahya cizgisi


func setup(world_points: PackedVector2Array, h: float, top: Color, side: Color) -> void:
	var max_y := -INF
	var sum := Vector2.ZERO
	for p in world_points:
		max_y = maxf(max_y, p.y)
		sum += p
	var origin := Vector2(sum.x / world_points.size(), max_y)
	position = origin
	poly = PackedVector2Array()
	for p in world_points:
		poly.append(p - origin)
	height = h
	top_color = top
	side_color = side


func _draw() -> void:
	var n := poly.size()
	if n < 3:
		return
	var center := Vector2.ZERO
	for p in poly:
		center += p
	center /= n
	# ekranda "yukari" yonu (4 yonlu bakista kamera doner)
	var vr: float = SpriteSheet.view_rot
	var up := Vector2(0, -height).rotated(vr)
	# guneye bakan yan yuzler
	for i in n:
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % n]
		var normal := (b - a).orthogonal().normalized()
		if normal.dot((a + b) * 0.5 - center) < 0.0:
			normal = -normal
		if normal.rotated(-vr).y > 0.05:
			var shade := side_color.darkened(0.15 * absf(normal.x))
			draw_colored_polygon(PackedVector2Array([a, b, b + up, a + up]), shade)
	# ust yuz
	var top := PackedVector2Array()
	for p in poly:
		top.append(p + up)
	draw_colored_polygon(top, top_color)
	var outline := top.duplicate()
	outline.append(top[0])
	draw_polyline(outline, line_color, 1.5)
	if ridge and vr == 0.0:
		var minx := INF
		var maxx := -INF
		for p in top:
			minx = minf(minx, p.x)
			maxx = maxf(maxx, p.x)
		var cy := (center + up).y
		draw_line(Vector2(minx + 4, cy), Vector2(maxx - 4, cy), top_color.darkened(0.35), 4.0)


func view_base() -> float:
	## donuk acida z sirasi: tabanin ekrandaki en alt noktasi
	var best := -INF
	for p in poly:
		var v: Vector2 = lvl.to_view(global_position + p) if lvl else global_position + p
		best = maxf(best, v.y)
	return best


func view_changed() -> void:
	queue_redraw()
