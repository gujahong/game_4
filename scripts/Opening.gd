extends Node2D
class_name Opening

## 게임을 켜면 나오는 화면.
##
## ```
## 1. 캄캄하다
## 2. 등불이 번지며 들어온다 — 디더 격자 때문에 빛 가장자리가 점으로 흩어지며 물러난다
## 3. 그림이 옆으로 밀리며 관문이 드러난다
## ```
##
## 밀리는 것은 **정수 픽셀로 끊는다.** 부드럽게 밀면 도트가 반 칸씩 어긋나 뭉개진다.
##
## 문 너머의 세계는 `PortalWave`로 일렁인다 - 저 안은 꿈이고 여긴 아니라는 것을 움직임으로
## 말한다. 관문 밖은 멎어 있다.

const PICTURE := "res://assets/photos/gate_4_wide.png"
const BEYOND := "res://assets/photos/archive.png"
const FIGURE := "res://assets/photos/pilgrim.png"
const TRACK := "res://assets/music/title.mp3"
## 곡의 이 지점부터 쓴다(회원님). 앞의 도입부는 안 쓰고, 한 바퀴 돌아도 여기로 돌아온다.
const TRACK_FROM := 26.0
const WAVE_SHADER := "res://shaders/PortalWave.gdshader"
const LEAK_SHADER := "res://shaders/PortalLeak.gdshader"

const SCREEN := Vector2(960, 540)

## 실루엣 그림 안에서 발밑과 등불이 있는 자리. `tools/_silhouette.gd` 기준이다.
##
## **발밑을 기준점으로 삼는다.** 안쪽으로 걸어가면 작아지는데, 왼쪽 위 귀퉁이를 기준으로 두면
## 작아질 때 발이 바닥에서 떠오른다.
const FOOT_IN_FIGURE := Vector2(18, 76)
const LANTERN_IN_FIGURE := Vector2(34, 38)

## 순례자가 처음 서 있는 자리(발밑, 화면 좌표). 다 밀린 뒤 기준이다.
##
## 키가 72px이라 470px짜리 관문의 6분의 1이 조금 넘는다. **관문의 크기는 사람이 옆에 서야
## 비로소 읽힌다** - 이 실루엣이 없으면 그냥 큰 그림일 뿐이다.
const FIGURE_AT := Vector2(420, 512)

## 문 구멍의 가운데(`gate_4_wide` 기준). `tools/_extend.gd`가 재서 알려준다 -
## 늘리면서 0.631에서 0.869로 옮겨갔다.
const OPENING := Vector2(0.869, 0.545)

## 늘려 붙인 자리와 원본 그림이 만나는 지점(가로 비율). `_extend.gd`가 재서 알려준다.
## 여기까지만 일렁이고 그 오른쪽 관문은 멎어 있다.
const SEAM := 0.644

## 처음에 그림을 오른쪽으로 밀어둔 양(픽셀). 처음엔 그림의 왼쪽 끝(빈 벌판)만 보이다가,
## 밀려 나가면서 오른쪽의 관문이 들어온다.
##
## 그림은 화면보다 이만큼 넓게 만들어져 있다(`_extend.gd`의 `ADD_LEFT`). 그래서 미는 동안
## 어느 쪽에도 검은 여백이 생기지 않는다 - 폭을 딱 960으로 맞췄더니 그림 끝이 검은 수직선으로
## 드러났다(2026-08-12).
const PAN_FROM := 300.0

## 연출 순서. 앞에서부터 차례로 이어 붙는다.
##
## ```
## 어둠 → 글이 한 단어씩 → 그대로 둠 → 글이 사라짐 → 다시 어둠
##      → 등불에 불이 붙음 → 그 불에서 빛이 번져 화면을 덮음 → 옆으로 밀림
## ```
##
## **빛은 화면 가운데가 아니라 등불에서 나간다.** 등불이 불빛의 출처라는 것이 이 게임의
## 규칙이라, 연출도 거기서 시작해야 말이 맞는다.
const DARK_SECONDS := 0.8    ## 아무것도 없는 어둠
const WRITE_SECONDS := 7.0   ## 글이 다 쓰이기까지
const READ_SECONDS := 0.8    ## 다 쓰인 글을 그대로 두는 시간
const FADE_SECONDS := 1.0    ## 글이 사라지는 시간
const BEAT_SECONDS := 0.4    ## 글이 사라지고 다시 캄캄한 사이
const LAMP_SECONDS := 2.0    ## 등불에만 불이 붙는 시간
const LIGHT_SECONDS := 4.5   ## 그 불에서 빛이 번져 나가는 시간
const SLIDE_SECONDS := 3.0   ## 옆으로 밀리는 시간

