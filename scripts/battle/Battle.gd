extends RefCounted
class_name Battle

## 전투 한 판의 진행. **화면을 전혀 모른다** - 시그널만 쏘고, 행동 함수만 받는다.
## 대사 시스템이 `DialogueController`(로직)와 `DialogueUI`(화면)로 나뉜 것과 같은 구조다.
## 그래서 화면을 통째로 갈아엎어도 여기는 손댈 일이 없다.
##
## 한 턴은 이렇게 흐른다.
##   플레이어 행동 → 기름 소모 → 살아 있는 적들이 차례로 행동(+ 큰 공격 예고) → 반복
## 등불 밝기를 바꾸는 것은 행동이 아니라서 이 흐름에 끼지 않는다.
##
## **적은 처음부터 여럿을 받는다**(2026-08-14). 지금 서고에서 마주치는 것은 하나뿐이지만,
## 하나만 담을 수 있게 짜 두면 여럿이 나오는 순간 이 파일을 다시 뒤집어야 한다. 목록으로
## 들고 있으면 화면 쪽도 "몇이든 그린다"로 한 번만 짜면 된다.

signal message(text: String)          ## 전투 기록에 한 줄 추가
signal state_changed()                ## 체력/기름/밝기가 바뀜 - 화면 갱신용
signal finished(outcome: String)      ## "victory" / "defeat" / "talked" / "fled"

const PLAYER_DAMAGE_MIN := 6
const PLAYER_DAMAGE_MAX := 10

var enemies: Array[EnemyDef] = []
var hps: PackedInt32Array = PackedInt32Array()   ## 적마다의 남은 체력. `enemies`와 같은 순서다
var lantern := Lantern.new()
## 적에게 맞아 잃은 밝기의 **누적**. 밝기는 칼질·시간으로도 내려가므로, 화면이 "맞았다"만
## 골라 떨게 하려면 맞은 몫을 따로 세어 줘야 한다.
var bruised: int = 0
var is_over: bool = false

var _winding: Array[bool] = []      ## 적마다 큰 공격을 준비 중인가
var _flinching: Array[bool] = []    ## 적마다 다음 차례를 건너뛰는가
var _resting: Array[int] = []       ## 적마다 다음 공격까지 남은 웅크림 턴
var _guarding: bool = false
var _said: Dictionary = {}          ## "적:말길"마다 몇 줄까지 나왔는가
var _watched: int = 0               ## 보기만 하는 것이 몇 번 쳐다봤는가


func _init(defs: Array) -> void:
	for def in defs:
		enemies.append(def)
		hps.append(def.max_hp)
		_winding.append(false)
		_flinching.append(false)
		# 첫 턴은 반드시 웅크림이다. **첫 수는 내가 먼저 두어야** 상대를 살필 틈이 있다.
		_resting.append(maxi(def.pace, 1))


# --- 적 목록을 읽는 것 ---

## 아직 살아 있는 적들의 번호. **고를 수 있는 대상이 곧 이 목록이다.**
func alive() -> PackedInt32Array:
	var out := PackedInt32Array()
	for i in hps.size():
		if hps[i] > 0:
			out.append(i)
	return out


func display_name(target: int) -> String:
	return enemies[target].display_name


## 적 체력을 숫자로 보여주지 않는다. 눈금이 보이면 계산이 되고, 계산이 되면 무섭지 않다.
func enemy_condition(target: int) -> String:
	var ratio := float(hps[target]) / float(enemies[target].max_hp)
	if ratio > 0.66:
		return "멀쩡하다"
	if ratio > 0.33:
		return "금이 갔다"
	return "무너지기 직전이다"


# --- 행동 (턴을 소비한다) ---

## 기름 한 병을 붓는다. **턴을 쓰는 행동이다**(회원님) - 공격 대신 붓는 것이라,
## "지금 부을까 버틸까"가 턴의 선택이 된다. 빈손이면 턴을 안 뺏는다.
func pour_oil() -> void:
	if is_over:
		return
	if not lantern.pour():
		message.emit("기름병이 비었다.")
		state_changed.emit()
		return
	message.emit("기름을 부었다. 불이 차오른다.")
	_end_player_turn()


## target은 `alive()`가 돌려준 번호 중 하나다.
func attack(target: int) -> void:
	if is_over or target < 0 or target >= hps.size() or hps[target] <= 0:
		return
	# **빛이 모자라면 칼이 아예 안 선다**(회원님). 화면이 미리 잠그지만 여기서도 막는다 -
	# 턴을 안 뺏는다. 못 한 것이지 헛한 것이 아니다.
	if not lantern.can_swing():
		message.emit("빛이 모자라 칼이 서지 않는다.")
		state_changed.emit()
		return
	# 휘두르는 값. **맞든 빗나가든 빛은 탄다** - 칼 자체가 빛으로 만든 것이니까.
	lantern.swing()
	if randf() < lantern.player_hit():
		var dealt := randi_range(PLAYER_DAMAGE_MIN, PLAYER_DAMAGE_MAX)
		hps[target] = maxi(hps[target] - dealt, 0)
		message.emit("칼이 파고들었다. (%d)" % dealt)
		if hps[target] <= 0:
			message.emit("%s이(가) 무너져 내렸다." % enemies[target].display_name)
	else:
		message.emit("헛손질했다.")
	_end_player_turn()


func guard() -> void:
	if is_over:
		return
	_guarding = true
	message.emit("몸을 낮추고 다음 수를 기다렸다.")
	_end_player_turn()


