extends Node2D
class_name Clutter

## 서고를 채우는 **벽과 장식과 주울 것**(회원님, 2026-08-18: "필드가 횅하다").
##
## - **벽** — 바닥이 끝나는 자리에 세운다. 코드로 그리고 방 판정을 읽어서 자리를 정한다
## - **가짜 더미** — 안 일어나는 종이 더미. 적(`Sleepers`)과 같은 그림이라 **어느 것이
##   살아 있는지 더 모르게 된다.** 이 방의 공포("지나가려던 쓰레기가 일어선다")가
##   더미가 넷뿐이면 성립하지 않는다 - 널려 있어야 헷갈린다
## - **기름병** — 주우면 전투에서 부을 병이 는다(`Lantern.carried`). 유일하게 규칙에 닿는 것
## - **책장** — 벽을 따라 선다(뽑은 그림). 심연에 띄웠던 것은 없앴다
## - **떠다니는 책** — 심연 가장자리를 느리게 오르내린다
## - **부서진 땅** — 통로 위의 금과 이 빠진 자리
##
## **이동 판정의 원천은 여전히 `TilesetRoom._walkable()` 하나다.** 더미와 선 책장은 몸을
## 막지만(`blocks()`), 그 판정을 여기서 직접 하지 않고 `Walker`가 방의 판정에 곱해서 쓴다.

const PILE := "res://assets/enemies/paper_pile.png"

## ### 책장 뽑기에서 알아낸 것 (2026-08-18)
##
## PixelLab로 여러 번 뽑으며 투시가 계속 어긋났다. 주인공(`pilgrim/south.png`)을 옆에
## 놓고 재보면 이유가 분명하다.
##
## ```
## 주인공     정면만 보인다.  모서리 평행
## 종이 더미  납작해서 윗면.  모서리 평행
## 어긋난 것  정면 + 옆면.    모서리가 수렴  ← 혼자 3점투시
## ```
##
## **높은 물건이 문제다.** 납작한 것(종이 더미)은 어느 각도로 뽑아도 바닥에 눕지만, 높은
## 것은 `view`를 조금만 틀어도 옆면과 소실점이 생긴다. `side`는 윗면이 아예 없고
## `high top-down`은 옆면까지 다 보인다 - **그 사이가 `low top-down`이다.**
const SHELF_ART := "res://assets/tilesets/bookshelf.png"

## 자리는 전부 **한가운데에서 몇 칸 떨어졌는가**(칸 좌표)다. 화면 좌표라 아래가 +y다.
## 홀은 반너비 4.5칸, 날개 복도는 반너비 1.6칸으로 8칸까지, 끝방은 8~14칸에 반너비 3칸이다
## (`TilesetRoom`). 서가·적이 앉은 자리와 겹치지 않게 골랐다.
## **일곱에서 넷으로 줄였다**(회원님, 2026-08-18: "바닥에 있는 책들 너무 많아").
## 진짜 적(`Sleepers`)이 넷이라 가짜도 넷이면 반반이고, 그 정도면 헷갈린다.
const PILES := [
	Vector2(-1.0, 7.4),                        # 남쪽 복도
	Vector2(-3.2, 2.0),                        # 홀
	Vector2(7.4, -1.0),                        # 동쪽 복도
	Vector2(-9.2, 2.2),                        # 서쪽 열람실
]
const BOTTLES := [Vector2(-12.6, 1.6), Vector2(12.6, 1.6), Vector2(0.0, -3.4)]

## 뽑은 책장(정면 그림)을 **벽을 따라 세운다.** 이 게임은 3/4 시점이라 가구가 전부 같은
## 방향을 봐야 하는데, 축이 직각인 구조라 벽에 붙이면 그대로 맞는다.
## **북쪽 문(±1.6칸) 앞은 비운다** - 막으면 그것에게 못 간다.
const FLOOR_SHELVES := [
	Vector2(-3.9, -4.0), Vector2(-2.7, -4.0),   # 홀 북벽 - 문 왼쪽
	Vector2(2.7, -4.0), Vector2(3.9, -4.0),     # 홀 북벽 - 문 오른쪽
	Vector2(-3.9, 4.0), Vector2(3.9, 4.0),      # 홀 남벽 구석
	Vector2(-11.6, -2.4), Vector2(-10.4, -2.4), # 서쪽 열람실 안쪽 벽
	Vector2(11.6, -2.4), Vector2(10.4, -2.4),   # 동쪽 열람실 안쪽 벽
]

## **떠 있던 책장은 없앴다**(회원님: "책장이 대각선으로 있잖아"). 심연 위 대각선에 띄워
## 놨더니 벽도 아니고 가구도 아닌 것이 비스듬히 걸려 있었다 - 책장은 벽을 따라 선다.
## 떠다니는 책만 몇 권 남긴다. 이 세계의 기록은 원래 떠다니기도 한다.
const BOOKS := [
	Vector2(-6.2, -6.6), Vector2(6.6, 6.2), Vector2(-12.6, 6.6),
]
## 통로 위. 길 한가운데를 조금씩 비켜 둔다.
const CRACKS := [
	Vector2(-0.9, 5.6), Vector2(-2.5, -2.0), Vector2(2.2, 2.6),
	Vector2(-8.6, -1.0), Vector2(8.6, 1.2), Vector2(-11.2, 0.6),
]

