extends Resource
class_name DialogueScene

## Chapter > Scene > Dialogue > Command 계층에서 Scene 단계 - DialogueLine 목록 하나.
## NPC 대화/상점 대화/퀘스트/튜토리얼/라디오/뉴스 등 모든 용도가 이 리소스 하나만 채워서 재사용한다.

@export var scene_id: String = ""
@export var lines: Array[DialogueLine] = []
