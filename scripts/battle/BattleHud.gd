extends CanvasLayer
class_name BattleHud

## 전투 화면에 뜨는 것 전부.
##
## **배치도 연출도 모른다.** 값을 받아 그리고, 눌린 것을 알릴 뿐이다. 그래서 전투가 어느 씬에
## 얹히든(조우 복도든 시험용 씬이든) 이 파일은 그대로 쓴다. 규칙은 `Battle`이, 무대는
## `BattleStage`가 맡는다.
##
## **숫자를 안 보여준다**(회원님, 2026-08-14). 체력·적 상태를 글자로 적어 두면 화면이 계산표가
## 되고, 계산이 되는 것은 안 무섭다. 남는 것은 넷뿐이다.
##
## ```
## 등불 밑     등불 밝기 + -  와 남은 기름 눈금
## 등불에서    고를 것 넷이 빛줄기를 타고 뻗는다
## 아래 가운데 지금 벌어진 일이 한 단어씩 떠오른다
## 화면 전체   등불이 어두워지면 세상도 같이 죽는다 (= 기름 눈금이자 체력 눈금)
## ```

signal acted(index: int)         ## 빛줄기 메뉴에서 고른 행동
signal targeted(index: int)      ## 대상 고르기에서 고른 적(`alive()` 목록 안에서의 번호)
signal talked(index: int)        ## 그 대상에게 거는 말길 번호
signal pour_asked()   ## 기름을 붓겠다 - 턴을 쓰는 행동이다

## 고를 것들. 빛줄기 넷이 **등불에서 부챗살로 퍼지고** 그 끝에 글자가 붙는다 - 한 줄로
## 늘어놓으면 목록이 되고, 갈라져야 등불에서 뻗어 나온 것으로 보인다.
## **도주는 부챗살에 안 낀다.** 싸우는 방법들 사이에 끼워 두면 그것도 한 수처럼 보이는데,
## 도망은 이 자리를 떠나는 일이라 결이 다르다. 넷과 떨어져 **혼자 아래로 뻗는 빛**이 된다.
const ACTION_NAMES := ["공격", "기술", "대화", "방어"]
const FLEE_NAME := "도주"

## 자리를 손으로 하나씩 적었더니 **길이도 사이도 제각각이라** 어떤 것은 겹치고 어떤 것은
## 혼자 멀리 떨어졌다. **몇 개가 오든 같은 자리에 고르게 편다** - 칸 간격을 못박아 두면
## 항목이 하나 늘 때 마지막 것이 화면 밖으로 나간다(취소를 붙이자마자 그렇게 됐다).
##
## 각도는 0이 오른쪽이고 음수가 위쪽이다.
##
## ### ★ 이 값은 건드리지 말 것 (2026-08-21에 헛돌고 배운 것)
##
## 눈금을 등불 밑에 깔았더니 맨 아래 줄기(도주)와 자리싸움이 나서, 여기를 **세 번** 갈아엎었다.
## 전부 헛수고였다.
##
## | 해본 것 | 무너진 곳 |
## |---|---|
## | 범위를 `0도`까지 좁히기 | 줄기 사이가 좁아져 **빛 원뿔끼리 파고들었다** |
## | 세로를 고르게 나누기 | 맨 위가 등불 바로 위에 서서 **혼자 튀었다** |
## | 원뿔을 좁히기 | 원뿔이 글자를 못 품어 **글자가 빛 밖으로 나갔다** |
##
## **답은 눈금을 세로로 세워 등불 옆에 붙이는 것이었다**(회원님). 등불 밑이 비니까 부챗살은
## 원래 값 그대로 두면 된다.
##
## 그래도 언젠가 여기를 좁혀야 한다면, `LightMenu.CONE_HALF_WIDTH`와 묶여 있다는 것만 기억할 것.
##
## ```
## 원뿔의 반각 = atan(CONE_HALF_WIDTH / (FAN_REACH × CONE_OVERSHOOT))
## 안 겹치려면   반각 × 2  ≤  (FAN_TO - FAN_FROM) / (항목 수 - 1)
## ```
##
## 폭을 줄이는 것보다 **거리(`FAN_REACH`)를 늘리는 쪽**이 낫다. 같은 폭이라도 멀어지면
## 각도상으로는 얇아져서, 글자를 품는 것을 안 깨고도 옆 줄기와 벌어진다.
const FAN_REACH := 214.0
const FAN_FROM := -78.0
const FAN_TO := 21.0

