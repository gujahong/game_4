extends DialogueCommandHandler
class_name DialogueCommandFlicker

## params: {cycles: int(선택, 기본 5), interval: float(선택, 기본 0.12), dark_alpha: float(선택, 기본 0.7)}
## 부드러운 fade가 아니라 화면이 딱딱 끊기며 깜빡이다가 어두운 채로 고정된다(요청: "깜빡깜빡 하고
## 어두워지고(페이드아웃X)").
func execute(params: Dictionary) -> void:
	await ScreenEffect.flicker(
		params.get("cycles", 5),
		params.get("interval", 0.12),
		params.get("dark_alpha", 0.7)
	)
