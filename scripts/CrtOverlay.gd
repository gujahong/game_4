extends CanvasLayer
class_name CrtOverlay

## CRT 모니터 흉내(볼록렌즈 왜곡 + 가로 주사선)를 화면 전체에 씌운다. 다른 모든 것 위에 놓여서
## 이미 그려진 화면을 다시 읽어 비튼다.
##
## **아직 확정된 연출이 아니다.** C 키로 껐다 켰다 하며 비교해보라고 만들어둔 것이다.
##
## 대가를 하나 적어둔다. 이 게임은 640x360을 정수배로만 확대해서 도트가 화면 픽셀에 딱 떨어지는
## 것이 규칙인데, **왜곡은 그 규칙을 깬다.** 화면 가장자리로 갈수록 도트가 늘어지고 계단처럼
## 울렁인다. 진짜 CRT가 그랬으니 어울린다고 볼 수도 있고, 애써 지킨 격자를 스스로 무너뜨리는
## 것이라고 볼 수도 있다. 눈으로 보고 정할 일이다.

const SHADER_PATH := "res://shaders/CrtScreen.gdshader"
const LAYER := 200

var _screen: ColorRect


func _ready() -> void:
	layer = LAYER
	_screen = ColorRect.new()
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var effect := ShaderMaterial.new()
	effect.shader = load(SHADER_PATH)
	_screen.material = effect
	add_child(_screen)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C:
		visible = not visible
		get_viewport().set_input_as_handled()
