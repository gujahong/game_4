extends SceneTree

## 둘러 놓은 투명 여백을 **도로 잘라낸다.** 알맹이가 있는 데까지만 남긴다.
##
## `--headless --script res://tools/_unpad.gd`

const TARGET := "res://assets/enemies/paper.png"


func _init() -> void:
	var image := Image.load_from_file(TARGET)
	image.convert(Image.FORMAT_RGBA8)
	var used := image.get_used_rect()
	if used.size == image.get_size():
		print("여백이 없다(%s). 아무것도 안 한다." % str(image.get_size()))
		quit()
		return

	var cut := image.get_region(used)
	cut.save_png(TARGET)
	print("여백을 잘랐다: %s -> %s" % [str(image.get_size()), str(cut.get_size())])
	quit()
