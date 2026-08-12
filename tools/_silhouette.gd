extends SceneTree

## 등불을 든 순례자의 실루엣을 찍는다. 통짜 검정이라 **윤곽만 맞으면 되는** 그림이라서
## 손으로 안 그리고 코드로 찍는다. 마음에 안 들면 숫자만 고쳐 다시 돌리면 되고 비용도 없다.
##
## 뒷모습이다. 관문을 마주 보고 서 있고, 등불은 오른손에 늘어뜨렸다. 등불이 몸통 밖으로
## 나와야 보인다 - 팔을 몸에 붙이면 실루엣 안에 먹혀서 사라진다.
##
## `--headless --script res://tools/_silhouette.gd`

const OUTPUT := "res://assets/photos/pilgrim.png"

const W := 44
const H := 80

## 머리 꼭대기와 발끝. 키는 이 둘의 차이(72px)다.
const TOP := 4.0
const FOOT := 76.0

## 세로 위치별 몸통 반폭. 두건 -> 목에서 살짝 들어감 -> 어깨 -> 아래로 갈수록 벌어지는 망토.
## **목의 잘록함이 사람으로 읽히게 하는 유일한 단서다.** 이게 없으면 그냥 종 모양이 된다.
const OUTLINE := [
	[4.0, 0.0], [5.0, 2.2], [6.0, 3.4], [9.0, 4.8], [12.0, 5.2],
	[15.0, 4.6], [18.0, 4.6],
	[21.0, 7.8], [28.0, 8.4], [42.0, 9.2], [58.0, 10.0],
	[70.0, 11.0], [74.0, 11.6], [76.0, 12.0],
]

const CENTRE_X := 18.0
## 서 있는 자세가 뻣뻣하지 않게 아주 조금 휘어준다.
const SWAY := 0.8

## 등불을 든 팔. **몸통 바깥으로 확실히 내밀어야 한다** - 처음에 팔을 몸에 붙였더니 등불이
## 실루엣에 먹혀서 옆구리의 혹으로만 보였다. 관문 쪽으로 등불을 들어 보이는 자세이기도 하다.
const SHOULDER := Vector2(24.0, 24.0)
const HAND := Vector2(34.0, 31.0)


func _init() -> void:
	var image := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			if _inside(float(x) + 0.5, float(y) + 0.5):
				image.set_pixel(x, y, Color(0, 0, 0, 1))
	image.save_png(OUTPUT)
	print("저장: %s  (%dx%d, 키 %d)" % [OUTPUT, W, H, int(FOOT - TOP)])
	print("등불 자리(그림 안 좌표): %.1f, %.1f" % [HAND.x + 0.5, HAND.y + 7.0])
	quit()


func _inside(x: float, y: float) -> bool:
	return _body(x, y) or _arm(x, y) or _lantern(x, y)


func _body(x: float, y: float) -> bool:
	if y < TOP or y > _hem(x):
		return false
	var lean := CENTRE_X - sin((y - TOP) / (FOOT - TOP) * PI) * SWAY
	return absf(x - lean) <= _half(y)


## 망토 아랫단. 자로 그은 듯 평평하면 잘라 붙인 티가 난다. 다만 주기가 하나면 빗살처럼
## 규칙적인 톱니가 되므로, 주기가 안 맞는 둘을 겹쳐 불규칙하게 만든다.
func _hem(x: float) -> float:
	return FOOT - absf(sin(x * 0.9)) * 0.7 - absf(sin(x * 2.3)) * 0.5


func _half(y: float) -> float:
	for i in range(OUTLINE.size() - 1):
		var a: Array = OUTLINE[i]
		var b: Array = OUTLINE[i + 1]
		if y <= b[0]:
			return lerpf(a[1], b[1], (y - a[0]) / (b[0] - a[0]))
	return OUTLINE[-1][1]


## 어깨에서 손까지. 굵기 2px.
func _arm(x: float, y: float) -> bool:
	var along: Vector2 = HAND - SHOULDER
	var t: float = clampf((Vector2(x, y) - SHOULDER).dot(along) / along.length_squared(), 0.0, 1.0)
	return (Vector2(x, y) - (SHOULDER + along * t)).length() <= 1.6


## 손에 매달린 등불. 뚜껑 / 몸통 / 받침 세 덩이로 나눠야 이 크기에서도 등불로 읽힌다.
func _lantern(x: float, y: float) -> bool:
	var cx := HAND.x + 0.5
	if _box(x, y, cx, 3.5, HAND.y + 1.0, HAND.y + 3.0):    # 뚜껑
		return true
	if _box(x, y, cx, 2.5, HAND.y + 3.0, HAND.y + 11.0):   # 몸통
		return true
	if _box(x, y, cx, 3.5, HAND.y + 11.0, HAND.y + 13.0):  # 받침
		return true
	return false


func _box(x: float, y: float, cx: float, half: float, top: float, bottom: float) -> bool:
	return absf(x - cx) <= half and y >= top and y < bottom
