extends Node
class_name DialogueController

## 대사 시스템의 실행기(Autoload "Dialogue"로 등록). 현재 재생 중인 DialogueScene을 한 줄씩 순회하며
## 타이핑 진행 상태를 갖고, advance()가 호출되면(UI가 클릭/스페이스 입력을 받으면) 다음 줄로 넘어간다.
##
## 저결합: 플레이어/NPC/맵/UI를 직접 참조하지 않는다. UI는 이 컨트롤러의 시그널만 구독하고
## advance()/select_choice()/set_auto_advance()/set_skip_mode()만 호출한다(DialogueUI.gd 참고).
## 캐릭터 생성/아이템 지급/맵 이동처럼 다른 시스템이 처리해야 하는 것들은 command_type="event"로 표시된
## DialogueCommand가 dialogue_event 시그널로만 방출되고, 실제 처리는 그 시그널을 구독하는(아직 없는)
## 시스템 쪽 책임이다 - 이 컨트롤러는 이벤트가 뭘 하는지 전혀 모른다.
##
## 선택지(8단계): 줄에 choices가 있으면 타이핑이 끝나는 순간 advance()가 막히고 choices_presented가
## 뜬다 - UI가 select_choice(index)를 호출해줘야 진행된다. 선택한 Choice의 commands를 먼저 실행하고,
## next_scene이 있으면 그 씬으로 갈아타고(scene_id는 안 바뀌어도 current_scene 참조만 교체), 없으면
## 그냥 지금 씬의 다음 줄로 이어간다.
##
## 자동 진행/로그(9단계): auto_advance가 켜져 있으면 타이핑이 끝난 뒤 auto_advance_delay초 후 자동으로
## advance() - 선택지가 떠 있으면 자동 진행 안 함(플레이어 선택 필요). log_entries는 지나간 줄을
## (speaker, text) 쌍으로 계속 쌓아두기만 하고, 보여주는 건 UI 책임.
##
## 스킵/저장(10단계): 이미 지나간 줄은 scene_id+줄 번호로 visited 처리되고, skip_mode 중엔 이미 본 줄만
## 즉시 리빌+즉시 진행한다 - 처음 보는 줄을 만나면 skip_mode가 자동으로 꺼진다(표준적인 VN 스킵 동작).
## get_save_data()/load_save_data()는 상태를 직렬화 가능한 Dictionary로 내주고 받는 것까지만 - 실제
## 파일 입출력은 이 프로젝트가 아직 "세이브 없음"을 전제로 하고 있어서(README) 범위 밖으로 남겨둔다.

signal line_started(line: DialogueLine)  # 새 줄 시작(타이핑 시작 직전) - UI가 이름/텍스트 초기화에 씀
signal line_typing_progress(revealed_text: String)  # 타이핑 진행 중 매 글자마다
signal line_finished_typing()  # 이번 줄 텍스트가 전부 드러남 - 다음 advance() 입력을 기다리는 상태로 전환
signal scene_started(scene: DialogueScene)
signal scene_finished()  # 마지막 줄까지 다 끝남
signal dialogue_event(event_name: String, params: Dictionary)  # event 타입 커맨드 방출용(저결합 통신)
signal choices_presented(choices: Array)  # Array[DialogueChoice] - UI가 선택지 버튼을 그려야 함
signal choice_selected(choice: DialogueChoice)
signal log_entry_added(speaker: String, text: String)
signal auto_advance_changed(enabled: bool)
signal skip_mode_changed(enabled: bool)
signal chapter_finished()  # play_chapter()로 재생한 마지막 씬까지 다 끝남

@export var chars_per_second: float = 35.0  # 타이핑 속도(초당 글자 수)
@export var auto_advance_delay: float = 1.2  # 자동 진행 시, 타이핑 끝난 뒤 다음 줄까지 대기 시간(초)
## 한 글자, "..." 처럼 아주 짧은 줄은 뜨자마자 이미 다 타이핑돼있어서, 빠르게 연달아 두 번 클릭하면
## (첫 클릭=이전 줄 reveal, 둘째 클릭=advance) 그 사이에 이 줄도 이미 다 드러난 상태라 읽을 새도 없이
## 바로 다음 줄로 넘어가 버린다(2026-08-01) - 줄이 다 드러난 시점부터 최소 이만큼은 advance()가 씹혀서
## 화면에 머물게 한다. skip_mode(이미 본 줄 빨리 넘기기)는 의도적으로 빠르게 넘기는 기능이라 예외로 둠.
@export var min_line_display_time: float = 0.3