## 대상·말길에서 물러설 때 붙는 마지막 줄기. **행동 넷에는 안 붙는다** - 거기서는 돌아갈
## 데가 없다.
const CANCEL := "그만두기"

## 등불에 딸린 것들이 앉는 자리. **등불 바로 곁**이라야 이것들이 저 불의 것으로 보인다 -
## 화면 구석에 두면 그냥 설정 창이 된다.
##
## ### ★ 눈금은 세로로 세워 등불 왼쪽에 붙인다 (회원님, 2026-08-21)
##
## ```
##  ▯
##  ▯          ← 없는 칸이 위에서 내려온다
##  ▮
##  ▓  [등불]   (44, 428)
##  ▓
##  ─
##  ▯▯▯        ← 기름병
##      [기름 붓기]
## ```
##
## **가로로 눕혀 등불 밑에 깔았다가 세로로 세웠다.** 밑은 부챗살의 맨 아래 줄기(도주)가
## 지나는 자리라 자리싸움이 났고, 그것을 피하려고 부챗살을 만졌더니 빛 원뿔이 겹쳤다.
## **옆으로 비키니 둘 다 없던 일이 됐다.**
##
## 그리고 세로가 더 맞는다 - **아래에서부터 차오르는 것**이 등불 안의 기름으로 읽힌다.
##
## 그전에 고친 것 셋도 그대로 살아 있다.
##
## 1. **가운데 맞추기를 버렸다.** 등불이 왼쪽 끝(x=44)에 앉는데 그 축에 가운데를 맞추니
##    폭이 조금만 넓어도 왼쪽이 잘렸다
## 2. **"기름" 글자를 뺐다.** 빛 한가운데라 맨 글자는 씻겨서 안 읽혔다. 병 수는 눈금이
##    찍으므로, 바탕 있는 단추 하나만 남긴다
## 3. **글자를 네이티브 크기로**(회원님) - 32는 이 구석에 너무 컸다
const GAUGE_LEFT := 6.0     ## 눈금 기둥의 왼쪽 여백. 등불 그림보다 왼쪽이다
const BUTTON_AT := Vector2(52.0, 486.0)   ## "기름 붓기". 등불 밑, 기름병 오른쪽

## 지금 벌어진 일. **아래 가운데**에 한 단어씩 떠오른다(오프닝의 경구와 같은 방식).
const SAY_AT := 496.0


var _menu: LightMenu
var _row: HBoxContainer
var _buttons: Array[Button] = []
var _gauge: LanternGauge
var _say: EmberText

## 지금 빛줄기에 걸려 있는 것이 무엇인가. 고른 것을 어디로 보낼지가 여기서 갈린다.
enum Picking { ACTION, TARGET, TALK }

var _origin := Vector2.ZERO   ## 빛줄기가 뻗어 나오는 자리
var _picking: Picking = Picking.ACTION
var _light := 1.0      ## 기름이 정하는 밝기
var _flicker := 1.0    ## 불꽃이 흔들리는 몫

## 0이면 아무것도 안 보이고 1이면 다 보인다. **카메라가 다 돌고 나서 등불에서 빛이 배어
## 나오듯 떠야 한다** - 전환이 끝나자마자 글자가 툭 떠 있으면 급작스럽다.
var reveal: float = 1.0:
	set(value):
		reveal = clampf(value, 0.0, 1.0)
		_apply_alpha()

## 등불이 밝힌 만큼. **불을 줄이면 손에 든 것도 같이 죽는다** - 화면에서 보이는 것이 전부
## 이 불에 달려 있다는 규칙에는 UI도 예외가 아니다.
##
## 바닥(`GLOOM_FLOOR`)은 남긴다. 아예 안 보이면 뭘 고르는지도 모른 채 눌러야 한다.
const GLOOM_FLOOR := 0.28
var _gloom := 1.0


func _apply_alpha() -> void:
	var shown: float = reveal * lerpf(GLOOM_FLOOR, 1.0, _gloom)
	for item in [_menu, _row, _say]:
		if item != null:
			item.modulate.a = shown
	# **눈금만은 어둠을 안 뒤집어쓴다**(회원님, 2026-08-21: "게이지는 필터를 빼야 할 것
	# 같아, 안 보여"). 다른 것들은 불이 죽으면 같이 죽는 게 맞는데, 이것은 **남은 자원을
	# 읽는 자리**다 - 어두울수록 아껴 써야 하는데 정작 그때 안 보이면 거꾸로다.
	# 들고 나는 것(`reveal`)만 따른다.
	if _gauge != null:
		_gauge.modulate.a = reveal


