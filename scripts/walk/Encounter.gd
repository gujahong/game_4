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
## 소실점. 화면 가운데보다 조금 위에 둔다 - 바닥이 더 보여야 걸어 들어가는 것으로 읽힌다.
const VANISH := Vector2(480, 236)

## 소실점으로 모이는 선의 수와, 깊이를 나타내는 사각 테의 수.
##
## 16개는 빽빽했다. **선은 적을수록 검은 자리가 남고, 그 검은 자리가 이 화면의 알맹이다.**
## 8개면 대각선까지 딱 여덟 갈래로 갈라져 방향이 읽힌다.
const RAYS := 8
const RUNGS := 4

## 걷는 속도(깊이 0~1 기준). **아무 일도 안 일어나는 시간이 외로움을 만든다.**
##
## 0.085(12초)로 잡았더니 빨랐다. 0.045면 22초쯤 걸린다 - 그것에 닿기까지 한참이다.
const WALK_SPEED := 0.045

## 그것의 크기(화면 높이에 대한 비율).
##
## **처음부터 크다**(회원님). 점에서 자라나면 "나타나는" 것이 되는데, 그것은 나타나지 않는다 -
## 처음부터 거기 그만큼 크게 있었고 내가 다가갈 뿐이다. 조우 연출을 만들 때 세운 규칙
## (*"그것은 안 움직이고, 내가 작아진다"*)과 같은 말이다.
const TARGET_FAR := 0.45
const TARGET_NEAR := 0.95

var _lines: Node2D
var _target: Sprite2D
var _figure: HeroSprite
var _lamp: LampGlow

var _depth := 0.0   ## 0이면 맨 끝, 1이면 닿음
var _flow := 0.0    ## 사각 테가 흘러나온 양. 걸을 때만 늘어난다


func _ready() -> void:
	_build()
	_place()


func _process(delta: float) -> void:
	if _depth >= 1.0:
		return
	var walking := Input.is_action_pressed("ui_up")
	if walking:
		_depth = minf(_depth + WALK_SPEED * delta, 1.0)
		_flow += WALK_SPEED * delta * float(RUNGS)
	_place(walking)
	if _depth >= 1.0:
		get_tree().change_scene_to_file(BATTLE_SCENE)


func _place(walking: bool = false) -> void:
	var grow: float = lerpf(TARGET_FAR, TARGET_NEAR, pow(_depth, 2.4))
	if _target.texture != null:
		var scale_now: float = SCREEN.y * grow / float(_target.texture.get_size().y)
		_target.scale = Vector2(scale_now, scale_now)
	_target.position = VANISH
	_figure.show_state("north", walking)
	_lamp.position = _figure.position + _figure.lantern_at() * float(FIGURE_ZOOM)
	_lines.queue_redraw()


func _build() -> void:
	_lines = _Lines.new()
	add_child(_lines)

	# 그것은 선보다 위에 그린다. 선이 위를 지나가면 그것이 뒤에 있는 것처럼 보인다.
	_target = Sprite2D.new()
	_target.texture = load(TARGET)
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

	# 등불은 필터 밖이자 맨 위다. 이 화면에서 색을 가진 것은 이것뿐이다.
	var lamp_layer := CanvasLayer.new()
	lamp_layer.layer = 60
	add_child(lamp_layer)
	_lamp = LampGlow.new()
	_lamp.glow_size = 160
	lamp_layer.add_child(_lamp)


## 선을 그리는 판. 그리는 일만 하고 규칙은 위에서 받는다.
class _Lines extends Node2D:
	func _draw() -> void:
		var owner_scene := get_parent() as Encounter
		if owner_scene == null:
			return
		var vanish: Vector2 = Encounter.VANISH
		var screen: Vector2 = Encounter.SCREEN

		# 소실점에서 사방으로 뻗는 선. 화면 밖까지 길게 그어 잘리게 둔다.
		for i in Encounter.RAYS:
			var angle: float = TAU * float(i) / float(Encounter.RAYS)
			var far: Vector2 = vanish + Vector2(cos(angle), sin(angle)) * screen.length()
			draw_line(vanish, far, Color(1, 1, 1, 0.16), 1.0)

		# 깊이를 나타내는 사각 테. 소실점 쪽에서 나와 바깥으로 흘러나간다.
		for i in Encounter.RUNGS:
			var at: float = fposmod(float(i) / float(Encounter.RUNGS) + owner_scene._flow, 1.0)
			# 앞으로 갈수록 간격이 벌어져야 다가가는 것으로 읽힌다.
			var spread: float = pow(at, 2.2)
			var half: Vector2 = screen * spread
			var rect := Rect2(vanish - half, half * 2.0)
			# 소실점 근처에서는 흐리게. 안 그러면 한 점에 뭉쳐 지저분해진다.
			draw_rect(rect, Color(1, 1, 1, minf(at * 1.6, 0.5)), false, 1.0)
