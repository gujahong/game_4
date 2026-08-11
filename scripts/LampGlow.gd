extends Sprite2D
class_name LampGlow

## 주인공이 들고 다니는 등불의 빛.
##
## **FilteredBackground의 자식으로 넣지 말 것.** 자식이면 배경과 함께 필터를 통과해서 회색이 된다.
## 형제로, 배경보다 뒤에(위에 그려지게) 놓아야 색을 지킨다.
##
## 임시다. 지금은 코드로 그린 원형 그라디언트라 자세히 보면 동그란 테두리가 보인다. 등불 그림이
## 나오면 이 파일은 통째로 버리고 그 그림을 쓰면 된다.

@export var glow_size: int = 128:
	set(value):
		glow_size = value
		_rebuild()

@export var core_color: Color = Color(1.0, 0.78, 0.42, 0.95):
	set(value):
		core_color = value
		_rebuild()

@export var edge_color: Color = Color(1.0, 0.45, 0.1, 0.0):
	set(value):
		edge_color = value
		_rebuild()


const SHADER_PATH := "res://shaders/DitherLight.gdshader"


func _ready() -> void:
	# 빛도 배경과 같은 디더 격자로 흩어져야 한다. 매끈한 그라디언트로 두면 도트로 된 화면에서
	# 빛만 혼자 부드러워 겉돈다. (셰이더가 더하기 합성까지 맡는다)
	var dithered := ShaderMaterial.new()
	dithered.shader = load(SHADER_PATH)
	material = dithered
	_rebuild()


func _rebuild() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, core_color)
	gradient.set_color(1, edge_color)

	var glow := GradientTexture2D.new()
	glow.gradient = gradient
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.5)
	glow.fill_to = Vector2(1.0, 0.5)
	glow.width = glow_size
	glow.height = glow_size
	texture = glow