## 말을 거는 방법들. **적마다 다르다** - 무엇이 뜰지도, 그것이 무슨 일을 하는지도 적이 정한다.
func talk_options(target: int) -> Array[TalkOption]:
	return enemies[target].talk_options


## 골라서 말을 건다. 같은 것을 다시 고르면 다음 줄이 나오고, 줄이 다 떨어지면 그때 일이 벌어진다.
##
## **규칙은 벌어질 수 있는 일 몇 가지만 안다**(`TalkOption.Effect`). 그중 무엇인지는 리소스가
## 정하므로, 새 적에게 새 말길을 내는 데 이 파일은 안 건드린다.
func talk(target: int, choice: int) -> void:
	if is_over or target < 0 or target >= hps.size() or hps[target] <= 0:
		return
	var options: Array[TalkOption] = enemies[target].talk_options
	if choice < 0 or choice >= options.size():
		return
	var option: TalkOption = options[choice]

	# 어두우면 아무 말도 안 통한다. 턴만 나간다 - **말에도 기름값이 든다.**
	if option.needs_light and not lantern.can_read_enemy():
		message.emit(option.dark_line)
		_end_player_turn()
		return

	var key := "%d:%d" % [target, choice]
	var said: int = _said.get(key, 0)
	if said < option.lines.size():
		message.emit(option.lines[said])
		_said[key] = said + 1
		_end_player_turn()
		return

	if not option.effect_line.is_empty():
		message.emit(option.effect_line)
	match option.effect:
		TalkOption.Effect.OPENS:
			_finish("talked")
			return
		TalkOption.Effect.FLINCH:
			_flinching[target] = true
		TalkOption.Effect.ANGER:
			_winding[target] = true
		TalkOption.Effect.READS:
			message.emit("%s은(는) %s." % [enemies[target].display_name, enemy_condition(target)])
			if _winding[target]:
				message.emit(enemies[target].telegraph_line)
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


# --- 내부 ---

func _end_player_turn() -> void:
	if alive().is_empty():
		_finish("victory")
		return

	# 시간이 태우는 몫. **등불이 꺼지면 진다**(회원님) - 밝기가 곧 목숨이다.
	lantern.burn()
	if lantern.is_out():
		message.emit("등불이 꺼졌다.")
		_finish("defeat")
		return
	for i in alive():
		_enemy_turn(i)
		if lantern.is_out():
			message.emit("등불이 꺼졌다.")
			_finish("defeat")
			return
	_guarding = false
	state_changed.emit()


func _enemy_turn(index: int) -> void:
	var enemy: EnemyDef = enemies[index]
	# **보기만 하는 것은 아무 짓도 안 한다.** 때리지 않는데도 물러설 수 없는 상대다 -
	# 여기 서 있는 한 계속 보고 있고, 그것으로 충분하다.
	if enemy.watches:
		if not enemy.watch_lines.is_empty():
			message.emit(enemy.watch_lines[_watched % enemy.watch_lines.size()])
			_watched += 1
		return
	# 주춤한 것은 이번 차례를 건너뛴다. **한 턴을 벌어 준다** - 말이 통했거나 받아넘긴
	# 것이 이렇게 보인다.
	if _flinching[index]:
		_flinching[index] = false
		message.emit("%s이(가) 잠깐 멈칫한다." % enemy.display_name)
		return

	# **웅크리는 턴.** 적은 매 턴 때리지 않는다(회원님, 2026-08-18) - 공격 전에 반드시
	# 웅크리고, 그 웅크림이 곧 예고다. 밝으면 무엇이 오는지 보이고, 어두우면 낌새만 남는다.
	if _resting[index] > 0:
		_resting[index] -= 1
		if not _winding[index] and randf() < enemy.heavy_chance:
			_winding[index] = true
		if lantern.can_sense_enemy():
			var warning: String = enemy.telegraph_line if _winding[index] else enemy.prep_line
			message.emit(warning if warning != "" else
				"%s이(가) 몸을 웅크린다." % enemy.display_name)
		else:
			message.emit("어둠 속에서 무언가 움직인다.")
		return

	# **공격 턴.** 다음 공격까지의 웅크림을 다시 세워 둔다.
	_resting[index] = maxi(enemy.pace, 1)
	var heavy: bool = _winding[index]
	_winding[index] = false
	var doing: String = ("%s이(가) 내리쳤다." if heavy else "%s이(가) 덤벼들었다.") % enemy.display_name

	# **예고를 보고 방어했으면 받아넘긴다** - 완전 무효에, 적이 크게 휘청여 다음 차례를
	# 잃는다. 맞는 것이 주사위가 아니라 내 읽기 실패가 되는 자리다.
	if _guarding:
		message.emit("%s 받아넘겼다! %s이(가) 크게 휘청인다." % [doing, enemy.display_name])
		_flinching[index] = true
		return
	_strike(enemy.heavy_damage if heavy else randi_range(enemy.damage_min, enemy.damage_max),
		doing)


func _strike(amount: int, description: String) -> void:
	# 예고까지 하고 온 공격이라 웬만하면 맞는다. 피하는 길은 주사위가 아니라 방어다.
	if randf() >= lantern.enemy_hit():
		message.emit("%s 빗나갔다." % description)
		return
	var taken := amount
	# 적의 타격은 **불을 갉는다.** 몸이 따로 없다 - 등불이 나다.
	lantern.hurt(taken)
	bruised += taken
	message.emit("%s (%d)" % [description, taken])


func _finish(outcome: String) -> void:
	is_over = true
	state_changed.emit()
	finished.emit(outcome)