var is_playing: bool = false
var current_scene: DialogueScene
var current_line_index: int = -1
var revealed_text: String = ""
var is_line_fully_revealed: bool = false
var pending_choices: Array = []  # Array[DialogueChoice] - 비어있지 않으면 advance() 무시, 선택 대기 중
var auto_advance: bool = false
var skip_mode: bool = false
## 켜져 있으면 DialogueUI가 클릭/스페이스를 완전히 무시한다(advance()는 여전히 코드로 직접 호출 가능) -
## 노래 가사처럼 플레이어가 끼어들면 안 되는, 완전히 자동재생이어야 하는 구간용(2026-08-01).
var input_locked: bool = false
var log_entries: Array = []  # Array[{"speaker": String, "text": String}]

var _typing_progress: float = 0.0
var _current_full_text: String = ""
var _typing_speed_scale: float = 1.0  # 현재 줄의 line.typing_speed_scale를 그대로 옮겨온 것 - style 자체는 모름
var _current_char_timings: PackedFloat32Array = PackedFloat32Array()  # 비어있지 않으면 균등 타이핑 대신 이걸로 리빌 판정(카라오케 동기화)
var _line_start_msec: int = 0  # char_timings 판정 기준(줄이 시작된 실제 시각)
## 커맨드 await 중 등 advance() 재진입을 막아야 하는 구간의 깊이. bool 하나가 아니라 카운터인 이유:
## scene_finished 시그널이 (chapter 자동 진행 등으로) 콜스택 안에서 곧바로 다음 play_scene()을 재귀적으로
## 트리거할 수 있는데, 그 안쪽 호출이 아직 안 끝난 채로 바깥쪽 호출이 먼저 끝나 _busy를 false로 되돌려
## 버리면(bool이었다면) 안쪽이 아직 블로킹 중(예: 다음 씬 첫 줄의 wait_for_completion 커맨드)인데도 재진입
## 방지가 풀려버린다. 카운터면 각자 자기가 늘린 만큼만 줄이므로 가장 안쪽이 끝나야 진짜 0이 된다.
var _busy_depth: int = 0
var _auto_advance_token: int = 0  # 자동 진행 타이머가 그 사이 상황이 바뀌었는지 확인하는 무효화 토큰
var _visited_keys: Dictionary = {}  # "scene_id:line_index" -> true, 스킵 판정용
var _line_revealed_at_msec: int = 0  # 현재 줄이 다 드러난 시각(min_line_display_time 판정용)
var _line_min_display_ms: float = 0.0  # 이번 줄의 실제 최소 유지시간(ms) - 아래 참고

var current_chapter: DialogueChapter
var _chapter_scene_index: int = -1


func play_scene(scene: DialogueScene) -> void:
	if not scene or scene.lines.is_empty():
		return
	current_scene = scene
	current_line_index = -1
	is_playing = true
	scene_started.emit(scene)
	# 감싸는 이유: 첫 줄의 commands_before에 wait_for_completion=true인 커맨드(예: fade_in 3초)가 있으면
	# 그동안 advance()가 재진입 방지 없이 통과돼서, 아직 line_started도 안 뜬 새 줄을 건너뛰고
	# _advance_to_next_line()이 중첩 호출되는 사고가 난다(줄이 하나 통째로 씹히고 순서가 꼬임).
	_busy_depth += 1
	await _advance_to_next_line()
	_busy_depth -= 1


## Chapter의 scenes를 선택지 없이 처음부터 끝까지 순서대로 이어 재생한다(컷씬처럼 끊김 없는 여러 씬
## 연출용). 각 씬은 독립된 DialogueScene 재생과 동일하게 동작하고(scene_started/scene_finished도 씬마다
## 그대로 발생), 마지막 씬까지 끝나면 chapter_finished를 추가로 emit한다.
func play_chapter(chapter: DialogueChapter) -> void:
	if not chapter or chapter.scenes.is_empty():
		return
	current_chapter = chapter
	_chapter_scene_index = 0
	if not scene_finished.is_connected(_on_chapter_scene_finished):
		scene_finished.connect(_on_chapter_scene_finished)
	await play_scene(chapter.scenes[0])


func _on_chapter_scene_finished() -> void:
	if not current_chapter:
		return
	_chapter_scene_index += 1
	if _chapter_scene_index >= current_chapter.scenes.size():
		current_chapter = null
		scene_finished.disconnect(_on_chapter_scene_finished)
		chapter_finished.emit()
		return
	await play_scene(current_chapter.scenes[_chapter_scene_index])