## 연출이 다 끝나는 시각. 이때부터 걸을 수 있다.
const TOTAL_SECONDS := (DARK_SECONDS + WRITE_SECONDS + READ_SECONDS + FADE_SECONDS
	+ BEAT_SECONDS + LAMP_SECONDS + LIGHT_SECONDS + SLIDE_SECONDS)

## 걸을 수 있는 가로 범위(발밑의 화면 좌표)와 속도.
##
## 오른쪽 끝은 문턱이다. 관문 구멍의 가운데가 화면 795쯤이라 거기서 멈춘다.
## 속도는 키 72px을 사람 키로 치고 보통 걸음으로 잡은 값이다.
const WALK_FROM := 58.0
const WALK_TO := 796.0
const WALK_SPEED := 56.0

## 문턱을 넘어 서고로 들어간다 (2026-08-14).
##
## **관문은 서고의 입구다**(회원님). 여기를 지나면 아카식 서고 안이고, 서고 안쪽으로 더
## 들어가면 그것과 마주친다 - `Room` → `Encounter` → 전투로 이어진다.
##
## 넘어가는 조건을 **문턱에 닿는 것만으로 두지 않는다.** 걷다가 끝에 부딪히면 실수로도
## 넘어가 버려서, 관문을 구경할 새가 없다. **문턱에 서서 안쪽으로 한 번 더 걸어 들어가야**
## 넘어간다 - 들어가겠다는 뜻이 손에 남는다.
const ARCHIVE_SCENE := "res://scenes/Room.tscn"
## **너무 깊이 들어가야 했다**(2026-08-14, 회원님). 0.72는 갈 수 있는 데까지 거의 다 가야
## 하는 값이라, 문 앞에 서 있는데도 안 넘어가서 뭘 더 해야 하는지 알 수 없었다.
## 문지방을 넘는 정도면 충분하다.
const ENTER_NEAR := 22.0    ## 문턱에서 이만큼 안쪽이면 문 앞으로 친다
const ENTER_DEPTH := 0.28   ## 그 자리에서 안쪽으로 이만큼 더 들어가면 넘어간다
const ENTER_FADE := 1.6

## 안쪽으로 걸어 들어갈 수 있는 끝. 발밑이 여기까지 올라가고 그만큼 작아진다.
##
## **경외감은 그것이 커지는 데서 오는 게 아니라 내가 작아지는 데서 온다**(`WalkScene`에서
## 확인한 것). 관문은 그 자리에 그대로 크고, 안으로 갈수록 내가 준다.
const FOOT_FAR := 442.0
const FAR_SCALE := 0.55
## 안팎으로 걷는 속도(발밑 픽셀/초). 바닥이 눕혀져 보이므로 가로보다 느려야 같은 걸음으로 읽힌다.
const DEPTH_SPEED := 26.0

## 몇 픽셀 걸을 때마다 한 번 발을 딛는가. 1px 오르내리는 것만으로 미끄러지지 않고 걷는 것으로
## 보인다 - 걷기 그림이 따로 없어서 이걸로 대신한다.
##
## 처음에 14로 뒀더니 초당 여덟 걸음이라 걷는 게 아니라 떠는 것으로 보였다. **키를 사람 키로
## 치면 한 걸음이 30px쯤**이고, 그래야 초당 두 걸음이 나온다.
const STEP_LENGTH := 30.0

## 여는 글. 분위기를 잡는 문장이 아니라 **규칙을 미리 말해두는 것**이다 - 시야 밖은 실제로
## 없는 것처럼 굴고, 싸우려고 등불을 쓰면 그만큼 세계가 줄어든다. 다 하고 나서 되돌아보면
## 경고였음을 알게 되는 자리다.
## 둘째 줄은 반드시 한 줄로 둔다 - 이 문장이 이 게임의 규칙이라서, 쪼개면 힘이 빠진다.
## 32px에서 첫 줄이 880px이라 960 화면에 40px씩만 남는다. 꽉 찬다.
const EPIGRAPH := """세계를 건너다니는 자에게는 그곳이 온전히 보이지 않는다.
등불이 비추는 것만 실재한다."""

