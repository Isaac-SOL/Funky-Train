class_name Station extends PathFollow3D

@export var waiting_character: CharacterInfo

func _ready() -> void:
	if waiting_character:
		print(name + " " + waiting_character.resource_path)
		print("PROTO : " + name + " " + waiting_character.name)
	get_section().add_station(self)
	load_character()

func get_section() -> RailSection:
	return get_parent()

func get_camera_pos() -> Node3D:
	return %CameraPos

func remove_character():
	waiting_character = null
	load_character()

func set_character(new_character: CharacterInfo):
	waiting_character = new_character
	load_character()

func load_character():
	if waiting_character:
		%CharacterSprite.texture = waiting_character.sprite
		%CharacterSprite.visible = true
		print(name + ": " + waiting_character.name)
	else:
		%CharacterSprite.visible = false
	print(%CharacterSprite.visible)
