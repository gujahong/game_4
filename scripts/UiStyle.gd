extends RefCounted
class_name UiStyle

## 화면 스타일을 한곳에 모아둔다. 대사창과 전투 화면이 같은 물건을 쓰게 해서, 톤을 바꾸고
## 싶을 때 두 곳을 따로 고치지 않도록 한다.
##
## **색을 아껴 쓴다.** 이 게임 화면은 "쨍한 것만 색이 남는" 규칙 위에 서 있어서, UI까지
## 알록달록하면 규칙이 깨진다. 살아 있는 색은 등불색 하나뿐이고, 그것도 "지금 고르고 있는 것"
## 에만 쓴다.

const PANEL_BG := Color(0.04, 0.04, 0.05, 0.84)
const PANEL_BORDER := Color(0.55, 0.55, 0.58, 0.5)
const TEXT := Color(0.87, 0.87, 0.85)
const TEXT_DIM := Color(0.66, 0.66, 0.7)

## 등불색. 화면에서 강조는 전부 이 색으로 통일한다.
##
## **등불 색이 곧 체력이다.** 다칠수록 붉어진다 - 눈금 대신 화면으로 알리는 것이라, 적 체력을
## 숫자로 안 보여주기로 한 것과 같은 방향이다. 피가 마를수록 내 불이 핏빛이 된다.
const LAMP := Color(1.0, 0.71, 0.33)       ## 성할 때
const LAMP_EDGE := Color(1.0, 0.45, 0.10)  ## 빛이 스러지는 가장자리
const LAMP_HURT := Color(1.0, 0.26, 0.16)  ## 다 죽어갈 때
const LAMP_HURT_EDGE := Color(0.86, 0.06, 0.04)


## 체력 비율(0~1)에 맞는 등불색. 0.75 제곱을 씌운 이유는, 선형으로 섞으면 조금만 다쳐도
## 벌써 벌겋게 보여서 "위험하다"는 신호가 헐거워지기 때문이다.
static func lamp_colour(health_ratio: float) -> Color:
	return LAMP_HURT.lerp(LAMP, pow(clampf(health_ratio, 0.0, 1.0), 0.75))


static func lamp_edge_colour(health_ratio: float) -> Color:
	return LAMP_HURT_EDGE.lerp(LAMP_EDGE, pow(clampf(health_ratio, 0.0, 1.0), 0.75))

const BUTTON_BG := Color(0.05, 0.05, 0.06, 0.88)
const BUTTON_BG_LIT := Color(0.1, 0.09, 0.07, 0.94)
const BUTTON_BORDER := Color(0.42, 0.42, 0.45, 0.6)
const BUTTON_BORDER_LIT := Color(1.0, 0.71, 0.33, 0.9)
const BUTTON_TEXT := Color(0.78, 0.78, 0.76)
const BUTTON_TEXT_LIT := Color(1.0, 0.89, 0.7)


static func panel_box(margin: int = 9) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL_BG
	box.border_color = PANEL_BORDER
	box.set_border_width_all(1)
	box.set_content_margin_all(margin)
	return box


## 정해진 자리에 놓이는 패널 하나. 컨테이너에 안 넣고 좌표로 직접 놓는다 - 640x360은
## 좁아서 자동 배치보다 손으로 잡는 편이 낫다.
static func make_panel(rect: Rect2, margin: int = 9) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", panel_box(margin))
	return panel


## Godot 기본 버튼(둥근 회색 막대)을 이 게임 톤으로 갈아입힌다. "focus"까지 덮어쓰는 이유는
## 기본 테마의 포커스 테두리가 남으면 키보드로 고를 때 파란 사각형이 튀기 때문이다.
static func style_button(button: Button) -> void:
	var idle := _button_box(BUTTON_BG, BUTTON_BORDER)
	var lit := _button_box(BUTTON_BG_LIT, BUTTON_BORDER_LIT)
	button.add_theme_stylebox_override("normal", idle)
	button.add_theme_stylebox_override("hover", lit)
	button.add_theme_stylebox_override("pressed", lit)
	button.add_theme_stylebox_override("focus", lit)
	button.add_theme_stylebox_override("disabled", idle)
	button.add_theme_color_override("font_color", BUTTON_TEXT)
	button.add_theme_color_override("font_hover_color", BUTTON_TEXT_LIT)
	button.add_theme_color_override("font_pressed_color", BUTTON_TEXT_LIT)
	button.add_theme_color_override("font_focus_color", BUTTON_TEXT_LIT)
	button.add_theme_color_override("font_disabled_color", TEXT_DIM)


## 상자 없는 버튼. 글자만 있고, 가리키면 등불색으로 살아난다.
##
## 화면 대부분이 어둠이라 상자를 두를 이유가 없다. 상자를 두르면 UI만 덩어리로 커 보이고,
## "UI는 등불이 비추는 것"이라는 화면 규칙과도 어긋난다.
static func style_flat_button(button: Button) -> void:
	var blank := StyleBoxEmpty.new()
	for slot in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(slot, blank)
	button.add_theme_color_override("font_color", TEXT_DIM)
	button.add_theme_color_override("font_hover_color", LAMP)
	button.add_theme_color_override("font_pressed_color", LAMP)
	button.add_theme_color_override("font_focus_color", LAMP)
	button.add_theme_color_override("font_disabled_color", Color(TEXT_DIM.r, TEXT_DIM.g, TEXT_DIM.b, 0.4))


static func _button_box(bg: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(1)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 3
	box.content_margin_bottom = 3
	return box
