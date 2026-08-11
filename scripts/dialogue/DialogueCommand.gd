extends Resource
class_name DialogueCommand

## 대사 한 줄에 딸린 명령 하나. command_type은 DialogueCommandRegistry에 등록된 이름과 문자열로만
## 연결된다(핸들러 스크립트를 직접 참조하지 않음) - 그래서 새 명령을 추가할 때 이 리소스나
## DialogueController를 전혀 안 건드리고 핸들러 스크립트 하나 + 등록 한 줄만 있으면 된다.
##
## command_type == "event"는 특별 취급된다 - 핸들러를 실행하는 대신 DialogueController가
## dialogue_event 시그널만 방출한다(params.name = 이벤트 이름). 캐릭터 생성/아이템 지급/맵 이동처럼
## 대사 시스템이 직접 실행하면 안 되는(플레이어/맵/인벤토리와 직접 결합하게 되는) 것들은 전부 이 방식으로
## 이벤트만 던지고, 실제 처리는 그 이벤트를 구독하는 다른 시스템이 담당한다(저결합 요구사항).

@export var command_type: String = ""  # 예: "wait", "camera_shake", "play_sfx", "event"
@export var params: Dictionary = {}
@export var wait_for_completion: bool = false  # true면 이 명령이 끝날 때까지 다음 줄로 안 넘어감(예: 페이드/카메라 이동)
