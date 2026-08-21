extends SceneTree
const LIST := [
	["관문 gate_4_wide", "res://assets/photos/gate_4_wide.png"],
	["문 너머 archive", "res://assets/photos/archive.png"],
]
func _init() -> void:
	for pair in LIST:
		var p: String = pair[1]
		if not FileAccess.file_exists(p): print("%-18s 없음  %s" % [pair[0], p]); continue
		var img := Image.load_from_file(ProjectSettings.globalize_path(p))
		img.convert(Image.FORMAT_RGBA8)
		var seen := {}; var sat := 0.0; var n := 0
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a < 0.5: continue
				seen[c.to_rgba32()] = true; sat += c.s; n += 1
		print("%-18s %4dx%-4d  색 %3d개  채도 %.2f" % [
			pair[0], img.get_width(), img.get_height(), seen.size(), sat/maxf(float(n),1.0)])
		# 눈으로 보게 절반 크기 미리보기(정수배 축소라 도트 격자는 유지된다)
		var small := img.duplicate()
		small.resize(img.get_width()/2, img.get_height()/2, Image.INTERPOLATE_NEAREST)
		small.save_png(ProjectSettings.globalize_path(
			"res://tools/_gate_%s.png" % p.get_file().get_basename()))
	quit()
