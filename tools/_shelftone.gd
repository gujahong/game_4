extends SceneTree

## 일회용. 뽑힌 책장의 채도를 타일셋과 같은 값(0.30)으로 낮춘다 - 서고 바닥이 그 값으로
## 눌려 있어서(`_desat.gd`), 그 위에 설 가구도 같은 눈금이어야 한 세계가 된다.
## 원본(bookshelf_raw.png)은 안 건드린다.

const CHOSEN := 0.30

func _init() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path("res://assets/tilesets/bookshelf_raw.png"))
	image.convert(Image.FORMAT_RGBA8)
	var used := image.get_used_rect()
	var cut := image.get_region(used)
	for y in cut.get_height():
		for x in cut.get_width():
			var c := cut.get_pixel(x, y)
			if c.a <= 0.01:
				continue
			var grey := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			cut.set_pixel(x, y, Color(
				lerpf(grey, c.r, CHOSEN), lerpf(grey, c.g, CHOSEN), lerpf(grey, c.b, CHOSEN), c.a))
	cut.save_png(ProjectSettings.globalize_path("res://assets/tilesets/bookshelf.png"))
	var big := cut.duplicate()
	big.resize(cut.get_width() * 4, cut.get_height() * 4, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path("res://tools/_shelf_zoom.png"))
	print("채도 ", CHOSEN, "로 저장 ", cut.get_size())
	quit()
