extends Node
class_name BattleStage

## 전투를 **이미 서 있는 화면 위에 그대로 얹는다.**
##
## 예전에는 조우가 끝나면 씬을 갈아탔는데, 그러면 복도도 등불도 그것도 한 번 사라졌다가 다시
## 생긴다 - 아무리 이어 붙여도 "장면이 바뀌었다"가 보인다. 여기서는 **아무것도 안 사라진다.**
## 서 있던 그것이 왼쪽으로, 내가 오른쪽으로 스윽 옮겨 앉을 뿐이라 카메라만 돌린 것으로 읽힌다.
##
## 그래서 이 파일은 **어느 씬에 얹혀도 된다.** 그것과 나와 등불을 넘겨받아 옮기고, 규칙
## (`Battle`)과 글자(`BattleHud`)를 이어 줄 뿐 자기 화면을 따로 갖지 않는다.

signal over(outcome: String)

const SCREEN := Vector2(960, 540)

## 전투 곡. **카메라가 돌기 시작할 때 같이 든다** - 다 앉고 나서 틀면 음악이 뒤늦게 따라온
## 것이 되고, 이 순간은 화면이 도는 것과 소리가 바뀌는 것이 한 몸이어야 한다.
const TRACK := "res://assets/music/battle.mp3"
const TRACK_FROM := 2.0

## 그것은 **오른쪽 위로 물러나면서 화면 밖으로 넘치고**, 나는 왼쪽 아래 구석으로 물러난다
## (회원님 스케치). 다 보이면 그냥 큰 그림이고, 잘려야 다 안 보인다 - 조우에서 세운
## "그것은 안 움직이고 내가 작아진다"를 전투에서도 잇는다.
const ENEMY_AT := Vector2(698, 166)
## 화면 높이에 대한 비율. 1보다 크면 위아래로 넘쳐서 다 안 보인다.
##
## **조우가 끝났을 때의 크기(2.1)에서 크게 줄이면 안 된다.** 카메라가 도는 것인데 그것이
## 작아지면 물러선 것으로 읽힌다 - 1.34로 잡았더니 64%로 쪼그라들면서 뒷걸음질쳐 보였다.
const ENEMY_HEIGHT := 1.9
## **전투에서는 사람이 안 보인다.** 카메라가 도는 동안 몸만 스러지고 등불만 남아서 여기
## 앉는다 - 이 화면에서 나를 나타내는 것은 등불이다(체력이 곧 불빛 색이고, 고를 것들도
## 이 불에서 뻗어 나온다). 사람을 세워 두면 그 규칙이 흐려지고 구도만 복잡해진다.
const LAMP_AT := Vector2(44, 428)
## **사람은 자리에 가서 사라지는 게 아니라 화면 밖으로 흘러 나간다.** 카메라가 돌아서 그가
## 화면에서 밀려나는 것이라, 제자리에서 스러지면 사람이 지워진 것이 되고 카메라가 돈 것이
## 안 된다. 등불만 염력에 매달린 채 남는다.
const HERO_EXIT := Vector2(-180, 470)
## 전투에서 쓰는 **큰 등불 그림**(16x22). 손에 들려 있을 때는 8x11짜리로 충분하지만, 여기서는
## 이것이 나를 대신해 화면에 남으므로 제일 오래 보게 되는 물건이다 - 늘리기만 하면 도트
## 하나가 여덟 칸이 될 뿐 없던 디테일이 생기지 않는다(`tools/_lantern_big.gd`).
const LANTERN_ART := "res://assets/characters/pilgrim/lantern_big.png"
## 큰 그림을 이 배율로 놓는다. 화면에서 64x88이다.
const LANTERN_PIXELS := 4.0
## 빛무리도 등불만큼 커진다.
const GLOW_ZOOM := 2.4
## 등불이 제일 밝을 때 보이는 반경(화면 짧은 쪽에 대한 비율). 1.4면 구석까지 닿는다.
## **제일 밝은 칸도 다 열지 않는다**(회원님). 구석까지 훤하면 어둠 속을 걷는 이야기가
## 아니게 된다 - 예전의 "밝음" 칸이 이제 천장이다.
const DARK_WIDE := 0.75
## 제일 어두울 때(꺼짐 바로 위)의 반경. 0이면 아무것도 안 보인다.
const DARK_NEAR := 0.05
## 밝기의 바닥. 이보다 아래로는 안 내려간다 - 한 칸 내렸는데 절반 넘게 떨어지면
## 조리개가 확 닫힌 것처럼 보인다.
const DARK_FLOOR := 0.14
## 어둠의 가장자리가 스러지는 폭. **크게 잡아야 조리개가 아니라 어둠이 된다.**
const SHADE_SOFT := 5.0
## 어두울 때 화면 전체가 같이 내려가는 몫.
const SHADE_DIM := 0.55
## 제일 밝을 때도 이만큼은 눌러 둔다. 0이면 화면이 대낮처럼 평평해진다.
const SHADE_DIM_FLOOR := 0.12
## 불이 떨리는 폭. 0.12면 세기가 위아래로 12%쯤 흔들린다 - 더 키우면 불이 꺼질락 말락 해서
## 화면이 정신없고, 더 줄이면 안 흔들리는 것과 구별이 안 된다.
const FLICKER := 0.12

