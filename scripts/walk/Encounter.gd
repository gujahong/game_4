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
## 화면 대부분이 어둡고 등불만 또렷한 이 게임의 인상과 같은 데서 나온 형식이다.
##
## 그리고 회원님이 주신 참고 그림이 예외 없이 1점 투시였다. 그걸 그림에 맡기지 않고 직접
## 그리는 것이니 원래 의도에 오히려 가깝다.

## 전투는 **씬을 갈아타지 않고** 이 화면 위에 얹는다(`BattleStage`). 복도도 등불도 그것도
## 사라지지 않아야 카메라만 돌린 것으로 읽힌다.
const ENEMY_DEF := "res://resources/watcher.tres"
## 배경째 뽑힌 그림의 테두리를 흩는 셰이더.
const EDGE_BLEED := "res://shaders/EdgeBleed.gdshader"

## **다른 화면에서 이 복도로 적을 들여보낼 때 쓴다.** 씬을 갈아타면 값이 안 넘어가므로
## 정적 변수로 건네준다 - 서고에서 종이 더미가 일어서면 여기에 적어 놓고 씬을 바꾼다.
## 비어 있으면 이 화면의 기본값(그 것)이다.
static var pending_enemy := ""
## 참이면 걷기·붙잡힘·암전을 건너뛰고 곧장 전투로 간다.
static var straight := false

## 곧장 전투로 올 때 적이 시작하는 크기.
const COMING_FROM := 0.1
## **조리개가 넘어오는 크기.** 저쪽(`Walker`)이 여기까지 닫고 넘기면 여기서 그 크기부터
## 열어 나간다 - 두 화면이 같은 구멍으로 이어져서 눈을 안 뗀 채로 배경만 바뀐다.
const IRIS_SMALL := 0.16
const IRIS_OPEN_FOR := 1.0
const TARGET := "res://assets/enemies/watcher.png"
## 탑다운 맵에서 쓰는 그 주인공을 그대로 쓴다. **북쪽(뒷모습) 걷기**가 이 화면에 맞는다 -
## 등을 보이고 안으로 걸어 들어가는 그림이라서다. 떠 있는 등불도 `HeroSprite`가 같이 그린다.
const FRAMES := "res://assets/characters/pilgrim_rot/pilgrim_frames.tres"
## 16x32짜리라 그대로 두면 너무 작다. 정수배로만 키운다.
const FIGURE_ZOOM := 3
## 등불을 어깨 너머로 밀어 놓는 양. 머리 위에 그대로 두면 빛이 머리를 뚫고 나와 보인다.
const LAMP_ASIDE := Vector2(52.0, 22.0)

const SCREEN := Vector2(960, 540)
## 소실점 = 지평선. 위쪽 3분의 1쯤에 둔다 - **바닥이 넓게 보여야 서 있는 자리가 잡힌다.**
const VANISH := Vector2(480, 190)
## 지금의 소실점. **전투로 넘어가면 그것을 따라 옮겨 간다** - 원근이 그것에게 모여야 구도가
## 하나로 읽힌다. 걷는 동안에는 `VANISH` 그대로다.
var vanish := VANISH

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
const WALK_SPEED := 0.038

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
const BREATH := 26.0
const BREATH_SPEED := 0.42
const SPIN_SPEED := 0.09
## 붙잡히는 순간 **도는 것이 멎고**(이만큼), **정면으로 홱 돌아선다**(이만큼 걸려서).
## 둘을 더해도 `HALT_FOR`보다 한참 짧아야 한다 - 돌아선 채로 가만히 있는 사이가 남아야
## 소름이 돋는다.
## 발견하고 멎어 있는 사이. 짧다 - 그 뒤에 돈다.
const SPIN_FREEZE := 1.0
## 다 돌고 나서 **한참 쳐다보다가** 운다. 돌자마자 울면 도는 동작에 딸린 소리로 들린다.
const CRY_WAIT := 1.3
const SPIN_SNAP := 2.6
## 돌아설 때 **몇 번에 끊어 도는가.** 매끄럽게 돌면 문짝이 열리는 것이고, 칸칸이 끊어야
## "드드드드"가 된다 - 산 것이 아니라 뭔가에 붙들려 돌아가는 것으로 보인다.
## **잘게 썰어야 한다.** 9칸으로는 한 칸이 커서 쿵쿵거리는 것이 됐고, 20칸도 한 번에 도는
## 각이 커서 가벼웠다. 칸이 많고 느릴수록 무겁게 끌려 돌아가는 것으로 보인다.
const SPIN_STEPS := 44
## 돌아서는 동안의 잔떨림(픽셀). **1~2px짜리 좀스러운 떨림**이라야 "드드드"로 들린다.
## 4px는 화면이 통째로 들려서 "쿠구구구궁"이 됐다 - 그건 다가올 때 쓸 것이다.
const SPIN_QUAKE := 1.4

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
var _burst: _Burst
var _stage: BattleStage  ## 전투가 시작되면 여기 얹힌다. null이면 아직 걷는 중이다
var _tune_note: Label   ## 값을 눈으로 잡을 때만 뜬다(`-- --tune`)
var _tune_dragging := false

## 어둠이 먹어드는 구간(깊이). **시간이 아니라 거리에 물린다** - 멈추면 어두워지는 것도
## 멎어야 한다(회원님). 컷신이 아니라 내가 다가가서 벌어지는 일이다.
## **일찍 가려야 한다.** 0.45부터 가리면 그것이 다 커진 모습을 이미 본 뒤라, 나중에 불이
## 들어와도 "이미 본 것"이 다시 밝아질 뿐이다. 절반쯤 왔을 때 이미 안 보여야 마지막 순간이
## 놀랍다.
const DARK_FROM := 0.22
## 0.62에서 다 가렸더니 붙잡히자마자 캄캄해져서, 그것이 다가오는 것을 볼 새가 없었다.
## 0.88까지 늦춰서 **훨씬 가까이 온 뒤에** 암전된다.
const DARK_TO := 0.88

