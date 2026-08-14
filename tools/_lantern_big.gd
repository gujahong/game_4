extends SceneTree

## 전투 화면에 쓸 **큰 등불**을 찍는다. 8x11짜리(`_lantern.gd`)를 늘려 놨더니 도트 하나가
## 여덟 칸이 될 뿐, 격자는 안 깨져도 **원래 없던 디테일이 생기지는 않았다.**
##
## 그래서 규칙대로 **놓일 크기로 새로 그린다**(CLAUDE.md 그림 규칙). 가로세로를 두 배로 잡으면
## 칸은 네 배라, 손에 든 것에서는 한 점으로 뭉개지던 것들이 하나씩 자리를 갖는다 -
## 고리의 굵기, 갓의 처마, 유리를 가르는 창살, 심지와 그 둘레의 열기, 받침의 굽.
##
## **왼쪽 절반만 찍고 오른쪽은 거울로 뒤집는다**(회원님). 좌우를 따로 찍으면 밝은 면을 한쪽에만
## 넣는 식으로 반드시 어딘가 어긋나고, 정면에서 보는 물건은 그 어긋남이 바로 보인다.
## 그래서 여기 좌표는 전부 **왼쪽 절반**(x는 0~7)이고, `_row`가 반대쪽을 알아서 찍는다.
##
## `--headless --script res://tools/_lantern_big.gd`

const OUTPUT := "res://assets/characters/pilgrim/lantern_big.png"

const W := 16
const H := 22

## 작은 등불에서 쓰던 네 색을 그대로 가져오고, **두 색만 더한다.** 칸이 네 배로 늘어난 만큼
## 놋쇠에 빛 받는 면과 그늘진 면이 갈려야 통이 둥글게 읽힌다. 색을 더 늘리면 이 게임의
## 규칙(화면에서 색을 가진 것은 등불뿐)이 흐려지므로 여기까지다.
const FRAME := Color("4a3c18")   ## 세로 뼈대와 창살. 어두운 쇠
const BRASS := Color("b99d53")   ## 갓과 받침. 놋쇠
const SHINE := Color("e4cd8b")   ## 놋쇠에서 빛을 받는 윗면
const GLASS := Color("7d6a2e")   ## 유리. 불빛이 비쳐도 심지보다는 어둡다
const HEAT := Color("c9ab5e")    ## 심지 둘레. 유리와 심지 사이를 메운다
const FLAME := Color("f3e0a0")   ## 심지
const DARK := Color("2a2119")    ## 그림자


func _init() -> void:
	var image := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)

	# 손잡이 고리. **위로 솟은 반원이 손에 드는 물건이라는 제일 강한 표시다.**
	_row(image, 6, 7, 0, FRAME)
	_row(image, 5, 5, 1, FRAME)
	_row(image, 4, 4, 2, FRAME)
	_row(image, 4, 4, 3, FRAME)
	_row(image, 7, 7, 3, FRAME)      # 고리를 통에 매다는 목

	# 갓. **윗면이 빛을 받고 처마는 그늘진다.** 밝은 면을 한쪽에만 넣으면 대칭이 깨지므로,
	# 왼쪽이 아니라 위가 밝은 것으로 방향을 잡는다 - 등불은 제 빛으로 제 갓을 못 비춘다.
	_row(image, 3, 7, 4, SHINE)
	_row(image, 2, 7, 5, BRASS)
	# **처마 밑 그늘을 통 전체에 긋지 않는다.** 가로로 죽 그으면 등불이 위아래로 잘린다.
	# 처마가 튀어나온 끝에만 둔다.
	_row(image, 2, 3, 6, DARK)

	# 통. 바깥 뼈대와 창살 하나씩, 그 사이가 유리다.
	for y in range(6, 17):
		_row(image, 4, 7, y, GLASS)
		_row(image, 3, 3, y, FRAME)   # 바깥 뼈대
		_row(image, 5, 5, y, FRAME)   # 창살. 심지를 비켜 세운다

	# 심지와 그 둘레의 열기. **통 전체가 아니라 가운데만 밝다** - 다 밝히면 풍등이 된다.
	# 창살(x=5)을 건드리지 않는 6~7칸 안에서만 논다.
	for y in range(8, 17):
		_row(image, 6, 7, y, HEAT)
	# 심지는 물방울이다. 네모로 채우면 창문에 불을 켜 둔 것처럼 보인다.
	_row(image, 7, 7, 10, FLAME)
	for y in range(11, 14):
		_row(image, 6, 7, y, FLAME)
	_row(image, 7, 7, 14, FLAME)

	# 받침. 굽을 한 칸씩 안으로 들여야 바닥에 닿는 면이 좁아 보이고, 매달린 티가 난다.
	_row(image, 2, 7, 17, SHINE)
	_row(image, 3, 7, 18, FRAME)
	_row(image, 4, 7, 19, BRASS)
	_row(image, 5, 7, 20, FRAME)
	_row(image, 6, 7, 21, DARK)

	image.save_png(OUTPUT)
	print("저장: %s (%dx%d)" % [OUTPUT, W, H])
	quit()


## **왼쪽 절반의 좌표만 받아** 그 칸들과 거울로 뒤집은 칸들을 함께 칠한다.
## from/to는 둘 다 포함이고, 0~7 사이여야 한다(가운데는 7과 8 사이다).
func _row(image: Image, from: int, to: int, y: int, colour: Color) -> void:
	for x in range(from, to + 1):
		image.set_pixel(x, y, colour)
		image.set_pixel(W - 1 - x, y, colour)
