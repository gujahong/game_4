extends SceneTree
const SHOW := ["gate_4", "gate_1", "gate_2", "gate_wide"]
func _init() -> void:
	for name in SHOW:
		var p: String = "res://assets/photos/%s.png" % str(name)
		if not FileAccess.file_exists(p): continue
		var img := Image.load_from_file(ProjectSettings.globalize_path(p))
		img.convert(Image.FORMAT_RGBA8)
		var half := img.duplicate()
		half.resize(img.get_width()/2, img.get_height()/2, Image.INTERPOLATE_NEAREST)
		half.save_png(ProjectSettings.globalize_path("res://tools/_v_%s.png" % str(name)))
	print("저장")
	quit()
