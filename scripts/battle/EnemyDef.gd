extends Resource
class_name EnemyDef

## 적 하나의 정의. **새 적을 늘리려면 이 리소스를 하나 만들면 된다** - 전투 코드는 안 건드린다.
##
## 체력을 숫자로 보여주지 않는 것이 이 게임의 방침이다(`Battle.enemy_condition()` 참고).
## 눈금이 보이면 계산이 되고, 계산이 되면 무섭지 않다.

@export var display_name: String = ""
@export var texture: Texture2D

@export var max_hp: int = 30
@export var damage_min: int = 5
@export var damage_max: int = 8

## **덤비지 않고 보기만 하는 것.** 참이면 제 차례에 아무 짓도 안 하고 `watch_lines`를 한 줄
## 흘린다 - 때리지 않는데도 물러설 수 없는 상대가 있어야 한다. 지키는 자가 그렇다.
@export var watches: bool = false
@export var watch_lines: Array[String] = []

## 예고된 뒤 다음 턴에 날아오는 큰 공격. 방어로만 흘릴 수 있다.
@export var heavy_damage: int = 15
@export var heavy_chance: float = 0.3  ## 매 턴 큰 공격을 준비할 확률

## 큰 공격을 준비할 때 뜨는 문장. **등불이 환할 때만 보인다** - 어두우면 뭐가 오는지 모른다.
@export_multiline var telegraph_line: String = ""

## **말을 거는 방법들.** 무엇이 뜰지도, 그것이 무슨 일을 하는지도 적마다 다르다
## (`TalkOption`). 여기가 비면 대화가 아예 안 뜬다 - 말이 안 통하는 것도 있어야 한다.
@export var talk_options: Array[TalkOption] = []
