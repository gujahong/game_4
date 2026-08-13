extends SceneTree

## 두건 속 얼굴을 검게 지운다. `raw/`의 원본을 읽어 고친 것을 그 위 폴더에 쓴다.
##
## PixelLab이 그려준 얼굴은 또렷한데, 이 게임의 주인공은 **얼굴이 안 보여야 한다.** 다시 뽑는
## 대신 살색만 골라 그림자색으로 바꾼다 — **0 generation**이고, 원본이 `raw/`에 남아 있어
## 마음에 안 들면 되돌릴 수 있다.
##
## **애니메이션 프레임에도 그대로 돌려야 한다.** PixelLab 쪽 원본은 얼굴이 있는 채라
## 거기서 만들어지는 프레임에도 얼굴이 딸려 온다. 그래서 한 번 쓰고 버리는 스크립트가 아니라
## 폴더를 통째로 처리하게 만들어 뒀다.
##
## `--headless --script res://tools/_hood.gd`

## 읽을 곳. `raw/`는 PixelLab의 현재본, `copy/`는 손대기 전 판이다.
##
## [2026-08-13] 지금은 `copy/`를 읽는다. 회원님이 두건을 손보시면서 **등불까지 덮으셨고**,
## 그 판이 `raw/`에 들어와 있다. 원본에서 다시 만드는 편이 등불을 되살리는 것보다 간단하다.
const FROM_DIR := "res://assets/characters/pilgrim/copy"
const TO_DIR := "res://assets/characters/pilgrim"

## 살색으로 볼 범위. 옷(H220 언저리의 회청색)·가죽끈(어둡다)·등불(H44 언저리의 금색)과
## 확실히 갈리는 폭으로 잡았다.
## 색상각 아래 끝은 옆모습 볼의 `#85453f`가 **5도**여서 8에서 내린 값이다. 붉은 천도 이
## 언저리(4~6도)지만 채도가 0.77 넘게 진해서 아래의 채도 상한에 걸러진다.
const HUE_FROM := 3.0
const HUE_TO := 38.0
const SAT_FROM := 0.15
## 채도 위 끝은 **가슴의 붉은 천**(`#571b14`, 채도 0.77)이 안 걸리게 잡은 선이다.
const SAT_TO := 0.65
## 명도 아래 끝은 옆모습 볼에 남던 `#85453f`(명도 0.52)를 잡으려고 0.55에서 내린 값이다.
const VALUE_FROM := 0.45

## **위쪽 40%만 본다.** 두 가지를 피하려는 것이다.
##
## - 등불을 든 **손**이 같은 살색이라 색만으로 고르면 손까지 지워진다
## - 명도 문턱을 내린 뒤로는 **어깨의 붉은 천**(y22 언저리)도 걸린다. 얼굴은 y15~19라
##   40%로 좁히면 얼굴만 남기고 어깨는 빠진다
##
## 그림마다 인물이 놓인 높이가 달라서, 캔버스가 아니라 **그려진 부분**을 기준으로 잰다.
##
## 0.40으로는 턱 쪽 살색(y20)이 경계에 딱 걸려 남았다. 0.45면 그것까지 들어가고 어깨의
## 붉은 천(y22)은 여전히 빠진다.
const UPPER_PART := 0.45

## 이보다 어두우면 "어둠"으로 본다. 두건 속에 혼자 남은 밝은 점을 찾는 데 쓴다.
const DARK := 0.12

## 지운 자리에 채울 색. 이 그림에서 가장 많이 쓰인 그림자색이라 팔레트가 안 늘어난다.
const SHADOW := Color("040303")


func _init() -> void:
	var dir := DirAccess.open(FROM_DIR)
	if dir == null:
		push_error("원본 폴더가 없다: %s" % FROM_DIR)
		quit()
		return

	for name in dir.get_files():
		if not name.ends_with(".png"):
			continue
		var image := Image.load_from_file("%s/%s" % [FROM_DIR, name])
		image.convert(Image.FORMAT_RGBA8)
		var wiped := _wipe_face(image)
		image.save_png("%s/%s" % [TO_DIR, name])
		print("%-12s 얼굴 %d칸을 지웠다" % [name, wiped])
	quit()


func _wipe_face(image: Image) -> int:
	var box := _content(image)
	var limit := int(float(box.position.y) + float(box.size.y) * UPPER_PART)
	var wiped := 0

	for y in mini(limit, image.get_height()):
		for x in image.get_width():
			if not _is_skin(image.get_pixel(x, y)):
				continue
			image.set_pixel(x, y, SHADOW)
			wiped += 1

	# 살색이 아닌데 두건 속에 혼자 남는 점이 있다. 옷과 같은 회청색 계열이라 색으로는 못
	# 가른다. 대신 **어둠에 둘러싸였는지**로 가른다 - 두건 안이니까 사방이 어두운 것이다.
	#
	# 얼굴을 지운 뒤의 그림을 놓고 판정해야 한다. 지우기 전에는 옆이 아직 얼굴이라 안 걸린다.
	var after := image.duplicate() as Image
	for y in mini(limit, image.get_height()):
		for x in image.get_width():
			var c := after.get_pixel(x, y)
			if c.a < 0.5 or c.get_luminance() < DARK:
				continue
			# **넷 다** 어두울 때만 지운다. 셋으로 두면 두건의 흰 테두리까지 먹는다 -
			# 얼굴을 검게 칠하고 나면 테두리 안쪽이 어둠이 되어 조건에 걸린다.
			# 테두리는 옆으로 이어져 있으니 밝은 이웃이 하나는 남는다.
			if _dark_neighbours(after, x, y) < 4:
				continue
			image.set_pixel(x, y, SHADOW)
			wiped += 1
	return wiped


func _dark_neighbours(image: Image, x: int, y: int) -> int:
	var dark := 0
	var steps: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for step in steps:
		var at: Vector2i = Vector2i(x, y) + step
		if at.x < 0 or at.y < 0 or at.x >= image.get_width() or at.y >= image.get_height():
			continue
		var c := image.get_pixel(at.x, at.y)
		if c.a >= 0.5 and c.get_luminance() < DARK:
			dark += 1
	return dark


## 그려진 부분(투명하지 않은 곳)을 감싸는 사각형.
func _content(image: Image) -> Rect2i:
	var min_p := Vector2i(image.get_width(), image.get_height())
	var max_p := Vector2i.ZERO
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a < 0.5:
				continue
			min_p = min_p.min(Vector2i(x, y))
			max_p = max_p.max(Vector2i(x, y))
	return Rect2i(min_p, max_p - min_p)


func _is_skin(c: Color) -> bool:
	if c.a < 0.5:
		return false
	var hue: float = c.h * 360.0
	return (hue >= HUE_FROM and hue <= HUE_TO
		and c.s >= SAT_FROM and c.s <= SAT_TO
		and c.v >= VALUE_FROM)
