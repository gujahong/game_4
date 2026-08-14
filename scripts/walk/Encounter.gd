extends Node2D
class_name Encounter

## 조우 연출 — **검은 화면에 흰 선뿐이다.**
##
## 앞선 방식은 일러스트 한 장을 화면에 채우고 그 안으로 걸어 들어가는 것이었다. 두 가지가
## 걸렸다. 그것이 배경과 같은 중간 회색이라 **묻혀서 안 보였고**(화면 필터가 4계조로 깎으니
## 밝기를 올려도 같이 밝아질 뿐이었다), 장소마다 일러스트를 뽑아야 해서 값이 들었다.
##
## 선으로만 그리면 둘 다 사라진다. **묻힐 배경이 없고, 뽑을 그림도 없다(0 generation).**
##
## 언더테일 전투 화면이 같은 형식이다 - 검정 바탕, 흰 선, 색을 가진 것 하나. 우연이 아니라
## 우리 규칙(*"화면에서 색을 가진 것은 등불뿐"*)과 같은 데서 나온 형식이다.
##
## 그리고 회원님이 주신 참고 그림이 예외 없이 1점 투시였다. 그걸 그림에 맡기지 않고 직접
## 그리는 것이니 원래 의도에 오히려 가깝다.

const BATTLE_SCENE := "res://scenes/Battle.tscn"
const TARGET := "res://assets/enemies/watcher.png"
## 탑다운 맵에서 쓰는 그 주인공을 그대로 쓴다. **북쪽(뒷모습) 걷기**가 이 화면에 맞는다 -
## 등을 보이고 안으로 걸어 들어가는 그림이라서다. 떠 있는 등불도 `HeroSprite`가 같이 그린다.
const FRAMES := "res://assets/characters/pilgrim_rot/pilgrim_frames.tres"
## 16x32짜리라 그대로 두면 너무 작다. 정수배로만 키운다.
const FIGURE_ZOOM := 3

const SCREEN := Vector2(960, 540)
## 소실점 = 지평선. 위쪽 3분의 1쯤에 둔다 - **바닥이 넓게 보여야 서 있는 자리가 잡힌다.**
const VANISH := Vector2(480, 190)

## 바닥으로 뻗는 세로선의 수와, 다가오는 가로선의 수.
##
## 처음엔 소실점에서 사방으로 뻗는 선과 동심 사각형을 그렸는데 **복도가 아니라 터널 정면**으로
## 읽혔다. 바닥이 없으니 내가 어디 서 있는지가 안 잡혔던 것이다.
##
## 선은 적을수록 낫다. 검은 자리가 이 화면의 알맹이다.
const DEPTH_LINES := 9
const RUNGS := 9

## 바닥 세로선이 화면 아래에서 벌어지는 폭(화면 너비의 배수). 1보다 크면 화면 밖까지 뻗는다.
const FLOOR_SPREAD := 2.2

## 양옆으로 물러나는 책장. **여기가 서고라는 것을 이것 하나가 말한다.**
##
## 바닥 가로선과 **같은 `_flow`를 쓴다.** 깊이 하나만 정하면 자리도 크기도 거기서 나오므로
## (`y = 지평선 + 깊이/d`, `크기 = 1/d`), 걸으면 지평선에서 솟아 커지며 스쳐 지나간다.
## 장식이 아니라 진짜 원근 운동이고, 그래서 **책장은 흘러가는데 그것은 안 커지는** 것이 보인다.
const SHELVES := 6
const SHELF_X := 0.34    ## 가운데에서 얼마나 옆인가(`FLOOR_SPREAD` 폭에 대한 비율, 깊이 1 기준)
const SHELF_W := 110.0   ## 깊이 1에서의 너비와 높이(픽셀)
const SHELF_H := 320.0
const SHELF_ROWS := 4    ## 칸 수
## 책장이 차지하는 **깊이.** 이게 있어야 옆면이 생기고 상자가 된다 - 없으면 정면 사각형뿐이라
## 아무리 꾸며도 평면으로 보인다.
const SHELF_DEEP := 0.55

