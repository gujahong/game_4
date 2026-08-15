extends SceneTree

## 뽑아둔 효과음을 순서대로 한 번씩 들려준다. **`--headless`로 돌리면 소리가 안 난다** -
## headless는 오디오 장치를 안 잡는다. 창을 띄워서 돌릴 것.
##
## `--path . --script res://tools/_play_sfx.gd`
##
## 도는 소리(drone·wind)는 끝이 없으므로 `LOOP_SECONDS`만큼만 들려주고 끊는다.

const SFX_DIR := "res://assets/sfx"
const GAP := 0.35        ## 소리 사이 틈. 겹쳐 들리면 뭐가 뭔지 모른다
const LOOP_SECONDS := 4.0

## 만든 순서대로. 이 순서가 곧 게임에서 들리는 순서에 가깝다.
const ORDER := [
	"step", "seize", "tick", "cry", "drone", "wind",
	"blink", "shard", "sweep",
	"move", "pick", "hit", "hurt", "flare", "damp", "over",
]


func _init() -> void:
	await process_frame   # root가 생기기를 기다린다

	var player := AudioStreamPlayer.new()
	root.add_child(player)

	print("--- 효과음 %d개 ---" % ORDER.size())
	for name in ORDER:
		var path := "%s/%s.tres" % [SFX_DIR, name]
		if not ResourceLoader.exists(path):
			print("  없다: %s" % path)
			continue

		var stream: AudioStream = load(path)
		var seconds: float = stream.get_length()
		var looping: bool = seconds <= 0.0 or seconds > LOOP_SECONDS
		if looping:
			seconds = LOOP_SECONDS

		print("  %-6s %.2f초" % [name, seconds])
		player.stream = stream
		player.play()
		await create_timer(seconds + GAP).timeout
		player.stop()

	print("--- 끝 ---")
	quit()
