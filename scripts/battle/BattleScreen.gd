extends Node
class_name BattleScreen

## **전투만 따로 켜 보는 시험대**다. 실제 전투는 조우 화면(`Encounter`) 위에 그대로 얹히므로
## (`BattleStage`) 이 씬을 거치지 않는다 - 여기는 8초를 걷지 않고 바로 전투를 보고 싶을 때,
## 그리고 등불 밝기가 화면에 어떻게 먹는지 확인용으로 찍을 때 쓴다.
##
## 화면을 만드는 일은 하나도 안 한다. 무대와 글자는 `BattleStage`/`BattleHud`가 갖고 있고,
## 여기는 **그것과 등불을 어디에 세워 둘지**만 정한다.

## 첫 조우 상대는 아카식 서고를 지키는 것이다(2026-08-13). 속 빈 갑옷은
## `resources/hollow_armour.tres`에 그대로 있으니 여기 한 줄만 되돌리면 된다.
const ENEMY_PATH := "res://resources/watcher.tres"

## 조우가 끝난 그 자리에서 시작한다. 무대가 여기서 좌우로 옮겨 앉힌다.
const ENEMY_START := Vector2(480, 190)
const LAMP_START := Vector2(480, 453)

@onready var _background: FilteredBackground = $Background
@onready var _enemy_sprite: FilteredSprite = $Enemy
@onready var _lamp: LampGlow = $Lamp

var _stage: BattleStage


func _ready() -> void:
	var enemy: EnemyDef = load(ENEMY_PATH)
	_enemy_sprite.texture = enemy.texture
	_enemy_sprite.position = ENEMY_START
	_lamp.position = LAMP_START

	_stage = BattleStage.new()
	add_child(_stage)
	# 여기엔 주인공 그림이 없다. 무대는 없으면 없는 대로 돌아간다.
	_stage.begin([enemy], _enemy_sprite, null, _lamp, _background)

	if "--capture" in OS.get_cmdline_user_args():
		_capture_brightness_and_quit()


## 확인용. `-- --capture`로 실행하면 등불 단계를 위에서부터 한 장씩 찍고 끝낸다.
## 밝기가 화면에 제대로 먹는지는 눈으로 봐야 알 수 있어서 남겨둔다.
func _capture_brightness_and_quit() -> void:
	var crt: CrtOverlay = $Crt
	crt.visible = false
	# 무대가 좌우로 옮겨 앉고 글자를 띄울 때까지 기다린다.
	await get_tree().create_timer(BattleStage.MOVE_FOR + 0.2).timeout
	var battle: Battle = _stage.battle

	# 밝기 단계는 이제 게이지에서 파생된다. 단계마다 게이지를 그 구간 값으로 직접 놓는다.
	var bands: Array = [90, 60, 35, 10, 0]   # 환함 -> 꺼짐
	for step in bands.size():
		var index: int = bands.size() - 1 - step
		battle.lantern.light = bands[step]
		battle.state_changed.emit()
		await _shoot("res://tools/_battle_%d.png" % index)

	# CRT를 끈 것과 켠 것. 어느 쪽이 나은지 눈으로 고르려고 같은 장면을 두 번 찍는다.
	battle.lantern.light = 35
	battle.state_changed.emit()
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