## 옮겨 앉는 데 걸리는 시간. **한 박자에 끝나야 카메라를 돌린 것이 된다** - 길게 끌면
## 둘이 걸어서 자리를 잡는 것으로 보인다.
## **부우웅.** 느리게 떠서 가운데가 빠르고 끝이 다시 느려야 카메라가 실린 무게로 도는 것이
## 된다 - 사인 곡선 1초로는 스윽 지나가서 도는 티가 안 났다.
const MOVE_FOR := 1.5
const MOVE_CURVE := Tween.TRANS_CUBIC

## 카메라가 멎고 빛이 배어 나오기까지 쉬는 시간과, 배어 나오는 데 걸리는 시간.
const REVEAL_WAIT := 0.5
const REVEAL_FOR := 0.9

## 한 줄이 화면에 머무는 시간과, 그것이 움직이기 전에 쉬는 시간.
##
## **이 둘이 곧 전투의 박자다.** 짧으면 예전처럼 한 번에 처리된 것으로 보이고, 길면 답답하다.
## **다 떠오른 뒤에** 그대로 두는 시간이다. 떠오르는 시간은 문장마다 달라서 따로 잰다.
const SAY_FOR := 0.5
const PAUSE_FOR := 0.3

## 글 앞에 이 표가 붙어 있으면 **그 줄이 뜰 때 고리가 한 칸 돈다.** 표는 화면에 안 나온다.
const TURNS := "[돈다]"
## 한 칸이 도는 각(라디안). 조우에서 44칸에 한 바퀴를 돌던 것과 비슷한 크기다.
const NOTCH := 0.16

## 앉은 뒤의 숨. 조우 화면에서 쓰던 것과 같은 박자라야 이어진 것으로 보인다.
const BREATH := 20.0
const BREATH_SPEED := 0.42
## 등불이 떠 있는 흔들림. `HeroSprite`가 쓰던 것과 같은 값이라, 몸에서 떨어져 나와도
## 같은 박자로 계속 뜬다.
const FLOAT_HEIGHT := 2.5
const FLOAT_SPEED := 1.6

var battle: Battle

var _hud: BattleHud
var _enemy: Node2D
var _enemy_seat := ENEMY_AT   ## 이 적이 앉는 자리. 리소스가 정해두면 그것을 쓴다
var _hero: Node2D
var _lamp: Node2D
var _world: CanvasItem
var _shade: CanvasItem   ## 화면을 덮은 어둠. 등불이 여기에 구멍을 낸다

