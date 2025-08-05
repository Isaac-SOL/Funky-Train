class_name Station extends PathFollow3D

@export var waiting_character: CharacterInfo
@export var revealed: bool = false


func _ready() -> void:
	get_section().add_station(self)
	load_character()
	%SpriteMinimap.global_rotation = Vector3(-PI / 2.0, 0, PI)

func get_section() -> RailSection:
	return get_parent()

func get_camera_pos() -> Node3D:
	return %CameraPos

func reveal():
	revealed = true
	if waiting_character:
		%SpriteMinimap.texture = waiting_character.sprite_cadre

func remove_character():
	waiting_character = null
	load_character()
	%SpriteMinimap.visible = false

func set_character(new_character: CharacterInfo):
	waiting_character = new_character
	load_character()

func load_character():
	if waiting_character:
		%CharacterSprite.texture = waiting_character.sprite
		%CharacterSprite.visible = true
		if revealed:
			%SpriteMinimap.texture = waiting_character.sprite_cadre
		%SpriteMinimap.visible = true
		print(name + ": " + waiting_character.name)
	else:
		%CharacterSprite.visible = false
		%SpriteMinimap.visible = false
