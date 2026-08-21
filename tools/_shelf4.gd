extends SceneTree

## 일회용. 뽑은 책장의 여백을 자르고 4배로 키워 눈으로 볼 수 있게 한다.

func _init() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path("res://tools/_cmp/shelf4.png"))
	img.convert(Image.FORMAT_RGBA8)
	var cut := img.get_region(img.get_used_rect())
	print("본체 ", cut.get_size())
	cut.resize(cut.get_width() * 4, cut.get_height() * 4, Image.INTERPOLATE_NEAREST)
	cut.save_png(ProjectSettings.globalize_path("res://tools/_shelf4_zoom.png"))
	quit()
