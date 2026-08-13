extends Node2D

## **조우 연출.** 일러스트 한 장이 뜨고, 그림 속 제단에 그것이 서 있고, 내가 걸어서 다가간다.
## 닿으면 전투가 시작된다.
##
## 평소 지역을 돌아다니는 것은 탑다운이고, **이 화면은 보스나 큰 조우에서만 쓴다**(2026-08-11 결정).
## 매 장면이 이러면 무뎌지지만, 어쩌다 한 번이면 사건이 된다 - 압도감은 희소해야 산다.
##
## ### 그것은 배경에 못 박혀 있다. 움직이는 것은 나뿐이다.
##
## 처음에는 그것에게 배경과 다른 원근 곡선을 줬는데(그것은 깊이^2.2로 커지고 배경은 일정하게
## 확대됨), **제단에 서 있는 게 아니라 배경 위를 미끄러져서 어색했다**(2026-08-11, 회원님 지적).
## 이제 그것의 자리와 크기는 전부 **그림 사각형에 대한 비율**로만 정해진다 - 그림이 확대되면
## 정확히 같은 비율로 같이 커지므로, 그림에 그려 넣은 것과 구별되지 않는다.
##
## 그래서 **내가 커졌다 작아진다.** 가까울 때는 꽤 크게 시작해서 안으로 갈수록 작아지고,
## 그것은 처음부터 끝까지 그 자리에 그대로 크다. 경외감은 그것이 커지는 데서 오는 게 아니라
## **내가 작아지는 데서** 온다 - 참고로 주신 협곡 그림이 그렇게 되어 있다.
##
## 우리가 싸울 것들은 대개 **엄청나게 커다란 무언가**라서(회원님), 그것을 처음부터 크게 그려놓고
## 안 움직여도 된다. 안 움직이는 게 더 무섭다 - 쫓아오면 도망이라도 치는데, 기다리고 있으면
## 내 발로 가는 수밖에 없다.
##
## 시점의 근거: 회원님이 주신 참고 그림 일곱 장이 예외 없이 1점 투시였고, 사람은 전부 **등을 보인 채**
## 안쪽을 향하고 있었다. 등이 보인다는 건 카메라가 옆이 아니라 **내 뒤**에 있다는 뜻이다.

const PHOTO_DIR := "res://assets/photos"
const BATTLE_SCENE := "res://scenes/Battle.tscn"
## 처음에 띄울 사진. 비워두면 폴더의 첫 장부터. Space로 넘기며 볼 수 있지만, 지금 보고 싶은
## 그림이 정해져 있을 때 여섯 번 누르지 않으려고 둔다.
## 조우가 벌어지는 곳의 그림. **첫 조우는 아카식 서고 안**이다(2026-08-13).
##
## 전에는 `gate_3.png`를 가리키고 있었는데 **그 파일이 저장소에 없어서 열면 그대로 깨졌다.**
## 다른 컴퓨터에서 만들고 안 올린 것으로 보인다.
const START_PHOTO := "archive.png"

const CENTRE := Vector2(480, 270)

## 걷는 바닥. **그림 사각형에 대한 비율**이라 320/448/512 어느 크기든 그대로 맞는다.
## 세로: 가까우면 아래(0.90), 그것 앞까지 가면 위(0.66). 그림마다 소실점 자리가 달라서
## 눈으로 맞춰야 한다(Space로 넘겨보며 확인할 것).
const NEAR_Y := 0.90
const FAR_Y := 0.66

## 가로로 벗어날 수 있는 폭(가운데에서 한쪽으로). **깊을수록 좁아진다.**
## 1점 투시에서 바닥은 사다리꼴이다 - 멀리서 옆으로 한 걸음 옮겨도 화면에서는 조금밖에 안 움직인다.
## 고정 픽셀로 주면 원근이 깨져서 인물이 바닥 위를 미끄러진다.
const NEAR_HALF := 0.30
const FAR_HALF := 0.05

## 내 키(그림 높이에 대한 비율). 꽤 크게 시작해서 안으로 갈수록 작아진다.
const FIGURE_NEAR := 0.16
const FIGURE_FAR := 0.045
const FIGURE_ASPECT := 0.33   ## 폭 = 키 * 이것. 넓으면 사람이 아니라 덩어리로 읽힌다
const FIGURE_COLOR := Color(0.02, 0.02, 0.03, 1.0)

## 등불 빛의 크기(내 키에 대한 비율). 나와 같이 작아진다.
const GLOW_OF_HEIGHT := 3.2

## --- 그것 ---

