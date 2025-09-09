extends PathFollow3D

func _ready() -> void:
	await get_tree().process_frame
	Main.instance.rhythm_sync.beat.connect(func(_b):
		%ChiliPivot.scale = Vector3(1.2, 1.2, 1.2)
		var tween := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(%ChiliPivot, "scale", Vector3.ONE, 0.5)
	)


func _on_collision_area_entered(_area: Area3D) -> void:
	%AudioBonk.play()
	var bonk_tween := create_tween()
	bonk_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	bonk_tween.tween_property(%ChiliPivot, "rotation_degrees:z", 90.0, 0.05)
	bonk_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	bonk_tween.tween_property(%ChiliPivot, "rotation_degrees:z", 0.0, 1.0)
