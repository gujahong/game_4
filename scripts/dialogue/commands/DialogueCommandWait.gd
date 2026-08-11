extends DialogueCommandHandler
class_name DialogueCommandWait

## 기본 제공 예시 커맨드 - params={"duration": 1.5}만큼 그냥 시간을 끈다("wait_for_completion=true"로
## 쓰면 다음 줄이 그만큼 늦게 뜸). 새 커맨드를 만들 때 참고할 최소한의 "시간이 걸리는 커맨드" 예제.

func execute(params: Dictionary) -> void:
	var duration: float = params.get("duration", 1.0)
	await Engine.get_main_loop().create_timer(duration).timeout
