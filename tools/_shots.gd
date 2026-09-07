extends Node

## **기획서에 넣을 화면 사진을 찍는다.**
##
## 게임을 진짜로 띄워서 찍는다 - 그래야 문서와 화면이 어긋날 수가 없다. 손으로 찍으면
## 매번 다른 순간이 잡히고, 코드를 고치고 나면 문서만 옛날 화면으로 남는다.
##
## ```
## Godot --path . --audio-driver Dummy res://tools/_shots.tscn -- --walk
## ```
##
## `--walk`를 주는 이유는 **아무것도 안 덤비게** 하려는 것이다(`Walker._peaceful`) -
## 사진 찍는 도중에 전투로 끌려가면 못 찍는다.
##
## 결과는 `res://tools/_doc_*.png`로 떨어진다. 문서 폴더로 옮기는 것은 밖에서 한다 -
## 여기서 `기획서/`에 바로 쓰면 Godot가 그 폴더까지 import하려 든다.
##
## **관문·전투는 각 씬에 이미 붙어 있는 `--capture`/`--shot`이 찍는다.** 여기서 찍는 것은
## 그 장치가 없는 것들뿐이다 - 서고를 걷는 장면과 서가를 읽는 장면.

const OUT := "res://tools/_doc_%s.png"
const ROOM := "res://scenes/Room.tscn"

## 서가 앞에 세울 자리. 서가 **아래쪽**에 선다(판정 거리는 1.8칸 = 57px, 몸이 막히는
## 거리는 26px이라 그 사이여야 알림이 뜨면서 안 겹친다).
const STAND_BELOW := 40.0

## 무언가를 기다릴 때의 한계(초). 조건이 영영 안 오면 사진 없이 끝나는 것이 낫지,
## 창을 띄운 채로 멈춰 있으면 무엇이 잘못됐는지도 모른다.
const GIVE_UP := 12.0


func _ready() -> void:
	await get_tree().process_frame
	await _archive()
	print("사진 다 찍었다")
	get_tree().quit()


func _archive() -> void:
	var room: Node = load(ROOM).instantiate()
	get_tree().root.add_child(room)
	# 들어올 때 어두운 데서 밝아지는 연출(`Walker.ENTER_FADE`)이 끝나기를 기다린다.
	await get_tree().create_timer(2.4).timeout
	await _shoot("archive_hall")

	var records: Records = room._records
	var hero: Hero = room._hero
	var ui: DialogueUI = get_tree().get_first_node_in_group("dialogue_ui")
	if records == null or hero == null or ui == null:
		push_error("서고를 못 찾았다 - 씬 구조가 바뀌었나")
		return

	# **서가 앞에 세운다.** 걸어서 가면 매번 다른 자리에 서고, 걷는 길에 무엇이 있느냐에
	# 따라 못 닿기도 한다. 자리를 직접 주면 늘 같은 사진이 나온다.
	hero.at = records._shelves[0].at + Vector2(0.0, STAND_BELOW)
	hero.facing = "north"
	# 알림이 뜨는 데 걸리는 시간(`Records.HINT_FADE`)보다 넉넉히.
	await get_tree().create_timer(0.7).timeout
	await _shoot("archive_shelf")

	# **서가를 읽는다.** 해독 두 단계를 한 장씩 잡는다.
	Dialogue.play_scene(RecordText.scene_for(0, false))
	# 1단계 - 옛 문자가 써지는 중. 첫 줄의 절반쯤.
	await _until(func() -> bool: return ui._full_line.length() > 0)
	await _until(func() -> bool:
		return ui._text_label.text.count("[img") >= ui._full_line.length() / 3)
	await _shoot("record_glyphs")

	# 2단계 - 빛이 글줄을 훑고 지나가는 중. 절반쯤 풀렸을 때.
	await _until(func() -> bool: return ui._solving)
	await _until(func() -> bool:
		return ui._solved >= float(ui._full_line.length()) * 0.5)
	await _shoot("record_solving")

	# 다 풀린 뒤. 읽을 수 있는 글이 대사창에 남은 모습.
	await _until(func() -> bool: return not ui._solving)
	await _shoot("record_done")


## 조건이 참이 될 때까지 기다린다. 시간을 재서 기다리면 속도 상수를 고칠 때마다
## 사진이 엉뚱한 순간으로 밀린다 - **화면이 실제로 그 상태가 되었는지**를 본다.
func _until(cond: Callable) -> void:
	var waited := 0.0
	while not cond.call() and waited < GIVE_UP:
		await get_tree().process_frame
		waited += get_process_delta_time()
	if waited >= GIVE_UP:
		push_warning("기다리다 포기했다 - 사진이 엉뚱한 순간일 수 있다")


## 화면 필터가 화면 텍스처를 다시 읽으므로 프레임을 넉넉히 기다린 뒤에 찍는다
## (안 그러면 드라이버가 죽는다 - CRT 오버레이에서 겪었다).
func _shoot(shot_name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT % shot_name)
	print("찍음: ", shot_name)
