class_name Station extends PathFollow3D

@export var waiting_character: CharacterInfo

func _ready() -> void:
	get_section().add_station(self)

func get_section() -> RailSection:
	return get_parent()

func remove_character():
	waiting_character = null

func set_character(new_character: CharacterInfo):
	waiting_character = new_character
