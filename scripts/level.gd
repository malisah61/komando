extends Node2D
## Bolum dosyasini (levels/*.json) okur ve dunyayi kurar.
## Ilke 1: her engelin `move` (hareketi engeller) ve `view` (gorusu engeller) bayragi var.
## Ilke 2: engeller serbest cokgen.
## Ilke 3: `footprints` zeminlerinde ayak izi kalir, askerler fark eder.
## Ilke 4: haritalar koddan ayri veri dosyalarinda.

signal changed_map                # harita degisti (kopru yikildi): mini harita yeniden cizilsin

const Prop = preload("res://scripts/prop.gd")
const Roof = preload("res://scripts/roof.gd")
const SpriteSheet = preload("res://scripts/sprite_sheet.gd")

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
	"tower":   [false, false, 52.0, Color(0.45, 0.33, 0.2),  Color(0.3, 0.22, 0.13)],   # gozetleme kulesi (dekor, ustunde kule nobetcisi)
}
# siper: arkasinda comelen karakter daha zor vurulur (Desperados III / Commandos)
const COVER_TYPES := ["sandbag", "crate", "rock", "truck", "tank", "wall", "fence"]
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

# --- 4 yonlu bakis (Commandos 2): her aci Blender'da ayri render edilir (<bolum>_art/v1..v3) ---
static var view := 0              # 0..3, her biri 90 derece
static var view_rot := 0.0        # kamera donusu (radyan)
var art_dir := ""
var _views := {}                  # aci -> {ground, objects, roofs, occ, walls, roof_nodes}
var _world: Node2D
var _roofs: Node2D

# --- Bina ici haritalar (Commandos 2 gibi): her bina ayri, buyutulmus bir ic mekan ---
const ISCALE := 2.0
const IWALL := 16.0
const IWALL_H := 64.0
const IDOOR := 76.0
var interiors: Array = []         # {name, rect, irect, side, ext_door, int_door, out, locked}
var cover_polys: Array = []       # [PackedVector2Array, Rect2] - siper
var sirens: Array = []            # Vector2 - alarm sireni (asker kosup calar)
var siren_on := 0.0               # siren calma suresi (gorsel)
var soft_from := 0                # view_segments icinde calilik (yumusak) kenarlarin isareti



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
	size = _v(data["size"])
	_plan_interiors()
	_map_data()
	art_dir = path.get_basename() + "_art/"
	art = FileAccess.file_exists(art_dir + "manifest.json")
	_world = world
	_roofs = roofs
	view = 0
	view_rot = 0.0
	SpriteSheet.view_rot = 0.0
	size = _v(data["size"])
	start = _v(data["start"])
	var e: Array = data["exit"]
	exit_rect = Rect2(e[0], e[1], e[2], e[3])
	document_pos = _v(data["document"])
	for r in data.get("roads", []):
		roads.append(Rect2(r[0], r[1], r[2], r[3]))
	for pk in data.get("pickups", []):
		pickups.append({"type": pk.get("type", "medkit"), "pos": _v(pk["pos"]), "taken": false,
			"item": pk.get("item", ""), "count": int(pk.get("count", 1))})
	for r in data.get("bridges", []):
		bridges.append(Rect2(r[0], r[1], r[2], r[3]))
	for sp in data.get("sirens", []):
		sirens.append(_v(sp))
	for s in data.get("surfaces", []):
		var col := Color(0.9, 0.92, 0.95)
		match s.get("type", ""):
			"mud": col = Color(0.4, 0.3, 0.18)
			"beton": col = Color(0.52, 0.52, 0.5)
		surfaces.append({"points": _poly(s["points"]), "color": col, "footprints": s.get("footprints", false),
			"slow": float(s.get("slow", 1.0))})

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
	for i in interiors.size():
		_build_interior(i, world)

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
	if o.get("type", "wall") in COVER_TYPES:
		var bb := Rect2(pts[0], Vector2.ZERO)
		for q in pts:
			bb = bb.expand(q)
		cover_polys.append([pts, bb])
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
	var p = _mkprop()
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
	var cx: float = rect.get_center().x
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
		var p = _mkprop()
		p.setup(pts, WALL_H, Color(0.78, 0.72, 0.6), Color(0.6, 0.53, 0.42))
		world.add_child(p)
		wall_props.append(p)

	# bina disaridan kapali: icine kapidan girilir ve ayri ic haritaya gecilir
	_add_solid(_rect_poly(rect.grow(-WALL + 2)), true, false)

	# cati + icerisi icin seffaflasan alan
	var roof = null
	if not art:
		var rc: Array = b.get("roof", [0.58, 0.3, 0.24])
		var roof_col := Color(rc[0], rc[1], rc[2])
		roof = _mkprop()
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


