extends Sprite2D
class_name FilteredSprite

## 세계에 속한 물건(적, 소품)을 배경과 **같은 필터로** 그린다. 그래야 배경 위에 얹었을 때
## 따로 놀지 않는다.
##
## 등불(`LampGlow`)만 필터 바깥에 둔다 - 색을 지키는 것은 그것뿐이라는 규칙이다.

const SHADER_PATH := "res://shaders/DitherFilter.gdshader"

## 이 층을 얼마나 누를지. 따로 뽑은 물건은 배경보다 밝게 나오는 일이 많아서, 그냥 얹으면
## 오려 붙인 티가 난다. 어둡게 눌러 배경의 명암에 맞춘다.
##
## 노드의 `modulate`는 안 먹는다 - 셰이더가 COLOR를 통째로 덮어쓰기 때문이다. 이 값을 쓸 것.
@export var layer_modulate: Color = Color.WHITE:
	set(value):
		layer_modulate = value
		if material is ShaderMaterial:
			material.set_shader_parameter("layer_modulate", value)


func _ready() -> void:
	var filter := ShaderMaterial.new()
	filter.shader = load(SHADER_PATH)
	material = filter
	filter.set_shader_parameter("layer_modulate", layer_modulate)
