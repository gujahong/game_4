extends Node2D
class_name Relic

## 등불에서 꺼내는 **빛으로 된 보구 — 칼.**
##
## 이 화면에서 나를 나타내는 것은 등불이다. 그래서 공격도 등불에서 나온다. 연출은 세 박이다
## (회원님, 2026-08-18: "칼 모양 빛 실루엣만 나오고 사라졌다가 베는 이펙트(검기)가 적한테").
##
## 1. 유리에서 칼 모양 빛이 **쑤욱** 뽑혀 나와 잠깐 멎는다 - 겨눔
## 2. **사라진다** - 칼이 날아가는 것을 안 보여주는 것이 핵심이다. 빛이 응축됐다 흩어지고
## 3. 다음 순간 적 위에 **검기**가 번쩍 그어진다 - 팽창했다가 부풀며 스러지는 애니메이션
##
## 그림 파일이 없다. 빛은 이 게임에서 색을 가진 유일한 것이라 `LampGlow`와 같은 디더
## 셰이더(`DitherLight`)를 쓴다 — 화면의 다른 빛과 같은 격자로 흩어지고, 더하기 합성이라
## 등불빛 위를 지나도 서로 죽지 않는다.
##
## 노드는 등불빛과 같은 층(어둠 위)에 앉힌다. 빛이 어둠에 가려지면 말이 안 된다.

## 뽑히기. **쑤욱이다 — 느려야 뽑는 것이 된다.** 빨리 나오면 튀어나온 것이고, 본동작 전의
## 예비 동작(ANIMATION.md)이기도 해서, 이 느림과 다음의 정적이 "겨눴다"를 만든다.
const DRAW_FOR := 0.5
const HOLD_FOR := 0.16
## 뽑혔을 때 자루 끝과 유리 사이의 틈.
const CLEAR := 10.0
## 사라지는 시간과, 사라진 뒤 검기가 나타나기까지의 정적. **이 정적이 "어디서든 벨 수 있다"다**
## - 붙어 있으면 칼이 순간이동한 것이고, 한 숨 떨어져야 칼과 검기가 다른 것이 된다.
const VANISH_FOR := 0.12
const GAP_FOR := 0.06

## 검기. **칼은 사라지고 베는 궤적만 적 위에 나타난다**(회원님). 양끝이 뾰족한 초승달 획이
## 위-오른쪽에서 아래-왼쪽으로 번쩍 그어지고, 이펙트의 공식(ANIMATION.md — 팽창 → 흩어짐 →
## 사라짐)대로 부풀며 스러진다.
const SLASH_ANGLE := 2.4     ## 획이 나아가는 각(라디안, 137도). 위-오른쪽에서 아래-왼쪽
const SLASH_LEN := 470.0     ## 획의 길이. 적 그림(430px)을 끝에서 끝까지 가른다
const SLASH_W := 18.0        ## 한가운데 폭. 양끝은 뾰족하다. **홀쭉해야 날카롭다**(회원님)
const SLASH_IN := 0.08       ## 그어지는 시간. **번쩍이어야 검기다** - 느리면 붓질이 된다
const SLASH_OUT := 0.28      ## 부풀며 스러지는 시간
const SLASH_FAT := 1.7       ## 스러질 때 폭이 이만큼 부푼다

## 칼의 치수. 날 끝에서 자루 끝까지 250px쯤 — **등불의 세 배 가까이 된다**(회원님이 세 번
## 키웠다). 등불에서 제 몸보다 큰 것이 나와야 보구지, 주머니칼이면 시시하다.
## **길고 홀쭉해야 멋이 난다**(회원님: "너무 뚱뚱한 칼같아") - 길이 대 폭이 11:1이다.
const BLADE := 220.0    ## 날 길이 (코등이에서 끝까지)
const BLADE_W := 20.0   ## 날 밑동의 폭. 끝으로 갈수록 좁아진다
const GUARD_W := 64.0   ## 코등이 폭. **이 가로 획 하나가 막대를 칼로 만든다**
const GRIP := 44.0      ## 자루 길이