# ---------------- Bina ici ----------------
func _plan_interiors() -> void:
	var x := 300.0
	var y := size.y + 700.0
	var row_h := 0.0
	for bd in data.get("buildings", []):
		var r: Array = bd["rect"]
		var rect := Rect2(r[0], r[1], r[2], r[3])
		var isz := rect.size * ISCALE
		if x + isz.x > maxf(size.x, 2400.0):
			x = 300.0
			y += row_h + 500.0
			row_h = 0.0
		var ir := Rect2(x, y, isz.x, isz.y)
		x += isz.x + 500.0
		row_h = maxf(row_h, isz.y)
		var side: String = bd.get("door", "S")
		var out: Vector2 = {"N": Vector2.UP, "S": Vector2.DOWN, "W": Vector2.LEFT, "E": Vector2.RIGHT}[side]
		var c := rect.get_center()
		var ic := ir.get_center()
		var edge := c + Vector2(out.x * rect.size.x / 2, out.y * rect.size.y / 2)
		var iedge := ic + Vector2(out.x * ir.size.x / 2, out.y * ir.size.y / 2)
		interiors.append({"name": bd.get("name", "Bina"), "rect": rect, "irect": ir, "side": side, "out": out,
			"ext_door": edge + out * 26.0, "int_door": iedge - out * 40.0, "specials": [],
			"locked": str(bd.get("locked", ""))})


func in_cover(p: Vector2, from: Vector2) -> bool:
	## p noktasi, from yonunden gelen atisa karsi alcak bir siperin (kum torbasi, sandik...) arkasinda mi?
	var seg := PackedVector2Array([from, p])
	for cv in cover_polys:
		var bb: Rect2 = cv[1]
		if not bb.grow(46.0).has_point(p):
			continue
		if bb.has_point(from):
			continue
		if Geometry2D.intersect_polyline_with_polygon(seg, cv[0]).size() > 0:
			return true
	return false


func add_pickup(pk: Dictionary) -> void:
	pickups.append(pk)
	queue_redraw()


func interior_of_ext(p: Vector2) -> int:
	## dis haritada bu nokta hangi binanin icinde? (yoksa -1)
	for i in interiors.size():
		if interiors[i]["rect"].has_point(p):
			return i
	return -1


func interior_at(p: Vector2) -> int:
	## bu nokta hangi ic haritada? (yoksa -1)
	for i in interiors.size():
		if interiors[i]["irect"].grow(40).has_point(p):
			return i
	return -1


func map_point(p: Vector2) -> Vector2:
	var i := interior_of_ext(p)
	if i < 0:
		return p
	var it: Dictionary = interiors[i]
	var q: Vector2 = it["irect"].position + (p - it["rect"].position) * ISCALE
	var inner: Rect2 = it["irect"].grow(-IWALL - 20.0)
	q = q.clamp(inner.position, inner.end)
	it["specials"].append(q)
	return q


func _seg_ok(map: RID, a: Vector2, b: Vector2) -> bool:
	if a.distance_to(b) < 4.0:
		return true
	var p := NavigationServer2D.map_get_path(map, a, b, true)
	return p.size() > 1 and p[p.size() - 1].distance_to(b) < 14.0


func reach(map: RID, a: Vector2, b: Vector2) -> bool:
	## kapilardan gecerek a -> b ulasilabilir mi (ic haritalar dis haritadan ayri)
	var ia := interior_at(a)
	var ib := interior_at(b)
	if ia == ib:
		return _seg_ok(map, a, b)
	var pa := a
	if ia >= 0:
		if not _seg_ok(map, a, interiors[ia]["int_door"]):
			return false
		pa = interiors[ia]["ext_door"]
	if ib >= 0:
		return _seg_ok(map, pa, interiors[ib]["ext_door"]) and _seg_ok(map, interiors[ib]["int_door"], b)
	return _seg_ok(map, pa, b)


func _map_arr(a: Array) -> Array:
	var q := map_point(Vector2(a[0], a[1]))
	return [q.x, q.y]