## 한 단어가 불붙듯 떠오르는 데 걸리는 시간. 단어 간격보다 길어서 서로 겹친다 - 그래야
## 하나씩 딱딱 켜지지 않고 이어서 번지는 것으로 보인다.
const WORD_FADE := 1.3

## 갓 떠오른 글자의 색과 다 떠오른 뒤의 색. 등불 색에서 시작해 뼈색으로 가라앉는다.
const EMBER := Color(1.0, 0.60, 0.25)
const BONE := Color(0.86, 0.84, 0.79)

## 빛이 다 번졌을 때의 값. `DitherScreen`의 uniform과 같은 이름이다.
##
## 등불이 화면 오른쪽 아래에 치우쳐 있어서 가운데에서 비출 때보다 멀리 가야 한다. 반경 1이
## 넘는 것이 그래서다 - `hint_range`는 편집기 눈금일 뿐 코드로 넣는 값은 안 잘린다.
## 반대편 위 귀퉁이만 살짝 어둡게 남아서 등불에서 나온 빛처럼 읽힌다.
const LIGHT_RADIUS := 1.05
const LIGHT_SOFTNESS := 0.7
const AMBIENT := 0.16

var _world: Node2D
var _picture: Sprite2D
var _beyond: Sprite2D
var _screen: ColorRect
var _lamp: LampGlow
var _epigraph: RichTextLabel
var _words: PackedStringArray   ## 단어들
var _gaps: PackedStringArray    ## 각 단어 뒤에 붙는 공백이나 줄바꿈

var _figure: Sprite2D

var _elapsed := 0.0
var _settled := false   ## 글이 다 떠올라 더 고쳐 쓸 필요가 없는 상태
var _walked := 0.0      ## 처음 선 자리에서 좌우로 걸어온 거리(픽셀)
var _depth := 0.0       ## 0이면 맨 앞, 1이면 갈 수 있는 가장 안쪽
var _entering := false  ## 문턱을 넘는 중. 두 번 들어가지 않게 잠근다
## 마지막 발소리 뒤로 걸어온 거리(픽셀). 시간이 아니라 **거리**로 세는 이유는, 안쪽으로
## 갈수록 화면에서 느리게 움직이므로 시간으로 세면 걸음이 총총거리기 때문이다.
var _since_step := 0.0
var _left_foot := false


func _ready() -> void:
	_build()
	_apply(0.0)
	Music.play_in(self, TRACK, Music.VOLUME_DB, TRACK_FROM)

	if "--capture" in OS.get_cmdline_user_args():
		_capture_and_quit()


func _process(delta: float) -> void:
	_elapsed += delta
	# 연출이 다 끝나야 손이 간다. 중간에 움직이면 빛이 같이 끌려다녀서 연출이 무너진다.
	if _elapsed >= TOTAL_SECONDS and not _entering:
		# **멀수록 화면에서 느리게 움직인다.** 같은 걸음이라도 멀리 있으면 조금밖에 안 가는
		# 것이 원근이다. 속도를 그대로 두면 안쪽에서 미끄러지듯 빨라 보인다.
		var near: float = _size()
		var going: float = Input.get_axis("ui_left", "ui_right")
		var before: float = _walked
		_walked = clampf(_walked + going * WALK_SPEED * near * delta,
			WALK_FROM - FIGURE_AT.x, WALK_TO - FIGURE_AT.x)
		var inward: float = Input.get_axis("ui_down", "ui_up")
		var deeper: float = inward * DEPTH_SPEED * near * delta / (FIGURE_AT.y - FOOT_FAR)
		_depth = clampf(_depth + deeper, 0.0, 1.0)

		# **발소리가 걸음을 만든다**(2026-08-14). 전에는 소리가 하나도 없어서, 정지 그림이
		# 조용히 미끄러질 뿐이라 걷는 것으로 안 보였다(회원님). 그림을 새로 그리지 않아도
		# 박자만 있으면 걸음이 된다 - 조우 화면이 걷는 것처럼 느껴지는 이유가 그것이다.
		#
		# 안쪽으로 들어가는 것도 걸음으로 친다. 위아래로만 움직이는데 조용하면 미끄러진다.
		_since_step += absf(_walked - before) + absf(deeper) * (FIGURE_AT.y - FOOT_FAR)
		var stride: float = STEP_LENGTH * near
		if _since_step >= stride:
			_since_step = fmod(_since_step, stride)
			_step()

		# 문 앞에 서서 안쪽으로 더 들어가면 넘어간다.
		var at_threshold: bool = _walked >= (WALK_TO - FIGURE_AT.x) - ENTER_NEAR
		if at_threshold and _depth >= ENTER_DEPTH:
			_enter()
	_apply(_elapsed)


