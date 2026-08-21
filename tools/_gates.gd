extends SceneTree
func _init() -> void:
	var dir := DirAccess.open("res://assets/photos")
	var names: Array = []
	dir.list_dir_begin()
	var n := dir.get_next()
	while n != "":
		if n.ends_with(".png") and (n.begins_with("gate") or n.begins_with("tower_gate")):
			names.append(n)
		n = dir.get_next()
	names.sort()
	for name in names:
		var p: String = "res://assets/photos/" + str(name)
		var img := Image.load_from_file(ProjectSettings.globalize_path(p))
		img.convert(Image.FORMAT_RGBA8)
		var seen := {}; var sat := 0.0; var c := 0
		for y in img.get_height():
			for x in img.get_width():
				var col := img.get_pixel(x, y)
				if col.a < 0.5: continue
				seen[col.to_rgba32()] = true; sat += col.s; c += 1
		print("%-22s %4dx%-4d  색 %5d개  채도 %.2f" % [
			name, img.get_width(), img.get_height(), seen.size(), sat/maxf(float(c),1.0)])
	quit()
