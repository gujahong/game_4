extends DialogueCommandHandler
class_name DialogueCommandAutoAdvance

## params: {enabled: bool, delay: float(선택, 있으면 줄 사이 대기시간 auto_advance_delay도 같이 바꿈),
##          lock_input: bool(선택, 기본 enabled와 동일)}
## 노래 가사처럼 플레이어 클릭 없이 알아서 줄줄이 넘어가야 하는 구간에 씀. lock_input도 같이 켜면
## 클릭/스페이스로 끼어들어 넘길 수도 없게 완전히 자동재생만 되게 한다(2026-08-01). 켜놓은 채로 다음
## 씬으로 새지 않도록, 그 구간이 끝나면 반드시 enabled=false(그리고 필요하면 lock_input=false)로
## 다시 꺼줘야 한다.
func execute(params: Dictionary) -> void:
	if params.has("delay"):
		Dialogue.auto_advance_delay = params["delay"]
	var enabled: bool = params.get("enabled", true)
	Dialogue.set_auto_advance(enabled)
	Dialogue.input_locked = params.get("lock_input", enabled)