## bypass_min_display: auto_advance 내부 타이머(_schedule_auto_advance)처럼 이미 자체적인 지연 시간을
## 갖고 있는 호출 경로용 - min_line_display_time은 "플레이어가 두 번 빠르게 눌러서 씹히는" 상황(사용자
## 입력) 방지가 목적이라, auto_advance_delay가 min_line_display_time보다 짧게 설정된 경우(예: 카라오케
## 연출의 0.3초) 이 가드에 막혀 자동 진행이 영원히 멈추는 버그가 있었다(2026-08-01).
func advance(bypass_min_display: bool = false) -> void:
	if not is_playing or _busy_depth > 0 or not pending_choices.is_empty():
		return
	if not is_line_fully_revealed:
		_reveal_instantly()
		return
	if not bypass_min_display and not skip_mode and Time.get_ticks_msec() - _line_revealed_at_msec < _line_min_display_ms:
		return

	_busy_depth += 1
	if current_line_index >= 0 and current_line_index < current_scene.lines.size():
		var current_line: DialogueLine = current_scene.lines[current_line_index]
		for cmd in current_line.commands_after:
			await _run_command(cmd)
	await _advance_to_next_line()
	_busy_depth -= 1


## UI가 선택지 버튼 클릭 시 호출. choices_presented로 받은 배열의 인덱스를 그대로 넘기면 된다.
func select_choice(index: int) -> void:
	if index < 0 or index >= pending_choices.size():
		return
	var choice: DialogueChoice = pending_choices[index]
	pending_choices = []
	choice_selected.emit(choice)

	_busy_depth += 1
	for cmd in choice.commands:
		await _run_command(cmd)
	if choice.next_scene:
		current_scene = choice.next_scene
		current_line_index = -1
	await _advance_to_next_line()
	_busy_depth -= 1


func set_auto_advance(enabled: bool) -> void:
	auto_advance = enabled
	auto_advance_changed.emit(enabled)


## 이미 본 줄만 빠르게 넘긴다 - 처음 보는 줄을 만나면 자동으로 꺼진다(표준 VN 스킵 동작).
func set_skip_mode(enabled: bool) -> void:
	skip_mode = enabled
	skip_mode_changed.emit(enabled)
	if enabled:
		_try_skip_current()


## Chapter/Scene 선택 화면 등에서 이어하기용으로 쓸 상태 스냅샷. 실제 파일 저장/불러오기는 이 프로젝트
## 범위 밖(README의 "세이브 없음" 전제) - 여기서는 직렬화 가능한 Dictionary만 만들어준다.
func get_save_data() -> Dictionary:
	return {
		"scene_path": current_scene.resource_path if current_scene else "",
		"line_index": current_line_index,
		"auto_advance": auto_advance,
		"visited_keys": _visited_keys.duplicate(),
	}


func load_save_data(data: Dictionary) -> void:
	var scene_path: String = data.get("scene_path", "")
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return
	var scene: DialogueScene = load(scene_path)
	current_scene = scene
	current_line_index = data.get("line_index", -1)
	auto_advance = data.get("auto_advance", false)
	_visited_keys = data.get("visited_keys", {}).duplicate()
	is_playing = true
	scene_started.emit(scene)
	_busy_depth += 1  # play_scene()과 동일한 이유(첫 줄 commands_before 블로킹 중 재진입 방지)
	await _advance_to_next_line()
	_busy_depth -= 1


func stop() -> void:
	is_playing = false
	current_scene = null
	current_line_index = -1
	pending_choices = []


func _advance_to_next_line() -> void:
	current_line_index += 1
	if not current_scene or current_line_index >= current_scene.lines.size():
		is_playing = false
		scene_finished.emit()
		return

	var line: DialogueLine = current_scene.lines[current_line_index]

	for cmd in line.commands_before:
		await _run_command(cmd)

	_current_full_text = line.text
	revealed_text = ""
	_typing_progress = 0.0
	_typing_speed_scale = line.typing_speed_scale if line.typing_speed_scale > 0.0 else 1.0
	_current_char_timings = line.char_timings
	_line_start_msec = Time.get_ticks_msec()
	is_line_fully_revealed = line.text.is_empty()
	line_started.emit(line)
	log_entries.append({"speaker": line.speaker, "text": line.text})
	log_entry_added.emit(line.speaker, line.text)

	# 스킵 모드 + 이미 본 줄이면 타이핑 애니메이션 없이 바로 전체 텍스트를 보여준다(표준 VN 스킵 동작).
	if not is_line_fully_revealed and skip_mode and _is_current_visited():
		revealed_text = _current_full_text
		is_line_fully_revealed = true
		line_typing_progress.emit(revealed_text)

	if is_line_fully_revealed:
		_on_line_finished_typing()


func _reveal_instantly() -> void:
	revealed_text = _current_full_text
	is_line_fully_revealed = true
	line_typing_progress.emit(revealed_text)
	_on_line_finished_typing()