## 한 발. **한쪽이 조금 여려야 걸음에 좌우가 생긴다** - 같은 크기로 되풀이하면 사람이 아니라
## 기계다. 그리고 안으로 들어갈수록 여려진다. 멀어지는 것이 소리에도 있어야 한다.
func _step() -> void:
	_left_foot = not _left_foot
	var away: float = lerpf(0.0, -9.0, _depth)
	Sfx.play(self, Sfx.STEP,
		(-14.0 if _left_foot else -17.0) + away,
		randf_range(0.95, 1.05) * (1.0 if _left_foot else 1.06))


## 문턱을 넘는다. **소리부터 나고 화면이 잦아든다** - 넘어가는 것이 화면 전환이 아니라
## 내가 한 일로 읽혀야 한다.
func _enter() -> void:
	_entering = true
	Sfx.play(self, Sfx.FLARE, -6.0, 0.7)
	await ScreenEffect.fade_out(ENTER_FADE)
	get_tree().change_scene_to_file(ARCHIVE_SCENE)


## 지금 깊이에서의 크기 배율. 1이면 맨 앞, 작을수록 안쪽이다.
func _size() -> float:
	return lerpf(1.0, FAR_SCALE, _depth)


## 시간 하나로 화면 전체를 정한다. 캡처할 때 아무 시점이나 찍을 수 있어서 편하다.
func _apply(time: float) -> void:
	# 캄캄한 채로 글이 **한 단어씩 불붙듯** 떠오른다. 다 쓰이고 잠깐 둔 뒤에야 불이 들어온다 -
	# 글을 먼저 읽히고 세계를 보여주는 순서다.
	#
	# 다 떠오른 뒤에는 다시 짓지 않는다. BBCode를 매 프레임 새로 파싱시킬 이유가 없다.
	var writing: float = DARK_SECONDS + WRITE_SECONDS
	if time <= writing:
		_epigraph.text = _epigraph_text(time)
		_settled = false
	elif not _settled:
		# 캡처처럼 시간을 건너뛰어 부를 수도 있다. 그때도 다 떠오른 상태가 되어야 한다.
		_epigraph.text = _epigraph_text(writing)
		_settled = true

	# 다 쓰인 글은 잠깐 머물렀다가 사라진다.
	var written: float = DARK_SECONDS + WRITE_SECONDS + READ_SECONDS
	_epigraph.modulate.a = 1.0 - clampf((time - written) / FADE_SECONDS, 0.0, 1.0)

	var struck: float = written + FADE_SECONDS + BEAT_SECONDS   # 등불에 불이 붙는 시각
	var flowing: float = struck + LAMP_SECONDS                  # 그 불에서 빛이 나가는 시각
	var flame: float = clampf((time - struck) / LAMP_SECONDS, 0.0, 1.0)
	var lighting: float = clampf((time - flowing) / LIGHT_SECONDS, 0.0, 1.0)
	var sliding: float = clampf((time - flowing - LIGHT_SECONDS) / SLIDE_SECONDS, 0.0, 1.0)

	# 밀림은 정수 픽셀로 끊는다.
	var eased: float = 1.0 - pow(1.0 - sliding, 3.0)
	_world.position.x = roundf(PAN_FROM * (1.0 - eased))

	# 걸어온 만큼 옮겨 세운다. 발을 딛을 때마다 1px 오르내려서 미끄러지지 않게 한다.
	# 걸음 길이도 크기를 따라 줄여야 안쪽에서 종종거리지 않는다.
	var near: float = _size()
	var stride: float = STEP_LENGTH * near
	var stepping: float = 1.0 if fposmod(_walked, stride) < stride * 0.5 else 0.0
	_figure.position = Vector2(FIGURE_AT.x + _walked,
		lerpf(FIGURE_AT.y, FOOT_FAR, _depth) - stepping).round()
	_figure.scale = Vector2(near, near)

	# 등불은 색을 지키려고 필터 판 **위**에 있어서 세계와 같이 밀리지 않는다. 그래서 밀린
	# 만큼을 직접 더해 순례자의 손에 붙여 둔다.
	_lamp.position = (_figure.position + (LANTERN_IN_FIGURE - FOOT_IN_FIGURE) * near
		+ Vector2(_world.position.x, 0.0))
	_lamp.scale = Vector2(near, near)
	# 먼저 등불에만 불이 붙는다. 이때는 아직 세계가 캄캄해서 불빛만 떠 있다.
	var catching: float = flame * flame * (3.0 - 2.0 * flame)
	_lamp.visible = catching > 0.01
	if _lamp.visible:
		_lamp.self_modulate = Color(1.0, 1.0, 1.0, catching)

	# 그 다음 그 불에서 빛이 번져 나간다. **시작도 끝도 느리게** 한다 - 앞이 빠른 곡선을
	# 쓰면 시간을 아무리 늘려도 처음에 확 튀어서 스르르 퍼지는 것으로 안 보인다.
	var spread: float = lighting * lighting * (3.0 - 2.0 * lighting)
	_screen.material.set_shader_parameter("light_position", _lamp.position / SCREEN)
	_screen.material.set_shader_parameter("light_radius", LIGHT_RADIUS * spread)
	# **번짐도 같이 줄여야 진짜 어둠이 된다.** 반경만 0으로 두면 번짐의 꼬리가 남아서 등불
	# 자리에 흐린 원반이 계속 보인다 - 글이 쓰이는 동안 캄캄해야 하는데 안 캄캄했다.
	_screen.material.set_shader_parameter("light_softness", maxf(LIGHT_SOFTNESS * spread, 0.001))
	_screen.material.set_shader_parameter("ambient", AMBIENT * spread)