## 이만큼 걸으면 **그것이 직접 다가오기 시작한다.** 그 뒤로는 멈춰도 거리가 줄어든다 -
## 걸음이 갑자기 빨라지는 것이 "저것이 오고 있다"로 읽혀서, 아예 그렇게 만든 것이다.
const SEIZE_AT := 8.0
## 붙잡힌 뒤의 배속. **길게 쫓아와야** 도망칠 수 없다는 것이 드러난다.
const SEIZE_PACE := 1.15
## 코앞까지 왔을 때의 배속. `SEIZE_PACE`에서 여기까지 매끄럽게 올라간다.
const SEIZE_RUSH := 2.4
## 붙잡히는 순간 **걸음이 멎고 잠깐 아무 일도 안 일어난다.** 그 정적이 있어야 다음에
## 다가오는 것이 사건이 된다 - 곧바로 쫓아오면 그냥 빨라진 것으로 보인다.
const HALT_FOR := 8.4
## 다가올수록 화면이 떨린다. 가장 가까울 때의 흔들림(픽셀).
const SHAKE_MAX := 9.0
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
const FLASH_RISE := 0.55   ## 번쩍이 다 차오르는 데 걸리는 시간. 그 뒤로는 머문다
const FLASH_SIZE := 5.5    ## 번쩍일 때 등불이 부푸는 크기
const FLASH_GLARE := 0.62  ## 그때 주황 판이 덮는 정도. 눈을 때리는 부분이다
## **휙!** 번쩍이 차오른 그 자리에서 조리개가 단숨에 열린다. 이게 "휙"이고,
## 그 뒤로 이어지는 것이 "번쩌어어억"이다.
const OPEN_AT := 5.55   ## 두 번째 깜빡임이 사그라진 직후. 어둠에서 곧장 빛살이 터진다
const SETTLE := 0.55    ## 빛살이 걷히고 화면이 원래대로 돌아오는 시간
const LINGER := 0.9     ## 돌아온 화면을 그대로 두는 시간. 그 뒤에 전투로 넘어간다
## **번쩌어어어억.** 주황빛이 차오르고, 다 덮인 채로 한참 버틴다. 여기가 길어야 소리를
## 길게 늘여 부른 그 느낌이 난다 - 짧으면 그냥 전환 효과다.
## 빛살이 두두두 터져 나오는 시간. **`_Burst`가 스스로 정한다** - 손으로 맞춰 두면 `GAPS`를
## 고칠 때마다 어긋나고, 어긋나면 조각이 덜 나온 채 화면이 켜진다.
var _burst_for := _Burst.duration()
## 다 채운 흰 화면을 그대로 두는 시간. **여기가 있어야 "다 찼다"가 보인다.**
const BURST_HOLD := 0.45
const FLOOD_FOR := 1.6
## 다 덮인 채로 두는 시간. **짧아야 한다** - 빛이 화면을 채우면 그 안에서 이미 바뀌어 있어야
## 한다. 길게 끌면 "빛이 찼다가 → 가라앉고 → 바뀐다"가 되어 전환이 눈에 보인다.
const HOLD := 0.18

## 발소리 사이(초). 걷는 박자와 어긋나 보이면 여기를 고친다.
const STEP_EVERY := 0.46

var _walked := 0.0    ## 실제로 걸은 시간(초). 멈춰 있으면 안 는다
var _held := 0.0      ## 붙잡힌 뒤 흐른 시간. 앞의 `HALT_FOR`는 정적이다
var _spin_from := 0.0 ## 도는 것이 멎은 자리(라디안). 여기서 정면으로 돌아선다
var _spun := false    ## 멎은 자리를 이미 잡아 뒀는가
var _spin_clicks := -1  ## 돌아서면서 딸깍인 횟수. 칸이 넘어갈 때만 소리를 낸다
var _step_beat := 0.0   ## 마지막 발소리로부터 흐른 시간
var _left_foot := false ## 어느 발 차례인가. 좌우로 크기가 조금 다르다
var _blinked := 0       ## 부싯돌이 튄 횟수
var _shards := 0        ## 터져 나온 빛살 수
var _cried := false     ## 돌아선 뒤의 울음이 이미 울었는가
var _hum: AudioStreamPlayer   ## 그것이 오는 동안 깔리는 공포
var _seized := false  ## 붙잡혔는가. 그 뒤로는 내가 멈춰도 그것이 다가온다
var _depth := 0.0   ## 0이면 맨 끝, 1이면 닿음
var _flow := 0.0    ## 사각 테가 흘러나온 양. 걸을 때만 늘어난다
var _arrived := -1.0  ## 닿은 뒤 흐른 시간. 음수면 아직 걷는 중이다


func _ready() -> void:
	_build()
	_place()
	# 서고에 흐르는 바람. **처음부터 끝까지 안 멎는다** - 전투에 들어가도 여기는 같은 자리다.
	# **-31dB은 사실상 안 들렸다**(2026-08-14). 바람은 배경음이라 앞에 나서면 안 되지만,
	# 안 들리면 없는 것과 같다 - 있는지 없는지 모를 만큼은 들려야 서고가 빈 공간이 된다.
	Sfx.loop(self, Sfx.WIND, -20.0)

	# **전투 구도만 볼 때 쓰는 지름길.** `-- --battle`로 켜면 8초를 걷고 붙잡히는 7초를
	# 기다리고 암전·빛살까지 25초를 보지 않고 곧장 전투로 간다. `Battle.tscn`은 옛날 배경에
	# CRT가 걸린 시험대라 이 화면과 딴판이므로, 구도를 볼 때는 여기로 봐야 한다.
	# **다른 데서 마주친 것도 여기로 온다**(2026-08-18). 서고에서 종이 더미가 일어서면
	# 걷는 것 없이 이 복도로 넘어와서 전투만 한다 - 배경이 투시선인 것은 전투 화면의 얼굴이라
	# 적마다 다른 데서 싸우면 그 얼굴이 흐려진다. 다만 8초를 걷고 붙잡히는 연출은 그 것에게만
	# 쓴다(`straight`).
	# `-- --shot`을 같이 주면 다 앉은 뒤 한 장 찍고 끝낸다. **자리가 맞는지는 눈으로 재야
	# 안다** - 말로 주고받으면 서로 다른 것을 상상하게 된다.
	if "--tune" in OS.get_cmdline_user_args():
		_tuner.call_deferred()
	if "--shot" in OS.get_cmdline_user_args():
		_shoot_and_quit()

	# `-- --paper`로 켜면 종이로 된 것과 바로 붙는다. 서고를 걸어가 밟지 않고도 그 전투를
	# 볼 수 있어야 그림이 뒤집혔는지 같은 것을 바로 확인한다.
	if "--paper" in OS.get_cmdline_user_args():
		pending_enemy = "res://resources/paper.tres"
		straight = true

	if straight or "--battle" in OS.get_cmdline_user_args():
		straight = false
		_depth = 1.0
		_place()
		# **작게 시작한다.** 무대가 카메라를 돌리면서 제 크기까지 키운다 - 일러스트가 자라는
		# 것과 화면이 도는 것이 한 사건이 된다.
		_target.scale = Vector2.ONE * COMING_FROM
		# **각도를 0으로 못박는다.** `_place()`가 시간에 따라 그림을 천천히 돌리는데, 그건
		# 떠 있는 고리(그 것)의 것이다 - 바닥에 선 것이 기울어 있으면 수평이 안 맞는다.
		_target.rotation = 0.0
		_begin_battle()
		# 저쪽이 닫아 놓은 그 구멍에서 이어받아 연다. 카메라가 도는 동안 세상이 드러난다.
		_shade.material.set_shader_parameter("light_position", Vector2(0.5, 0.5))
		var open := create_tween()
		open.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		open.tween_method(
			func(r: float) -> void:
				_shade.material.set_shader_parameter("radius", r),
			IRIS_SMALL, OPEN_WIDE, IRIS_OPEN_FOR)


