extends SceneTree

## 일회용. 그림에 쓰인 색을 많이 쓰인 순서로 뽑아 본다. 어떤 색을 고쳐야 하는지 짐작하지
## 않으려고 만든 것이다.
## `--headless --script res://tools/_palette.gd`

const SOURCES := [
	"res://assets/characters/pilgrim/raw/south.png",
	"res://assets/characters/pilgrim/raw/east.png",
	"res://assets/characters/pilgrim/raw/west.png",
	"res://assets/characters/pilgrim/raw/north.png",
]
## 이 세로 범위만 본다. 손과 등불이 있는 아래쪽만 들여다보려는 것.
const FROM_Y := 24
const TO_Y := 48


func _init() -> void:
	for source in SOURCES:
		_dump(source)
	quit()


func _dump(SOURCE: String) -> void:
	var image := Image.load_from_file(SOURCE)
	image.convert(Image.FORMAT_RGBA8)
	var counts: Dictionary = {}
	var spots: Dictionary = {}
	for y in range(FROM_Y, mini(TO_Y, image.get_height())):
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var key := c.to_html(false)
			counts[key] = counts.get(key, 0) + 1
			if not spots.has(key):
				spots[key] = []
			if spots[key].size() < 4:
				spots[key].append("%d,%d" % [x, y])

	var keys: Array = counts.keys()
	keys.sort_custom(func(a, b): return counts[a] > counts[b])
	print("%s  (%dx%d, 색 %d개)"
		% [SOURCE, image.get_width(), image.get_height(), keys.size()])
	for key in keys:
		var c := Color(key)
		print("#%s  %4d칸  H%.0f S%.2f V%.2f   %s"
			% [key, counts[key], c.h * 360.0, c.s, c.v, ", ".join(spots[key])])
	print("")
