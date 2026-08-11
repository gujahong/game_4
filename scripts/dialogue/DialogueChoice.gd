extends Resource
class_name DialogueChoice

## 선택지 하나 - Command가 아니라 별도 Resource(리뷰 반영). Command는 "실행하고 끝"이지만 선택지는
## 여러 갈래로 흐름 자체를 나누는 것이라 성격이 달라서 분리했다.
##
## condition_flag: 지금은 Flag/조건 시스템 자체가 없어서 값만 들고 있고 아직 아무도 평가하지 않는다
## (8단계 선택지 시스템 구현 시 실제로 검사하게 됨) - 필드 모양을 먼저 잡아둬야 나중에 이미 만들어진
## 선택지 데이터를 다시 고칠 필요가 없다.

@export var text: String = ""
@export var next_scene: DialogueScene  # 선택 시 이어질 씬. 비어있으면 현재 씬의 다음 줄로 그냥 진행(단순 분기 없는 선택지)
@export var condition_flag: String = ""  # 비어있으면 항상 노출. 8단계(Flag 시스템)에서 실제로 평가됨 - 지금은 미평가
@export var commands: Array[DialogueCommand] = []  # 선택하는 순간 실행(예: event 커맨드로 "choice_selected" 방출)
