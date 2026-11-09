extends RefCounted
## Sprite sheet'leri otomatik SpriteFrames'e cevirir. Iki duzeni destekler:
##
## 1) Basit grid (elle cizilen / disaridan eklenen):
##    4x4, 32px; satir 0 idle, 1 walk, 2 action, 3 death. Sola bakarken aynalanir.
##    Farkli duzen icin yanina ayni adla .json:
##    {"frame": 32, "cols": 4, "fps": 8, "anims": {"idle": [0], "walk": [1]}}
##
## 2) 8 yonlu (tools/blender/asker.py uretir):
##    {"frame": 128, "slot": 8, "slots_per_row": 2, "directions": 8, "pivot": [64, 80],
##     "anims": {"walk": {"slot": 8, "frames": 8, "fps": 10, "loop": true}, ...}}
##    Her animasyon icin "walk_0" ... "walk_7" olusur (0 = dogu, saat yonunde).

const DEFAULT_LAYOUT := {
	"frame": 32,
	"cols": 4,
	"fps": 8,
	"anims": {"idle": [0], "walk": [1], "action": [2], "death": [3]},
	"loop": {"idle": true, "walk": true, "action": false, "death": false},
}


static func load_layout(path: String) -> Dictionary:
	var layout := DEFAULT_LAYOUT.duplicate(true)
	var json_path := path.get_basename() + ".json"
	if FileAccess.file_exists(json_path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(json_path))
		if typeof(parsed) == TYPE_DICTIONARY:
			if parsed.has("anims"):
				layout.erase("anims")
			layout.merge(parsed, true)
	return layout


static func build_frames(path: String, layout: Dictionary) -> SpriteFrames:
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	if tex == null:
		return null
	var fs: int = int(layout["frame"])
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var dirs: int = int(layout.get("directions", 1))
	if dirs > 1:
		var slot_w: int = int(layout["slot"])
		var per_row: int = int(layout["slots_per_row"])
		for anim_name in layout["anims"]:
			var a: Dictionary = layout["anims"][anim_name]
			for d in dirs:
				var anim := StringName("%s_%d" % [anim_name, d])
				frames.add_animation(anim)
				frames.set_animation_speed(anim, float(a.get("fps", 10)))
				frames.set_animation_loop(anim, bool(a.get("loop", true)))
				var slot: int = int(a["slot"]) + d
				var row: int = slot / per_row
				var c0: int = (slot % per_row) * slot_w
				for i in int(a["frames"]):
					var at := AtlasTexture.new()
					at.atlas = tex
					at.region = Rect2((c0 + i) * fs, row * fs, fs, fs)
					frames.add_frame(anim, at)
		return frames
	# basit grid
	var cols: int = int(layout["cols"])
	var rows: int = int(tex.get_height() / fs)
	var loops: Dictionary = layout.get("loop", {})
	for anim_name in layout["anims"]:
		var anim := StringName(anim_name)
		frames.add_animation(anim)
		frames.set_animation_speed(anim, float(layout["fps"]))
		frames.set_animation_loop(anim, loops.get(anim_name, true))
		for row in layout["anims"][anim_name]:
			if int(row) >= rows:
				continue
			for col in cols:
				var at := AtlasTexture.new()
				at.atlas = tex
				at.region = Rect2(col * fs, int(row) * fs, fs, fs)
				if _is_empty(tex, at.region):
					continue
				frames.add_frame(anim, at)
	return frames


static func _is_empty(tex: Texture2D, region: Rect2) -> bool:
	var img := tex.get_image()
	if img == null:
		return false
	if img.is_compressed():
		img.decompress()
	var r := Rect2i(region)
	for y in range(r.position.y, r.end.y, 2):
		for x in range(r.position.x, r.end.x, 2):
			if img.get_pixel(x, y).a > 0.05:
				return false
	return true


static func attach(owner: Node2D, path: String, display_px: float = 44.0) -> AnimatedSprite2D:
	## Karaktere AnimatedSprite2D ekler; ayaklar karakterin orijininde durur.
	var layout := load_layout(path)
	var frames := build_frames(path, layout)
	if frames == null:
		return null
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = frames
	var fs := float(layout["frame"])
	var dirs: int = int(layout.get("directions", 1))
	spr.set_meta("directions", dirs)
	if layout.get("filter", "nearest") == "linear":
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	else:
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # piksel art keskin kalsin
	var s := float(layout.get("display_px", display_px)) / fs
	spr.scale = Vector2(s, s)
	if layout.has("pivot"):
		var pv: Array = layout["pivot"]
		spr.offset = Vector2(fs * 0.5 - float(pv[0]), fs * 0.5 - float(pv[1]))
	else:
		spr.offset = Vector2(0, -fs * 0.5)
	owner.add_child(spr)
	play(spr, &"idle", 0.0)
	return spr


static func dir_index(facing: float, dirs: int) -> int:
	return posmod(roundi(facing / (TAU / dirs)), dirs)


static func play(spr: AnimatedSprite2D, anim: StringName, facing: float, force := false) -> void:
	## Yonlu sheet'te "walk_3" gibi dogru yonu secer, basit sheet'te aynalar.
	if spr == null:
		return
	var dirs: int = spr.get_meta("directions", 1)
	var name := anim
	if dirs > 1:
		name = StringName("%s_%d" % [anim, dir_index(facing, dirs)])
	else:
		spr.flip_h = cos(facing) < 0.0
	if not spr.sprite_frames.has_animation(name):
		return
	if spr.animation == name and not force:
		return
	# ayni hareketin yonu degisirse kareyi koru (yururken donunce takilmasin)
	var keep := spr.frame if String(spr.animation).get_slice("_", 0) == String(anim) else 0
	spr.play(name)
	if not force and keep < spr.sprite_frames.get_frame_count(name):
		spr.frame = keep


static func base_anim(spr: AnimatedSprite2D) -> String:
	return String(spr.animation).get_slice("_", 0)