## 옮겨 앉기 전의 자리. 칸칸이 끊어 옮기려면 출발점을 들고 있어야 한다.
var _enemy_from := Vector2.ZERO
var _enemy_zoom_from := Vector2.ONE
var _enemy_zoom_to := Vector2.ONE
var _hero_from := Vector2.ZERO
var _lamp_from := Vector2.ZERO
var _lamp_zoom_from := Vector2.ONE
var _lantern: Sprite2D          ## 몸에서 떼어 받아 온 등불 그림. 이제 이것이 나다
var _lantern_from := Vector2.ZERO
var _lantern_zoom_from := Vector2.ONE
var _lantern_zoom_to := Vector2.ONE
var _seated := false   ## 다 옮겨 앉았는가. 그 뒤로는 여기서 숨을 이어 쉰다
var _glow := 1.0       ## 기름이 정하는 빛 세기. 여기에 불꽃 흔들림을 곱한다
var _last_player_hp := 0   ## 마지막으로 화면에 보여준 체력. 줄었으면 맞은 것이다
var _last_enemy_hp := 0
var _beats: Array = []     ## 아직 안 보여준 일들. 한 줄씩 사이를 두고 푼다
var _outcome := ""         ## 전투가 끝났으면 그 결과. 다 풀고 나서 알린다
var _busy := false         ## 지난 턴을 푸는 중. 그동안은 아무것도 안 먹는다
var _standing := PackedInt32Array()   ## 지금 겨눌 수 있는 적들의 번호
var _aiming := -1   ## 대상을 물은 행동(0 공격, 2 대화)
var _aimed := 0     ## 고른 대상의 번호


## world는 전투 내내 등불 밝기를 따라 어두워질 배경이다(없어도 된다).
## shade는 화면을 덮은 어둠이다(`Vignette` 셰이더). 넘겨주면 등불 밝기가 곧 **보이는 반경**이
## 된다 - 안 넘겨도 돌아간다.
func begin(enemy_defs: Array, enemy: Node2D, hero: Node2D, lamp: Node2D,
		world: CanvasItem = null, shade: CanvasItem = null) -> void:
	_enemy = enemy
	_hero = hero
	_lamp = lamp
	_world = world
	_shade = shade

	# 앞의 2초는 안 쓴다(회원님). 한 바퀴 돌아도 이 자리로 돌아온다.
	Music.play_in(self, TRACK, Music.VOLUME_DB, TRACK_FROM)

	battle = Battle.new(enemy_defs)
	_last_player_hp = battle.player_hp
	_last_enemy_hp = _enemy_total()
	battle.message.connect(_on_message)
	battle.state_changed.connect(_refresh)
	battle.finished.connect(_on_finished)

	# **날아오는 동안에도 등불 밝기를 쓴다.** 이걸 여기서 한 번 걸어 두지 않으면 일러스트가
	# 제 밝기 그대로 들어오다가 다 앉는 순간 어두워져서, 들어오는 내내 혼자 환하다.
	_light_world()
	_slide(enemy)


## 그것과 내가 자리를 옮긴다. **둘이 같이 움직여야** 화면이 돌아간 것으로 보인다 - 하나만
## 움직이면 그놈이 걸어간 것이다.
##
## 자리를 하나씩 트윈하지 않고 **진행도 하나만 트윈해서 셋을 한꺼번에 앉힌다.** 그것과 나와
## 등불이 같은 값 하나를 따라가야 따로 노는 데가 없다 - 둘이 자리를 옮기는 게 아니라
## 카메라가 도는 것이므로.
func _slide(enemy: Node2D) -> void:
	_enemy_from = enemy.position
	_enemy_zoom_from = enemy.scale
	_enemy_zoom_to = enemy.scale
	if enemy is Sprite2D and (enemy as Sprite2D).texture != null:
		var tall: float = float((enemy as Sprite2D).texture.get_size().y)
		# **크기는 적이 정한다.** 그 것은 넘쳐야 하지만 길에서 만나는 것까지 그러면 다
		# 똑같이 커 보인다. 리소스에 안 적혀 있으면 예전 값을 쓴다.
		var height: float = ENEMY_HEIGHT
		if not battle.enemies.is_empty() and "battle_height" in battle.enemies[0]:
			height = battle.enemies[0].battle_height
		var want: float = SCREEN.y * height / tall
		_enemy_zoom_to = Vector2(want, want)

	# **앉는 자리도 적이 정한다.** 떠 있는 고리는 화면 위쪽에 걸쳐도 되지만 바닥에 선 것은
	# 발이 바닥에 닿아야 한다 - 같은 자리에 놓으면 떠 있는 것처럼 보여 수평이 안 맞는다.
	if not battle.enemies.is_empty() and "battle_at" in battle.enemies[0]:
		var seat: Vector2 = battle.enemies[0].battle_at
		if seat != Vector2.ZERO:
			_enemy_seat = seat

	_hero_from = _hero.position if _hero != null else Vector2.ZERO
	_lamp_from = _lamp.position if _lamp != null else Vector2.ZERO
	_lamp_zoom_from = _lamp.scale if _lamp != null else Vector2.ONE

	if _hero != null:
		if "aside" in _hero:
			_hero.aside = Vector2.ZERO   # 어깨 너머로 밀던 것은 뒷모습에서만 쓰던 것이다
		if _hero.has_method("show_state"):
			_hero.call("show_state", "east", true)
		_take_lantern()

	var move := create_tween()
	move.set_trans(MOVE_CURVE).set_ease(Tween.EASE_IN_OUT)
	move.tween_method(_seat_at, 0.0, 1.0, MOVE_FOR)
	await move.finished
	_seat_at(1.0)
	_take_seat()


