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

## **적은 매 턴 때리지 않는다**(회원님, 2026-08-18). 공격과 공격 사이에 이만큼 웅크린다 -
## 이 박자가 전투의 숨구멍이다. 웅크리는 턴이 기름 붓고 말 거는 창이 된다.
@export var pace: int = 1
## 웅크릴 때 뜨는 문장(일반 공격의 예고). **등불이 밝아야 보인다** - 어두우면
## "어둠 속에서 무언가 움직인다"만 뜬다. 예고를 보고 방어하면 받아넘긴다.
@export_multiline var prep_line: String = ""

## 웅크림이 큰 공격의 예고일 때가 있다. 그때는 `telegraph_line`이 대신 뜬다.
@export var heavy_damage: int = 15
@export var heavy_chance: float = 0.3  ## 웅크릴 때 큰 공격을 준비할 확률
@export_multiline var telegraph_line: String = ""
## **큰 공격이 등불 눈금까지 깎는가**(2026-08-21). 0이면 몸만 다친다.
##
## 시간이 마르는 것과는 아프기가 다르다 - 시간은 두 턴에 하나씩 예고 없이 주지만, 이것은
## **상대가 내 빛을 꺼뜨리는 것**이라 다음 턴에 쓸 수 있는 것이 그 자리에서 줄어든다.
## 예고를 읽고 방어하면 안 맞으므로, 이 값이 큰 적일수록 밝게 다녀야 한다.
@export var drain: int = 0

## **말을 거는 방법들.** 무엇이 뜰지도, 그것이 무슨 일을 하는지도 적마다 다르다
## (`TalkOption`). 여기가 비면 대화가 아예 안 뜬다 - 말이 안 통하는 것도 있어야 한다.
@export var talk_options: Array[TalkOption] = []

## 전투에서 차지하는 크기(화면 높이에 대한 비율). **적마다 다르다** - 그 것은 1보다 커서
## 위아래로 넘쳐야 압도감이 나지만, 길에서 만나는 것까지 그러면 다 똑같이 커 보인다.
@export var battle_height: float = 1.9

## 그림을 좌우로 뒤집어 놓는가. 뽑힌 그림이 반대쪽을 보고 있을 때 쓴다 - 다시 뽑느니
## 한 줄로 뒤집는 편이 낫다.
@export var flip_h: bool = false

## 위아래로도 뒤집는가. `flip_h`와 같이 켜면 180도 돌린 것이 된다 - 뽑힌 그림이 거꾸로
## 서 있을 때 쓴다.
@export var flip_v: bool = false

## 가장자리에서 기운이 일렁이는가(`AuraRipple`). **그 것에게만 쓴다** - 그림을 바깥으로
## 밀어내는 셰이더라, 안 쓰는 적에게 그대로 걸리면 모양이 통째로 일그러진다.
@export var aura: bool = false

## 전투에서 앉는 자리(화면 좌표). **(0,0)이면 무대의 기본값**을 쓴다.
##
## 그 것은 떠 있는 고리라 화면 위쪽에 걸쳐도 되지만, 바닥에 선 것은 **발이 바닥에 닿아야**
## 한다 - 같은 자리에 놓으면 떠 있는 것처럼 보여 수평이 안 맞는다.
@export var battle_at: Vector2 = Vector2.ZERO

## 제자리에서 아주 느리게 오르내리는가. **떠 있는 것에만 쓴다** - 바닥에 선 것이 위아래로
## 흔들리면 숨 쉬는 게 아니라 발이 안 붙은 것으로 보인다.
@export var breathes: bool = true

