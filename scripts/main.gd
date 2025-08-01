class_name Main extends Node3D

static var instance: Main

@export var character_list: Array[CharacterInfo]
@export var character_leave_button_scene: PackedScene
@export var character_icon_scene: PackedScene
@export var character_signalisation_scene: PackedScene
@export var camera_sensitivity: Vector2 = Vector2.ONE
@export var zoom_sensitivity: float = 1.0

var active_station: Station
var signals_up: bool = false
@onready var camera_follow_pos: Node3D = %CameraFollowPos
@onready var camera_pivot_x: Node3D = %CameraPivotX
@onready var camera_pivot_y: Node3D = %CameraPivotY
@onready var camera_loop_pos: Node3D = %CameraLoopPos
var dragging_camera: bool = false

func _ready() -> void:
	instance = self
	#Preload Diologic timeline by starting a blanc timeline
	Dialogic.start("timeline_blanc")
	await get_tree().process_frame

func stop_at_station(station: Station):
	active_station = station
	%CameraShaker.target_node = active_station.get_camera_pos()
	var character_info := station.waiting_character
	if character_info:
		%LabelTitre.text = character_info.name
		%MarginContainerStationGrab.visible = true
	else:
		for carriage in Locomotive.instance.carriages:
			var new_button: Button = character_leave_button_scene.instantiate()
			new_button.text = carriage.character.name
			new_button.icon = carriage.character.sprite_cadre
			new_button.pressed.connect(_on_character_leave_pressed.bind(carriage))
			%VBoxContainerLeaveButtons.add_child(new_button)
		%PanelStationPut.visible = true

func update_characters_ui():
	for child in %HBoxContainerCharacters.get_children():
		if child != %TextureLocomotive:
			child.queue_free()
	for carriage: Carriage in Locomotive.instance.carriages:
		var new_texture: TextureRect = character_icon_scene.instantiate()
		new_texture.texture = carriage.character.sprite_cadre
		%HBoxContainerCharacters.add_child(new_texture)
		%HBoxContainerCharacters.move_child(new_texture, 0)
	await get_tree().process_frame
	%MarginContainerCharacters.size = Vector2.ZERO

func leave_station():
	Locomotive.instance.restart()
	active_station = null
	%CameraShaker.target_node = camera_follow_pos

func get_character(character_name: String) -> CharacterInfo:
	for char: CharacterInfo in character_list:
		if char.name == character_name:
			return char
	return null

func set_single_signal(reqs: Array[String], parent_node: Control):
	for r: String in reqs:
		var char_name: String = r
		var forbidden: bool = false
		if r.begins_with("-"):
			char_name = r.substr(1)
			forbidden = true
		var new_signal: CharacterSignalisation = character_signalisation_scene.instantiate()
		parent_node.add_child(new_signal)
		new_signal.load_character(get_character(char_name))
		new_signal.set_forbidden(forbidden)

func set_signals(reqs_left: Array[String], reqs_right: Array[String]):
	set_single_signal(reqs_left, %SignalisationLeft)
	set_single_signal(reqs_right, %SignalisationRight)
	signals_up = true

func set_direction_valid(valid: bool):
	%LeverDirection.modulate = Color.WHITE if valid else Color.RED

func reset_signals():
	for child in %SignalisationLeft.get_children():
		child.queue_free()
	for child in %SignalisationRight.get_children():
		child.queue_free()
	signals_up = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			dragging_camera = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			dragging_camera = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_follow_pos.position.z += zoom_sensitivity
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_follow_pos.position.z -= zoom_sensitivity
		camera_follow_pos.position.z = clampf(camera_follow_pos.position.z, 2.5, 10.0)
	elif event is InputEventMouseMotion:
		if dragging_camera:
			camera_pivot_y.rotate_y(-event.relative.x * camera_sensitivity.y)
			camera_pivot_x.rotate_x(-event.relative.y * camera_sensitivity.x)
			camera_pivot_x.rotation_degrees.x = clampf(camera_pivot_x.rotation_degrees.x, -45.0, 20.0)

func _on_button_prendre_pressed() -> void:
	close_add_character()
	Locomotive.instance.add_character(active_station.waiting_character)
	active_station.remove_character()
	leave_station()

func _on_button_laisser_pressed() -> void:
	close_add_character()
	leave_station()

func close_add_character():
	%MarginContainerStationGrab.visible = false

func close_character_leave():
	%PanelStationPut.visible = false
	for child in %VBoxContainerLeaveButtons.get_children():
		%VBoxContainerLeaveButtons.remove_child(child)

func _on_button_no_one_pressed() -> void:
	close_character_leave()
	leave_station()
	

func _on_character_leave_pressed(carriage: Carriage):
	close_character_leave()
	Locomotive.instance.remove_carriage(carriage)
	active_station.set_character(carriage.character)
	leave_station()


func _on_check_box_toggled(toggled_on: bool) -> void:
	Locomotive.instance.stop_at_stations = toggled_on


func _on_area_loop_area_entered(area: Area3D) -> void:
	%CameraShaker.target_node = camera_loop_pos


func _on_area_loop_area_exited(area: Area3D) -> void:
	%CameraShaker.target_node = camera_follow_pos
