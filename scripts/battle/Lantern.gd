extends RefCounted
class_name Lantern

## 등불. **마나이자 밝기다**(회원님, 2026-08-21). 규칙은 `전투.md`에 있다.
##
## 하스스톤의 마나 크리스탈과 같은 읽기인데 **거꾸로 간다** — 크리스탈이 매 턴 늘어나는
## 것이 아니라 **2턴마다 하나씩 줄어든다.** 그것이 이 게임이다: 등불은 저절로 꺼져 간다.
## 기름을 붓는 턴은 지금은 손해고 다음 턴부터 이득이라, 램프를 할지 지금 때릴지가 매 턴
## 판단이 된다. 그리고 **전투가 길어지면 반드시 진다** — 따로 타이머를 안 걸어도 된다.
##
## ### 전과 무엇이 달라졌나
##
## 전에는 **밝기 하나가 체력이자 자원**이었다(0~100, 꺼지면 패배). 회원님이 나누셨다.
##
## ```
## 체력      맞을 때만 준다.        0이면 패배
## 눈금      2턴마다 · 특수 공격.   0이면 주먹질만 된다
## ```
##
## **눈금 0을 패배로 안 만든다.** 공격도 기술도 못 쓰고 맨손만 남으니 저절로 밀린다 —
## 규칙을 하나 안 늘리고 압박만 남는다.
##
## ### 눈금과 밝기 칸은 다른 것이다
##
## 눈금은 0~10이고 **눈에 보이는 밝기는 여섯 칸**이다(회원님이 정하신 구간).
##
## ```
## 눈금  0      꺼짐        두 눈금이 한 칸을 쓴다. 그래서 눈금이 1 줄어도
##      1~2    엄청 어두움   화면이 매번 안 바뀌고, 두 번 걸러 한 번
##      3~4    어두움       눈에 띄게 어두워진다 — 계단이 보여야
##      5~6    중간         "줄고 있다"가 읽힌다
##      7~8    밝음
##      9~10   엄청 밝음
## ```
##
## `level`이라는 이름은 그대로 뒀다 — 화면 쪽이 `BRIGHTNESS[lantern.level]` 식으로 쓰고
## 있어서, 표를 다섯 칸에서 여섯 칸으로 늘리는 것만으로 그쪽이 다 따라온다.

## 눈금의 최대치. 칸으로 그리는 것은 `LanternGauge`가 한다.
const SLOTS := 10
## 전투를 시작하는 눈금. **가득 차서 시작하면 아낄 이유가 없다.**
## 성장(`전투.md`)으로 오르는 값이라 나중에는 밖에서 받는다.
const START_MARKS := 4
## 몇 턴마다 눈금이 하나 줄어드는가. 성장으로 3턴, 4턴이 된다.
const DECAY_EVERY := 2
## 기름 한 병이 올리는 눈금과, 들고 시작하는 병 수.
const POUR_MARKS := 2
const FLASKS := 3

## 몸. **새로 생긴 것이다** — 전에는 밝기가 체력을 겸했다.
const MAX_HP := 40

## 여섯 칸. `MID`가 새로 낀 칸이다.
enum Level { OUT, EMBER, DIM, MID, LIT, BRIGHT }
const NAMES := ["꺼짐", "불씨", "어스름", "은은함", "밝음", "환함"]

## 눈금(0~10)을 밝기 칸(0~5)으로 옮기는 표. **계산으로 하지 않고 표로 적는다** —
## 구간을 회원님이 정하셨으므로 고칠 때 여기 한 줄만 보면 된다.
const BAND := [0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5]

## 내 명중률. **어두울수록 헛친다.**
##
## ⚠️ 남길지 말지 아직 안 정했다(`전투.md` 6장). 마나로 값을 치르는데 명중률까지
## 떨어지면 한 번 어두워진 것으로 두 번 벌받는다. **그래서 많이 눕혔다** — 옛 값은
## 0.15~0.92였는데 지금은 0.55~1.0이다. 헛손질 연출(`Relic.fumble`)을 살려 두려고 0은 안 만든다.
const PLAYER_HIT := [0.55, 0.70, 0.80, 0.88, 0.95, 1.0]
## 적 명중률. **밝기와 무관하다**(회원님, 2026-08-18) — 어둠 속을 사는 것들이라 빛이
## 없어도 나를 본다. 예고를 보고 방어하면 아예 안 맞으므로 높아도 된다.
const ENEMY_HIT := 0.85
const FLEE_CHANCE := [0.90, 0.80, 0.68, 0.55, 0.42, 0.28]  ## 어두울수록 도망치기 쉽다
const DESATURATE := [1.0, 1.0, 0.86, 0.72, 0.60, 0.5]      ## 화면에서 색이 얼마나 빠지는가
## 세상이 실제로 얼마나 밝은가. **탈색만으로는 어림도 없다** — 색만 빠지고 밝기가 그대로면
## 불을 꺼도 적이 또렷하게 보여서 "안 보인다"가 성립하지 않는다. 0이면 완전한 암흑이다.
const BRIGHTNESS := [0.0, 0.16, 0.38, 0.58, 0.80, 1.0]
## **불빛 자체가 얼마나 도드라지는가.** 위와 반대로 움직인다 — 캄캄할수록 작은 불빛이 강하게
## 보이는 것이 실제로 맞고, 화면에서도 그래야 "이 불이 내가 가진 전부"로 읽힌다.
const LIGHT_INTENSITY := [0.0, 1.0, 0.90, 0.78, 0.68, 0.58]
## 등불 빛의 크기(px). 화면 아래 가운데에서 나오므로, 환할 때는 적이 선 위쪽까지 닿아야 한다.
const GLOW_SIZE := [0, 120, 200, 280, 356, 432]

