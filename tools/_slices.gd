extends SceneTree

## **성당 그림에서 화풍 참조로 쓸 조각들을 오린다.**
##
## 화풍 참조는 **32/64/128/256 정사각형**만 받는다. 성당은 448x448이라 그대로는 못 넣는데,
## **줄이면 안 된다** - 도트 격자가 깨져서 엉뚱한 화풍을 가르치게 된다. 오려야 한다.
##
## 그리고 오릴 때 **한 조각만 고를 이유가 없다.** 공식은 참조를 최대 64장까지 받고
## **5~10장을 권한다.** 다만 조건이 붙는다 —
##
## > *"핵심은 일관성이다. 비슷한 도트 밀도, 비슷한 외곽선, 비슷한 명암, 비슷한 비율."*
##
## **같은 그림에서 오리면 그 조건이 저절로 충족된다.** 그래서 결이 다른 자리를 골고루
## 오린다 - 아치, 스테인드글라스, 기둥, 바닥, 어두운 구석.
##
## `--headless --script res://tools/_slices.gd`

const SOURCE := "res://tools/_chapel448_seed1000.png"
const OUT_DIR := "res://assets/style"
const SHEET := "res://tools/_slices_sheet.png"

## 오릴 자리. `[이름, 왼쪽, 위, 한 변]`.
## 한 변은 **규격(256/128/64)** 이어야 한다. 원본이 448이라 256은 두 장쯤이 한계고,
## 나머지는 128로 잘게 딴다 - 작을수록 화풍을 많이 배운다(*"smaller resolution equals
## more style learning"*).
const SLICES := [
	["가운데_큰",     96,  96, 256],   # 아치 + 스테인드글라스 + 바닥이 다 들어간다
	["왼쪽_큰",        0, 130, 256],   # 왼쪽 벽면과 기둥. 결이 다른 한 장
	["스테인드글라스", 168, 150, 128],   # 이 그림에서 색이 제일 진한 자리
	["아치_천장",     150,   8, 128],   # 어두운 천장. 명암의 어두운 끝
	["기둥_결",        20, 150, 128],   # 세로로 선 것의 도트 결
	["바닥_안개",     140, 290, 128],   # 빛이 번지는 바닥. 밝은 끝
]

const ZOOM := 2
const GAP := 10


func _init() -> void:
	if not FileAccess.file_exists(SOURCE):
		push_error("원본이 없다: " + SOURCE)
		quit(1)
		return
	var src := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	src.convert(Image.FORMAT_RGBA8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var cuts: Array = []
	for slice in SLICES:
		var name: String = slice[0]
		var side: int = slice[3]
		# 원본 밖으로 나가지 않게 민다. 나가면 검은 띠가 참조에 섞인다.
		var x: int = clampi(slice[1], 0, src.get_width() - side)
		var y: int = clampi(slice[2], 0, src.get_height() - side)
		var cut := src.get_region(Rect2i(x, y, side, side))
		cut.save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUT_DIR, name]))
		print("%-16s %3dx%-3d  (%d, %d)에서" % [name, side, side, x, y])
		cuts.append(cut)

	_sheet(cuts)
	print("조각 %d장 → %s" % [cuts.size(), OUT_DIR])
	quit()


## 오린 것들을 나란히 놓고 본다. **눈으로 안 보면 어디를 잘랐는지 모른다.**
func _sheet(cuts: Array) -> void:
	var w := 0
	var h := 0
	for c in cuts:
		w += c.get_width() * ZOOM + GAP
		h = maxi(h, c.get_height() * ZOOM)
	var sheet := Image.create_empty(maxi(w, 1), maxi(h, 1), false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.09, 0.08, 0.07))
	var x := 0
	for c in cuts:
		var big := c.duplicate()
		big.resize(c.get_width() * ZOOM, c.get_height() * ZOOM, Image.INTERPOLATE_NEAREST)
		sheet.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i(x, 0))
		x += big.get_width() + GAP
	sheet.save_png(ProjectSettings.globalize_path(SHEET))
