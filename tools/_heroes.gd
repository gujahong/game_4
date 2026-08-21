extends SceneTree
## 후보 주인공 그림들을 나란히 놓고 본다. 어느 것이 지금 것인지 눈으로 고르려는 것.
const CANDS := [
	["pilgrim", "res://assets/_before_palette/characters/pilgrim/south.png"],
	["pilgrim_rot/walk", "res://assets/characters/pilgrim_rot/walk/south/0.png"],
	["pilgrim_drawn", "res://assets/characters/pilgrim_drawn/walk4/south/0.png"],
	["pilgrim2", "res://assets/characters/pilgrim2/raw/south.png"],
	["pilgrim3", "res://assets/characters/pilgrim3/raw/south.png"],
]
const ZOOM := 5
const GAP := 14
func _init() -> void:
	var cuts: Array = []
	for pair in CANDS:
		if not FileAccess.file_exists(pair[1]):
			print("없음: ", pair[1]); continue
		var img := Image.load_from_file(ProjectSettings.globalize_path(pair[1]))
		img.convert(Image.FORMAT_RGBA8)
		var cut := img.get_region(img.get_used_rect())
		print("%-20s %s  %s" % [pair[0], cut.get_size(), pair[1]])
		cut.resize(cut.get_width()*ZOOM, cut.get_height()*ZOOM, Image.INTERPOLATE_NEAREST)
		cuts.append(cut)
	var w := 0; var h := 0
	for c in cuts: w += c.get_width()+GAP; h = maxi(h, c.get_height())
	if cuts.is_empty(): quit(); return
	var sheet := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.09,0.08,0.07))
	var x := 0
	for c in cuts:
		sheet.blend_rect(c, Rect2i(Vector2i.ZERO, c.get_size()), Vector2i(x, h-c.get_height()))
		x += c.get_width()+GAP
	sheet.save_png(ProjectSettings.globalize_path("res://tools/_heroes.png"))
	quit()
