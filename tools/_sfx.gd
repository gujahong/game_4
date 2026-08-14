extends SceneTree

## 효과음을 **코드로 합성해서** wav로 뽑는다. 등불과 복도를 코드로 그린 것과 같은 방식이다.
##
## 이 게임의 소리는 거의 다 "정체 모를 웅웅거림"이라 합성이 잘 맞는다 - 현실에서 녹음한 발소리나
## 종이 소리는 오르간 드론 위에 얹으면 오히려 겉돈다. 그리고 **숫자만 바꿔 다시 뽑을 수 있다.**
##
## 다 모노 22050Hz 16비트다. 이 소리들은 저역과 잡음이 대부분이라 더 높은 표본률이 필요 없고,
## 파일이 작아야 저장소에도 부담이 없다.
##
## `--headless --script res://tools/_sfx.gd`

const OUT_DIR := "res://assets/sfx"
const RATE := 22050


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)

	_save("step", _step())
	_save("seize", _seize())
	_save("tick", _tick())
	_save("cry", _cry())
	_save("drone", _drone(), true)
	_save("wind", _wind(), true)
	_save("blink", _blink())
	_save("shard", _shard())
	_save("sweep", _sweep())
	_save("move", _move())
	_save("pick", _pick())
	_save("hit", _hit())
	_save("hurt", _hurt())
	_save("flare", _flare())
	_save("damp", _damp())
	_save("over", _over())
	quit()


# --- 소리 하나하나 ---

## 걸음. **발소리가 아니라 발 밑에서 나는 울림이다.** 또렷한 발소리를 넣으면 사람이 걷는
## 소리가 되는데, 여기서는 캄캄한 서고에 울리는 것이라야 한다.
##
## **잡음 한 덩어리만으로는 발소리가 안 된다.** 짧게 터지고 마니까 그냥 지직 소리다. 셋을 겹친다 -
## 발이 닿는 순간(짧고 마른 것), 몸무게가 실리는 저역(둔한 것), 그리고 **서고가 되받는 꼬리**.
## 마지막 것이 있어야 좁은 데가 아니라 크고 빈 데를 걷는 소리가 된다.
func _step() -> PackedFloat32Array:
	var out := _empty(1.1)
	# **사인파를 쓰면 안 된다.** 굽 소리를 205Hz 사인으로 냈더니 핀셋 부딪는 소리가 됐다 -
	# 순수한 음은 금속으로 들린다. 재료가 있는 소리는 **잡음을 걸러서** 만든다. 짧게 터뜨린
	# 잡음을 넓은 띠로 통과시키면 음높이는 어렴풋한데 두께가 생겨서 "툭"이 된다.
	var low := 0.0
	var band := 0.0
	var thump := 0.0
	var prev := 0.0
	var f: float = 2.0 * sin(PI * 290.0 / float(RATE))
	for i in out.size():
		var t: float = float(i) / float(RATE)
		var noise: float = randf_range(-1.0, 1.0)

		# 굽이 닿는 짧은 터짐. 이걸 띠에 통과시켜 몸통을 만든다.
		var hit: float = noise * exp(-t * 70.0)
		var high: float = hit - low - 0.9 * band   # 0.9면 꽤 넓다 - 좁으면 다시 금속이 된다
		band += f * high
		low += f * band
		var thok: float = band * 1.5

		# 밑에 깔리는 둔한 소리. 걸러 낸 잡음이라 사인처럼 울리지 않는다.
		thump = _lowpass(thump, noise, 0.05)
		var weight: float = thump * 0.9 * exp(-t * 34.0)

		# 밑창이 돌을 스치는 여린 소리. 아주 조금만.
		var scuff: float = (noise - prev) * 0.18 * exp(-t * 60.0)
		prev = noise

		out[i] = thok + weight + scuff

	# **복도는 되돌려준다.** 한 발 소리가 벽에 부딪혀 조금 늦게 한 번 더 온다 - 이 늦은
	# 한 번이 있어야 방이 아니라 긴 복도가 된다. 두 번 겹쳐서 점점 여리게.
	# 복도 울림은 `_save`가 모든 소리에 똑같이 씌운다.
	return out


