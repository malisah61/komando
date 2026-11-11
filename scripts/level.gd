extends Node2D
## Bolum dosyasini (levels/*.json) okur ve dunyayi kurar.
## Ilke 1: her engelin `move` (hareketi engeller) ve `view` (gorusu engeller) bayragi var.
## Ilke 2: engeller serbest cokgen.
## Ilke 3: `footprints` zeminlerinde ayak izi kalir, askerler fark eder.
## Ilke 4: haritalar koddan ayri veri dosyalarinda.

const Prop = preload("res://scripts/prop.gd")
const Roof = preload("res://scripts/roof.gd")

const WALL := 12.0
const DOOR := 60.0
const WALL_H := 30.0
const FOOTPRINT_LIFE := 40.0

# tur -> [hareket, gorus, yukseklik, ust renk, yan renk]
const TYPES := {
	"hedge":   [true,  true,  26.0, Color(0.2, 0.36, 0.15), Color(0.12, 0.24, 0.09)],
	"wall":    [true,  true,  34.0, Color(0.62, 0.6, 0.55), Color(0.42, 0.4, 0.36)],
	"sandbag": [true,  false, 14.0, Color(0.74, 0.66, 0.46), Color(0.52, 0.45, 0.3)],
	"bush":    [false, true,  22.0, Color(0.24, 0.44, 0.18, 0.92), Color(0.16, 0.3, 0.12, 0.92)],
	"crate":   [true,  true,  28.0, Color(0.6, 0.45, 0.25), Color(0.42, 0.3, 0.16)],
	"tree":    [true,  true,  42.0, Color(0.17, 0.33, 0.13), Color(0.1, 0.21, 0.07)],
	"water":   [true,  false, 0.0,  Color(0.22, 0.38, 0.5),  Color(0.16, 0.3, 0.42)],
	"fence":   [true,  false, 12.0, Color(0.48, 0.36, 0.22), Color(0.33, 0.24, 0.14)],
	"tent":    [true,  true,  24.0, Color(0.44, 0.46, 0.32), Color(0.31, 0.33, 0.22)],
	"truck":   [true,  true,  26.0, Color(0.31, 0.34, 0.25), Color(0.2, 0.22, 0.16)],
	"tank":    [true,  true,  24.0, Color(0.37, 0.39, 0.34), Color(0.24, 0.26, 0.22)],
	"rock":    [true,  true,  18.0, Color(0.52, 0.52, 0.5),  Color(0.36, 0.36, 0.34)],
}
const GRID := 128.0

var data := {}
var size := Vector2(1600, 1100)
var start := Vector2.ZERO
var exit_rect := Rect2()
var document_pos := Vector2.ZERO
var document_taken := false

var view_segments: Array = []     # [a, b, bbox]
var move_polys: Array = []        # PackedVector2Array
var surfaces: Array = []          # {points, color, footprints}
var floors: Array = []            # Rect2 (bina ici)
var roads: Array = []
var bridges: Array = []           # Rect2 (ahsap kopru)
var water: Array = []             # PackedVector2Array (zeminde cizilir)
var hide_zones: Array = []        # [merkez, yaricap] ya da PackedVector2Array (calilar)
var _grid := {}                   # Vector2i -> [segment indeksleri]
var _stamp := PackedInt32Array()
var _query := 0
var footprints: Array = []        # {pos, rot, age, noticed}

var _redraw_t := 0.0

# --- Blender'da render edilmis harita (levels/<bolum>_art/) ---
var art := false
var ground_tex: Texture2D        # eski tek parca zemin (geriye uyum)
var ground_tiles: Array = []      # [Texture2D, Rect2] - parcali zemin
var art_scale := 1.0
var _areas: Array = []            # bina indeksi -> Roof alani
var pickups: Array = []          # {type, pos, taken} - saglik cantasi / mermi
var scorches: Array = []         # [konum, yaricap] - patlama izi
var broken_bridges: Array = []    # Rect2
var _region: NavigationRegion2D
var occluders: Array = []         # [ekran dikdortgeni, taban y, dugum] - silüet icin


