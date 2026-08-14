extends RefCounted
class_name Sfx

## 효과음을 한 줄로 낸다. **소리를 내는 쪽은 자기가 언제 나는지만 알면 된다.**
##
## ```gdscript
## Sfx.play(self, Sfx.TICK)              # 한 번 나고 사라진다
## var hum := Sfx.loop(self, Sfx.DRONE)  # 계속 돈다. 소리 크기는 부르는 쪽이 정한다
## ```
##
## 소리는 전부 코드로 합성한 것이다(`tools/_sfx.gd`). 숫자만 바꿔 다시 뽑을 수 있다.

const STEP := "res://assets/sfx/step.tres"      ## 걸음
const SEIZE := "res://assets/sfx/seize.tres"    ## 붙잡히는 순간
const TICK := "res://assets/sfx/tick.tres"      ## 돌아설 때 한 칸
const CRY := "res://assets/sfx/cry.tres"        ## 마주 섰을 때의 울음
const DRONE := "res://assets/sfx/drone.tres"    ## 다가올 때 깔리는 저역
const WIND := "res://assets/sfx/wind.tres"      ## 서고에 흐르는 바람
const BLINK := "res://assets/sfx/blink.tres"    ## 부와앙 - 불이 붙으려다 만다
const SHARD := "res://assets/sfx/shard.tres"    ## 빛살 한 조각
const SWEEP := "res://assets/sfx/sweep.tres"    ## 카메라가 도는 소리
const MOVE := "res://assets/sfx/move.tres"      ## 고를 것을 옮김
const PICK := "res://assets/sfx/pick.tres"      ## 고름
const HIT := "res://assets/sfx/hit.tres"        ## 내 칼이 파고듦
const HURT := "res://assets/sfx/hurt.tres"      ## 내가 맞음
const FLARE := "res://assets/sfx/flare.tres"    ## 등불을 밝힘
const DAMP := "res://assets/sfx/damp.tres"      ## 등불을 줄임
const OVER := "res://assets/sfx/over.tres"      ## 전투가 끝남


## 한 번 내고 스스로 사라진다. pitch를 흔들면 같은 소리를 여러 번 내도 기계처럼 안 들린다.
static func play(host: Node, path: String, volume_db: float = 0.0,
		pitch: float = 1.0) -> AudioStreamPlayer:
	var stream: AudioStream = load(path)
	if stream == null or host == null or not host.is_inside_tree():
		return null
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	host.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	return player


## 계속 도는 소리. 끄고 켜고 크기를 바꾸는 것은 부르는 쪽이 한다.
static func loop(host: Node, path: String, volume_db: float = -40.0) -> AudioStreamPlayer:
	var stream: AudioStream = load(path)
	if stream == null or host == null or not host.is_inside_tree():
		return null
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	host.add_child(player)
	player.play()
	return player