## 붙잡히는 순간. 저역이 쿵 내려앉는다. **음이 아래로 미끄러져야** 뭔가 가라앉는 것이 된다.
func _seize() -> PackedFloat32Array:
	var out := _empty(1.4)
	var phase := 0.0
	var low := 0.0
	for i in out.size():
		var t: float = float(i) / float(RATE)
		var hz: float = lerpf(96.0, 33.0, minf(t / 0.8, 1.0))
		phase += TAU * hz / float(RATE)
		low = _lowpass(low, randf_range(-1.0, 1.0), 0.03)
		out[i] = (sin(phase) * 0.7 + low * 1.2) * exp(-t * 2.2)
	return out


## 돌아설 때의 한 칸. **무겁고 기괴해야 한다.**
##
## 마른 딸깍으로 만들었더니 태엽 감는 소리가 됐다(회원님). 딸깍은 작고 가벼운 물건이 내는
## 소리다. 여기서는 큰 것이 억지로 한 칸 돌아가는 것이라, **때린 쇠붙이**에 가깝게 만든다 -
## 낮은 몸통이 울리고 그 위에 배음이 얹히는데, **그 배음이 몸통의 정수배가 아니다.**
## 정수배면 종이나 악기가 되어 곱게 들리고, 어긋나야 쇠붙이가 삐걱이는 소리가 된다.
## **돌이 돌에 갈리는 소리다**(회원님). 때린 쇠붙이로 만들었더니 종에 가까웠다 - 치는 것은
## 한 번에 울리고 마는데, 갈리는 것은 **소리가 이어지면서 거칠게 떨린다.**
## 그러니 여운을 길게 두고, 잡음을 30Hz쯤으로 잘게 끊어서 그그그긍 하고 긁히게 만든다.
func _tick() -> PackedFloat32Array:
	var out := _empty(0.5)
	var body := 0.0
	var grind := 0.0
	var low := 0.0
	for i in out.size():
		var t: float = float(i) / float(RATE)
		body += TAU * 96.0 / float(RATE)
		grind += TAU * 31.0 / float(RATE)   # 긁히는 결. 이 주기가 곧 "그그그긍"이다
		low = _lowpass(low, randf_range(-1.0, 1.0), 0.16)

		# 잡음을 톱니처럼 끊는다. 고르게 흐르면 바람이고, 끊겨야 갈리는 것이 된다.
		var teeth: float = 0.35 + 0.65 * absf(sin(grind))
		var scrape: float = low * 2.4 * teeth * exp(-t * 5.0)
		# 갈리는 동안 몸통이 낮게 운다. 무게는 여기서 온다.
		var stone: float = sin(body) * 0.5 * exp(-t * 6.0)
		out[i] = scrape + stone
	return out


## 마주 섰을 때 그 것이 내는 소리. **울음이지 포효가 아니다.** 위협하는 것이 아니라 여기
## 있다는 것을 알리는 소리다 - 낮은 음이 천천히 아래로 미끄러지고, 그 위에 몇 헤르츠
## 어긋난 음이 겹쳐 울렁인다. 고래나 큰 관악기 언저리다.
func _cry() -> PackedFloat32Array:
	var seconds := 2.6
	var out := _empty(seconds)
	var first := 0.0
	var second := 0.0
	var breath := 0.0
	for i in out.size():
		var t: float = float(i) / float(RATE)
		var along: float = t / seconds

		# 음이 아래로 미끄러진다. 떨림(4.5Hz)을 얹어야 숨 쉬는 것으로 들린다.
		# **너무 낮으면 안 들린다.** 104→71Hz로 잡았더니 작은 스피커에서 거의 안 나왔다.
		# 소리를 크게 하는 대신 음을 올린다 - 낮다고 무거운 게 아니다.
		var hz: float = lerpf(233.0, 165.0, along) * (1.0 + 0.012 * sin(TAU * 4.5 * t))
		first += TAU * hz / float(RATE)
		second += TAU * (hz * 1.503) / float(RATE)   # 딱 떨어지지 않는 배음
		breath = _lowpass(breath, randf_range(-1.0, 1.0), 0.06)

		# 천천히 부풀어 한참 버티다 잦아든다.
		var swell: float = clampf(along / 0.22, 0.0, 1.0) * clampf((1.0 - along) / 0.4, 0.0, 1.0)
		out[i] = (sin(first) * 0.72 + sin(second) * 0.30 + breath * 0.35) * swell
	return out


