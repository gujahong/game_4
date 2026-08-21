extends TileMapLayer
class_name TilesetRoom

## PixelLab에서 받은 Wang 타일셋(16장 시트 + metadata.json)으로 방 하나를 깐다.
##
## 공식 안내(`pixellab://docs/godot/wang-tilesets`)는 변환 스크립트를 돌려 `.tres`를 만들라고 하고,
## 영상은 웹에서 "tileset 15"로 내보내 TileMapDual 플러그인에 넣으라고 한다. 둘 다 사람 손이
## 필요해서, 여기서는 **받은 시트를 그대로 읽어 코드로 TileSet을 세운다.** 플러그인도 변환도
## 필요 없다.
##
## 코너 규칙: 각 칸의 네 꼭짓점이 위 지형(1)이냐 아래 지형(0)이냐로 타일이 정해진다.
##   wang = NW*8 + NE*4 + SW*2 + SE
## metadata의 `bounding_box`가 시트에서 그 타일의 정확한 자리다(`original_position`은 생성 격자라
## 쓰면 안 된다 — 안내에 그렇게 적혀 있다).

## **나무 통로 ↔ 심연**(2026-08-14). 전에는 `marble_void`(흰파랑 대리석 + 남색 공허)였는데,
## 회원님이 주신 서고 참고 그림 — 따뜻한 호박색 나무와 책, 심연 위에 놓인 통로 — 과 안 맞아
## 새로 뽑았다. 옛 시트도 남아 있으니 이 두 줄만 되돌리면 그대로 쓴다.
##
##   tileset 15cddff9-7b91-4781-8815-02417fa8f242
##   심연     93a487f0-3861-4d3b-b844-9badcb48dd51
##   나무     a3daef06-de22-4892-ad36-e6be10b9cbb9   ← 다음 타일셋의 lower로 넘기면 이어진다
const SHEET_PATH := "res://assets/tilesets/wood_chasm_image.png"
const META_PATH := "res://assets/tilesets/wood_chasm_metadata.json"

## ### 서고는 나선이다 (2026-08-14)
##
## 전에는 사각형 방 하나였다. 회원님이 주신 참고 그림 셋 — **고리 세계 · 나선 코덱스 ·
## 떠 있는 서가 탑** — 을 하나로 묶으면 이런 곳이 된다.
##
## ```
## 바깥   최근에 다녀온 꿈. 내가 남긴 기록
##   ↓
## 안쪽   더 오래된 것. 누가 썼는지 모르는 것
##   ↓
## 중심   그것이 있다. 잡으면 포탈이 열리고, 그 너머가 마을이다
## ```
##
## **중심은 마을이 아니다**(2026-08-15 정정). 마주 서는 자리일 뿐이라 넓을 이유가 없다 -
## 오히려 좁아야 도망갈 데가 없어 보인다. 마을(포탈·기름·기록물)은 포탈 너머의 계단의 방이다.
##
## 고리 사이는 **한 군데씩만 뚫려 있고 그 자리가 고리마다 돌아간다.** 그래서 곧장 못 들어가고
## 돌아 걸어야 한다 - 등불이 좁아 한 번에 조금밖에 안 보이는 것과 맞물려 서고가 넓게 느껴진다.
##
## **다만 마지막 한 걸음만은 북쪽이다.** 마을로 들어가는 통로를 중심의 남쪽에 못 박아뒀다 -
## 조우 화면이 뒷모습으로 북쪽을 향해 걸어 들어가는 그림이라, 여기서 옆으로 들어가면
## 넘어가는 순간 방향이 어긋난다(회원님 지적).

## 방 크기(칸). 정사각형이어야 한다. 32px 타일이니 32칸이면 1024px다.
## **44칸에서 줄였다**(회원님, 2026-08-18: "서고 너무 큰 것 같던데"). 나선일 때는 바깥
## 고리 한 바퀴가 120칸이라 걷기만 하다 끝났는데, 지금은 입구에서 그것까지 22칸 직선이다.
const COLS := 32
const ROWS := 32

