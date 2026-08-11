extends RefCounted
class_name DialogueCommandRegistry

## Command 이름(String) -> 핸들러 인스턴스 매핑. 자식 노드/오토로드가 아니라 static 딕셔너리 하나뿐인
## 유틸리티 클래스라 어디서든 `DialogueCommandRegistry.register(...)`/`.get_handler(...)`로 바로 접근
## 가능하다. 새 명령 추가 = 핸들러 스크립트 하나 작성 + register() 한 줄(어디서 호출해도 됨, 보통 그
## 기능을 담당하는 시스템의 _ready()에서) - DialogueController/이 파일 자체는 절대 안 건드림.
##
## 기본 제공 커맨드("wait")는 최초 접근 시점에 지연 등록된다(_ensure_defaults) - 등록 순서와 무관하게
## 항상 사용 가능하도록.
##
## [2026-08-11] 우주쓰레기게임에서 옮겨오면서 뺀 것들 - 필요해지면 그쪽에서 다시 가져오면 된다.
## - zoom: GameCamera가 있어야 동작한다. 이 게임엔 아직 카메라가 없다
## - play_sfx / play_bgm / change_bgm / stop_bgm: SfxManager(448줄, 그 게임 효과음 파일이 박혀 있음)가
##   통째로 딸려온다. 소리를 붙일 때 이 게임에 맞는 걸 새로 만드는 쪽이 싸다
## - emergency_light / cargo_panel: 우주선 비상등, 화물칸. 그 게임 전용

static var _handlers: Dictionary = {}
static var _defaults_registered: bool = false


static func register(command_type: String, handler: DialogueCommandHandler) -> void:
	_handlers[command_type] = handler


static func get_handler(command_type: String) -> DialogueCommandHandler:
	_ensure_defaults()
	return _handlers.get(command_type)


static func _ensure_defaults() -> void:
	if _defaults_registered:
		return
	_defaults_registered = true
	register("wait", DialogueCommandWait.new())
	register("fade_in", DialogueCommandFadeIn.new())
	register("fade_out", DialogueCommandFadeOut.new())
	register("shake", DialogueCommandShake.new())
	register("flash", DialogueCommandFlash.new())
	register("blackout", DialogueCommandBlackout.new())
	register("flicker", DialogueCommandFlicker.new())
	register("set_auto_advance", DialogueCommandAutoAdvance.new())
