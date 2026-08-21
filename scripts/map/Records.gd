extends Node2D
class_name Records

## **읽을 수 있는 서가.** 서고의 핵심 장치다.
##
## 지금까지 자리(`TilesetRoom.RECORDS`)와 판정(`record_at()`)과 문을 여는 함수(`open_way()`)는
## 있었는데 **아무도 안 불렀다.** 서가가 그려지지도 않았고 읽을 수도 없어서, 북쪽 길이 영영
## 안 열렸다 - 그것에게 갈 방법이 없었다. 그 구멍을 메운다.
##
## ### 서가는 장식 책장보다 크다 (회원님, 2026-08-19)
##
## `Clutter`의 책장은 벽을 채우는 가구고, 이것은 **읽어야 하는 물건**이다. 크기가 같으면
## 어느 것이 중요한지 구별이 안 된다. 그래서 **책장 그림 셋을 나란히 붙여 한 덩어리**로
## 세운다 - 그림을 늘리지 않으므로 도트가 안 깨진다(그림 규칙).
##
## ### 읽으면 대사창이 뜬다
##
## 대사 시스템(`Dialogue` 오토로드 + `DialogueUI`)을 그대로 쓴다. 쯔꾸르식 글 박스가
## 화면 아래에 뜨고 한 글자씩 찍힌다 - 이 게임에 이미 있는 것이라 새로 만들 이유가 없다.

signal read(index: int)      ## 서가 하나를 다 읽었다
signal all_read()            ## 넷을 다 읽었다 - 북쪽 길이 열린다

const SHELF_ART := "res://assets/tilesets/bookshelf.png"
## 한 서가를 이룰 책장 수와 간격(픽셀). 그림이 38px 폭이라 38이면 딱 붙는다.
const WIDE := 3
const STEP := 37

## ### 알림은 필터 위에 띄운다 (회원님, 2026-08-19: "읽는다 이것도 잘 안 보여")
##
## 처음엔 서가 옆에 그냥 붙였는데 **안 보였다.** 이 게임은 화면을 덮는 판이 둘이다 —
## 디더 필터(layer 50)와 등불이 뚫는 어둠. 세상(`World`) 안에 있는 것은 그 아래에 그려져서
## **격자로 흩어지고 어둠에 먹힌다.**
##
## 그래서 알림만 **등불과 같은 층**(layer 60 위)에 올린다. 세상 좌표를 화면 좌표로 옮겨
## 서가를 따라다니게 하면 된다 - 이 게임은 카메라가 주인공을 따라다니므로 계산이 간단하다.
const HINT_LAYER := 70
## 카메라 배율(`Room.tscn`의 Camera2D). 세상 거리를 화면 거리로 옮길 때 곱한다.
const ZOOM := 2.0

## 다가가면 뜨는 알림. 서가 위에 뜬다.
const HINT_ABOVE := 46.0
const HINT_TEXT := "읽는다"
## 알림이 뜨고 지는 데 걸리는 시간.
const HINT_FADE := 0.18
## 다 읽은 서가에 남는 표시. **다시 읽을 수 있다는 것을 알린다.**
const DONE_TEXT := "다시 읽는다"

## 몸이 막히는 반지름(픽셀). 서가는 벽에 붙은 큰 가구라 넓게 막는다.
const BLOCK := 52.0


class Shelf:
	var at: Vector2
	var done := false
	var hint: Label


var _hints: CanvasLayer
var _shelves: Array[Shelf] = []
var _near := -1        ## 지금 앞에 선 서가. 없으면 -1
var _reading := -1     ## 지금 읽는 중인 서가
## ### 닫히자마자 다시 열리는 것을 막는다
##
## 읽기와 대사 넘기기가 **같은 키**(스페이스)다. 그래서 마지막 줄을 넘기려고 누른 것이
## 곧바로 "다시 펼치기"로 먹혀서 *"이미 읽은 장이다"*가 계속 떴다(회원님, 2026-08-19).
##
## **다시 읽는 것은 막지 않는다** - 그 자리에 선 채로 한 번 더 펼 수 있어야 한다.
## 막는 것은 **닫힌 직후 한 박자**뿐이다. 키에서 손을 떼고 다시 누를 시간이면 된다.
const AFTER_CLOSE := 0.35
var _cool := 0.0
var _room: TilesetRoom