func _build() -> void:
	_world = Node2D.new()
	add_child(_world)

	var picture_texture: Texture2D = load(PICTURE)
	var picture_size := Vector2(picture_texture.get_size())
	# 다 밀린 뒤의 자리. 그림의 오른쪽 끝을 화면 오른쪽 끝에 붙이고 세로는 가운데를 쓴다.
	# 왼쪽 귀퉁이를 기준으로 놓아야 `OPENING` 비율을 그대로 곱해 쓸 수 있다.
	var corner := Vector2(SCREEN.x - picture_size.x, (SCREEN.y - picture_size.y) * 0.5)

	_beyond = Sprite2D.new()
	_beyond.texture = load(BEYOND)
	# 문 너머는 크게 굼실거린다. 저기가 꿈이라는 것을 움직임으로 말하는 자리다.
	_beyond.material = _wave(5.0, 72.0, 0.8)
	# 문 구멍 가운데에 맞춘다. 관문보다 크면 밖으로 나가지만 문틀에 가려 안 보인다.
	_beyond.position = corner + picture_size * OPENING
	_world.add_child(_beyond)

	_picture = Sprite2D.new()
	_picture.texture = picture_texture
	_picture.centered = false
	_picture.position = corner
	# 늘려 붙인 왼쪽은 **관문에서 새어 나온다.** 문 옆은 거의 멎어 있고 멀어질수록 늘어지며
	# 무너진다. 이음새에서 진폭이 0이라 관문은 저절로 돌처럼 멎는다.
	var leak := ShaderMaterial.new()
	leak.shader = load(LEAK_SHADER)
	# 나오는 자리를 이음새보다 살짝 오른쪽에 둔다. 원본 그림 쪽으로도 조금 넘어가 늘어나서
	# 이음새에서 딱 시작하는 티가 안 난다.
	leak.set_shader_parameter("source_x", SEAM + 0.03)
	_picture.material = leak
	_world.add_child(_picture)

	_figure = Sprite2D.new()
	_figure.texture = load(FIGURE)
	_figure.centered = false
	# 그림을 밀어 놓아서 **노드의 원점이 발밑**이 되게 한다. 그래야 크기를 줄여도 발이 바닥에
	# 붙어 있고, 등불 자리도 같은 기준으로 계산된다.
	_figure.offset = -FOOT_IN_FIGURE
	_world.add_child(_figure)

	var filter_layer := CanvasLayer.new()
	filter_layer.layer = 50
	add_child(filter_layer)
	_screen = ColorRect.new()
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var effect := ShaderMaterial.new()
	effect.shader = load("res://shaders/DitherScreen.gdshader")
	_screen.material = effect
	filter_layer.add_child(_screen)

	var lamp_layer := CanvasLayer.new()
	lamp_layer.layer = 60
	add_child(lamp_layer)
	_lamp = LampGlow.new()
	# 손에 든 등불 크기에 맞춘다. 288은 허공에 뜬 해처럼 보였다.
	_lamp.glow_size = 128
	lamp_layer.add_child(_lamp)

	# 여는 글은 필터 판 **위**에 놓는다. 세계에 속한 것이 아니라 세계를 두고 하는 말이라서다.
	# 아래에 두면 흐리게 떠오르는 동안 글자가 베이어 격자에 잘게 부서진다.
	var text_layer := CanvasLayer.new()
	text_layer.layer = 70
	add_child(text_layer)
	# 가운데 정렬은 컨테이너에 맡긴다. 가로는 `[center]`가, 세로는 `CenterContainer`가 잡는다 -
	# 글 높이를 내가 재서 좌표를 계산하지 않아도 된다.
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_layer.add_child(middle)

	# 단어마다 진하기가 달라야 해서 `Label`이 아니라 `RichTextLabel`이다. Label은 글자 단위로
	# 색을 못 준다.
	_epigraph = RichTextLabel.new()
	_epigraph.bbcode_enabled = true
	_epigraph.fit_content = true
	_epigraph.autowrap_mode = TextServer.AUTOWRAP_OFF
	_epigraph.scroll_active = false
	_epigraph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 세로만 내용에 맞추고 가로는 화면 전체를 쓴다. 그래야 `[center]`의 기준이 화면이 된다.
	_epigraph.custom_minimum_size = Vector2(SCREEN.x, 0.0)
	# 픽셀 글꼴은 네이티브 크기의 정수배로만 쓴다. 1.5배 같은 걸 주면 도트 격자가 어긋난다.
	KoreanFont.apply(_epigraph, KoreanFont.NATIVE_SIZE * 2)
	_epigraph.add_theme_constant_override("line_separation", 14)
	middle.add_child(_epigraph)

	_split_words(EPIGRAPH)


