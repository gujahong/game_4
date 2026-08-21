extends SceneTree
const LIST := [
	"res://tools/_chapel448_seed1000.png",
	"res://assets/photos/chapel_1.png",
	"res://assets/photos/chapel_2.png",
	"res://assets/backgrounds/chapel.png",
]
func _init() -> void:
	for p in LIST:
		if not FileAccess.file_exists(p): print("%-40s 없음" % p); continue
		var img := Image.load_from_file(ProjectSettings.globalize_path(p))
		img.convert(Image.FORMAT_RGBA8)
		var seen := {}; var sat := 0.0; var n := 0
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a < 0.5: continue
				seen[c.to_rgba32()] = true; sat += c.s; n += 1
		print("%-26s %4dx%-4d  색 %4d개  채도 %.2f" % [
			p.get_file(), img.get_width(), img.get_height(), seen.size(), sat/maxf(float(n),1.0)])
	quit()
