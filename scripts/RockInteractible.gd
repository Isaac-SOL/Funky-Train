class_name RockInteractible extends GenericInteractible

func _ready() -> void:
	super._ready()
	await get_tree().process_frame
	Main.instance.rhythm_sync.beat.connect(func(_b):
		scale = Vector3(1.2, 1.2, 1.2)
		var tween := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(self, "scale", Vector3.ONE, 0.5)
	)

func interact():
	visible = false
	%AudioBreak.play()
	Main.instance.camera.get_parent().shake(0.3, .7)
	Locomotive.instance.speed *= 0.3
	await %AudioBreak.finished
	destroy()
