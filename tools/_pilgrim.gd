extends SceneTree

## 주인공을 코드로 찍는다. 4방향 x (서 있기 1 + 걷기 4) = 20장.
##
## PixelLab로 뽑은 것과 견줘 보려고 만든 것이다. **0 generation**이고 숫자만 고쳐 다시 돌리면
## 되므로 몇 번이고 바꿀 수 있다.
##
## 이 캐릭터라서 해볼 만하다 - 얼굴이 없고(두건 속 어둠), 팔이 망토에 가려 거의 안 보이고,
## 몸이 사실상 **종 모양 하나 + 두건**이다. 게다가 화면 필터가 4계조로 깎아서 정교한 명암이
## 어차피 안 살아남는다.
##
## `--headless --script res://tools/_pilgrim.gd`

const OUT_DIR := "res://assets/characters/pilgrim_drawn/walk4"

## 캔버스는 PixelLab 것과 맞춘다. 그래야 좌표와 도구를 그대로 쓴다.
const W := 48
const H := 48

const TOP := 10.0    ## 두건 꼭대기
const FOOT := 40.0   ## 발끝
const CX := 24.0

## 팔레트. 회청색 망토에 뼈색 테두리 - 처음 뽑았던 판의 색을 가져왔다.
const OUTLINE := Color("08080a")
const DARK := Color("2b2f3a")   ## 그늘진 쪽
const MID := Color("3f4553")    ## 바탕
const LIGHT := Color("565d6e")  ## 빛 받는 쪽
const TRIM := Color("d8dcdc")   ## 두건 테두리
const HOLLOW := Color("050506")  ## 두건 속
const BOOT := Color("1b1819")

## 세로 위치별 반폭. 앞뒤는 넓고 옆모습은 좁다.
const WIDE := [
	[10.0, 0.0], [11.0, 3.0], [13.0, 5.0], [16.0, 5.5],
	[18.0, 4.8], [20.0, 7.0], [26.0, 7.5], [32.0, 8.5], [37.0, 9.5], [40.0, 10.0],
]
const NARROW := [
	[10.0, 0.0], [11.0, 2.5], [13.0, 4.0], [16.0, 4.5],
	[18.0, 4.0], [20.0, 5.5], [26.0, 6.0], [32.0, 6.5], [37.0, 7.0], [40.0, 7.5],
]

const DIRECTIONS := ["south", "north", "east", "west"]

## 걷기 네 자세. 각 항목은 [두 발의 앞뒤 어긋남, 몸이 뜨는 양].
## 접지 - 통과 - 접지 - 통과 순서라야 한 바퀴가 이어진다.
const STEPS := [
	[2.0, 0.0], [0.0, 1.0], [-2.0, 0.0], [0.0, 1.0],
]


func _init() -> void:
	for entry in DIRECTIONS:
		var direction: String = entry
		var here := "%s/%s" % [OUT_DIR, direction]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(here))

		# 0번은 서 있는 자세다(`_frames.gd`가 그렇게 읽는다).
		_draw(direction, 0.0, 0.0).save_png("%s/0.png" % here)
		for i in STEPS.size():
			var step: Array = STEPS[i]
			_draw(direction, step[0], step[1]).save_png("%s/%d.png" % [here, i + 1])
		print("%-6s 5장" % direction)
	print("저장: %s" % OUT_DIR)
	quit()


func _draw(direction: String, stride: float, lift: float) -> Image:
	var image := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	var profile: Array = NARROW if direction in ["east", "west"] else WIDE
	var flip := direction == "west"

	_boots(image, direction, stride)
	_cloak(image, profile, lift, flip)
	_hood(image, direction, profile, lift, flip)
	_edge(image)
	return image