func load_level(path: String, world: Node2D, roofs: Node2D) -> bool:
	level_path = path
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Bolum dosyasi acilamadi: " + path)
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Bolum dosyasi bozuk: " + path)
		return false
	data = parsed
	var art_dir := path.get_basename() + "_art/"
	art = FileAccess.file_exists(art_dir + "manifest.json")
	size = _v(data["size"])
	start = _v(data["start"])
	var e: Array = data["exit"]
	exit_rect = Rect2(e[0], e[1], e[2], e[3])
	document_pos = _v(data["document"])
	for r in data.get("roads", []):
		roads.append(Rect2(r[0], r[1], r[2], r[3]))
	for pk in data.get("pickups", []):
		pickups.append({"type": pk.get("type", "medkit"), "pos": _v(pk["pos"]), "taken": false})
	for r in data.get("bridges", []):
		bridges.append(Rect2(r[0], r[1], r[2], r[3]))
	for s in data.get("surfaces", []):
		var col := Color(0.4, 0.3, 0.18) if s.get("type", "") == "mud" else Color(0.9, 0.92, 0.95)
		surfaces.append({"points": _poly(s["points"]), "color": col, "footprints": s.get("footprints", false)})

	# harita kenarlari: gorusu keser
	var border := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
	_add_view_poly(border)

	var bi := 0
	for b in data.get("buildings", []):
		_build_building(b, world, roofs)
		bi += 1
	for o in data.get("obstacles", []):
		_build_obstacle(o, world)
	if art:
		_build_art(art_dir, world, roofs)

	_build_navigation()
	_build_grid()
	queue_redraw()
	return true


# ---------------- Kurulum ----------------
func _build_obstacle(o: Dictionary, world: Node2D) -> void:
	var t: Array = TYPES.get(o.get("type", "wall"), TYPES["wall"])
	var pts: PackedVector2Array
	if o.has("circle"):
		var c: Array = o["circle"]
		pts = _circle(Vector2(c[0], c[1]), c[2], 10)
	else:
		pts = _poly(o["points"])
	var blocks_move: bool = o.get("move", t[0])
	var blocks_view: bool = o.get("view", t[1])
	_add_solid(pts, blocks_move, blocks_view)
	if blocks_view and not blocks_move:
		if o.has("circle"):
			var cc: Array = o["circle"]
			hide_zones.append([Vector2(cc[0], cc[1]), float(cc[2])])
		else:
			hide_zones.append(pts)
	if t[2] <= 0.0:
		water.append(pts)     # yuksekligi olmayan: zemine cizilir
		return
	if art:
		return                # gorunum render edilmis atlastan gelir
	var p = Prop.new()
	p.setup(pts, t[2], t[3], t[4])
	world.add_child(p)


func _build_building(b: Dictionary, world: Node2D, roofs: Node2D) -> void:
	var r: Array = b["rect"]
	var rect := Rect2(r[0], r[1], r[2], r[3])
	floors.append(rect)
	var door: String = b.get("door", "S")
	var x0 := rect.position.x
	var y0 := rect.position.y
	var x1 := rect.end.x
	var y1 := rect.end.y
	var cx := rect.get_center().x
	var cy := rect.get_center().y
	var hd := DOOR * 0.5
	var walls: Array[Rect2] = []
	# kuzey
	if door == "N":
		walls.append(Rect2(x0, y0, cx - hd - x0, WALL))
		walls.append(Rect2(cx + hd, y0, x1 - cx - hd, WALL))
	else:
		walls.append(Rect2(x0, y0, rect.size.x, WALL))
	# guney
	if door == "S":
		walls.append(Rect2(x0, y1 - WALL, cx - hd - x0, WALL))
		walls.append(Rect2(cx + hd, y1 - WALL, x1 - cx - hd, WALL))
	else:
		walls.append(Rect2(x0, y1 - WALL, rect.size.x, WALL))
	# bati
	if door == "W":
		walls.append(Rect2(x0, y0 + WALL, WALL, cy - hd - y0 - WALL))
		walls.append(Rect2(x0, cy + hd, WALL, y1 - WALL - cy - hd))
	else:
		walls.append(Rect2(x0, y0 + WALL, WALL, rect.size.y - WALL * 2))
	# dogu
	if door == "E":
		walls.append(Rect2(x1 - WALL, y0 + WALL, WALL, cy - hd - y0 - WALL))
		walls.append(Rect2(x1 - WALL, cy + hd, WALL, y1 - WALL - cy - hd))
	else:
		walls.append(Rect2(x1 - WALL, y0 + WALL, WALL, rect.size.y - WALL * 2))

	var wall_props: Array = []
	for w in walls:
		var pts := _rect_poly(w)
		_add_solid(pts, true, true)
		if art:
			continue
		var p = Prop.new()
		p.setup(pts, WALL_H, Color(0.78, 0.72, 0.6), Color(0.6, 0.53, 0.42))
		world.add_child(p)
		wall_props.append(p)

	# cati + icerisi icin seffaflasan alan
	var roof = null
	if not art:
		var rc: Array = b.get("roof", [0.58, 0.3, 0.24])
		var roof_col := Color(rc[0], rc[1], rc[2])
		roof = Prop.new()
		roof.setup(_rect_poly(rect.grow(6)), WALL_H + 8.0, roof_col, roof_col.darkened(0.3))
		roof.ridge = true
		roofs.add_child(roof)
	var area = Roof.new()
	area.roof_node = roof
	area.wall_nodes = wall_props
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size - Vector2(WALL * 2, WALL * 2)
	shape.shape = rs
	area.position = rect.get_center()
	area.add_child(shape)
	add_child(area)
	_areas.append(area)


