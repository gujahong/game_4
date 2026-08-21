extends SceneTree
## 새로 받은 주인공 8방향을 나란히 놓고 본다.
const DIRS := ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
const ZOOM := 5
const GAP := 12
func _init() -> void:
	var cuts: Array = []
	for d in DIRS:
		var p := "res://tools/_new/%s.png" % d
		if not FileAccess.file_exists(p): continue
		var img := Image.load_from_file(ProjectSettings.globalize_path(p))
		img.convert(Image.FORMAT_RGBA8)
		var used := img.get_used_rect()
		if d == DIRS[0]:
			print("캔버스 %s  본체 %s" % [img.get_size(), used.size])
		var cut := img.get_region(used)
		cut.resize(cut.get_width()*ZOOM, cut.get_height()*ZOOM, Image.INTERPOLATE_NEAREST)
		cuts.append(cut)
	var w := 0; var h := 0
	for c in cuts: w += c.get_width()+GAP; h = maxi(h, c.get_height())
	var sheet := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.09,0.08,0.07))
	var x := 0
	for c in cuts:
		sheet.blend_rect(c, Rect2i(Vector2i.ZERO, c.get_size()), Vector2i(x, h-c.get_height()))
		x += c.get_width()+GAP
	sheet.save_png(ProjectSettings.globalize_path("res://tools/_newhero.png"))
	print("저장")
	quit()