## 기름병을 줍는 거리(픽셀). 등불 반경 안에서 보고 다가가면 닿는 크기다.
const PICK_REACH := 26.0

## 몸이 막히는 반지름(픽셀). **밟고 지나가지 못한다**(회원님) - 종이라도 무릎까지
## 쌓인 무더기다. 이동 판정 자체는 여전히 방이 정하고, Walker가 그 판정에 이것을 곱한다.
const PILE_BLOCK := 14.0
const SHELF_BLOCK := 17.0

## 떠다니는 책의 숨. 느려야 떠 있는 것이지, 빠르면 튀는 것이다.
const BOB_PIXELS := 3.0
const BOB_SPEED := 0.8

## ### 벽 (회원님, 2026-08-18: "벽이 있어야 할 것 같은데")
##
## **바닥이 끝나고 심연이 시작되는 자리에 세운다.** 이 게임은 3/4 시점이라 북쪽으로 난
## 모서리에서만 벽의 **얼굴**이 보인다 - 거기에 벽면을 그리면 심연 위에 뜬 판이 아니라
## 방 안이 된다.
##
## **벽의 모양을 따로 적지 않는다.** 어느 칸이 바닥인지는 `TilesetRoom._walkable()` 하나가
## 정하고, 여기서는 그 판정을 읽어서 "바닥인데 북쪽이 심연인 칸"만 골라 세운다 -
## 방 구조를 고치면 벽이 저절로 따라온다.
const WALL_HIGH := 20.0
const WALL_CAP := 5.0                       ## 벽 꼭대기의 밝은 띠(윗면)
const WALL_TOP := Color(0.26, 0.20, 0.13)   ## 빛을 받는 윗면
const WALL_FACE := Color(0.15, 0.11, 0.07)  ## 그늘진 벽면
const WALL_FOOT := Color(0.07, 0.05, 0.03)  ## 바닥과 만나는 자리의 그림자

var _blocks: Array = []   ## [자리, 막는 반지름] 짝. 더미와 통로 책장이 쌓는다
var _bottle_spots: Array[Vector2] = []
var _bottles: Array[Sprite2D] = []
var _book_spots: Array[Vector2] = []
var _crack_spots: Array[Vector2] = []
var _wall_cells: Array[Vector2] = []   ## 벽을 세울 칸의 왼쪽 위 모서리(세상 좌표)
var _tile := 32.0
var _time := 0.0


func setup(room: TilesetRoom) -> void:
	_gather_walls(room)

	# 가짜 더미. 반씩 뒤집고 조금씩 어둡혀서 **같은 그림이 같은 물건으로 안 보이게** 한다.
	var pile: Texture2D = load(PILE)
	for i in PILES.size():
		var lying := Sprite2D.new()
		lying.texture = pile
		lying.position = room.spot_px(PILES[i]).round()
		lying.flip_h = i % 2 == 1
		var shade: float = 0.86 + 0.14 * float(i % 3) * 0.5
		lying.modulate = Color(shade, shade, shade)
		add_child(lying)
		_blocks.append([lying.position, PILE_BLOCK])

	# 벽을 따라 선 책장. 반씩 뒤집어서 같은 그림이 늘어서 벽지가 되는 것을 피한다.
	var shelf_art: Texture2D = load(SHELF_ART)
	for i in FLOOR_SHELVES.size():
		var standing := Sprite2D.new()
		standing.texture = shelf_art
		standing.flip_h = i % 2 == 1
		standing.position = room.spot_px(FLOOR_SHELVES[i]).round()
		add_child(standing)
		_blocks.append([standing.position, SHELF_BLOCK])

	for spot in BOTTLES:
		var bottle := Sprite2D.new()
		bottle.texture = _bottle_art()
		bottle.position = room.spot_px(spot).round()
		add_child(bottle)
		_bottles.append(bottle)
		_bottle_spots.append(bottle.position)

	for spot in BOOKS:
		_book_spots.append(room.spot_px(spot).round())
	for spot in CRACKS:
		_crack_spots.append(room.spot_px(spot).round())
	queue_redraw()


func _process(delta: float) -> void:
	if _book_spots.is_empty():
		return
	_time += delta
	queue_redraw()


## 이 자리가 더미나 책장에 막히는가. Walker가 걷기 판정에 곱해서 쓴다.
func blocks(at: Vector2) -> bool:
	for pair in _blocks:
		if at.distance_to(pair[0]) < pair[1]:
			return true
	return false


## 주인공이 걸을 때마다 불린다. 기름병 곁을 지나면 줍는다.
func poll(at: Vector2) -> void:
	for i in _bottles.size():
		if _bottles[i] == null or not _bottles[i].visible:
			continue
		if at.distance_to(_bottle_spots[i]) < PICK_REACH:
			_bottles[i].visible = false
			Lantern.carried += 1
			Sfx.play(self, Sfx.PICK, -10.0)


