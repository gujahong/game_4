extends SceneTree
const LIST := [
	["새 주인공", "res://tools/_new/south.png"],
	["그 것", "res://assets/_before_palette/enemies/watcher.png"],
	["종이로 된 것", "res://assets/_before_palette/enemies/paper.png"],
	["바닥 타일셋", "res://assets/_before_palette/tilesets/wood_chasm_image.png"],
]
func _init() -> void:
	for pair in LIST:
		var p: String = pair[1]
		if not FileAccess.file_exists(p): print("%-14s 없음" % pair[0]); continue
		var img := Image.load_from_file(ProjectSettings.globalize_path(p))
		img.convert(Image.FORMAT_RGBA8)
		var seen := {}; var sat := 0.0; var n := 0
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a < 0.5: continue
				seen[c.to_rgba32()] = true; sat += c.s; n += 1
		print("%-14s %4dx%-4d  색 %3d개  칠해진 칸 %6d  채도 %.2f" % [
			pair[0], img.get_width(), img.get_height(), seen.size(), n, sat/maxf(float(n),1.0)])
	quit()
