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

## 방 크기(칸). 나선이라 정사각형이어야 한다. 32px 타일이니 44칸이면 1408px다.
const COLS := 44
const ROWS := 44

## 고리들의 반지름(칸). 바깥에서 안으로.
## 안쪽 고리를 8.5에서 밀었다 - 중심과 틈이 0.4칸뿐이라 사실상 붙어 있어서, 돌아가지 않고
## 아무 데서나 들어가졌다(2026-08-15).
const RINGS := [19.0, 14.0, 9.0]
## 통로의 반너비(칸). 1.6이면 세 칸 남짓 - 등불 지름보다 좁아야 벽이 보인다.
const WALK_HALF := 1.6

## 그것과 마주 서는 자리의 반지름(칸). **좁다** - 마을이 아니라 마주 서는 데다.
const HEART := 4.5

## 고리와 고리를 잇는 통로. 각도(라디안)와 반각.
## **고리마다 자리가 돌아간다.** 같은 자리에 뚫으면 곧장 가로질러 들어가 버린다.
const SPOKE_TURN := 2.3
const SPOKE_HALF := 0.13

## **마지막 통로만 남쪽에 못 박는다.** 여기로 들어가면 반드시 북쪽을 향해 걷게 되고,
## 그래야 조우 화면(뒷모습으로 북쪽을 향해 걸어 들어감)과 방향이 이어진다.
## 화면 좌표라 아래가 +y이므로 남쪽이 +PI/2다.
const LAST_SPOKE := PI * 0.5
## 마지막 통로는 조금 넓게. 여기만은 헤매게 하지 않는다 - 찾는 재미는 앞의 고리들이 이미 준다.
const LAST_SPOKE_HALF := 0.30

## ### 상호작용하는 자리
##
## 서가다. 고리 위에 놓이고, **다가가서 읽으면 기록이 뜬다.** 첫 안이라 자리는 눈으로 보고
## 옮기면 된다 - `[고리 번호, 각도]`뿐이라 숫자 두 개다.
##
## **통로가 뚫린 자리에서 먼 데** 둔다. 지나는 길에 저절로 밟히면 찾은 것이 아니라 걸린 것이다.
## 그리고 안쪽 고리일수록 오래된 기록이라, 거기 있는 것이 그것의 이름에 가깝다.
## 들어오는 자리가 남쪽(각도 +PI/2 = 1.57)이므로 **거기서 멀찍이** 둔다. 처음에 둘이 입구
## 근처에 몰려 있어서 시작하자마자 밟혔다(2026-08-15).
const RECORDS := [
	[0, -1.2],   # 바깥 고리 - 북서쪽. 들어오자마자 반 바퀴 돌아야 한다
	[0, 0.2],    # 바깥 고리 - 동쪽
	[1, 3.4],    # 가운데 고리 - 서쪽
	[2, -0.4],   # 안쪽 고리 - 북동쪽. 제일 오래된 기록
]
## 서가 앞에 서면 반응하는 거리(칸).
const RECORD_REACH := 1.8

## ### 중심으로 가는 길은 잠겨 있다 (2026-08-15)
##
## **서가를 다 읽어야 마지막 통로가 열린다.** 그래야 기록이 장식이 아니라 관문이 된다.
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


## **세상 좌표로 물어보는 것.** Hero가 이걸 쓴다 - 칸이 아니라 실제 발밑 자리로 묻는다.
func is_walkable_px(point: Vector2) -> bool:
	return _walkable(point / float(_tile_px()))


## 방 전체를 감싸는 사각형. 카메라 한계와 종이 뿌리는 범위로 쓴다.
func floor_rect_px() -> Rect2:
	var px: int = _tile_px()
	return Rect2(Vector2.ZERO, Vector2(COLS * px, ROWS * px))


## 마을 한가운데(세상 좌표). 그것이 지키는 자리이자 포탈·기름·기록물이 놓일 곳이다.
func heart_px() -> Vector2:
	return _centre * float(_tile_px())


## 바깥 고리 위의 한 자리(세상 좌표). 관문에서 들어온 사람이 여기 선다.
func entrance_px() -> Vector2:
	var out: float = RINGS[0]
	return (_centre + Vector2(0.0, out)) * float(_tile_px())


## 서가들의 자리(세상 좌표). 칸이 아니라 실제 좌표로 내준다 - 쓰는 쪽이 칸을 몰라도 되게.
func record_spots_px() -> Array[Vector2]:
	var out: Array[Vector2] = []
	var px := float(_tile_px())
	for spot in RECORDS:
		var r: float = RINGS[spot[0]]
		var a: float = spot[1]
		out.append((_centre + Vector2(cos(a), sin(a)) * r) * px)
	return out


## 이 자리에서 읽을 수 있는 서가가 있는가. 있으면 몇 번째인지, 없으면 -1.
func record_at(point: Vector2) -> int:
	var reach: float = RECORD_REACH * float(_tile_px())
	var spots := record_spots_px()
	for i in spots.size():
		if point.distance_to(spots[i]) <= reach:
			return i
	return -1


func _tile_px() -> int:
	return tile_set.tile_size.x if tile_set else 32


## ### 나선의 정의
##
## 여기 한 곳만 고치면 방 모양이 통째로 바뀐다. 타일도 이동 판정도 전부 이 함수 하나를 본다.
func _walkable(at: Vector2) -> bool:
	var offset: Vector2 = at - _centre
	var d: float = offset.length()

	# 그것과 마주 서는 자리. **길이 열리기 전에는 여기도 못 간다** - 통로만 막고 안쪽을
	# 남겨두면 지도에서 섬처럼 떠 보인다.
	if d <= HEART:
		return _opened

	# 고리 위.
	for r in RINGS:
		if absf(d - r) <= WALK_HALF:
			return true

	# 고리와 고리 사이를 잇는 통로. **고리마다 한 군데뿐이고 자리가 돌아간다.**
	var angle: float = offset.angle()
	var inner: float = HEART
	for i in RINGS.size():
		var outer: float = RINGS[RINGS.size() - 1 - i]
		if d > inner - WALK_HALF and d < outer + WALK_HALF:
			# i가 0인 것이 **중심으로 들어가는 마지막 통로**다. 이것만 남쪽에 고정하고,
			# 서가를 다 읽기 전에는 아예 없다.
			if i == 0 and not _opened:
				inner = outer
				continue
			var spoke: float = LAST_SPOKE if i == 0 else float(i) * SPOKE_TURN
			var half: float = LAST_SPOKE_HALF if i == 0 else SPOKE_HALF
			# 각도는 한 바퀴 돌면 되돌아오므로 차이를 -PI~PI로 접어서 잰다.
			if absf(wrapf(angle - spoke, -PI, PI)) <= half:
				return true
		inner = outer

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
