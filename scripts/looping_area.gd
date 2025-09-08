class_name LoopingArea extends Area3D

func _ready() -> void:
	await get_tree().process_frame
	area_entered.connect(Main.instance._on_area_loop_area_entered)
	area_exited.connect(Main.instance._on_area_loop_area_exited)
