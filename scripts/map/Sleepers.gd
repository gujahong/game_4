extends Node2D
class_name Sleepers

## 서고 바닥에 누워 있는 **종이로 된 것들.** 다가가면 일어선다.
##
## ### 왜 이게 무서운가
##
## 서고에는 원래 종이가 사방에 흩날린다(`Pages`). 그래서 **어느 더미가 살아 있는지 구별이
## 안 간다** - 지나가려던 쓰레기가 일어서는 것이 이 적의 정체다.
##
## 그리고 등불 반경이 좁아서 **밟기 직전에야 보인다.** 밝히면 미리 보이고, 아끼면 모르고
## 지나가다 밟는다.
##
## ### 부스럭거림이 먼저 온다 (아직 계획이다)
##
## 반응 거리(`SLEEPER_REACH`, 1.1칸)는 등불 반경보다 작다. **보고 나서 피할 수 있어야** 하기
## 때문이다 - 다가가면 먼저 부스럭거리고, 거기서 물러나면 안 깨우는 것이 목표인데,
## **지금은 닿는 순간 바로 깬다.** 부스럭 소리와 물러날 틈은 아직 안 만들었다.
##
## 일어서는 것은 화면에 안 그린다. 부스럭거리다 **바로 암전**으로 넘어가고, 눈을 뜨면 전투
## 화면에 그것이 서 있다. 안 보여주는 쪽이 무섭기도 하고, 64px로 일어서는 그림을 그려봐야
## 어차피 잘 안 읽힌다.

const PILE := "res://assets/enemies/paper_pile.png"

## 일어서는 프레임들. 납작한 더미가 한 층씩 쌓여 올라가 탑이 된다.
##
## **끝 프레임을 못 박아야 나온다**(2026-08-15). 안 주고 "일어서라"고만 하면 제자리에서
## 부스럭거리기만 한다 - 시작 자세와 목표가 멀면 모델이 안전한 쪽으로 도망간다.
## 도착점(`paper_stood.png`)을 주니 거기까지 갔다.
const RISE_DIR := "res://assets/enemies/paper_rise"
const RISE_FRAMES := 9
const RISE_FPS := 11.0

## 일어선 뒤 암전까지의 뜸. 다 서고 나서 한 박자 있어야 "아, 저게 살아 있었구나"가 읽힌다.
const HOLD_AFTER := 0.25

signal woke(index: int)

var _room: TilesetRoom
var _sprites: Array[Sprite2D] = []
var _rise: Array[Texture2D] = []
var _awake := -1        ## 지금 일어서는 중인 것. -1이면 없다
var _rise_time := 0.0


func setup(room: TilesetRoom) -> void:
	_room = room
	var pile: Texture2D = load(PILE)
	for i in RISE_FRAMES:
		var path := "%s/%d.png" % [RISE_DIR, i]
		if ResourceLoader.exists(path):
			_rise.append(load(path))

	for at in room.sleeper_spots_px():
		var sprite := Sprite2D.new()
		sprite.texture = pile
		sprite.position = at.round()
		add_child(sprite)
		_sprites.append(sprite)


## 주인공이 여기 왔다. 가까우면 깨운다.
##
## **한 번 시작하면 못 멈춘다.** 일어서는 도중에 물러나도 소용없다 - 피하려면 부스럭거리기
## 전에, 즉 반응 거리 밖에서 알아채야 한다. 그게 등불을 밝히는 값어치다.
func check(hero_at: Vector2, delta: float) -> void:
	if _awake >= 0:
		_rise_time += delta
		_show_rise(_awake)
		if _rise_time >= _rise_seconds() + HOLD_AFTER:
			var index := _awake
			_awake = -1
			# 일어선 것은 **그대로 세워 둔다.** 암전이 끝나기 전에 숨기면 눈앞에서 사라진다 -
			# `woke`를 받은 쪽이 씬을 갈아타므로 여기서 치울 것이 없다.
			woke.emit(index)
		return

	var near := _room.sleeper_at(hero_at)
	if near < 0:
		return
	_awake = near
	_rise_time = 0.0


func _rise_seconds() -> float:
	return float(maxi(_rise.size(), 1)) / RISE_FPS


## **한 번만 재생하고 마지막에 멈춘다.** 되풀이하면 일어섰다 누웠다 하는 꼴이 된다.
func _show_rise(index: int) -> void:
	if _rise.is_empty():
		return
	var frame: int = mini(int(_rise_time * RISE_FPS), _rise.size() - 1)
	_sprites[index].texture = _rise[frame]