func _process(delta: float) -> void:
	# 전투가 시작되면 이 화면은 손을 뗀다. 복도도 그것도 그대로 서 있고, 움직이는 것은
	# `BattleStage`가 맡는다.
	if _stage != null:
		# 선은 계속 다시 그린다. 떠 있는 정육면체와 매달린 등이 제 박자로 흔들려야 전투
		# 내내 공간이 살아 있다 - 안 그리면 배경이 사진처럼 굳는다.
		_lines.queue_redraw()
		return

	if _arrived >= 0.0:
		_arrived += delta
		_close_in()
		# 빛살이 걷히고 세상이 돌아온 뒤 잠깐 두었다가 전투로 넘어간다.
		if _arrived >= OPEN_AT + _burst_for + BURST_HOLD + SETTLE + LINGER:
			_begin_battle()
		return

	# 떠 있는 것들은 걸음과 무관하게 흔들리므로 멈춰 있어도 다시 그려야 한다.
	_lines.queue_redraw()
	var walking := Input.is_action_pressed("ui_up")

	# **어느 순간부터는 그것이 온다.** 8초쯤 걸으면 붙잡힌 것이고, 그 뒤로는 내가 멈춰도
	# 거리가 줄어든다 - 도망칠 수 없다는 것이 걸음으로 드러난다.
	if not _seized:
		if walking:
			_walked += delta
			# 발이 땅에 닿을 때마다 한 번. **소리 높이를 조금씩 흔든다** - 똑같은 소리를
			# 되풀이하면 걸음이 아니라 시계가 된다.
			_step_beat += delta
			if _step_beat >= STEP_EVERY:
				_step_beat = 0.0
				# **한 발씩 번갈아 밟는다.** 같은 크기로 되풀이하면 사람이 아니라 기계다.
				# 한쪽이 조금 여려야 걸음에 좌우가 생긴다.
				_left_foot = not _left_foot
				Sfx.play(self, Sfx.STEP,
					-13.0 if _left_foot else -16.0,
					randf_range(0.95, 1.05) * (1.0 if _left_foot else 1.06))
		if _walked >= SEIZE_AT:
			_seized = true
			# **붙잡히는 소리는 뺐다**(회원님). 울음과 같은 순간에 울려서 울음을 덮었다.
			# 소리는 순서대로 하나씩 온다 - 발견하고(멎음), 돌고(그그그긍), 울고, 그리고
			# 다가오기 시작할 때 공포가 깔린다.
			pass

	# 붙잡히면 **걸음이 멎고 정적이 흐른다.** 그 사이에는 아무것도 안 움직인다.
	if _seized:
		_held += delta
	var halted: bool = _seized and _held < HALT_FOR

	# **소리가 순서대로 하나씩 온다.** 다 겹쳐 놓으면 무슨 일이 벌어지는지가 안 들린다.
	# 돌아서기를 마치는 순간 운다.
	if _seized and not _cried and _held >= SPIN_FREEZE + SPIN_SNAP + CRY_WAIT:
		_cried = true
		Sfx.play(self, Sfx.CRY, 0.0)
	# 정적이 끝나고 **오기 시작할 때** 공포가 깔린다. 크기는 남은 거리가 정한다.
	if _seized and not halted and _hum == null:
		_hum = Sfx.loop(self, Sfx.DRONE, -26.0)

	# **거리와 복도는 다른 것이다.** 거리는 나와 그것 사이가 좁혀지는 양이고, 복도가 흐르는
	# 것은 내가 지나가는 양이다. 걸을 때는 둘이 같이 가지만, 붙잡힌 뒤에는 **그것만 온다.**
	# 전에는 하나로 묶여 있어서, 서 있는데도 책장이 계속 지나갔다 - 내가 걸어가는 그림이라
	# 다가오는 것이 안 보였다.
	if (walking or _seized) and not halted:
		# **어두워졌다고 빨라지지 않는다.** 빨라지는 것은 그것이 오는 것 하나뿐이라야 산다.
		var pace: float = WALK_SPEED
		if _seized:
			# **가까울수록 빨리 온다.** 고른 속도로 오면 굴러오는 물건 같다. 끝에 가서
			# 달려들어야 쫓기는 것이 된다. 계단이 없는 한 줄짜리 곡선이라 중간에
			# "갑자기 빨라지는" 데가 없다.
			pace = WALK_SPEED * lerpf(SEIZE_PACE, SEIZE_RUSH, _depth)
		_depth = minf(_depth + pace * delta, 1.0)

	# 붙잡힌 뒤에는 ↓로 물러설 수 있다. **멀어지지는 않는다** - 발버둥이 아무 소용 없다는
	# 것이 그 자체로 이 장면의 말이다.
	var backing: bool = _seized and not halted and Input.is_action_pressed("ui_down")

	# 복도는 **내 발이 움직이는 만큼** 흐른다. 앞으로 밀면 지나가고 물러서면 되밀린다.
	# 발을 떼면 멎는다 - 그것이 오는 것은 거리(`_depth`)이지 복도가 아니다.
	if not halted:
		if walking:
			_flow += WALK_SPEED * delta * float(RUNGS)
		elif backing:
			_flow -= WALK_SPEED * delta * float(RUNGS)

	# 저역은 **가까울수록 커진다.** 화면 떨림과 같은 값을 쓴다 - 귀와 눈이 같은 것을 말해야
	# 하나의 사건으로 읽힌다. 조용한 데서 시작해 코앞에서 제 소리가 된다.
	if _hum != null:
		_hum.volume_db = lerpf(-24.0, -3.0, _depth)

	# 다가올수록 화면이 떨린다. **CanvasLayer 위의 것들은 안 흔들린다** - 어둠과 등불이
	# 같이 떨면 화면 전체가 흔들리는 것이라 멀미가 나고, 세상만 떨어야 그것이 다가와서
	# 울리는 것으로 읽힌다.
	var quake: float = 0.0
	if _seized and not halted:
		quake = SHAKE_MAX * _depth
	elif _turning():
		quake = SPIN_QUAKE
	position = Vector2(randf_range(-quake, quake), randf_range(-quake, quake)).round()

	# **정적일 때는 캐릭터도 멎는다.** 걸음이 멎었는데 다리만 움직이면 제자리걸음이 된다.
	_place(false if halted else (walking or backing), backing)


	if _depth >= 1.0:
		_arrived = 0.0
		# **팟 - 등불이 꺼진다.** 화면이 캄캄해지는 그 순간에 소리가 같이 끊겨야 꺼진 것이
		# 된다. 그 뒤로 우웅…… 우웅…… 하고 붙으려다 말고, 마지막에 팟팟팟 터진다.
		Sfx.play(self, Sfx.SHARD, -4.0, 0.82)
		if _hum != null:
			_hum.queue_free()
			_hum = null
		# 흔들림을 여기서 푼다. 안 그러면 마지막에 흔들린 만큼 화면이 비뚤어진 채로 굳어,
		# 빛살이 걷히고 세상이 돌아왔을 때 몇 픽셀 어긋나 있다.
		position = Vector2.ZERO
		# **빛살이 걷히면 그것을 마주 보고 서 있다.** 물러서던 중이었으면 이쪽을 보고 있는데,
		# 그 자세로 전투에 들어가면 등지고 싸우는 그림이 된다. 여기서 돌려세운다.
		_place(false, false)


