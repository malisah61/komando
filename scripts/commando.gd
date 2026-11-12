extends CharacterBody2D
## Oyuncu komandosu (Yesil Bere).
## Silahlar: bicak (sessiz, aninda) ve tabanca (mermi, ses yapar). Secilen silah degistirilene kadar kalir.
## Can, sağlik cantasi, comelme, ceset tasima.

const SpriteSheet = preload("res://scripts/sprite_sheet.gd")
const Fx = preload("res://scripts/fx.gd")
# once elle eklenen sheet, yoksa Blender'da render edilen
const SHEETS := ["res://assets/sprites/commandos_sprite_sheet.png", "res://assets/sprites/komando_sprite_sheet.png"]

const PISTOL_RANGE := 270.0
const PISTOL_DMG := 40.0
const PISTOL_COOLDOWN := 0.55
const PISTOL_NOISE := 420.0

@export var speed: float = 120.0

var main
var navigation_agent: NavigationAgent2D
var facing := 0.0
var alive := true
var target_guard = null
var _repath := 0.0
var _step := 0.0
var sprite: AnimatedSprite2D      # sprite sheet varsa dolu, yoksa sekillerle cizilir
var run := false                  # HUD'daki Kos dugmesi
var run_once := false             # cift dokunus: bu hareket icin kos
var crouch := false               # HUD'daki Comel dugmesi
const KNIFE_FRONT_DMG := 35.0
var weapon := "knife"             # "knife" / "pistol" - secim kalicidir
var ammo := 12
var medkits := 1
var stones := 4
var _slow := 1.0                 # derin kar
var _slow_t := 0.0                  # atilabilir tas (dikkat dagitma)
const THROW_RANGE := 320.0
const STONE_NOISE := 200.0
var hp := 100.0
var max_hp := 100.0
var carrying = null               # tasinan ceset
# Tur 3
var disguise := ""                # giyilen Alman uniformasi (er/kis): erler uzaktan fark etmez
var ropes := 3                    # bayilan askeri baglamak icin ip
var _whistle_cd := 0.0
const WHISTLE_CD := 5.0
var _cool := 0.0
var _hurt_t := 0.0
var ghost: AnimatedSprite2D       # bina/agac arkasindayken gorunen silüet (Commandos gibi)

const GHOST_SHADER := """
shader_type canvas_item;
uniform vec4 tint : source_color = vec4(0.45, 1.0, 0.45, 0.6);
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = vec4(tint.rgb, step(0.8, c.a) * tint.a);
}
"""


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 9.0
	shape.shape = c
	add_child(shape)
	navigation_agent = NavigationAgent2D.new()
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0
	navigation_agent.radius = 10.0
	add_child(navigation_agent)
	for path in SHEETS:
		if ResourceLoader.exists(path):
			sprite = SpriteSheet.attach(self, path)
			break
	if sprite != null:
		ghost = AnimatedSprite2D.new()
		ghost.sprite_frames = sprite.sprite_frames
		ghost.scale = sprite.scale
		ghost.offset = sprite.offset
		ghost.texture_filter = sprite.texture_filter
		ghost.z_index = 15
		var sh := Shader.new()
		sh.code = GHOST_SHADER
		var m := ShaderMaterial.new()
		m.shader = sh
		ghost.material = m
		ghost.visible = false
		add_child(ghost)


func nav_ready() -> bool:
	return NavigationServer2D.map_get_iteration_id(navigation_agent.get_navigation_map()) > 0


func is_crouching() -> bool:
	return crouch and not run_once


func move_to(p: Vector2) -> void:
	target_guard = null
	run_once = false
	navigation_agent.target_position = p


func attack(g) -> void:
	if carrying != null:
		return
	target_guard = g
	if weapon != "pistol" or global_position.distance_to(g.global_position) > PISTOL_RANGE:
		navigation_agent.target_position = g.global_position
	else:
		navigation_agent.target_position = global_position


func cur_speed() -> float:
	var s := speed
	if run_once:
		s *= 1.6
	elif crouch:
		s *= 0.55
	elif run:
		s *= 1.6
	if carrying != null:
		s *= 0.6
	return s * _slow