## 위아래를 채우는 것들. **책장만 있으면 좌우만 있고 상하가 비어서 복도가 납작하다.**
const CEILING := 640.0   ## 천장 높이(깊이 1 기준). 바닥이 0이다
const LAMPS := 5         ## 천장에 매달린 등
const PAPERS := 16       ## 허공에 떠다니는 종이

## 걷는 속도(깊이 0~1 기준). **아무 일도 안 일어나는 시간이 외로움을 만든다.**
##
## 0.085(12초) → 0.045(22초) → 0.037(27초)로 늘렸다가 **되돌렸다.** 뒤쪽이 어두워지면
## 화면이 거의 안 바뀌어서, 걸음이 길면 회원님 말씀대로 **멈춘 줄 알게 된다.**
## 도착까지 빠르게 가고 그 대신 암전으로 사이를 둔다.
const WALK_SPEED := 0.058

## 그것의 크기(화면 높이에 대한 비율).
##
## **처음부터 크다**(회원님). 점에서 자라나면 "나타나는" 것이 되는데, 그것은 나타나지 않는다 -
## 처음부터 거기 그만큼 크게 있었고 내가 다가갈 뿐이다. 조우 연출을 만들 때 세운 규칙
## (*"그것은 안 움직이고, 내가 작아진다"*)과 같은 말이다.
const TARGET_FAR := 0.45
## **끝에는 화면을 넘어간다.** 1보다 크면 위아래가 화면 밖으로 나가서 다 안 보이게 된다 -
## 안 보이는 것이 무섭고, 화면 안에 얌전히 들어오면 그냥 큰 그림이다.
const TARGET_NEAR := 2.1

## 그것의 숨과 회전. **살아 있는지 아닌지 알 수 없을 만큼 느리게.**
## 한 바퀴 도는 데 100초쯤 걸린다.
const BREATH := 10.0
const BREATH_SPEED := 0.35
const SPIN_SPEED := 0.062

## 가장자리의 기운을 바깥으로 퍼지게 하는 셰이더.
const AURA_SHADER := "res://shaders/AuraRipple.gdshader"
## 등불 자리에 구멍을 뚫어놓고 화면을 덮는 판.
const VIGNETTE_SHADER := "res://shaders/Vignette.gdshader"

var _lines: Node2D
var _target: Sprite2D
var _figure: HeroSprite
var _lamp: LampGlow
var _shade: ColorRect
var _flash: ColorRect

## 어둠이 먹어드는 구간(깊이). **시간이 아니라 거리에 물린다** - 멈추면 어두워지는 것도
## 멎어야 한다(회원님). 컷신이 아니라 내가 다가가서 벌어지는 일이다.
const DARK_FROM := 0.45
const DARK_TO := 1.0
const DARK_LAMP := 0.22   ## 다 먹혔을 때 등불이 눌린 크기

## 뚫린 구멍이 다 열렸을 때의 반경. 화면 구석까지 덮으려면 1보다 커야 한다.
const OPEN_WIDE := 1.7

## 닿은 뒤: 잠깐의 암전, 그리고 등불부터 빛이 들어오는 시간.
##
## **암전을 짧게 둔다.** 길면 회원님 말씀대로 멈춘 줄 알고 키를 놓게 된다 - 연출이 아니라
## 고장으로 읽힌다. 대신 **가장 어두운 자리를 지나야 다음 빛이 밝다**.
## 닿은 뒤의 시간표(초). **깜빡… 깜빡… 번쩍! 화아악!**
##
## 등불이 한 번에 팟 켜지면 그냥 조명이 들어온 것이다. 두 번 힘없이 깜빡이고, 사이에 어둠을
## 두고, 그 다음 번쩍해야 **되살아나는 것**으로 읽힌다.
## 길이를 0.20에서 0.75로 늘렸다. **짧으면 스위치를 딸깍한 것**이고, 길어야 불이 스르르
## 붙었다 사그라지는 것으로 읽힌다.
const BLINKS := [
	[3.10, 0.75, 0.30],   # [시각, 길이, 세기]
	[4.35, 0.85, 0.45],
]
const FLASH_AT := 5.55
const FLASH_FOR := 0.55
const FLASH_SIZE := 5.5    ## 번쩍일 때 등불이 부푸는 크기
const FLASH_GLARE := 0.62  ## 그때 주황 판이 덮는 정도. 눈을 때리는 부분이다
const OPEN_AT := 6.05   ## 조리개가 열리기 시작하는 시각. 앞의 3초는 완전한 암전이다
const OPEN_FOR := 3.4   ## 2.0은 눈에 확 열리다 못해 그냥 켜진 것으로 보였다
const FLOOD_FOR := 1.4  ## 주황빛이 화면을 삼키는 시간
const HOLD := 0.7       ## 다 덮인 채로 두는 시간. 이 사이에 넘겨야 이음매가 안 보인다

