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

## 방 크기(칸). 화면 960x540에 32px 타일이면 30x16이 딱 들어간다.
const COLS := 30
const ROWS := 16
## 바깥으로 남기는 공허의 두께(칸).
const MARGIN := 2

var _wang_to_atlas: Dictionary = {}  ## wang 번호 -> 아틀라스 좌표
var _floor: Rect2i                   ## 걸어다닐 수 있는 칸 범위


func _ready() -> void:
	var meta := _read_metadata()
	if meta.is_empty():
		return
	tile_set = _build_tileset(meta)
	_floor = Rect2i(MARGIN, MARGIN, COLS - MARGIN * 2, ROWS - MARGIN * 2)
	_paint_room()


## 이 칸이 바닥인가(걸을 수 있는가).
func is_floor(cell: Vector2i) -> bool:
	return _floor.has_point(cell)


func floor_rect_px() -> Rect2:
	var size: Vector2i = tile_set.tile_size if tile_set else Vector2i(32, 32)
	return Rect2(Vector2(_floor.position * size), Vector2(_floor.size * size))


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
			# 꼭짓점이 바닥 영역 안에 있으면 위 지형(대리석), 아니면 아래 지형(공허).
			var inside := c >= _floor.position.x and c <= _floor.end.x \
				and r >= _floor.position.y and r <= _floor.end.y
			row.append(1 if inside else 0)
		vertex.append(row)

	for r in ROWS:
		for c in COLS:
			var wang: int = vertex[r][c] * 8 + vertex[r][c + 1] * 4 \
				+ vertex[r + 1][c] * 2 + vertex[r + 1][c + 1]
			if _wang_to_atlas.has(wang):
				set_cell(Vector2i(c, r), 0, _wang_to_atlas[wang])