func _physics_process(delta: float) -> void:
	_cool -= delta
	_whistle_cd -= delta
	_hurt_t -= delta
	if not alive or main.game_over or not nav_ready():
		velocity = Vector2.ZERO
		queue_redraw()
		return
	if target_guard != null:
		_attack_step(delta)

	if navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		run_once = false
		_play(&"idle")
		_carry_follow()
		queue_redraw()
		return

	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var direction: Vector2 = global_position.direction_to(next_path_position)
	velocity = direction * cur_speed()
	_play(&"walk")
	facing = lerp_angle(facing, direction.angle(), minf(1.0, delta * 12.0))
	var before := global_position
	_slow_t -= delta
	if _slow_t <= 0.0:
		_slow_t = 0.2
		_slow = main.level.speed_mul(global_position)
	move_and_slide()
	_carry_follow()

	# camurda ayak izi
	_step += before.distance_to(global_position)
	if _step > 22.0:
		_step = 0.0
		if main.level.leaves_footprints(global_position):
			main.level.add_footprint(global_position, facing)
	queue_redraw()


func _attack_step(delta: float) -> void:
	var g = target_guard
	if not g.alive:
		target_guard = null
		navigation_agent.target_position = global_position
		return
	var d := global_position.distance_to(g.global_position)
	if weapon == "knife" or weapon == "fist":
		if d < 30.0:
			# onden ve tetikteyken tek darbede olmez: yaralar, catisma baslar
			var to_me: Vector2 = global_position - g.global_position
			var facing_me: bool = absf(wrapf(to_me.angle() - g.facing, -PI, PI)) < 1.2
			if g.state == &"combat" and facing_me:
				g.take_damage(KNIFE_FRONT_DMG if weapon == "knife" else 12.0, global_position)
				_cool = 0.6
			elif weapon == "fist":
				g.knock_out()                 # bayilt: oldurmez, ~40 sn sonra ayilir (bagla!)
				main.stats["knockouts"] = main.stats.get("knockouts", 0) + 1
			else:
				g.kill()
			main.scuffle(g.global_position, self)
			target_guard = null
			_play(&"action", true)
			navigation_agent.target_position = global_position
		else:
			_repath -= delta
			if _repath <= 0.0:
				_repath = 0.25
				navigation_agent.target_position = g.global_position
		return
	# tabanca: menzilde ve goruyorsa dur ve ates et
	if d <= PISTOL_RANGE and main.level.has_los(global_position, g.global_position):
		navigation_agent.target_position = global_position
		facing = (g.global_position - global_position).angle()
		if _cool <= 0.0:
			if ammo <= 0:
				main.hud.toast("Mermi bitti!")
				target_guard = null
				return
			ammo -= 1
			_cool = PISTOL_COOLDOWN
			_play(&"shoot", true)
			var acc := clampf(0.95 - d / 900.0, 0.5, 0.95)
			if main.level.in_cover(g.global_position, global_position):
				acc *= 0.6          # asker siperde
			var hit := randf() < acc
			var aim: Vector2 = g.global_position + Vector2(0, -16)
			if not hit:
				aim += Vector2(randf_range(-28, 28), randf_range(-28, 28))
			Fx.tracer(main.world, global_position + Vector2(0, -18), aim)
			main.make_noise(global_position, PISTOL_NOISE, self)
			blow_disguise()
			if hit:
				g.take_damage(PISTOL_DMG * randf_range(0.85, 1.15), global_position)
			main.hud.refresh_items()
	else:
		_repath -= delta
		if _repath <= 0.0:
			_repath = 0.3
			navigation_agent.target_position = g.global_position


func take_damage(amount: float, _from: Vector2) -> void:
	if not alive:
		return
	hp -= amount
	_hurt_t = 0.25
	Fx.blood(main.world, global_position + Vector2(0, -16))
	if hp <= 0.0:
		hp = 0.0
		alive = false
		drop_body()
		_play(&"death", true)
		main.lose("Çvş. Reilly vuruldu!")


