extends SceneTree

## 그림을 좌우로 뒤집어 **파일 자체를 고친다.**
##
## 스프라이트의 `flip_h`로 돌려 놓을 수도 있지만, 그러면 그 그림을 쓰는 데마다 뒤집는 것을
## 기억해야 한다 - 방에서는 안 뒤집히고 전투에서만 뒤집히는 식으로 어긋난다.
## **원본이 틀렸으면 원본을 고친다.**
##
## `--headless --script res://tools/_flip.gd`

const TARGET := "res://assets/enemies/paper.png"


func _init() -> void:
	var image := Image.load_from_file(TARGET)
	image.flip_x()
	image.save_png(TARGET)
	print("좌우를 뒤집었다: %s (%dx%d)" % [TARGET, image.get_width(), image.get_height()])
	quit()