## 씬을 갈아타는 대신 **이 화면 위에 전투를 얹는다.** 서 있던 그것과 나를 그대로 넘겨주면
## 무대가 둘을 좌우로 옮겨 앉힌다 - 아무것도 사라지지 않으니 카메라만 돈 것이 된다.
func _begin_battle() -> void:
	# 카메라가 도는 소리. 저역이 쓸려 가며 부풀었다 잦아든다.
	Sfx.play(self, Sfx.SWEEP, -8.0)
	if _hum != null:
		_hum.queue_free()   # 다가오는 것은 끝났다. 이제부터는 전투 곡이 깔린다
		_hum = null
	# **어둠은 안 걷는다.** 전투도 서고 한복판이고, 여기서 보이는 것은 등불이 밝히는 데까지다 -
	# 불을 끄면 아무것도 안 보여야 한다. 반경은 무대가 등불 밝기에 맞춰 잡는다.
	_hole(OPEN_WIDE, 0.0)
	# **투시선을 도로 켠다.** 다가가는 동안 걷어 놨는데(`_place`), 그대로 두면 전투가 빈 검은
	# 화면에서 벌어진다 - 여기가 서고라는 것도, 공간이 있다는 것도 이 선들이 말해 준다.
	_lines.modulate.a = 1.0
	# 등불을 몸에 도로 붙인다. 뒷걸음질 때만 제자리에 묶어 둔 것이라, 옆을 보고 서면 등불도
	# 그쪽 앞에 떠야 한다.
	_figure.lantern_facing = ""
	_stage = BattleStage.new()
	add_child(_stage)
	# 여럿을 받을 수 있는 자리다. 서고에서 마주치는 것은 지금 하나뿐이다.
	var def: EnemyDef = load(ENEMY_DEF if pending_enemy.is_empty() else pending_enemy)
	pending_enemy = ""
	# 그림이 반대쪽을 보고 있으면 여기서 뒤집는다. 다시 뽑느니 한 줄이 낫다.
	if "flip_h" in def:
		_target.flip_h = def.flip_h
		_target.flip_v = def.flip_v
	# **일렁임은 그 것에게만 걸린다.** 픽셀을 바깥으로 밀어내는 셰이더라, 다른 그림에 그대로
	# 걸리면 모양이 통째로 일그러진다 - 종이가 이상해 보이던 것이 좌우가 아니라 이것이었다.
	if "aura" in def and not def.aura:
		# **배경째 뽑힌 그림은 테두리를 녹인다.** 안 그러면 화면에 정사각형 판이 하나 떠 있는
		# 꼴이 된다 - 자리를 어디로 옮겨도 네모는 네모다. 도려내면 배경의 책장까지 없어지므로
		# 가장자리만 디더로 흩어 어둠에 묻는다(`EdgeBleed`).
		var bleed := ShaderMaterial.new()
		bleed.shader = load(EDGE_BLEED)
		_target.material = bleed
	if def.texture != null:
		_target.texture = def.texture
	_stage.begin([def], _target, _figure, _lamp, _lines, _shade)

	# **소실점이 그것을 따라간다.** 둘이 걸어서 자리를 옮기는 게 아니라 카메라가 돌아서
	# 구도가 바뀌는 것이므로, 복도의 원근도 같이 돌아야 한다 - 안 그러면 배경만 아까 그대로
	# 서 있고 둘만 미끄러진다. 무대와 같은 시간·같은 곡선이라 한 몸으로 움직인다.
	var turn := create_tween()
	turn.set_trans(BattleStage.MOVE_CURVE).set_ease(Tween.EASE_IN_OUT)
	turn.tween_property(self, "vanish", BattleStage.ENEMY_AT, BattleStage.MOVE_FOR)


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
	# **캄캄한 동안에도 등불은 떠 있다.** 도착하면 `_place`가 멎어서 빛이 그 자리에 굳는데,
	# 그러면 깜빡이는 것이 등불이 아니라 화면에 박힌 점이 된다. 여기서 흔들림만 이어 준다 -
	# 사람은 어둠에 묻혀 안 보이고 빛만 오르내린다.
	_figure.show_state("north", false)
	_lamp.position = _figure.lantern_global()

	# 부와앙…… 깜빡임이 시작되는 시각마다 한 번씩. 불이 붙으려다 마는 소리다.
	while _blinked < BLINKS.size() and _arrived >= BLINKS[_blinked][0]:
		Sfx.play(self, Sfx.BLINK, -8.0, randf_range(0.94, 1.06))
		_blinked += 1

	# 조리개가 열리기 전까지는 **완전한 암전**이다. 등불까지 꺼서 볼 것이 하나도 없다.
	if _arrived < OPEN_AT:
		_hole(0.0)
		_blink(_arrived)
		return

	# 번쩍한 그 자리에서 조리개가 열린다. **빛 그림이 커지는 게 아니라 그 반경 안이 진짜로
	# 보인다.** 앞이 느리고 끝이 급한 곡선이라야 "확" 열린다.
	# **화면을 하얗게 채우지 않는다**(회원님). 암전에서 빛살이 두두두 터져 나오고, 그 사이에
	# 세상이 다시 드러난다. 밝아졌다 어두워지는 왕복이 없어서 눈이 안 피로하다.
	var burst: float = clampf((_arrived - OPEN_AT) / _burst_for, 0.0, 1.0)
	_burst.centre = _lamp.position
	_burst.spread = burst
	# 조각이 하나 터질 때마다 소리도 하나. **화면이 세는 박자를 귀도 그대로 센다** - 두두두두가
	# 눈에만 있고 귀에 없으면 반쪽이다.
	var out: int = _Burst.popped(burst)
	while _shards < out:
		_shards += 1
		Sfx.play(self, Sfx.SHARD, -9.0, randf_range(0.8, 1.24))
	_burst.modulate.a = 1.0
	_burst.queue_redraw()

	# **빛살이 터지는 내내 암전이다.** 조리개를 같이 열면 세상이 비쳐서 빛살과 섞이고,
	# 갈라진 모양이 안 보인다. 검은 화면에 빛살만 두두두 나온다.
	# **다 채운 채로 잠깐 버틴다.** 마지막 조각이 자리에 앉는 순간 화면이 켜지면 덜 찬 것처럼
	# 보인다 - 흰 화면이 한 박자 서 있어야 "다 찼다"가 눈에 들어온다.
	if burst < 1.0 or _arrived < OPEN_AT + _burst_for + BURST_HOLD:
		_hole(0.0)
		_lamp.visible = false
		return

	# 빛살이 다 채운 뒤 **조각이 걷히면서 화면이 원래대로 돌아온다.** 어둡던 것을 여기서
	# 통째로 푼다. 그리고 잠시 그대로 두었다가 전투로 넘어간다.
	# **어둡던 것을 여기서 통째로 푼다.** 조각이 걷히는 동안 화면이 원래대로 돌아오고,
	# 그대로 잠시 두었다가 전투로 넘어간다.
	var back: float = clampf(
		(_arrived - OPEN_AT - _burst_for - BURST_HOLD) / SETTLE, 0.0, 1.0)
	_burst.modulate.a = 1.0 - back
	_hole(OPEN_WIDE, 0.0)
	_lamp.visible = true
	_lamp.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	_lamp.scale = Vector2.ONE

	# 흰 판은 안 쓴다. **깨진 빛살과 같이 쓰니 둘이 섞여 지저분했다** - 갈라진 모양이 판에
	# 묻혀서 안 보인다. 화면을 채우는 것은 빛살 자체다.
	_flash.color.a = 0.0


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
	# **올라가서 머문다.** 사인 한 마루로 하면 들어왔다 바로 빠져서 "번쩍"이 되는데,
	# 올라간 채로 버텨야 "번쩌어어어억"이 된다. 그 상태에서 조리개가 열려 나간다.
	# **부풀어 오르는 번쩍은 뺐다**(회원님). 빛이 먼저 퍼지고 나서 빛살이 나오면 빛이 두 번
	# 나는 것이다. 빛살은 어둠에서 곧장 터져야 알이 깨지는 것으로 읽힌다 - 여기서는
	# 힘없이 두 번 깜빡이고 마는 것까지다.
	_lamp.visible = glow > 0.01
	_lamp.self_modulate = Color(1.0, 1.0, 1.0, glow)
	_lamp.scale = Vector2.ONE * lerpf(DARK_LAMP * 0.5, DARK_LAMP * 2.4, glow)
	_flash.color.a = 0.0


