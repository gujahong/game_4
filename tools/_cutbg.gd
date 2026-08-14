extends SceneTree

## 그림 바깥의 배경을 도려낸다. `no_background`를 켜고 뽑았는데도 배경이 딸려 왔을 때 쓴다.
##
## **색으로 고르지 않는다.** 그것의 바깥 고리도 어두워서 색만 보면 같이 지워진다. 대신
## **가장자리에서 이어진 곳만** 지운다 - 배경은 테두리에 닿아 있고 주제는 안 닿아 있다.
##
## `--headless --script res://tools/_cutbg.gd`

## 원본은 손대지 않고 따로 둔다. 문턱을 바꿔 몇 번이고 다시 돌려야 하기 때문이다.
const SOURCE := "res://assets/enemies/watcher_raw.png"
const OUTPUT := "res://assets/enemies/watcher.png"

## 씨앗 색에서 이만큼 안쪽이면 배경으로 본다. 크게 잡으면 주제를 파먹는다.
##
## 0.34로는 귀퉁이만 지워지고 고리 뒤의 올리브색 원반이 남았다. 배경이 한 색이 아니라
## 어두운 귀퉁이에서 밝은 원반으로 번져 있어서다.
## 0.62로는 바깥 오로라까지 먹었다. 낮출수록 덜 지우고 오로라가 더 남는다.
##
## **배경이 검은 화면이라 덜 지워도 손해가 없다.** 남는 것은 어두운 찌꺼기인데 검정 위에서는
## 안 보인다. 오히려 오로라가 잘리는 쪽이 눈에 띈다.
const TOLERANCE := 0.44

## 이 반지름(그림 폭에 대한 비율) 바깥은 무조건 자른다. 0.5면 그림 끝이라 아무것도 안 잘린다.
##
## 0.45로 잡았다가 되돌렸다(2026-08-13). 고리 바깥의 옅은 테를 배경 찌꺼기로 보고 쳐냈는데,
## **검은 화면에 올려놓고 보니 그게 오로라처럼 읽혔다.** 잘라낸 것이 오히려 분위기였다.
const RADIUS := 0.5

## 사방에 두를 투명 여백(픽셀). 일렁임이 미는 폭(26)보다 넉넉해야 안 잘린다.
const PAD := 72


func _init() -> void:
	var image := Image.load_from_file(SOURCE)
	image.convert(Image.FORMAT_RGBA8)
	var w := image.get_width()
	var h := image.get_height()

	# 네 귀퉁이의 평균을 배경색으로 삼는다.
	var seed := Color(0, 0, 0)
	for at in [Vector2i(0, 0), Vector2i(w - 1, 0), Vector2i(0, h - 1), Vector2i(w - 1, h - 1)]:
		var c := image.get_pixel(at.x, at.y)
		seed += Color(c.r * 0.25, c.g * 0.25, c.b * 0.25)

	var seen := {}
	var queue: Array[Vector2i] = []
	for x in w:
		queue.append(Vector2i(x, 0))
		queue.append(Vector2i(x, h - 1))
	for y in h:
		queue.append(Vector2i(0, y))
		queue.append(Vector2i(w - 1, y))

	var wiped := 0
	var steps: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	]
	while not queue.is_empty():
		var at: Vector2i = queue.pop_back()
		if at.x < 0 or at.y < 0 or at.x >= w or at.y >= h or seen.has(at):
			continue
		seen[at] = true
		var c := image.get_pixel(at.x, at.y)
		if c.a < 0.5:
			continue
		if _apart(c, seed) > TOLERANCE:
			continue
		image.set_pixel(at.x, at.y, Color(0, 0, 0, 0))
		wiped += 1
		for step in steps:
			queue.append(at + step)

	# 색으로 못 가르는 나머지는 반지름으로 자른다. 고리 바깥에 옅은 테가 남는데, 그 색이
	# 고리와 비슷해서 문턱을 더 올리면 고리를 파먹는다. **그것이 원형이라 쓸 수 있는 수단이다.**
	var centre := Vector2(float(w), float(h)) * 0.5
	var limit: float = float(w) * RADIUS
	for y in h:
		for x in w:
			if image.get_pixel(x, y).a < 0.5:
				continue
			if Vector2(float(x), float(y)).distance_to(centre) <= limit:
				continue
			image.set_pixel(x, y, Color(0, 0, 0, 0))
			wiped += 1

	# **투명 여백을 두른다.** 일렁임(`AuraRipple`)이 픽셀을 바깥으로 미는데 그림이 여기서
	# 끝나면 밀려난 자리가 경계에서 잘려 **사각형 자국**이 된다. 미는 폭보다 넉넉히 남긴다.
	var roomy := Image.create_empty(w + PAD * 2, h + PAD * 2, false, Image.FORMAT_RGBA8)
	roomy.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(PAD, PAD))
	image = roomy

	image.save_png(OUTPUT)
	print("배경 %d칸을 지웠다 (전체의 %.0f%%)" % [wiped, 100.0 * float(wiped) / float(w * h)])
	quit()


func _apart(a: Color, b: Color) -> float:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
