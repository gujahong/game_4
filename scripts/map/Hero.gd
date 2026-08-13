extends RefCounted
class_name Hero

## 주인공의 자리와 이동 규칙. **화면을 모른다** — 노드도 그림도 안 들고 있다.
##
## 대사(`DialogueController` / `DialogueUI`)와 전투(`Battle` / `BattleScreen`)가 쓰는 것과 같은
## 방식이다. 그림이 바뀌어도 이 파일은 안 바뀌고, 규칙이 바뀌어도 화면은 안 바뀐다.

const SPEED := 90.0

## **4방향만 쓴다**(회원님 결정, 2026-08-13). 대각선을 넣으면 방향별 그림이 여덟 장 필요해지고
## 걷기 애니메이션도 여덟 벌이 된다.
##
## 열쇠 이름은 PixelLab이 쓰는 방향 이름 그대로다. 받은 시트를 이름 바꾸지 않고 쓸 수 있다.
const DIRECTIONS := {
	"south": Vector2i(0, 1),
	"north": Vector2i(0, -1),
	"east": Vector2i(1, 0),
	"west": Vector2i(-1, 0),
}

var at: Vector2             ## 세상 좌표에서 서 있는 자리
var facing := "south"       ## 바라보는 쪽
var walking := false

var _bounds: Rect2


func _init(bounds: Rect2) -> void:
	_bounds = bounds
	at = bounds.get_center()


## 한 프레임 움직인다. `push`는 눌린 방향(-1~1)이고, 대각선은 여기서 하나로 줄어든다.
func step(push: Vector2, delta: float) -> void:
	var going := _one_way(push)
	walking = going != Vector2i.ZERO
	if not walking:
		return
	facing = _name_of(going)
	var next: Vector2 = at + Vector2(going) * SPEED * delta
	# 바닥 밖으로는 못 나간다. 벽 충돌을 따로 만들 것 없이 바닥 사각형에 가둔다.
	at = Vector2(
		clampf(next.x, _bounds.position.x, _bounds.end.x),
		clampf(next.y, _bounds.position.y, _bounds.end.y)
	)


## 대각선으로 눌러도 한 방향만 고른다. 가로를 먼저 본다 — 둘 다 눌렸을 때 어느 쪽으로 갈지
## 규칙이 정해져 있어야 몸이 떨지 않는다.
func _one_way(push: Vector2) -> Vector2i:
	if not is_zero_approx(push.x):
		return Vector2i(int(signf(push.x)), 0)
	if not is_zero_approx(push.y):
		return Vector2i(0, int(signf(push.y)))
	return Vector2i.ZERO


func _name_of(going: Vector2i) -> String:
	for key in DIRECTIONS:
		if DIRECTIONS[key] == going:
			return key
	return facing