## 다가올 때 깔리는 저역. **한 바퀴 돌아 이어 붙일 것**이라 시작과 끝이 같아야 한다.
## 그래서 길이에 딱 떨어지는 주기의 사인만 쓴다 - 잡음을 섞으면 이음매가 툭 들린다.
## 다가올 때 깔리는 소리. **둘을 겹친다**(회원님).
##
## 하나는 **쿠구구극** - 땅이 울리는 저역인데 고르게 울면 기계라, 빠른 떨림과 느린 떨림을
## 곱해서 불규칙하게 끊기게 한다.
## 하나는 **계속 들려오는 기괴한 소리** - 높은 음 둘을 몇 헤르츠 차이로 겹쳐 놓으면 서로
## 밀고 당기며 울렁인다. 사람 목소리 언저리라 뭔가가 내는 소리처럼 들린다.
##
## **한 바퀴 돌아 이어 붙일 것**이라 시작과 끝이 같아야 한다. 그래서 길이에 딱 떨어지는
## 주기만 쓴다 - 잡음은 이어 붙인 자리가 안 들리므로 세기와 밝기만 맞추면 된다.
func _drone() -> PackedFloat32Array:
	var seconds := 6.0
	var out := _empty(seconds)
	var low := 0.0
	for i in out.size():
		var t: float = float(i) / float(RATE)
		var turn: float = TAU * t / seconds

		# 쿠구구극. 빠른 떨림(11Hz)과 느린 떨림(4.5Hz)을 곱해서 고르지 않게 만든다.
		# **너무 낮게 거르면 안 들린다** - 작은 스피커가 못 내는 데다 몰아넣지 않는다.
		low = _lowpass(low, randf_range(-1.0, 1.0), 0.14)
		var pulse: float = 0.55 + 0.45 * sin(turn * 66.0) * sin(turn * 27.0)
		var rumble: float = low * 2.6 * pulse

		# 밑에 깔리는 92Hz. 이게 있어야 떨림이 허공에 뜨지 않는다.
		var deep: float = sin(turn * 552.0) * 0.34

		# 기괴한 것. 430Hz와 437Hz가 7Hz로 맥놀이하며 울렁인다.
		var eerie: float = (sin(turn * 2580.0) + sin(turn * 2622.0)) * 0.5
		eerie *= 0.30 + 0.22 * sin(turn * 13.0)

		out[i] = rumble * 0.5 + deep + eerie * 0.5
	return out


