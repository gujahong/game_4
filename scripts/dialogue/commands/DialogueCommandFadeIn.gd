extends DialogueCommandHandler
class_name DialogueCommandFadeIn

## params: {duration: float}
func execute(params: Dictionary) -> void:
	await ScreenEffect.fade_in(params.get("duration", 1.0))
