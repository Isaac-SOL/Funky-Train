class_name Accelerator extends PathFollow3D

@export var instant_speed: float = 20.0


func _ready() -> void:
	get_section().add_interactible(self)
	await get_tree().process_frame

func get_section() -> RailSection:
	return get_parent()
