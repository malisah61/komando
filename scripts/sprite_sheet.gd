extends RefCounted
## Disaridan eklenen sprite sheet'leri otomatik SpriteFrames'e cevirir.
##
## Varsayilan duzen (4x4 grid, her kare 32x32):
##   satir 0 -> idle    (4 kare, dongu)
##   satir 1 -> walk    (4 kare, dongu)
##   satir 2 -> action  (4 kare, tek sefer: bicak / ates)
##   satir 3 -> death   (4 kare, tek sefer)
## Farkli bir duzen icin ayni klasore ayni adla bir .json koy, ornek:
##   commandos_sprite_sheet.json -> {"frame": 32, "cols": 4, "fps": 8,
##       "anims": {"idle": [0], "walk": [1], "action": [2], "death": [3]}}
##   (dizi = satir numaralari; birden fazla satir verilirse arka arkaya eklenir)

const DEFAULT_LAYOUT := {
	"frame": 32,
	"cols": 4,
	"fps": 8,
	"anims": {"idle": [0], "walk": [1], "action": [2], "death": [3]},
	"loop": {"idle": true, "walk": true, "action": false, "death": false},
}


static func exists(path: String) -> bool:
	return ResourceLoader.exists(path)


static func build_frames(path: String) -> SpriteFrames:
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	if tex == null:
		return null
	var layout := DEFAULT_LAYOUT.duplicate(true)
	var json_path := path.get_basename() + ".json"
	if FileAccess.file_exists(json_path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(json_path))
		if typeof(parsed) == TYPE_DICTIONARY:
			layout.merge(parsed, true)
	var fs: int = int(layout["frame"])
	var cols: int = int(layout["cols"])
	var rows: int = int(tex.get_height() / fs)
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for anim_name in layout["anims"]:
		var anim := StringName(anim_name)
		frames.add_animation(anim)
		frames.set_animation_speed(anim, float(layout["fps"]))
		frames.set_animation_loop(anim, layout["loop"].get(anim_name, true))
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
	## tamamen saydam kareleri atla (4'ten az kareli satirlar icin)
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
	var frames := build_frames(path)
	if frames == null:
		return null
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = frames
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # piksel art keskin kalsin
	var fs := 32.0
	var first: Texture2D = null
	if frames.has_animation(&"idle") and frames.get_frame_count(&"idle") > 0:
		first = frames.get_frame_texture(&"idle", 0)
	if first:
		fs = first.get_height()
	var s := display_px / fs
	spr.scale = Vector2(s, s)
	spr.offset = Vector2(0, -fs * 0.5)
	owner.add_child(spr)
	if frames.has_animation(&"idle"):
		spr.play(&"idle")
	return spr
