class_name Interruptor extends PathFollow3D

signal pressed

@export var rail_to_toggle: RailSection

func _ready() -> void:
	get_section().add_interruptor(self)
	await get_tree().process_frame
	assert(rail_to_toggle.is_toggled)

func get_section() -> RailSection:
	return get_parent()

func press():
	rail_to_toggle.toggle()
	%AudioPressed.play()
	pressed.emit()
