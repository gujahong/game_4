extends SceneTree

## **프로젝트 팔레트를 기존 에셋 전부에 강제한다.**
##
## 픽셀마다 팔레트에서 **제일 가까운 색**을 찾아 바꾼다. 서로 다른 도구로 다른 날 만든
## 에셋이라도 같은 색만 쓰게 되는 것이 요점이다(PixelLab 공식 영상의 화풍 통일 방법).
##
## **가까움은 OKLab에서 잰다.** RGB 거리로 재면 사람 눈과 다르게 나온다 - 특히 어두운
## 쪽에서 엉뚱한 색을 고른다. OKLab은 "눈에 보이는 차이"에 가깝게 만들어진 색공간이라
## 여기서 재야 갈아 끼운 티가 덜 난다.
##
## **원본은 안 지운다.** `assets/_before_palette/`에 복사해 두고 덮어쓰므로 되돌릴 수 있다.
## (git으로도 되돌아가지만 눈으로 비교하려면 옆에 있는 편이 낫다)
##
## `--headless --script res://tools/_repaint.gd`

const PALETTE := "res://assets/palette.txt"
const BACKUP := "res://assets/_before_palette"
const SHEET := "res://tools/_repaint_sheet.png"

## 이 폴더들 아래의 PNG를 전부 바꾼다.
const FOLDERS := ["res://assets/characters", "res://assets/enemies", "res://assets/tilesets"]
## 건드리지 않을 것. 원본(`_raw`)과 앵커, 그리고 이미 만든 백업.
const SKIP := ["_raw", "_before_palette", "anchor_64", "/raw/", "/copy/", "/empty/"]

## ### ★ 큰 일러스트는 팔레트를 안 입힌다 (회원님, 2026-08-19)
##
## *"일러스트 배경들은 단순하지 않았으면 좋겠어"* · *"그것, 일러스트와, 종이로 된 적은
## 멋있게 나와야 해"*
##
## 맞는 판단이다. 팔레트 강제는 **작은 스프라이트를 서로 어울리게** 만드는 도구지,
## 큰 그림에 쓰면 배경의 결이 통째로 뭉개진다. 512x512 그림의 42색을 32색으로 눌러봐야
## 얻는 것은 없고 잃는 것만 있다.
##
## **이 화면에서 제일 오래 보게 되는 그림들이라 여기만은 화려해도 된다** - 오히려
## 주변이 회색으로 눌려 있어서 이것들이 더 도드라진다.
const RICH := [
	"paper.png",           # 종이로 된 것 (512x512)
	"paper_stood.png",     # 그 일어선 자세
	"watcher.png",         # 그 것 (656x656)
	"hollow_armour.png",   # 갑옷 (160x208)
]

## 비교 시트에 넣을 것들. 눈으로 판단할 대표만 고른다.
const SHOW := [
	"res://assets/characters/pilgrim/south.png",
	"res://assets/enemies/paper_pile.png",
	"res://assets/tilesets/bookshelf.png",
	"res://assets/tilesets/wood_chasm_image.png",
]
const ZOOM := 3
const GAP := 10

var _palette: Array[Color] = []
var _lab: Array = []   ## 팔레트를 OKLab으로 미리 바꿔 둔다. 픽셀마다 다시 계산하면 느리다


func _init() -> void:
	_load_palette()
	if _palette.is_empty():
		push_error("팔레트가 비었다. 먼저 tools/_anchor.gd를 돌릴 것")
		quit(1)
		return

	var befores: Array = []
	for path in SHOW:
		befores.append(_read(path))

	var count := 0
	for folder in FOLDERS:
		count += _walk(folder)
	print("%d장에 팔레트를 입혔다 (%d색)" % [count, _palette.size()])

	var afters: Array = []
	for path in SHOW:
		afters.append(_read(path))
	_compare(befores, afters)
	quit()


func _load_palette() -> void:
	for line in FileAccess.get_file_as_string(PALETTE).split("\n"):
		var text := line.strip_edges()
		if text.is_empty() or text.begins_with("#"):
			continue
		var hex := text.split(" ")[0]
		var c := Color(hex)
		_palette.append(c)
		_lab.append(_oklab(c))