## 옮겨 앉는 도중 한 지점. **자리는 정수 픽셀로 끊는다** - 반 칸에 그리면 도트가 혼자
## 매끈해진다. 움직임 자체는 끊지 않는다(칸칸이 끊어 봤더니 카메라가 아니라 화면이 튀었다).
func _seat_at(t: float) -> void:
	if _enemy != null:
		_enemy.position = _enemy_from.lerp(_enemy_seat, t).round()
		_enemy.scale = _enemy_zoom_from.lerp(_enemy_zoom_to, t)
	# 사람은 화면 왼쪽 밖으로 흘러 나간다. 지워지는 게 아니라 카메라가 두고 가는 것이다.
	if _hero != null:
		_hero.position = _hero_from.lerp(HERO_EXIT, t).round()
	# 등불은 남아서 제자리를 잡고 커진다.
	if _lantern != null:
		_lantern.position = _lantern_from.lerp(LAMP_AT, t).round()
		_lantern.scale = _lantern_zoom_from.lerp(_lantern_zoom_to, t)
	if _lamp != null:
		_lamp.position = _lamp_from.lerp(LAMP_AT, t).round()
		_lamp.scale = _lamp_zoom_from.lerp(_lamp_zoom_from * GLOW_ZOOM, t)


## 다 옮겨 앉은 뒤에야 글자를 띄운다. **움직이는 중에 UI가 떠 있으면** 카메라가 도는 동안
## 메뉴가 따라다니는 꼴이라 화면이 둘로 갈린다.
func _take_seat() -> void:
	if _hero != null:
		_hero.visible = false   # 이미 화면 밖이다. 그려 봐야 헛일이라 여기서 끈다
	# **다 커진 자리에서 그림만 바꿔 끼운다.** 크기가 똑같아서 바뀌는 순간이 안 보이고,
	# 도트만 네 배로 촘촘해진다 - 빛이 배어 나오면서 세밀해진 등불이 드러난다.
	if _lantern != null and ResourceLoader.exists(LANTERN_ART):
		_lantern.texture = load(LANTERN_ART)
		_lantern.scale = Vector2.ONE * LANTERN_PIXELS
	_seated = true

	_hud = BattleHud.new()
	add_child(_hud)
	# 빛줄기는 **흔들리지 않는 자리**에서 뻗는다. 떠 있는 등불을 그대로 따라가면 부챗살이
	# 통째로 위아래로 출렁여서 글자가 멀미난다.
	_hud.setup(LAMP_AT)
	_hud.acted.connect(_on_acted)
	_hud.targeted.connect(_on_targeted)
	_hud.talked.connect(_on_talked)
	_hud.lamp_shifted.connect(_on_lamp_shifted)

	_hud.say("%s이(가) 앞을 막아섰다." % battle.display_name(0))
	_refresh()

	# **카메라가 멎고 한 박자 쉰 뒤에 빛이 배어 나온다.** 전환이 끝나자마자 글자가 떠 있으면
	# 급작스럽다 - 잠깐 그것과 나만 마주 서 있다가, 등불에서 빛줄기가 스며 나오면서 고를
	# 것들이 딸려 나온다.
	var wake := create_tween()
	wake.tween_interval(REVEAL_WAIT)
	wake.tween_property(_hud, "reveal", 1.0, REVEAL_FOR).set_trans(Tween.TRANS_SINE)


