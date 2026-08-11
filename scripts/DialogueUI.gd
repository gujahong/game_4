extends CanvasLayer
class_name DialogueUI

## 대사창. Dialogue(DialogueController Autoload)의 시그널만 구독하고 advance()/select_choice()만
## 호출한다 - Controller는 이 UI의 존재를 전혀 모른다. 그래서 화면을 통째로 갈아엎어도 대사 로직은
## 손댈 일이 없다.
##
## [2026-08-11] 우주쓰레기게임에서 가져온 것은 **구조**뿐이다 - 시그널을 어떻게 받는지, style을
## BBCode로 어떻게 바꾸는지, 선택지를 어떻게 띄우는지. 겉모습은 새로 짰다. 그쪽 대사창에는 SF HUD
## 테두리(PixelHudFrame)와 CRT 켜짐 연출(CrtPowerOn)이 붙어 있어서 이 게임의 회색 고딕 화면과
## 어긋난다.
##
## 노드를 씬 파일이 아니라 코드로 만든다 - 640x360에 맞춘 좌표 몇 개가 전부라, 씬 파일로 두면
## 오히려 어디에 뭐가 있는지 읽기 어렵다.

## ScreenEffect(layer 100)보다 위. 암전/페이드가 걸려 있어도 대사는 읽혀야 한다.
const LAYER := 101

const PANEL_RECT := Rect2(30, 366, 900, 144)
const CHOICE_TOP := 225

const TEXT_COLOR := UiStyle.TEXT
const NAME_COLOR := UiStyle.TEXT_DIM

const ARROW_BLINK_INTERVAL := 0.5

## 스타일 이름 -> 연출. 없는 항목은 "기본값 유지"를 뜻한다. 새 스타일은 여기 한 줄 추가하면 끝이고
## 다른 코드는 안 건드린다. Controller는 style을 읽지도 않고 그냥 실어 나르기만 한다.
##
## **색을 아껴 쓴다.** 이 게임 화면은 "쨍한 것만 색이 남는" 규칙 위에 서 있어서, 글자까지
## 알록달록하면 그 규칙이 깨진다. important의 주황은 주인공이 든 등불 색이다.
const STYLE_PRESETS: Dictionary = {
	"normal": {},
	## 기울임은 쓰지 않는다. 픽셀 폰트에 [i]를 걸면 도트를 비스듬히 밀어버려서 격자가 깨진다.
	"narration": {"color": "8a8a8a"},
	"important": {"color": "ffb454"},
	## 크기는 네이티브의 **정수배**여야 도트가 안 어긋난다(16 -> 32).
	"emphasis": {"font_size": KoreanFont.NATIVE_SIZE * 2, "shake": {"rate": 9.0, "level": 3}},
}

var _panel: PanelContainer
var _name_label: Label
var _text_label: RichTextLabel
var _arrow: Label
var _choice_box: VBoxContainer

var _current_style := "normal"
var _arrow_blink_t := 0.0
var _panel_home := Vector2.ZERO


func _ready() -> void:
	layer = LAYER
	add_to_group("dialogue_ui")
	_build()
	_panel.visible = false
	_choice_box.visible = false

	Dialogue.scene_started.connect(_on_scene_started)
	Dialogue.line_started.connect(_on_line_started)
	Dialogue.line_typing_progress.connect(_on_typing_progress)
	Dialogue.line_finished_typing.connect(_on_line_finished_typing)
	Dialogue.choices_presented.connect(_on_choices_presented)
	Dialogue.scene_finished.connect(_on_scene_finished)
	Dialogue.chapter_finished.connect(_on_scene_finished)


func _process(delta: float) -> void:
	if not _arrow.visible:
		return
	_arrow_blink_t += delta
	if _arrow_blink_t >= ARROW_BLINK_INTERVAL:
		_arrow_blink_t = 0.0
		_arrow.modulate.a = 0.15 if _arrow.modulate.a > 0.5 else 1.0


func _unhandled_input(event: InputEvent) -> void:
	if not Dialogue.is_playing or Dialogue.input_locked:
		return
	if not Dialogue.pending_choices.is_empty():
		return  # 선택지가 떠 있으면 버튼으로만 진행한다
	if _is_advance_input(event):
		Dialogue.advance()
		get_viewport().set_input_as_handled()


