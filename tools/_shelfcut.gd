extends SceneTree

## 일회용. 뽑힌 책장에서 투명 여백을 자르고(확대·축소 없이) 확대본도 한 장 남긴다.

func _init() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path("res://assets/tilesets/bookshelf_raw.png"))
	image.convert(Image.FORMAT_RGBA8)
	var used := image.get_used_rect()
	print("본체: ", used)
	var cut := image.get_region(used)
	cut.save_png(ProjectSettings.globalize_path("res://assets/tilesets/bookshelf.png"))
	var big := cut.duplicate()
	big.resize(cut.get_width() * 4, cut.get_height() * 4, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path("res://tools/_shelf_zoom.png"))
	print("저장: bookshelf.png ", cut.get_size())
	quit()