var _depth := 0.0   ## 0이면 맨 끝, 1이면 닿음
var _flow := 0.0    ## 사각 테가 흘러나온 양. 걸을 때만 늘어난다
var _arrived := -1.0  ## 닿은 뒤 흐른 시간. 음수면 아직 걷는 중이다


func _ready() -> void:
	_build()
	_place()


func _process(delta: float) -> void:
	if _arrived >= 0.0:
		_arrived += delta
		_close_in()
		# 다 덮인 뒤 잠깐 그대로 둔다. **화면이 주황으로 균일할 때 넘겨야 이음매가 안 보인다** -
		# 덮이자마자 바꾸면 툭 끊긴 것으로 읽힌다.
		if _arrived >= OPEN_AT + OPEN_FOR + FLOOD_FOR + HOLD:
			get_tree().change_scene_to_file(BATTLE_SCENE)
		return

	# 떠 있는 것들은 걸음과 무관하게 흔들리므로 멈춰 있어도 다시 그려야 한다.
	_lines.queue_redraw()
	var walking := Input.is_action_pressed("ui_up")
	if walking:
		_depth = minf(_depth + WALK_SPEED * delta, 1.0)
		_flow += WALK_SPEED * delta * float(RUNGS)
	_place(walking)
	if _depth >= 1.0:
		_arrived = 0.0


## 등불 자리에 뚫린 구멍의 반경을 정한다. 0이면 완전한 암전이다.
func _hole(radius: float, dim: float = 0.0) -> void:
	_shade.material.set_shader_parameter("radius", maxf(radius, 0.0))
	_shade.material.set_shader_parameter("dim", clampf(dim, 0.0, 1.0))
	_shade.material.set_shader_parameter("light_position", _lamp.position / SCREEN)


## 닿은 뒤. **암전 → 잠깐 사이 → 등불부터 빛이 들어오며 세상이 드러남 → 전투.**
##
## 이 순간만 시간에 물린다. 어둠이 먹어드는 것은 걸어야 진행되지만(`_place`), 여기서부터는
## 이미 벌어진 일이라 내가 멈춘다고 멎지 않는다.
func _close_in() -> void:
	# 조리개가 열리기 전까지는 **완전한 암전**이다. 등불까지 꺼서 볼 것이 하나도 없다.
	if _arrived < OPEN_AT:
		_hole(0.0)
		_blink(_arrived)
		return

	# 번쩍한 그 자리에서 조리개가 열린다. **빛 그림이 커지는 게 아니라 그 반경 안이 진짜로
	# 보인다.** 앞이 느리고 끝이 급한 곡선이라야 "확" 열린다.
	var open: float = clampf((_arrived - OPEN_AT) / OPEN_FOR, 0.0, 1.0)
	_lamp.visible = true
	_lamp.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	_hole(pow(open, 2.4) * OPEN_WIDE, (1.0 - open) * 0.75)
	_lamp.scale = Vector2.ONE * lerpf(DARK_LAMP * 2.4, 7.0, pow(open, 2.0))

	# 다 열린 뒤에는 주황빛이 화면을 삼킨다. 아무것도 안 보이는 채로 전투로 넘어간다.
	if open >= 1.0:
		var flood: float = clampf((_arrived - OPEN_AT - OPEN_FOR) / FLOOD_FOR, 0.0, 1.0)
		_lamp.scale = Vector2.ONE * lerpf(7.0, 64.0, pow(flood, 1.5))
		# **등불을 키우는 것만으로는 화면이 안 덮인다.** 빛이 둥글게 퍼지므로 네 귀퉁이가
		# 끝까지 남는다. 주황 판을 맨 위에 덮어야 눈이 머는 것처럼 다 가려진다.
		_flash.color.a = pow(flood, 1.7)


