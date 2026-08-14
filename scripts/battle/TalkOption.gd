extends Resource
class_name TalkOption

## 말을 거는 방법 하나. **무엇이 뜰지도, 무엇이 벌어질지도 적이 정한다.**
##
## "살펴보기·묻기·위협"처럼 목록을 코드에 박아 두면 모든 적이 같은 방식으로 상대된다 - 그러면
## 적이 늘어도 싸움은 안 늘어난다. 그 것에게는 고리에 적힌 이름을 묻는 것이 통하고, 다른 것에게는
## 그런 말이 아예 안 통해야 한다.
##
## 규칙(`Battle`)은 **벌어질 수 있는 일 몇 가지만** 알고, 그중 무엇인지는 여기서 고른다.
## 새 적을 만들 때 코드는 안 건드리고 이 리소스만 몇 개 얹으면 된다.

enum Effect {
	NOTHING,   ## 말만 오간다. 턴은 쓴다
	OPENS,     ## 길이 열린다. 전투가 끝난다
	FLINCH,    ## 그 적이 다음 차례를 건너뛴다
	ANGER,     ## 그 적이 큰 공격을 준비한다
	READS,     ## 그 적의 상태와 노리는 것이 읽힌다
}

@export var label: String = "말을 건다"

## 고를 때마다 순서대로 하나씩 나온다. 다 떨어지면 마지막 것이 계속 나온다.
@export var lines: Array[String] = []

## 등불이 환해야 통하는가. 참이면 **말에도 기름값이 든다.**
@export var needs_light: bool = false

## 어두워서 안 통했을 때. 이때는 `effect`가 안 일어나고 턴만 나간다.
@export_multiline var dark_line: String = ""

## 말이 다 떨어진 뒤에 일어나는 일. 그전까지는 `lines`만 나온다.
@export var effect: Effect = Effect.NOTHING

## `effect`가 일어나는 순간의 문장.
@export_multiline var effect_line: String = ""
