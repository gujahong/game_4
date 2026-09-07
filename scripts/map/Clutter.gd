extends Node2D
class_name Clutter

## 서고를 채우는 **장식과 주울 것**(회원님, 2026-08-18: "필드가 횅하다").
##
## - **부서진 땅** — 통로 위의 금과 이 빠진 자리. 코드로 그린다
## - **가짜 더미** — 안 일어나는 종이 더미. 적(`Sleepers`)과 같은 그림이라 **어느 것이
##   살아 있는지 더 모르게 된다.** 이 방의 공포("지나가려던 쓰레기가 일어선다")가
##   더미가 넷뿐이면 성립하지 않는다 - 널려 있어야 헷갈린다
## - **기름병** — 주우면 전투에서 부을 병이 는다(`Lantern.carried`). 유일하게 규칙에 닿는 것
## - **떠다니는 책** — 심연 가장자리를 느리게 오르내린다
##
## **이동 판정의 원천은 여전히 `TilesetRoom._walkable()` 하나다.** 종이 더미는 몸을
## 막지만(`blocks()`), 그 판정을 여기서 직접 하지 않고 `Walker`가 방의 판정에 곱해서 쓴다.

const PILE := "res://assets/enemies/paper_pile.png"

## 자리는 전부 **한가운데에서 몇 칸 떨어졌는가**(칸 좌표)다. 화면 좌표라 아래가 +y다.
## 홀은 반너비 4.5칸, 날개 복도는 반너비 1.6칸으로 8칸까지, 끝방은 8~14칸에 반너비 3칸이다
## (`TilesetRoom`). 서가·적이 앉은 자리와 겹치지 않게 골랐다.
## **일곱에서 넷으로 줄였다**(회원님, 2026-08-18: "바닥에 있는 책들 너무 많아").
## 진짜 적(`Sleepers`)이 넷이라 가짜도 넷이면 반반이고, 그 정도면 헷갈린다.
const PILES := [
	Vector2(-1.2, 9.2),                        # 남쪽 복도
	Vector2(-4.0, 2.5),                        # 홀
	Vector2(9.2, -1.2),                        # 동쪽 복도
	Vector2(-11.5, 2.8),                       # 서쪽 열람실
]
const BOTTLES := [Vector2(-15.7, 2.0), Vector2(15.7, 2.0), Vector2(0.0, -4.2)]

## **장식 책장은 없앴다**(회원님, 2026-08-24).
##
## 벽을 따라 여섯 개를 세워 뒀었는데, **읽는 서가와 같은 그림**이라 어느 것이 읽히는
## 것인지 흐렸다. 전에는 읽는 쪽을 셋씩 붙여 크기로 갈랐는데, 그것도 벽지처럼 보여서
## 하나로 줄였다(`Records`) - 그러면 크기로도 못 가른다.
##
## **그래서 장식 쪽을 없앤다.** 책장이 서 있으면 전부 읽는 것이다. 규칙이 하나가 된다.

## 떠다니는 책 몇 권. **이 세계의 기록은 원래 떠다니기도 한다.**
## 전에 심연 위에 띄워 뒀던 책장은 없앴다(회원님: "책장이 대각선으로 있잖아") -
## 벽도 아니고 가구도 아닌 것이 비스듬히 걸려 있었다.
const BOOKS := [
	Vector2(-7.8, -8.2), Vector2(8.2, 7.8), Vector2(-15.7, 8.2),
]
## 통로 위. 길 한가운데를 조금씩 비켜 둔다.
const CRACKS := [
	Vector2(-1.1, 7.0), Vector2(-3.1, -2.5), Vector2(2.8, 3.2),
	Vector2(-10.8, -1.2), Vector2(10.8, 1.5), Vector2(-14.0, 0.8),
]

## 기름병을 줍는 거리(픽셀). 등불 반경 안에서 보고 다가가면 닿는 크기다.
const PICK_REACH := 26.0

## 더미가 몸을 막는 반지름(픽셀). **밟고 지나가지 못한다**(회원님) - 종이라도 무릎까지
## 쌓인 무더기다. 이동 판정 자체는 여전히 방이 정하고, Walker가 그 판정에 이것을 곱한다.
const PILE_BLOCK := 14.0

## 떠다니는 책의 숨. 느려야 떠 있는 것이지, 빠르면 튀는 것이다.
const BOB_PIXELS := 3.0
const BOB_SPEED := 0.8

## **벽은 없앴다**(회원님, 2026-08-24: "그냥 벽 아예 없애자").
##
## 사면에 세워도 봤는데, 바깥이 심연이라 배경이 거의 검정이라서 **벽면이 배경에 녹아**
## 밝은 꼭대기 줄만 남았다 - 벽이 아니라 테두리 선으로 보였다. 밝기를 올리면 이번에는
## 심연 위에 떠 있다는 그림이 죽는다.
##
## **그래서 안 그린다.** 바닥이 끝나면 그냥 끝난다 - 심연 위에 놓인 판이다.
## 되살릴 일이 생기면 git에서 꺼내면 된다(2026-08-24 커밋).

var _blocks: Array = []   ## [자리, 막는 반지름] 짝. 종이 더미가 쌓는다
var _bottle_spots: Array[Vector2] = []
var _bottles: Array[Sprite2D] = []
var _book_spots: Array[Vector2] = []
var _crack_spots: Array[Vector2] = []
var _time := 0.0


func setup(room: TilesetRoom) -> void:
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


## 이 자리가 종이 더미에 막히는가. Walker가 걷기 판정에 곱해서 쓴다.
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


func _draw() -> void:
	for i in _crack_spots.size():
		_crack(_crack_spots[i], i)
	for i in _book_spots.size():
		_book(_book_spots[i], i)


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
