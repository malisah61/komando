extends Node2D
## Tur 6: gercekci anahtar deligi / pencere bakisi. Kapinin (pencerenin) onunden disari dar bir koni
## (~40 derece, makul menzil) acik kalir; duvar ve engeller gorusu keser (Level.ray_end = has_los ile ayni),
## koninin disi ve gorusu kesilen yerler karanlik. Konideki askerler ve hareketleri canli gorunur.

const RAYS := 48
const DARK := Color(0.015, 0.012, 0.01, 0.96)
const FAR := 6000.0

var main
var from := Vector2.ZERO
var dir := 0.0
var half := 0.35
var rng := 520.0
var ends := PackedVector2Array()     # her isinin engele carptigi nokta
var _t := 0.0


func open(p: Vector2, d: float, h: float, r: float) -> void:
	from = p
	dir = d
	half = h
	rng = r
	visible = true
	_cast()


func close() -> void:
	visible = false


func lit(p: Vector2) -> bool:
	## bu nokta delikten gorunuyor mu? (test ve bot icin)
	if not visible:
		return false
	var d := p - from
	if d.length() > rng or absf(wrapf(d.angle() - dir, -PI, PI)) > half:
		return false
	return main.level.has_los(from, p)


func _cast() -> void:
	ends.clear()
	for i in RAYS + 1:
		var a := dir - half + half * 2.0 * float(i) / RAYS
		ends.append(main.level.ray_end(from, from + Vector2.from_angle(a) * rng))
	queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	_t -= delta
	if _t <= 0.0:
		_t = 0.5             # kapi kirilir / tel kesilir: arada bir yeniden hesapla
		_cast()


func _draw() -> void:
	if ends.is_empty():
		return
	# 1) koninin disi: kapinin onunden baslayip uzun yay boyunca donen tek cokgen
	var a0 := dir - half
	var a1 := dir + half
	var outer := PackedVector2Array([from])
	var steps := 24
	for k in steps + 1:
		var a := a1 + (TAU - half * 2.0) * float(k) / steps
		outer.append(from + Vector2.from_angle(a) * FAR)
	draw_colored_polygon(outer, DARK)
	# 2) koninin icinde engelin arkasi: her isin araliginda carpma noktasindan otesi karanlik
	for i in RAYS:
		var aa := a0 + half * 2.0 * float(i) / RAYS
		var ab := a0 + half * 2.0 * float(i + 1) / RAYS
		var q := PackedVector2Array([ends[i], from + Vector2.from_angle(aa) * FAR, from + Vector2.from_angle(ab) * FAR, ends[i + 1]])
		draw_colored_polygon(q, DARK)
	# 3) menzil sinirinda yumusak kenar
	for i in RAYS:
		draw_line(ends[i], ends[i + 1], Color(0, 0, 0, 0.35), 6.0)
