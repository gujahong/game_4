extends SceneTree

## 손에 든 등불을 지워 **빈손 주인공**을 만든다. 등불은 따로 그려서(`_lantern.gd`) 코드로
## 얹는다 - 그림에 박아 넣었더니 걷기 프레임마다 위치와 모양이 튀었고, 물건을 든 캐릭터에는
## 템플릿 애니메이션도 못 썼다(2026-08-13).
##
## **지울 자리를 손대기 전 판에서 찾는다.** 회원님 손질본에서는 등불이 어두운 색으로 덮여
## 있어서 망토 그늘과 구별이 안 된다. 손대기 전 판(`copy/`)에는 놋쇠색이 그대로 있으므로,
## 거기서 금색이 놓인 사각형을 재고 그 자리를 손질본에서 지운다.
##
## [실패한 방법] 처음엔 두 판을 픽셀마다 견줘 "달라진 곳"을 지웠다. **망토에 구멍이 났다** -
## Pixelorama에서 저장하면서 그림 전체가 다시 인코딩돼 등불과 상관없는 픽셀도 값이 조금씩
## 달라져 있었다. 차이로 찾으면 안 된다.
##
## `--headless --script res://tools/_unlantern.gd`

const EDITED_DIR := "res://assets/characters/pilgrim/raw"    ## 회원님 손질본
const ORIGINAL_DIR := "res://assets/characters/pilgrim/copy"  ## 손대기 전
const TO_DIR := "res://assets/characters/pilgrim"

## 놋쇠색. 색상각 38~60도의 또렷한 금색만 고른다.
const GOLD_FROM := 38.0
const GOLD_TO := 60.0
const GOLD_SAT := 0.30

## 금색 사각형을 사방으로 이만큼 넓혀서 지운다. 등불의 어두운 테두리까지 걷어내려는 것.
const GROW := 1


func _init() -> void:
	var dir := DirAccess.open(EDITED_DIR)
	if dir == null:
		push_error("폴더가 없다: %s" % EDITED_DIR)
		quit()
		return

	for name in dir.get_files():
		if not name.ends_with(".png"):
			continue
		var edited := Image.load_from_file("%s/%s" % [EDITED_DIR, name])
		var original := Image.load_from_file("%s/%s" % [ORIGINAL_DIR, name])
		edited.convert(Image.FORMAT_RGBA8)
		original.convert(Image.FORMAT_RGBA8)

		var before := edited.duplicate() as Image
		var wiped := 0
		for y in edited.get_height():
			for x in edited.get_width():
				var here := before.get_pixel(x, y)
				if here.a < 0.5 or not _is_gold(here):
					continue
				edited.set_pixel(x, y, _nearby(before, x, y))
				wiped += 1

		edited.save_png("%s/%s" % [TO_DIR, name])
		print("%-12s 남은 놋쇠 %d칸을 메웠다" % [name, wiped])
	quit()


## 금색이 아닌 이웃 색 하나. 구멍을 내지 않고 주변에 묻히려는 것.
func _nearby(image: Image, x: int, y: int) -> Color:
	var steps: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	]
	for step in steps:
		var at: Vector2i = Vector2i(x, y) + step
		if at.x < 0 or at.y < 0 or at.x >= image.get_width() or at.y >= image.get_height():
			continue
		var c := image.get_pixel(at.x, at.y)
		if c.a >= 0.5 and not _is_gold(c):
			return c
	return Color(0, 0, 0, 0)


func _is_gold(c: Color) -> bool:
	var hue: float = c.h * 360.0
	return hue >= GOLD_FROM and hue <= GOLD_TO and c.s >= GOLD_SAT
