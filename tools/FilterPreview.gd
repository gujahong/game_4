# DitherFilter를 눈으로 맞추는 도구.
#
# 배경을 640x360 그대로 띄우고, 오른쪽 패널의 슬라이더로 필터 값을 돌린다.
# Space로 배경을 넘겨가며 같은 값이 여러 장에 다 통하는지 본다 - 통해야 화풍이 통일된다.
# 마음에 드는 값을 찾으면 그 숫자가 이 게임의 화풍이 된다.
extends Control

const IMAGE_DIR := "res://assets/photos"
const SHADER_PATH := "res://shaders/DitherFilter.gdshader"
# Godot 기본 폰트에는 한글이 없어서 시스템 폰트를 빌려온다.
const CAPTURE_PREFIX := "res://tools/_preview_"

const PANEL_WIDTH := 264  # 글자가 16px이라 라벨 한 줄이 다 들어가려면 이 정도는 필요하다
const FONT_SIZE := KoreanFont.NATIVE_SIZE

# 임시 등불. 인물이 설 만한 자리에 놓고 크기만 대충 맞춰뒀다.
const LAMP_POSITION := Vector2(330, 380)
const LAMP_SIZE := 192

# 슬라이더로 돌릴 값들. 여기 한 줄 넣으면 슬라이더가 는다.
const PARAMS := [
	{"label": "흑점", "uniform": "input_black", "min": 0.0, "max": 0.9, "step": 0.02, "value": 0.0},
	{"label": "백점", "uniform": "input_white", "min": 0.1, "max": 1.0, "step": 0.02, "value": 1.0},
	{"label": "계조 수", "uniform": "levels", "min": 2.0, "max": 16.0, "step": 1.0, "value": 4.0},
	{"label": "디더 세기", "uniform": "dither_strength", "min": 0.0, "max": 2.0, "step": 0.05, "value": 1.0},
	{"label": "탈색량", "uniform": "desaturate", "min": 0.0, "max": 1.0, "step": 0.05, "value": 0.5},
	{"label": "색 남길 채도 기준", "uniform": "sat_threshold", "min": 0.0, "max": 1.0, "step": 0.02, "value": 0.3},
	{"label": "경계 부드럽기", "uniform": "sat_softness", "min": 0.01, "max": 0.5, "step": 0.01, "value": 0.1},
]

var _material := ShaderMaterial.new()
var _panel: PanelContainer
var _readout: Label
var _values := {}
var _tint := Color.WHITE

var _view: TextureRect
var _images: PackedStringArray
var _index := 0
var _current_name := ""
var _lamp: LampGlow


func _ready() -> void:
	_material.shader = load(SHADER_PATH)
	_images = _find_images()

	_view = TextureRect.new()
	_view.material = _material
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED  # 늘리면 도트가 깨진다
	add_child(_view)

	_lamp = LampGlow.new()
	_lamp.position = LAMP_POSITION
	_lamp.glow_size = LAMP_SIZE
	add_child(_lamp)

	_build_panel()
	_show_image(0)

	if "--capture" in OS.get_cmdline_user_args():
		_capture_all_and_quit()


# 필터를 통과한 화면을 그대로 PNG로 뽑는다. 지금 보고 있는 배경 하나만 찍는다.
func _capture() -> void:
	var path := CAPTURE_PREFIX + _current_name
	var was_visible := _panel.visible
	_panel.visible = false
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	_panel.visible = was_visible
	print("저장: ", path)


# `-- --capture`로 실행하면 모든 배경을 지금 값으로 한 장씩 찍고 끝낸다.
# 여러 장을 나란히 놓고 "같은 값이 다 통하는가"를 볼 때 쓴다.
func _capture_all_and_quit() -> void:
	for i in _images.size():
		_show_image(i)
		await _capture()
	get_tree().quit()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_TAB:
			_panel.visible = not _panel.visible
			get_viewport().set_input_as_handled()
		KEY_C:
			DisplayServer.clipboard_set(_as_text())
		KEY_S:
			_capture()
		KEY_SPACE:
			_show_image(_index + 1)
		KEY_L:
			_lamp.visible = not _lamp.visible


# assets/backgrounds/ 안의 그림을 순서대로 돌려본다. 값을 고정해놓고 여러 장을
# 넘겨봐야 "이 수치가 모든 배경에 통하는가"를 알 수 있다.
func _find_images() -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(IMAGE_DIR)
	if dir == null:
		push_warning("배경 폴더를 못 열었다: %s" % IMAGE_DIR)
		return found
	for file in dir.get_files():
		if file.get_extension().to_lower() == "png":
			found.append(file)
	found.sort()
	return found


func _show_image(index: int) -> void:
	if _images.is_empty():
		return
	_index = index % _images.size()
	_current_name = _images[_index]
	_view.texture = load("%s/%s" % [IMAGE_DIR, _current_name])
	_refresh_readout()


func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_panel.offset_left = -PANEL_WIDTH

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.0, 0.0, 0.0, 0.75)
	bg.set_content_margin_all(6)
	_panel.add_theme_stylebox_override("panel", bg)
	add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	_panel.add_child(box)

	for p in PARAMS:
		var uniform: String = p["uniform"]
		_values[uniform] = p["value"]
		_apply(uniform, p["value"])

		box.add_child(_make_label(p["label"]))

		var slider := HSlider.new()
		slider.min_value = p["min"]
		slider.max_value = p["max"]
		slider.step = p["step"]
		slider.value = p["value"]
		slider.custom_minimum_size.y = 12
		slider.value_changed.connect(_on_slider_changed.bind(uniform))
		box.add_child(slider)

	box.add_child(_make_label("틴트 (회색 부분에 얹는 색)"))
	var picker := ColorPickerButton.new()
	picker.color = _tint
	picker.custom_minimum_size.y = 14
	picker.color_changed.connect(_on_tint_changed)
	box.add_child(picker)
	_apply("tint", _tint)

	_readout = _make_label("")
	box.add_child(_readout)
	box.add_child(_make_label("Space 다음 배경 / L 등불 / Tab 패널 숨김\nC 값 복사 / S 화면 저장"))
	_refresh_readout()


func _on_slider_changed(value: float, uniform: String) -> void:
	_values[uniform] = value
	_apply(uniform, value)
	_refresh_readout()


func _on_tint_changed(color: Color) -> void:
	_tint = color
	_apply("tint", color)
	_refresh_readout()


func _apply(uniform: String, value: Variant) -> void:
	# levels만 셰이더에서 int라 넘기기 전에 맞춰준다.
	if uniform == "levels":
		_material.set_shader_parameter(uniform, int(value))
	else:
		_material.set_shader_parameter(uniform, value)


func _refresh_readout() -> void:
	_readout.text = _as_text()


func _as_text() -> String:
	var lines := PackedStringArray()
	for p in PARAMS:
		lines.append("%s = %s" % [p["label"], String.num(_values[p["uniform"]], 2)])
	lines.append("틴트 = #%s" % _tint.to_html(false))
	lines.append("[%s]" % _current_name)
	return "\n".join(lines)


func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	KoreanFont.apply(label, FONT_SIZE)
	return label