## 앉고 나서도 **숨은 계속 쉰다.** 조우 화면이 매 프레임 흔들어 주던 것들인데, 전투가
## 시작되면 그쪽이 손을 떼서 그것도 등불도 딱 멎어 버린다 - 그 순간 화면이 사진이 되고,
## 그게 전환이 어색한 진짜 이유다. 여기서 이어받는다.
func _process(_delta: float) -> void:
	if not _seated:
		return
	var now: float = float(Time.get_ticks_msec()) * 0.001
	if _enemy != null:
		var lift := 0.0
		if battle.enemies.is_empty() or not ("breathes" in battle.enemies[0]) or battle.enemies[0].breathes:
			lift = sin(now * BREATH_SPEED) * BREATH
		_enemy.position = _enemy_seat + Vector2(0.0, lift)
	# 등불은 몸에서 떨어져 나온 뒤에도 제 박자로 떠 있고, 빛도 거기 붙어 다닌다.
	# **정수 픽셀로 끊어 흔든다** - 부드럽게 움직이면 도트가 반 칸씩 어긋나 혼자 매끈해진다.
	if _lantern != null:
		var lift: float = roundf(sin(now * FLOAT_SPEED) * FLOAT_HEIGHT) * _lantern.scale.y
		_lantern.position = LAMP_AT + Vector2(0.0, lift)
	if _lamp != null:
		_lamp.position = _lamp_seat()
		# **불은 멎어 있지 않다.** 세기가 고르면 등불이 아니라 켜 둔 전구가 된다. 주기가 서로
		# 안 맞는 흔들림 셋을 겹쳐 불규칙하게 떨리게 하고, 빛무리의 크기와 빛줄기의 진하기를
		# 같은 값으로 흔든다 - 따로 흔들면 둘이 다른 불이 된다.
		var flick: float = _flame(now)
		_lamp.self_modulate = Color(1.0, 1.0, 1.0, _glow * flick)
		_lamp.scale = _lamp_zoom_from * GLOW_ZOOM * (0.94 + flick * 0.06)
		if _hud != null:
			_hud.set_flicker(flick)


## 불꽃이 흔들리는 몫. 1을 가운데 두고 위아래로 떨린다.
##
## **주기가 서로 안 맞는 흔들림 셋을 겹친다.** 하나만 쓰면 고른 맥박이라 기계가 되고, 겹치면
## 마루가 만났다 어긋났다 하면서 불규칙해진다 - 살아 있는 불이 그렇다.
func _flame(now: float) -> float:
	var quick: float = sin(now * 7.3)
	var quicker: float = sin(now * 11.7 + 1.3)
	var slow: float = sin(now * 3.1 + 2.4)
	return 1.0 + (quick * 0.5 + quicker * 0.3 + slow * 0.2) * FLICKER


## **등불을 몸에서 떼어 받아 온다.** 사람은 화면 밖으로 흘러 나가는데 등불은 남아야 하므로,
## 그의 자식으로 두면 같이 딸려 나간다. 있던 자리 그대로 세상에 옮겨 심는다.
func _take_lantern() -> void:
	if not _hero.has_method("release_lantern"):
		return
	var zoom: float = _hero.scale.x
	var stood: Vector2 = _hero.position + (_hero.call("lantern_at") as Vector2) * zoom
	_lantern = _hero.call("release_lantern")
	if _lantern == null:
		return
	_hero.get_parent().add_child(_lantern)
	_lantern.position = stood
	_lantern.scale = Vector2(zoom, zoom)
	_lantern.z_index = 3
	_lantern_from = stood
	_lantern_zoom_from = _lantern.scale
	# **작은 그림을 큰 그림이 놓일 크기까지 키운다.** 큰 그림은 가로세로가 두 배라 배율은
	# 절반이면 같은 크기다 - 다 커진 자리에서 그림만 바꿔 끼우면 크기는 그대로인데 도트만
	# 촘촘해진다(`_take_seat`). 옮겨 앉는 도중에 바꾸면 그 순간 크기가 튄다.
	_lantern_zoom_to = Vector2.ONE * LANTERN_PIXELS * 2.0


## 등불 그림이 지금 떠 있는 자리. 빛(`LampGlow`)을 여기 붙인다.
func _lamp_seat() -> Vector2:
	return _lantern.position if _lantern != null else LAMP_AT


# --- 손이 누른 것 ---