## DialogueCommandShake가 부른다. 대사창만 흔든다 - 배경은 필터가 걸린 그림이라 흔들면
## 디더 격자가 같이 밀려서 지저분해진다.
func shake_panel(amount: float, duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		var decay: float = 1.0 - elapsed / duration
		_panel.position = _panel_home + Vector2(
			randf_range(-amount, amount) * decay,
			randf_range(-amount, amount) * decay
		)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	_panel.position = _panel_home


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.position = PANEL_RECT.position
	_panel.size = PANEL_RECT.size
	_panel_home = PANEL_RECT.position

	_panel.add_theme_stylebox_override("panel", UiStyle.panel_box())
	add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	_panel.add_child(column)

	_name_label = Label.new()
	KoreanFont.apply(_name_label)
	_name_label.add_theme_color_override("font_color", NAME_COLOR)
	column.add_child(_name_label)

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.scroll_active = false
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	KoreanFont.apply(_text_label)
	_text_label.add_theme_color_override("default_color", TEXT_COLOR)
	column.add_child(_text_label)

	_arrow = Label.new()
	_arrow.text = "▼"
	KoreanFont.apply(_arrow)
	_arrow.add_theme_color_override("font_color", TEXT_COLOR)
	_arrow.position = PANEL_RECT.end - Vector2(30, 30)
	_arrow.visible = false
	add_child(_arrow)

	_choice_box = VBoxContainer.new()
	_choice_box.add_theme_constant_override("separation", 3)
	_choice_box.position = Vector2(PANEL_RECT.position.x + 90, CHOICE_TOP)
	_choice_box.custom_minimum_size.x = PANEL_RECT.size.x - 180
	add_child(_choice_box)


func _on_scene_started(_scene: DialogueScene) -> void:
	_panel.visible = true


func _on_line_started(line: DialogueLine) -> void:
	_current_style = line.style
	_name_label.text = line.speaker
	_name_label.visible = not line.speaker.is_empty()
	_text_label.text = ""
	_arrow.visible = false


func _on_typing_progress(revealed_text: String) -> void:
	_text_label.text = _decorate(revealed_text)


func _on_line_finished_typing() -> void:
	# 이 시점엔 아직 pending_choices가 안 채워져 있다(Controller가 이 시그널을 먼저 쏘고 나서
	# 선택지를 세팅한다) - 선택지가 있는 줄이면 곧 _on_choices_presented가 화살표를 다시 끈다.
	_arrow.visible = true
	_arrow.modulate.a = 1.0
	_arrow_blink_t = 0.0


func _on_choices_presented(choices: Array) -> void:
	_arrow.visible = false
	_clear_choices()
	for i in choices.size():
		var choice: DialogueChoice = choices[i]
		var button := Button.new()
		button.text = choice.text
		KoreanFont.apply(button)
		UiStyle.style_button(button)
		button.pressed.connect(_on_choice_pressed.bind(i))
		_choice_box.add_child(button)
	_choice_box.visible = true
	# 첫 버튼에 포커스를 준다 - 이러면 위/아래 키로 고르고 스페이스로 확정하는 게 그냥 된다.
	# 대화 도중에 마우스를 잡으러 손을 옮기지 않아도 되게 하려는 것.
	_choice_box.get_child(0).grab_focus()


func _on_choice_pressed(index: int) -> void:
	_choice_box.visible = false
	_clear_choices()
	Dialogue.select_choice(index)


func _on_scene_finished() -> void:
	_panel.visible = false
	_arrow.visible = false
	_choice_box.visible = false
	_clear_choices()


func _clear_choices() -> void:
	for child in _choice_box.get_children():
		child.queue_free()


func _is_advance_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode == KEY_SPACE or event.keycode == KEY_ENTER
	return false


## 지금 줄의 style을 BBCode 태그로 감싼다. 전부 Godot이 이미 제공하는 태그라 셰이더나 별도
## 애니메이션 시스템이 필요 없다.
func _decorate(text: String) -> String:
	if text.is_empty():
		return ""
	var preset: Dictionary = STYLE_PRESETS.get(_current_style, {})
	var out := text
	if preset.has("shake"):
		out = "[shake rate=%s level=%s]%s[/shake]" % [preset["shake"]["rate"], preset["shake"]["level"], out]
	if preset.get("italic", false):
		out = "[i]%s[/i]" % out
	if preset.has("font_size"):
		out = "[font_size=%d]%s[/font_size]" % [preset["font_size"], out]
	if preset.has("color"):
		out = "[color=#%s]%s[/color]" % [preset["color"], out]
	return out