## 서고에 흐르는 바람. **어디선가 새어 드는 공기지 바깥의 바람이 아니다** - 세게 몰아치면
## 여기가 실내가 아니게 된다. 아주 여리게 깔려서, 없으면 허전한 정도면 된다.
##
## 잡음은 이어 붙인 자리가 안 들린다(잡음이라 그렇다). 들리는 것은 **세기와 밝기가 오르내리는
## 흐름**이므로, 그쪽만 길이에 딱 떨어지는 주기로 만들면 한 바퀴 돌아도 티가 안 난다.
func _wind() -> PackedFloat32Array:
	var seconds := 8.0
	var out := _empty(seconds)
	var low := 0.0
	var band := 0.0
	var wide := 0.0
	for i in out.size():
		var t: float = float(i) / float(RATE)
		# 8초에 각각 3, 5, 2바퀴. 서로 안 맞아서 같은 자리로 안 돌아오는 것처럼 들린다.
		var slow: float = sin(TAU * 3.0 * t / seconds)
		var slower: float = sin(TAU * 5.0 * t / seconds + 1.1)
		var slowest: float = sin(TAU * 2.0 * t / seconds + 2.3)

		# **크게 부풀었다 잦아들면 파도가 된다**(회원님). 밀려왔다 쓸려 나가는 그 오르내림이
		# 파도의 정체다. 실내의 공기는 그냥 흐르고 있을 뿐이라, 세기를 거의 안 건드리고
		# 밝기만 아주 조금 흔든다.
		# **겨울바람은 낮고 둥근 소리가 아니다.** 0.018로 걸렀더니 밀려왔다 쓸려 가는
		# 파도가 됐다 - 낮게만 남기면 무엇이든 파도로 들린다. 훨씬 밝게 열어서 마르고
		# 가느다란 소리로 만든다.
		# **휘파람은 음이 아니라 좁게 걸러낸 잡음이다.** 사인파를 남겼더니 시험음(삐-)이
		# 됐고, 넓게 거른 잡음을 남겼더니 파도가 됐다. 그 사이가 바람이다 - 잡음을 아주 좁은
		# 띠로만 통과시키면, 소리에 음높이가 생기면서도 여전히 바람인 채로 남는다.
		#
		# 통과시키는 자리를 8초에 걸쳐 위아래로 옮기는 것이 **휘우우웅**이다.
		# **너무 좁으면 인공이 된다.** 띠가 좁을수록 음높이가 또렷해지는데, 또렷해질수록
		# 신시사이저 소리로 들린다. 넓게 잡아서 소리에 결만 남기고 음은 안 서게 한다.
		var centre: float = 560.0 + 150.0 * slower + 80.0 * slow
		var f: float = 2.0 * sin(PI * centre / float(RATE))
		var noise: float = randf_range(-1.0, 1.0)
		var high: float = noise - low - 0.34 * band   # 0.34가 띠의 좁기다
		band += f * high
		low += f * band

		# 그 뒤에 **바람의 몸**을 깐다. 휘파람만 있으면 소리가 허공에 가늘게 서 있고, 이
		# 넓은 결이 받쳐 줘야 공기가 실제로 움직이는 것으로 들린다. 파도가 안 되게 세기는
		# 거의 고정하고, 낮은 쪽으로 너무 몰지 않는다.
		wide = _lowpass(wide, noise, 0.09)

		var swell: float = 0.82 + 0.18 * absf(slowest * 0.7 + slow * 0.3)
		out[i] = clampf(band * 0.14 + wide * 0.95, -1.0, 1.0) * swell
	return out


## 암전 속에서 등불이 붙으려다 마는 소리. **부와앙……** 부싯돌처럼 마른 소리가 아니라, 저역이
## 부풀었다 스러진다 - 불이 튀는 게 아니라 뭔가가 잠깐 켜졌다 꺼지는 것이다.
func _blink() -> PackedFloat32Array:
	var out := _empty(0.95)
	var phase := 0.0
	var low := 0.0
	for i in out.size():
		var t: float = float(i) / float(RATE)
		# 음이 살짝 올라갔다 내려온다. 곧게 두면 경적이 된다.
		var hz: float = 52.0 + 16.0 * sin(PI * minf(t / 0.95, 1.0))
		phase += TAU * hz / float(RATE)
		low = _lowpass(low, randf_range(-1.0, 1.0), 0.05)
		# **부풀었다 잦아든다.** 앞이 느려야 "부-", 뒤가 길어야 "-와앙"이 된다.
		var swell: float = pow(sin(PI * minf(t / 0.95, 1.0)), 1.6)
		out[i] = (sin(phase) * 0.85 + low * 0.5) * swell
	return out