## **빛의 칼은 겹으로 그린다** — 겉의 번진 빛무리, 비치는 몸, 그리고 흰 심. 한 겹짜리
## 통짜 색은 칼 아이콘이지 빛이 아니다(회원님: "짜치게 생겼는데").
##
## 그리고 **몸이 꽉 차 있으면 쇠가 된다**(회원님: "지금은 진짜 검같아"). 빛이려면
## ① 몸이 비쳐야 하고 ② 자루끝 구슬 같은 쇠붙이 장식이 없어야 하고 ③ 윤곽이 가만히
## 있지 않아야 한다. 심만 꽉 찬 흰색이고 나머지는 전부 반투명이다.
##
## **색은 안 입힌다**(회원님: "칼 색 없에고 빛으로만" - 주황기가 돌면 놋쇠 칼이 된다).
## 조우 화면의 빛살이 흰 것과 같은 이유다 - 등불에서 나온 것들은 흰빛이다.
const HAZE := Color(1.0, 0.98, 0.93)    ## 겉 빛무리. 아주 옅은 온기만 남긴 흰빛
const STEEL := Color(1.0, 1.0, 0.98)    ## 칼 몸. **반투명**
const CORE := Color(1.0, 1.0, 1.0)      ## 심. 흰색. 유일하게 꽉 찬 겹

## 등불 그림(88px)의 유리 위쪽. 여기서 뽑혀 나온다.
const GLASS_TOP := Vector2(0.0, -34.0)

## 도트 한 칸(픽셀). **등불 그림의 도트가 4px라**(16x22 그림을 4배로 놓는다) 거기서 나온
## 것도 같은 굵기로 깎아야 한 물건이다. 몸과 심을 이 칸의 계단으로 그리고(회원님: "도트
## 같은 느낌"), 빛무리만 매끈하게 둔다 - 어차피 디더 셰이더가 점으로 흩는다.
const CELL := 4.0

## **빛으로 이루어진 무기다**(회원님). 쇠라면 가만히 있어야 하지만 빛은 가만히 못 있는다 -
## 겉 빛무리가 숨 쉬듯 일렁인다. 매 프레임 바꾸면 지글거리므로 도트 애니메이션 박자
## (초당 12번)로 끊는다(EFFECT.md).
const WOBBLE := 0.35
const WOBBLE_HZ := 12.0

const SHADER := "res://shaders/DitherLight.gdshader"

## 헛손질. **여느 공격처럼 끝까지 뽑혀 나왔다가, 검기로 넘어가는 그 직전에 빛 알갱이로
## 흩어진다**(회원님) - 뽑히는 동안은 될지 안 될지 알 수 없어야 한다.
const SCATTER_FOR := 0.35    ## 흩어지는 시간
const MOTES := 18            ## 알갱이 수
const SCATTER_REACH := 70.0  ## 알갱이가 날아가는 거리

enum Shape { SWORD, SLASH, MOTES_SHAPE }

var _shape := Shape.SWORD
var _spot := Vector2.ZERO       ## 칼자루 한가운데, 또는 검기가 시작되는 끝
var _facing := -PI / 2          ## 칼끝(획)이 향한 각. 뽑힐 때는 위
var _alpha := 0.0
var _wobble := 1.0              ## 겉 빛무리의 이번 박자 세기
var _reach := 1.0               ## 검기가 그어진 비율. 0에서 1로 훑는다
var _fat := 1.0                 ## 검기의 폭 배수. 스러질 때 부푼다
var _motes: Array = []          ## [출발점, 나는 방향] 짝. 헛손질 때 만든다
var _burst := 0.0               ## 알갱이가 날아간 비율


func _init() -> void:
	var dithered := ShaderMaterial.new()
	dithered.shader = load(SHADER)
	material = dithered


func _process(_delta: float) -> void:
	if _alpha <= 0.01:
		return
	# 박자마다 다른 수를 뽑는다. 황금비를 굴리면 되풀이가 안 보인다(EFFECT.md).
	var beat: float = floorf(Time.get_ticks_msec() * 0.001 * WOBBLE_HZ)
	_wobble = 1.0 - WOBBLE * fmod(beat * 0.618034, 1.0)
	queue_redraw()