## ### 중앙 홀 + 네 날개 (2026-08-18)
##
## 나선을 버렸다. **성당 회랑처럼 가운데 홀에서 네 방향으로 복도가 뻗고, 복도 끝마다 방이
## 하나씩** 있는 십자 구조다(회원님이 고른 안).
##
## ```
##            그것          북쪽 끝방. 서가를 다 읽어야 열린다
##             │
##      서가 ─ 홀 ─ 서가    동·서 끝방이 열람실. 서가 둘씩
##             │
##            입구          남쪽 끝방
## ```
##
## 나선이 주던 "돌아 걸어야 한다"를 **길이 대신 갈래**로 바꾼 것이다 - 어디로 갈지는
## 고르지만 오래 걷지는 않는다. 그리고 축이 직각이라 **오브젝트를 정면으로 세우기 좋다**:
## 이 게임은 3/4 시점(타일셋이 `high top-down`)이라 가구가 전부 같은 방향을 봐야 하는데,
## 복도가 가로세로면 벽을 따라 죽 세우면 그대로 맞는다.

## 중앙 홀의 반너비(칸).
const HALL_HALF := 4.5
## 날개 복도의 반너비(칸). 등불 지름보다 좁아야 벽이 보인다.
const WING_HALF := 1.6
## 날개 복도가 끝나고 방이 시작되는 거리(칸).
const WING_TO := 8.0
## 날개 끝방의 한가운데까지의 거리와 그 방의 반너비(칸).
const ROOM_AT := 11.0
const ROOM_HALF := 3.0

## ### 상호작용하는 자리
##
## 서가다. 고리 위에 놓이고, **다가가서 읽으면 기록이 뜬다.** 첫 안이라 자리는 눈으로 보고
## 옮기면 된다 - `[고리 번호, 각도]`뿐이라 숫자 두 개다.
##
## **통로가 뚫린 자리에서 먼 데** 둔다. 지나는 길에 저절로 밟히면 찾은 것이 아니라 걸린 것이다.
## 그리고 안쪽 고리일수록 오래된 기록이라, 거기 있는 것이 그것의 이름에 가깝다.
## 들어오는 자리가 남쪽(각도 +PI/2 = 1.57)이므로 **거기서 멀찍이** 둔다. 처음에 둘이 입구
## 근처에 몰려 있어서 시작하자마자 밟혔다(2026-08-15).
## 자리는 **한가운데에서 몇 칸 떨어졌는가**(칸 좌표)다. 화면 좌표라 아래가 +y다.
const RECORDS := [
	Vector2(-12.0, -1.8),   # 서쪽 열람실 - 안쪽 벽
	Vector2(-10.0, 1.8),    # 서쪽 열람실 - 문 가까이
	Vector2(12.0, 1.8),     # 동쪽 열람실 - 안쪽 벽
	Vector2(10.0, -1.8),    # 동쪽 열람실 - 문 가까이
]
## 서가 앞에 서면 반응하는 거리(칸).
const RECORD_REACH := 1.8

## ### 종이로 된 것들이 누워 있는 자리
##
## **서고 바닥에는 원래 종이가 널려 있다**(`Pages`가 흩날리고 있다). 그래서 어느 더미가
## 살아 있는지 구별이 안 간다 - 지나가려다 일어서는 것이 이 적의 정체다.
##
## 서가로 가는 길목에 둔다. **일부러 밟게 하려는 게 아니라 지나칠 수밖에 없게** 하는 것이라,
## 서가와 통로 사이 어중간한 자리가 맞다.
## **복도 한가운데가 아니라 한쪽으로 치우쳐 둔다.** 복도 반너비가 1.6칸이고 밟는 거리가
## 1.1칸이라, 반대쪽으로 비키면 안 깨우고 지나갈 수 있다 - 보고 나서 피할 수 있어야 한다.
const SLEEPERS := [
	Vector2(0.9, 6.4),     # 남쪽 복도 - 들어와서 처음 만난다
	Vector2(-6.4, -0.9),   # 서쪽 복도 - 열람실 가는 길
	Vector2(6.4, 0.9),     # 동쪽 복도 - 열람실 가는 길
	Vector2(3.4, -3.4),    # 홀 북동 구석 - 그것에게 가는 문 앞
]
## 밟았다고 치는 거리(칸). 등불 반경보다 작아야 **보고 나서 피할 수 있다.**
const SLEEPER_REACH := 1.1