## 글을 단어와 그 뒤의 여백으로 갈라둔다. 단어마다 색을 따로 입히려면 이렇게 나눠야 하고,
## 여백을 같이 들고 있어야 다시 이어 붙일 때 줄바꿈이 살아난다.
func _split_words(text: String) -> void:
	_words = PackedStringArray()
	_gaps = PackedStringArray()
	var word := ""
	var gap := ""
	for i in text.length():
		var letter: String = text[i]
		if letter == " " or letter == "\n":
			gap += letter
			continue
		if not gap.is_empty():
			_words.append(word)
			_gaps.append(gap)
			word = ""
			gap = ""
		word += letter
	if not word.is_empty():
		_words.append(word)
		_gaps.append("")


## 단어마다 진하기를 달리한 BBCode를 짓는다. `written`은 0이면 아직 안 나온 것, 1이면 다 나온 것.
func _epigraph_text(time: float) -> String:
	var step: float = (WRITE_SECONDS - WORD_FADE) / maxf(float(_words.size() - 1), 1.0)
	var out := "[center]"
	for i in _words.size():
		var rising: float = clampf((time - DARK_SECONDS - float(i) * step) / WORD_FADE, 0.0, 1.0)
		# 끝으로 갈수록 느려지게 해야 불이 붙듯 스르르 떠오른다.
		var lit: float = rising * rising * (3.0 - 2.0 * rising)
		var colour: Color = EMBER.lerp(BONE, lit)
		colour.a = lit
		out += "[color=#%s]%s[/color]%s" % [colour.to_html(true), _words[i], _gaps[i]]
	return out + "[/center]"


func _wave(amplitude: float, wavelength: float, speed: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load(WAVE_SHADER)
	material.set_shader_parameter("amplitude", amplitude)
	material.set_shader_parameter("wavelength", wavelength)
	material.set_shader_parameter("speed", speed)
	return material


## 확인용. `-- --capture`로 실행하면 연출의 네 시점을 한 장씩 찍고 끝낸다.
func _capture_and_quit() -> void:
	set_process(false)
	for at in [4.0, 7.8, 9.2, 11.0, 14.0, 19.5]:
		_apply(at)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tools/_opening_%02d.png" % int(at * 10))
	get_tree().quit()
