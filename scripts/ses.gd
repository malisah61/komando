extends RefCounted
## Tur 6: kucuk sentez sesler (kodla uretilir: lisans sorunu yok, CC0 / kendi uretimimiz).
## "tirman": pencere pervazina tutunma + surtunme, "in": yere inis. Telefonda da hafif (ilk kullanimda bir kez uretilir).

static var _cache := {}


static func _make(kind: String) -> AudioStreamWAV:
	var rate := 22050
	var dur := 0.38 if kind == "tirman" else 0.22
	var n := int(rate * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 61 if kind == "tirman" else 62
	var lp := 0.0
	for i in n:
		var t := float(i) / rate
		var v := 0.0
		if kind == "tirman":
			# ahsap pervaz "tok" + kumas/tas surtunmesi
			var knock := sin(TAU * 180.0 * t) * exp(-t * 38.0)
			lp = lerp(lp, rng.randf_range(-1.0, 1.0), 0.18)
			var scrape := lp * (0.5 + 0.5 * sin(TAU * 7.0 * t)) * exp(-t * 4.0) * smoothstep(0.03, 0.08, t)
			v = knock * 0.7 + scrape * 0.55
		else:
			# yumusak inis: alcak tok ses + kisa toz
			lp = lerp(lp, rng.randf_range(-1.0, 1.0), 0.08)
			v = sin(TAU * 90.0 * t) * exp(-t * 30.0) * 0.8 + lp * exp(-t * 18.0) * 0.4
		var s16 := int(clampf(v, -1.0, 1.0) * 20000.0)
		data.encode_s16(i * 2, s16)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w


static func play(parent: Node, kind: String, pos: Vector2) -> void:
	if not _cache.has(kind):
		_cache[kind] = _make(kind)
	var p := AudioStreamPlayer2D.new()
	p.stream = _cache[kind]
	p.position = pos
	p.max_distance = 900.0
	p.volume_db = -6.0
	parent.add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
