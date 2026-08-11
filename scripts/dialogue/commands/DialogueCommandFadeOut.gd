extends DialogueCommandHandler
class_name DialogueCommandFadeOut

## params: {duration: float, color: Color(선택, 기본 검정), above_ui: bool(선택, 기본 false)}
func execute(params: Dictionary) -> void:
	await ScreenEffect.fade_out(
		params.get("duration", 1.0), params.get("color", Color.BLACK), params.get("above_ui", false)
	)
