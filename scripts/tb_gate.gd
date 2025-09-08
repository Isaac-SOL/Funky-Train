class_name TBGate extends GenericInteractible

func _ready() -> void:
	super._ready()
	await get_tree().process_frame
	Main.instance.rhythm_sync.beat.connect(func(_b):
		%MicPivot.scale = Vector3(1.15, 1.15, 1.15)
		var tween := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(%MicPivot, "scale", Vector3.ONE, 0.5)
	)

func interact():
	%AudioGate.play()
	var tween := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(%BarrierPivot, "rotation_degrees:z", 75.0, 0.35)
	tween.tween_interval(5.0)
	tween.tween_property(%BarrierPivot, "rotation_degrees:z", 0.0, 0.35)
