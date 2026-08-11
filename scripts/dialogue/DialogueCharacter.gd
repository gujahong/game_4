extends Resource
class_name DialogueCharacter

## 대화 중 화면에 표시되는 캐릭터 한 명의 상태 - SHOW_PORTRAIT/CHANGE_FACE/HIDE 같은 Command가 아니라
## 데이터로 관리한다(리뷰 반영: Command로 넣으면 씬이 길어질수록 관리가 어려워짐). DialogueLine이 "이
## 줄 시점에 이런 캐릭터들이 이런 상태로 있어야 한다"를 이 Resource 배열로 선언하면, 2단계에서 만들
## 초상화 UI가 그 상태를 읽어서 그린다(이전 줄과 비교해서 등장/퇴장/이동 애니메이션 여부를 판단하는 것도
## UI 쪽 책임 - 지금은 상태 스키마만 확정).

@export var character_id: String = ""
@export var portrait_id: String = ""  # 초상화 이미지 식별자 - 실제 텍스처 매핑은 UI가 담당
@export var emotion: String = "normal"
@export var position: String = "center"  # left/center/right 같은 슬롯 식별자 - 실제 좌표 변환은 UI가 담당
@export var visible_state: bool = true  # "visible"은 Resource 내장 프로퍼티와 이름이 겹쳐서 접미사 붙임
@export var emphasized: bool = false  # 강조 확대
@export var dimmed: bool = false  # 어둡게 표시(비활성 대화자 등)
