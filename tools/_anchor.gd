extends SceneTree

## **앵커에서 프로젝트 팔레트를 뽑는다.**
##
## PixelLab 공식 영상이 화풍 통일의 답으로 내놓은 것이 이것이다 —
## *"그림 한 장을 모든 것의 시각적 앵커로 삼았다. 화풍 이탈이 전혀 없었다."*
## 화풍은 **생성할 때 잡는 것이 아니라 만든 뒤에 팔레트로 강제하는 것**이다.
##
## 앵커는 **주인공**이다(회원님, 2026-08-19). 모든 화면에 나오고 화풍이 이미 잡혀 있다.
##
## 하는 일 둘.
##   1. 주인공 그림에서 쓰인 색을 많이 쓰인 순서로 뽑아 `palette.txt`에 적는다
##   2. 화풍 참조로 쓸 수 있게 **규격 크기(64x64)로 여백을 덧대** `anchor_64.png`를 만든다
##      - 규격은 32 / 64 / 128 / 256 정사각형뿐이다. 아니면 화풍 학습이 제대로 안 된다
##      - **확대하지 않고 투명 여백만 덧댄다**(그림 규칙)
##
## `--headless --script res://tools/_anchor.gd`

## 앵커. 네 방향 중 정면이 제일 많이 보이는 얼굴이다.
const ANCHOR := "res://assets/characters/pilgrim/south.png"
## 팔레트를 넓히려고 같이 읽는 것들.
##
## 처음엔 **주인공만** 읽었는데 그러면 안 됐다(2026-08-19). 16x31짜리 인물 하나에는
## 회색과 살빛뿐이라 나무 색이 없어서, 그 팔레트를 바닥 타일셋에 입히니 **난간이 분홍으로
## 변했다.** 팔레트가 세상 전체를 덮으려면 **제일 넓은 면을 차지하는 것**도 표본에 넣어야 한다.
##
## 그래도 순서는 지킨다 — **주인공이 먼저 읽히므로** 겹치는 색은 주인공 쪽이 살아남는다.
const ALSO := [
	"res://assets/characters/pilgrim/north.png",
	"res://assets/characters/pilgrim/east.png",
	"res://assets/characters/pilgrim/west.png",
	"res://assets/_before_palette/tilesets/wood_chasm_image.png",
]

const PALETTE_OUT := "res://assets/palette.txt"
const ANCHOR_OUT := "res://assets/anchor_64.png"
const SHEET_OUT := "res://tools/_palette_sheet.png"

## 화풍 참조로 넣을 수 있는 규격. 이 중 앵커가 들어가는 제일 작은 것을 쓴다.
const SIZES := [32, 64, 128, 256]
## 팔레트에 남길 색의 최대 개수. 너무 많으면 강제하는 뜻이 없어진다.
## 24색은 인물에는 맞았지만 나무 바닥까지 덮기엔 모자랐다.
const KEEP := 32


func _init() -> void:
	var counts: Dictionary = {}
	var sources: Array = [ANCHOR] + ALSO
	for path in sources:
		if not FileAccess.file_exists(path):
			print("없음: ", path)
			continue
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		img.convert(Image.FORMAT_RGBA8)
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a < 0.5:
					continue
				var key: int = c.to_rgba32()
				counts[key] = counts.get(key, 0) + 1

	# 많이 쓰인 순서로 줄 세운다. 넓은 면적을 차지하는 색이 곧 그 그림의 색이다.
	var keys: Array = counts.keys()
	keys.sort_custom(func(a, b) -> bool: return counts[a] > counts[b])
	var palette: Array[Color] = []
	for i in mini(keys.size(), KEEP):
		palette.append(Color(String("#%08x" % keys[i])))

	var text := "# 프로젝트 팔레트 — 앵커(%s)에서 뽑음\n" % ANCHOR.get_file()
	text += "# 많이 쓰인 순서. %d색 중 위 %d색\n" % [keys.size(), palette.size()]
	for i in palette.size():
		text += "%s  %d칸\n" % [palette[i].to_html(false), counts[keys[i]]]
	var file := FileAccess.open(PALETTE_OUT, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	print("팔레트: %s  (%d색 중 %d색 남김)" % [PALETTE_OUT, keys.size(), palette.size()])

	# 눈으로 보는 띠. 색 이름만 봐서는 어떤 팔레트인지 모른다.
	_swatch(palette)

	# 규격 크기 앵커. **여백만 덧대고 확대는 안 한다.**
	var src := Image.load_from_file(ProjectSettings.globalize_path(ANCHOR))
	src.convert(Image.FORMAT_RGBA8)
	var body := src.get_region(src.get_used_rect())
	var need: int = maxi(body.get_width(), body.get_height())
	var side: int = SIZES[SIZES.size() - 1]
	for size in SIZES:
		if size >= need:
			side = size
			break
	var padded := Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
	# 가운데에 놓되 **발이 아래에 닿게** 아래쪽으로 붙인다 - 서 있는 것이라야 참조로도 맞다.
	padded.blit_rect(body, Rect2i(Vector2i.ZERO, body.get_size()),
		Vector2i((side - body.get_width()) / 2, side - body.get_height()))
	padded.save_png(ProjectSettings.globalize_path(ANCHOR_OUT))
	print("앵커: %s  (본체 %s → %dx%d, 여백만 덧댐)" % [
		ANCHOR_OUT, body.get_size(), side, side])
	quit()


## 팔레트를 가로 띠로 찍는다. 한 칸 32px.
func _swatch(palette: Array[Color]) -> void:
	const CELL := 32
	var sheet := Image.create_empty(CELL * palette.size(), CELL, false, Image.FORMAT_RGBA8)
	for i in palette.size():
		sheet.fill_rect(Rect2i(i * CELL, 0, CELL, CELL), palette[i])
	sheet.save_png(ProjectSettings.globalize_path(SHEET_OUT))
