extends SceneTree

## 일회용. **투시를 정하는 것은 주인공 그림이다.** 주인공·종이 더미·뽑은 책장을 같은
## 배율로 나란히 놓고 본다.

const SOURCES := [
	"res://assets/characters/pilgrim_rot/pilgrim_frames.tres",
	"res://assets/enemies/paper_pile.png",
	"res://assets/tilesets/bookshelf.png",
]
const ZOOM := 4
const GAP := 16

func _init() -> void:
	var cuts: Array = []
	for path in ["res://assets/characters/pilgrim/south.png", SOURCES[1], SOURCES[2]]:
		if not FileAccess.file_exists(path):
			print("없음: ", path)
			continue
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		img.convert(Image.FORMAT_RGBA8)
		var cut := img.get_region(img.get_used_rect())
		print(path, " ", cut.get_size())
		cut.resize(cut.get_width() * ZOOM, cut.get_height() * ZOOM, Image.INTERPOLATE_NEAREST)
		cuts.append(cut)
	var w := 0
	var h := 0
	for c in cuts:
		w += c.get_width() + GAP
		h = maxi(h, c.get_height())
	var sheet := Image.create_empty(maxi(w, 1), maxi(h, 1), false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.09, 0.08, 0.06))
	var x := 0
	for c in cuts:
		sheet.blit_rect(c, Rect2i(Vector2i.ZERO, c.get_size()), Vector2i(x, h - c.get_height()))
		x += c.get_width() + GAP
	sheet.save_png(ProjectSettings.globalize_path("res://tools/_view_compare.png"))
	quit()