## 등불(from)에서 칼이 뽑혀 나왔다 사라지고, 적(to) 위에 검기가 그어진다.
## **획이 다 그어진 순간에 돌아온다** — 부르는 쪽이 이어서 맞는 반응을 터뜨리면 된다.
func strike(from: Vector2, to: Vector2) -> void:
	var glass: Vector2 = from + GLASS_TOP
	# 칼끝이 유리에 걸친 자리에서, 자루까지 다 빠져나온 자리까지.
	var sheathed: Vector2 = glass + Vector2(0.0, BLADE)
	var drawn: Vector2 = glass - Vector2(0.0, GRIP + 6.0 + CLEAR)
	_shape = Shape.SWORD
	_facing = -PI / 2
	Sfx.play(self, Sfx.SHARD, -18.0, 1.25)

	# 쑤욱. 밝아지며 곧게 올라온다.
	var draw_out := create_tween()
	draw_out.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	draw_out.set_parallel()
	draw_out.tween_method(_move, sheathed, drawn, DRAW_FOR)
	draw_out.tween_method(_shine, 0.0, 1.0, DRAW_FOR * 0.6)
	await draw_out.finished
	await get_tree().create_timer(HOLD_FOR).timeout

	# 사라진다. 응축됐던 빛이 풀리는 것 - 다음 순간 적 위에서 획으로 나타난다.
	var gone := create_tween()
	gone.tween_method(_shine, 1.0, 0.0, VANISH_FOR)
	await gone.finished
	await get_tree().create_timer(GAP_FOR).timeout

	# 검기. 위-오른쪽 끝에서 아래-왼쪽으로 **번쩍** 그어진다.
	Sfx.play(self, Sfx.SHARD, -12.0, 0.8)
	_shape = Shape.SLASH
	_facing = SLASH_ANGLE
	_spot = to - Vector2.from_angle(SLASH_ANGLE) * SLASH_LEN * 0.5
	_fat = 1.0
	_alpha = 1.0
	var cut := create_tween()
	cut.tween_method(_sweep, 0.0, 1.0, SLASH_IN)
	await cut.finished

	# 갈랐다. 부르는 쪽은 여기서 이어받고, 획은 기다리지 않고 부풀며 스러진다.
	var fade := create_tween()
	fade.set_parallel()
	fade.tween_method(_fatten, 1.0, SLASH_FAT, SLASH_OUT)
	fade.tween_method(_shine, 1.0, 0.0, SLASH_OUT)


## 헛손질(from은 등불 자리). **여느 공격과 똑같이 끝까지 뽑혀 나와 멎었다가**, 검기가
## 나가야 할 바로 그 순간에 빛 알갱이로 흩어진다. 다 흩어진 뒤에 돌아온다 -
## 부르는 쪽은 그다음에 "헛손질했다"를 띄운다.
func fumble(from: Vector2) -> void:
	var glass: Vector2 = from + GLASS_TOP
	var sheathed: Vector2 = glass + Vector2(0.0, BLADE)
	var drawn: Vector2 = glass - Vector2(0.0, GRIP + 6.0 + CLEAR)
	_shape = Shape.SWORD
	_facing = -PI / 2
	Sfx.play(self, Sfx.SHARD, -18.0, 1.25)

	# 쑤욱. 공격과 똑같이 - 뽑히는 동안은 헛손질이 될지 알 수 없어야 한다.
	var draw_out := create_tween()
	draw_out.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	draw_out.set_parallel()
	draw_out.tween_method(_move, sheathed, drawn, DRAW_FOR)
	draw_out.tween_method(_shine, 0.0, 1.0, DRAW_FOR * 0.6)
	await draw_out.finished
	await get_tree().create_timer(HOLD_FOR).timeout

	# 검기가 나가야 할 순간 - 대신 흩어진다. 알갱이들이 보이던 날 위에서 태어나
	# 제각각 날아가므로, 첫 장은 칼이 알갱이로 부서진 것으로 보인다.
	Sfx.play(self, Sfx.DAMP, -14.0)
	_motes.clear()
	for i in MOTES:
		var start: Vector2 = drawn + Vector2(
			randf_range(-BLADE_W * 0.5, BLADE_W * 0.5),
			randf_range(-BLADE, GRIP * 0.5))
		# 위쪽으로 반, 옆으로 반 - 아래로 떨어지면 부스러기지 빛이 아니다.
		var away := Vector2(randf_range(-1.0, 1.0), -randf_range(0.2, 1.0)).normalized()
		_motes.append([start, away * randf_range(0.4, 1.0)])
	_shape = Shape.MOTES_SHAPE
	var scatter := create_tween()
	scatter.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	scatter.set_parallel()
	scatter.tween_method(func(b: float) -> void:
		_burst = b
		queue_redraw(), 0.0, 1.0, SCATTER_FOR)
	scatter.tween_method(_shine, 1.0, 0.0, SCATTER_FOR)
	await scatter.finished


