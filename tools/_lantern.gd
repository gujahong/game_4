extends SceneTree

## 손에 쥐여 줄 등불을 찍는다. 캐릭터는 빈손으로 뽑고 이것만 따로 얹는다.
##
## **캐릭터 그림에 등불을 그려 넣었더니 걷기 프레임마다 위치와 모양이 튀었다**(2026-08-13).
## 게다가 물건을 든 캐릭터에는 템플릿 애니메이션을 못 써서 걷는 폼도 나빴다. 갈라 놓으면
## 둘 다 풀린다 - 캐릭터는 맨손이라 템플릿이 잘 듣고, 등불은 우리가 좌표를 쥔다.
##
## 몇 픽셀짜리라 뽑을 것도 없다. **0 generation**이고 색과 크기를 여기서 바로 고친다.
##
## 크기는 사람 키에 맞춘다. 32px짜리 주인공에게 10px은 몸의 3분의 1이라 가방처럼 보였고,
## 6x8로 줄였더니 이번엔 너무 작아 안 보였다. **8x11**이 그 사이다.
##
## `--headless --script res://tools/_lantern.gd`

const OUTPUT := "res://assets/characters/pilgrim/lantern.png"

const W := 8
const H := 11

## 놋쇠 통과 그 안의 불. 캐릭터 팔레트에 있던 금색을 그대로 가져왔다.
##
## **네 색이 다 필요하다.** 처음엔 통 전체를 한 가지 금색으로 채우고 가운데만 밝게 했더니
## 풍등처럼 보였다 - 종이 원통과 다를 게 없었다. 위아래에 밝은 놋쇠 테를 두르고 세로로
## 어두운 뼈대를 세워야 **쇠붙이 안에 불이 든 것**으로 읽힌다.
const FRAME := Color("4a3c18")   ## 세로 뼈대. 어두운 쇠
const BRASS := Color("b99d53")   ## 갓과 받침. 빛 받는 놋쇠
const GLASS := Color("7d6a2e")   ## 유리. 불빛이 비쳐도 심지보다는 어둡다
const FLAME := Color("f3e0a0")   ## 심지
const DARK := Color("2a2119")    ## 그림자


func _init() -> void:
	var image := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)

	# 손잡이 고리. 위로 솟은 반원이 **손에 드는 물건**이라는 제일 강한 표시다.
	_bar(image, 3, 5, 0, FRAME)
	image.set_pixel(2, 1, FRAME)
	image.set_pixel(5, 1, FRAME)

	_bar(image, 1, 7, 2, BRASS)       # 갓
	for y in range(3, 8):             # 유리
		_bar(image, 2, 6, y, GLASS)
		image.set_pixel(1, y, FRAME)  # 세로 뼈대
		image.set_pixel(6, y, FRAME)
	_bar(image, 3, 5, 4, FLAME)       # 심지. 통 전체가 아니라 가운데만 밝다
	_bar(image, 3, 5, 5, FLAME)
	_bar(image, 1, 7, 8, BRASS)       # 받침
	_bar(image, 2, 6, 9, FRAME)
	_bar(image, 3, 5, 10, DARK)

	image.save_png(OUTPUT)
	print("저장: %s (%dx%d)" % [OUTPUT, W, H])
	quit()


## x가 from부터 to 직전까지 한 줄을 칠한다.
func _bar(image: Image, from: int, to: int, y: int, colour: Color) -> void:
	for x in range(from, to):
		image.set_pixel(x, y, colour)