## 암전 속에서 등불이 깜빡이다 번쩍한다. 켜졌다 꺼지는 것을 사인 한 마루로 만든다 -
## 네모나게 켜면 조명 스위치가 되고, 부드럽게 들고 나야 불이 붙으려다 만 것으로 읽힌다.
func _blink(t: float) -> void:
	var glow := 0.0
	for entry in BLINKS:
		var at: float = entry[0]
		var span: float = entry[1]
		if t >= at and t < at + span:
			glow = maxf(glow, entry[2] * sin((t - at) / span * PI))
	# **번쩍은 깜빡임과 다른 물건이다.** 같은 자로 재면 조금 센 깜빡임일 뿐이라, 등불을 훨씬
	# 크게 부풀리고 주황 판까지 잠깐 씌워서 눈을 때린다.
	var strike := 0.0
	if t >= FLASH_AT and t < FLASH_AT + FLASH_FOR:
		strike = sin((t - FLASH_AT) / FLASH_FOR * PI)
	glow = maxf(glow, strike)
	_lamp.visible = glow > 0.01
	_lamp.self_modulate = Color(1.0, 1.0, 1.0, glow)
	_lamp.scale = Vector2.ONE * lerpf(DARK_LAMP * 0.5, FLASH_SIZE, pow(strike, 0.6)) \
		if strike > 0.01 else Vector2.ONE * lerpf(DARK_LAMP * 0.5, DARK_LAMP * 2.4, glow)
	_flash.color.a = pow(strike, 1.6) * FLASH_GLARE


func _place(walking: bool = false) -> void:
	var grow: float = lerpf(TARGET_FAR, TARGET_NEAR, pow(_depth, 2.4))
	if _target.texture != null:
		var scale_now: float = SCREEN.y * grow / float(_target.texture.get_size().y)
		_target.scale = Vector2(scale_now, scale_now)
	# 그것은 아주 느리게 오르내리고 빙빙 돈다. **살아 있는지 아닌지 알 수 없을 만큼** 느려야
	# 한다 - 빠르면 기계가 되고, 멎어 있으면 그림이 된다.
	var now: float = float(Time.get_ticks_msec()) * 0.001
	_target.position = VANISH + Vector2(0.0, sin(now * BREATH_SPEED) * BREATH)
	_target.rotation = now * SPIN_SPEED
	# **다가갈수록 세상이 걷힌다.** 바닥·책장·천장이 흐려져서 끝에는 그것과 내 등불만 남는다.
	# 끝까지 복도가 그대로면 "도착했다"가 눈에 안 보인다.
	#
	# 선을 그리는 판 전체에 한 번에 거는 것이라 그리는 쪽은 이걸 몰라도 된다.
	_lines.modulate.a = 1.0 - smoothstep(0.35, 0.92, _depth)

	# 다가갈수록 어둠이 먹어든다. **등불까지 눌린다** - 그래야 닿는 순간 그 자리에서
	# 불이 되살아나는 것으로 읽힌다. 걸음에 물려 있으므로 멈추면 이것도 멎는다.
	# **등불 쪽만 남기고 어둠이 조여든다.** 통짜 검은 판을 알파로 여닫으면 화면이 흐려질 뿐이라
	# 세상이 안 사라진다. 구멍의 반경을 줄여야 바깥부터 먹히고 등불 쪽만 남는다.
	var eaten: float = smoothstep(DARK_FROM, DARK_TO, _depth)
	_lamp.scale = Vector2.ONE * lerpf(1.0, DARK_LAMP, eaten)
	# 구멍이 줄면서 **남은 자리도 같이 흐려진다.** 줄기만 하면 조리개처럼 보인다.
	_hole(lerpf(OPEN_WIDE, 0.0, eaten), eaten * 0.92)

	_figure.show_state("north", walking)
	_lamp.position = _figure.position + _figure.lantern_at() * float(FIGURE_ZOOM)
	_lines.queue_redraw()