## 폴더를 훑어 PNG마다 팔레트를 입힌다. 바꾼 장수를 돌려준다.
func _walk(folder: String) -> int:
	var changed := 0
	var dir := DirAccess.open(folder)
	if dir == null:
		return 0
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var path: String = folder + "/" + name
		if dir.current_is_dir():
			changed += _walk(path)
		elif name.ends_with(".png") and not _skipped(path):
			if _repaint(path):
				changed += 1
		name = dir.get_next()
	dir.list_dir_end()
	return changed


func _skipped(path: String) -> bool:
	for mark in SKIP:
		if path.contains(mark):
			return true
	return path.get_file() in RICH


func _repaint(path: String) -> bool:
	var image := _read(path)
	if image == null:
		return false

	# 원본을 백업에 남긴다. 폴더 구조를 그대로 옮겨야 나중에 짝을 찾을 수 있다.
	var kept: String = path.replace("res://assets/", BACKUP + "/")
	DirAccess.make_dir_recursive_absolute(kept.get_base_dir())
	if not FileAccess.file_exists(kept):
		image.save_png(ProjectSettings.globalize_path(kept))

	# 같은 색이 여러 번 나오므로 한 번 고른 것은 기억한다. 이게 없으면 큰 그림에서 아주 느리다.
	var known: Dictionary = {}
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a < 0.004:
				continue
			var key: int = c.to_rgba32()
			if not known.has(key):
				known[key] = _nearest(c)
			# **알파는 원본 것을 지킨다.** 팔레트 색은 불투명이라 그대로 쓰면
			# 반투명하게 흩어진 가장자리가 통째로 살아나 테두리가 두꺼워진다.
			var picked: Color = known[key]
			image.set_pixel(x, y, Color(picked.r, picked.g, picked.b, c.a))
	image.save_png(ProjectSettings.globalize_path(path))
	return true


## 팔레트에서 제일 가까운 색. OKLab 거리로 잰다.
func _nearest(c: Color) -> Color:
	var want := _oklab(c)
	var best := 0
	var best_gap := INF
	for i in _lab.size():
		var gap: float = (want - _lab[i]).length_squared()
		if gap < best_gap:
			best_gap = gap
			best = i
	return _palette[best]


## sRGB → OKLab. 출처: Björn Ottosson, "A perceptual color space for image processing".
func _oklab(c: Color) -> Vector3:
	var r := _linear(c.r)
	var g := _linear(c.g)
	var b := _linear(c.b)
	var l := pow(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b, 1.0 / 3.0)
	var m := pow(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b, 1.0 / 3.0)
	var s := pow(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b, 1.0 / 3.0)
	return Vector3(
		0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
		1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
		0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)


func _linear(v: float) -> float:
	return pow((v + 0.055) / 1.055, 2.4) if v > 0.04045 else v / 12.92


func _read(path: String) -> Image:
	if not FileAccess.file_exists(path):
		return null
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	image.convert(Image.FORMAT_RGBA8)
	return image


## 바꾸기 전과 후를 위아래로 놓고 가로로 이어 붙인다.
func _compare(befores: Array, afters: Array) -> void:
	var w := 0
	var h := 0
	for i in befores.size():
		if befores[i] == null:
			continue
		w += befores[i].get_width() * ZOOM + GAP
		h = maxi(h, befores[i].get_height() * ZOOM)
	var sheet := Image.create_empty(maxi(w, 1), h * 2 + GAP, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.09, 0.08, 0.07))
	var x := 0
	for i in befores.size():
		if befores[i] == null:
			continue
		for row in 2:
			var img: Image = (befores[i] if row == 0 else afters[i]).duplicate()
			img.resize(img.get_width() * ZOOM, img.get_height() * ZOOM, Image.INTERPOLATE_NEAREST)
			sheet.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()),
				Vector2i(x, row * (h + GAP) + h - img.get_height()))
		x += befores[i].get_width() * ZOOM + GAP
	sheet.save_png(ProjectSettings.globalize_path(SHEET))
	print("비교: %s  (위가 전, 아래가 후)" % SHEET)
