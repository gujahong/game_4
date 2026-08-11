extends Node

## 사진 쌓기가 어떻게 보이는지만 확인하는 씬. 게임 내용이 아니다.
## Space를 누르면 다음 장소에 닿은 셈치고 사진이 한 장 더 얹힌다.

const PHOTO_DIR := "res://assets/photos"

@onready var _stack: PhotoStack = $PhotoStack

var _paths: PackedStringArray = PackedStringArray()
var _next: int = 0


func _ready() -> void:
	var dir := DirAccess.open(PHOTO_DIR)
	if dir:
		for file in dir.get_files():
			if file.get_extension().to_lower() == "png":
				_paths.append("%s/%s" % [PHOTO_DIR, file])
		_paths.sort()

	_advance()
	if "--capture" in OS.get_cmdline_user_args():
		_capture_and_quit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_advance()


func _advance() -> void:
	if _paths.is_empty():
		return
	_stack.push_photo(load(_paths[_next % _paths.size()]))
	_next += 1


func _capture_and_quit() -> void:
	for shot in 5:
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tools/_stack_%d.png" % (shot + 1))
		_advance()
	get_tree().quit()
