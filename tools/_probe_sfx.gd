extends SceneTree

## 일회용. 효과음이 **실제로 소리를 담고 있는지** 재 본다. "안 들린다"는 말이 나올 때
## 파일이 비었는지, 소리가 작은지, 아니면 아예 안 틀린 건지를 가르려고 쓴다.
##
## `--headless --script res://tools/_probe_sfx.gd`

func _init() -> void:
	for path in [Sfx.STEP, Sfx.SEIZE, Sfx.TICK, Sfx.CRY, Sfx.DRONE, Sfx.WIND, Sfx.BLINK,
			Sfx.SHARD, Sfx.SWEEP, Sfx.MOVE, Sfx.PICK, Sfx.HIT, Sfx.HURT,
			Sfx.FLARE, Sfx.DAMP, Sfx.OVER]:
		var stream: AudioStreamWAV = load(path)
		if stream == null:
			print("못 읽음 : ", path)
			continue

		var peak := 0.0
		var total := 0.0
		var count: int = stream.data.size() / 2
		for i in count:
			var value: float = float(stream.data.decode_s16(i * 2)) / 32767.0
			peak = maxf(peak, absf(value))
			total += value * value
		var rms: float = sqrt(total / maxf(float(count), 1.0))

		print("%-30s %5.2f초  가장 큰 곳 %.2f  평균 %.3f (%.0f dB)" % [
			path.get_file(), stream.get_length(), peak, rms,
			20.0 * log(maxf(rms, 0.00001)) / log(10.0),
		])
	quit()