## 그것이 도는 각. 평소에는 그냥 천천히 돌지만, **붙잡히는 순간 멎었다가 정면으로 홱
## 돌아선다.** 계속 돌면 그냥 떠 있는 물건인데, 멎고 바로 서면 이쪽을 알아본 것이 된다.
func _spin(now: float) -> float:
	if not _seized:
		return now * SPIN_SPEED
	if not _spun:
		# 멎은 자리를 그대로 잡아 둔다. **가까운 쪽으로 돌려야** 한 바퀴 돌아가지 않는다.
		_spin_from = wrapf(_target.rotation, -PI, PI)
		_spun = true
	if _held < SPIN_FREEZE:
		return _spin_from
	var turn: float = clampf((_held - SPIN_FREEZE) / SPIN_SNAP, 0.0, 1.0)
	# **칸칸이 끊어 돈다.** 마지막 칸은 정확히 0이라 어긋난 채로 멎지 않는다.
	var step: float = snappedf(turn, 1.0 / float(SPIN_STEPS))
	# 칸이 넘어갈 때마다 마른 딸깍. 44칸이 이어지면 이것이 곧 그르르르다.
	var clicked: int = int(round(step * float(SPIN_STEPS)))
	if clicked != _spin_clicks:
		_spin_clicks = clicked
		# 44칸이 이어지므로 **한 칸은 여려야 한다** - 하나하나가 또렷하면 시끄럽다.
		Sfx.play(self, Sfx.TICK, -26.0, randf_range(0.94, 1.07))
	return lerpf(_spin_from, 0.0, step)


