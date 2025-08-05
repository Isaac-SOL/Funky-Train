class_name TrafficSignal extends Node3D

func _ready() -> void:
	await get_tree().process_frame
	Main.instance.rhythm_sync.beats(2).connect(func(_b): %AnimationPlayer.play("woobwoob"))