## origin은 빛줄기가 뻗어 나오는 자리 - 등불이 앉은 곳이다.
func setup(origin: Vector2) -> void:
	layer = 101

	_build_lamp_panel(origin)

	_say = EmberText.new()
	KoreanFont.apply(_say, KoreanFont.NATIVE_SIZE * 2)
	# 가로는 화면 전체를 써야 `[center]`의 기준이 화면 가운데가 된다.
	# **왼쪽 아래는 도주가 쓰는 자리다.** 화면 전체 폭으로 가운데를 잡으면 글자가 그 위에
	# 겹친다 - 부챗살이 안 닿는 오른쪽 절반 안에서 가운데를 잡는다.
	_say.custom_minimum_size = Vector2(640.0, 0.0)
	_say.position = Vector2(320.0, SAY_AT)
	add_child(_say)

	_origin = origin
	_menu = LightMenu.new()
	_menu.origin = origin
	# **`show_actions()`를 거쳐야 도주가 붙는다.** 여기서 부챗살 넷만 세웠더니 처음 한 턴은
	# 도주가 아예 없었다 - 도주는 부챗살이 아니라 따로 아래로 뻗는 빛이라 그 함수가 붙인다.
	show_actions()
	_menu.chosen.connect(_on_chosen)
	add_child(_menu)

	reveal = 0.0   # 무대가 켜 준다


## 등불에서 같은 거리·같은 각도 차이로 편 자리들. **고를 것이 몇이든 같은 부채꼴에 눕는다** -
## 행동 넷이든 대상 하나든 여섯이든, 이 화면에서 고르는 것은 늘 등불에서 뻗어 나온다.
func _fan(names: Array) -> Array:
	var spread: Array = []
	var last: float = maxf(float(names.size() - 1), 1.0)
	for i in names.size():
		var along: float = 0.5 if names.size() == 1 else float(i) / last
		var angle: float = deg_to_rad(lerpf(FAN_FROM, FAN_TO, along))
		spread.append({
			"text": names[i],
			"anchor": (_origin + Vector2(cos(angle), sin(angle)) * FAN_REACH).round(),
		})
	return spread


## 고른 것을 어느 쪽으로 보낼지는 **지금 무엇을 고르는 중인가**가 정한다.
func _on_chosen(index: int) -> void:
	match _picking:
		Picking.TARGET:
			targeted.emit(index)
		Picking.TALK:
			talked.emit(index)
		_:
			acted.emit(index)


## 빛줄기가 그대로 이름만 갈아입는다 - 창이 새로 뜨는 게 아니라 **같은 불에서 다른 것이
## 뻗어 나온다.** 무엇을 고르는 중인지는 무대가 정하고, 여기는 이름만 받는다.
func _show(mode: Picking, names: Array) -> void:
	_picking = mode
	_menu.setup(_fan(names))
	_menu.modulate.a = reveal


## 다섯을 **같은 부채꼴에 고르게** 편다. 도주는 그중 제일 아래 줄기다.
func show_actions() -> void:
	_picking = Picking.ACTION
	# **도주까지 같은 부채꼴에 고르게 넣는다.** 따로 각도를 잡아 뒀더니 그것만 사이가 달라서
	# 제각각으로 보였다 - 제일 아래 줄기라는 것만으로 이미 다른 것과 구별된다.
	var spread: Array = _fan(ACTION_NAMES + [FLEE_NAME])
	_menu.setup(spread)
	_apply_alpha()


## 대상과 말길에는 **물러설 줄기가 하나 더 붙는다.** 잘못 들어왔을 때 나갈 데가 있어야 한다.
func show_targets(names: Array) -> void:
	_show(Picking.TARGET, names + [CANCEL])


func show_talks(names: Array) -> void:
	_show(Picking.TALK, names + [CANCEL])