func throw_stone(p: Vector2) -> bool:
	## tasi at: dustugu yerin cevresindeki askerler alarm vermeden bakmaya gider
	if stones <= 0 or not alive:
		return false
	if main.level.interior_at(p) != main.level.interior_at(global_position):
		return false
	var to := p
	if to.distance_to(global_position) > THROW_RANGE:
		to = global_position + (p - global_position).normalized() * THROW_RANGE
	to = main.level.ray_end(global_position, to).move_toward(global_position, 6.0)
	stones -= 1
	facing = (to - global_position).angle()
	_play(&"action", true)
	Fx.stone(main.world, global_position + Vector2(0, -20), to)
	main.hud.refresh_items()
	get_tree().create_timer(0.45, false).timeout.connect(func(): main.distract(to, STONE_NOISE))
	return true


func do_whistle() -> void:
	## islik: 190 px icindeki askerler sesin geldigi yere bakmaya gelir
	if _whistle_cd > 0.0 or not alive:
		main.hud.toast("Islık için bekle (%d sn)" % ceili(maxf(_whistle_cd, 0.0)))
		return
	_whistle_cd = WHISTLE_CD
	var n: int = main.whistle(global_position)
	main.hud.toast("Islık çaldın: %d asker geliyor" % n if n > 0 else "Islık çaldın (yakında asker yok)")


func put_on_uniform(g) -> void:
	## Commandos 2: olu/bayilan erin uniformasini giy. Erler uzaktan fark etmez; SS ve subay tanir.
	if g == null or g.stripped or g.kind == "elit" or g.kind == "subay" or g.kind == "kule":
		return
	g.stripped = true
	disguise = g.kind
	_set_outfit("res://assets/sprites/alman_%s_sprite_sheet.png" % g.kind)
	main.stats["disguises"] = main.stats.get("disguises", 0) + 1
	main.hud.toast("Üniformayı giydin: erler seni uzaktan tanımaz (SS ve subaylara dikkat!)")


func blow_disguise() -> void:
	if disguise == "":
		return
	disguise = ""
	for path in SHEETS:
		if ResourceLoader.exists(path):
			_set_outfit(path)
			break
	main.hud.toast("Kılığın açığa çıktı!")


func _set_outfit(path: String) -> void:
	if sprite == null or not ResourceLoader.exists(path):
		return
	var tmp: AnimatedSprite2D = SpriteSheet.attach(self, path)
	if tmp == null:
		return
	sprite.sprite_frames = tmp.sprite_frames
	if ghost != null:
		ghost.sprite_frames = tmp.sprite_frames
	remove_child(tmp)
	tmp.queue_free()


func tie_up(g) -> void:
	if g == null or not g.knocked or g.tied or ropes <= 0:
		return
	ropes -= 1
	g.tied = true
	g.queue_redraw()
	main.hud.toast("Asker bağlandı (kalan ip: %d)" % ropes)


func use_medkit() -> void:
	if medkits <= 0 or hp >= max_hp or not alive:
		return
	medkits -= 1
	hp = minf(max_hp, hp + 50.0)
	Fx.heal(main.world, global_position)
	main.hud.refresh_items()


# ---------------- Ceset tasima ----------------
func body_nearby():
	for g in get_tree().get_nodes_in_group("guards"):
		if not g.alive and not g.carried and g.global_position.distance_to(global_position) < 36.0:
			return g
	return null


func pick_body(g) -> void:
	carrying = g
	g.carried = true
	g.hidden_body = false
	target_guard = null


func drop_body() -> void:
	if carrying == null:
		return
	var g = carrying
	carrying = null
	g.carried = false
	g.global_position = global_position + Vector2.from_angle(facing + PI) * 14.0
	# calilikta birakilan ceset gorulmez
	g.hidden_body = main.level.is_inside_view_blocker(g.global_position)


func _carry_follow() -> void:
	if carrying != null:
		carrying.global_position = global_position + Vector2.from_angle(facing + PI) * 16.0