## 그것이 서 있는 자리와 키(그림 비율). 성당이면 제단, 협곡이면 골짜기 끝.
##
## **그림마다 다르므로 눈으로 맞춘다.** 제단 높이도, 그림 속 원근도 장면마다 다르고, 스프라이트
## 아래에 남은 투명 여백까지 얽혀서 계산으로는 안 나온다. 실행 중에 [ ] - = 로 옮겨보고,
## 맞은 값을 그 장면의 데이터로 적어둔다(FilterPreview에서 필터 값을 맞추던 방식과 같다).
const TARGET_AT_DEFAULT := Vector2(0.5, 0.72)
## **크게 잡는다** - 우리가 싸울 것들은 대개 엄청나게 큰 것들이다.
const TARGET_HEIGHT_DEFAULT := 0.44
const NUDGE := 0.01
## 안개에 묻혀 조금 눌러둔다. 배경과 명암을 맞춰야 오려붙인 티가 안 난다.
const TARGET_DIM := 0.74
## 조우 상대. 아카식 서고를 지키는 **눈으로 뒤덮인 고리**다(2026-08-13).
## 배경은 `tools/_cutbg.gd`로 도려냈고 원본은 `watcher_raw.png`에 남아 있다.
const TARGET_PATH := "res://assets/enemies/watcher.png"

## --- 움직임 ---

## 한 장면을 끝까지 걷는 데 걸리는 시간(초). **일부러 느리다** - 가는 동안 아무 일도 안 일어나는
## 것이 외로움을 만든다. 빠르면 그냥 이동이 되어버린다.
const WALK_SECONDS := 12.0
const SIDE_SECONDS := 7.0

## 다가갈수록 그림이 커진다(달리 인). 그것도 그림에 못 박혀 있으니 같이 커진다 - 어긋나지 않는다.
const DOLLY_MAX := 1.30

## 배율을 끊는 단위(Q). 격자를 화면에 못 박은 뒤로는 안 켜도 멀쩡하지만, 다른 그림에서
## 지글거리면 켜본다.
const ZOOM_STEP := 0.1

var _picture: FilteredSprite
var _target: FilteredSprite
var _lamp: LampGlow
## 실루엣은 **등불보다 위에** 그려야 한다. 등불 빛이 blend_add라서 아래에 그리면 빛이 더해져
## 검은 사람이 지워진다(2026-08-11, 첫 캡처에서 사람이 아예 안 보였다). 참고 그림의 협곡도
## 밝은 빛 **안에** 검은 점이 박혀 있는 구조다.
var _figure: Node2D
var _status: Label

var _paths: PackedStringArray = PackedStringArray()
var _index := 0
var _depth := 0.0      ## 0 = 그림 앞, 1 = 그것 앞
var _side := 0.0       ## -1 = 바닥 왼쪽 끝, 0 = 가운데, 1 = 오른쪽 끝
var _dolly := true
var _fill := true      ## 사진을 화면 높이에 맞춰 채울 것인가
var _quantise := false ## 배율과 자리를 단계로 끊을 것인가
var _screen_dither := true  ## 디더 격자를 화면에 못 박을 것인가(2026-08-11 확정: 켠다)
var _arrived := false

var _target_foot := TARGET_AT_DEFAULT.y
var _target_height := TARGET_HEIGHT_DEFAULT

## 그림의 **초점**이 가로로 어디에 있는가(그림 폭에 대한 비율). 문·제단처럼 내가 향해 가는 곳이다.
##
## 생성기가 주제를 정확히 한가운데 놓아주지 않는다(`gate_2`는 오른쪽으로 조금 밀려 있다).
## 그림을 다시 뽑는 대신 **놓는 자리로 잡는다** - 이 값이 화면 한가운데에 오도록 그림을 좌우로
## 밀고, 걷는 길과 그것의 자리도 같은 값을 쓰므로 셋이 저절로 한 줄에 선다.
## gate_2 · gate_3 둘 다 재보니 0.63이었다. pixen이 주제를 일관되게 오른쪽에 놓는다 -
## 프롬프트에 `centred in the frame`을 넣은 것(0.630)과 안 넣은 것(0.632)이 사실상 같았으므로,
## **말로는 안 고쳐지고 놓는 자리로 잡아야 한다.**
var _focus_x := 0.63


func _ready() -> void:
	_paths = _find_photos()

	_picture = FilteredSprite.new()
	_picture.z_index = -10
	_picture.position = CENTRE
	add_child(_picture)

	# 그림보다 위, 나보다 아래. 배경과 같은 필터를 통과해야 오려붙인 티가 안 난다.
	_target = FilteredSprite.new()
	_target.z_index = -5
	_target.texture = load(TARGET_PATH)
	_target.layer_modulate = Color(TARGET_DIM, TARGET_DIM, TARGET_DIM, 1.0)
	add_child(_target)

	_lamp = LampGlow.new()
	_lamp.z_index = 5
	add_child(_lamp)

	_figure = Node2D.new()
	_figure.z_index = 10
	_figure.draw.connect(_draw_figure)
	add_child(_figure)

	_build_status()
	_apply_dither_anchor()
	_show_photo(_start_index())

	if "--capture" in OS.get_cmdline_user_args():
		_capture_and_quit()


