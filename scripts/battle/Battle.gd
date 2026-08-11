extends RefCounted
class_name Battle

## 전투 한 판의 진행. **화면을 전혀 모른다** - 시그널만 쏘고, 행동 함수만 받는다.
## 대사 시스템이 `DialogueController`(로직)와 `DialogueUI`(화면)로 나뉜 것과 같은 구조다.
## 그래서 화면을 통째로 갈아엎어도 여기는 손댈 일이 없다.
##
## 한 턴은 이렇게 흐른다.
##   플레이어 행동 → 기름 소모 → 적 행동(+ 다음 큰 공격 예고) → 반복
## 등불 밝기를 바꾸는 것은 행동이 아니라서 이 흐름에 끼지 않는다.

signal message(text: String)          ## 전투 기록에 한 줄 추가
signal state_changed()                ## 체력/기름/밝기가 바뀜 - 화면 갱신용
signal finished(outcome: String)      ## "victory" / "defeat" / "talked" / "fled"

const PLAYER_MAX_HP := 40
const PLAYER_DAMAGE_MIN := 6
const PLAYER_DAMAGE_MAX := 10

var enemy: EnemyDef
var lantern := Lantern.new()
var player_hp: int = PLAYER_MAX_HP
var enemy_hp: int
var is_over: bool = false

var _enemy_winding_up: bool = false  ## 적이 큰 공격을 준비 중
var _guarding: bool = false
var _talk_index: int = 0


func _init(enemy_def: EnemyDef) -> void:
	enemy = enemy_def
	enemy_hp = enemy.max_hp


# --- 밝기 조절 (행동을 쓰지 않는다) ---

func brighten() -> void:
	if is_over:
		return
	lantern.brighten()
	state_changed.emit()


func dim() -> void:
	if is_over:
		return
	lantern.dim()
	state_changed.emit()


# --- 행동 (턴을 소비한다) ---

func attack() -> void:
	if is_over:
		return
	if randf() < lantern.player_hit():
		var dealt := randi_range(PLAYER_DAMAGE_MIN, PLAYER_DAMAGE_MAX)
		enemy_hp -= dealt
		message.emit("칼이 파고들었다. (%d)" % dealt)
	else:
		message.emit("헛손질했다.")
	_end_player_turn()


func guard() -> void:
	if is_over:
		return
	_guarding = true
	message.emit("몸을 낮추고 다음 수를 기다렸다.")
	_end_player_turn()


## 말을 걸 때마다 정해진 대사가 순서대로 나오고, 다 떨어지면 통하거나 안 통한다.
## 통하는 조건에 등불이 걸려 있어서, **설득에도 기름값이 든다.**
func talk() -> void:
	if is_over:
		return
	if _talk_index < enemy.talk_lines.size():
		message.emit(enemy.talk_lines[_talk_index])
		_talk_index += 1
		_end_player_turn()
		return

	if not enemy.talk_needs_light or lantern.can_read_enemy():
		message.emit(enemy.talk_success_line)
		_finish("talked")
	else:
		message.emit(enemy.talk_fail_line)
		_end_player_turn()


func flee() -> void:
	if is_over:
		return
	if randf() < lantern.flee_chance():
		message.emit("등을 돌리고 달아났다.")
		_finish("fled")
	else:
		message.emit("발이 떨어지지 않았다.")
		_end_player_turn()


# --- 상태를 말로 옮기는 것 ---

## 적 체력을 숫자로 보여주지 않는다. 눈금이 보이면 계산이 되고, 계산이 되면 무섭지 않다.
func enemy_condition() -> String:
	var ratio := float(enemy_hp) / float(enemy.max_hp)
	if ratio > 0.66:
		return "멀쩡하다"
	if ratio > 0.33:
		return "금이 갔다"
	return "무너지기 직전이다"


# --- 내부 ---

func _end_player_turn() -> void:
	if enemy_hp <= 0:
		message.emit("%s이(가) 무너져 내렸다." % enemy.display_name)
		_finish("victory")
		return

	lantern.burn()
	_enemy_turn()
	_guarding = false

	if player_hp <= 0:
		_finish("defeat")
		return
	state_changed.emit()


func _enemy_turn() -> void:
	if _enemy_winding_up:
		_enemy_winding_up = false
		_strike(enemy.heavy_damage, "%s이(가) 내리쳤다." % enemy.display_name)
		return

	_strike(randi_range(enemy.damage_min, enemy.damage_max), "%s이(가) 덤벼들었다." % enemy.display_name)
	if player_hp <= 0:
		return
	if randf() < enemy.heavy_chance:
		_enemy_winding_up = true
		# 어두우면 아무 말도 안 뜬다 - 뭐가 올지 모른 채로 다음 턴을 맞는다.
		if lantern.can_read_enemy():
			message.emit(enemy.telegraph_line)


func _strike(amount: int, description: String) -> void:
	if randf() >= lantern.enemy_hit():
		message.emit("%s 빗나갔다." % description)
		return
	var taken := amount
	var guarded := ""
	if _guarding:
		taken = int(ceil(amount * 0.5))
		guarded = " 막아냈다."
	player_hp = maxi(player_hp - taken, 0)
	message.emit("%s%s (%d)" % [description, guarded, taken])


func _finish(outcome: String) -> void:
	is_over = true
	state_changed.emit()
	finished.emit(outcome)