func _build() -> void:
	_lines = _Lines.new()
	add_child(_lines)

	# 그것은 선보다 위에 그린다. 선이 위를 지나가면 그것이 뒤에 있는 것처럼 보인다.
	_target = Sprite2D.new()
	_target.texture = load(TARGET)
	# 가장자리에서 기운이 바깥으로 퍼진다. **세로로 미는 `PortalWave`는 원형에 안 맞았다** -
	# 폭을 2에서 16까지 올려도 "일렁인다"가 아니라 "그림이 흔들린다"로 보였다.
	# 반지름 방향으로 밀어야 뿜어져 나오는 것이 된다.
	var wave := ShaderMaterial.new()
	wave.shader = load(AURA_SHADER)
	_target.material = wave
	_target.z_index = 1
	add_child(_target)

	# 나는 화면 아래 가운데에 등을 보이고 서 있다. **크기가 안 변한다** - 검은 공간에는
	# 견줄 것이 없어서 내가 작아지는 것과 그것이 커지는 것이 같은 말이 된다.
	_figure = HeroSprite.new()
	_figure.sprite_frames = load(FRAMES)
	_figure.scale = Vector2(FIGURE_ZOOM, FIGURE_ZOOM)
	_figure.position = Vector2(SCREEN.x * 0.5, SCREEN.y - 96.0)
	_figure.z_index = 2
	add_child(_figure)

	# 화면을 덮는 검은 판. **등불보다 아래**에 둬서, 다 덮이고 나면 등불만 남게 한다.
	var shade_layer := CanvasLayer.new()
	shade_layer.layer = 50
	add_child(shade_layer)
	_shade = ColorRect.new()
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hole := ShaderMaterial.new()
	hole.shader = load(VIGNETTE_SHADER)
	_shade.material = hole
	shade_layer.add_child(_shade)

	# 눈이 머는 주황 판. **맨 위**에 있어야 전부 덮는다.
	var flash_layer := CanvasLayer.new()
	flash_layer.layer = 70
	add_child(flash_layer)
	_flash = ColorRect.new()
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1.0, 0.78, 0.42, 0.0)
	flash_layer.add_child(_flash)

	# 등불은 필터 밖이자 맨 위다. 이 화면에서 색을 가진 것은 이것뿐이다.
	var lamp_layer := CanvasLayer.new()
	lamp_layer.layer = 60
	add_child(lamp_layer)
	_lamp = LampGlow.new()
	# 이 화면에는 등불 말고 색이 없어서, 맵보다 크고 촘촘해도 된다.
	_lamp.glow_size = 224
	lamp_layer.add_child(_lamp)