func _map_data() -> void:
	## bina icindeki her sey (asker, karakter, belge, esya, gorev noktasi) ic haritaya tasinir
	for g in data.get("guards", []):
		var np: Array = []
		for p in g["path"]:
			np.append(_map_arr(p))
		g["path"] = np
	for n in data.get("npcs", []):
		n["pos"] = _map_arr(n["pos"])
	for pk in data.get("pickups", []):
		pk["pos"] = _map_arr(pk["pos"])
	data["document"] = _map_arr(data["document"])
	for o in data.get("objectives", []):
		if o.has("pos") and not o.has("bridge"):
			o["pos"] = _map_arr(o["pos"])


const FURN := {
	# ad: [genislik, derinlik, yukseklik, ust renk, yan renk, gorusu keser]
	"masa":   [64, 40, 22, Color(0.52, 0.36, 0.2), Color(0.36, 0.24, 0.12), false],
	"dolap":  [80, 26, 60, Color(0.36, 0.24, 0.14), Color(0.25, 0.16, 0.09), true],
	"yatak":  [48, 84, 18, Color(0.88, 0.86, 0.8), Color(0.55, 0.42, 0.3), false],
	"sandik": [36, 36, 30, Color(0.6, 0.45, 0.25), Color(0.42, 0.3, 0.16), false],
	"soba":   [36, 36, 40, Color(0.2, 0.2, 0.22), Color(0.12, 0.12, 0.13), false],
	"harita": [96, 56, 22, Color(0.25, 0.4, 0.28), Color(0.3, 0.2, 0.12), false],
	"saman":  [74, 48, 34, Color(0.82, 0.7, 0.36), Color(0.62, 0.5, 0.22), true],
	"sira":   [130, 26, 20, Color(0.45, 0.3, 0.18), Color(0.32, 0.2, 0.1), false],
	"raf":    [90, 24, 58, Color(0.4, 0.28, 0.16), Color(0.28, 0.18, 0.1), true],
}