func _move(next: Vector2) -> void:
	_spot = next
	queue_redraw()


func _shine(bright: float) -> void:
	_alpha = bright
	queue_redraw()


func _sweep(frac: float) -> void:
	_reach = frac
	queue_redraw()


func _fatten(fat: float) -> void:
	_fat = fat
	queue_redraw()


func _draw() -> void:
	if _alpha <= 0.01:
		return
	var spun := Transform2D(_facing, _spot.round())
	match _shape:
		Shape.SWORD:
			_sword(spun)
		Shape.SLASH:
			_slash(spun)
		Shape.MOTES_SHAPE:
			# 흩어진 알갱이. 칸 하나짜리 흰 점들이 제각각 날아가며 스러진다.
			for mote in _motes:
				var at: Vector2 = mote[0] + mote[1] * SCATTER_REACH * _burst
				var snapped: Vector2 = (at / CELL).floor() * CELL
				draw_rect(Rect2(snapped, Vector2(CELL, CELL)), Color(CORE, _alpha))


## 칼. 세로로 선 자세 전용이다(칼은 뽑혀 서 있기만 하고, 베는 것은 검기가 한다).
func _sword(spun: Transform2D) -> void:
	# 빛무리. **넓어질수록 옅어지는 겹을 여러 장 둘러** 그라디언트를 흉내 낸다 - 등불빛
	# (`LampGlow`)이 매끈한 원 그라디언트를 디더로 흩듯, 이 칼도 같은 셰이더가 흩는다.
	# **바깥 겹일수록 박자 따라 크게 넘실댄다** - 윤곽이 박제되면 쇠가 되고, 숨 쉬어야 빛이 된다.
	for coat in [[4.2, 30.0, 0.06], [3.2, 22.0, 0.10], [2.3, 14.0, 0.15], [1.6, 7.0, 0.22]]:
		var spread: float = 1.0 + (coat[0] - 1.0) * lerpf(1.0, _wobble, coat[0] * 0.25)
		draw_colored_polygon(_blade(spun, spread, coat[1]), Color(HAZE, _alpha * coat[2]))

	# 몸과 심. **칸의 계단으로 깎는다.** 날은 위(끝)로 갈수록 좁아진다.
	var base: Vector2 = (_spot / CELL).floor() * CELL
	var rows: int = int(BLADE / CELL)
	for i in rows:
		var t: float = (float(i) + 0.5) / float(rows)   # 0 끝 -> 1 밑동
		# **끝까지 완만하게 가늘어진다.** 두 토막 직선보다 곡선 하나가 홀쭉하고 미끈하다.
		var taper: float = pow(t, 0.35)
		var y: float = base.y - BLADE + float(i) * CELL
		_row(base.x, y, BLADE_W * 0.5 * taper, Color(STEEL, _alpha * 0.65))
		# 심은 날 밑동 쪽 8할에만 산다. 끝 두 칸이 몸 색만 남아야 끝이 뾰족하게 읽힌다
		if t > 0.16:
			_row(base.x, y, BLADE_W * 0.2, Color(CORE, _alpha))
	# 코등이. 가로 한 줄에 **양끝만 한 칸 처진다** - 날개처럼. 통짜 두 단은 뚱뚱했다.
	# **꽉 찬 흰색이어야 한다.** 반투명이면 뒤의 주황 빛줄기가 비쳐 섞여서 갈색빛이 돈다
	# (회원님: "손잡이쪽에 갈색빛 돌잖아") - 더하기 합성에서 흰빛으로 남으려면 다 채워야 한다.
	_row(base.x, base.y, GUARD_W * 0.5, Color(CORE, _alpha))
	var wing: float = maxf(roundf(GUARD_W * 0.5 / CELL), 1.0) * CELL
	draw_rect(Rect2(Vector2(base.x - wing, base.y + CELL), Vector2(CELL, CELL)), Color(CORE, _alpha))
	draw_rect(Rect2(Vector2(base.x + wing - CELL, base.y + CELL), Vector2(CELL, CELL)), Color(CORE, _alpha))
	# 자루. 한 칸 굵기의 줄기 - 자루끝 구슬 같은 쇠붙이 장식은 빛에 없다.
	var grips: int = int(GRIP / CELL)
	for i in grips:
		_row(base.x, base.y + CELL * float(2 + i), CELL * 0.5, Color(CORE, _alpha * 0.85))


