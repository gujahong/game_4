extends RefCounted
class_name Lantern

## 등불. **게이지 하나가 전부다 - 밝기가 곧 체력이고 자원이다**(회원님, 2026-08-18).
##
## 밝기는 세 갈래로 빠져나간다: 칼을 휘두를 때(`swing`), 적에게 맞을 때(`hurt`),
## 그리고 턴이 지날 때(`burn`). 채우는 길은 기름병 하나를 붓는 것뿐이고(`pour`),
## 그것도 턴을 쓰는 행동이다. **등불이 꺼지면 전투에서 진다.**
##
## 그래서 매 턴 "태울까 아낄까"가 선택이 되고, 그 선택이 곧 "적을 읽을 수 있는가"가 된다.
## 코즈믹 호러에서 기름을 태우는 이유가 명중률만이 아니라 **저게 뭔지 알기 위해서**가
## 되는 것이 이 시스템의 핵심이다.
##
## 적은 어둠 속을 사는 것들이라 **빛이 없어도 나를 본다**(`ENEMY_HIT`는 밝기와 무관).
## 어두워서 손해 보는 것은 나뿐이다 - 대신 도망은 어두울수록 쉽다(`FLEE_CHANCE`).
## 아끼는 쪽에도 이득이 하나는 있어야 선택이 성립한다.

enum Level { OUT, EMBER, DIM, LIT, BRIGHT }

## 적의 예고 동작이 보이기 시작하는 밝기. 여기서부터가 "읽을 수 있는" 구간이고,
## 그래서 제일 비싸다.
const TELEGRAPH_LEVEL := Level.BRIGHT

const NAMES := ["꺼짐", "불씨", "어스름", "밝음", "환함"]
const PLAYER_HIT := [0.15, 0.35, 0.55, 0.75, 0.92]   ## 내 명중률. 어두울수록 헛친다
## 적 명중률. **밝기와 무관하다**(회원님, 2026-08-18) - 어둠 속을 사는 것들이라 빛이
## 없어도 나를 본다. 어두워서 손해 보는 것은 나뿐이다.
## 예고-응수 구조(2026-08-18)에서는 높아도 된다 - 웅크림을 보고 방어하면 아예 안 맞으므로,
## 공격 턴에 서 있다 맞는 것은 주사위가 아니라 내 선택이다.
const ENEMY_HIT := 0.85
const FLEE_CHANCE := [0.90, 0.75, 0.60, 0.42, 0.28]  ## 어두울수록 도망치기 쉽다
const DESATURATE := [1.0, 1.0, 0.80, 0.62, 0.5]      ## 화면에서 색이 얼마나 빠지는가
## 세상이 실제로 얼마나 밝은가. **탈색만으로는 어림도 없다** - 색만 빠지고 밝기가 그대로면
## 불을 꺼도 적이 또렷하게 보여서 "안 보인다"가 성립하지 않는다. 0이면 완전한 암흑이다.
const BRIGHTNESS := [0.0, 0.20, 0.46, 0.72, 1.0]
## **불빛 자체가 얼마나 도드라지는가.** 위 BRIGHTNESS와 반대로 움직인다 - 캄캄할수록 작은
## 불빛이 강하게 보이는 게 실제로 맞고, 화면에서도 그래야 "이 불이 내가 가진 전부"로 읽힌다.
## 꺼짐만 0이다. 불이 아예 없으니 도드라질 것도 없다.
const LIGHT_INTENSITY := [0.0, 1.0, 0.88, 0.72, 0.58]
## 등불 빛의 크기(px). 화면 아래 가운데에서 나오므로, 환할 때는 적이 선 위쪽까지 닿아야 한다.
const GLOW_SIZE := [0, 132, 228, 324, 432]

## 게이지의 눈금. 100이 가득이고 0이면 꺼진 것 - 진 것이다.
const FULL := 100
## 시작 밝기. 가득 차서 시작하면 아낄 이유가 없고, 너무 낮으면 첫 턴부터 쫓긴다.
const START := 70
## 턴이 끝날 때마다 저절로 마르는 몫. **아무것도 안 해도 어두워진다** - 시간이 적이다.
## 첫 판은 3이었는데, 칼값·적 타격과 겹치니 "채우고 맞고 채우고 맞고"만 남았다(회원님).
const TURN_BURN := 2
## 칼 한 번 뽑는 값. 10이었더니 때릴수록 손해라 공격이 무서워졌다 - 공격이 본전은 되어야
## 전투가 굴러간다.
const SWING_COST := 6
## 기름 한 병이 채우는 몫과, 들고 시작하는 병 수.
const POUR := 40
const FLASKS := 3

## **전투 밖에서도 이어지는 병 주머니.** 서고에서 주우면(`Clutter`) 늘고, 전투에서 부으면
## 준다. 전투마다 새 Lantern이 생기므로, 병만은 여기 정적으로 남아 따라다닌다.
static var carried: int = FLASKS

var light: int = START    ## 밝기 = 체력 = 자원. 이 숫자 하나가 전부다
var flasks: int = FLASKS  ## 남은 기름병


func _init() -> void:
	flasks = carried

## 다섯 단계는 게이지에서 **파생**된다. 명중률·시야·화면 규칙이 전부 단계를 타므로,
## 게이지가 내려가면 세상도 그만큼 어두워진다.
var level: int:
	get:
		if light <= 0:
			return Level.OUT
		if light < 25:
			return Level.EMBER
		if light < 50:
			return Level.DIM
		if light < 75:
			return Level.LIT
		return Level.BRIGHT


## 휘두를 수 있는가. **값을 치르고도 불이 남아야 한다** - 제 칼질로 제 불을 끄는 일은 없다.
func can_swing() -> bool:
	return light > SWING_COST


func swing() -> void:
	light = maxi(light - SWING_COST, 0)


## 맞았다. 적의 매 타가 불을 갉는다.
func hurt(amount: int) -> void:
	light = maxi(light - amount, 0)


## 한 턴이 지났다. 저절로 마른다.
func burn() -> void:
	light = maxi(light - TURN_BURN, 0)


## 기름 한 병을 붓는다. 부었으면 참을 돌려준다. 주머니(`carried`)에서도 같이 준다.
func pour() -> bool:
	if flasks <= 0:
		return false
	flasks -= 1
	carried = flasks
	light = mini(light + POUR, FULL)
	return true


## 꺼졌는가 - 즉 졌는가.
func is_out() -> bool:
	return light <= 0


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


## 적의 웅크림(공격이 온다는 낌새)이 보이는가. **글을 읽는 것(BRIGHT)보다는 싸서**,
## 밝음부터 보인다 - 어스름 아래로 내려가면 낌새 없이 공격 턴을 맞는다.
func can_sense_enemy() -> bool:
	return level >= Level.LIT
