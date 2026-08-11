extends SceneTree

## 일회용. 작은 그림을 정수배로 확대해 눈으로 보게 한다(타일셋 시트처럼 128px짜리는 그대로는 안 보인다).
## `--headless --script res://tools/_zoom.gd`

const SOURCE := "res://assets/tilesets/marble_void_image.png"
const OUTPUT := "res://tools/_zoom.png"
const SCALE := 5


func _init() -> void:
	var image := Image.load_from_file(SOURCE)
	image.resize(image.get_width() * SCALE, image.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	image.save_png(OUTPUT)
	print("저장: %s (%dx%d)" % [OUTPUT, image.get_width(), image.get_height()])
	quit()