func _process(delta: float) -> void:
	if not is_playing or is_line_fully_revealed:
		return
	var count: int
	if _current_char_timings.size() > 0:
		# 균등 속도 대신 글자별 실측 타이밍으로 리빌(카라오케 동기화 등) - i번째 값 = i번째 글자가
		# 나와야 할, 줄 시작 기준 경과 초. 타이밍 배열보다 텍스트가 길면 나머지는 마지막 글자 속도로 자연히 이어짐.
		var elapsed: float = (Time.get_ticks_msec() - _line_start_msec) / 1000.0
		count = 0
		while count < _current_char_timings.size() and count < _current_full_text.length() and _current_char_timings[count] <= elapsed:
			count += 1
		count = min(count, _current_full_text.length())
	else:
		_typing_progress += chars_per_second * _typing_speed_scale * delta
		count = min(int(_typing_progress), _current_full_text.length())
	if count > revealed_text.length():
		revealed_text = _current_full_text.substr(0, count)
		line_typing_progress.emit(revealed_text)
	if count >= _current_full_text.length():
		is_line_fully_revealed = true
		_on_line_finished_typing()


## 타이핑이 끝난 시점(즉시/자연 완료 공통 경유지) - 이 줄을 visited 처리하고, 선택지/스킵/자동진행을
## 순서대로 판단한다(선택지가 있으면 최우선, 그다음 스킵, 그다음 자동진행).
func _on_line_finished_typing() -> void:
	_line_revealed_at_msec = Time.get_ticks_msec()
	_line_min_display_ms = _compute_min_display_ms(current_scene.lines[current_line_index])
	_mark_current_visited()
	line_finished_typing.emit()

	var line: DialogueLine = current_scene.lines[current_line_index]
	if not line.choices.is_empty():
		pending_choices = line.choices
		choices_presented.emit(pending_choices)
		return

	if skip_mode:
		_try_skip_current()
		return

	if auto_advance:
		_schedule_auto_advance()


## min_line_display_time은 "짧은 줄이 순식간에 지나가지 않게"용 최소값일 뿐이라, shake/zoom처럼 그
## 자체로 0.5초보다 긴 화면 연출이 commands_before에 걸린 줄은 그 연출이 다 끝나기도 전에 다음 줄로
## 넘어가 버릴 수 있었다(2026-08-01, "효과들 빠르게 넘기면 안 보인다" 버그) - 그 줄의 commands_before
## 중 duration 파라미터가 있는 커맨드들과 min_line_display_time 중 더 큰 값을 실제 최소 유지시간으로 쓴다.
func _compute_min_display_ms(line: DialogueLine) -> float:
	var longest: float = min_line_display_time
	for cmd in line.commands_before:
		if cmd.params.has("duration"):
			longest = max(longest, float(cmd.params["duration"]))
	return longest * 1000.0


## advance()를 바로 부르지 않고 call_deferred로 미루는 이유: 이 함수는 종종 advance() 자신의 호출
## 스택 안쪽(리빌 완료 -> _on_line_finished_typing -> 스킵 판정)에서 재귀적으로 트리거된다. 그 상태에서
## advance()를 직접 부르면 아직 스택에 남아있는 바깥쪽 advance()의 _busy 재진입 방지 플래그에 막혀
## 아무 일도 안 하고 조용히 무시된다(여러 줄 연속 스킵이 첫 줄만 넘기고 멈추는 버그). 다음 프레임으로
## 미루면 그 시점엔 바깥쪽 advance() 호출이 이미 완전히 끝나 _busy가 풀려있으므로 안전하다.
func _try_skip_current() -> void:
	if current_line_index < 0 or not current_scene:
		return
	if not _is_current_visited():
		skip_mode = false
		skip_mode_changed.emit(false)
		return
	call_deferred("advance")


func _schedule_auto_advance() -> void:
	_auto_advance_token += 1
	var token: int = _auto_advance_token
	await get_tree().create_timer(auto_advance_delay).timeout
	if token != _auto_advance_token:
		return  # 그 사이 다른 진행이 있었음(플레이어가 직접 넘겼거나 등) - 무효
	if auto_advance and is_playing and is_line_fully_revealed and _busy_depth == 0 and pending_choices.is_empty():
		advance(true)


func _mark_current_visited() -> void:
	_visited_keys[_line_key(current_scene, current_line_index)] = true


func _is_current_visited() -> bool:
	return _visited_keys.has(_line_key(current_scene, current_line_index))


func _line_key(scene: DialogueScene, line_index: int) -> String:
	var id: String = scene.scene_id if scene and not scene.scene_id.is_empty() else str(scene.get_instance_id())
	return "%s:%d" % [id, line_index]


func _run_command(cmd: DialogueCommand) -> void:
	if cmd.command_type == "event":
		dialogue_event.emit(cmd.params.get("name", ""), cmd.params)
		return
	var handler: DialogueCommandHandler = DialogueCommandRegistry.get_handler(cmd.command_type)
	if not handler:
		push_warning("Dialogue: unknown command type '%s'" % cmd.command_type)
		return
	if cmd.wait_for_completion:
		await handler.execute(cmd.params)
	else:
		handler.execute(cmd.params)
