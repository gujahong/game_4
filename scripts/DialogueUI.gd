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

## **크고 불투명해야 읽힌다**(회원님, 2026-08-19).
##
## 처음엔 900x144에 배경 알파 0.84였는데, 서고에서 열어 보니 **뒤의 디더 격자가 비쳐서
## 글이 안 읽혔다.** 이 게임 화면은 통째로 도트로 흩어져 있어서 반투명 판을 얹으면 글자와
## 격자가 겹친다. **대사창만은 화면을 가려야 한다.**
##
## 높이도 키웠다 - 서가의 글은 두세 줄짜리라 144로는 빠듯했다.
const PANEL_RECT := Rect2(24, 324, 912, 192)
## 대사창 배경. **알파를 거의 1로 둔다** - 아주 조금만 비쳐서 떠 있는 판인 것만 알린다.
const PANEL_BG := Color(0.035, 0.033, 0.030, 0.985)
const PANEL_BORDER := Color(0.62, 0.58, 0.52, 0.75)

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
	## 서가에 적힌 글. 못 읽는 글자가 스르르 풀린다(`DECODING`). 색은 보통 글과 같다 -
	## 연출은 푸는 과정에 있지 다 풀린 결과에 있지 않다.
	"record": {},
	## 서가의 마지막 한 줄. 같은 해독을 거치되 다 풀리면 등불색으로 남는다.
	"record_key": {"color": "ffb454"},
}

## ### 해독 연출 (2026-08-19)
##
## **못 읽는 글자가 먼저 다 깔려 있고, 앞에서부터 스르르 풀린다.** 한 글자씩 찍혀 나오는
## 보통 방식과 다른 점은 **문장의 길이가 처음부터 보인다**는 것이다 - 무언가 적혀 있긴 한데
## 읽을 수가 없는 상태에서 시작한다.
##
## 아직 안 풀린 자리는 매번 다시 뽑지 않고 **줄이 시작될 때 한 번 뽑아 고정한다.**
## 매 프레임 바꾸면 글씨가 지글거려서 눈이 아프다 - 셰이더의 자글자글과 같은 이유다.
##
## 이 스타일에서만 켠다. 다른 화면(관문·전투)은 그대로다.
const DECODING := ["record", "record_key"]

## ### 못 읽는 글자는 **세상에 없는 문자**여야 한다 (회원님, 2026-08-19)
##
## 두 번 틀렸다.
##
## 1. 자모(ㄱㄴㄷ)와 기호(※▨◈)를 섞었더니 **암호로 보였다.** 우리가 원하는 것은 뜻을
##    감춘 것이 아니라 **아직 못 읽는 것**이다
## 2. 무작위 한글 음절을 썼더니 **우리 글자였다.** 안 읽히긴 해도 우리가 아는 문자다
##
## 설정은 이렇다 — **이미 우리가 모르는 문자로 쓰여 있고, 그것이 해독된다.**
## 그래서 문자를 직접 만들었다(`tools/_glyphs.gd`). 줄기 하나에 표식이 붙는 규칙으로
## 스물네 자를 찍었고, 규칙이 있어서 한 문자 체계로 읽힌다.
##
## 글꼴이 아니라 **작은 그림 스물네 장**이라, BBCode의 `[img]`로 글 속에 끼워 넣는다.
const GLYPHS := 24
const GLYPH_DIR := "res://assets/ui/glyphs"
## 글자 크기(픽셀). 대사 글꼴(16)과 나란히 놓이므로 높이를 맞춘다.
## **글자 크기의 두 배로 놓는다** - 대사 글꼴이 32px이라 16px짜리 문자를 그대로 끼우면
## 혼자 작아서 글줄이 어긋난다. 도트 그림이라 정수배 확대는 격자가 안 깨진다.
const GLYPH_W := 24
const GLYPH_H := 32
## 아직 안 읽힌 문자의 색. 흐려야 "안 읽히는 것"으로 보인다.
const UNREAD := Color("6b625a")

