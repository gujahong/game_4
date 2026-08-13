extends AnimatedSprite2D
class_name HeroSprite

## 주인공을 그린다. **규칙을 모른다** — `Hero`가 정한 방향과 걷는지 여부만 받아 그림을 고른다.
##
## 애니메이션 이름은 `walk_south`처럼 상태와 방향을 이어 붙인 것이고, 방향 이름은 PixelLab이
## 쓰는 것(south / north / east / west)을 그대로 쓴다.
##
## **서 있는 그림에 generation을 안 쓴다.** PixelLab이 걷기를 만들 때 원본 회전 그림을 첫
## 장으로 끼워 주는데, 그게 곧 서 있는 자세다. `tools/_frames.gd`가 그 한 장을 `idle_`로
## 갈라둔다 — 걷기 고리에 넣어두면 한 바퀴마다 한 번씩 멈칫한다.
##
## 그림이 아직 없으면 조용히 아무 일도 안 한다 — 지금은 등불 빛이 곧 주인공이라 그것만으로도
## 화면이 성립한다.
##
## **등불은 캐릭터 그림에 안 들어 있다.** 그려 넣었더니 걷기 프레임마다 위치와 모양이 튀었고,
## 물건을 든 캐릭터에는 템플릿 애니메이션도 못 썼다(2026-08-13). 여기서 따로 얹는다.
##
## 그리고 **손에 들지 않고 앞에 띄운다**(회원님). 비밀 결사의 수호자니 그 정도는 한다.
## 손에 매달아 두면 걸을 때 팔 흔들림과 어긋나서 어색한데, 띄우면 그 문제가 통째로 사라진다 -
## 붙어 있을 이유가 애초에 없어지니까.

const LANTERN := "res://assets/characters/pilgrim/lantern.png"

## 방향별로 등불이 뜨는 자리(스프라이트 가운데에서 잰 픽셀). 그림이 16x32라 가운데는 (8,16)이고,
## 등불은 **바라보는 쪽 앞**에 뜬다.
const LANTERN_AT := {
	"south": Vector2(0, 15),
	"north": Vector2(0, -13),
	"east": Vector2(13, 3),
	"west": Vector2(-13, 3),
}

## 떠 있는 티가 나게 위아래로 흔든다. **걸음과 무관하게 제 박자로** 움직여야 매달린 것과 갈린다.
##
## 흔들림이 정수 픽셀로 끊기므로 폭이 곧 계단 수다 - 1.5면 위아래 1칸씩뿐이라 거의 안 보였다.
## 2.5면 2칸씩 오르내린다.
const FLOAT_HEIGHT := 2.5
const FLOAT_SPEED := 1.6

var _lantern: Sprite2D


func _ready() -> void:
	_lantern = Sprite2D.new()
	_lantern.texture = load(LANTERN)
	add_child(_lantern)


func show_state(facing: String, walking: bool) -> void:
	_float_lantern(facing)

	if sprite_frames == null:
		return
	var wanted := ("walk_" if walking else "idle_") + facing
	if not sprite_frames.has_animation(wanted):
		return
	if animation != wanted or not is_playing():
		play(wanted)


## 등불을 바라보는 쪽 앞에 띄운다. 흔들림은 **정수 픽셀로 끊는다** - 부드럽게 움직이면
## 도트가 반 칸씩 어긋나 혼자 매끈해 보인다.
func _float_lantern(facing: String) -> void:
	var at: Vector2 = LANTERN_AT.get(facing, Vector2.ZERO)
	var drift: float = float(Time.get_ticks_msec()) * 0.001 * FLOAT_SPEED
	at.y += roundf(sin(drift) * FLOAT_HEIGHT)
	_lantern.position = at
	# 뒤를 보고 갈 때는 등불이 나보다 멀리 있으므로 몸 뒤로 보낸다.
	_lantern.z_index = -1 if facing == "north" else 1


## 등불이 지금 떠 있는 자리. 빛(`LampGlow`)을 여기에 맞추려고 밖에서 읽어 간다.
func lantern_at() -> Vector2:
	return _lantern.position
