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
## 중심   그것이 지킨다. 그 너머가 마을 — 포탈 · 기름 · 기록물
## ```
##
## **안으로 갈수록 오래되고 위험해진다.** 그리고 마을이 그것 뒤에 있으므로, 처음 온 사람은
## 반드시 한 번 마주쳐야 여기가 자기 거점이 된다.
##
## 고리 사이는 **한 군데씩만 뚫려 있고 그 자리가 고리마다 돌아간다.** 그래서 곧장 못 들어가고
## 돌아 걸어야 한다 - 등불이 좁아 한 번에 조금밖에 안 보이는 것과 맞물려 서고가 넓게 느껴진다.

## 방 크기(칸). 나선이라 정사각형이어야 한다. 32px 타일이니 44칸이면 1408px다.
const COLS := 44
const ROWS := 44

## 고리들의 반지름(칸). 바깥에서 안으로.
const RINGS := [19.0, 13.5, 8.5]
## 통로의 반너비(칸). 1.6이면 세 칸 남짓 - 등불 지름보다 좁아야 벽이 보인다.
const WALK_HALF := 1.6

## 한가운데 마을의 반지름(칸). 포탈·기름·기록물 세 자리가 들어가야 해서 넓다.
const HEART := 6.5

## 고리와 고리를 잇는 통로. 각도(라디안)와 반각.
## **고리마다 자리가 돌아간다.** 같은 자리에 뚫으면 곧장 가로질러 들어가 버린다.
const SPOKE_TURN := 2.3
const SPOKE_HALF := 0.13

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


func _tile_px() -> int:
	return tile_set.tile_size.x if tile_set else 32


## ### 나선의 정의
##
## 여기 한 곳만 고치면 방 모양이 통째로 바뀐다. 타일도 이동 판정도 전부 이 함수 하나를 본다.
func _walkable(at: Vector2) -> bool:
	var offset: Vector2 = at - _centre
	var d: float = offset.length()

	# 한가운데 마을.
	if d <= HEART:
		return true

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
			var spoke: float = float(i) * SPOKE_TURN
			# 각도는 한 바퀴 돌면 되돌아오므로 차이를 -PI~PI로 접어서 잰다.
			if absf(wrapf(angle - spoke, -PI, PI)) <= SPOKE_HALF:
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