func _process(delta: float) -> void:
	if _arrived:
		return
	var forward := Input.get_axis("ui_down", "ui_up")
	var sideways := Input.get_axis("ui_left", "ui_right")
	if forward == 0.0 and sideways == 0.0:
		return
	_depth = clampf(_depth + forward * delta / WALK_SECONDS, 0.0, 1.0)
	_side = clampf(_side + sideways * delta / SIDE_SECONDS, -1.0, 1.0)
	_refresh()
	if _depth >= 1.0:
		_arrive()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_SPACE:
			_show_photo(_index + 1)
		KEY_D:
			_dolly = not _dolly
			_refresh()
		KEY_F:
			_fill = not _fill
			_refresh()
		KEY_Q:
			_quantise = not _quantise
			_refresh()
		KEY_G:
			_screen_dither = not _screen_dither
			_apply_dither_anchor()
			_refresh()
		KEY_BRACKETLEFT:
			_target_foot -= NUDGE
			_refresh()
		KEY_BRACKETRIGHT:
			_target_foot += NUDGE
			_refresh()
		KEY_COMMA:
			_focus_x = maxf(_focus_x - NUDGE, 0.0)
			_refresh()
		KEY_PERIOD:
			_focus_x = minf(_focus_x + NUDGE, 1.0)
			_refresh()
		KEY_MINUS:
			_target_height = maxf(_target_height - NUDGE, 0.05)
			_refresh()
		KEY_EQUAL:
			_target_height += NUDGE
			_refresh()
		KEY_R:
			_depth = 0.0
			_side = 0.0
			_arrived = false
			_refresh()
		_:
			return
	get_viewport().set_input_as_handled()


# --- 그림이 놓이는 자리 ---

## 사진이 화면에 놓이는 기본 배율. 1.0이면 320짜리 사진이 960x540 한가운데 작게 떠서
## **"그 안에 들어간다"가 아니라 "사진을 본다"**가 된다. 채우기를 켜면 화면 높이에 맞춘다.
func _base_scale() -> float:
	if not _fill or _picture.texture == null:
		return 1.0
	return 540.0 / float(_picture.texture.get_size().y)


func _display_scale() -> float:
	var dolly: float = lerpf(1.0, DOLLY_MAX, _depth) if _dolly else 1.0
	var scale: float = _base_scale() * dolly
	if _quantise:
		scale = roundf(scale / ZOOM_STEP) * ZOOM_STEP
	return maxf(ZOOM_STEP, scale)


## 그림이 실제로 놓인 사각형. 그것과 나의 자리·크기는 전부 이 사각형에 대한 비율로 정해진다 -
## 그래서 그림이 커지면 셋이 정확히 같이 커진다.
func _picture_rect() -> Rect2:
	if _picture.texture == null:
		return Rect2(CENTRE, Vector2.ZERO)
	var size: Vector2 = Vector2(_picture.texture.get_size()) * _picture.scale
	# 초점이 화면 한가운데(CENTRE.x) 오도록 좌우로 민다. 세로는 그냥 가운데.
	return Rect2(Vector2(CENTRE.x - size.x * _focus_x, CENTRE.y - size.y * 0.5), size)


## 지금 내가 서 있는 화면 좌표. 발이 닿는 자리다. 바닥이 사다리꼴이라 깊이가 세로 자리와
## 가로로 벗어날 수 있는 폭을 **동시에** 정한다.
func _foot_position() -> Vector2:
	var rect := _picture_rect()
	var across: float = _focus_x + _side * lerpf(NEAR_HALF, FAR_HALF, _depth)
	var along: float = lerpf(NEAR_Y, FAR_Y, _depth)
	return rect.position + rect.size * Vector2(across, along)


## 내 키(화면 픽셀).
func _figure_height() -> float:
	return _picture_rect().size.y * lerpf(FIGURE_NEAR, FIGURE_FAR, _depth)


# --- 화면 갱신 ---

func _refresh() -> void:
	var scale := _display_scale()
	_picture.scale = Vector2(scale, scale)
	var rect := _picture_rect()
	_picture.position = _snap(rect.position + rect.size * 0.5)

	var foot := _foot_position()
	var height := _figure_height()

	# 등불은 손 높이, 몸 옆에 든다. 몸에 겹치면 빛이 실루엣을 가린다.
	_lamp.position = _snap(foot + Vector2(height * FIGURE_ASPECT * 0.8, -height * 0.5))
	_lamp.glow_size = maxi(int(height * GLOW_OF_HEIGHT), 8)

	_place_target()

	_status.text = "깊이 %d%%   초점 %.2f   그것: 발 %.2f  키 %.2f   [%s]\n↑↓←→ 걷기 / , . 좌우 초점 / [ ] 발높이 / - = 크기 / Space 사진 / F 채우기 / R 처음" % [
		int(_depth * 100.0), _focus_x, _target_foot, _target_height,
		_paths[_index].get_file() if not _paths.is_empty() else ""
	]
	_figure.queue_redraw()


