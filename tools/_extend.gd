extends SceneTree

## 그림을 옆으로 늘린다. **가장자리 한 줄을 그대로 죽 미는** 방식이다.
##
## 관문 그림은 왼쪽 끝이 하늘 띠와 바닥 띠라, 그 세로줄을 옆으로 복사하면 자연스럽게 이어진다.
## 생성이 필요 없으므로 **0 generation**이고, 마음에 안 들면 그냥 지우면 된다.
##
## 한계: 가로로 균일한 가장자리에서만 통한다. 왼쪽 지평선의 언덕처럼 튀는 것이 걸리면 띠로
## 늘어난다. 그럴 땐 늘리는 폭을 줄이거나 그 부분만 손으로 지운다.
##
## `--headless --script res://tools/_extend.gd`

const SOURCE := "res://assets/photos/gate_4_cut.png"
const OUTPUT := "res://assets/photos/gate_4_wide.png"
## 왼쪽에 덧붙일 폭(픽셀). 화면을 채우는 데 512가 필요하고(448+512=960), 여는 연출에서
## 옆으로 미는 거리 300만큼을 **더** 붙인다. 딱 960으로 맞추면 미는 동안 그림 끝이 검은
## 수직선으로 드러난다. UI는 이 덧붙인 자리에 올린다.
const ADD_LEFT := 812

## 이음새를 덜 어색하게 만드는 두 장치.
##
## 첫 세로줄을 그대로 복사하면 자로 그은 듯 똑같은 띠가 되어 경계가 드러난다. 그래서
## 가로로 가면서 몇 픽셀씩 위아래로 흔들어 준다(`WOBBLE`). 띠가 굼실거리면 안개처럼 읽힌다.
##
## 그리고 왼쪽 끝으로 갈수록 어둡게 눌러(`EDGE_DIM`) 경계를 어둠에 묻는다. 그 자리에 UI가
## 올라갈 것이므로 어두운 편이 낫기도 하다.
## 흔들기는 아주 약하게만 준다. 3px에 주기 70으로 줬더니 **골판지 같은 결**이 생겨서 오히려
## 더 인공적으로 보였다(2026-08-12). 무늬로 읽히지 않을 만큼만 남긴다.
const WOBBLE := 1.5
const WOBBLE_LENGTH := 240.0
## 대신 어둡게 누르는 쪽을 세게 한다. 왼쪽 끝이 거의 검어지면 이음새가 통째로 묻히고,
## 그 자리에 올라갈 UI 글자도 잘 읽힌다.
const EDGE_DIM := 0.12


func _init() -> void:
	var source := Image.load_from_file(SOURCE)
	source.convert(Image.FORMAT_RGBA8)
	var w := source.get_width()
	var h := source.get_height()

	var wide := Image.create_empty(w + ADD_LEFT, h, false, Image.FORMAT_RGBA8)

	# 왼쪽 여백을 원본의 첫 세로줄로 채우되, 흔들고 어둡게 눌러 이음새를 감춘다.
	for x in ADD_LEFT:
		var toward_seam := float(x) / float(ADD_LEFT)   # 0 = 왼쪽 끝, 1 = 이음새
		var shift := int(round(sin(float(x) / WOBBLE_LENGTH * TAU) * WOBBLE))
		var dim := lerpf(EDGE_DIM, 1.0, toward_seam)
		for y in h:
			var c := source.get_pixel(0, clampi(y + shift, 0, h - 1))
			wide.set_pixel(x, y, Color(c.r * dim, c.g * dim, c.b * dim, c.a))

	wide.blit_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), Vector2i(ADD_LEFT, 0))
	wide.save_png(OUTPUT)

	# 문 구멍 위치는 적어두지 않고 **뚫린 자리를 직접 잰다.** 손으로 옮겨 적으면 잘라내기를
	# 다시 돌렸을 때 조용히 어긋난다.
	var hole := _hole(source)
	var centre := Vector2(hole.position + hole.end) * 0.5
	print("저장: %s  (%dx%d)" % [OUTPUT, wide.get_width(), h])
	print("늘리기 전 문 중심: %.3f, %.3f" % [centre.x / float(w), centre.y / float(h)])
	print("늘린 뒤 문 중심:   %.3f, %.3f  <- Opening.OPENING 에 넣을 값"
		% [(centre.x + float(ADD_LEFT)) / float(w + ADD_LEFT), centre.y / float(h)])
	print("이음새:            %.3f  <- Opening.SEAM 에 넣을 값"
		% (float(ADD_LEFT) / float(w + ADD_LEFT)))
	quit()


## 알파가 0인 자리(=도려낸 문 구멍)를 감싸는 사각형.
func _hole(image: Image) -> Rect2i:
	var min_p := Vector2i(image.get_width(), image.get_height())
	var max_p := Vector2i.ZERO
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.0:
				continue
			min_p = min_p.min(Vector2i(x, y))
			max_p = max_p.max(Vector2i(x, y))
	return Rect2i(min_p, max_p - min_p)