func _build_interior(i: int, world: Node2D) -> void:
	var it: Dictionary = interiors[i]
	var ir: Rect2 = it["irect"]
	var name: String = it["name"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + i * 77
	# duvarlar (kapi boslugu dis kapiyla ayni tarafta)
	var x0 := ir.position.x
	var y0 := ir.position.y
	var x1 := ir.end.x
	var y1 := ir.end.y
	var c := ir.get_center()
	var hd := IDOOR / 2.0
	var side: String = it["side"]
	var walls: Array = []
	if side == "N":
		walls += [Rect2(x0, y0, c.x - hd - x0, IWALL), Rect2(c.x + hd, y0, x1 - c.x - hd, IWALL)]
	else:
		walls.append(Rect2(x0, y0, ir.size.x, IWALL))
	if side == "S":
		walls += [Rect2(x0, y1 - IWALL, c.x - hd - x0, IWALL), Rect2(c.x + hd, y1 - IWALL, x1 - c.x - hd, IWALL)]
	else:
		walls.append(Rect2(x0, y1 - IWALL, ir.size.x, IWALL))
	if side == "W":
		walls += [Rect2(x0, y0, IWALL, c.y - hd - y0), Rect2(x0, c.y + hd, IWALL, y1 - c.y - hd)]
	else:
		walls.append(Rect2(x0, y0, IWALL, ir.size.y))
	if side == "E":
		walls += [Rect2(x1 - IWALL, y0, IWALL, c.y - hd - y0), Rect2(x1 - IWALL, c.y + hd, IWALL, y1 - c.y - hd)]
	else:
		walls.append(Rect2(x1 - IWALL, y0, IWALL, ir.size.y))
	# kapi esigi disari kapali: ic harita kapidan sonra biter
	var out: Vector2 = it["out"]
	var sill := Rect2(c + Vector2(out.x * ir.size.x / 2, out.y * ir.size.y / 2) - Vector2(hd + 4, hd + 4), Vector2(IDOOR + 8, IDOOR + 8))
	sill.position += out * (hd + 10)
	_add_solid(_rect_poly(sill), true, true)
	var specials: Array = it["specials"]
	var door_in: Vector2 = it["int_door"]
	# genis binalarda ara duvar (iki oda)
	if ir.size.x >= 460.0 and name != "Kilise" and name != "Ambar" and side != "E" and side != "W":
		var px := x0 + ir.size.x * 0.58
		var ok := true
		for sp in specials:
			if absf(sp.x - px) < 50.0:
				ok = false
		if ok:
			var gy := y0 + ir.size.y * 0.5
			walls.append(Rect2(px, y0, IWALL, gy - 45 - y0))
			walls.append(Rect2(px, gy + 45, IWALL, y1 - gy - 45))
	for w in walls:
		if w.size.x <= 1.0 or w.size.y <= 1.0:
			continue
		var pts := _rect_poly(w)
		_add_solid(pts, true, true)
		var pr = _mkprop()
		pr.setup(pts, IWALL_H, Color(0.32, 0.27, 0.22), Color(0.72, 0.66, 0.56))
		world.add_child(pr)
	# mobilya: duvar boyunca, kapi onu ve onemli noktalar bos kalir
	var kinds: Array
	match name:
		"Karargâh":
			kinds = ["harita", "masa", "dolap", "raf", "sandik", "masa"]
		"Ambar":
			kinds = ["saman", "saman", "sandik", "sandik", "saman", "raf"]
		"Belediye":
			kinds = ["masa", "masa", "dolap", "raf", "sandik"]
		"Depo":
			kinds = ["sandik", "sandik", "raf", "raf", "sandik", "sandik"]
		"Kilise":
			kinds = []
		_:
			kinds = ["yatak", "masa", "dolap", "soba", "sandik"]
	var placed: Array = []
	if name == "Kilise":
		# sira sira oturaklar, ortada koridor
		var yy := y0 + 80.0
		while yy < y1 - 110.0:
			for sx in [-1, 1]:
				var cx: float = c.x + sx * 85.0
				placed.append(_furn("sira", Vector2(cx, yy), world))
			yy += 60.0
		return
	var tries := 0
	var ki := 0
	while ki < kinds.size() and tries < 80:
		tries += 1
		var k: String = kinds[ki]
		var f: Array = FURN[k]
		var wall_side := rng.randi_range(0, 3)
		var along := rng.randf_range(0.15, 0.85)
		var pos: Vector2
		var horiz := wall_side < 2
		var fw: float = f[0] if horiz else f[1]
		var fh: float = f[1] if horiz else f[0]
		match wall_side:
			0: pos = Vector2(x0 + ir.size.x * along, y0 + IWALL + fh / 2 + 4)
			1: pos = Vector2(x0 + ir.size.x * along, y1 - IWALL - fh / 2 - 4)
			2: pos = Vector2(x0 + IWALL + fw / 2 + 4, y0 + ir.size.y * along)
			_: pos = Vector2(x1 - IWALL - fw / 2 - 4, y0 + ir.size.y * along)
		var rr := Rect2(pos - Vector2(fw, fh) / 2, Vector2(fw, fh))
		var bad := rr.grow(70).has_point(door_in)
		for sp in specials:
			if rr.grow(34).has_point(sp):
				bad = true
		for o in placed:
			if o.grow(20).intersects(rr):
				bad = true
		if bad:
			continue
		placed.append(_furn(k, pos, world, not horiz))
		ki += 1


func _furn(k: String, center: Vector2, world: Node2D, rotated := false) -> Rect2:
	var f: Array = FURN[k]
	var sz := Vector2(f[1], f[0]) if rotated else Vector2(f[0], f[1])
	var r := Rect2(center - sz / 2, sz)
	var pts := _rect_poly(r)
	_add_solid(pts, true, f[5])
	var pr = _mkprop()
	pr.setup(pts, f[2], f[3], f[4])
	world.add_child(pr)
	return r


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
	var vs := {"ground": ground_tiles, "nodes": [], "occ": occluders, "walls": {}, "roof_nodes": {}}
	for e in man.get("objects", []):
		var spr := _art_sprite(obj_pages[int(e.get("page", 0))], e)
		spr.set_meta("static_z", true)
		world.add_child(spr)
		vs["nodes"].append(spr)
		occluders.append([_world_rect(e), float(e["base"][3]), spr])
		if e["kind"] == "wall":
			var a = _areas[int(e["building"])]
			a.wall_nodes.append(spr)
			if not vs["walls"].has(int(e["building"])):
				vs["walls"][int(e["building"])] = []
			vs["walls"][int(e["building"])].append(spr)
	for e in man.get("roofs", []):
		var spr := _art_sprite(roof_pages[int(e.get("page", 0))], e)
		roofs.add_child(spr)
		vs["nodes"].append(spr)
		occluders.append([_world_rect(e), INF, spr])
		_areas[int(e["building"])].roof_node = spr
		vs["roof_nodes"][int(e["building"])] = spr
	_views[0] = vs


# ---------------- 4 yonlu bakis ----------------
func to_view(p: Vector2, k := -1) -> Vector2:
	## dunya -> k. acinin ekran koordinati (Blender'daki view_xy ile ayni)
	if k < 0:
		k = view
	var c := size * 0.5
	var c2 := Vector2(size.y, size.x) * 0.5 if k % 2 == 1 else c
	return (p - c).rotated(-k * PI / 2.0) + c2


func from_view(v: Vector2, k := -1) -> Vector2:
	if k < 0:
		k = view
	var c := size * 0.5
	var c2 := Vector2(size.y, size.x) * 0.5 if k % 2 == 1 else c
	return (v - c2).rotated(k * PI / 2.0) + c


func has_view(k: int) -> bool:
	if not art:
		return k == 0
	return k == 0 or FileAccess.file_exists(art_dir + "v%d/manifest.json" % k)


static func zkey(view_y: float) -> int:
	## Y-Sort yerine z sirasi (donuk acilarda): -3000..3000
	return clampi(int(view_y * 0.4) - 1500, -3000, 3000)


func _load_view(k: int) -> Dictionary:
	var dir := art_dir + "v%d/" % k
	var man = JSON.parse_string(FileAccess.get_file_as_string(dir + "manifest.json"))
	var vs := {"ground": [], "nodes": [], "occ": [], "walls": {}, "roof_nodes": {}}
	var rot := k * PI / 2.0
	var old_scale := art_scale
	art_scale = float(man.get("scale", 1.0))
	for g in man.get("ground", []):
		var r: Array = g["rect"]
		vs["ground"].append([load(dir + g["file"]), Rect2(r[0], r[1], r[2], r[3])])
	var obj_pages := _pages(dir, man, "objects")
	var roof_pages := _pages(dir, man, "roofs")
	for e in man.get("objects", []):
		var spr := _art_sprite(obj_pages[int(e.get("page", 0))], e)
		spr.position = from_view(spr.position, k)
		spr.rotation = rot
		spr.z_index = zkey(float(e["base"][3]))
		spr.set_meta("static_z", true)
		spr.visible = false
		_world.add_child(spr)
		vs["nodes"].append(spr)
		vs["occ"].append([_world_rect(e), float(e["base"][3]), spr])
		if e["kind"] == "wall":
			var bi := int(e["building"])
			if not vs["walls"].has(bi):
				vs["walls"][bi] = []
			vs["walls"][bi].append(spr)
	for e in man.get("roofs", []):
		var spr := _art_sprite(roof_pages[int(e.get("page", 0))], e)
		spr.position = from_view(spr.position, k)
		spr.rotation = rot
		spr.visible = false
		_roofs.add_child(spr)
		vs["nodes"].append(spr)
		vs["occ"].append([_world_rect(e), INF, spr])
		vs["roof_nodes"][int(e["building"])] = spr
	art_scale = old_scale
	return vs


func set_view(k: int) -> bool:
	if not has_view(k):
		return false
	if not _views.has(k):
		_views[k] = _load_view(k)
	for kk in _views:
		for n in _views[kk]["nodes"]:
			n.visible = kk == k
	var vs: Dictionary = _views[k]
	view = k
	view_rot = k * PI / 2.0
	SpriteSheet.view_rot = view_rot
	ground_tiles = vs["ground"]
	occluders = vs["occ"]
	for bi in _areas.size():
		var a = _areas[bi]
		a.roof_node = vs["roof_nodes"].get(bi)
		a.wall_nodes = vs["walls"].get(bi, [])
	# donuk acida Y-Sort calismaz (yerel y'ye gore siralar): z sirasi kullan
	_world.y_sort_enabled = k == 0
	z_index = 0 if k == 0 else -4000
	_roofs.z_index = 10 if k == 0 else 3500
	for ch in _world.get_children():
		if ch.has_method("view_changed"):
			ch.view_changed()
		if k == 0 and not ch.has_meta("static_z"):
			ch.z_index = 0
	update_z()
	queue_redraw()
	return true


func update_z() -> void:
	## donuk acida hareket eden her seyin z sirasi (her kare)
	if view == 0:
		return
	for ch in _world.get_children():
		if ch.has_meta("static_z"):
			continue
		if ch.has_method("view_base"):
			ch.z_index = zkey(ch.view_base())
		else:
			ch.z_index = zkey(to_view(ch.position).y)


func ground_tiles0() -> Array:
	return _views[0]["ground"] if _views.has(0) else ground_tiles


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
	var head := to_view(p) + Vector2(0, -22)
	for o in occluders:
		var rect: Rect2 = o[0]
		if not rect.has_point(head):
			continue
		if o[1] > head.y + 22.0 and o[2].modulate.a > 0.5:
			return true
	return false


func _add_solid(pts: PackedVector2Array, blocks_move: bool, blocks_view: bool) -> void:
	if blocks_view:
		_add_view_poly(pts, not blocks_move)     # calilik: yakindan gorulebilir
	if blocks_move:
		move_polys.append(pts)
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var cp := CollisionPolygon2D.new()
		cp.polygon = pts
		body.add_child(cp)
		add_child(body)


func _add_view_poly(pts: PackedVector2Array, soft := false) -> void:
	for i in pts.size():
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		var bb := Rect2(a, Vector2.ZERO).expand(b)
		view_segments.append([a, b, bb, soft])


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
	# buyuk haritada cok yakin kose noktalari ayni hucreye dusup "merge edge" hatasi veriyordu:
	# birlestirme izgarasini incelt (2D harita 4.3'te 3D sunucunun haritasidir)
	NavigationServer3D.map_set_merge_rasterizer_cell_scale(get_world_2d().navigation_map, 0.001)
	var src := NavigationMeshSourceGeometryData2D.new()
	src.add_traversable_outline(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]))
	for it in interiors:
		src.add_traversable_outline(_rect_poly(it["irect"].grow(-IWALL - 1.0)))
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
	changed_map.emit()


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