func _build_art(dir: String, world: Node2D, roofs: Node2D) -> void:
	## Blender ciktisi: zemin karolari + her nesne icin Y-Sort'a giren ayri sprite
	var man = JSON.parse_string(FileAccess.get_file_as_string(dir + "manifest.json"))
	art_scale = float(man.get("scale", 1.0))
	if man.has("ground"):
		for g in man["ground"]:
			var r: Array = g["rect"]
			ground_tiles.append([load(dir + g["file"]), Rect2(r[0], r[1], r[2], r[3])])
	else:
		ground_tex = load(dir + "ground.jpg")
	var obj_pages := _pages(dir, man, "objects")
	var roof_pages := _pages(dir, man, "roofs")
	for e in man.get("objects", []):
		var spr := _art_sprite(obj_pages[int(e.get("page", 0))], e)
		world.add_child(spr)
		occluders.append([_world_rect(e), float(e["base"][3]), spr])
		if e["kind"] == "wall":
			var a = _areas[int(e["building"])]
			a.wall_nodes.append(spr)
	for e in man.get("roofs", []):
		var spr := _art_sprite(roof_pages[int(e.get("page", 0))], e)
		roofs.add_child(spr)
		occluders.append([_world_rect(e), INF, spr])
		_areas[int(e["building"])].roof_node = spr


func _pages(dir: String, man: Dictionary, key: String) -> Array:
	var out: Array = []
	if man.has(key + "_pages"):
		for f in man[key + "_pages"]:
			out.append(load(dir + f))
	else:
		out.append(load(dir + key + ".png"))
	return out


func _world_rect(e: Dictionary) -> Rect2:
	var r: Array = e["rect"]
	return Rect2(r[0] / art_scale, r[1] / art_scale, r[2] / art_scale, r[3] / art_scale)


func _art_sprite(tex: Texture2D, e: Dictionary) -> Sprite2D:
	var r: Array = e["rect"]
	var a: Array = e["atlas"]
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(a[0], a[1], r[2], r[3])
	var spr := Sprite2D.new()
	spr.texture = at
	spr.centered = false
	spr.scale = Vector2.ONE / art_scale
	var base: Array = e["base"]
	spr.position = Vector2((float(base[0]) + float(base[2])) * 0.5, float(base[3]))
	# offset yerel (olceklenmemis) birimde
	spr.offset = Vector2(r[0], r[1]) - spr.position * art_scale
	return spr


func is_occluded(p: Vector2) -> bool:
	## karakter bir nesnenin/catinin arkasinda mi? (Commandos'taki silüet icin)
	var head := p + Vector2(0, -22)
	for o in occluders:
		var rect: Rect2 = o[0]
		if not rect.has_point(head):
			continue
		if o[1] > p.y and o[2].modulate.a > 0.5:
			return true
	return false


func _add_solid(pts: PackedVector2Array, blocks_move: bool, blocks_view: bool) -> void:
	if blocks_view:
		_add_view_poly(pts)
	if blocks_move:
		move_polys.append(pts)
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var cp := CollisionPolygon2D.new()
		cp.polygon = pts
		body.add_child(cp)
		add_child(body)


func _add_view_poly(pts: PackedVector2Array) -> void:
	for i in pts.size():
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		var bb := Rect2(a, Vector2.ZERO).expand(b)
		view_segments.append([a, b, bb])


static var _nav_cache := {}       # bolum yolu -> hazir navigasyon (yeniden baslatmada tekrar pisirme)
var level_path := ""


