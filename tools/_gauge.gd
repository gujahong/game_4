extends SceneTree

## 등불 눈금을 여러 상태로 나란히 찍는다. **한 줄만 봐서는 읽히는지 모른다** —
## 가득 찬 것과 다 쓴 것과 꺼진 것이 나란히 있어야 칸이 구별되는지 알 수 있다.
##
##   Godot_v4.7.1-stable_win64.exe --path . --script res://tools/_gauge.gd
##
## 헤드리스로는 안 된다 — 그리질 않으니 찍을 것이 없다.

const OUT := "res://tools/_gauge.png"
const WAIT := 20
const ZOOM := 3          ## 도트를 눈으로 보려고 정수배로 키운다
const ROW := 60
const LEFT := 190

## 보여줄 상태들. [눈금, 이번 턴 마나, 기름병, 설명]
const CASES := [
	[10, 10, 3, "환함 · 다 남았다"],
	[10, 4, 3, "환함 · 여섯 썼다"],
	[6, 6, 2, "중간"],
	[6, 2, 2, "중간 · 넷 썼다"],
	[4, 4, 1, "어두움"],
	[2, 1, 1, "엄청 어두움"],
	[0, 0, 0, "꺼짐 · 주먹질만"],
	[7, 7, 7, "기름이 많을 때"],
]

var _n := 0


func _initialize() -> void:
	var back := ColorRect.new()
	back.color = Color(0.07, 0.06, 0.06)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(back)

	for i in CASES.size():
		var case: Array = CASES[i]
		var top: float = 40.0 + float(i * ROW)

		var name := Label.new()
		name.text = String(case[3])
		name.position = Vector2(20.0, top + 6.0)
		name.add_theme_color_override("font_color", UiStyle.TEXT_DIM)
		name.add_theme_font_size_override("font_size", 15)
		root.add_child(name)

		# **도트를 보려면 키워야 한다.** 눈금 하나가 10px라 그대로 두면 안 읽힌다.
		var frame := Node2D.new()
		frame.position = Vector2(LEFT, top)
		frame.scale = Vector2(ZOOM, ZOOM)
		root.add_child(frame)

		var gauge := LanternGauge.new()
		# 다칠수록 붉어지는 색을 그대로 받는다. 여기서는 성한 색으로 본다.
		gauge.set_state(int(case[0]), int(case[1]), int(case[2]), UiStyle.LAMP)
		frame.add_child(gauge)



func _process(_delta: float) -> bool:
	_n += 1
	if _n < WAIT:
		return false
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT))
	print("저장: %s  (%dx%d)" % [OUT, img.get_width(), img.get_height()])
	return true
