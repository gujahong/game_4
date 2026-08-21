extends Control
class_name LanternGauge

## **등불 눈금 — 칸이 열이다.** 한 자리에서 셋을 같이 읽는다(회원님, 2026-08-21).
##
## 전에는 가로 막대 하나였다. 밝기가 곧 체력이자 자원이던 때는 그것으로 됐는데,
## 등불이 마나가 되면서(`전투.md`) **봐야 할 것이 셋으로 늘었다.**
##
## ```
##  ▯   ← 없는 칸
##  ▯
##  ▮   ← 이미 쓴 칸 (다음 턴에 다시 찬다)
##  ▮
##  ▓   ← 이번 턴에 아직 쓸 수 있는 마나
##  ▓
##  ─────
##  ▯▯▯  ← 기름병
## ```
##
## | 칸 모양 | 뜻 |
## |---|---|
## | **찬 칸** | 이번 턴에 **아직 쓸 수 있는** 마나 |
## | **빈 칸** | 눈금은 있는데 **이미 쓴** 것. 다음 턴에 다시 찬다 |
## | **없는 칸** | 눈금이 여기까지 안 온다. 기름을 부어야 열린다 |
##
## 하스스톤의 마나 크리스탈과 같은 읽기다. **다만 여기는 늘어나지 않고 줄어든다** —
## 위에서부터 없는 칸이 내려온다.
##
## ### ★ 세로로 세워 등불 옆에 붙인다 (회원님, 2026-08-21)
##
## 처음엔 가로로 눕혀 등불 밑에 깔았는데 자리싸움이 났다 — 등불 밑은 부챗살의 맨 아래
## 줄기(도주)가 지나는 데다. 그것을 피하려고 부챗살을 위로 밀었더니 이번에는 빛 원뿔끼리
## 겹쳤다. **세로로 세워 옆에 붙이면 아래가 통째로 비어서 부챗살을 원래대로 둘 수 있다.**
##
## 그리고 **아래에서부터 찬다.** 등불 안의 기름이 차오르는 것처럼 읽힌다 - 가로로 눕혀
## 놓았을 때는 그냥 막대였다.
##
## ### 왜 칸으로 끊는가
##
## 이어진 막대는 "몇 개 쓸 수 있는지"를 못 알려준다. 기술이 3을 먹는데 막대가 절반이면
## 되는지 안 되는지 재야 한다. **칸으로 끊으면 세면 된다** — 카드게임이 다 이렇게 하는 이유다.
##
## 이 노드는 **`Lantern`을 모른다.** 숫자 셋을 받아서 그릴 뿐이라 전투 밖에서도 쓸 수 있고,
## 규칙이 바뀌어도 안 바뀐다.

## 칸 수. 눈금의 최대치와 같다.
const SLOTS := 10

## 칸 하나와 사이. **정수로만 잰다** — 픽셀 게임이라 반 칸이 생기면 도트가 흐려진다.
## 세로로 쌓으므로 눕은 네모다.
const CELL := Vector2i(14, 9)
const GAP := 2
const EDGE := 1

## ### 기름은 병 모양으로 그린다 (회원님, 2026-08-21)
##
## 처음엔 작은 네모로 찍었더니 **눈금 칸과 똑같이 생겨서** 눈금이 열다섯 칸인 줄 읽혔다.
## 가르는 금을 그어도 소용없었다 - 모양이 같으면 같은 것으로 본다.
##
## **목이 있는 병 실루엣**이면 한눈에 다른 것이 된다. 그리고 **빈 병은 안 그린다** -
## 몇 병 남았는지만 알면 되지 최대치는 알 필요가 없고, 안 그리면 헷갈릴 일도 없다.
const FLASK := Vector2i(7, 11)
const FLASK_NECK := 3        ## 목의 폭
const FLASK_NECK_H := 3      ## 목의 높이
const FLASK_GAP := 4
const FLASKS_MAX := 4        ## 이보다 많으면 "x7"처럼 숫자로 적는다

## 눈금과 기름을 가르는 가로 금과 그 위아래 여백.
const SPLIT_PAD := 7
const SPLIT_H := 1

## 없는 칸은 있는 자리라는 것만 알려주면 된다. **너무 진하면 마나로 착각하고, 너무
## 흐리면 열 칸이라는 것 자체가 안 읽힌다.**
const GONE_EDGE := Color(0.46, 0.41, 0.36, 0.7)
## 있는데 이미 쓴 칸. 테두리는 살아 있고 속만 비었다.
const SPENT_FILL := Color(0.13, 0.11, 0.09, 0.9)

