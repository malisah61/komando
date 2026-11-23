extends ScrollContainer
## Tur 9: parmakla / fareyle surukleyerek kaydirilan liste (bolum secimi, kayit, brifing, yenilikler).
## Godot'nun kendi ScrollContainer'i dugmelerin USTUNDEN surukleyince kaymaz (dugme olayi yutar) ve PC'de
## fareyle surukleme yoktur. Bu sinif olaylari _input'ta (dugmelerden once) izler:
##  - 12 px'ten fazla suruklenirse liste kayar ve `moved` true olur; dugme geri cagrilari `moved` ise
##    tiklamayi yok sayar (kaydirirken yanlislikla bolum secilmez),
##  - fare tekerlegi ve kaydirma cubugu ScrollContainer'in kendisinde zaten calisir,
##  - birakinca kisa bir atalet (savurma) ile yavaslayarak durur.

const DEADZONE := 12.0
var moved := false
var _down := false
var _start := Vector2.ZERO
var _last_y := 0.0
var _vel := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS          # menu acikken oyun duraklatilmis olur
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_deadzone = int(DEADZONE)


func _input(e: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			if get_global_rect().has_point(e.position):
				_down = true
				moved = false
				_start = e.position
				_last_y = e.position.y
				_vel = 0.0
		elif _down:
			_down = false
	elif e is InputEventMouseMotion and _down:
		if not moved and e.position.distance_to(_start) > DEADZONE:
			moved = true
		if moved:
			var dy: float = e.position.y - _last_y
			scroll_vertical = int(scroll_vertical - dy)
			_vel = -dy / maxf(get_process_delta_time(), 0.008)
			get_viewport().set_input_as_handled()     # dugme ve yerlesik surukleme ikinci kez kaydirmasin
		_last_y = e.position.y
	elif e is InputEventScreenDrag and moved:
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _down or absf(_vel) < 20.0:
		return
	scroll_vertical = int(scroll_vertical + _vel * delta)
	_vel *= pow(0.04, delta)              # ~1 sn'de durur


func tap_ok() -> bool:
	## dugme geri cagrisinda: kaydirma hareketi degil gercek dokunus mu
	return not moved
