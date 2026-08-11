extends Node
class_name Walker

## 방 안을 돌아다니는 주인공. **아직 그림이 없어서 등불 빛이 곧 주인공**이다.
##
## 임시가 아니라 이 게임에 맞는 표현이기도 하다 - 화면에서 색을 가진 것은 등불뿐이고,
## 그 등불을 든 것이 나다. 캐릭터 스프라이트가 생기면 이 빛 아래에 세우면 된다.
##
## 카메라가 나를 따라오므로 **나는 항상 화면 한가운데**에 있다. 그래서 등불(CanvasLayer)과
## 화면 필터의 빛도 가운데에 고정해두면 되고, 세상 쪽만 움직인다.
##
## 등불은 필터 판보다 **위** 레이어에 있어서 회색으로 안 변한다(`Room.tscn` 참고).

const SPEED := 90.0
const EDGE_PADDING := 10.0  ## 벽에 코를 박지 않게 바닥 안쪽으로 남기는 여유

@onready var _room: TilesetRoom = $World/Room
@onready var _camera: Camera2D = $World/Camera
@onready var _lamp: LampGlow = $LampLayer/Lamp
@onready var _screen: ColorRect = $FilterLayer/Screen

var _bounds: Rect2
var _at: Vector2  ## 세상 좌표에서 내가 서 있는 자리


func _ready() -> void:
	_bounds = _room.floor_rect_px().grow(-EDGE_PADDING)
	_at = _bounds.get_center()
	_camera.position = _at

	# 나는 늘 화면 한가운데에 있으므로 등불과 빛도 가운데 고정이다.
	_lamp.position = get_viewport().get_visible_rect().size * 0.5
	_screen.material.set_shader_parameter("light_position", Vector2(0.5, 0.5))

	if "--capture" in OS.get_cmdline_user_args():
		_capture_and_quit()


func _process(delta: float) -> void:
	var move := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	if move == Vector2.ZERO:
		return
	var next: Vector2 = _at + move.normalized() * SPEED * delta
	# 바닥 밖으로는 못 나간다. 벽 충돌을 따로 만들 것 없이 바닥 사각형에 가둔다.
	_at = Vector2(
		clampf(next.x, _bounds.position.x, _bounds.end.x),
		clampf(next.y, _bounds.position.y, _bounds.end.y)
	)
	_camera.position = _at


## 확인용. 화면 필터가 화면 텍스처를 다시 읽으므로 프레임을 넉넉히 기다린 뒤에 찍는다
## (안 그러면 드라이버가 죽는다 - CRT 오버레이에서 겪었다).
func _capture_and_quit() -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tools/_room.png")
	get_tree().quit()
