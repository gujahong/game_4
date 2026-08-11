extends DialogueCommandHandler
class_name DialogueCommandShake

## params: {amount: float(선택, 기본 4.0), duration: float(선택, 기본 0.3)}
##
## 대사창을 흔든다. "dialogue_ui" 그룹으로 찾으므로 대사 시스템이 UI 노드 경로를 직접 몰라도 된다.
##
## [2026-08-11] 우주쓰레기게임에는 GameCamera를 흔드는 경로가 먼저 있고 카메라가 없을 때만 UI를
## 흔드는 폴백이었는데, 이 게임엔 아직 카메라가 없어서 폴백 쪽만 남겼다. 나중에 카메라가 생기면
## 그쪽 코드를 다시 보면 된다.
func execute(params: Dictionary) -> void:
	var dialogue_ui: DialogueUI = Engine.get_main_loop().get_first_node_in_group("dialogue_ui")
	if dialogue_ui:
		await dialogue_ui.shake_panel(params.get("amount", 4.0), params.get("duration", 0.3))
