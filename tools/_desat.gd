extends SceneTree

## 타일셋의 **채도를 낮춘다.** 그림을 다시 뽑지 않고 숫자 하나로 조절한다.
##
## 서고 타일셋(`wood_chasm`)이 너무 쨍했다(회원님). 재보니 16,384픽셀이 **전부** 채도 0.3을
## 넘어서, `DitherFilter`를 통과해도 색이 거의 안 빠지고 화면에 그대로 나온다.
##
## 채도를 낮추면 두 가지가 따라온다.
##   1. 쨍한 것이 가라앉는다
##   2. **틴트가 살아난다** - 지금은 타일이 제 색을 다 갖고 있어 `tint`를 줘도 안 보이는데,
##      회색에 가까워지면 얹은 색이 그대로 보인다. 장소마다 색조를 정할 수 있게 된다
##
## `--headless --script res://tools/_desat.gd`
##
## `LEVELS`로 여러 단계를 한 장에 나란히 뽑아 눈으로 고른다. 고른 값을 `CHOSEN`에 적고 다시
## 돌리면 그 값으로 실제 타일셋이 덮어써진다. **원본(`_raw`)은 안 건드리므로 몇 번이든 다시 한다.**

const RAW := "res://assets/tilesets/wood_chasm_raw.png"
const OUT := "res://assets/tilesets/wood_chasm_image.png"
const SHEET := "res://tools/_desat_compare.png"

## 남길 채도. 0이면 완전 흑백, 1이면 원본 그대로.
const LEVELS := [1.0, 0.45, 0.30, 0.15]
const CHOSEN := 0.30

## 비교 그림을 몇 배로 키울지. 128px짜리는 그대로는 안 보인다.
const ZOOM := 3
const GAP := 8


func _init() -> void:
	var raw := Image.load_from_file(RAW)
	if raw == null:
		push_error("원본을 못 읽었다: %s" % RAW)
		quit()
		return

	# --- 나란히 놓고 보는 그림 ---
	var w: int = raw.get_width() * ZOOM
	var h: int = raw.get_height() * ZOOM
	var sheet := Image.create(w * LEVELS.size() + GAP * (LEVELS.size() - 1), h, false,
		Image.FORMAT_RGBA8)
	sheet.fill(Color(0.08, 0.08, 0.09, 1.0))

	for i in LEVELS.size():
		var keep: float = LEVELS[i]
		var one := _desaturate(raw, keep)
		print("채도 %.2f 남김  →  평균 %.3f   0.3 초과 %d%%" % [
			keep, _mean_saturation(one), _over_threshold(one)
		])
		one.resize(w, h, Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(one, Rect2i(0, 0, w, h), Vector2i(i * (w + GAP), 0))

	sheet.save_png(SHEET)
	print("비교: %s  (왼쪽부터 %s)" % [SHEET, str(LEVELS)])

	# --- 실제로 쓸 것 ---
	_desaturate(raw, CHOSEN).save_png(OUT)
	print("적용: %s  (채도 %.2f 남김)" % [OUT, CHOSEN])
	quit()


## 밝기 쪽으로 끌어당겨 채도를 뺀다. **밝기는 그대로 두는 것**이 중요하다 - 어두워지면
## 채도가 아니라 노출을 만진 것이 되어 형태가 뭉갠다.
func _desaturate(source: Image, keep: float) -> Image:
	# `duplicate()`는 Resource를 돌려주므로 **타입을 적어줘야** 아래에서 Color 추론이 된다.
	var out: Image = source.duplicate()
	for y in out.get_height():
		for x in out.get_width():
			var c: Color = out.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var lum: float = c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			out.set_pixel(x, y, Color(
				lerpf(lum, c.r, keep), lerpf(lum, c.g, keep), lerpf(lum, c.b, keep), c.a))
	return out


func _mean_saturation(image: Image) -> float:
	var total := 0.0
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			total += _saturation(c)
			count += 1
	return total / maxf(float(count), 1.0)


## `DitherFilter`가 색을 남기는 기준이 0.3이다. 이 비율이 낮을수록 회색으로 간다.
func _over_threshold(image: Image) -> int:
	var over := 0
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			count += 1
			if _saturation(c) > 0.3:
				over += 1
	return int(round(100.0 * float(over) / maxf(float(count), 1.0)))


func _saturation(c: Color) -> float:
	var hi: float = maxf(c.r, maxf(c.g, c.b))
	var lo: float = minf(c.r, minf(c.g, c.b))
	return (hi - lo) / hi if hi > 0.0 else 0.0
