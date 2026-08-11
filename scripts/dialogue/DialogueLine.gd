extends Resource
class_name DialogueLine

## 대사 한 줄. speaker가 비어있으면 이름창을 숨긴다(내레이션/독백 등).
## commands_before: 이 줄이 뜨기 전에 실행(예: 배경 전환 후 대사 시작).
## commands_after: 플레이어가 이 줄을 확인하고 다음으로 넘기려는 순간, 다음 줄이 뜨기 전에 실행
## (예시 흐름: "대사 → 성검 등장 → 효과음 → 카메라 확대 → NPC 등장 → 다음 대사" 중 가운데 4개가 여기).
##
## active_characters/choices는 2단계(초상화)/8단계(선택지) UI가 아직 없어서 지금 당장 아무도 안 읽지만,
## Command로 흉내내지 말고 처음부터 Resource 스키마로 잡아두라는 리뷰를 반영해 미리 필드만 확정해둔다 -
## 나중에 이미 작성된 대사 데이터를 다시 고칠 필요가 없게 하려는 목적.

@export var speaker: String = ""
@export_multiline var text: String = ""
@export var commands_before: Array[DialogueCommand] = []
@export var commands_after: Array[DialogueCommand] = []
@export var active_characters: Array[DialogueCharacter] = []  # 이 줄 시점에 화면에 있어야 할 캐릭터 상태들(2단계 UI 소비 예정)
@export var choices: Array[DialogueChoice] = []  # 이 줄 다음에 표시할 선택지(비어있으면 그냥 다음 줄로 순차 진행, 8단계 UI 소비 예정)

## 연출 스타일 이름(예: "normal", "emphasis", "narration"...). Controller는 이 값을 절대 읽지 않고 그대로
## 들고 있기만 한다 - 색상/굵기/흔들림 등 실제 해석과 적용은 전부 DialogueUI의 몫(DialogueUI.STYLE_PRESETS 참고).
@export var style: String = "normal"

## 이 줄만 타이핑 속도를 다르게 하고 싶을 때 쓰는 배수(1.0 = 기본 속도). style과 별개의 범용 필드라
## Controller는 "Thought라서 느리다"를 모르고 그냥 숫자 배수로만 chars_per_second에 곱한다.
@export var typing_speed_scale: float = 1.0

## 균등 속도(chars_per_second * typing_speed_scale) 대신, 글자 하나하나가 노래/음성의 실제 타이밍에
## 맞춰 나오게 하고 싶을 때 쓴다(2026-08-01, 카라오케 가사 동기화). i번째 원소 = i번째 글자가 나와야 할,
## 줄 시작 시점 기준 경과 초. 비어있으면(기본값) 기존 균등 타이핑 방식을 그대로 쓴다 - 완전히 하위 호환.
@export var char_timings: PackedFloat32Array = PackedFloat32Array()

## 줄 전체가 아니라 특정 구간(단어/구절)만 다른 style로 덧씌우고 싶을 때 쓴다. 각 항목은
## {"start": int, "end": int, "style": String} - text의 [start, end) 구간(문자 인덱스)을 그 style로 강조.
## 예: text="53 크레딧을 얻었다"에서 "53 크레딧"만 강조하고 싶으면
## [{"start": 0, "end": 6, "style": "important"}] - 나머지 구간은 줄 기본 style(위 style 필드)을 그대로 씀.
## Controller는 이 필드도 style과 마찬가지로 전혀 해석하지 않는다 - 전부 DialogueUI 몫.
@export var inline_styles: Array[Dictionary] = []
