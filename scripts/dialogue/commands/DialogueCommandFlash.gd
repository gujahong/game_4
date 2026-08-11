extends DialogueCommandHandler
class_name DialogueCommandFlash

## params: {duration: float(선택, 기본 0.15 - 짧은 순간 번쩍), color: Color(선택, 기본 흰색)}
func execute(params: Dictionary) -> void:
	await ScreenEffect.flash(params.get("duration", 0.15), params.get("color", Color.WHITE))
