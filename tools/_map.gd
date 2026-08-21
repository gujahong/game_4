extends SceneTree

## 서고의 **구조를 통째로** 그려서 보여준다. 게임 화면은 등불이 좁아 한 번에 조금밖에 안
## 보이므로, 통로가 제대로 놓였는지는 이렇게 위에서 내려다봐야 안다.
##
## `TilesetRoom._walkable()`을 **그대로 불러서** 그린다 - 판정을 여기 다시 적으면 두 곳이
## 반드시 어긋난다. 게임이 쓰는 것과 같은 함수라 이 그림이 곧 실제 방이다.
##
## `--headless --script res://tools/_map.gd`

const OUT := "res://tools/_map.png"
const ZOOM := 20     ## 한 칸을 몇 픽셀로 그릴지. 폰에서도 보이게 크게 잡는다

const VOID := Color(0.05, 0.05, 0.07, 1.0)   ## 못 걷는 곳 — 심연
const WALK := Color(0.55, 0.45, 0.32, 1.0)   ## 걸을 수 있는 곳 — 나무 통로
const HEART := Color(0.85, 0.30, 0.25, 1.0)  ## 그것과 마주 서는 자리
const RECORD := Color(0.40, 0.85, 0.55, 1.0) ## 상호작용 — 서가(기록물)
const SLEEPER := Color(0.95, 0.55, 0.20, 1.0)## 누워 있는 것 — 다가가면 일어선다
const START := Color(0.35, 0.70, 0.95, 1.0)  ## 들어오는 자리 — 관문


func _init() -> void:
	var room = load("res://scripts/map/TilesetRoom.gd").new()
	var cols: int = room.COLS
	var rows: int = room.ROWS

	var image := Image.create(cols * ZOOM, rows * ZOOM, false, Image.FORMAT_RGBA8)
	image.fill(VOID)

	var walkable := 0
	for r in rows:
		for c in cols:
			# 칸 한가운데로 물어본다. 게임에서 Hero가 서는 자리와 같은 기준이다.
			if not room._walkable(Vector2(c + 0.5, r + 0.5)):
				continue
			walkable += 1
			# 그것이 지키는 자리는 **북쪽 끝방**이다(2026-08-18 구조 변경).
			var centre: Vector2 = Vector2(c + 0.5, r + 0.5) - room._centre
			var tone: Color = HEART if _in_heart(room, centre) else WALK
			image.fill_rect(Rect2i(c * ZOOM, r * ZOOM, ZOOM, ZOOM), tone)

	# 서가. 상호작용하는 자리라 크게 찍는다 - 한 칸이면 지도에서 안 보인다.
	for spot in room.RECORDS:
		_dot(image, room._centre + spot, RECORD)

	# 누워 있는 것들.
	for spot in room.SLEEPERS:
		_dot(image, room._centre + spot, SLEEPER)

	# 들어오는 자리. 남쪽 끝방이다.
	_dot(image, room._centre + Vector2(0.0, room.ROOM_AT), START)

	# **글자로도 찍는다.** 원격으로 폰에서 볼 때는 그림 파일이 안 넘어가서, 글자 격자가
	# 유일하게 보이는 방법이다.
	print("--- 글자 지도 ---")
	print("  .  못 걷는 곳      #  걸을 수 있는 곳")
	print("  X  그것    B  서가    P  누워 있는 것    E  들어오는 자리")
	var marks := {}
	for spot in room.SLEEPERS:
		var at: Vector2 = room._centre + spot
		marks[Vector2i(int(at.x), int(at.y))] = "P"
	for i in room.RECORDS.size():
		var at: Vector2 = room._centre + room.RECORDS[i]
		marks[Vector2i(int(at.x), int(at.y))] = "B"
	var enter: Vector2 = room._centre + Vector2(0.0, room.ROOM_AT)
	marks[Vector2i(int(enter.x), int(enter.y))] = "E"

	for r in rows:
		var line := ""
		for c in cols:
			var cell := Vector2i(c, r)
			var here := Vector2(c + 0.5, r + 0.5)
			if marks.has(cell):
				line += marks[cell]
			elif not room._walkable(here):
				line += "."
			elif _in_heart(room, here - room._centre):
				line += "X"
			else:
				line += "#"
		print(line)
	print("--- 끝 ---")

	image.save_png(OUT)
	print("저장: %s  (%dx%d칸, 걸을 수 있는 칸 %d개 = %d%%)" % [
		OUT, cols, rows, walkable, int(round(100.0 * walkable / float(cols * rows)))
	])
	quit()


## 상호작용 자리 표시. 한 칸이면 지도에서 안 보여서 세 칸짜리 점으로 찍는다.
func _dot(image: Image, at: Vector2, tone: Color) -> void:
	var x: int = (int(at.x) - 1) * ZOOM
	var y: int = (int(at.y) - 1) * ZOOM
	image.fill_rect(Rect2i(x, y, ZOOM * 3, ZOOM * 3), tone)


## 이 자리(한가운데 기준 칸 좌표)가 그것이 지키는 북쪽 끝방 안인가.
func _in_heart(room, offset: Vector2) -> bool:
	return absf(offset.x) <= room.ROOM_HALF and absf(offset.y + room.ROOM_AT) <= room.ROOM_HALF
