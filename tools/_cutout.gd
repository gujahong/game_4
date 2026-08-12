extends SceneTree

## 관문 그림에서 **문 안쪽만** 투명하게 도려낸다. 그 뒤에 다른 세계를 놓으려는 것.
##
## **회원님이 문 안쪽을 순백으로 칠해두셨다**(2026-08-12). 처음엔 검은 부분을 밝기로 골라
## 잘랐는데, 하늘과 돌 그림자까지 같이 먹어서 지저분했다. 순백은 이 그림에 달리 없는 색이라
## 한 번에 정확히 골라진다 - **자를 자리를 사람이 칠해주는 쪽이 훨씬 깨끗하다.**
##
## `--headless --script res://tools/_cutout.gd`

const SOURCE := "res://assets/photos/gate_4.png"
const OUTPUT := "res://assets/photos/gate_4_cut.png"

## 문이 있을 만한 가로 범위(비율). 돌의 밝은 부분이 잘못 걸리는 것을 막는 안전장치다.
const BAND_FROM := 0.40
const BAND_TO := 0.85
## 세 채널이 전부 이보다 밝으면 "칠해둔 흰색"으로 본다. 돌은 이만큼 밝지 않다.
const WHITE := 0.95


func _init() -> void:
	var image := Image.load_from_file(SOURCE)
	image.convert(Image.FORMAT_RGBA8)
	var w := image.get_width()
	var h := image.get_height()

	var from_x := int(w * BAND_FROM)
	var to_x := int(w * BAND_TO)
	var cut := 0
	var box := Rect2i(w, h, 0, 0)  # 자른 자리의 최소/최대를 모은다

	for y in h:
		for x in range(from_x, to_x):
			var c := image.get_pixel(x, y)
			if c.r < WHITE or c.g < WHITE or c.b < WHITE:
				continue
			image.set_pixel(x, y, Color(0, 0, 0, 0))
			cut += 1
			box.position.x = mini(box.position.x, x)
			box.position.y = mini(box.position.y, y)
			box.size.x = maxi(box.size.x, x)
			box.size.y = maxi(box.size.y, y)

	image.save_png(OUTPUT)
	print("잘라낸 픽셀: %d" % cut)
	print("문 구멍 범위: x %d~%d, y %d~%d  (%dx%d 이미지 기준)"
		% [box.position.x, box.size.x, box.position.y, box.size.y, w, h])
	print("가운데 비율: %.3f" % ((float(box.position.x + box.size.x) * 0.5) / float(w)))
	print("저장: %s" % OUTPUT)
	quit()
