extends SceneTree

## 일회용. 뽑아본 책장 셋을 여백 자르고 4배로 키워 가로로 이어 붙인다.
## **작은 도트는 그대로는 눈으로 못 고른다**(ANIMATION.md §6).

const SOURCES := ["res://tools/_cmp/shelf1.png", "res://tools/_cmp/shelf2.png", "res://tools/_cmp/shelf3.png"]
const ZOOM := 4
const GAP := 12

func _init() -> void:
	var cuts: Array = []
	for path in SOURCES:
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		img.convert(Image.FORMAT_RGBA8)
		var cut := img.get_region(img.get_used_rect())
		cut.resize(cut.get_width() * ZOOM, cut.get_height() * ZOOM, Image.INTERPOLATE_NEAREST)
		cuts.append(cut)
	var w := 0
	var h := 0
	for c in cuts:
		w += c.get_width() + GAP
		h = maxi(h, c.get_height())
	var sheet := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.07, 0.06, 0.05))
	var x := 0
	for c in cuts:
		sheet.blit_rect(c, Rect2i(Vector2i.ZERO, c.get_size()), Vector2i(x, h - c.get_height()))
		x += c.get_width() + GAP
	sheet.save_png(ProjectSettings.globalize_path("res://tools/_shelf_compare.png"))
	print("저장 ", sheet.get_size())
	quit()
