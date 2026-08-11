extends RefCounted
class_name Lantern

## 등불. 이 게임 전투의 자원이자 **화면 밝기 그 자체**다.
##
## 밝기를 바꾸는 데 행동을 쓰지 않는다 - 대가는 기름뿐이다. 그래서 매 턴 "태울까 아낄까"가
## 선택이 되고, 그 선택이 곧 "적을 읽을 수 있는가"가 된다. 코즈믹 호러에서 기름을 태우는
## 이유가 명중률만이 아니라 **저게 뭔지 알기 위해서**가 되는 것이 이 시스템의 핵심이다.
##
## 어두우면 적도 나를 잘 못 본다(`ENEMY_HIT`). 그래서 불을 끄는 것이 자살이 아니라 **숨는 것**이
## 되고, 도망도 쉬워진다. 아끼는 쪽에도 이득이 있어야 선택이 성립한다.
##
## **맨 아래 단계(꺼짐)는 진짜 암흑이다.** 밝기가 0이라 배경도 적도 화면에서 사라지고 UI만
## 남는다. 눈이 아니라 전투 기록으로만 싸우게 된다 - 안 보이는 것이 무섭다는 규칙을 그대로
## 시스템에 옮긴 것이다.

enum Level { OUT, EMBER, DIM, LIT, BRIGHT }

## 적의 예고 동작이 보이기 시작하는 밝기. 여기서부터가 "읽을 수 있는" 구간이고,
## 그래서 제일 비싸다.
const TELEGRAPH_LEVEL := Level.BRIGHT

const NAMES := ["꺼짐", "불씨", "어스름", "밝음", "환함"]
const OIL_COST := [0, 1, 3, 5, 8]                    ## 턴당 기름 소모
const PLAYER_HIT := [0.15, 0.35, 0.55, 0.75, 0.92]   ## 내 명중률
const ENEMY_HIT := [0.35, 0.50, 0.65, 0.78, 0.85]    ## 적 명중률 - 어두우면 적도 헛친다
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

const STARTING_OIL := 100
## 처음엔 "밝음"에서 시작한다. 최고 단계에서 시작하면 첫 턴부터 기름이 8씩 녹아 쫓기고,
## 최저에서 시작하면 아무것도 안 보여서 뭘 하는 게임인지 모른다.
const STARTING_LEVEL := Level.LIT

var oil: int = STARTING_OIL
var level: int = STARTING_LEVEL


func brighten() -> void:
	if oil <= 0:
		return
	level = mini(level + 1, Level.BRIGHT)


func dim() -> void:
	level = maxi(level - 1, Level.OUT)


## 한 턴이 지났다. 기름이 마르면 저절로 꺼진다 - 하지만 죽지는 않는다.
## 기름을 목숨으로 만들면 "불을 끄고 숨는다"가 전략이 아니라 자살이 되어버린다.
func burn() -> void:
	oil = maxi(oil - OIL_COST[level], 0)
	if oil <= 0:
		level = Level.OUT


func level_name() -> String:
	return NAMES[level]


func player_hit() -> float:
	return PLAYER_HIT[level]


func enemy_hit() -> float:
	return ENEMY_HIT[level]


func flee_chance() -> float:
	return FLEE_CHANCE[level]


## 적의 예고 동작이 보이는가.
func can_read_enemy() -> bool:
	return level >= TELEGRAPH_LEVEL
