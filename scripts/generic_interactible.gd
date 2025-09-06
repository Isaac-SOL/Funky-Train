class_name GenericInteractible extends PathFollow3D

func _ready() -> void:
	get_section().add_interactible(self)

func get_section() -> RailSection:
	return get_parent()

func interact():
	pass

func destroy():
	get_section().remove_interactible(self)
	queue_free()
