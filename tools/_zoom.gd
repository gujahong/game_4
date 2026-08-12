extends SceneTree

## 일회용. 작은 그림을 정수배로 확대해 눈으로 보게 한다(타일셋 시트처럼 128px짜리는 그대로는 안 보인다).
## `--headless --script res://tools/_zoom.gd`

const SOURCE := "res://assets/photos/pilgrim.png"
const OUTPUT := "res://tools/_zoom.png"
const SCALE := 8


func _init() -> void:
	var image := Image.load_from_file(SOURCE)
	image.resize(image.get_width() * SCALE, image.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	# 투명 배경이면 검은 실루엣이 안 보인다. 회색을 깔고 그 위에 얹는다.
	var backdrop := Image.create_empty(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8)
	backdrop.fill(Color(0.55, 0.55, 0.55))
	backdrop.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i.ZERO)
	image = backdrop
	image.save_png(OUTPUT)
	print("저장: %s (%dx%d)" % [OUTPUT, image.get_width(), image.get_height()])
	quit()