## 한 칸에 꽂힌 책들. **틀과 가로줄만으로는 그냥 상자다** — 책장을 책장으로 만드는 것은
## 높이가 들쭉날쭉한 세로 막대들이다.
##
## 높이는 자리에서 바로 뽑아 쓴다(`seed`). 무작위로 뽑으면 매 프레임 다시 흔들려서 책이
## 떠는 것처럼 보인다.
class _Lines extends Node2D:
	const BOOK_WIDE := 3.0    ## 책 한 권의 폭(픽셀). 이보다 좁아지면 안 그린다
	const BOOK_LOW := 0.45    ## 칸 높이에 대한 가장 낮은 책
	const BOOK_HIGH := 0.92

	## 네 귀퉁이로 둘러싸인 면을 빗금으로 채운다. `a`-`b`가 아랫변, `d`-`c`가 윗변이다.
	##
	## **면을 따라 보간해서 긋는다.** 화면에서 곧게 그으면 원근이 무너진다 - 빗금도 면 위에
	## 놓인 선이라 소실점 쪽으로 좁아져야 한다.
	const HATCH := 7
	const HATCH_SKEW := 0.42   ## 윗변에서 얼마나 밀지. 0이면 세로줄이라 빗금이 아니다

	func _hatch(a: Vector2, b: Vector2, c: Vector2, d: Vector2, colour: Color) -> void:
		if a.distance_to(b) < 6.0:
			return   # 멀어서 뭉갤 자리에는 안 긋는다
		for i in HATCH:
			var t: float = (float(i) + 0.5) / float(HATCH)
			var up: float = t - HATCH_SKEW
			if up < 0.0 or up > 1.0:
				continue
			draw_line(a.lerp(b, t), d.lerp(c, up), colour, 1.0)


	## 허공에 뜬 정육면체. 앞면·뒷면과 그 사이를 잇는 모서리 넷을 그린다.
	## **잇는 모서리가 소실점으로 모이는 것**이 정육면체로 보이게 하는 전부다.
	func _cube(vanish: Vector2, deep: float, x: float, height: float,
			d: float, size: float, colour: Color) -> void:
		# 앞뒤 두께. 옆 거리 한 칸이 깊이로는 `1/deep` 칸이라야 정육면체가 된다.
		var half_d: float = size / deep * 0.5
		var dn: float = d - half_d
		var df: float = d + half_d
		if dn <= 0.25:
			return
		var half: float = size * 0.5
		for at in [dn, df]:
			draw_polyline([
				_post(vanish, deep, x - half, height - half, at),
				_post(vanish, deep, x + half, height - half, at),
				_post(vanish, deep, x + half, height + half, at),
				_post(vanish, deep, x - half, height + half, at),
				_post(vanish, deep, x - half, height - half, at),
			] as PackedVector2Array, colour, 1.0)
		for corner in [Vector2(-half, -half), Vector2(half, -half),
				Vector2(half, half), Vector2(-half, half)]:
			draw_line(_post(vanish, deep, x + corner.x, height + corner.y, dn),
				_post(vanish, deep, x + corner.x, height + corner.y, df), colour, 1.0)


	## 세상 좌표를 화면으로. `x`는 가운데에서의 옆 거리, `height`는 바닥에서의 높이,
	## `d`는 깊이다(전부 깊이 1에서 잰 값). **원근은 나누기 하나뿐이다.**
	func _post(vanish: Vector2, deep: float, x: float, height: float, d: float) -> Vector2:
		return Vector2(vanish.x + x / d, vanish.y + (deep - height) / d)

	## 선반에 꽂힌 책들. 옆면 위에 서 있으므로 **깊이 방향으로 늘어선다** - 그래서 이것들도
	## 소실점 쪽으로 좁아지며 모인다.
	func _books(vanish: Vector2, deep: float, x: float, tall: float,
			dn: float, df: float, lit: float, seed: int) -> void:
		var rows: int = Encounter.SHELF_ROWS
		var row_high: float = tall / float(rows)
		# **문턱을 두면 책이 툭 튀어나온다.** 가까워질수록 서서히 진해지게 한다 - 회원님이
		# "책장이 가까워지면 책 모양이 바뀐다"고 하신 것이 이 팝이었다.
		var showing: float = smoothstep(3.0, 9.0, row_high / dn)
		if showing <= 0.01:
			return
		var books := int((df - dn) / 0.035)
		for row in rows:
			var stand: float = tall * float(row) / float(rows)
			for i in books:
				var jitter: float = fposmod(sin(float(seed + row * 131 + i * 31)) * 43758.5453, 1.0)
				if jitter < 0.14:
					continue   # 빈틈이 있어야 빽빽한 무늬가 아니라 꽂힌 것으로 보인다
				var d: float = lerpf(dn, df, (float(i) + 0.5) / float(books))
				var high: float = stand + row_high * lerpf(BOOK_LOW, BOOK_HIGH, jitter)
				draw_line(_post(vanish, deep, x, stand, d), _post(vanish, deep, x, high, d),
					Color(1, 1, 1, lit * showing * lerpf(0.4, 0.9, jitter)), 1.0)
	func _draw() -> void:
		var owner_scene := get_parent() as Encounter
		if owner_scene == null:
			return
		var vanish: Vector2 = Encounter.VANISH
		var screen: Vector2 = Encounter.SCREEN
		var deep: float = screen.y - vanish.y   # 지평선에서 화면 아래까지

		# 지평선. 한 줄이지만 이게 있어야 위가 허공이고 아래가 바닥이 된다.
		draw_line(Vector2(0.0, vanish.y), Vector2(screen.x, vanish.y), Color(1, 1, 1, 0.20), 1.0)

		# 바닥의 세로선. 소실점에서 화면 아래로 부챗살처럼 벌어진다.
		#
		# **이 선들은 안 움직인다.** 앞으로 곧게 걸을 때 세로선은 제자리고 가로선만 다가온다 -
		# 그게 실제 원근이고, 전부 같이 움직이면 눈이 속지 않는다.
		var wide: float = screen.x * Encounter.FLOOR_SPREAD
		for i in Encounter.DEPTH_LINES:
			var across: float = float(i) / float(Encounter.DEPTH_LINES - 1)
			var foot := Vector2(vanish.x + (across - 0.5) * wide, screen.y)
			draw_line(vanish, foot, Color(1, 1, 1, 0.16), 1.0)

		# 바닥의 가로선. **화면 y는 거리의 역수**라, 멀수록 촘촘히 모여 지평선에 붙는다.
		# 균등하게 놓으면 바닥이 눕지 않고 벽처럼 선다.
		for i in Encounter.RUNGS:
			var far: float = float(i) + 1.0 - fposmod(owner_scene._flow, 1.0)
			if far <= 0.0:
				continue
			var y: float = vanish.y + deep / far
			if y > screen.y:
				continue
			# 지평선에 가까울수록 흐리게. 안 그러면 한 줄에 뭉쳐 지저분해진다.
			var lit: float = minf(1.0 / far, 1.0) * 0.45
			draw_line(Vector2(0.0, y), Vector2(screen.x, y), Color(1, 1, 1, lit), 1.0)

		# 양옆의 책장. 가로선과 같은 깊이 자를 쓰고, **앞뒤로 두께가 있다.**
		for i in Encounter.SHELVES:
			var dn: float = float(i) + 1.0 - fposmod(owner_scene._flow, 1.0)
			if dn <= 0.35:
				continue   # 너무 가까우면 화면을 뒤덮으므로 지나간 것으로 친다
			var df: float = dn + Encounter.SHELF_DEEP
			var lit: float = minf(1.0 / dn, 1.0) * 0.55
			var inner: float = Encounter.SHELF_X * wide
			var outer: float = inner + Encounter.SHELF_W
			var tall: float = Encounter.SHELF_H

			for side in [-1.0, 1.0]:
				var xi: float = inner * side
				var xo: float = outer * side

				# 복도를 향한 옆면. **위아래 모서리가 소실점으로 모이는 것이 입체의 전부다.**
				draw_polyline([
					_post(vanish, deep, xi, 0.0, dn), _post(vanish, deep, xi, 0.0, df),
					_post(vanish, deep, xi, tall, df), _post(vanish, deep, xi, tall, dn),
				] as PackedVector2Array, Color(1, 1, 1, lit), 1.0)

				# 이쪽을 보고 있는 앞면.
				draw_polyline([
					_post(vanish, deep, xi, 0.0, dn), _post(vanish, deep, xo, 0.0, dn),
					_post(vanish, deep, xo, tall, dn), _post(vanish, deep, xi, tall, dn),
					_post(vanish, deep, xi, 0.0, dn),
				] as PackedVector2Array, Color(1, 1, 1, lit), 1.0)

				# 옆면은 복도 안쪽을 향해 그늘진 면이다. **빗금으로 어둠을 표현한다** -
				# 선으로만 그리는 그림에서 면을 어둡게 하는 방법은 이것뿐이다.
				_hatch(
					_post(vanish, deep, xi, 0.0, dn), _post(vanish, deep, xi, 0.0, df),
					_post(vanish, deep, xi, tall, df), _post(vanish, deep, xi, tall, dn),
					Color(1, 1, 1, lit * 0.30))

				# 칸을 나누는 선반. 옆면 위에 놓이므로 이것도 소실점으로 모인다.
				for row in range(1, Encounter.SHELF_ROWS):
					var h: float = tall * float(row) / float(Encounter.SHELF_ROWS)
					draw_line(_post(vanish, deep, xi, h, dn), _post(vanish, deep, xi, h, df),
						Color(1, 1, 1, lit * 0.7), 1.0)

				# **씨앗은 슬롯 번호로 뽑으면 안 된다.** `_flow`가 정수를 넘을 때마다 슬롯이
				# 한 칸씩 밀려서(눈에는 이어져 보인다) 책이 통째로 바뀐다. `i + floor(_flow)`는
				# 같은 책장이 다가오는 동안 안 변한다 - 그 책장의 진짜 번호다.
				var shelf_no: int = i + int(floor(owner_scene._flow))
				_books(vanish, deep, xi, tall, dn, df, lit, shelf_no * 97 + int(side) * 7)

		# 천장. 바닥과 같은 자를 높이만 바꿔 쓴다.
		var ceil_edge: float = wide * 0.5
		for side in [-1.0, 1.0]:
			draw_line(_post(vanish, deep, ceil_edge * side, Encounter.CEILING, 1.0), vanish,
				Color(1, 1, 1, 0.13), 1.0)
		for i in Encounter.RUNGS:
			var far: float = float(i) + 1.0 - fposmod(owner_scene._flow, 1.0)
			if far <= 0.0:
				continue
			var y: float = vanish.y + (deep - Encounter.CEILING) / far
			if y < 0.0:
				continue
			draw_line(Vector2(0.0, y), Vector2(screen.x, y),
				Color(1, 1, 1, minf(1.0 / far, 1.0) * 0.30), 1.0)

		# 천장에 매달린 등. 줄 하나에 작은 상자 하나면 매달린 것으로 읽힌다.
		for i in Encounter.LAMPS:
			var d: float = float(i) + 1.0 - fposmod(owner_scene._flow, 1.0)
			if d <= 0.35:
				continue
			# **복도 한가운데에 매단다.** 옆으로 치우쳐 두면 다가올수록 옆 거리가 `1/깊이`로
			# 커져서 옆으로 미끄러진다 - 원근으로는 맞지만 매달린 것이 흔들리는 것처럼 보인다.
			var lit: float = minf(1.0 / d, 1.0) * 0.45
			var top := _post(vanish, deep, 0.0, Encounter.CEILING, d)
			var hook := _post(vanish, deep, 0.0, Encounter.CEILING - 150.0, d)
			draw_line(top, hook, Color(1, 1, 1, lit * 0.6), 1.0)
			var half: float = 26.0 / d
			draw_rect(Rect2(hook.x - half, hook.y, half * 2.0, half * 1.6),
				Color(1, 1, 1, lit), false, 1.0)

		# 허공에 떠 있는 사각형들. 자리를 번호에서 뽑아 쓴다 - 무작위로 뽑으면 매 프레임 떤다.
		for i in Encounter.PAPERS:
			var spot: float = fposmod(sin(float(i) * 12.9898) * 43758.5453, 1.0)
			var lift: float = fposmod(sin(float(i) * 78.233) * 43758.5453, 1.0)
			var d: float = fposmod(float(i) * 0.61 - owner_scene._flow * 0.7, 1.0) * 5.0 + 0.4
			if d <= 0.4:
				continue
			# 책장 사이의 빈 공간에만 띄운다. 책장 자리에 겹치면 지저분해진다.
			var x: float = (spot - 0.5) * wide * 0.62
			var height: float = lerpf(120.0, Encounter.CEILING - 120.0, lift)
			# 크기와 흔들림을 번호에서 뽑아 제각각으로 만든다. 같은 크기가 줄지어 있으면
			# 무늬로 읽히고, 떠 있다기보다 박혀 있는 것으로 보인다.
			var bulk: float = fposmod(sin(float(i) * 4.71) * 43758.5453, 1.0)
			var size: float = lerpf(12.0, 46.0, bulk)
			# 저마다 다른 박자로 오르내린다. 같은 박자면 통째로 흔들려서 벽처럼 보인다.
			#
			# **시간에 물린다. `_flow`에 물리면 걸을 때만 흔들린다** - 걸음은 거리이지
			# 시간이 아니라서, 서 있으면 통째로 멎어버렸다.
			var now: float = float(Time.get_ticks_msec()) * 0.001
			height += sin(now * lerpf(0.9, 2.3, bulk) + float(i) * 1.7) * 26.0
			# **스쳐 지나갈 때 흐려지며 사라진다.** 딱 잘라내면 눈앞에서 툭 꺼진다 -
			# 깊이가 되감기는 자리라서 어차피 한 번은 없어져야 하고, 그 순간을 감추는 것이다.
			var lit: float = minf(1.0 / d, 1.0) * 0.5 * smoothstep(0.5, 1.3, d)
			if lit <= 0.01:
				continue
			_cube(vanish, deep, x, height, d, size, Color(1, 1, 1, lit))
