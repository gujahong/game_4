extends RefCounted
class_name DialogueCommandHandler

## 모든 Command 핸들러의 베이스. 새 명령을 추가하려면 이 클래스를 상속해서 execute()만 오버라이드하고,
## DialogueCommandRegistry.register("이름", MyHandler.new())로 등록하면 끝 - DialogueController나
## 다른 핸들러는 전혀 안 건드려도 된다.
##
## 즉시 끝나는 명령은 execute()가 그냥 리턴하면 되고, 시간이 걸리는 명령(페이드/카메라 이동/줌 등)은
## execute() 안에서 await를 쓰면 된다(예: DialogueCommandWait.gd 참고) - DialogueController는
## `cmd.wait_for_completion`이 true인 경우에만 `await handler.execute(params)`로 완료를 기다리므로,
## 핸들러 쪽은 일반 async 함수 작성하듯이 그냥 await만 쓰면 자동으로 맞물린다.


func execute(_params: Dictionary) -> void:
	pass


## 사운드 계열 커맨드(PlaySFX/PlayBGM/ChangeBGM) 공용 헬퍼 - params.stream(직접 AudioStream 참조)이
## 있으면 그걸 쓰고, 없으면 params.path(리소스 경로 문자열)를 load()한다. 프로젝트에 아직 실제 오디오
## 에셋이 하나도 없어서(SfxManager 참고) 지금은 데이터를 넘겨받는 통로만 만들어두고, 나중에 실제 음악/
## 효과음 파일이 추가되면 그 경로만 params에 넣으면 바로 동작한다.
static func resolve_stream(params: Dictionary) -> AudioStream:
	var stream: AudioStream = params.get("stream")
	if stream:
		return stream
	if params.has("path"):
		return load(params["path"])
	return null