# ---------------- Animasyon ----------------
func _play(anim: StringName, force := false) -> void:
	if sprite == null:
		return
	# tek seferlik animasyon (bicak/ates) bitene kadar bozma
	var cur := SpriteSheet.base_anim(sprite)
	if not force and (cur == "action" or cur == "shoot") and sprite.is_playing():
		return
	if anim == &"walk":
		if run_once:
			anim = &"run"
		elif crouch and sprite.sprite_frames.has_animation(&"crouch_0"):
			anim = &"crouch"
		elif run:
			anim = &"run"
	elif anim == &"idle" and is_crouching() and sprite.sprite_frames.has_animation(&"crouch_0"):
		anim = &"crouch"
		SpriteSheet.play(sprite, anim, facing, force)
		sprite.pause()
		return
	SpriteSheet.play(sprite, anim, facing, force)


func _process(_delta: float) -> void:
	if ghost == null:
		return
	ghost.visible = alive and main.level.is_occluded(global_position)
	if ghost.visible:
		if ghost.animation != sprite.animation:
			ghost.animation = sprite.animation
		ghost.frame = sprite.frame
		ghost.flip_h = sprite.flip_h


func is_hidden() -> bool:
	return main.level.is_inside_view_blocker(global_position)


func _draw() -> void:
	# hedef yolu
	if alive and nav_ready() and not navigation_agent.is_navigation_finished():
		var pts := navigation_agent.get_current_navigation_path()
		var idx := navigation_agent.get_current_navigation_path_index()
		for i in range(idx, pts.size()):
			draw_circle(pts[i] - global_position, 2.5, Color(1, 1, 1, 0.5))
		if pts.size() > 0:
			draw_arc(pts[pts.size() - 1] - global_position, 9, 0, TAU, 20, Color(1, 1, 1, 0.7), 2.0)
	# tabanca menzili (secili ve hedef varken)
	if alive and weapon == "pistol" and target_guard != null:
		draw_arc(Vector2.ZERO, PISTOL_RANGE, 0, TAU, 64, Color(1, 0.8, 0.3, 0.25), 1.5)
	# golge + secim halkasi
	draw_set_transform(Vector2.ZERO, SpriteSheet.view_rot, Vector2(1, 0.5))
	if sprite == null:
		draw_circle(Vector2.ZERO, 12, Color(0, 0, 0, 0.35))
	draw_arc(Vector2.ZERO, 18, 0, TAU, 28, Color(0.4, 1, 0.4, 0.9), 2.5)
	draw_set_transform(Vector2.ZERO, SpriteSheet.view_rot, Vector2.ONE)
	# can cubugu (hasar aldiysa)
	if alive and hp < max_hp:
		draw_rect(Rect2(-16, -62, 32, 4), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-16, -62, 32 * hp / max_hp, 4), Color(0.3, 0.9, 0.3))
	if sprite != null:
		var col := Color.WHITE
		if not alive:
			col = Color(1, 0.6, 0.6)
		elif _hurt_t > 0.0:
			col = Color(1, 0.4, 0.4)
		elif is_hidden():
			col = Color(1, 1, 1, 0.6)
		sprite.modulate = col
		if is_hidden():
			draw_string(ThemeDB.fallback_font, Vector2(-22, -48), "gizli", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 1, 0.7))
		elif crouch:
			draw_string(ThemeDB.fallback_font, Vector2(-26, -48), "çömelik", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.9, 1))
		return
	# govde (ayaklar orijinde, govde yukarida)
	var body := Vector2(0, -12)
	var bc := Color(0.3, 0.42, 0.2) if alive else Color(0.55, 0.2, 0.2)
	draw_circle(body, 11, Color(0.08, 0.1, 0.06))
	draw_circle(body, 9.5, bc)
	draw_circle(body + Vector2.from_angle(facing) * 3 + Vector2(0, -3), 6, Color(0.12, 0.38, 0.12))  # yesil bere
	draw_line(body, body + Vector2.from_angle(facing - 0.5) * 15, Color(0.85, 0.85, 0.9), 2.0)         # bicak
	if is_hidden():
		draw_string(ThemeDB.fallback_font, Vector2(-22, -30), "gizli", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 1, 0.7))