## 그것은 **깊이를 전혀 안 본다.** 자리와 크기가 그림 사각형에 대한 비율로만 정해지므로,
## 그림에 그려 넣은 것처럼 그 자리에 붙어 있다. 그림이 확대되면 정확히 같이 커진다.
func _place_target() -> void:
	if _target.texture == null:
		return
	var rect := _picture_rect()
	var texture_height: float = float(_target.texture.get_size().y)
	var grow: float = rect.size.y * _target_height / texture_height
	_target.scale = Vector2(grow, grow)

	var foot := rect.position + rect.size * Vector2(_focus_x, _target_foot)
	_target.position = _snap(foot - Vector2(0.0, texture_height * grow * 0.5))


## 실루엣. 발이 _foot_position()에 닿게 그린다 - 위로 갈수록 작아지는 것이 곧 멀어지는 것이다.
## 등불(z 5)보다 위(z 10)에 있어야 빛에 지워지지 않는다.
## 뒷모습 실루엣. 머리 하나에 몸통 하나뿐이지만, 사각형 하나보다는 사람으로 읽힌다.
## 어차피 참고 그림에서도 사람은 실루엣일 뿐이라, 그림이 생겨도 크게 달라지지 않을 것이다.
func _draw_figure() -> void:
	var height := _figure_height()
	var width := height * FIGURE_ASPECT
	var foot := _snap(_foot_position())

	var head := width * 0.36
	var body_top := foot.y - height + head * 1.6
	_figure.draw_rect(
		Rect2(foot.x - width * 0.5, body_top, width, foot.y - body_top), FIGURE_COLOR
	)
	_figure.draw_circle(Vector2(foot.x, body_top - head * 0.6), head, FIGURE_COLOR)


## 그림과 그것이 같은 격자 기준을 쓰게 맞춘다. 둘이 다르면 한쪽만 기어다녀서 오려붙인 티가 난다.
func _apply_dither_anchor() -> void:
	for sprite in [_picture, _target]:
		if sprite.material is ShaderMaterial:
			sprite.material.set_shader_parameter("dither_on_screen", _screen_dither)


## 화면 좌표를 픽셀 격자에 맞춘다. 소수점 자리에 놓인 스프라이트는 매 프레임 다른 픽셀에
## 걸려서 디더가 기어다닌다.
func _snap(point: Vector2) -> Vector2:
	return point.round() if _quantise else point


# --- 사진 ---

func _find_photos() -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(PHOTO_DIR)
	if dir == null:
		push_error("사진 폴더를 못 열었다: %s" % PHOTO_DIR)
		return found
	for file in dir.get_files():
		if file.get_extension().to_lower() == "png":
			found.append("%s/%s" % [PHOTO_DIR, file])
	found.sort()
	return found


## START_PHOTO와 이름이 같은 사진의 자리. 못 찾으면 첫 장.
func _start_index() -> int:
	for i in _paths.size():
		if _paths[i].get_file() == START_PHOTO:
			return i
	return 0


func _show_photo(index: int) -> void:
	if _paths.is_empty():
		return
	_index = index % _paths.size()
	_picture.texture = load(_paths[_index])
	_depth = 0.0
	_side = 0.0
	_arrived = false
	_refresh()


# --- 도착 ---

## 끝까지 들어가면 조우가 벌어진다. **카메라를 안 돌린다** - 걷기와 전투가 같은 시점(정면, 아래에서
## 위를 봄)이라 화면만 갈릴 뿐 보는 방향은 그대로다.
func _arrive() -> void:
	_arrived = true
	_status.text = "무언가가 앞을 막아섰다."
	await get_tree().create_timer(1.2).timeout
	get_tree().change_scene_to_file(BATTLE_SCENE)


func _build_status() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 101
	add_child(layer)

	_status = Label.new()
	KoreanFont.apply(_status)
	_status.add_theme_color_override("font_color", UiStyle.TEXT_DIM)
	_status.position = Vector2(14, 12)
	layer.add_child(_status)


## 확인용. `-- --capture`로 실행하면 깊이 세 단계를 한 장씩 찍고 끝낸다.
func _capture_and_quit() -> void:
	_status.visible = false
	for depth in [0.0, 0.5, 0.95]:
		_depth = depth
		_refresh()
		await _shoot("res://tools/_walk_%02d.png" % int(depth * 100.0))
	get_tree().quit()


func _shoot(path: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("저장: ", path)
