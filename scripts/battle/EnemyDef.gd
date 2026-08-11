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

## 예고된 뒤 다음 턴에 날아오는 큰 공격. 방어로만 흘릴 수 있다.
@export var heavy_damage: int = 15
@export var heavy_chance: float = 0.3  ## 매 턴 큰 공격을 준비할 확률

## 큰 공격을 준비할 때 뜨는 문장. **등불이 환할 때만 보인다** - 어두우면 뭐가 오는지 모른다.
@export_multiline var telegraph_line: String = ""

## 말을 걸 때마다 순서대로 하나씩. 다 떨어지면 통하거나 안 통한다.
@export var talk_lines: Array[String] = []

## 마지막 말이 통하려면 등불이 환해야 하는가. 참이면 "설득하려면 기름을 태워야 한다"가 된다 -
## 말로 푸는 길에도 값을 매기는 장치다.
@export var talk_needs_light: bool = true
@export_multiline var talk_success_line: String = ""
@export_multiline var talk_fail_line: String = ""