## 바닥인데 **북쪽이 심연인** 칸을 모은다. 거기가 벽의 얼굴이 보이는 자리다.
func _gather_walls(room: TilesetRoom) -> void:
	_tile = float(room.tile_px())
	for r in TilesetRoom.ROWS:
		for c in TilesetRoom.COLS:
			if not room.is_floor(Vector2i(c, r)):
				continue
			if room.is_floor(Vector2i(c, r - 1)):
				continue
			_wall_cells.append(Vector2(float(c), float(r)) * _tile)


func _draw() -> void:
	# 벽이 제일 먼저다 - 바닥 위의 것들이 벽 앞에 와야 방 안에 선 것으로 보인다.
	for at in _wall_cells:
		_wall(at)
	for i in _crack_spots.size():
		_crack(_crack_spots[i], i)
	for i in _book_spots.size():
		_book(_book_spots[i], i)


## 벽 한 칸. 바닥 칸의 **위쪽으로** 솟는다 - 윗면·얼굴·발치 그림자 세 띠다.
## 세 띠라야 판때기가 아니라 두께가 있는 벽으로 읽힌다.
func _wall(at: Vector2) -> void:
	var top: float = at.y - WALL_HIGH
	draw_rect(Rect2(Vector2(at.x, top), Vector2(_tile, WALL_CAP)), WALL_TOP)
	draw_rect(Rect2(Vector2(at.x, top + WALL_CAP),
		Vector2(_tile, WALL_HIGH - WALL_CAP)), WALL_FACE)
	# 벽과 바닥이 만나는 한 줄. 이게 있어야 벽이 바닥에 서 있는 것이 된다.
	draw_rect(Rect2(Vector2(at.x, at.y - 2.0), Vector2(_tile, 2.0)), WALL_FOOT)


## 통로 위의 금. 어두운 점 몇 개가 지그재그로 이어진 것 - 가까이서만 보이면 된다.
func _crack(at: Vector2, seed_i: int) -> void:
	var ink := Color(0.05, 0.04, 0.03)
	var step := Vector2(3.0, 1.0) if seed_i % 2 == 0 else Vector2(1.0, 3.0)
	var wobble: float = 1.0 if seed_i % 3 == 0 else -1.0
	var spot: Vector2 = at
	for k in 5:
		draw_rect(Rect2(spot.round(), Vector2(2.0, 2.0)), ink)
		spot += step + Vector2(wobble * float(k % 2), -wobble * float((k + 1) % 2)) * 2.0
	# 이 빠진 자리 하나. 금 끝에 뚫린 구멍이라야 부서진 땅이 된다.
	draw_rect(Rect2((at + step * 2.0).round(), Vector2(4.0, 3.0)), Color(0.02, 0.02, 0.02))




## 심연 가장자리를 떠도는 책 한 권. 위아래로 느리게 숨 쉰다.
func _book(at: Vector2, seed_i: int) -> void:
	var cover := Color(0.28, 0.20, 0.13) if seed_i % 2 == 0 else Color(0.20, 0.22, 0.17)
	var pages := Color(0.52, 0.48, 0.40)
	var lift: float = roundf(sin(_time * BOB_SPEED + float(seed_i) * 1.7) * BOB_PIXELS)
	var spot: Vector2 = at + Vector2(0.0, lift)
	# **정수 픽셀에 놓는다** - 소수점 자리는 도트를 죽인다.
	spot = spot.round()
	draw_rect(Rect2(spot, Vector2(11.0, 8.0)), cover)
	draw_rect(Rect2(spot + Vector2(9.0, 1.0), Vector2(2.0, 6.0)), pages)


## 기름병 그림. 코드로 찍는다(ANIMATION.md §4) - 10x14, 유리에 기름이 2/3쯤 담긴 병.
func _bottle_art() -> ImageTexture:
	var glass := Color(0.42, 0.46, 0.44)
	var dark := Color(0.10, 0.12, 0.11)
	var oil := Color(0.76, 0.53, 0.20)
	var cork := Color(0.38, 0.28, 0.16)
	var image := Image.create_empty(10, 14, false, Image.FORMAT_RGBA8)
	# 마개와 목.
	image.fill_rect(Rect2i(3, 0, 4, 2), cork)
	image.fill_rect(Rect2i(3, 2, 4, 3), glass)
	image.fill_rect(Rect2i(4, 3, 2, 2), dark)
	# 몸통. 테두리가 유리, 속은 어둡고, 아래 2/3에 기름.
	image.fill_rect(Rect2i(1, 5, 8, 9), glass)
	image.fill_rect(Rect2i(2, 6, 6, 7), dark)
	image.fill_rect(Rect2i(2, 8, 6, 5), oil)
	# 빛 받는 세로줄 하나. 이게 있어야 유리로 읽힌다.
	image.fill_rect(Rect2i(2, 6, 1, 6), Color(0.62, 0.66, 0.62))
	return ImageTexture.create_from_image(image)