## 빛살 한 조각이 터지는 소리. **팟-** 짧고 밝고 마르다.
## 잡음이 아래로 쓸려 내려가게 했더니 "슈욱"이 되어 조각이 깨지는 것 같지 않았다.
func _shard() -> PackedFloat32Array:
	var out := _empty(0.34)
	var low := 0.0
	var band := 0.0
	var body := 0.0
	for i in out.size():
		var t: float = float(i) / float(RATE)
		var noise: float = randf_range(-1.0, 1.0)

		# **빛살이 뻗어 나가는 소리다.** 1900Hz 사인을 얹었더니 띵- 하는 종소리가 됐다.
		# 통과시키는 자리를 위에서 아래로 훑어 내리면, 한 점이 울리는 게 아니라 **뭔가가
		# 지나간** 것으로 들린다.
		var centre: float = lerpf(3200.0, 700.0, minf(t / 0.2, 1.0))
		var f: float = 2.0 * sin(PI * minf(centre, 9000.0) / float(RATE))
		var high: float = noise * exp(-t * 16.0) - low - 0.55 * band
		band += f * high
		low += f * band

		# 밑에 두께를 조금. 빛살에도 무게가 있어야 가볍지 않다.
		body = _lowpass(body, noise, 0.10)
		out[i] = band * 1.6 + body * 0.7 * exp(-t * 24.0)
	return out


## 카메라가 부우웅 도는 소리. 낮은 쪽으로 쓸려 가며 커졌다 잦아든다.
func _sweep() -> PackedFloat32Array:
	var out := _empty(1.6)
	var phase := 0.0
	var low := 0.0
	for i in out.size():
		var t: float = float(i) / float(RATE)
		var hz: float = lerpf(140.0, 46.0, t / 1.6)
		phase += TAU * hz / float(RATE)
		low = _lowpass(low, randf_range(-1.0, 1.0), 0.05)
		# 가운데가 제일 크다. 사인 한 마루로 부풀렸다 재운다.
		var swell: float = sin(PI * t / 1.6)
		out[i] = (sin(phase) * 0.6 + low * 0.8) * swell
	return out


## 고를 것을 옮길 때. `_tick`보다 여리고 짧다 - 손이 내는 소리라 앞에 나서면 안 된다.
func _move() -> PackedFloat32Array:
	var out := _empty(0.05)
	var prev := 0.0
	var low := 0.0
	for i in out.size():
		var t: float = float(i) / float(RATE)
		low = _lowpass(low, randf_range(-1.0, 1.0), 0.5)
		var dry: float = low - prev
		prev = low
		out[i] = dry * 1.6 * exp(-t * 120.0)
	return out


## 골랐을 때. **불이 한 번 훅 인다.** 잡음이 부풀었다 잦아든다.
func _pick() -> PackedFloat32Array:
	var out := _empty(0.42)
	var low := 0.0
	for i in out.size():
		var t: float = float(i) / float(RATE)
		low = _lowpass(low, randf_range(-1.0, 1.0), 0.12)
		var swell: float = sin(PI * minf(t / 0.42, 1.0))
		out[i] = low * 2.2 * swell * swell
	return out


## 내 칼이 파고들 때. **살을 베는 소리가 아니라 뭔가 갈라지는 소리다** - 상대가 사람이 아니다.
func _hit() -> PackedFloat32Array:
	var out := _empty(0.30)
	var low := 0.0
	var prev := 0.0
	for i in out.size():
		var t: float = float(i) / float(RATE)
		low = _lowpass(low, randf_range(-1.0, 1.0), 0.22)
		var crack: float = low - prev * 0.7
		prev = low
		out[i] = crack * 3.0 * exp(-t * 20.0)
	return out


## 내가 맞을 때. 저역이 한 번 짓눌린다. **때리는 소리보다 낮고 둔해야** 맞은 쪽이 나라는 게 된다.
func _hurt() -> PackedFloat32Array:
	var out := _empty(0.55)
	var phase := 0.0
	var low := 0.0
	for i in out.size():
		var t: float = float(i) / float(RATE)
		var hz: float = lerpf(74.0, 40.0, minf(t / 0.25, 1.0))
		phase += TAU * hz / float(RATE)
		low = _lowpass(low, randf_range(-1.0, 1.0), 0.04)
		out[i] = (sin(phase) * 0.8 + low * 0.9) * exp(-t * 7.0)
	return out


## 등불을 밝힐 때. 불이 확 인다 - `_pick`보다 길고 위로 열린다.
func _flare() -> PackedFloat32Array:
	var out := _empty(0.5)
	var low := 0.0
	for i in out.size():
		var t: float = float(i) / float(RATE)
		# 걸름막이 열린다. 어두운 데서 밝은 데로.
		low = _lowpass(low, randf_range(-1.0, 1.0), lerpf(0.04, 0.4, minf(t / 0.3, 1.0)))
		out[i] = low * 2.6 * sin(PI * minf(t / 0.5, 1.0))
	return out


