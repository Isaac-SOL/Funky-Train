class_name VibingNode extends Node3D

@export_range(0.0, 1.0, 0.05) var vibe_ratio: float = 0.1

func _ready() -> void:
	await get_tree().process_frame
	Main.instance.rhythm_sync.beat.connect(func(_b):
		scale = Vector3(1.0, 0.9, 1.0)
		var tween := get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(self, "scale", Vector3.ONE, 0.5)
	)
