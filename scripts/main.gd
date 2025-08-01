class_name Main extends Node3D

static var instance: Main

@export var character_leave_button_scene: PackedScene
@export var character_icon_scene: PackedScene

var active_station: Station

func _ready() -> void:
	instance = self

func stop_at_station(station: Station):
	active_station = station
	var character_info := station.waiting_character
	if character_info:
		%LabelTitre.text = character_info.name
		%TextureRect.texture = character_info.sprite
		%PanelStation.visible = true
		%VBoxContainerNewChar.visible = true
	else:
		for carriage in Locomotive.instance.carriages:
			var new_button: Button = character_leave_button_scene.instantiate()
			new_button.text = carriage.character.name
			new_button.icon = carriage.character.sprite
			new_button.pressed.connect(_on_character_leave_pressed.bind(carriage))
			%VBoxContainerLeaveButtons.add_child(new_button)
		%PanelStation.visible = true
		%VBoxContainerPutChar.visible = true

func update_characters_ui():
	for child in %HBoxContainerCharacters.get_children():
		if child != %TextureLocomotive:
			child.queue_free()
	for carriage: Carriage in Locomotive.instance.carriages:
		var new_texture: TextureRect = character_icon_scene.instantiate()
		new_texture.texture = carriage.character.sprite
		%HBoxContainerCharacters.add_child(new_texture)
		%HBoxContainerCharacters.move_child(new_texture, 0)
	await get_tree().process_frame
	%MarginContainerCharacters.size = Vector2.ZERO

func _on_button_prendre_pressed() -> void:
	close_add_character()
	Locomotive.instance.add_character(active_station.waiting_character)
	active_station.remove_character()
	Locomotive.instance.restart()
	active_station = null

func _on_button_laisser_pressed() -> void:
	close_add_character()
	Locomotive.instance.restart()
	active_station = null

func close_add_character():
	%PanelStation.visible = false
	%VBoxContainerNewChar.visible = false

func close_character_leave():
	%PanelStation.visible = false
	%VBoxContainerPutChar.visible = false
	for child in %VBoxContainerLeaveButtons.get_children():
		%VBoxContainerLeaveButtons.remove_child(child)

func _on_button_no_one_pressed() -> void:
	close_character_leave()
	Locomotive.instance.restart()
	active_station = null
	

func _on_character_leave_pressed(carriage: Carriage):
	close_character_leave()
	Locomotive.instance.remove_carriage(carriage)
	active_station.set_character(carriage.character)
	Locomotive.instance.restart()
	active_station = null