## 등불 밑에 붙는 것들. **밝기를 올리고 내리는 손잡이와 남은 기름 눈금뿐이다.**
##
## 등불 조절은 행동이 아니라서(턴을 안 쓴다) 빛줄기 메뉴에 섞지 않는다 - 같이 두면
## "이것도 턴을 쓰나?" 하고 헷갈린다.
func _build_lamp_panel(origin: Vector2) -> void:
	# **눈금 열 칸.** 전에는 이어진 막대 하나였는데, 등불이 마나가 되면서 봐야 할 것이
	# 셋으로 늘었다(눈금·이번 턴 마나·기름). 막대로는 "몇 개 쓸 수 있는지"를 못 알려준다 -
	# 기술이 3을 먹는데 막대가 절반이면 되는지 재야 한다. **칸으로 끊으면 세면 된다.**
	#
	# **등불 왼쪽에 세로로 세운다**(회원님). 칸 기둥의 가운데를 등불 높이에 맞춘다.
	_gauge = LanternGauge.new()
	_gauge.position = Vector2(
		GAUGE_LEFT,
		origin.y - LanternGauge.slots_height() * 0.5).round()
	add_child(_gauge)

	# **"기름"이라는 글자를 뺐다.** 등불 빛 한가운데 앉는 자리라 맨 글자는 씻겨서 안
	# 읽혔고, 눈금에 병이 그려지므로 무엇에 붓는지도 이미 보인다. 바탕이 있는 단추만
	# 남기면 빛 위에서도 읽힌다.
	_row = HBoxContainer.new()
	_row.position = BUTTON_AT
	_row.add_theme_constant_override("separation", 12)
	_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(_row)

	var pour := Button.new()
	pour.text = "기름 붓기"
	# **네이티브(16) 그대로.** 32는 이 구석에 너무 컸다(회원님).
	KoreanFont.apply(pour, KoreanFont.NATIVE_SIZE)
	UiStyle.style_flat_button(pour)
	pour.focus_mode = Control.FOCUS_NONE  # 빛줄기 메뉴의 방향키 조작에 안 끼어들게
	pour.pressed.connect(func() -> void: pour_asked.emit())
	_row.add_child(pour)
	_buttons.append(pour)


## 등불이 옮겨 다니면 빛줄기도 따라간다.
func aim_from(origin: Vector2) -> void:
	if _menu != null:
		_menu.origin = origin


## 지금 벌어진 일을 한 단어씩 띄운다. 앞의 것은 지운다 - 쌓아 두는 기록판이 아니다.
## **다 떠오르는 데 걸리는 시간을 돌려준다** - 그만큼은 기다려야 다음 줄로 넘어갈 수 있다.
func say(text: String) -> float:
	if _say == null:
		return 0.0
	return _say.say(text)


## 상태를 화면에 옮긴다. **숫자는 하나도 안 쓴다.**
func show_state(battle: Battle, light: float, colour: Color) -> void:
	var lantern := battle.lantern
	_light = light
	_menu.light = light * _flicker
	_menu.colour = colour

	# 불을 줄이면 글자도 눈금도 같이 죽는다.
	_gloom = Lantern.BRIGHTNESS[lantern.level]
	_apply_alpha()

	# 눈금 · 이번 턴 마나 · 기름을 한 자리에서 보여준다. **색은 등불색을 그대로 받는다** -
	# 다칠수록 붉어지므로 이 한 줄이 체력까지 말해 준다.
	_gauge.set_state(lantern.marks, lantern.mana, lantern.flasks, colour)
	# 병 수는 눈금 쪽이 찍는다. 빈손이면 단추만 흐려진다.
	for button in _buttons:
		button.disabled = lantern.flasks <= 0


## 불꽃이 흔들리는 몫(1이면 그대로). **밝기 자체와 갈라 둔다** - 밝기는 기름이 정하는 값이고
## 이건 매 프레임 흔들리는 것이라, 하나로 합쳐 두면 다음 갱신 때 흔들림이 지워진다.
func set_flicker(amount: float) -> void:
	_flicker = amount
	if _menu != null:
		_menu.light = _light * _flicker


## 지난 턴을 푸는 동안에는 아무것도 안 먹는다. **손을 묶어 둬야 박자가 산다** - 안 그러면
## 그것이 반격하는 것을 보기도 전에 다음 것을 눌러 버린다.
func set_enabled(value: bool) -> void:
	_menu.enabled = value
	for button in _buttons:
		button.disabled = not value


func close() -> void:
	set_enabled(false)
