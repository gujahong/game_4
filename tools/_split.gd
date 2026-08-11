extends SceneTree

## 일회용. 가로 배경을 **갈라진 이음매에서** 반으로 잘라 정사각형 사진 두 장으로 만든다.
##
## pixen이 640x360처럼 가로로 긴 캔버스에서 좌우로 갈라진 그림을 내놓는 것은 지금까지 결함이었다.
## 사진을 쌓는 방식으로 가면 그 자리가 곧 자를 자리가 되고, 한 장에서 두 장이 나온다.
##
## `--headless --script res://tools/_split.gd`로 돌린다.

const SOURCES := ["chapel", "forest", "tower", "tower_gate"]
const SIZE := 320   ## 사진 한 장의 크기. 앞으로 새로 뽑을 것도 이 크기로 맞춘다.
const TOP := 20     ## 세로 360에서 320을 남기려면 위아래로 20씩 버린다.


func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/photos")
	for name in SOURCES:
		var image := Image.load_from_file("res://assets/backgrounds/%s.png" % name)
		for half in 2:
			var piece := image.get_region(Rect2i(half * SIZE, TOP, SIZE, SIZE))
			var path := "res://assets/photos/%s_%d.png" % [name, half + 1]
			piece.save_png(path)
			print("저장: ", path)
	quit()
