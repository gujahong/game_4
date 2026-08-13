extends SceneTree

## 참조로 넣을 그림을 만든다. **캔버스를 캐릭터 크기에 맞춰 잘라내는 것**이 전부다.
##
## PixelLab의 v3 회전(`create_character` + `reference_image`)은 내가 준 그림을 그대로 여덟
## 방향으로 돌려준다. 뽑기를 굴려 맞추는 게 아니라 **한 장을 정해놓고 나머지를 만들게 하는**
## 방식이라, 색과 화풍이 판마다 달라지는 문제가 안 생긴다.
##
## 다만 공식 자료에 함정이 하나 적혀 있다 — *"56x56 캔버스에 담긴 32x32 캐릭터를 참조로
## 넣었더니 생성된 것이 더 크게 나왔다. 캔버스를 캐릭터 크기에 맞춰 줄여서 넣을 것."*
## 우리 그림도 32px짜리가 48x48 캔버스에 들어 있어서 그대로 넣으면 안 된다.
##
## `--headless --script res://tools/_reference.gd`

## 회원님이 PixelLab에서 만드신 `empty hands` 상태의 정면. **정면만 마음에 든다**고 하셔서
## 이 한 장으로 나머지 방향을 만든다(2026-08-13).
const SOURCE := "res://assets/characters/pilgrim/empty/south.png"
const OUTPUT := "res://assets/characters/pilgrim/reference.png"


func _init() -> void:
	var image := Image.load_from_file(SOURCE)
	image.convert(Image.FORMAT_RGBA8)

	var box := _content(image)
	var cropped := Image.create_empty(box.size.x, box.size.y, false, Image.FORMAT_RGBA8)
	cropped.blit_rect(image, box, Vector2i.ZERO)
	cropped.save_png(OUTPUT)

	print("원본 %dx%d 에서 그려진 부분 x %d~%d, y %d~%d 를 잘랐다"
		% [image.get_width(), image.get_height(),
			box.position.x, box.end.x - 1, box.position.y, box.end.y - 1])
	print("저장: %s  (%dx%d)" % [OUTPUT, box.size.x, box.size.y])
	quit()


func _content(image: Image) -> Rect2i:
	var min_p := Vector2i(image.get_width(), image.get_height())
	var max_p := Vector2i.ZERO
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a < 0.5:
				continue
			min_p = min_p.min(Vector2i(x, y))
			max_p = max_p.max(Vector2i(x, y))
	return Rect2i(min_p, max_p - min_p + Vector2i.ONE)