func ray_end(from: Vector2, to: Vector2, ignore_soft := false) -> Vector2:
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
				if ignore_soft and s[3]:
					continue
				if not ray_bb.intersects(s[2], true):
					continue
				var hit = Geometry2D.segment_intersects_segment(from, to, s[0], s[1])
				if hit != null:
					var d: float = from.distance_to(hit)
					if d < best_d:
						best_d = d
						best = hit
	return best


func has_los(a: Vector2, b: Vector2, ignore_soft := false) -> bool:
	return ray_end(a, b, ignore_soft).distance_to(b) < 1.0


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


func speed_mul(p: Vector2) -> float:
	## derin kar / camur: yavaslatir
	for s in surfaces:
		if s["slow"] < 1.0 and Geometry2D.is_point_in_polygon(p, s["points"]):
			return s["slow"]
	return 1.0


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
	if siren_on > 0.0:
		siren_on -= delta
		_redraw_t = minf(_redraw_t, 0.12)
	if _redraw_t <= 0.0:
		_redraw_t = 0.25
		queue_redraw()


# ---------------- Zemin cizimi ----------------
func _draw() -> void:
	var font := ThemeDB.fallback_font
	for it in interiors:
		var ir: Rect2 = it["irect"]
		draw_rect(ir, Color(0.44, 0.32, 0.2))
		var yy: float = ir.position.y + 18.0
		var k := 0
		while yy < ir.end.y:
			draw_line(Vector2(ir.position.x, yy), Vector2(ir.end.x, yy), Color(0.36, 0.25, 0.15), 2.0)
			var xx: float = ir.position.x + fmod(k * 53.0, 120.0)
			while xx < ir.end.x:
				draw_line(Vector2(xx, yy - 18), Vector2(xx, yy), Color(0.38, 0.27, 0.17), 1.0)
				xx += 120.0
			yy += 18.0
			k += 1
		var rug := Rect2(ir.get_center() - ir.size * 0.18, ir.size * 0.36)
		draw_rect(rug, Color(0.45, 0.14, 0.12, 0.85))
		draw_rect(rug.grow(-8), Color(0.62, 0.48, 0.2, 0.6), false, 3.0)
		draw_string(ThemeDB.fallback_font, ir.position + Vector2(24, -14), it["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.85, 0.8, 0.6))
	if not ground_tiles.is_empty():
		if view != 0:
			# acinin zemini kendi (donuk) koordinatinda: dunyaya cevir
			var c := size * 0.5
			var c2 := Vector2(size.y, size.x) * 0.5 if view % 2 == 1 else c
			draw_set_transform(c - c2.rotated(view_rot), view_rot)
		for t in ground_tiles:
			draw_texture_rect(t[0], t[1], false)
		draw_set_transform(Vector2.ZERO, 0.0)
	elif ground_tex != null:
		draw_texture(ground_tex, Vector2.ZERO)
	else:
		_draw_plain_ground()
	_draw_overlays(font)


func _draw_plain_ground() -> void:
	var gcol := Color(0.36, 0.45, 0.26)
	match data.get("theme", ""):
		"kar": gcol = Color(0.8, 0.83, 0.88)
		"liman": gcol = Color(0.38, 0.42, 0.32)
	draw_rect(Rect2(Vector2.ZERO, size), gcol)
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
		if pk["type"] == "key":
			_draw_key(pp)
		elif pk["type"] == "item":
			draw_rect(Rect2(pp - Vector2(10, 6), Vector2(20, 12)), Color(0.55, 0.15, 0.1))
			draw_rect(Rect2(pp - Vector2(10, 6), Vector2(20, 12)), Color(1, 0.8, 0.3), false, 1.5)
			draw_line(pp + Vector2(6, -6), pp + Vector2(12, -14), Color(0.9, 0.9, 0.8), 1.5)
		elif pk["type"] == "medkit":
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
	# calinacak esyalar (belge, planlar, anahtar, kodlar...): gorev listesinden
	var m = get_parent().get("mission")
	if m != null:
		for o in m.objectives:
			if o["type"] != "take" or o["done"] or not o.has("pos"):
				continue
			var dp := _v(o["pos"])
			if "anahtar" in str(o.get("item", "")):
				_draw_key(dp)
			else:
				draw_rect(Rect2(dp - Vector2(12, 9), Vector2(24, 18)), Color(1, 0.9, 0.3))
				draw_rect(Rect2(dp - Vector2(12, 9), Vector2(24, 18)), Color(0.4, 0.3, 0), false, 2.0)
	elif not document_taken:
		draw_rect(Rect2(document_pos - Vector2(12, 9), Vector2(24, 18)), Color(1, 0.9, 0.3))
	# alarm sirenleri: direk + kirmizi lamba (calinca yanip soner)
	var blink: bool = siren_on > 0.0 and int(Time.get_ticks_msec() / 250) % 2 == 0
	for sp in sirens:
		# direk her bakis acisinda ekranda dik durur (4 yonlu kamera)
		draw_set_transform(sp, view_rot, Vector2.ONE)
		draw_rect(Rect2(Vector2(-3, -46), Vector2(6, 46)), Color(0.25, 0.25, 0.27))
		draw_rect(Rect2(Vector2(-11, -58), Vector2(22, 14)), Color(0.3, 0.3, 0.32))
		draw_circle(Vector2(0, -51), 6.0, Color(1, 0.15, 0.1) if blink else Color(0.45, 0.08, 0.06))
		if blink:
			draw_circle(Vector2(0, -51), 26.0, Color(1, 0.2, 0.1, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# kilitli kapilar: asma kilit
	for it in interiors:
		if it["locked"] != "" and not (m != null and m.items.has(it["locked"])):
			var dp2: Vector2 = it["ext_door"] - it["out"] * 20.0
			draw_rect(Rect2(dp2 - Vector2(7, 3), Vector2(14, 11)), Color(0.75, 0.6, 0.2))
			draw_arc(dp2 + Vector2(0, -3), 5.0, PI, TAU, 8, Color(0.6, 0.6, 0.62), 2.0)


func _draw_key(p: Vector2) -> void:
	draw_circle(p + Vector2(-6, 0), 5.0, Color(1, 0.85, 0.2))
	draw_circle(p + Vector2(-6, 0), 2.0, Color(0.3, 0.25, 0.1))
	draw_rect(Rect2(p + Vector2(-2, -1.5), Vector2(12, 3)), Color(1, 0.85, 0.2))
	draw_rect(Rect2(p + Vector2(7, 0), Vector2(3, 5)), Color(1, 0.85, 0.2))


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


func _mkprop():
	var p = Prop.new()
	p.lvl = self
	return p
