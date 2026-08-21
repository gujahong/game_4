extends SceneTree

## 일회용. 타일 시트에서 **네 모서리가 다 upper(나무 바닥)인 타일**을 찾아 3x3으로 이어
## 붙여 96x96 조각을 만든다. `create_map_object`의 화풍 참조(background_image)로 쓴다 -
## 게임 화면은 일부러 어두워서 참조가 못 되고, 타일 원본이 밝은 정본이다.
## `--headless --script res://tools/_chunk.gd`

const SHEET := "res://assets/tilesets/wood_chasm_image.png"
const META := "res://assets/tilesets/wood_chasm_metadata.json"
const OUTPUT := "res://tools/_floor_chunk.png"


func _init() -> void:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(META))
	var box: Dictionary = {}
	for tile in meta["tileset_data"]["tiles"]:
		var corners: Dictionary = tile["corners"]
		var all_upper := true
		for side in corners:
			if corners[side] != "upper":
				all_upper = false
				break
		if all_upper:
			box = tile["bounding_box"]
			print("전부 나무인 타일: ", tile["name"], " @ ", box)
			break
	if box.is_empty():
		push_error("네 모서리가 다 upper인 타일이 없다")
		quit(1)
		return

	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SHEET))
	sheet.convert(Image.FORMAT_RGBA8)
	var rect := Rect2i(int(box["x"]), int(box["y"]), int(box["width"]), int(box["height"]))
	var chunk := Image.create_empty(96, 96, false, Image.FORMAT_RGBA8)
	for r in 3:
		for c in 3:
			chunk.blit_rect(sheet, rect, Vector2i(c * 32, r * 32))
	chunk.save_png(ProjectSettings.globalize_path(OUTPUT))
	print("저장: ", OUTPUT)
	quit()