## ### 북쪽 날개는 잠겨 있다 (2026-08-15)
##
## **서가를 다 읽어야 그것에게 가는 길이 열린다.** 그래야 기록이 장식이 아니라 관문이 된다.
##
## 그리고 읽으려면 등불이 밝아야 하고, 등불은 기름을 태운다. **알아내는 데 값이 드는 구조**가
## 여기서 실제 규칙이 된다 - 예전에 적어둔 *"기름을 태워야 알 수 있다"* 그대로다.
##
## 잠겨 있는 동안 그 자리는 심연이라 지도에서도 끊겨 보인다. 열리면 이어진다.
var _opened := false


## 서가를 다 읽었다. 중심으로 가는 길이 열린다.
func open_way() -> void:
	if _opened:
		return
	_opened = true
	_paint_room()   # 통로가 하나 늘었으니 바닥을 다시 깐다


func is_open() -> bool:
	return _opened

var _wang_to_atlas: Dictionary = {}  ## wang 번호 -> 아틀라스 좌표
var _centre := Vector2(COLS * 0.5, ROWS * 0.5)   ## 나선의 한가운데(칸 좌표)


func _ready() -> void:
	var meta := _read_metadata()
	if meta.is_empty():
		return
	tile_set = _build_tileset(meta)
	_paint_room()


## 이 칸이 바닥인가.
func is_floor(cell: Vector2i) -> bool:
	return _walkable(Vector2(cell) + Vector2(0.5, 0.5))


## 타일 한 칸의 픽셀 크기. 벽을 그리는 쪽(`Clutter`)이 칸을 픽셀로 옮길 때 쓴다.
func tile_px() -> int:
	return _tile_px()


## **세상 좌표로 물어보는 것.** Hero가 이걸 쓴다 - 칸이 아니라 실제 발밑 자리로 묻는다.
##
## **그림과 판정을 같은 눈으로 잰다**(회원님, 2026-08-18: "갈 수 있을 것 같은데 못 가는
## 곳이 있다"). 타일은 모서리 격자를 반올림해 깔리는데 판정만 연속 값으로 재면, 나무가
## 그려진 가장자리 반 칸이 "보이는데 못 가는" 띠가 된다 - 걷기도 제일 가까운 모서리로
## 판정해야 그림의 계단과 막히는 자리가 일치한다.
func is_walkable_px(point: Vector2) -> bool:
	return _walkable((point / float(_tile_px())).round())


## 방 전체를 감싸는 사각형. 카메라 한계와 종이 뿌리는 범위로 쓴다.
func floor_rect_px() -> Rect2:
	var px: int = _tile_px()
	return Rect2(Vector2.ZERO, Vector2(COLS * px, ROWS * px))


## 그것이 지키는 자리(세상 좌표). **북쪽 끝방 한가운데다**(회원님, 2026-08-18:
## "위쪽은 서가 말고 그것으로") - 남쪽 입구에서 곧장 북쪽을 향해 걸어 들어가게 되므로,
## 조우 화면(뒷모습으로 북쪽을 향해 걷는 그림)과 방향이 이어진다.
func heart_px() -> Vector2:
	return (_centre + Vector2(0.0, -ROOM_AT)) * float(_tile_px())


## 칸 좌표(한가운데에서 몇 칸)를 세상 픽셀로. 장식(`Clutter`)이 방 모양을 몰라도
## 자리를 잡을 수 있게 내준다.
func spot_px(offset: Vector2) -> Vector2:
	return (_centre + offset) * float(_tile_px())


## 남쪽 끝방 한가운데(세상 좌표). 관문에서 들어온 사람이 여기 선다.
func entrance_px() -> Vector2:
	return (_centre + Vector2(0.0, ROOM_AT)) * float(_tile_px())


## 서가들의 자리(세상 좌표). 칸이 아니라 실제 좌표로 내준다 - 쓰는 쪽이 칸을 몰라도 되게.
func record_spots_px() -> Array[Vector2]:
	return _spots(RECORDS)


## 이 자리에서 읽을 수 있는 서가가 있는가. 있으면 몇 번째인지, 없으면 -1.
func record_at(point: Vector2) -> int:
	var reach: float = RECORD_REACH * float(_tile_px())
	var spots := record_spots_px()
	for i in spots.size():
		if point.distance_to(spots[i]) <= reach:
			return i
	return -1


## 누워 있는 것들의 자리(세상 좌표).
func sleeper_spots_px() -> Array[Vector2]:
	return _spots(SLEEPERS)


