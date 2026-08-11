extends Control
class_name LightMenu

## 등불에서 뻗어 나온 빛줄기 끝에 선택지가 붙는 메뉴.
##
## 상자에 담긴 버튼을 쓰지 않는 이유는 이 게임의 규칙 때문이다 - 화면에서 색을 가진 것은
## 등불뿐이라, UI에 회색 상자를 늘어놓으면 그 규칙이 깨진다. **메뉴 자체가 빛이면** UI가
## 설정의 일부가 되고, 등불이 약해질 때 메뉴도 같이 흐려진다.
##
## 다만 완전히 사라지게 두지는 않는다(`MIN_TEXT_ALPHA`). 암흑에서도 뭘 고를 수 있는지는
## 보여야 게임이 된다 - 안 보이는 것은 **적**이지 내 손이 아니다.

signal chosen(index: int)

const ORIGIN := Vector2(480, 453)   ## 빛이 나오는 자리. 화면 아래 가운데, 내가 등불을 든 위치다.

## 빛줄기는 **가는 선이 아니라 짧은 원뿔**이다. 꼭짓점이 등불이고 밖으로 갈수록 넓어지면서
## 스러진다. 선으로 그리면 길쭉한 형광등에서 나온 것처럼 보이는데, 등불은 그렇게 안 비친다.
##
## 그리고 **글자는 빛 끝에 매달리는 게 아니라 빛 안에 잠겨 있다.** 그래서 원뿔이 글자를 지나쳐
## 더 뻗고, 글자는 빛이 아직 진한 자리에 놓인다.
const APEX_INSET := 8.0          ## 꼭짓점을 등불 중심에서 살짝 띄운다 - 한 점에 모이면 뾰족해 보인다
const CONE_HALF_WIDTH := 81.0    ## 맨 끝에서의 반너비. 글자를 품어야 해서 넓다
const CONE_OVERSHOOT := 1.65     ## 글자 자리보다 이만큼 더 뻗는다
const CONE_OVERSHOOT_PICKED := 1.9
const CONE_FALLOFF_AT := 0.72    ## 이 지점까지는 밝기를 지키고, 그 뒤로 스러진다
const MIN_TEXT_ALPHA := 0.34

var light: float = 1.0:  ## 등불 밝기(0~1). 빛줄기의 진하기를 정한다.
	set(value):
		light = clampf(value, 0.0, 1.0)
		_refresh_labels()
		queue_redraw()

var enabled: bool = true:
	set(value):
		enabled = value
		_refresh_labels()
		queue_redraw()

var _index: int = 0
var _anchors: Array[Vector2] = []
var _labels: Array[Label] = []


## 빛의 색. 체력이 깎일수록 붉어진다 - `BattleScreen`이 매 턴 갈아 끼운다.
var colour: Color = UiStyle.LAMP:
	set(value):
		colour = value
		_refresh_labels()
		queue_redraw()


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 빛도 배경과 같은 디더 격자로 흩어지게 한다(더하기 합성도 셰이더가 맡는다).
	var dithered := ShaderMaterial.new()
	dithered.shader = load("res://shaders/DitherLight.gdshader")
	material = dithered


## options: [{ "text": String, "anchor": Vector2 }, ...]
## anchor는 빛줄기가 끝나는 자리이자 글자가 붙는 자리다. 화면 왼쪽이면 글자가 왼쪽으로,
## 오른쪽이면 오른쪽으로 뻗는다.
func setup(options: Array) -> void:
	for label in _labels:
		label.queue_free()
	_labels.clear()
	_anchors.clear()

	for i in options.size():
		var anchor: Vector2 = options[i]["anchor"]
		_anchors.append(anchor)

		var label := Label.new()
		label.text = options[i]["text"]
		KoreanFont.apply(label)
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.mouse_entered.connect(_on_hover.bind(i))
		label.gui_input.connect(_on_label_input.bind(i))
		add_child(label)
		_labels.append(label)
		# 글자 크기가 잡힌 뒤에 자리를 잡아야 해서 한 프레임 미룬다.
		label.resized.connect(_place_label.bind(i))
		_place_label(i)

	_refresh_labels()
	queue_redraw()


## anchor는 글자가 **놓이는 자리**다. 빛은 이 자리를 지나 더 뻗어나가므로 글자가 빛 안에 잠긴다.
func _place_label(i: int) -> void:
	var label := _labels[i]
	label.position = _anchors[i] - label.get_minimum_size() * 0.5


func _draw() -> void:
	var alpha := light if enabled else light * 0.4
	for i in _anchors.size():
		var selected := i == _index and enabled
		_draw_cone(_anchors[i], (0.72 if selected else 0.26) * alpha, selected)


## 등불에서 나가는 빛 한 줄기. 두 토막으로 그린다 - 글자가 놓이는 데까지는 밝기를 지키고,
## 그 뒤로 스러진다. 한 토막으로 그리면 글자 자리에서 이미 빛이 다 죽어서 글자가 어둠에
## 뜬 것처럼 보인다(`draw_polygon`이 꼭짓점 색을 섞어준다).
func _draw_cone(anchor: Vector2, strength: float, picked: bool) -> void:
	var direction := (anchor - ORIGIN).normalized()
	var across := Vector2(-direction.y, direction.x)
	var reach := ORIGIN.distance_to(anchor) * (CONE_OVERSHOOT_PICKED if picked else CONE_OVERSHOOT)
	var apex := ORIGIN + direction * APEX_INSET
	var hold := ORIGIN + direction * (reach * CONE_FALLOFF_AT)
	var tip := ORIGIN + direction * reach
	var hold_half := CONE_HALF_WIDTH * CONE_FALLOFF_AT

	var beam := colour
	var core := Color(beam.r, beam.g, beam.b, strength)
	var held := Color(beam.r, beam.g, beam.b, strength * 0.85)
	var faded := Color(beam.r, beam.g, beam.b, 0.0)

	draw_polygon(
		PackedVector2Array([apex, hold + across * hold_half, hold - across * hold_half]),
		PackedColorArray([core, held, held])
	)
	draw_polygon(
		PackedVector2Array([
			hold + across * hold_half,
			tip + across * CONE_HALF_WIDTH,
			tip - across * CONE_HALF_WIDTH,
			hold - across * hold_half,
		]),
		PackedColorArray([held, faded, faded, held])
	)


func _refresh_labels() -> void:
	for i in _labels.size():
		var selected := i == _index and enabled
		var ink := colour if selected else UiStyle.TEXT
		var alpha := maxf(light, MIN_TEXT_ALPHA)
		if not enabled:
			alpha *= 0.5
		_labels[i].add_theme_color_override("font_color", Color(ink.r, ink.g, ink.b, alpha))


func _unhandled_input(event: InputEvent) -> void:
	if not enabled or _anchors.is_empty():
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_UP, KEY_LEFT:
			_move(-1)
		KEY_DOWN, KEY_RIGHT:
			_move(1)
		KEY_ENTER, KEY_SPACE, KEY_KP_ENTER:
			chosen.emit(_index)
		_:
			return
	get_viewport().set_input_as_handled()


func _move(delta: int) -> void:
	_index = wrapi(_index + delta, 0, _anchors.size())
	_refresh_labels()
	queue_redraw()


func _on_hover(index: int) -> void:
	if not enabled:
		return
	_index = index
	_refresh_labels()
	queue_redraw()


func _on_label_input(event: InputEvent, index: int) -> void:
	if not enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_index = index
		chosen.emit(index)