## 칸 계단의 한 줄. 반폭을 칸 격자로 끊어 네모 하나로 그린다.
func _row(cx: float, y: float, half: float, color: Color) -> void:
	var w: float = maxf(roundf(half / CELL), 1.0) * CELL
	draw_rect(Rect2(Vector2(cx - w, y), Vector2(w * 2.0, CELL)), color)


## 검기. 빛무리는 매끈한 획으로, 몸과 심은 **가로 칸줄의 계단**으로 깎는다 - 사선이
## 계단으로 내려가는 것이 도트의 획이다. 칼과 같은 재료라야 그 칼이 벤 것으로 읽힌다.
func _slash(spun: Transform2D) -> void:
	for coat in [[3.4, 0.05], [2.4, 0.10], [1.7, 0.16]]:
		draw_colored_polygon(_streak(spun, coat[0] * _wobble), Color(HAZE, _alpha * coat[1]))
	var slope := Vector2.from_angle(SLASH_ANGLE)
	# 획을 세로 방향 칸줄로 자른다. 사선 폭을 가로 폭으로 바꿔야 한다.
	var stretch: float = 1.0 / maxf(absf(slope.y), 0.3)
	var steps: int = int(SLASH_LEN / CELL * absf(slope.y))
	for i in steps:
		var t: float = (float(i) + 0.5) / float(steps)   # 획을 따라 0 -> 1
		if t > _reach:
			break
		var along: Vector2 = _spot + slope * SLASH_LEN * t
		var snapped: Vector2 = (along / CELL).floor() * CELL
		var w: float = SLASH_W * 0.5 * _fat * pow(sin(PI * t), 0.6) * stretch
		_row(snapped.x, snapped.y, w, Color(STEEL, _alpha * 0.5))
		_row(snapped.x, snapped.y, w * 0.45, Color(CORE, _alpha))


## 획의 꼴. 길이 방향(+x)으로 _reach만큼 드러나고, 폭은 한가운데가 제일 두툼하다.
func _streak(spun: Transform2D, width: float) -> PackedVector2Array:
	var seen: float = SLASH_LEN * _reach
	var tops: Array[Vector2] = []
	var bottoms: Array[Vector2] = []
	for i in 9:
		var x: float = seen * float(i) / 8.0
		# sin 곡선이 양끝을 0으로 데려간다. 지수를 낮춰 가운데를 넓게 편다.
		var w: float = SLASH_W * 0.5 * width * _fat * pow(sin(PI * x / SLASH_LEN), 0.6)
		w = maxf(w, 0.5)
		tops.append(spun * Vector2(x, -w))
		bottoms.append(spun * Vector2(x, w))
	bottoms.reverse()
	return PackedVector2Array(tops + bottoms)


## 날의 꼴. 밑동에서 끝으로 갈수록 좁아지고 끝이 뾰족하다. width로 겹의 폭을,
## reach로 끝이 얼마나 더 나가는지를 정한다(빛무리는 날보다 살짝 길다).
func _blade(spun: Transform2D, width: float, reach: float) -> PackedVector2Array:
	var w: float = BLADE_W * 0.5 * width
	var tip: float = BLADE + reach
	return PackedVector2Array([
		spun * Vector2(tip, 0.0),
		spun * Vector2(tip * 0.86, -w * 0.72),
		spun * Vector2(0.0, -w),
		spun * Vector2(0.0, w),
		spun * Vector2(tip * 0.86, w * 0.72),
	])


## 코등이의 꼴. size로 겹의 폭을 정한다.
func _guard(spun: Transform2D, size: float) -> PackedVector2Array:
	var reach: float = GUARD_W * 0.5
	return PackedVector2Array([
		spun * Vector2(10.0 * size, -reach),
		spun * Vector2(-1.0 - 3.0 * size, -reach * 0.9),
		spun * Vector2(-5.0 - 3.0 * size, 0.0),
		spun * Vector2(-1.0 - 3.0 * size, reach * 0.9),
		spun * Vector2(10.0 * size, reach),
		spun * Vector2(3.0, 0.0),
	])