## 한 턴은 **규칙 안에서 한 번에 끝난다.** 내 공격도 그것의 반격도 이 한 줄 안에서 다 벌어지고,
## 예전에는 그 결과가 같은 프레임에 화면까지 올라왔다 - 그래서 주고받는 싸움이 아니라
## 누를 때마다 숫자가 바뀌는 것으로 보였다.
##
## **규칙은 그대로 두고 화면이 늦게 보여준다.** 벌어진 일을 받아 뒀다가(`_beats`) 하나씩 사이를
## 두고 푼다. 푸는 동안에는 아무 버튼도 안 먹는다.
func _on_acted(index: int) -> void:
	if _busy:
		return
	# **겨눌 것이 있는 행동만 대상을 묻는다.** 공격과 대화는 누구에게 하는지가 다르지만,
	# 막고 달아나는 데에는 상대가 하나든 여럿이든 고를 것이 없다.
	if index == 0 or index == 2:
		_aiming = index
		_ask_target()
		return
	# 아직 익힌 것이 없다. **턴은 안 쓴다** - 없는 것을 골랐다고 한 턴을 잃으면 억울하다.
	if index == 1:
		_hud.say("아직 익힌 기술이 없다.")
		return

	_busy = true
	_beats.clear()
	_hud.set_enabled(false)

	match index:
		3: battle.guard()
		4: battle.flee()

	await _play_beats()
	_busy = false
	if _outcome.is_empty() and _hud != null:
		_hud.show_actions()
		_hud.set_enabled(true)


## 겨눌 것을 묻는다. **살아 있는 것만 뜬다** - 무너진 것을 다시 겨눌 수는 없다.
func _ask_target() -> void:
	_standing = battle.alive()
	if _standing.is_empty():
		return
	var names: Array = []
	for i in _standing:
		names.append(battle.display_name(i))
	_hud.show_targets(names)


## 겨눈 것을 때린다. 화면이 보여준 번호는 살아 있는 것들 안에서의 번호라, 규칙이 아는
## 번호로 옮겨서 넘긴다.
func _on_targeted(slot: int) -> void:
	if _busy:
		return
	# 목록 끝에 붙은 "그만두기". 아무 일도 안 일어나고 행동 넷으로 돌아간다.
	if slot < 0 or slot >= _standing.size():
		_hud.show_actions()
		return
	_aimed = _standing[slot]

	# 말을 걸기로 했으면 **그 대상이 들고 있는 말길**을 다시 묻는다. 적마다 다르다.
	if _aiming == 2:
		var ways: Array = []
		for option in battle.talk_options(_aimed):
			ways.append(option.label)
		if ways.is_empty():
			_hud.say("말이 통할 것 같지 않다.")
			_hud.show_actions()
			return
		_hud.show_talks(ways)
		return

	await _resolve(func() -> void: battle.attack(_aimed))


## 고른 말길로 말을 건다.
func _on_talked(choice: int) -> void:
	if _busy:
		return
	# 마지막 줄기는 "그만두기". 대상 고르기로 되돌아간다 - 한 걸음씩 물러선다.
	if choice < 0 or choice >= battle.talk_options(_aimed).size():
		_ask_target()
		return
	await _resolve(func() -> void: battle.talk(_aimed, choice))


## 한 턴을 규칙에 넘기고, 벌어진 일을 박자대로 푼 뒤 손을 돌려준다.
func _resolve(act: Callable) -> void:
	_busy = true
	_beats.clear()
	_hud.set_enabled(false)
	act.call()
	await _play_beats()
	_busy = false
	if _outcome.is_empty():
		_hud.show_actions()
		_hud.set_enabled(true)