func setup(room: TilesetRoom) -> void:
	_room = room
	# 알림을 얹을 층. **필터와 어둠 위**라 격자에도 안 먹히고 어둠에도 안 묻힌다.
	_hints = CanvasLayer.new()
	_hints.layer = HINT_LAYER
	add_child(_hints)

	var art: Texture2D = load(SHELF_ART)
	var spots := room.record_spots_px()
	for i in spots.size():
		var shelf := Shelf.new()
		shelf.at = spots[i].round()
		# 책장 셋을 나란히. 가운데가 spot에 오게 왼쪽부터 편다.
		for k in WIDE:
			var piece := Sprite2D.new()
			piece.texture = art
			piece.flip_h = k == 2
			piece.position = shelf.at + Vector2(float(k - 1) * STEP, 0.0)
			add_child(piece)
		shelf.hint = _make_hint()
		_hints.add_child(shelf.hint)
		_shelves.append(shelf)

	# 대사가 끝나면 읽은 것으로 친다. **끝나는 것을 여기서 듣는다** - 대사 시스템은
	# 서가가 있는 줄도 모른다.
	if not Dialogue.scene_finished.is_connected(_on_finished):
		Dialogue.scene_finished.connect(_on_finished)


## 이 자리가 서가에 막히는가. `Walker`가 걷기 판정에 곱해서 쓴다.
func blocks(at: Vector2) -> bool:
	for shelf in _shelves:
		if at.distance_to(shelf.at) < BLOCK:
			return true
	return false


## 대사를 읽는 중인가. 그동안은 못 걷는다.
func busy() -> bool:
	return _reading >= 0


## 주인공이 걸을 때마다 불린다. 곁에 서면 알림을 띄우고, 누르면 읽는다.
func poll(at: Vector2) -> void:
	_follow(at)
	if busy():
		return

	_cool = maxf(_cool - get_process_delta_time(), 0.0)

	var found: int = _room.record_at(at)
	if found != _near:
		_near = found
		_refresh_hints()

	if _near >= 0 and _cool <= 0.0 and Input.is_action_just_pressed("ui_accept"):
		_open(_near)


func done_count() -> int:
	var n := 0
	for shelf in _shelves:
		if shelf.done:
			n += 1
	return n


## 서가 하나를 펼친다.
func _open(index: int) -> void:
	if index < 0 or index >= _shelves.size():
		return
	_reading = index
	_refresh_hints()
	Sfx.play(self, Sfx.PICK, -12.0)
	Dialogue.play_scene(RecordText.scene_for(index, _shelves[index].done))


func _on_finished() -> void:
	if _reading < 0:
		return
	var index: int = _reading
	_reading = -1
	_cool = AFTER_CLOSE
	if not _shelves[index].done:
		_shelves[index].done = true
		read.emit(index)
		# **다 읽으면 길이 열린다.** 기록이 장식이 아니라 관문이 되는 자리다.
		if done_count() >= _shelves.size():
			all_read.emit()
	_refresh_hints()


func _refresh_hints() -> void:
	for i in _shelves.size():
		var shelf: Shelf = _shelves[i]
		shelf.hint.text = DONE_TEXT if shelf.done else HINT_TEXT
		# **다 읽은 서가는 흐리게.** 아직 안 읽은 것만 또렷해야 어디로 갈지 보인다.
		shelf.hint.add_theme_color_override(
			"font_color", UiStyle.TEXT_DIM if shelf.done else UiStyle.LAMP)
		var show: bool = i == _near and not busy()
		var fade := create_tween()
		fade.tween_property(shelf.hint, "modulate:a",
			(0.55 if shelf.done else 1.0) if show else 0.0, HINT_FADE)


## 알림이 서가를 따라다니게 한다.
##
## **카메라가 주인공을 따라다니므로 주인공은 늘 화면 한가운데다.** 그래서 화면 좌표는
## `서가 자리 - 주인공 자리 + 화면 절반`이면 된다. 카메라 zoom이 2라 세상 거리에 2를 곱한다.
func _follow(hero_at: Vector2) -> void:
	var half: Vector2 = Vector2(get_viewport().get_visible_rect().size) * 0.5
	for shelf in _shelves:
		var above: Vector2 = shelf.at + Vector2(0.0, -HINT_ABOVE)
		var on_screen: Vector2 = (above - hero_at) * ZOOM + half
		# **글자 폭의 절반만큼 왼쪽으로.** 그래야 서가 축과 가운데가 맞는다.
		shelf.hint.position = (on_screen - Vector2(shelf.hint.size.x * 0.5, 0.0)).round()


## 서가 위에 뜨는 알림. **크고 테두리가 굵어야 어두운 화면에서 읽힌다.**
func _make_hint() -> Label:
	var hint := Label.new()
	# 픽셀 글꼴은 네이티브(16)의 정수배로만. 32면 화면에서 또렷하다.
	KoreanFont.apply(hint, KoreanFont.NATIVE_SIZE * 2)
	hint.add_theme_color_override("font_color", UiStyle.LAMP)
	hint.add_theme_color_override("font_outline_color", Color(0.03, 0.02, 0.02))
	# 테두리를 두껍게. 배경이 책장이라 얇으면 글자가 묻힌다.
	hint.add_theme_constant_override("outline_size", 8)
	hint.modulate.a = 0.0
	return hint