## 지금 홱 돌아서는 중인가. 그동안만 화면이 자잘하게 운다.
func _turning() -> bool:
	return _seized and _held >= SPIN_FREEZE and _held < SPIN_FREEZE + SPIN_SNAP


func _place(walking: bool = false, backing: bool = false) -> void:
	# **캄캄해지면 몰래 끝 크기로 당겨 놓는다.** 아무도 못 보는 사이라 공짜이고, 불이
	# 들어오는 순간 이미 이만큼 커져 있어야 "왜 이렇게 커"가 나온다.
	# **어두워지는 정도로 크기를 당기지 않는다.** 어둠 곡선이 훨씬 가팔라서 깊이 0.27쯤에서
	# 그쪽이 앞지르고, 그 순간부터 그것만 갑자기 빨리 커진다 - 붙잡히기 직전에 뭔가 바뀐
	# 것처럼 보였던 것이 이것이다. 크기는 깊이 하나만 따른다.
	var grow: float = lerpf(TARGET_FAR, TARGET_NEAR, pow(_depth, 2.4))
	if _target.texture != null:
		var scale_now: float = SCREEN.y * grow / float(_target.texture.get_size().y)
		_target.scale = Vector2(scale_now, scale_now)
	# 그것은 아주 느리게 오르내리고 빙빙 돈다. **살아 있는지 아닌지 알 수 없을 만큼** 느려야
	# 한다 - 빠르면 기계가 되고, 멎어 있으면 그림이 된다.
	var now: float = float(Time.get_ticks_msec()) * 0.001
	_target.position = vanish + Vector2(0.0, sin(now * BREATH_SPEED) * BREATH)
	_target.rotation = _spin(now)
	# **다가갈수록 세상이 걷힌다.** 바닥·책장·천장이 흐려져서 끝에는 그것과 내 등불만 남는다.
	# 끝까지 복도가 그대로면 "도착했다"가 눈에 안 보인다.
	#
	# 선을 그리는 판 전체에 한 번에 거는 것이라 그리는 쪽은 이걸 몰라도 된다.
	_lines.modulate.a = 1.0 - smoothstep(0.35, 0.92, _depth)

	# 물러설 때는 이쪽을 보고 걷는다 — 그것을 마주 본 채 뒷걸음질하는 그림이다.
	# 등불을 오른쪽으로 비켜 놓는다. **뒷모습에서는 등불이 앞(=위)에 뜨는데, 그대로 두면
	# 빛이 머리를 뚫고 나오는 것처럼 보인다.** 어깨 너머로 밀어야 옆에 띄우고 가는 것으로
	# 읽힌다. **등불 그림과 빛을 같은 값으로 민다** - 따로 두면 빛만 옆에서 새는 꼴이 된다.
	# `lantern_at()`이 이미 `aside`를 더해서 돌려준다. 여기서 또 더하면 **빛만 두 번 밀려서**
	# 등불 그림과 어긋난다.
	#
	# **어둠(`_hole`)보다 먼저 놓는다.** 뒤에 두면 구멍이 한 프레임 늦은 자리를 쓴다.
	_figure.aside = LAMP_ASIDE / float(FIGURE_ZOOM)
	_figure.show_state("south" if backing else "north", walking)
	# 계산으로 다시 맞추지 않고 **그림이 실제로 있는 자리를 읽는다.** 배율·비켜놓기·판
	# 흔들림이 이미 다 들어 있어서, 하나라도 바뀌면 빛만 딴 데서 나던 일이 없어진다.
	# **화면이 흔들리는 몫(`position`)을 빛에도 더한다.** 등불 그림은 흔들리는 판 위에 있고
	# 빛은 `CanvasLayer` 위라 흔들림이 안 걸린다 - 그냥 두면 그것이 다가와 화면이 울 때
	# 등불만 떨고 빛은 제자리에 박혀 있어서 둘이 따로 논다.
	_lamp.position = _figure.lantern_global()

	# 다가갈수록 어둠이 먹어든다. **등불까지 눌린다** - 그래야 닿는 순간 그 자리에서
	# 불이 되살아나는 것으로 읽힌다. 걸음에 물려 있으므로 멈추면 이것도 멎는다.
	# **등불 쪽만 남기고 어둠이 조여든다.** 통짜 검은 판을 알파로 여닫으면 화면이 흐려질 뿐이라
	# 세상이 안 사라진다. 구멍의 반경을 줄여야 바깥부터 먹히고 등불 쪽만 남는다.
	var eaten: float = smoothstep(DARK_FROM, DARK_TO, _depth)
	# **등불은 끝까지 그대로 있다가 한 번에 꺼진다**(회원님). 닿기 직전에 스르르 줄이면
	# 기름이 떨어져 사그라드는 것으로 보이는데, 이건 그런 게 아니다 - 마주친 순간
	# **팟 하고 꺼진다**(`_process`의 도착 처리).
	_lamp.scale = Vector2.ONE
	# 구멍이 줄면서 **남은 자리도 같이 흐려진다.** 줄기만 하면 조리개처럼 보인다.
	_hole(lerpf(OPEN_WIDE, 0.0, eaten), eaten * 0.92)

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
	# 그림에 투명 여백을 둘렀으므로(`tools/_cutbg.gd`의 `PAD`) 주제가 끝나는 자리를 알려준다.
	# 안 주면 일렁이는 구간이 여백으로 밀려나 아무것도 안 흔들린다.
	var wave := ShaderMaterial.new()
	wave.shader = load(AURA_SHADER)
	var content: float = 0.5 * 512.0 / 656.0   # 원본 512가 656 안에 들어 있다
	wave.set_shader_parameter("edge_radius", content)
	wave.set_shader_parameter("calm_radius", content * 0.84)
	_target.material = wave
	_target.z_index = 1
	add_child(_target)

	# 나는 화면 아래 가운데에 등을 보이고 서 있다. **크기가 안 변한다** - 검은 공간에는
	# 견줄 것이 없어서 내가 작아지는 것과 그것이 커지는 것이 같은 말이 된다.
	_figure = HeroSprite.new()
	_figure.sprite_frames = load(FRAMES)
	_figure.scale = Vector2(FIGURE_ZOOM, FIGURE_ZOOM)
	_figure.position = Vector2(SCREEN.x * 0.5, SCREEN.y - 96.0)
	# 이 화면에서는 **등불이 몸을 안 따라간다.** 뒤돌아본다고 등불이 반대편으로 튀면
	# 띄워 둔 것이 아니라 들고 있는 것으로 보인다.
	_figure.lantern_facing = "north"
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
	# **치즈색을 피한다.** 주황을 그대로 쓰면 노랑기가 많아 소스처럼 보인다. 흰색 쪽으로
	# 끌어올려야 "눈이 머는 빛"이 되고, 등불빛이라는 것도 옅게 남는다.
	_flash.color = Color(1.0, 0.94, 0.84, 0.0)
	flash_layer.add_child(_flash)

	# 등불에서 갈라져 나오는 흰 빛살. **알이 깨지듯** 삼각뿔이 사방으로 뻗어 화면을 덮는다.
	_burst = _Burst.new()
	flash_layer.add_child(_burst)

	# 등불은 필터 밖이자 맨 위다. 이 화면에서 색을 가진 것은 이것뿐이다.
	var lamp_layer := CanvasLayer.new()
	lamp_layer.layer = 60
	add_child(lamp_layer)
	_lamp = LampGlow.new()
	# 이 화면에는 등불 말고 색이 없어서, 맵보다 크고 촘촘해도 된다.
	_lamp.glow_size = 224
	# **이 화면의 등불은 흰빛이다.** 주황이면 빛살(흰색)과 나란히 놓였을 때 둘이 다른 빛으로
	# 보인다. 같은 빛에서 나온 것이라야 갈라져 터지는 것이 말이 된다.
	_lamp.core_color = Color(1.0, 0.93, 0.78, 0.95)
	_lamp.edge_color = Color(1.0, 0.80, 0.52, 0.0)
	lamp_layer.add_child(_lamp)


