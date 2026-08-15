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

const VOID := Color(0.05, 0.05, 0.07, 1.0)
const WALK := Color(0.62, 0.50, 0.35, 1.0)   ## 나무 통로
const HEART := Color(0.95, 0.78, 0.45, 1.0)  ## 한가운데 마을
const START := Color(0.35, 0.75, 0.95, 1.0)  ## 들어오는 자리


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
			var centre: Vector2 = Vector2(c + 0.5, r + 0.5) - room._centre
			var tone: Color = HEART if centre.length() <= room.HEART else WALK
			image.fill_rect(Rect2i(c * ZOOM, r * ZOOM, ZOOM, ZOOM), tone)

	# 들어오는 자리에 표시 하나. 여기서 안쪽으로 감겨 들어가야 한다.
	var enter: Vector2 = room._centre + Vector2(0.0, room.RINGS[0])
	image.fill_rect(Rect2i(int(enter.x) * ZOOM, int(enter.y) * ZOOM, ZOOM, ZOOM), START)

	# **글자로도 찍는다.** 원격으로 폰에서 볼 때는 그림 파일이 안 넘어가서, 글자 격자가
	# 유일하게 보이는 방법이다.
	print("--- 글자 지도 ---")
	for r in rows:
		var line := ""
		for c in cols:
			var here := Vector2(c + 0.5, r + 0.5)
			if not room._walkable(here):
				line += "."
			elif (here - room._centre).length() <= room.HEART:
				line += "@"
			else:
				line += "#"
		print(line)
	print("--- 끝 ---")

	image.save_png(OUT)
	print("저장: %s  (%dx%d칸, 걸을 수 있는 칸 %d개 = %d%%)" % [
		OUT, cols, rows, walkable, int(round(100.0 * walkable / float(cols * rows)))
	])
	quit()