func _build_navigation(use_cache := true) -> void:
	if use_cache and _nav_cache.has(level_path):
		if _region == null:
			_region = NavigationRegion2D.new()
			add_child(_region)
		_region.navigation_polygon = _nav_cache[level_path]
		return
	var navpoly := NavigationPolygon.new()
	navpoly.agent_radius = 11.0
	var src := NavigationMeshSourceGeometryData2D.new()
	src.add_traversable_outline(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]))
	for p in move_polys:
		src.add_obstruction_outline(p)
	NavigationServer2D.bake_from_source_geometry_data(navpoly, src)
	if _region == null:
		_region = NavigationRegion2D.new()
		add_child(_region)
	_region.navigation_polygon = navpoly
	if use_cache:
		_nav_cache[level_path] = navpoly


func destroy_bridge(i: int) -> void:
	## kopru yikildi: artik suyun ustunden gecilemez (navigasyon yeniden hesaplanir)
	if i < 0 or i >= bridges.size():
		return
	var r: Rect2 = bridges[i]
	broken_bridges.append(r)
	_add_solid(_rect_poly(r.grow_individual(-30, 6, -30, 6)), true, false)
	_build_navigation(false)
	queue_redraw()


func add_scorch(p: Vector2, r: float) -> void:
	scorches.append([p, r])
	queue_redraw()


# ---------------- Gorus hatti ----------------
func _build_grid() -> void:
	## gorus cizgilerini 128px hucrelere dagit: buyuk haritada hizli isin testi
	_grid.clear()
	_stamp.resize(view_segments.size())
	for i in view_segments.size():
		var bb: Rect2 = view_segments[i][2]
		for cx in range(floori(bb.position.x / GRID), floori(bb.end.x / GRID) + 1):
			for cy in range(floori(bb.position.y / GRID), floori(bb.end.y / GRID) + 1):
				var key := Vector2i(cx, cy)
				if not _grid.has(key):
					_grid[key] = PackedInt32Array()
				_grid[key].append(i)


func ray_end(from: Vector2, to: Vector2) -> Vector2:
	var best := to
	var best_d := from.distance_to(to)
	var ray_bb := Rect2(from, Vector2.ZERO).expand(to).grow(1.0)
	_query += 1
	for cx in range(floori(ray_bb.position.x / GRID), floori(ray_bb.end.x / GRID) + 1):
		for cy in range(floori(ray_bb.position.y / GRID), floori(ray_bb.end.y / GRID) + 1):
			var cell = _grid.get(Vector2i(cx, cy))
			if cell == null:
				continue
			for i in cell:
				if _stamp[i] == _query:
					continue
				_stamp[i] = _query
				var s: Array = view_segments[i]
				if not ray_bb.intersects(s[2], true):
					continue
				var hit = Geometry2D.segment_intersects_segment(from, to, s[0], s[1])
				if hit != null:
					var d: float = from.distance_to(hit)
					if d < best_d:
						best_d = d
						best = hit
	return best


func has_los(a: Vector2, b: Vector2) -> bool:
	return ray_end(a, b).distance_to(b) < 1.0


func is_inside_view_blocker(p: Vector2) -> bool:
	# calilik icinde mi? (gorusu engelleyen ama hareketi engellemeyen)
	for z in hide_zones:
		if z is Array:
			if p.distance_to(z[0]) < z[1]:
				return true
		elif Geometry2D.is_point_in_polygon(p, z):
			return true
	return false


# ---------------- Ayak izleri ----------------
func leaves_footprints(p: Vector2) -> bool:
	for s in surfaces:
		if s["footprints"] and Geometry2D.is_point_in_polygon(p, s["points"]):
			return true
	return false


func add_footprint(p: Vector2, rot: float) -> void:
	footprints.append({"pos": p, "rot": rot, "age": 0.0, "noticed": false})


func _process(delta: float) -> void:
	var i := footprints.size() - 1
	while i >= 0:
		footprints[i]["age"] += delta
		if footprints[i]["age"] > FOOTPRINT_LIFE:
			footprints.remove_at(i)
		i -= 1
	_redraw_t -= delta
	if _redraw_t <= 0.0:
		_redraw_t = 0.25
		queue_redraw()


# ---------------- Zemin cizimi ----------------
func _draw() -> void:
	var font := ThemeDB.fallback_font
	if not ground_tiles.is_empty():
		for t in ground_tiles:
			draw_texture_rect(t[0], t[1], false)
	elif ground_tex != null:
		draw_texture(ground_tex, Vector2.ZERO)
	else:
		_draw_plain_ground()
	_draw_overlays(font)


