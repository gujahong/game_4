extends SceneTree

## 방향별 프레임 PNG를 모아 `SpriteFrames` 하나로 엮는다. `HeroSprite`가 그것을 쓴다.
##
## 이런 모양으로 놓여 있기를 기대한다 — 받은 프레임을 이 구조로 정리해두면 된다.
##
## ```
## assets/characters/pilgrim/walk/south/0.png  1.png  ...  8.png
##                                north/...  east/...  west/...
## ```
##
## **0번은 기준 프레임(서 있는 자세)이고 1번부터가 걷기다.** PixelLab v3가 원본 회전 그림을
## 첫 장으로 끼워 주기 때문이다. 그래서 방향마다 애니메이션을 둘 만든다.
##
## ```
## idle_south   0번 한 장
## walk_south   1~8번
## ```
##
## 서 있는 자세를 걷기 고리에 넣어두면 한 바퀴마다 한 번씩 멈칫한다. 갈라두면 그게 없다.
##
## `--headless --script res://tools/_frames.gd`

## 읽을 곳. 지금은 **손이 빈 회전판**(`pilgrim_rot`)을 쓴다.
##
## [2026-08-13] 앞선 판들은 여기 없다. 등불을 그림에 그려 넣었던 것(`pilgrim/walk`, `walk4`)은
## 걷기 프레임마다 등불이 튀어서 접었다. 지금은 손을 비우고 등불을 `HeroSprite`가 따로 얹는다.
const FRAME_DIR := "res://assets/characters/pilgrim_rot/walk"
const OUTPUT := "res://assets/characters/pilgrim_rot/pilgrim_frames.tres"

const DIRECTIONS := ["south", "north", "east", "west"]

## 초당 프레임. 4장이면 한 바퀴가 두 걸음이므로, 8이면 초당 네 걸음이다.
## 걷는 속도(`Hero.SPEED` 90px/초)에 맞춰 조정한다 — 발이 미끄러져 보이면 여기를 올린다.
const FPS := 8.0

## 걷기 프레임을 몇 장에 하나씩 쓸지. 1이면 받은 것을 다 쓰고, 2면 한 장 걸러 쓴다.
##
## 8장짜리에서 4장을 얻으려고 만든 값이다(0 generation). 다만 **한 장 걸러 써도 자세 자체의
## 흔들림은 안 사라진다** — 같은 그림이니까. 결국 4장으로 새로 뽑았고 지금은 1이다.
const WALK_STEP := 1


func _init() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	for entry in DIRECTIONS:
		var direction: String = entry
		var paths := _frames_of(direction)
		if paths.is_empty():
			push_warning("%s 프레임이 없다 - 건너뛴다" % direction)
			continue

		var idle := "idle_" + direction
		frames.add_animation(idle)
		frames.set_animation_loop(idle, false)
		frames.add_frame(idle, load(paths[0]))

		var walk := "walk_" + direction
		frames.add_animation(walk)
		frames.set_animation_speed(walk, FPS / float(WALK_STEP))
		var used := 0
		for i in range(1, paths.size(), WALK_STEP):
			frames.add_frame(walk, load(paths[i]))
			used += 1

		print("%-6s 서 있기 1장, 걷기 %d장 (받은 %d장에서)"
			% [direction, used, paths.size() - 1])

	var error := ResourceSaver.save(frames, OUTPUT)
	if error != OK:
		push_error("저장 실패: %d" % error)
	else:
		print("저장: %s" % OUTPUT)
	quit()


## 번호 순서대로 정렬한 프레임 경로들. 10번이 2번보다 먼저 오지 않게 숫자로 센다.
func _frames_of(direction: String) -> PackedStringArray:
	var here := "%s/%s" % [FRAME_DIR, direction]
	var dir := DirAccess.open(here)
	if dir == null:
		return PackedStringArray()

	var numbers: Array[int] = []
	for name in dir.get_files():
		if name.ends_with(".png"):
			numbers.append(int(name.get_basename()))
	numbers.sort()

	var paths := PackedStringArray()
	for number in numbers:
		paths.append("%s/%d.png" % [here, number])
	return paths
