extends Node2D
class_name Portal

## 관문과 그 너머의 세계. **뒤 그림은 일렁이고, 관문은 멎어 있다.**
##
## 합성본을 미리 만들지 않는다 - 노드 두 개를 겹쳐 놓아야 뒤쪽만 따로 움직이거나, 다가갈 때
## 뒤쪽만 커지게 할 수 있다.
##
## 관문 그림은 **문 구멍이 투명하게 도려내진 것**이어야 한다(`tools/_cutout.gd`가 만든다).

const WAVE_SHADER := "res://shaders/PortalWave.gdshader"

@export var gate_texture: Texture2D
@export var beyond_texture: Texture2D

## 문 구멍의 가운데(관문 그림에 대한 비율). `_cutout.gd`가 재서 알려준다.
## pixen이 주제를 0.62~0.63에 놓기 때문에 가운데(0.5)가 아니다.
@export var opening := Vector2(0.631, 0.545)

var _beyond: Sprite2D
var _gate: Sprite2D


func _ready() -> void:
	_beyond = Sprite2D.new()
	_beyond.texture = beyond_texture
	var wave := ShaderMaterial.new()
	wave.shader = load(WAVE_SHADER)
	_beyond.material = wave
	add_child(_beyond)

	_gate = Sprite2D.new()
	_gate.texture = gate_texture
	add_child(_gate)

	_place()


## 뒤 그림을 문 구멍 가운데에 맞춘다. 관문보다 크면 밖으로 나가지만 문틀에 가려 안 보인다.
func _place() -> void:
	if gate_texture == null:
		return
	var gate_size := Vector2(gate_texture.get_size())
	_gate.position = Vector2.ZERO
	_beyond.position = gate_size * (opening - Vector2(0.5, 0.5))
