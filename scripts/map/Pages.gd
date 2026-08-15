extends Node2D
class_name Pages

## 서고에 흩날리는 종이. **이 방이 살아 있다는 것을 이것 하나가 말한다.**
##
## 회원님이 주신 참고 그림에서 서가만큼이나 눈에 남는 것이 **공중에 떠다니는 낱장들**이었다.
## 서가는 멎어 있고 종이만 움직인다 - 그래서 이 거대한 곳이 죽은 유적이 아니라 **아직
## 무언가가 벌어지는 곳**으로 읽힌다.
##
## ### 세계 안에 있다
##
## 필터 판(`FilterLayer`, layer 50)보다 **아래**에 둔다. 그래야 종이도 디더를 통과해 세계의
## 일부가 되고, **등불이 닿는 데서만 보인다.** 어둠 속에서 뭔가가 스쳐 지나가는 것이 보이는
## 편이, 방 전체에 종이가 흩날리는 것을 다 보여주는 것보다 낫다.
##
## ### 회전은 쓰지 않는다
##
## 종이가 팔랑이는 것은 각도로 돌려야 자연스럽지만, **픽셀아트를 각도로 돌리면 도트 격자가
## 깨진다**(이 게임의 오래된 규칙). 대신 **가로 폭을 줄였다 늘린다** - 낱장이 옆으로 돌아
## 얇아졌다 다시 펴지는 것으로 읽힌다. 도트는 하나도 안 깨진다.

## 몇 장이나. 방 전체에 흩어지므로 등불 안에 들어오는 것은 늘 한둘이다.
const COUNT := 46

## 떠다니는 빠르기(픽셀/초). 아주 느리다 - 빠르면 벌레가 된다.
const DRIFT_MIN := 5.0
const DRIFT_MAX := 17.0

## 한 장의 크기(픽셀). 32px 타일 위에서 이보다 크면 종이가 아니라 판자가 된다.
const PAGE_W := 4.0
const PAGE_H := 3.0

## 팔랑이는 주기(초). 장마다 조금씩 달라야 한꺼번에 같이 접히지 않는다.
const FLUTTER_MIN := 0.9
const FLUTTER_MAX := 2.6

## 종이 색. **색을 안 쓴다** - 어차피 등불빛을 받아야 보이는 것이라, 흰 것으로 두면 불빛
## 색이 저절로 얹힌다. 종이가 제 색을 가지면 등불과 따로 논다.
const PAPER := Color(0.86, 0.85, 0.82, 1.0)
const CREASE := Color(0.42, 0.41, 0.39, 1.0)

var _bounds: Rect2
var _at: PackedVector2Array = PackedVector2Array()
var _drift: PackedVector2Array = PackedVector2Array()
var _phase: PackedFloat32Array = PackedFloat32Array()
var _rate: PackedFloat32Array = PackedFloat32Array()


## 방이 정해진 뒤에 부른다. 종이는 방 어디에나 있다.
func setup(bounds: Rect2) -> void:
	_bounds = bounds
	_at.resize(COUNT)
	_drift.resize(COUNT)
	_phase.resize(COUNT)
	_rate.resize(COUNT)
	for i in COUNT:
		_at[i] = Vector2(
			randf_range(_bounds.position.x, _bounds.end.x),
			randf_range(_bounds.position.y, _bounds.end.y)
		)
		# 방향이 제각각이라야 바람이 아니라 **떠 있는 것**으로 보인다. 한쪽으로 몰면
		# 눈보라가 된다.
		var angle: float = randf_range(0.0, TAU)
		_drift[i] = Vector2(cos(angle), sin(angle)) * randf_range(DRIFT_MIN, DRIFT_MAX)
		_phase[i] = randf_range(0.0, TAU)
		_rate[i] = TAU / randf_range(FLUTTER_MIN, FLUTTER_MAX)
	queue_redraw()


func _process(delta: float) -> void:
	if _at.is_empty():
		return
	for i in COUNT:
		_phase[i] += _rate[i] * delta
		var moved: Vector2 = _at[i] + _drift[i] * delta
		# 방 밖으로 나가면 반대편에서 들어온다. 끝이 없는 곳이라 어디로 가든 또 있다.
		if moved.x < _bounds.position.x:
			moved.x = _bounds.end.x
		elif moved.x > _bounds.end.x:
			moved.x = _bounds.position.x
		if moved.y < _bounds.position.y:
			moved.y = _bounds.end.y
		elif moved.y > _bounds.end.y:
			moved.y = _bounds.position.y
		_at[i] = moved
	queue_redraw()


func _draw() -> void:
	for i in _at.size():
		# **정수 픽셀에 놓는다.** 소수점 자리에 그리면 2배로 확대된 화면에서 가장자리가
		# 흐려져 도트가 아니게 된다.
		var at: Vector2 = _at[i].round()

		# 옆으로 돌면서 얇아진다. 0이 되지는 않게 남겨둔다 - 완전히 사라졌다 나타나면
		# 깜빡이는 점이 된다.
		var turn: float = absf(sin(_phase[i]))
		var w: float = maxf(roundf(PAGE_W * (0.25 + 0.75 * turn)), 1.0)

		draw_rect(Rect2(at, Vector2(w, PAGE_H)), PAPER)
		# 접힌 자리 한 줄. 이게 있어야 흰 점이 아니라 **낱장**으로 보인다.
		draw_rect(Rect2(at + Vector2(0.0, PAGE_H - 1.0), Vector2(w, 1.0)), CREASE)
