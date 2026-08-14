extends AudioStreamPlayer
class_name Music

## 한 화면의 배경음. **켜고 끄는 것 말고는 아무것도 안 한다.**
##
## 화면마다 오디오 노드를 손으로 붙이고 볼륨을 따로 적어 두면, 나중에 곡을 바꿀 때 여기저기를
## 뒤져야 한다. 한 줄로 켜지게 해 두면 곡을 넣고 빼는 것이 화면 쪽 일이 아니게 된다.
##
## ```gdscript
## Music.play_in(self, "res://assets/music/title.mp3")
## ```

## **소리 없이 시작해서 배어 나온다.** 켜자마자 제 소리로 나오면 화면은 아직 캄캄한데 음악만
## 먼저 와 있는 꼴이라 어긋난다. 이 게임은 어둠에서 빛이 배어 나오는 것으로 시작한다.
const FADE_IN := 4.0

## 기본 크기. 분위기를 까는 소리라 앞에 나서면 안 된다.
const VOLUME_DB := -8.0


## 곡을 걸고 켠다. 노드를 만들어 `host` 밑에 붙이고 그 노드를 돌려준다.
##
## from_position은 **곡의 어디서부터 쓸 것인가**다. 앞에 붙은 도입부를 안 쓸 때 여기를
## 넘기면 되고, 한 바퀴 돌아 다시 시작할 때도 이 자리로 돌아온다 - 처음 한 번만 건너뛰면
## 두 번째부터는 안 듣던 앞부분이 튀어나온다.
static func play_in(host: Node, path: String, volume_db: float = VOLUME_DB,
		from_position: float = 0.0) -> Music:
	var stream: AudioStream = load(path)
	if stream == null:
		push_warning("음악을 못 찾았다: %s" % path)
		return null

	# **불러온 자리에서 루프를 켠다.** mp3는 임포트 설정에 루프가 꺼진 채로 들어오는데,
	# 그걸 고치려면 `.import` 파일을 건드려야 하고 다시 임포트하면 도로 꺼진다.
	if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
		stream.set("loop", true)
		stream.set("loop_offset", from_position)

	var music := Music.new()
	music.stream = stream
	music.volume_db = -60.0
	music.bus = "Master"
	host.add_child(music)
	music.play(from_position)

	var swell := music.create_tween()
	swell.tween_property(music, "volume_db", volume_db, FADE_IN)
	return music


## 서서히 줄이고 끈다. 화면이 바뀔 때 뚝 끊으면 그 순간이 편집점으로 들린다.
func fade_out(duration: float = 2.0) -> void:
	var away := create_tween()
	away.tween_property(self, "volume_db", -60.0, duration)
	await away.finished
	stop()