## 등불에서 갈라져 나오는 흰 빛살. **알이 깨지듯** 삼각뿔이 사방으로 뻗는다.
##
## 둥근 빛이 커지기만 하면 그냥 밝아지는 것이다. 갈라진 살이 뻗어야 **터져 나오는** 것으로
## 읽힌다 — 껍질이 깨지고 그 틈으로 빛이 새어 나오는 모양이다.
class _Burst extends Node2D:
	## **몇 개 안 되고 폭이 제각각이라야 깨진 조각으로 보인다.** 얇은 살을 고르게 여럿 두면
	## 폭죽이나 햇살 무늬가 된다. 껍질이 갈라진 자리는 크기도 각도도 제멋대로다.
	const RAYS := 14
	const REACH := 1800.0   ## 다 뻗었을 때의 길이. 화면 대각선보다 길어야 구석까지 덮는다
	## 다 벌어졌을 때의 반각(라디안). 조각마다 이 사이에서 뽑는다.
	##
	## **끝에는 살끼리 붙어 화면을 다 채운다.** 조각 아홉이면 간격이 0.70이라 반각이 0.35를
	## 넘으면 겹치기 시작한다. 넉넉히 넘겨서 마지막엔 틈이 안 남게 한다 - 다 채운 그 순간이
	## 전환하는 자리다.
	## **가장 좁은 조각도 간격의 절반을 넘어야** 틈이 안 남는데, 0.17은 그 절반이었다 -
	## 다 터져도 검은 쐐기가 남아 있었다("몇 개 덜 찼어").
	##
	## 조각 열넷이면 간격이 0.449이고, 각도까지 흔들리므로(`ANGLE_JITTER`) 최대 0.606까지
	## 벌어진다. 그 절반인 0.303을 넘겨 잡는다. **조각을 늘려 잘게 쪼갠 것**이라 아홉 개일
	## 때(0.52~0.74)보다 훨씬 가늘다. 자라는 동안에는 `alive`가 곱해져 더 뾰족하다.
	const WIDE_LOW := 0.33
	const WIDE_HIGH := 0.47
	## 각도를 슬롯의 이만큼까지 흔든다. **0.7은 너무 컸다** - 조각이 이웃에 바싹 붙으면서
	## 반대쪽에 폭보다 넓은 틈이 생겼다.
	const ANGLE_JITTER := 0.35
	const POP := 0.05       ## 조각 하나가 튀어나오는 데 걸리는 몫. 짧아야 "툭"이다

	## 앞 조각과의 사이(초). **점점 좁아진다** — 툭 … 툭 … 툭 . 두두두두두.
	## 여기만 고치면 터지는 시간(`_burst_for`)이 저절로 따라온다.
	## **`RAYS`와 개수가 같아야 한다.** 조각을 늘리면서 뒤쪽을 더 촘촘하게 이어 붙였다 -
	## 뒤가 늘어지면 두두두두가 아니라 뚝뚝뚝이 된다.
	const GAPS := [1.0, 0.7, 0.5, 0.3, 0.2, 0.2, 0.2, 0.15, 0.15, 0.12, 0.12, 0.1, 0.1, 0.1]

	## 터지는 순서. **번호대로 두면 시계방향으로 돌아가며 나온다** — 갈라지는 게 아니라
	## 회전하는 것으로 보인다. 원을 건너뛰며 도는 순서로 섞는다(14와 5가 서로소라 한 바퀴에
	## 모든 조각을 정확히 한 번씩 짚는다 - **서로소가 아니면 몇 개는 아예 안 나온다**).
	const ORDER_STEP := 5

	var centre := Vector2.ZERO
	var spread := 0.0   ## 0이면 아직 안 터졌고 1이면 다 덮었다

	## 마지막 조각이 **터지기 시작하는** 시각(초).
	static func _span() -> float:
		var total := 0.0
		for gap in GAPS:
			total += gap
		return maxf(total, 0.001)

	## 지금까지 몇 조각이 터져 나왔는가. 소리를 조각마다 하나씩 내려고 밖에서 읽어 간다.
	static func popped(spread: float) -> int:
		var when := 0.0
		var out := 0
		for gap in GAPS:
			when += gap
			if when / duration() <= spread:
				out += 1
		return out

	## 다 터지고 다 벌어지는 데 걸리는 시간(초). **마지막 조각도 벌어질 몫(`POP`)이 뒤에
	## 남아 있어야 한다** - 시작 시각을 곧 끝나는 시각으로 삼았더니 마지막 조각은 나오지도
	## 못하고 그 앞 것도 덜 벌어진 채로 화면이 켜졌다.
	static func duration() -> float:
		return _span() / (1.0 - POP)

	func _draw() -> void:
		if spread <= 0.001:
			return
		for i in RAYS:
			# 각도도 폭도 번호에서 뽑는다. 무작위로 뽑으면 매 프레임 다시 갈라진다.
			# 씨앗을 두 번 흔들어야 값이 골고루 흩어진다. 한 번만 돌리면 번호가 이웃한
			# 조각끼리 값도 이웃해서, 규칙적으로 커졌다 작아지는 무늬가 된다.
			var jitter: float = fposmod(sin(float(i) * 127.1 + 311.7) * 43758.5453, 1.0)
			jitter = fposmod(sin(jitter * 269.5 + 183.3) * 43758.5453, 1.0)

			# **한꺼번에 벌어지지 않고 하나씩 튀어나온다 — 툭, 툭, 툭, 두두두두.**
			# 터지는 시각을 앞은 뜸하게 뒤는 촘촘하게 놓으면 그 박자가 나온다.
			# 이 조각이 몇 번째로 터지는가. 번호대로면 시계방향으로 돌아가며 나온다.
			var turn: int = (i * ORDER_STEP) % RAYS
			var when := 0.0
			for k in turn + 1:
				when += GAPS[k]
			var at: float = when / duration()
			var alive: float = clampf((spread - at) / POP, 0.0, 1.0)
			if alive <= 0.0:
				continue

			var angle: float = TAU * (float(i) + jitter * ANGLE_JITTER) / float(RAYS) - PI * 0.5
			var half: float = lerpf(WIDE_LOW, WIDE_HIGH, jitter) * alive
			var reach: float = REACH * alive
			draw_colored_polygon([
				centre,
				centre + Vector2(cos(angle - half), sin(angle - half)) * reach,
				centre + Vector2(cos(angle + half), sin(angle + half)) * reach,
			] as PackedVector2Array, Color(1.0, 0.97, 0.9, 1.0))


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
		var vanish: Vector2 = owner_scene.vanish
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