## 이 자리에서 깨어나는 것이 있는가. 있으면 몇 번째, 없으면 -1.
func sleeper_at(point: Vector2) -> int:
	var reach: float = SLEEPER_REACH * float(_tile_px())
	var spots := sleeper_spots_px()
	for i in spots.size():
		if point.distance_to(spots[i]) <= reach:
			return i
	return -1


## 칸 좌표 목록을 세상 좌표로 푼다. 서가와 적이 같은 방식이라 한 군데로 모은다.
func _spots(list: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var px := float(_tile_px())
	for spot in list:
		out.append((_centre + spot) * px)
	return out


func _tile_px() -> int:
	return tile_set.tile_size.x if tile_set else 32


## ### 나선의 정의
##
## 여기 한 곳만 고치면 방 모양이 통째로 바뀐다. 타일도 이동 판정도 전부 이 함수 하나를 본다.
func _walkable(at: Vector2) -> bool:
	var offset: Vector2 = at - _centre

	# 중앙 홀. 네모난 방 하나다.
	if absf(offset.x) <= HALL_HALF and absf(offset.y) <= HALL_HALF:
		return true

	# 네 날개. 축마다 **복도 + 그 끝의 방**이다. 축이 넷이라 같은 계산을 방향만 바꿔 돌린다 -
	# 축을 따라 나아간 만큼이 `along`, 축에서 옆으로 벗어난 만큼이 `across`다.
	for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var along: float = offset.dot(dir)
		if along <= 0.0:
			continue
		var across: float = absf(offset.x * dir.y - offset.y * dir.x)

		# **북쪽 날개가 그것에게 가는 길이다.** 서가를 다 읽기 전에는 복도도 방도 없다 -
		# 복도만 막고 방을 남겨두면 지도에서 섬처럼 떠 보인다.
		if dir == Vector2.UP and not _opened:
			continue

		if along <= WING_TO and across <= WING_HALF:
			return true
		if absf(along - ROOM_AT) <= ROOM_HALF and across <= ROOM_HALF:
			return true

	return false


func _read_metadata() -> Dictionary:
	if not FileAccess.file_exists(META_PATH):
		push_error("타일셋 metadata를 못 찾았다: %s" % META_PATH)
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(META_PATH)) != OK:
		push_error("타일셋 metadata를 못 읽었다")
		return {}
	return json.data


func _build_tileset(meta: Dictionary) -> TileSet:
	var tile_px: int = int(meta["tile_size"]["width"])
	var sheet: Texture2D = load(SHEET_PATH)

	var atlas := TileSetAtlasSource.new()
	atlas.texture = sheet
	atlas.texture_region_size = Vector2i(tile_px, tile_px)

	for tile in meta["tileset_data"]["tiles"]:
		var box: Dictionary = tile["bounding_box"]
		var coord := Vector2i(int(box["x"]) / tile_px, int(box["y"]) / tile_px)
		if not atlas.has_tile(coord):
			atlas.create_tile(coord)

		var corners: Dictionary = tile["corners"]
		var wang := 0
		wang += 8 if corners["NW"] == "upper" else 0
		wang += 4 if corners["NE"] == "upper" else 0
		wang += 2 if corners["SW"] == "upper" else 0
		wang += 1 if corners["SE"] == "upper" else 0
		_wang_to_atlas[wang] = coord

	var built := TileSet.new()
	built.tile_size = Vector2i(tile_px, tile_px)
	built.add_source(atlas, 0)
	return built


## 꼭짓점 격자를 만들고, 칸마다 네 꼭짓점을 읽어 맞는 타일을 놓는다.
func _paint_room() -> void:
	var vertex := []
	for r in ROWS + 1:
		var row := []
		for c in COLS + 1:
			# 꼭짓점이 통로 위에 있으면 위 지형(나무), 아니면 아래 지형(심연).
			row.append(1 if _walkable(Vector2(c, r)) else 0)
		vertex.append(row)

	for r in ROWS:
		for c in COLS:
			var wang: int = vertex[r][c] * 8 + vertex[r][c + 1] * 4 \
				+ vertex[r + 1][c] * 2 + vertex[r + 1][c + 1]
			if _wang_to_atlas.has(wang):
				set_cell(Vector2i(c, r), 0, _wang_to_atlas[wang])