## 적의 예고 동작이 보이기 시작하는 칸. 여기서부터가 "읽을 수 있는" 구간이라 제일 비싸다.
const TELEGRAPH_LEVEL := Level.BRIGHT

## **전투 밖에서도 이어지는 병 주머니.** 서고에서 주우면(`Clutter`) 늘고, 전투에서 부으면
## 준다. 전투마다 새 Lantern이 생기므로 병만은 여기 정적으로 남아 따라다닌다.
static var carried: int = FLASKS
## **눈금도 전투 밖에서 이어진다**(`전투.md`). 필드에서 어둡게 다니면 그 눈금으로 전투가
## 시작한다 — 아끼는 것이 손해가 아니라 선택이 된다.
static var carried_marks: int = START_MARKS

var marks: int = START_MARKS   ## 눈금. 매 턴 이만큼 마나를 낸다
var mana: int = START_MARKS    ## 이번 턴에 아직 안 쓴 마나
var flasks: int = FLASKS
var hp: int = MAX_HP

var _turns: int = 0            ## 눈금이 줄 때를 세는 것


func _init() -> void:
	flasks = carried
	marks = clampi(carried_marks, 0, SLOTS)
	mana = marks


## 밝기 칸. 눈금에서 **파생**된다.
var level: int:
	get:
		return BAND[clampi(marks, 0, SLOTS)]


# --- 마나 ---

## 낼 수 있는가.
func can_pay(cost: int) -> bool:
	return mana >= cost


## 낸다. **못 낼 값을 부르지 않는 것은 부르는 쪽 책임이다** — 여기서는 안 깎고 거짓만 준다.
func pay(cost: int) -> bool:
	if mana < cost:
		return false
	mana -= cost
	return true


## 턴이 시작됐다. **남은 마나는 사라진다**(회원님) — 이월이 없어야 매 턴 다 쓰게 된다.
func refill() -> void:
	mana = marks


## 턴이 지났다. `DECAY_EVERY`턴마다 눈금이 하나 준다.
func tick() -> void:
	_turns += 1
	if _turns % DECAY_EVERY == 0:
		marks = maxi(marks - 1, 0)
		mana = mini(mana, marks)


## 특수한 공격이 눈금을 깎는다. 맞은 그 자리에서 어두워진다.
func drain(amount: int) -> void:
	marks = maxi(marks - amount, 0)
	mana = mini(mana, marks)


## 기름 한 병을 붓는다. 부었으면 참을 돌려준다.
##
## **이번 턴 마나는 안 올린다.** 눈금만 오르고 마나는 다음 턴부터 나온다 — 그래야
## "지금은 손해, 다음 턴부터 이득"이라는 램프의 판단이 성립한다.
func pour() -> bool:
	if flasks <= 0:
		return false
	flasks -= 1
	carried = flasks
	marks = mini(marks + POUR_MARKS, SLOTS)
	carried_marks = marks
	return true


# --- 몸 ---

## 맞았다.
func hurt(amount: int) -> void:
	hp = maxi(hp - amount, 0)


func is_dead() -> bool:
	return hp <= 0


## 등불이 꺼졌는가. **졌다는 뜻이 아니다** — 주먹질만 남았다는 뜻이다.
func is_out() -> bool:
	return marks <= 0


# --- 읽는 것 ---

func level_name() -> String:
	return NAMES[level]


func player_hit() -> float:
	return PLAYER_HIT[level]


func enemy_hit() -> float:
	return ENEMY_HIT


func flee_chance() -> float:
	return FLEE_CHANCE[level]


## 적의 예고 동작이 보이는가.
func can_read_enemy() -> bool:
	return level >= TELEGRAPH_LEVEL


## 적의 웅크림(공격이 온다는 낌새)이 보이는가. **글을 읽는 것보다는 싸다.**
func can_sense_enemy() -> bool:
	return level >= Level.LIT


## 전투가 끝났다. 눈금을 밖으로 넘긴다 — 필드가 이 밝기로 이어받는다.
func carry_out() -> void:
	carried_marks = marks
	carried = flasks
