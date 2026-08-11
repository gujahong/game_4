extends Resource
class_name DialogueChapter

## Chapter > Scene > Dialogue > Command 계층에서 최상위 - DialogueScene 목록 하나.
## 1단계 범위에서는 DialogueController.play_scene()이 Scene 단위로만 재생하므로, Chapter는 여러 Scene을
## 묶어서 관리/순차 재생하는 용도의 데이터 컨테이너로만 존재한다(Chapter 자동 순차재생은 이후 단계).

@export var chapter_id: String = ""
@export var scenes: Array[DialogueScene] = []
