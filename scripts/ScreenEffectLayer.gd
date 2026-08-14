extends CanvasLayer
class_name ScreenEffectLayer

## 화면 전체를 덮는 이펙트 레이어(페이드/암전/플래시). Autoload "ScreenEffect"로 등록해서 대사 Command
## 핸들러뿐 아니라 다른 시스템도 어디서든 `ScreenEffect.fade_out(1.0)` 식으로 바로 쓸 수 있다 - 대사
## 시스템에 종속되지 않은 범용 유틸리티다. DialogueCommandFadeIn 등은 이걸 그대로 호출만 하는 얇은
## 어댑터일 뿐이라, 화면 효과 자체는 대사 시스템 없이도(예: 게임오버 페이드아웃 등) 재사용 가능하다.
## layer=100으로 다른 대부분의 CanvasLayer보다 위에 그려지도록 고정.
##
## (2026-08-01) 단, DialogueUI(layer=101)는 예외로 이보다 더 위에 있음 - 오프닝 프롤로그처럼 "검은
## 화면 + 시스템 경고 텍스트"를 함께 보여줘야 하는 연출이 있어서, blackout/fade가 걸려 있어도 대사
## 텍스트 패널만은 항상 읽을 수 있어야 한다(이전엔 대사 패널까지 같이 가려져서 클릭해도 아무 반응이
## 없는 것처럼 보이는 버그가 있었음).
##
## (2026-08-01) flash()만은 예외 - "화면이 밝아집니다" 연출은 대사 패널의 불투명한 프레임
## 배경(StyleBoxTexture)까지 포함해서 화면 전체가 순간적으로 번쩍여야 제대로 느껴진다("밝아지긴 하는데
## 지금 UI뒤로 밝아져" 버그 리포트). 그래서 flash 전용으로 DialogueUI(101)보다도 위인 layer=102짜리
## 별도 CanvasLayer를 하나 더 둔다 - fade/blackout은 여전히 대사창 아래(100)에 있어 텍스트 가독성을
## 지키고, flash만 화면 최상단에서 전체를 덮는다.

var _rect: ColorRect
var _flash_layer: CanvasLayer
var _flash_rect: ColorRect


func _ready() -> void:
	layer = 100
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)

	_flash_layer = CanvasLayer.new()
	_flash_layer.layer = 102
	add_child(_flash_layer)
	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(0, 0, 0, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_layer.add_child(_flash_rect)


## above_ui=true면 대사창(101)보다도 위인 flash용 레이어(102)를 써서 UI까지 포함해 화면 전체를 덮는다
## (2026-08-01, "화면이 하얗게 번지며 전환에서 UI는 안 번져" - 장면 전환용 흰 페이드는 대사 패널까지
## 같이 번져야 자연스럽다). 기본값 false는 기존 동작(암전 등, 대사 텍스트는 항상 읽히게) 그대로 유지.
func fade_out(duration: float, color: Color = Color.BLACK, above_ui: bool = false) -> void:
	var target: ColorRect = _flash_rect if above_ui else _rect
	target.color = Color(color.r, color.g, color.b, target.color.a)
	var tween := create_tween()
	tween.tween_property(target, "color:a", 1.0, max(duration, 0.001))
	await tween.finished


## 어느 쪽 레이어로 fade_out했는지 호출부가 따로 안 알려줘도 되게, 두 레이어를 한꺼번에 걷어낸다 - 이미
## 투명한 쪽은 그냥 무해하게 같이 트윈될 뿐이라 상태를 따로 추적할 필요가 없다.
func fade_in(duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(_rect, "color:a", 0.0, max(duration, 0.001))
	tween.parallel().tween_property(_flash_rect, "color:a", 0.0, max(duration, 0.001))
	await tween.finished


func flash(duration: float, color: Color = Color.WHITE) -> void:
	_flash_rect.color = Color(color.r, color.g, color.b, 1.0)
	var tween := create_tween()
	tween.tween_property(_flash_rect, "color:a", 0.0, max(duration, 0.001))
	await tween.finished


func set_blackout(enabled: bool, color: Color = Color.BLACK) -> void:
	_rect.color = Color(color.r, color.g, color.b, 1.0 if enabled else 0.0)


## fade_out()과 달리 부드럽게 트윈하지 않고 alpha를 딱딱 끊어서 켰다 껐다 반복한다("깜빡깜빡") - 끝나면
## dark_alpha로 고정(요청: "화면이 깜빡깜빡 하고 어두워지고(페이드아웃X)").
func flicker(cycles: int, interval: float, dark_alpha: float = 0.7, color: Color = Color.BLACK) -> void:
	for i in range(cycles):
		_rect.color = Color(color.r, color.g, color.b, dark_alpha)
		await get_tree().create_timer(interval).timeout
		_rect.color = Color(color.r, color.g, color.b, 0.0)
		await get_tree().create_timer(interval).timeout
	_rect.color = Color(color.r, color.g, color.b, dark_alpha)


## 어느 씬에서나 듣는 키 둘. **자동 로드라 여기 두면 씬마다 안 넣어도 된다.**
##
## Godot은 Esc에 아무것도 안 걸어둔다 — 창을 끄려면 Alt+F4밖에 없어서 확인할 때마다 번거로웠다.
func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
	match (event as InputEventKey).keycode:
		KEY_ESCAPE:
			get_tree().quit()
		KEY_F11:
			var full: bool = (DisplayServer.window_get_mode()
				== DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full
				else DisplayServer.WINDOW_MODE_FULLSCREEN)
