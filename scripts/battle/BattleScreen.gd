extends Node
class_name BattleScreen

## 전투 화면. `Battle`(로직)의 시그널만 구독하고 행동 함수만 부른다 - 로직은 이 화면을 모른다.
##
## 이 화면이 하는 일 중 제일 중요한 것은 **등불 밝기를 화면 전체로 흘려보내는 것**이다.
## 밝기가 바뀌면 배경과 적이 같이 색을 잃고 같이 어두워지고, **메뉴의 빛줄기까지 함께 흐려진다.**
## 그래서 남은 기름을 나타내는 눈금이 따로 필요 없다 - 화면이 곧 게이지다.

const ENEMY_PATH := "res://resources/hollow_armour.tres"

const ENEMY_POSITION := Vector2(480, 176)
const LAMP_POSITION := Vector2(480, 444)  ## 빛줄기가 뻗어나오는 자리와 같다

## 상자를 두르지 않는다. 화면 대부분이 어둠이라 글자만 놓아도 읽히고, 상자를 두르면
## UI만 덩어리로 커 보인다. 여기 숫자는 글자가 놓이는 자리다.
const STATUS_AT := Vector2(14, 12)
const CONDITION_AT := Rect2(600, 12, 346, 44)   ## 오른쪽 정렬이라 폭이 필요하다
const LOG_AT := Rect2(14, 300, 932, 44)
const LOG_LINES := 2

## 글자가 놓이는 자리. 빛은 이 자리를 지나 더 뻗어서 글자를 품는다.
## 가운데(적과 등불)를 비우고 좌우로 갈라 놓는다.
const ACTIONS := [
	{"text": "공격", "anchor": Vector2(252, 400)},
	{"text": "방어", "anchor": Vector2(282, 498)},
	{"text": "대화", "anchor": Vector2(708, 400)},
	{"text": "도주", "anchor": Vector2(678, 498)},
]

@onready var _background: FilteredBackground = $Background
@onready var _enemy_sprite: FilteredSprite = $Enemy
@onready var _lamp: LampGlow = $Lamp

var _battle: Battle
var _lines: PackedStringArray = PackedStringArray()

var _ui: CanvasLayer
var _status_label: Label
var _condition_label: Label
var _log_label: Label
var _menu: LightMenu
var _lamp_buttons: Array[Button] = []


func _ready() -> void:
	var enemy: EnemyDef = load(ENEMY_PATH)
	_enemy_sprite.texture = enemy.texture
	_enemy_sprite.position = ENEMY_POSITION
	_lamp.position = LAMP_POSITION

	_battle = Battle.new(enemy)
	_battle.message.connect(_append_line)
	_battle.state_changed.connect(_refresh)
	_battle.finished.connect(_on_finished)

	_build_ui()
	_append_line("%s이(가) 앞을 막아섰다." % enemy.display_name)
	_refresh()

	if "--capture" in OS.get_cmdline_user_args():
		_capture_brightness_and_quit()


# --- 화면 만들기 ---

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 101
	add_child(_ui)

	_status_label = _make_label(Rect2(STATUS_AT, Vector2.ZERO), HORIZONTAL_ALIGNMENT_LEFT)
	_condition_label = _make_label(CONDITION_AT, HORIZONTAL_ALIGNMENT_RIGHT)
	_log_label = _make_label(LOG_AT, HORIZONTAL_ALIGNMENT_LEFT)
	_condition_label.add_theme_color_override("font_color", UiStyle.TEXT_DIM)

	_build_lamp_buttons()

	_menu = LightMenu.new()
	_menu.setup(ACTIONS)
	_menu.chosen.connect(_on_action_chosen)
	_ui.add_child(_menu)


func _make_label(rect: Rect2, alignment: int) -> Label:
	var label := Label.new()
	KoreanFont.apply(label)
	label.add_theme_color_override("font_color", UiStyle.TEXT)
	label.horizontal_alignment = alignment
	label.position = rect.position
	if rect.size.x > 0.0:
		label.size = rect.size
	_ui.add_child(label)
	return label


## 등불 조절은 **행동이 아니다.** 그래서 빛줄기 메뉴에 섞지 않고 상태창 아래에 따로 둔다 -
## 같이 두면 "이것도 턴을 쓰나?" 하고 헷갈린다.
func _build_lamp_buttons() -> void:
	var row := HBoxContainer.new()
	row.position = STATUS_AT + Vector2(-4, 78)
	row.add_theme_constant_override("separation", 12)
	_ui.add_child(row)

	for entry in [["- 어둡게", Callable(self, "_on_dim")], ["밝게 +", Callable(self, "_on_brighten")]]:
		var button := Button.new()
		button.text = entry[0]
		KoreanFont.apply(button)
		UiStyle.style_flat_button(button)
		button.focus_mode = Control.FOCUS_NONE  # 빛줄기 메뉴의 방향키 조작에 끼어들지 않게
		button.pressed.connect(entry[1])
		row.add_child(button)
		_lamp_buttons.append(button)