## ### 해독은 두 단계다 (회원님, 2026-08-24)
##
## 전에는 **한 단계**였다 — 줄 전체가 못 읽는 문자로 처음부터 깔려 있고, 우리 글이 앞에서부터
## 그것을 먹어 들어갔다. 그래서 *옛 글씨가 적히는 장면 자체가 없었다.* 뭔가 이미 적혀 있는
## 종이를 읽는 것이었지, 받아 적히는 것이 아니었다.
##
## ```
## 1단계   못 읽는 문자가 한 자씩 써진다.        아직 아무것도 안 읽힌다
## 2단계   다 써진 뒤, 앞에서부터 우리 글로 바뀐다
## ```
##
## **1단계의 시계는 대사 시스템 것을 그대로 쓴다**(`chars_per_second`). 그래야 즉시완성도
## 글자별 실측 타이밍도 규칙을 안 건드리고 따라온다. **2단계만 여기서 잰다** — 대사 시스템은
## 1단계가 끝나면 이 줄을 "다 드러났다"로 치므로, 그 뒤는 화면이 알아서 붙잡고 있어야 한다.
const DECODE_CPS := 18.0
## 풀리는 자리 **앞의 몇 글자는 매번 다른 문자로 떨린다.** 이게 "스르륵"이다 —
## 딱 잘라 바뀌면 커서가 지나가는 것으로 보이지, 풀리는 것으로 안 보인다.
const DECODE_EDGE := 4
## 떨리는 주기(초). 매 프레임 새로 뽑으면 지지직거려서 눈이 아프다.
const DECODE_FLICKER := 0.055

## ### 등불빛이 글줄을 훑고 지나간다 (회원님, 2026-08-24: "꽤 멋있는 간단한 연출")
##
## 그냥 바뀌기만 하면 글자가 교체되는 것이지 *해독되는* 것이 아니다. 그래서 **푸는 자리에
## 빛을 하나 붙여 왼쪽에서 오른쪽으로 흘려보낸다.** 세 조각이 한 덩어리로 움직인다.
##
## ```
## …식은 우리 글  │  방금 풀려 아직 뜨거운 꼬리  │  빛이 닿아 떨리는 옛 문자  │  아직 어두운 옛 문자…
##                        등불색 → 제 색으로 식음          어둠 → 등불색으로 달아오름
## ```
##
## **빛이 지나간 자리가 읽힌다** — 이 게임의 전제("등불이 비추는 것만 실재한다")가 그대로
## 연출이 된다. 셰이더도 노드도 파티클도 안 쓴다. **글자마다 `[color]` 한 겹**이 전부다.
const SOLVED_GLOW := Color("ffb454")   ## 등불색
## 방금 풀린 글자가 제 색으로 식는 데 걸리는 글자 수. 꼬리 길이다.
const GLOW_TAIL := 7
## 아직 안 풀린 옛 문자가 빛을 얼마나 받는가(0~1). 1이면 앞이 너무 환해서 어디가 풀린
## 자리인지 안 보인다 — 빛은 **닿기만** 하고 넘어가야 한다.
const EDGE_LIT := 0.7

var _full_line := ""
## 못 읽는 줄. **글자 하나가 배열 한 칸**이다 - `[img]` 태그가 여러 글자라서 문자열로 두면
## "몇 자까지 풀렸는가"를 셀 수 없다.
var _scrambled: Array[String] = []

var _panel: PanelContainer
var _name_label: Label
var _text_label: RichTextLabel
var _arrow: Label
var _choice_box: VBoxContainer

var _current_style := "normal"
var _arrow_blink_t := 0.0
var _panel_home := Vector2.ZERO

