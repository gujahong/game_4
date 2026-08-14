extends SceneTree

## 일회용. **암전 중에 뜨는 그 약한 빛이 등불 그림과 같은 자리인지 재 본다.**
##
## 눈으로 확인하려면 8초를 걷고 붙잡히는 7초를 기다려야 해서, 걸음을 건너뛰고 도착 상태로
## 밀어 넣은 다음 두 자리를 찍어 본다.
##
## `--headless --script res://tools/_probe_lamp.gd`


func _init() -> void:
	var scene: Node = load("res://scenes/Encounter.tscn").instantiate()
	root.add_child(scene)
	await process_frame

	# 다 걸어간 것으로 친다. 다음 프레임에 도착 처리가 돈다.
	scene._depth = 1.0
	await process_frame
	await process_frame

	var drawn: Vector2 = scene._figure.lantern_global()
	var lit: Vector2 = scene._lamp.position
	print("등불 그림이 있는 자리 : ", drawn)
	print("빛이 나는 자리       : ", lit)
	print("어긋난 만큼          : ", lit - drawn)
	print("사람 자리            : ", scene._figure.position, "  판 흔들림: ", scene.position)
	quit()