# --- 입력 ---

func _on_action_chosen(index: int) -> void:
	match index:
		0: _battle.attack()
		1: _battle.guard()
		2: _battle.talk()
		3: _battle.flee()


func _on_dim() -> void:
	_battle.dim()


func _on_brighten() -> void:
	_battle.brighten()


# --- 전투가 알려오는 것 ---

func _append_line(text: String) -> void:
	_lines.append(text)
	while _lines.size() > LOG_LINES:
		_lines.remove_at(0)
	_log_label.text = "\n".join(_lines)


func _refresh() -> void:
	var lantern := _battle.lantern
	_status_label.text = "체력  %d/%d\n기름  %d\n등불  %s" % [
		_battle.player_hp, Battle.PLAYER_MAX_HP, lantern.oil, lantern.level_name()
	]
	_condition_label.text = "%s\n%s" % [_battle.enemy.display_name, _battle.enemy_condition()]

	# 세상은 어두워지고 색을 잃는다.
	var desaturate: float = Lantern.DESATURATE[lantern.level]
	var brightness: float = Lantern.BRIGHTNESS[lantern.level]
	_set_light(_background, desaturate, brightness)
	_set_light(_enemy_sprite, desaturate, brightness)

	# 반대로 불빛 자체는 어두울수록 도드라진다. 세상이 죽을수록 내 등불만 살아남는다.
	var intensity: float = Lantern.LIGHT_INTENSITY[lantern.level]
	# 그리고 **빛의 색이 곧 내 체력이다.** 다칠수록 붉어진다 - 체력 눈금을 화면으로 옮긴 것.
	var health := float(_battle.player_hp) / float(Battle.PLAYER_MAX_HP)
	var lamp_colour := UiStyle.lamp_colour(health)

	_menu.light = intensity
	_menu.colour = lamp_colour

	var glow: int = Lantern.GLOW_SIZE[lantern.level]
	_lamp.visible = intensity > 0.0
	if _lamp.visible:
		_lamp.glow_size = glow
		_lamp.self_modulate = Color(1.0, 1.0, 1.0, intensity)
		_lamp.core_color = Color(lamp_colour.r, lamp_colour.g, lamp_colour.b, 0.95)
		_lamp.edge_color = UiStyle.lamp_edge_colour(health) * Color(1.0, 1.0, 1.0, 0.0)


func _set_light(node: CanvasItem, desaturate: float, brightness: float) -> void:
	if not node.material is ShaderMaterial:
		return
	node.material.set_shader_parameter("desaturate", desaturate)
	node.material.set_shader_parameter("layer_modulate", Color(brightness, brightness, brightness, 1.0))


func _on_finished(outcome: String) -> void:
	const CLOSING := {
		"victory": "정적이 돌아왔다.",
		"defeat": "등불이 바닥에 떨어졌다.",
		"talked": "길이 열렸다.",
		"fled": "숨이 가라앉을 때까지 달렸다.",
	}
	_append_line(CLOSING.get(outcome, ""))
	_menu.enabled = false
	for button in _lamp_buttons:
		button.disabled = true


## 확인용. `-- --capture`로 실행하면 등불 단계를 위에서부터 한 장씩 찍고 끝낸다.
## 밝기가 화면에 제대로 먹는지는 눈으로 봐야 알 수 있어서 남겨둔다.
func _capture_brightness_and_quit() -> void:
	var crt: CrtOverlay = $Crt
	crt.visible = false

	while _battle.lantern.level < Lantern.Level.BRIGHT:
		_battle.brighten()
	for step in Lantern.NAMES.size():
		var index: int = Lantern.NAMES.size() - 1 - step
		await _shoot("res://tools/_battle_%d.png" % index)
		_battle.dim()

	# CRT를 끈 것과 켠 것. 어느 쪽이 나은지 눈으로 고르려고 같은 장면을 두 번 찍는다.
	while _battle.lantern.level < Lantern.Level.DIM:
		_battle.brighten()
	await _shoot("res://tools/_crt_off.png")
	crt.visible = true
	await _shoot("res://tools/_crt_on.png")
	get_tree().quit()


## 프레임을 두 번 기다리는 이유: CRT 오버레이가 화면 텍스처를 다시 읽는데, 그 복사가 끝나기 전에
## 뷰포트를 통째로 가져가면 드라이버가 죽는다(2026-08-11, 힙 손상으로 즉시 종료).
func _shoot(path: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
