extends TextureRect
class_name FilteredBackground

## 배경 한 장에 DitherFilter를 씌워 보여준다. 배경은 이 노드 하나로만 화면에 올린다.
##
## 값은 셰이더의 기본값을 그대로 쓴다 - 그 기본값이 곧 CLAUDE.md에 고정해둔 화풍이다. 화풍을
## 바꾸고 싶으면 `tools/FilterPreview.tscn`으로 맞춰보고 셰이더 기본값을 고치면, 배경이 몇 장이든
## 한꺼번에 따라온다. 여기서 값을 따로 덮어쓰지 말 것 - 그러면 배경마다 화풍이 갈라진다.
##
## 등불처럼 색을 지켜야 하는 것은 이 노드의 자식이 아니라 **형제로, 이 노드보다 뒤에** 놓는다.
## 자식으로 넣으면 같이 필터를 통과해서 회색이 된다.

const SHADER_PATH := "res://shaders/DitherFilter.gdshader"


func _ready() -> void:
	var filter := ShaderMaterial.new()
	filter.shader = load(SHADER_PATH)
	material = filter
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# 늘리지 않고 가운데 놓는다. 화면(960x540)을 통째로 덮는 그림은 pixen의 면적 상한을 넘어서
	# 아예 못 뽑으므로, 그림은 항상 화면보다 작다. 늘려 채우면 도트가 깨진다.
	stretch_mode = TextureRect.STRETCH_KEEP_CENTERED


## 배경을 갈아끼운다. 필터는 그대로 유지된다.
func show_background(path: String) -> void:
	texture = load(path)