## 받아 둔 일들을 하나씩 푼다. **그것이 움직이기 전에 한 박자 쉰다** - 내 행동과 그 반응이
## 붙어 있으면 주고받은 것이 아니라 한꺼번에 처리된 것으로 보인다.
func _play_beats() -> void:
	var seen_player: int = _last_player_hp
	var seen_enemy: int = _last_enemy_hp

	for i in _beats.size():
		var beat: Dictionary = _beats[i]
		if i > 0:
			await _wait(PAUSE_FOR)
		# **다 떠오를 때까지 기다린 다음에 읽을 시간을 준다.** 글이 한 단어씩 뜨는 데 걸리는
		# 시간을 안 세면, 긴 문장은 다 나오기도 전에 다음 줄이 덮어쓴다.
		# **글이 말한 것을 화면도 한다.** "고리가 한 칸 돌아간다"고 써 놓고 아무것도 안 돌면
		# 글과 그림이 따로 논다. 몸짓은 글 앞에 붙인 표로 적는다(`TURNS`) - 어느 적의 어느
		# 줄에든 붙일 수 있고, 규칙은 이런 게 있는 줄도 모른다.
		var line: String = beat["text"]
		if line.begins_with(TURNS):
			line = line.substr(TURNS.length())
			_notch()
		var showing: float = _hud.say(line)

		# **누가 맞았는지는 체력이 말해 준다.** 규칙에 "때렸다" 같은 신호를 새로 달지 않는다.
		if beat["enemy"] < seen_enemy:
			Sfx.play(self, Sfx.HIT, -9.0, randf_range(0.92, 1.1))
		if beat["player"] < seen_player:
			Sfx.play(self, Sfx.HURT, -7.0)
			_quake(7.0)   # 맞은 것은 화면이 대신 앓는다
		seen_player = beat["player"]
		seen_enemy = beat["enemy"]

		await _wait(showing + SAY_FOR)

	_last_player_hp = seen_player
	_last_enemy_hp = seen_enemy
	_refresh()
	if not _outcome.is_empty():
		Sfx.play(self, Sfx.OVER, -8.0)
		_hud.close()
		over.emit(_outcome)


## 적들의 체력을 다 더한 것. **누가 맞았는지가 아니라 맞았는지만** 보면 되는 자리에 쓴다 -
## 여럿이어도 소리는 한 번이면 된다.
func _enemy_total() -> int:
	var sum := 0
	for hp in battle.hps:
		sum += hp
	return sum


## 고리가 한 칸 돌아간다. **한 칸이라 짧고, 끝에서 뚝 멎어야** 저절로 도는 것이 아니라
## 뭔가가 돌린 것으로 보인다.
func _notch() -> void:
	if _enemy == null:
		return
	Sfx.play(self, Sfx.TICK, -14.0, 0.7)
	var turn := create_tween()
	turn.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	turn.tween_property(_enemy, "rotation", _enemy.rotation + NOTCH, 0.55)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


## 맞을 때 세상이 한 번 앓는다. **`CanvasLayer` 위의 것들은 안 흔들린다** - 등불과 글자까지
## 같이 떨면 화면 전체가 흔들리는 것이라 멀미가 나고, 맞은 것이 나라는 게 안 보인다.
func _quake(strength: float) -> void:
	var world: Node2D = _enemy.get_parent() as Node2D if _enemy != null else null
	if world == null:
		return
	var shake := create_tween()
	for i in 5:
		var away := Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		shake.tween_property(world, "position", away.round(), 0.04)
	shake.tween_property(world, "position", Vector2.ZERO, 0.07)


func _on_lamp_shifted(step: int) -> void:
	if step < 0:
		Sfx.play(self, Sfx.DAMP, -13.0)
		battle.dim()
	else:
		Sfx.play(self, Sfx.FLARE, -13.0)
		battle.brighten()


# --- 전투가 알려오는 것 ---

## 규칙이 알려오는 것을 **바로 안 띄우고 받아 둔다.** 한 턴에 여러 줄이 한꺼번에 쏟아지는데,
## 그대로 띄우면 마지막 줄만 남아서 그것이 뭘 했는지 읽을 새도 없이 지나간다.
func _on_message(text: String) -> void:
	_beats.append({
		"text": text,
		"player": battle.player_hp,
		"enemy": _enemy_total(),
	})


