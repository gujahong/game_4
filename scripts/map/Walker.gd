extends Node
class_name Walker

## 방 하나를 걸어다니는 화면. **엮기만 한다** — 규칙은 `Hero`, 그림은 `HeroSprite`가 맡는다.
##
## 카메라가 나를 따라오므로 **나는 항상 화면 한가운데**에 있다. 그래서 등불(CanvasLayer)과
## 화면 필터의 빛도 가운데에 고정해두면 되고, 세상 쪽만 움직인다.
##
## 등불은 필터 판보다 **위** 레이어에 있어서 회색으로 안 변한다(`Room.tscn` 참고).

const EDGE_PADDING := 10.0  ## 벽에 코를 박지 않게 바닥 안쪽으로 남기는 여유

## 조우가 벌어지는 자리(바닥 사각형에 대한 비율)와 닿았다고 볼 거리(픽셀).
##
## 자리를 표시해두지 않는다. **어쩌다 마주치는 편이 사건이 된다** - 조우 연출을 보스에만
## 쓰기로 한 것과 같은 이유다(2026-08-11).
## [2026-08-13] `Walk.tscn`(일러스트 한 장을 채우는 방식)에서 `Encounter.tscn`(검은 화면에
## 흰 선만)으로 바꿨다. 옛것은 그대로 남아 있으니 여기 한 줄만 되돌리면 된다.
const ENCOUNTER_SCENE := "res://scenes/Encounter.tscn"
## **나선의 한가운데다**(2026-08-14). 그것이 마을을 지키고 있고, 그 너머에 포탈·기름·기록물이
## 있다 - 처음 온 사람은 반드시 한 번 마주쳐야 여기가 자기 거점이 된다.
##
## 전에는 방 위쪽 가운데(0.5, 0.04)였다. 조우 화면에서 북쪽으로 걸어 들어가니 방에서도 위로
## 가야 맞는다고 봤는데, 나선이 되면서 **안쪽으로 감겨 들어가는 것**이 그 자리를 대신한다.
const ENCOUNTER_RANGE := 28.0
## 관문에서 넘어올 때 덮여 있던 암전을 걷는 시간. `Opening.ENTER_FADE`와 맞춘다.
const ENTER_FADE := 1.6

@onready var _room: TilesetRoom = $World/Room
@onready var _camera: Camera2D = $World/Camera
@onready var _hero_sprite: HeroSprite = $World/Hero
@onready var _lamp: LampGlow = $LampLayer/Lamp
@onready var _screen: ColorRect = $FilterLayer/Screen

var _hero: Hero
var _sleepers: Sleepers
var _encounter: Vector2
var _left := false   ## 이미 넘어갔는가. 한 프레임에 두 번 부르지 않으려는 것


func _ready() -> void:
	var floor_rect := _room.floor_rect_px().grow(-EDGE_PADDING)
	# **통로 위에서만 걷는다.** 방이 사각형이 아니라 나선이라, 판정을 방에게 물어본다 -
	# `Hero`는 방 모양을 몰라도 된다.
	_hero = Hero.new(floor_rect, _room.is_walkable_px, _room.entrance_px())
	# 그것은 나선 한가운데에서 마을을 지킨다.
	_encounter = _room.heart_px()
	_place()

	# **종이는 방보다 넓게 흩어져 있다.** 딱 바닥만큼만 두면 가장자리에서 종이가 사라지는
	# 자리가 보인다. 심연 위에도 떠 있어야 이 방이 끝이 있는 상자가 아니게 된다.
	$World/Pages.setup(floor_rect.grow(96.0))

	# 바닥에 누워 있는 것들. 다가가면 일어선다.
	_sleepers = $World/Sleepers
	_sleepers.setup(_room)
	_sleepers.woke.connect(_on_woke)

	# 나는 늘 화면 한가운데에 있으므로 화면 필터의 빛은 가운데 고정이면 된다.
	_screen.material.set_shader_parameter("light_position", Vector2(0.5, 0.5))

	# **관문을 넘어오면 화면이 까맣게 덮인 채로 도착한다**(2026-08-14). `ScreenEffect`는
	# 오토로드라 씬을 갈아타도 그 암전이 그대로 남는다 - 여기서 걷어내야 서고가 보인다.
	# 이 씬만 따로 열었을 때는 이미 투명해서 아무 일도 안 일어난다.
	ScreenEffect.fade_in(ENTER_FADE)

	if "--capture" in OS.get_cmdline_user_args():
		_capture_and_quit()


func _process(delta: float) -> void:
	if _left:
		return
	_hero.step(Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	), delta)
	_place()

	# 밟으면 부스럭거리다 일어선다.
	_sleepers.check(_hero.at, delta)

	# 조우 자리에 닿으면 연출로 넘어간다.
	if _hero.at.distance_to(_encounter) < ENCOUNTER_RANGE:
		_left = true
		get_tree().change_scene_to_file(ENCOUNTER_SCENE)


## 누워 있던 것이 일어섰다. **긴 연출은 그것한테만 쓴다** - 잡몹마다 15초짜리 암전·빛살을
## 보여주면 지친다. 여기서는 암전만 짧게 깔고 전투로 넘긴다(회원님이 정한 순서: 암전 →
## 빛 화악 → 카메라 무빙).
func _on_woke(_index: int) -> void:
	_left = true
	Sfx.play(self, Sfx.SEIZE, -6.0)
	await ScreenEffect.fade_out(0.45)
	get_tree().change_scene_to_file(ENCOUNTER_SCENE)


## **정수 픽셀로 끊어** 놓는다. 카메라가 소수점 자리에 있으면 2배로 확대된 화면에서 바닥
## 도트가 반 칸씩 어긋나 무늬가 지글거린다.
func _place() -> void:
	var here := _hero.at.round()
	_camera.position = here
	_hero_sprite.position = here
	_hero_sprite.show_state(_hero.facing, _hero.walking)

	# 빛을 등불에 맞춘다. 자리는 `HeroSprite`가 정하고 여기서는 읽어만 간다 - 표를 두 군데
	# 들고 있으면 반드시 어긋난다.
	#
	# 등불 빛은 화면 레이어에 있어서 세상과 같이 확대되지 않으므로 카메라 배율만큼 곱한다.
	# **빛을 몸 한가운데에 두면 안 된다** - 더하기 합성이라 겹치면 캐릭터가 통째로 씻긴다.
	_lamp.position = (get_viewport().get_visible_rect().size * 0.5
		+ _hero_sprite.lantern_at() * _camera.zoom).round()


## 확인용. 화면 필터가 화면 텍스처를 다시 읽으므로 프레임을 넉넉히 기다린 뒤에 찍는다
## (안 그러면 드라이버가 죽는다 - CRT 오버레이에서 겪었다).
func _capture_and_quit() -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tools/_room.png")
	get_tree().quit()
