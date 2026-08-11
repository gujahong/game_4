extends Node

## 대사 시스템이 실제로 도는지 확인하는 씬. **게임 내용이 아니다.**
##
## 대사 데이터는 원래 .tres 리소스로 만들어 인스펙터에서 편집하는 것이 정석이지만, 여기서는
## 코드로 급조해서 다음 넷만 본다.
##
##   1. 글자가 한 자씩 타이핑되는가
##   2. 클릭/스페이스로 넘어가는가 (그리고 타이핑 중에 누르면 즉시 전부 드러나는가)
##   3. style이 먹는가 (narration은 회색 기울임, important는 등불색)
##   4. 커맨드가 먹는가 (shake로 대사창이 흔들리는가)
##   5. 선택지가 뜨고, 고르면 이어지는가
##
## 이야기가 정해지면 이 파일은 버리고 .tres로 옮긴다.


func _ready() -> void:
	Dialogue.play_scene(_build_test_scene())
	if "--capture" in OS.get_cmdline_user_args():
		_capture_and_quit()


## `-- --capture`로 실행하면 대사 화면과 선택지 화면을 한 장씩 찍고 끝낸다(확인용).
func _capture_and_quit() -> void:
	await _shoot("res://tools/_dialogue_line.png", 1.2)
	for _step in 20:
		if not Dialogue.pending_choices.is_empty():
			break
		Dialogue.advance()
		await get_tree().create_timer(0.4).timeout
	await _shoot("res://tools/_dialogue_choice.png", 0.4)
	get_tree().quit()


func _shoot(path: String, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("저장: ", path)


func _build_test_scene() -> DialogueScene:
	var scene := DialogueScene.new()
	scene.scene_id = "test"

	_add(scene, _line("", "등불을 들어 올리자 예배당이 드러났다.", "narration"))
	_add(scene, _line("나", "여기서 얼마나 기다린 겁니까."))

	var shaken := _line("", "어디선가 무언가 무너지는 소리가 났다.", "narration")
	shaken.commands_before.append(_command("shake", {"amount": 3.0, "duration": 0.4}, true))
	_add(scene, shaken)

	_add(scene, _line("낯선 이", "불빛을 오랜만에 봅니다.", "important"))

	var asked := _line("낯선 이", "그 등불, 어디서 났습니까?")
	asked.choices.append(_choice("주웠다고 답한다"))
	asked.choices.append(_choice("아무 말도 하지 않는다"))
	_add(scene, asked)

	_add(scene, _line("낯선 이", "그렇군요. 그럼 됐습니다."))
	return scene


func _add(scene: DialogueScene, line: DialogueLine) -> void:
	scene.lines.append(line)


func _line(speaker: String, text: String, style: String = "normal") -> DialogueLine:
	var line := DialogueLine.new()
	line.speaker = speaker
	line.text = text
	line.style = style
	return line


func _command(type: String, params: Dictionary, wait_for_completion: bool = false) -> DialogueCommand:
	var command := DialogueCommand.new()
	command.command_type = type
	command.params = params
	command.wait_for_completion = wait_for_completion
	return command


func _choice(text: String) -> DialogueChoice:
	var choice := DialogueChoice.new()
	choice.text = text
	return choice
