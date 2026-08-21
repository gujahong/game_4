extends SceneTree

## **세상에 없는 문자를 만든다**(회원님, 2026-08-19).
##
## 서가에 적힌 것은 암호가 아니라 **우리가 못 읽는 문자로 이미 쓰인 것**이다. 그래서
## 한글 자모를 섞거나(암호로 보인다) 무작위 한글 음절을 쓰면(우리 글자다) 안 된다.
## 없는 문자를 만들어야 한다.
##
## ### 한 문자 체계로 보이려면 규칙이 있어야 한다
##
## 아무렇게나 그은 선을 스물네 개 모아 놓으면 무늬지 문자가 아니다. 진짜 문자는
## **같은 뼈대에 표식이 다르게 붙는다** - 로마자에 세로획이 있고, 룬에 줄기가 있고,
## 데바나가리에 윗줄이 있는 것처럼.
##
## 여기서는 이렇게 정한다.
##
## ```
## 뼈대   세로 줄기 하나가 위에서 아래까지 (모든 글자에 있다)
## 윗줄   글자 꼭대기를 잇는 가로획 (있는 것과 없는 것이 있다)
## 표식   줄기의 왼쪽/오른쪽/양쪽에 가로획·갈고리·점
## ```
##
## 표식의 자리(위·가운데·아래)와 방향(왼·오른·양쪽)과 종류(획·갈고리·점)를 조합하면
## 스물네 개가 규칙적으로 나온다. **손으로 스물네 개를 그리는 것이 아니라 규칙을 적는 것이다** -
## 마음에 안 들면 규칙만 고쳐 다시 돌린다.
##
## `--headless --script res://tools/_glyphs.gd`

const OUT_DIR := "res://assets/ui/glyphs"
const SHEET := "res://tools/_glyphs_sheet.png"

## 글자 한 칸. 대사 글꼴이 16px이라 높이를 맞춘다. 폭은 조금 좁아야 글줄이 촘촘하다.
const W := 12
const H := 16
## 줄기가 서는 자리와, 글자가 차지하는 세로 범위(위·아래 여백을 남긴다).
const STEM_X := 5
const TOP := 2
const BOTTOM := 13

const INK := Color(1, 1, 1, 1)   ## 흰색으로 찍고 화면에서 색을 입힌다

## 표식이 붙는 높이 셋.
const ROWS := [4, 8, 11]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var made: Array[Image] = []

	# 규칙을 돌려 글자를 만든다. 윗줄 있음/없음 × 표식 종류 넷 × 붙는 자리 셋 = 24.
	var index := 0
	for crown in [false, true]:
		for kind in 4:
			for row in ROWS.size():
				var glyph := _draw_glyph(crown, kind, row, index)
				glyph.save_png(ProjectSettings.globalize_path(
					"%s/%02d.png" % [OUT_DIR, index]))
				made.append(glyph)
				index += 1

	_sheet(made)
	print("글자 %d개 → %s" % [made.size(), OUT_DIR])
	quit()


## 글자 하나. `crown`은 윗줄, `kind`는 표식 종류, `row`는 붙는 높이.
func _draw_glyph(crown: bool, kind: int, row: int, seed_i: int) -> Image:
	var image := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	var y: int = ROWS[row]

	# 줄기. 모든 글자에 있는 뼈대다.
	for k in range(TOP, BOTTOM + 1):
		image.set_pixel(STEM_X, k, INK)

	# 윗줄. 글자 꼭대기를 가로로 잇는다 - 있는 것과 없는 것이 갈리면 체계가 두 갈래로 읽힌다.
	if crown:
		for x in range(STEM_X - 3, STEM_X + 4):
			image.set_pixel(x, TOP, INK)

	# 표식. 방향은 글자 번호로 갈라서 왼쪽/오른쪽/양쪽이 골고루 나오게 한다.
	var side: int = seed_i % 3   # 0 왼쪽, 1 오른쪽, 2 양쪽
	match kind:
		0:  # 가로획
			_bar(image, y, side, 3)
		1:  # 갈고리 — 가로획 끝이 아래로 꺾인다
			_bar(image, y, side, 3)
			_hook(image, y, side)
		2:  # 짧은 획 둘
			_bar(image, y, side, 2)
			_bar(image, mini(y + 3, BOTTOM), side, 2)
		3:  # 점 — 줄기에서 한 칸 띄운다
			_dot(image, y, side)
	return image


func _bar(image: Image, y: int, side: int, length: int) -> void:
	if side != 1:
		for x in range(STEM_X - length, STEM_X):
			image.set_pixel(x, y, INK)
	if side != 0:
		for x in range(STEM_X + 1, STEM_X + 1 + length):
			image.set_pixel(x, y, INK)


func _hook(image: Image, y: int, side: int) -> void:
	var low: int = mini(y + 2, BOTTOM)
	if side != 1:
		for k in range(y, low + 1):
			image.set_pixel(STEM_X - 3, k, INK)
	if side != 0:
		for k in range(y, low + 1):
			image.set_pixel(STEM_X + 3, k, INK)


func _dot(image: Image, y: int, side: int) -> void:
	if side != 1:
		image.set_pixel(STEM_X - 2, y, INK)
		image.set_pixel(STEM_X - 3, y, INK)
	if side != 0:
		image.set_pixel(STEM_X + 2, y, INK)
		image.set_pixel(STEM_X + 3, y, INK)


## 눈으로 보는 시트. **스물네 개를 나란히 놓아야 한 체계로 보이는지 알 수 있다.**
func _sheet(made: Array[Image]) -> void:
	const ZOOM := 4
	const GAP := 2
	var cols := 12
	var rows: int = int(ceil(float(made.size()) / float(cols)))
	var cell_w: int = W * ZOOM + GAP
	var cell_h: int = H * ZOOM + GAP
	var sheet := Image.create_empty(cols * cell_w, rows * cell_h, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.09, 0.08, 0.07))
	for i in made.size():
		var big := made[i].duplicate()
		big.resize(W * ZOOM, H * ZOOM, Image.INTERPOLATE_NEAREST)
		sheet.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()),
			Vector2i((i % cols) * cell_w, (i / cols) * cell_h))
	sheet.save_png(ProjectSettings.globalize_path(SHEET))
