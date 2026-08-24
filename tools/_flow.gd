extends Node

## **진행이 남는가, 전투가 끝나는가**를 헤드리스로 잰다.
##
## 2026-08-23 세션이 버그 셋을 고쳤는데 "Godot이 없는 환경이라 실행 확인을 못 했다"고
## 적어 두었다. 화면을 띄워 손으로 걷지 않고도 **규칙 층은 여기서 다 잴 수 있다.**
##
##   Godot_v4.7.1-stable_win64.exe --headless --path . res://tools/_flow.tscn
##
## **씬으로 띄운다.** `--script`로는 오토로드(`ScreenEffect`·`Dialogue`)가 안 올라와서
## `Walker`·`Records`가 아예 컴파일이 안 된다.
##
## **화면·씬 전환은 여기서 못 잰다.** 그건 실제로 걸어봐야 안다.

var _fails := 0


func _ready() -> void:
	_statics_survive()
	_forget_clears()
	_battle_ends()
	_lantern_mana()
	print("")
	if _fails == 0:
		print("다 통과했다.")
	else:
		print("실패 %d" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)


func _ok(name: String, got, want) -> void:
	if got == want:
		print("  OK   %s" % name)
	else:
		print("  실패 %s — %s 여야 하는데 %s" % [name, want, got])
		_fails += 1


## 씬을 갈아타도 남는가. **`static`이 아니면 전투에서 돌아올 때 통째로 지워진다.**
func _statics_survive() -> void:
	print("[진행이 남는가]")
	Walker.forget_all()

	Sleepers.beaten[3] = true
	Records.read_shelves[1] = true
	Walker.heart_done = true

	# 인스턴스를 새로 만들어도(= 방이 새로 지어져도) 값이 남아야 한다.
	var fresh_sleepers := Sleepers.new()
	var fresh_records := Records.new()
	_ok("잡은 종이 더미", Sleepers.beaten.has(3), true)
	_ok("읽은 서가", Records.read_shelves.has(1), true)
	_ok("그것과 마주섰던 것", Walker.heart_done, true)
	fresh_sleepers.free()
	fresh_records.free()


## 새 판을 시작하면 지워지는가.
func _forget_clears() -> void:
	print("[새 판을 시작하면 지워지는가]")
	Walker.forget_all()
	_ok("종이 더미", Sleepers.beaten.is_empty(), true)
	_ok("서가", Records.read_shelves.is_empty(), true)
	_ok("그것", Walker.heart_done, false)


## **전투가 실제로 끝나는가.** `over`가 안 이어져 있어서 안 돌아가던 것이 이 층 위의 일이다.
func _battle_ends() -> void:
	print("[전투가 끝나는가]")
	var def := EnemyDef.new()
	def.display_name = "허수아비"
	def.max_hp = 1
	def.damage_min = 0
	def.damage_max = 0

	var battle := Battle.new([def])
	# **람다는 지역변수를 값으로 캡처한다.** 안에서 대입해도 밖은 안 바뀐다 -
	# 사전은 참조라 이렇게 받아야 한다.
	var got := {"outcome": ""}
	battle.finished.connect(func(o: String) -> void: got["outcome"] = o)

	# 마나를 넉넉히 주고 쓰러질 때까지 친다. **열 번 안에 안 끝나면 그것이 문제다.**
	battle.lantern.marks = 10
	battle.lantern.mana = 10
	for i in 10:
		if battle.is_over:
			break
		battle.attack(0)
	_ok("이기고 끝났다", got["outcome"], "victory")
	_ok("적이 쓰러졌다", battle.alive().is_empty(), true)

	# 체력이 0이면 진다. **눈금이 0인 것으로는 안 진다** - 주먹질만 남을 뿐이다.
	var hurt := Battle.new([def])
	hurt.lantern.marks = 0
	hurt.lantern.mana = 0
	_ok("눈금 0이어도 안 죽었다", hurt.lantern.is_dead(), false)
	hurt.lantern.hurt(Lantern.MAX_HP)
	_ok("체력 0이면 죽는다", hurt.lantern.is_dead(), true)


## 마나 규칙. 하스스톤인데 거꾸로 도는지.
func _lantern_mana() -> void:
	print("[등불이 마나로 도는가]")
	var lamp := Lantern.new()
	lamp.marks = 5
	lamp.mana = 5

	_ok("낼 수 있다", lamp.pay(2), true)
	_ok("낸 만큼 준다", lamp.mana, 3)
	_ok("모자라면 못 낸다", lamp.pay(9), false)

	# 턴이 시작되면 눈금만큼 다시 찬다. **안 쓴 것은 사라진다.**
	lamp.refill()
	_ok("다시 찬다", lamp.mana, 5)

	# 2턴마다 하나씩 마른다.
	lamp.tick()
	_ok("한 턴으로는 안 마른다", lamp.marks, 5)
	lamp.tick()
	_ok("두 턴이면 마른다", lamp.marks, 4)

	# 기름은 눈금만 올리고 이번 턴 마나는 안 올린다.
	lamp.mana = 0
	lamp.flasks = 1
	_ok("부었다", lamp.pour(), true)
	_ok("눈금이 올랐다", lamp.marks, 4 + Lantern.POUR_MARKS)
	_ok("이번 턴 마나는 그대로", lamp.mana, 0)
	_ok("병이 줄었다", lamp.flasks, 0)

	# 밝기 칸은 눈금에서 파생된다(회원님이 정하신 구간).
	lamp.marks = 0
	_ok("0은 꺼짐", lamp.level, Lantern.Level.OUT)
	lamp.marks = 2
	_ok("2는 불씨", lamp.level, Lantern.Level.EMBER)
	lamp.marks = 6
	_ok("6은 가운데 칸", lamp.level, Lantern.Level.MID)
	lamp.marks = 10
	_ok("10은 환함", lamp.level, Lantern.Level.BRIGHT)