## 망토. 위에서 아래로 갈수록 벌어지고, 왼쪽이 빛을 받는다.
func _cloak(image: Image, profile: Array, lift: float, flip: bool) -> void:
	for y in range(int(TOP), int(FOOT)):
		var half := _half(profile, float(y))
		if half <= 0.0:
			continue
		for x in range(int(CX - half), int(CX + half) + 1):
			var side := (float(x) - CX) / maxf(half, 1.0)
			if flip:
				side = -side
			var colour := MID
			if side < -0.35:
				colour = LIGHT
			elif side > 0.45:
				colour = DARK
			image.set_pixel(x, y - int(lift), colour)


## 두건. 앞모습에는 속이 뚫린 어둠이 있고, 뒷모습에는 없다.
func _hood(image: Image, direction: String, profile: Array, lift: float, flip: bool) -> void:
	var hollow_from := 14.0
	var hollow_to := 20.0
	for y in range(int(TOP), int(hollow_to)):
		var half := _half(profile, float(y))
		if half <= 0.0:
			continue
		for x in range(int(CX - half), int(CX + half) + 1):
			var side := (float(x) - CX) / maxf(half, 1.0)
			if flip:
				side = -side
			var colour := MID if side > -0.35 else LIGHT
			image.set_pixel(x, y - int(lift), colour)

	if direction == "north":
		return  # 뒤에서는 두건 속이 안 보인다

	# 속을 판다. 옆모습은 얼굴이 옆을 향하므로 한쪽으로 치우친다.
	var shift := 0.0
	if direction == "east":
		shift = 1.5
	elif direction == "west":
		shift = -1.5
	for y in range(int(hollow_from), int(hollow_to)):
		var half := (2.5 if direction in ["east", "west"] else 3.0)
		for x in range(int(CX + shift - half), int(CX + shift + half) + 1):
			image.set_pixel(x, y - int(lift), HOLLOW)

	# 뼈색 테두리. **이 한 줄이 인물을 알아보게 하는 표시다** - 없으면 검은 덩어리가 된다.
	for y in range(int(hollow_from) - 1, int(hollow_to)):
		var half := (2.5 if direction in ["east", "west"] else 3.0)
		image.set_pixel(int(CX + shift - half) - 1, y - int(lift), TRIM)
		image.set_pixel(int(CX + shift + half) + 1, y - int(lift), TRIM)
	for x in range(int(CX + shift - 3.5), int(CX + shift + 4)):
		image.set_pixel(x, int(hollow_from - 2 - lift), TRIM)


## 두 발. 걸음에 따라 앞뒤로 어긋난다.
func _boots(image: Image, direction: String, stride: float) -> void:
	var apart := 3.0 if direction in ["east", "west"] else 4.0
	var offsets := [stride, -stride]
	for i in 2:
		var at: float = CX + (apart if i == 0 else -apart) * 0.5
		var drop: float = offsets[i] if direction in ["east", "west"] else 0.0
		var back: float = 0.0 if direction in ["east", "west"] else offsets[i]
		for y in range(int(FOOT - 3 + back), int(FOOT + 1 + back)):
			for x in range(int(at - 1.5 + drop), int(at + 1.5 + drop)):
				if x >= 0 and x < W and y >= 0 and y < H:
					image.set_pixel(x, y, BOOT)


## 그려진 것의 바깥 한 줄을 어둡게 두른다. 작은 그림은 외곽선이 형태를 잡아준다.
func _edge(image: Image) -> void:
	var before := image.duplicate() as Image
	for y in H:
		for x in W:
			if before.get_pixel(x, y).a >= 0.5:
				continue
			if _touches(before, x, y):
				image.set_pixel(x, y, OUTLINE)


func _touches(image: Image, x: int, y: int) -> bool:
	var steps: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for step in steps:
		var at: Vector2i = Vector2i(x, y) + step
		if at.x < 0 or at.y < 0 or at.x >= W or at.y >= H:
			continue
		if image.get_pixel(at.x, at.y).a >= 0.5:
			return true
	return false


func _half(profile: Array, y: float) -> float:
	for i in range(profile.size() - 1):
		var a: Array = profile[i]
		var b: Array = profile[i + 1]
		if y <= b[0]:
			return lerpf(a[1], b[1], (y - a[0]) / (b[0] - a[0]))
	return profile[-1][1]
