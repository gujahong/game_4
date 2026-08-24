extends SceneTree

## 등불에서 뻗는 빛줄기를 **각도별 밝기로 잰다.** 눈으로 "두껍다"고 하는 것이
## 실제로 폭인지 밝기인지 가리려는 것이다.
##   --headless --script res://tools/_beams.gd
const SHOT := "res://tools/_battle_shot.png"
const ORIGIN := Vector2(44, 428)

func _init() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(SHOT))
	for radius in [110.0, 170.0]:
		print("\n반지름 %d 에서 각도별 밝기 (부챗살은 -78도 ~ 21도)" % int(radius))
		var line := ""
		var deg := -85.0
		while deg <= 28.0:
			var at: Vector2 = ORIGIN + Vector2(cos(deg_to_rad(deg)), sin(deg_to_rad(deg))) * radius
			if at.x < 0 or at.y < 0 or at.x >= img.get_width() or at.y >= img.get_height():
				deg += 1.0
				continue
			# 디더 격자를 지나가므로 한 점만 보면 안 된다. 둘레로 몇 점 평균 낸다.
			var sum := 0.0
			for k in 5:
				var spot: Vector2 = ORIGIN + Vector2(cos(deg_to_rad(deg)), sin(deg_to_rad(deg))) * (radius + float(k) * 3.0)
				if spot.x < 0 or spot.y < 0 or spot.x >= img.get_width() or spot.y >= img.get_height():
					continue
				var c := img.get_pixelv(Vector2i(spot))
				sum += (c.r + c.g + c.b) / 3.0
			var v: int = int(round(sum / 5.0 * 9.0))
			line += str(clampi(v, 0, 9))
			deg += 1.0
		print("  %s" % line)
		print("  ^-85도                                                     +28도^")
	quit()