## 2단계가 도는 중인가. **도는 동안은 스페이스가 "넘기기"가 아니라 "마저 풀기"다.**
var _solving := false
var _solved := 0.0     ## 여기까지 우리 글로 풀렸다(소수점은 속도 계산용)
var _drawn := -1       ## 마지막으로 화면에 그린 `_solved`. 같으면 글자를 다시 안 짠다
var _flicker_t := 0.0


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
	if _solving:
		_step_solving(delta)
		return
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
		# **풀리는 중이면 먼저 마저 푼다.** 대사 시스템은 옛 문자가 다 써진 순간 이 줄을
		# "다 드러났다"로 쳐서, 여기서 안 가로채면 스르륵 풀리는 것을 못 보고 다음 줄로 넘어간다.
		if _solving:
			_finish_solving()
		else:
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

	# **여기만 UiStyle의 반투명 판을 안 쓴다.** 다른 패널은 화면이 비쳐도 되지만 대사창은
	# 글을 읽는 곳이라 가려야 한다.
	var box: StyleBoxFlat = UiStyle.panel_box(14)
	box.bg_color = PANEL_BG
	box.border_color = PANEL_BORDER
	_panel.add_theme_stylebox_override("panel", box)
	add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_panel.add_child(column)

	_name_label = Label.new()
	KoreanFont.apply(_name_label, KoreanFont.NATIVE_SIZE * 2)
	_name_label.add_theme_color_override("font_color", NAME_COLOR)
	column.add_child(_name_label)

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.scroll_active = false
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# **네이티브의 두 배(32).** 픽셀 글꼴은 정수배로만 써야 도트가 안 어긋난다.
	# 960x540 화면에서 16px는 읽기에 작다.
	KoreanFont.apply(_text_label, KoreanFont.NATIVE_SIZE * 2)
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
	# **해독 연출**(회원님, 2026-08-19). 옛 문자로 먼저 써지고 스르르 풀린다 -
	# 잊힌 것을 받아 적은 기록이라는 설정과 맞는다. 스타일로 켜므로 다른 화면은 그대로다.
	_full_line = line.text
	_scrambled = _garble(line.text)
	_solving = false
	_solved = 0.0
	_drawn = -1
	_flicker_t = 0.0


func _on_typing_progress(revealed_text: String) -> void:
	# **1단계.** 우리 글이 아니라 옛 문자가 써진다 - 드러난 길이만 받아 쓴다.
	if _current_style in DECODING:
		_text_label.text = _decorate(_written(revealed_text.length()))
		return
	_text_label.text = _decorate(revealed_text)


func _on_line_finished_typing() -> void:
	# **다 써졌으면 이제 푼다.** 화살표는 아직 안 띄운다 - 읽을 것이 아직 없다.
	if _current_style in DECODING and _full_line.length() > 0:
		_solving = true
		_solved = 0.0
		_drawn = -1
		_flicker_t = 0.0
		_arrow.visible = false
		return
	_show_arrow()


## **2단계.** 앞에서부터 우리 글로 바뀐다. 대사 시스템이 아니라 여기가 잰다.
func _step_solving(delta: float) -> void:
	var whole: float = float(_full_line.length())
	_solved = minf(_solved + DECODE_CPS * delta, whole)
	_flicker_t += delta
	var shake: bool = _flicker_t >= DECODE_FLICKER
	if shake:
		_flicker_t = 0.0
	# 푼 자리가 늘었거나 떨 차례일 때만 글자를 다시 짠다. BBCode를 매 프레임 다시 파싱하면
	# 줄이 길 때 눈에 띄게 무겁다.
	if shake or int(_solved) != _drawn:
		_drawn = int(_solved)
		_text_label.text = _decorate(_solving_text(_drawn))
	if _solved >= whole:
		_finish_solving()


func _finish_solving() -> void:
	_solving = false
	_solved = float(_full_line.length())
	_text_label.text = _decorate(_full_line)
	_show_arrow()