func _draw_plain_ground() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.36, 0.45, 0.26))
	for r in roads:
		draw_rect(r, Color(0.55, 0.47, 0.34))
	for s in surfaces:
		draw_colored_polygon(s["points"], s["color"])
	for w in water:
		draw_colored_polygon(w, Color(0.2, 0.36, 0.48))
		var edge: PackedVector2Array = w.duplicate()
		edge.append(w[0])
		draw_polyline(edge, Color(0.45, 0.42, 0.3), 5.0)
	for b in bridges:
		draw_rect(b, Color(0.42, 0.3, 0.18))
		var x: float = b.position.x
		while x < b.end.x:
			draw_line(Vector2(x, b.position.y), Vector2(x, b.end.y), Color(0.3, 0.2, 0.11), 2.0)
			x += 14.0
		draw_rect(Rect2(b.position, Vector2(b.size.x, 6)), Color(0.3, 0.2, 0.11))
		draw_rect(Rect2(b.position.x, b.end.y - 6, b.size.x, 6), Color(0.3, 0.2, 0.11))
	for fl in floors:
		draw_rect(fl, Color(0.45, 0.33, 0.22))
		var y: float = fl.position.y + 16.0
		while y < fl.end.y:
			draw_line(Vector2(fl.position.x, y), Vector2(fl.end.x, y), Color(0.38, 0.27, 0.18), 1.0)
			y += 16.0


func _draw_overlays(font: Font) -> void:
	for pk in pickups:
		if pk["taken"]:
			continue
		var pp: Vector2 = pk["pos"]
		if pk["type"] == "medkit":
			draw_rect(Rect2(pp - Vector2(9, 7), Vector2(18, 14)), Color(0.92, 0.92, 0.88))
			draw_rect(Rect2(pp - Vector2(2, 5), Vector2(4, 10)), Color(0.8, 0.1, 0.1))
			draw_rect(Rect2(pp - Vector2(5, 2), Vector2(10, 4)), Color(0.8, 0.1, 0.1))
		else:
			draw_rect(Rect2(pp - Vector2(9, 6), Vector2(18, 12)), Color(0.35, 0.38, 0.22))
			draw_rect(Rect2(pp - Vector2(9, 6), Vector2(18, 12)), Color(0.85, 0.75, 0.3), false, 1.5)
	for sc in scorches:
		draw_circle(sc[0], sc[1], Color(0.08, 0.07, 0.06, 0.55))
		draw_circle(sc[0], sc[1] * 0.6, Color(0.05, 0.04, 0.03, 0.5))
	for br in broken_bridges:
		var mid := Rect2(br.position.x + 30, br.position.y - 4, br.size.x - 60, br.size.y + 8)
		draw_rect(mid, Color(0.15, 0.3, 0.38))
		var rng := RandomNumberGenerator.new()
		rng.seed = int(br.position.x)
		for k in 18:
			var pp := Vector2(rng.randf_range(mid.position.x, mid.end.x), rng.randf_range(mid.position.y, mid.end.y))
			draw_set_transform(pp, rng.randf_range(-0.6, 0.6), Vector2.ONE)
			draw_rect(Rect2(-14, -3, 28, 6), Color(0.22, 0.15, 0.08))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for fp in footprints:
		var a: float = 1.0 - float(fp["age"]) / FOOTPRINT_LIFE
		draw_set_transform(fp["pos"], fp["rot"], Vector2.ONE)
		draw_rect(Rect2(-4, -5, 7, 3), Color(0.15, 0.1, 0.05, 0.7 * a))
		draw_rect(Rect2(-4, 2, 7, 3), Color(0.15, 0.1, 0.05, 0.7 * a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(exit_rect, Color(0.3, 0.9, 0.4, 0.22))
	draw_rect(exit_rect, Color(0.3, 0.9, 0.4, 0.8), false, 3.0)
	draw_string(font, exit_rect.position + Vector2(40, 30), "ÇIKIŞ", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	if not document_taken:
		draw_rect(Rect2(document_pos - Vector2(12, 9), Vector2(24, 18)), Color(1, 0.9, 0.3))
		draw_rect(Rect2(document_pos - Vector2(12, 9), Vector2(24, 18)), Color(0.4, 0.3, 0), false, 2.0)


# ---------------- Yardimcilar ----------------
func _v(a: Array) -> Vector2:
	return Vector2(a[0], a[1])


func _poly(arr: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in arr:
		out.append(Vector2(p[0], p[1]))
	return out


func _rect_poly(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


func _circle(c: Vector2, r: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		out.append(c + Vector2.from_angle(TAU * i / n) * r)
	return out
