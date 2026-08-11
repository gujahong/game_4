extends Node2D
class_name PhotoStack

## 지나온 장소를 사진처럼 쌓아 보여준다. 새 장소에 닿으면 사진 한 장이 좌우 번갈아 얹히고,
## 먼저 온 것들은 아래에 깔린 채 옆으로 삐져나온다.
##
## 이 방식이 나온 자리가 재미있다. pixen이 가로로 긴 캔버스에서 그림을 좌우로 갈라 내놓는 것이
## 계속 결함이었는데, **사진이 정사각형이면 그게 결함이 아니라 형식이 된다.** 게다가 갈라진
## 이음매에서 자르면 기존 배경 한 장이 사진 두 장이 된다.
##
## 그리고 화면이 곧 여정의 기록이 된다 - 오래 갈수록 쌓인 게 많아지고, 그게 얼마나 멀리
## 왔는지다. 설명이 필요 없다.
##
## **회전은 쓰지 않는다.** 폴라로이드처럼 비스듬히 겹치면 보기 좋겠지만 픽셀아트를 각도로
## 돌리면 도트 격자가 깨진다. 평행 이동과 밝기 차로만 층을 나눈다.

## 위치 사진의 크기. 화면 높이(540)의 83%다.
##
## 지역 배경(680x384)보다 크지만 그래도 된다 - 배경은 뒤에 어둡게 깔린 맥락이고 사진이 그 위에
## 얹히는 것이라, 사진이 배경 밖으로 조금 나가도 "위에 놓인 것"으로 읽힌다.
##
## 512로 안 가는 이유: 512면 화면 위아래에 14px밖에 안 남아서 **"놓인 사진"이 아니라
## "잘린 배경"으로 보인다.** 448이면 46px씩 검은 띠가 남아 사진처럼 읽힌다.
const PHOTO_SIZE := 448.0
const CENTRE := Vector2(480, 270)
const SIDE_OFFSET := 100.0     ## 좌우로 어긋나는 기본 거리
const DEPTH_OFFSET := 28.0     ## 한 장 밀릴 때마다 더 바깥으로 - 이게 있어야 옆구리가 보인다
const REGION_DIM := 0.34       ## 지역 배경은 맥락이지 주인공이 아니다. 눌러서 뒤로 보낸다
const DEPTH_DIM := 0.5         ## 한 장 밀릴 때마다 어두워지는 비율. 등불은 맨 위만 비춘다
const MAX_VISIBLE := 5         ## 이보다 오래된 것은 어차피 안 보이므로 버린다
const EDGE_ALPHA := 0.55       ## 사진 테두리. 이게 없으면 그냥 겹친 그림으로 읽힌다

var _photos: Array[FilteredSprite] = []
var _sides: Array[float] = []
var _placed: int = 0
var _region: FilteredSprite


## 지금 있는 꿈(지역)의 배경. 위치 사진들이 이 위에 쌓인다.
## 맥락이지 주인공이 아니라서 어둡게 눌러 뒤로 보낸다.
func set_region(texture: Texture2D) -> void:
	if _region == null:
		_region = FilteredSprite.new()
		_region.z_index = -MAX_VISIBLE - 1
		_region.position = CENTRE
		_region.layer_modulate = Color(REGION_DIM, REGION_DIM, REGION_DIM, 1.0)
		add_child(_region)
	_region.texture = texture


## 새 장소에 닿았다. 사진 한 장이 얹힌다.
func push_photo(texture: Texture2D) -> void:
	var photo := FilteredSprite.new()
	photo.texture = texture
	add_child(photo)

	_photos.append(photo)
	_sides.append(1.0 if _placed % 2 == 0 else -1.0)
	_placed += 1

	while _photos.size() > MAX_VISIBLE:
		_photos.pop_front().queue_free()
		_sides.pop_front()
	_arrange()


func _arrange() -> void:
	var newest := _photos.size() - 1
	for i in _photos.size():
		var depth := newest - i
		var photo := _photos[i]
		photo.position = CENTRE + Vector2(_sides[i] * (SIDE_OFFSET + depth * DEPTH_OFFSET), 0.0)
		# 사진을 전부 이 노드보다 뒤로 보낸다. 그래야 아래 _draw()의 테두리가 사진 위에 그려진다.
		photo.z_index = i - MAX_VISIBLE
		var dim: float = pow(DEPTH_DIM, depth)
		photo.layer_modulate = Color(dim, dim, dim, 1.0)
	queue_redraw()


## 사진마다 테두리 한 줄. 회전을 못 쓰는 대신 이 선이 "여기까지가 한 장"을 알려준다.
func _draw() -> void:
	var newest := _photos.size() - 1
	for i in _photos.size():
		var depth := newest - i
		var rect := Rect2(_photos[i].position - Vector2(PHOTO_SIZE, PHOTO_SIZE) * 0.5,
			Vector2(PHOTO_SIZE, PHOTO_SIZE))
		var ink := UiStyle.TEXT
		draw_rect(rect, Color(ink.r, ink.g, ink.b, EDGE_ALPHA * pow(DEPTH_DIM, depth)), false, 1.0)