func _show_arrow() -> void:
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
	_solving = false      # 창이 닫혔는데 안 보이는 글자를 계속 풀고 있으면 안 된다
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
## 줄 전체를 못 읽는 글자로 바꾼다. **띄어쓰기와 문장부호는 남긴다** - 그래야 낱말의
## 덩어리가 보여서 "글이긴 하다"로 읽힌다. 다 뭉개면 그냥 무늬가 된다.
## 줄 전체를 못 읽는 문자로 바꾼다.
##
## **띄어쓰기와 문장부호는 남긴다** - 그래야 낱말의 덩어리가 보여서 "글이긴 하다"로 읽힌다.
## 다 뭉개면 무늬가 된다. 그리고 한글 한 글자가 이 문자로는 한 자에 대응한다고 친다.
func _garble(text: String) -> Array[String]:
	var out: Array[String] = []
	for i in text.length():
		var c: String = text[i]
		if c == " " or c == "\n" or c in ".,…—-·":
			out.append(c)
		else:
			out.append(_glyph())
	return out


## 못 읽는 문자 하나를 BBCode 그림으로.
##
## `valign=center`라야 글줄에 앉는다. **색은 `[img]` 안에 넣어야 한다** - 바깥의
## `[color]`는 글자만 물들이고 그림은 안 물들인다.
## 빛이 닿는 자리는 밝게 뽑으려고 색을 받는다 - 안 주면 여느 때처럼 어둡다.
func _glyph(tint: Color = UNREAD) -> String:
	return "[img=%dx%d valign=center color=#%s]%s/%02d.png[/img]" % [
		GLYPH_W, GLYPH_H, tint.to_html(false), GLYPH_DIR, randi() % GLYPHS]


## **1단계의 한 컷.** 앞에서 `count`자까지 옛 문자가 써졌다. 뒤는 아직 빈자리다 —
## **줄이 자라는 것이 보여야** 적히는 중으로 읽힌다.
func _written(count: int) -> String:
	var upto: int = clampi(count, 0, _scrambled.size())
	var out := ""
	for i in upto:
		out += _scrambled[i]
	return out


## **2단계의 한 컷.** 빛이 `solved`자리에 와 있다. 위 그림의 네 조각을 순서대로 잇는다.
func _solving_text(solved: int) -> String:
	var upto: int = clampi(solved, 0, _full_line.length())
	var rest: Color = _rest_color()
	var out := ""

	# ① 다 식은 우리 글. 색을 안 입힌다 - 바깥의 스타일 색이 그대로 먹는다.
	var cooled: int = maxi(upto - GLOW_TAIL, 0)
	if cooled > 0:
		out += _full_line.substr(0, cooled)

	# ② 아직 뜨거운 꼬리. 빛에 가까울수록 등불색이다.
	for i in range(cooled, upto):
		var heat: float = 1.0 - float(upto - 1 - i) / float(GLOW_TAIL)
		out += "[color=#%s]%s[/color]" % [
			rest.lerp(SOLVED_GLOW, clampf(heat, 0.0, 1.0)).to_html(false), _full_line[i]]

	# ③④ 아직 안 풀린 옛 문자. 빛이 닿는 데까지만 떨면서 달아오른다.
	# 띄어쓰기와 문장부호는 애초에 안 뭉갠 것이라 떨 것도 없다(`_garble`).
	for i in range(upto, _scrambled.size()):
		if i < upto + DECODE_EDGE and _scrambled[i].begins_with("[img"):
			var near: float = 1.0 - float(i - upto) / float(DECODE_EDGE)
			out += _glyph(UNREAD.lerp(SOLVED_GLOW, near * EDGE_LIT))
		else:
			out += _scrambled[i]
	return out


## 다 풀리고 나면 이 색으로 남는다. 스타일이 색을 정했으면 그것, 아니면 보통 글자색이다.
func _rest_color() -> Color:
	var preset: Dictionary = STYLE_PRESETS.get(_current_style, {})
	return Color(preset["color"]) if preset.has("color") else TEXT_COLOR


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