## 등불을 줄일 때. 걸름막이 닫히며 먹먹해진다. `_flare`를 뒤집은 것이다.
func _damp() -> PackedFloat32Array:
	var out := _empty(0.45)
	var low := 0.0
	for i in out.size():
		var t: float = float(i) / float(RATE)
		low = _lowpass(low, randf_range(-1.0, 1.0), lerpf(0.35, 0.02, minf(t / 0.35, 1.0)))
		out[i] = low * 2.2 * exp(-t * 4.0)
	return out


## 전투가 끝날 때. 길게 가라앉는다. **이긴 것도 진 것도 같은 소리다** - 어느 쪽이든 정적이 온다.
func _over() -> PackedFloat32Array:
	var out := _empty(2.2)
	var phase := 0.0
	var low := 0.0
	for i in out.size():
		var t: float = float(i) / float(RATE)
		var hz: float = lerpf(62.0, 28.0, minf(t / 1.8, 1.0))
		phase += TAU * hz / float(RATE)
		low = _lowpass(low, randf_range(-1.0, 1.0), 0.02)
		out[i] = (sin(phase) * 0.7 + low * 0.6) * exp(-t * 1.3)
	return out


# --- 뼈대 ---

## 복도가 되돌려주는 소리. 벽에 부딪혀 조금씩 늦게, 조금씩 여리게 네 번 더 돌아온다.
## 꼬리가 잘리지 않게 뒤에 빈자리를 붙이고 나서 겹친다.
func _room(samples: PackedFloat32Array) -> PackedFloat32Array:
	var out := samples.duplicate()
	out.resize(samples.size() + int(0.55 * float(RATE)))
	for entry in [[0.075, 0.30], [0.165, 0.20], [0.290, 0.13], [0.430, 0.07]]:
		var back: int = int(entry[0] * float(RATE))
		for i in range(back, out.size()):
			out[i] += out[i - back] * entry[1]
	return out


func _empty(seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(seconds * float(RATE)))
	return out


## 한 극점 저역 통과. k가 작을수록 낮은 쪽만 남는다.
func _lowpass(state: float, input: float, k: float) -> float:
	return state + (input - state) * k


## 소리를 16비트로 눌러 담아 저장한다. **끝을 짧게 재워서** 뚝 끊길 때 나는 딱 소리를 막는다.
func _save(name: String, samples: PackedFloat32Array, looping: bool = false) -> void:
	# **여기는 다 서고 안이다.** 소리마다 따로 울림을 넣는 대신 나가는 길목에서 한 번에
	# 씌운다 - 그래야 전부 같은 공간에서 난 소리로 들린다.
	# 도는 소리(바람·공포)는 뺀다. 한 바퀴 돌아 이어 붙일 것이라 꼬리가 이음매를 망친다.
	if not looping:
		samples = _room(samples)

	var tail: int = mini(int(0.005 * float(RATE)), samples.size())
	if not looping:
		for i in tail:
			samples[samples.size() - 1 - i] *= float(i) / float(tail)

	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var value: int = int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, value)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = samples.size()

	# **`.tres`로 저장한다.** `.wav`로 저장하면 `ResourceSaver`가 그 확장자를 다룰 줄 몰라서
	# 아무것도 안 쓰고 조용히 실패한다(파일이 하나도 안 생겼는데 "저장"이라고 찍혔다).
	# `.tres`는 고도가 그대로 읽는 리소스라 임포트를 거치지 않고, 루프 설정도 파일에 같이 남는다.
	var path := "%s/%s.tres" % [OUT_DIR, name]
	var failed := ResourceSaver.save(stream, path)
	if failed != OK:
		push_error("못 썼다: %s (오류 %d)" % [path, failed])
		return
	print("저장: %s (%.2f초)" % [path, float(samples.size()) / float(RATE)])