## 등불 밝기를 화면 전체로 흘려보낸다. **그래서 남은 기름을 나타내는 눈금이 따로 필요 없다** -
## 세상이 어두워지는 것이 곧 눈금이다. 빛의 색은 내 체력이라 다칠수록 붉어진다.
func _refresh() -> void:
	# **어둠은 글자보다 먼저다.** 이 함수는 다 앉은 뒤에야 도는데, 그전까지 일러스트가
	# 어둠을 안 뒤집어쓴 채로 들어오다가 앉는 순간 툭 어두워졌다. 밝기는 글자가 뜨기 전에도
	# 이미 걸려 있어야 한다.
	_light_world()
	if _hud == null:
		return

	var lantern := battle.lantern
	_glow = Lantern.LIGHT_INTENSITY[lantern.level]
	var health := float(battle.player_hp) / float(Battle.PLAYER_MAX_HP)
	var colour := UiStyle.lamp_colour(health)
	_hud.show_state(battle, _glow, colour)


	if _lamp != null and _lamp is Sprite2D:
		_lamp.visible = _glow > 0.0
		if "glow_size" in _lamp:
			_lamp.glow_size = Lantern.GLOW_SIZE[lantern.level]
		if "core_color" in _lamp:
			_lamp.core_color = Color(colour.r, colour.g, colour.b, 0.95)
		if "edge_color" in _lamp:
			_lamp.edge_color = UiStyle.lamp_edge_colour(health) * Color(1.0, 1.0, 1.0, 0.0)
		# 세기는 매 프레임 불꽃이 흔들어 준다(`_process`). 여기서는 자리만 잡아 둔다.
		_lamp.self_modulate = Color(1.0, 1.0, 1.0, _glow)


## 색을 빼는 셰이더가 걸려 있으면 그쪽에 넘기고, 없으면 판 전체를 눌러 어둡힌다.
func _dim(node: CanvasItem, dark: float, dull: float) -> void:
	if node == null:
		return
	if node.material is ShaderMaterial and node.material.get_shader_parameter("desaturate") != null:
		node.material.set_shader_parameter("desaturate", dull)
		node.material.set_shader_parameter("layer_modulate", Color(dark, dark, dark, 1.0))
		return
	node.modulate = Color(dark, dark, dark, node.modulate.a)


## 끝난 것도 **바로 안 알린다.** 이 시그널은 마지막 한 방과 같은 프레임에 오므로, 그대로
## 처리하면 맞는 장면을 보기도 전에 전투가 닫힌다. 받아 둔 일을 다 푼 뒤에 마무리한다.
func _on_finished(outcome: String) -> void:
	const CLOSING := {
		"victory": "정적이 돌아왔다.",
		"defeat": "등불이 바닥에 떨어졌다.",
		"talked": "길이 열렸다.",
		"fled": "숨이 가라앉을 때까지 달렸다.",
	}
	_outcome = outcome
	_beats.append({
		"text": CLOSING.get(outcome, ""),
		"player": battle.player_hp,
		"enemy": _enemy_total(),
	})


## 등불 밝기를 세상에 흘려보낸다. **글자가 뜨기 전에도 걸려 있어야 한다** - 안 그러면
## 일러스트가 밝은 채로 들어오다가 다 앉는 순간 툭 어두워진다.
func _light_world() -> void:
	var lantern := battle.lantern
	# **바닥을 남긴다.** 밝기 값을 그대로 쓰면 어스름(0.46)에서 불씨(0.20)로 한 칸 내릴 때
	# 절반 넘게 뚝 떨어져서 조리개가 확 닫힌 것처럼 보인다.
	var dark: float = maxf(Lantern.BRIGHTNESS[lantern.level], DARK_FLOOR)
	var dull: float = Lantern.DESATURATE[lantern.level]

	# **등불이 밝히는 데까지만 보인다.** 어둠이 깔려 있고 그 구멍을 등불이 낸다.
	if _shade != null:
		# 곧게 늘리면 위쪽 두 칸이 붙어 버린다(반경 1이면 이미 구석까지 닿는다).
		var reach: float = lerpf(DARK_NEAR, DARK_WIDE, pow(dark, 0.75))
		_shade.material.set_shader_parameter("radius", reach)
		# 가장자리를 넓게 푼다. 좁으면 검은 종이에 구멍을 뚫은 것처럼 보인다.
		_shade.material.set_shader_parameter("softness", SHADE_SOFT)
		# 어두워지면 화면 전체도 같이 내려간다.
		_shade.material.set_shader_parameter("dim",
			SHADE_DIM_FLOOR + (1.0 - dark) * SHADE_DIM)
		_shade.material.set_shader_parameter("light_position", _lamp_seat() / SCREEN)

	_dim(_world, dark, dull)
	# 그것은 조금 더 빨리 묻힌다. **너무 가파르면(1.6제곱) 한 칸에 세 배씩 어두워진다.**
	_dim(_enemy, pow(dark, 1.25), dull)
