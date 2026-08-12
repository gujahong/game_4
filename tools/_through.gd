extends SceneTree

## 문 너머로 다른 세계가 보이는지 눈으로 확인한다. 도려낸 관문(`gate_4_cut`) 뒤에 다른 그림을
## 놓고 합쳐볼 뿐이고, 게임 코드가 아니다 - 실제로는 노드 두 개를 겹쳐 놓으면 된다.
##
## `--headless --script res://tools/_through.gd`

const GATE := "res://assets/photos/gate_4_cut.png"
const BEHIND := "res://assets/photos/archive.png"
const OUTPUT := "res://tools/_through.png"

## 문 구멍의 가운데(도려낼 때 재둔 값). 뒤 그림을 이 자리에 맞춘다.
const OPENING_X := 0.623
const OPENING_Y := 0.53


func _init() -> void:
	var gate := Image.load_from_file(GATE)
	var behind := Image.load_from_file(BEHIND)
	gate.convert(Image.FORMAT_RGBA8)
	behind.convert(Image.FORMAT_RGBA8)

	var canvas := Image.create_empty(gate.get_width(), gate.get_height(), false, Image.FORMAT_RGBA8)
	canvas.fill(Color.BLACK)

	# 뒤 그림을 문 구멍 가운데에 놓는다. 관문 밖으로 나가는 부분은 알아서 잘린다.
	var at := Vector2i(
		int(gate.get_width() * OPENING_X - behind.get_width() * 0.5),
		int(gate.get_height() * OPENING_Y - behind.get_height() * 0.5)
	)
	canvas.blit_rect(behind, Rect2i(Vector2i.ZERO, behind.get_size()), at)
	canvas.blend_rect(gate, Rect2i(Vector2i.ZERO, gate.get_size()), Vector2i.ZERO)

	canvas.save_png(OUTPUT)
	print("저장: %s" % OUTPUT)
	quit()
