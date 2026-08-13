extends SceneTree

## 일회용. 작은 그림을 정수배로 확대해 눈으로 보게 한다(타일셋 시트처럼 128px짜리는 그대로는 안 보인다).
## `--headless --script res://tools/_zoom.gd`

## 여러 장을 주면 가로로 이어 붙여 한 장으로 만든다.
const SOURCES := [
	"res://assets/characters/pilgrim_rot/walk/south/0.png",
	"res://assets/characters/pilgrim_rot/walk/south/1.png",
	"res://assets/characters/pilgrim_rot/walk/south/2.png",
	"res://assets/characters/pilgrim_rot/walk/south/3.png",
	"res://assets/characters/pilgrim_rot/walk/west/0.png",
	"res://assets/characters/pilgrim_rot/walk/west/1.png",
	"res://assets/characters/pilgrim_rot/walk/west/2.png",
	"res://assets/characters/pilgrim_rot/walk/west/3.png",
]
const OUTPUT := "res://tools/_zoom.png"
const SCALE := 12


func _init() -> void:
	var parts: Array[Image] = []
	for path in SOURCES:
		var part := Image.load_from_file(path)
		part.resize(part.get_width() * SCALE, part.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
		parts.append(part)

	var width := 0
	var height := 0
	for part in parts:
		width += part.get_width()
		height = maxi(height, part.get_height())

	# 투명 배경이면 어두운 그림이 안 보인다. 회색을 깔고 그 위에 얹는다.
	var sheet := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.55, 0.55, 0.55))
	var at := 0
	for part in parts:
		sheet.blend_rect(part, Rect2i(Vector2i.ZERO, part.get_size()), Vector2i(at, 0))
		at += part.get_width()

	sheet.save_png(OUTPUT)
	print("저장: %s (%dx%d)" % [OUTPUT, sheet.get_width(), sheet.get_height()])
	quit()
