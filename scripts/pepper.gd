extends PathFollow3D

func _ready() -> void:
	await get_tree().process_frame
	Main.instance.rhythm_sync.beat.connect(func(_b):
		%ChiliPivot.scale = Vector3(1.2, 1.2, 1.2)
		var tween := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(%ChiliPivot, "scale", Vector3.ONE, 0.5)
	)