## 확인용. 다 앉은 뒤 한 장 찍고 끝낸다(`-- --paper --shot`).
func _shoot_and_quit() -> void:
	await get_tree().create_timer(3.4).timeout
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tools/_battle_shot.png")

## ### 눈으로 보면서 값을 잡는 손잡이 (`-- --paper --tune`)
##
## 번지는 길이·크기·자리 셋이 서로 물려 있어서 **숫자를 말로 주고받으면 계속 어긋난다.**
## 화면을 보면서 직접 돌리고, 마음에 드는 값이 나오면 그대로 리소스에 적으면 된다.
##
##   막대 두 개   번지는 길이, 크기
##   마우스 끌기   자리
##
## **자리는 무대에게 알려줘야 한다.** 스프라이트를 직접 옮기면 다음 프레임에 무대가 제자리로
## 되돌린다 - 숨을 쉬느라 매 프레임 자리를 다시 잡기 때문이다.
func _tuner() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 120
	add_child(layer)

	var box := VBoxContainer.new()
	box.position = Vector2(12, 8)
	box.add_theme_constant_override("separation", 2)
	layer.add_child(box)

	_tune_note = Label.new()
	_tune_note.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55))
	box.add_child(_tune_note)

	var bleed := HSlider.new()
	bleed.min_value = 0.0
	bleed.max_value = 1.0
	bleed.step = 0.01
	bleed.custom_minimum_size = Vector2(280, 16)
	bleed.value = _tune_reach()
	bleed.value_changed.connect(func(v: float) -> void:
		if _target.material is ShaderMaterial:
			_target.material.set_shader_parameter("reach", v)
		_tune_show())
	box.add_child(bleed)

	var big := HSlider.new()
	big.min_value = 0.1
	big.max_value = 2.6
	big.step = 0.01
	big.custom_minimum_size = Vector2(280, 16)
	big.value = _target.scale.x
	big.value_changed.connect(func(v: float) -> void:
		_target.scale = Vector2(v, v)
		if _stage != null:
			_stage._enemy_zoom_to = Vector2(v, v)
		_tune_show())
	box.add_child(big)

	_tune_show()


func _tune_reach() -> float:
	if not _target.material is ShaderMaterial:
		return 0.0
	var got: Variant = _target.material.get_shader_parameter("reach")
	return float(got) if got != null else 0.0


func _tune_show() -> void:
	if _tune_note == null:
		return
	var seat: Vector2 = _stage._enemy_seat if _stage != null else _target.position
	_tune_note.text = "번짐 %.2f    크기 %.2f    자리 (%d, %d)   ← 그림을 끌어서 옮기세요" % [
		_tune_reach(), _target.scale.x, int(seat.x), int(seat.y)]


## 그림을 마우스로 끌어 옮긴다. **무대의 자리를 고쳐야** 다음 프레임에 안 돌아간다.
func _unhandled_input(event: InputEvent) -> void:
	if _tune_note == null:
		return
	if event is InputEventMouseButton:
		_tune_wheel(event as InputEventMouseButton)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_tune_dragging = event.pressed
	elif event is InputEventMouseMotion and _tune_dragging:
		var moved: Vector2 = (event as InputEventMouseMotion).relative
		if _stage != null:
			_stage._enemy_seat += moved
		else:
			_target.position += moved
		_tune_show()


## 막대가 안 먹을 때를 대비한 손잡이. **휠로 번짐, Shift+휠로 크기.**
func _tune_wheel(event: InputEventMouseButton) -> void:
	var up: bool = event.button_index == MOUSE_BUTTON_WHEEL_UP
	var down: bool = event.button_index == MOUSE_BUTTON_WHEEL_DOWN
	if not (up or down):
		return
	if Input.is_key_pressed(KEY_SHIFT):
		var grow: float = 1.04 if up else 0.962
		_target.scale *= grow
		if _stage != null:
			_stage._enemy_zoom_to = _target.scale
	elif _target.material is ShaderMaterial:
		_target.material.set_shader_parameter("reach",
			clampf(_tune_reach() + (0.03 if up else -0.03), 0.0, 1.0))
	_tune_show()
