class_name ParkerGate extends GenericInteractible

const base_scale := Vector3.ONE * 1.33

func _ready() -> void:
	super._ready()
	await get_tree().process_frame
	Main.instance.rhythm_sync.beat.connect(func(_b):
		%Root.scale = base_scale * 1.15
		var tween := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(%Root, "scale", base_scale, 0.5)
	)

func interact():
	%AudioGate.play()
	var tween := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.set_parallel()
	tween.tween_property(%Pivot1, "rotation:y", PI / 2, 0.5)
	tween.tween_property(%Pivot2, "rotation:y", -PI / 2, 0.5)
	tween.chain().tween_interval(5.0)
	tween.chain().tween_property(%Pivot1, "rotation:y", 0.0, 0.5)
	tween.tween_property(%Pivot2, "rotation:y", 0.0, 0.5)
