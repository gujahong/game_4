extends DialogueCommandHandler
class_name DialogueCommandBlackout

## params: {enabled: bool(선택, 기본 true), color: Color(선택, 기본 검정)} - 페이드와 달리 즉시 전환
## ("배경 즉시 변경"과 같은 결의 연출). 서서히 어두워지는 연출이 필요하면 DialogueCommandFadeOut을 쓸 것.
func execute(params: Dictionary) -> void:
	ScreenEffect.set_blackout(params.get("enabled", true), params.get("color", Color.BLACK))
