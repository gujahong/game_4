extends SceneTree

## 그림 한 귀퉁이를 잘라 키운다. 화면을 1x로 보면 눈금이 안 읽혀서, 볼 데만 떼어 본다.
##   -- --from=res://tools/_battle_shot.png --rect=0,440,260,100 --zoom=4
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	var src: String = args.get("from", "res://tools/_battle_shot.png")
	var nums := String(args.get("rect", "0,440,260,100")).split(",")
	var zoom := int(args.get("zoom", "4"))
	var img := Image.load_from_file(ProjectSettings.globalize_path(src))
	var cut := img.get_region(Rect2i(int(nums[0]), int(nums[1]), int(nums[2]), int(nums[3])))
	cut.resize(cut.get_width() * zoom, cut.get_height() * zoom, Image.INTERPOLATE_NEAREST)
	cut.save_png(ProjectSettings.globalize_path("res://tools/_crop.png"))
	print("잘랐다: %dx%d" % [cut.get_width(), cut.get_height()])
	quit()