## 눈금 셋. `colour`는 밖에서 준다 — **다칠수록 붉어지는** 등불색을 그대로 받는다.
var marks := 0
var mana := 0
var flasks := 0
var colour: Color = UiStyle.LAMP


func _init() -> void:
	custom_minimum_size = size_needed()
	size = size_needed()


static func slots_height() -> float:
	return float(SLOTS * CELL.y + (SLOTS - 1) * GAP)


static func size_needed() -> Vector2:
	return Vector2(
		float(maxi(CELL.x, FLASKS_MAX * FLASK.x + (FLASKS_MAX - 1) * FLASK_GAP)),
		slots_height() + SPLIT_PAD * 2 + SPLIT_H + float(FLASK.y))


## 상태를 넣는다. **셋 다 한 번에** — 따로 넣으면 한 프레임 어긋난 그림이 나온다.
func set_state(marks_now: int, mana_now: int, flasks_now: int, tint: Color) -> void:
	marks = clampi(marks_now, 0, SLOTS)
	mana = clampi(mana_now, 0, marks)
	flasks = maxi(flasks_now, 0)
	colour = tint
	queue_redraw()


func _draw() -> void:
	_draw_slots()
	_draw_flasks()


func _draw_slots() -> void:
	# 가장자리는 빛이 스러지는 색이라 속보다 어둡다. 등불 그림과 같은 규칙이다.
	var edge_lit := Color(colour.r * 0.75, colour.g * 0.6, colour.b * 0.45, 1.0)

	for i in SLOTS:
		# **아래에서부터 센다.** 기름이 차오르는 것처럼 보여야 한다.
		var from_bottom: int = SLOTS - 1 - i
		var box := Rect2(
			Vector2(0.0, float(from_bottom * (CELL.y + GAP))),
			Vector2(CELL))
		if i >= marks:
			# 없는 칸 — 테두리만 흐리게.
			draw_rect(box, GONE_EDGE, false, EDGE)
			continue

		# 있는 칸 — 테두리는 등불색.
		draw_rect(box, SPENT_FILL, true)
		draw_rect(box, edge_lit, false, EDGE)
		if i < mana:
			# 찬 칸 — 속을 채운다. 테두리 안쪽으로 한 칸 물려 그려야 테두리가 안 먹힌다.
			draw_rect(box.grow(-float(EDGE)), colour, true)


func _draw_flasks() -> void:
	# 눈금과 기름을 가르는 가로 금. **둘이 다른 것이라는 표시**다.
	var line_y: float = slots_height() + float(SPLIT_PAD)
	draw_rect(Rect2(0.0, line_y, float(CELL.x), float(SPLIT_H)), GONE_EDGE, true)

	var top: float = line_y + float(SPLIT_H + SPLIT_PAD)

	if flasks > FLASKS_MAX:
		# 너무 많으면 줄줄이 찍지 않는다. 하나 찍고 숫자를 붙인다.
		_flask(0.0, top)
		# **픽셀 글꼴을 네이티브 크기 그대로 쓴다.** 임의 크기로 줄이면 이 글자만 흐려진다.
		draw_string(KoreanFont.get_font(),
			Vector2(float(FLASK.x) + 4.0, top + float(FLASK.y)),
			"x%d" % flasks, HORIZONTAL_ALIGNMENT_LEFT, -1,
			KoreanFont.NATIVE_SIZE, colour)
		return
	# **있는 만큼만 그린다.** 빈 자리를 남기면 그것이 또 눈금처럼 보인다.
	for i in mini(flasks, FLASKS_MAX):
		_flask(float(i * (FLASK.x + FLASK_GAP)), top)


## 기름병 하나. 목이 있어야 눈금 칸과 안 헷갈린다.
func _flask(left: float, top: float) -> void:
	var neck_left: float = left + floorf(float(FLASK.x - FLASK_NECK) * 0.5)
	draw_rect(Rect2(neck_left, top, float(FLASK_NECK), float(FLASK_NECK_H)), colour, true)
	draw_rect(Rect2(left, top + float(FLASK_NECK_H),
		float(FLASK.x), float(FLASK.y - FLASK_NECK_H)), colour, true)
