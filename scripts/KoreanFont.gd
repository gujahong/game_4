extends RefCounted
class_name KoreanFont

## 화면에 쓰는 글꼴. Godot 기본 폰트에는 한글 글리프가 없어서 라벨이 통째로 비어 보인다.
##
## **픽셀 폰트는 정해진 크기(또는 그 정수배)로만 써야 한다.** 12px짜리를 14로 쓰면 도트 격자가
## 어긋나서 안 쓰느니만 못하다. 그래서 크기를 부르는 쪽에서 정하지 않고 여기 NATIVE_SIZE로 묶어둔다 -
## 폰트를 갈아끼우면 크기도 같이 따라온다.
##
## 도트가 안 뭉개지려면 안티앨리어싱/힌팅/서브픽셀이 꺼져 있어야 한다. project.godot의 [gui]
## 항목은 **기본 폰트에만** 걸리므로, 임포트한 폰트는 각자의 `.ttf.import`에서 따로 꺼야 한다.
##
## [2026-08-11] 갈무리에는 `Galmuri11Bitmap.ttf` 같은 **비트맵판**도 있는데 쓰지 않는다. 내장
## 비트맵이 특정 한 크기(11Bitmap은 16px, 9Bitmap은 12px)에만 들어 있어서, 그 크기가 아니면
## 글리프 높이가 0이 되어 **글자가 통째로 안 그려진다.** 파일은 1/7로 작지만 함정이 크다.
## 외곽선판은 어느 크기에서도 정상이고, 네이티브 크기에서 도트가 딱 떨어진다.

const FONT_PATH := "res://assets/fonts/NeoDunggeunmo.ttf"
const NATIVE_SIZE := 16

## 폰트 파일을 못 찾았을 때만 쓰는 비상용. 한글은 나오지만 안티앨리어싱된 벡터 폰트라
## 도트 배경 위에서 글자만 매끄럽게 겉돈다.
const SYSTEM_FALLBACK := "C:/Windows/Fonts/malgun.ttf"

static var _cached: Font = null
static var _tried := false


static func get_font() -> Font:
	if _tried:
		return _cached
	_tried = true
	if ResourceLoader.exists(FONT_PATH):
		_cached = load(FONT_PATH)
		return _cached
	if FileAccess.file_exists(SYSTEM_FALLBACK):
		push_warning("픽셀 폰트를 못 찾아 시스템 폰트로 대체한다: %s" % FONT_PATH)
		var font := FontFile.new()
		font.load_dynamic_font(SYSTEM_FALLBACK)
		_cached = font
		return _cached
	push_warning("쓸 수 있는 한글 폰트가 없다 - 글자가 안 보일 것이다")
	return null


## 라벨/버튼 등에 폰트와 크기를 한 번에 씌운다. 크기를 안 주면 그 폰트의 네이티브 크기를 쓴다.
## RichTextLabel만 테마 항목 이름이 다르다("normal_font") - 여기서 흡수한다.
static func apply(control: Control, size: int = NATIVE_SIZE) -> void:
	var font := get_font()
	var key := "normal_font" if control is RichTextLabel else "font"
	control.add_theme_font_size_override(key + "_size", size)
	if font != null:
		control.add_theme_font_override(key, font)
