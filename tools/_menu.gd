extends Node

## 빛줄기 메뉴만 **검은 바탕에 따로** 그려서 폭을 잰다.
##
## 실제 화면에서는 어둠·디더·등불 빛무리가 겹쳐서 "어느 줄기가 두꺼운가"를 눈으로 못 가린다.
## 여기서는 메뉴 하나만 세우고, 각도별 밝기를 숫자로 뽑는다.
##
##   Godot_v4.7.1-stable_win64.exe --path . res://tools/_menu.tscn

const OUT := "res://tools/_menu.png"
const ORIGIN := Vector2(44, 428)

var _menu: LightMenu
var _n := 0


func _ready() -> void:
	var back := ColorRect.new()
	back.color = Color.BLACK
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)

	_menu = LightMenu.new()
	_menu.origin = ORIGIN
	add_child(_menu)
	# `BattleHud`와 같은 부챗살을 세운다.
	var names := BattleHud.ACTION_NAMES + [BattleHud.FLEE_NAME]
	var spread: Array = []
	for i in names.size():
		var along: float = float(i) / float(names.size() - 1)
		var angle: float = deg_to_rad(lerpf(BattleHud.FAN_FROM, BattleHud.FAN_TO, along))
		spread.append({
			"text": names[i],
			"anchor": (ORIGIN + Vector2(cos(angle), sin(angle)) * BattleHud.FAN_REACH).round(),
		})
	_menu.setup(spread)
	# **골라진 줄기를 눈으로 보려고** 하나를 집어 둔다. 실제 게임에서는 마우스·방향키가 정한다.
	_menu._index = 3   # 방어


func _process(_delta: float) -> void:
	_n += 1
	if _n < 8:
		return
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT))
	_measure(img)
	get_tree().quit()


## 등불에서 같은 거리에 있는 점들의 밝기를 각도별로 찍는다.
func _measure(img: Image) -> void:
	print("\n각도별 밝기 (0~9). 부챗살은 %d도 ~ %d도, 줄기 사이는 %.1f도"
		% [int(BattleHud.FAN_FROM), int(BattleHud.FAN_TO),
			(BattleHud.FAN_TO - BattleHud.FAN_FROM) / 4.0])
	for radius in [90.0, 150.0, 210.0]:
		var line := ""
		var deg := -88.0
		while deg <= 32.0:
			var at: Vector2 = ORIGIN + Vector2(cos(deg_to_rad(deg)), sin(deg_to_rad(deg))) * radius
			if at.x < 0.0 or at.y < 0.0 or at.x >= img.get_width() or at.y >= img.get_height():
				line += "."
				deg += 1.0
				continue
			var c: Color = img.get_pixelv(Vector2i(at))
			line += str(clampi(int(round((c.r + c.g + c.b) / 3.0 * 9.0)), 0, 9))
			deg += 1.0
		print("  r=%3d  %s" % [int(radius), line])
	print("         ^-88도" + " ".repeat(105) + "+32도^")
	# 줄기가 놓인 각도를 같이 찍어 준다.
	var marks := ""
	for i in 5:
		marks += "%.1f  " % lerpf(BattleHud.FAN_FROM, BattleHud.FAN_TO, float(i) / 4.0)
	print("  줄기 각도: %s" % marks)
