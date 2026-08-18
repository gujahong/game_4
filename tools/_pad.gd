extends SceneTree

## 그림 사방에 **투명 여백을 두른다.** 가장자리가 바깥으로 번져 나가려면(`EdgeBleed`) 번져
## 나갈 자리가 있어야 하는데, 스프라이트는 제 그림 밖으로는 한 점도 못 그린다.
##
## `--headless --script res://tools/_pad.gd`

const TARGET := "res://assets/enemies/paper.png"
const PAD := 96


func _init() -> void:
	var image := Image.load_from_file(TARGET)
	image.convert(Image.FORMAT_RGBA8)
	var w := image.get_width()
	var h := image.get_height()
	if w > 600:
		print("이미 여백이 둘러져 있다(%dx%d). 아무것도 안 한다." % [w, h])
		quit()
		return

	var roomy := Image.create_empty(w + PAD * 2, h + PAD * 2, false, Image.FORMAT_RGBA8)
	roomy.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(PAD, PAD))
	roomy.save_png(TARGET)
	print("여백을 둘렀다: %dx%d (원본이 차지하는 비율 %.3f)" % [
		roomy.get_width(), roomy.get_height(), float(w) / float(roomy.get_width())])
	quit()
