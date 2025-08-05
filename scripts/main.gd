class_name Main extends Node3D

signal game_started
signal game_ended
signal credits_ended

static var instance: Main

@export var character_list: Array[CharacterInfo]
@export var character_leave_button_scene: PackedScene
@export var character_icon_scene: PackedScene
@export var character_signalisation_scene: PackedScene
@export var camera_sensitivity: Vector2 = Vector2.ONE
@export var zoom_sensitivity: float = 1.0
@export var quick_dialogue_scene: PackedScene
@export var rhythm_sync: RhythmNotifier
@export var rails_outline_material: ShaderMaterial
@export_group("Cursor")
@export var direction_cursor: Texture
@export var speed_cursor: Texture
@export var can_grab_cursor: Texture
@export var grabbing_cursor: Texture

var active_station: Station
var signals_up: bool = false
@onready var camera_follow_pos: Node3D = %CameraFollowPos
@onready var camera_pivot_x: Node3D = %CameraPivotX
@onready var camera_pivot_y: Node3D = %CameraPivotY
@onready var camera_loop_pos: Node3D = %CameraLoopPos
@onready var camera_end_pos: Node3D = %EndPos
var dragging_camera: bool = false
var ended: bool = false
var on_end_screen: bool = false

func _ready() -> void:
	instance = self
	Input.set_custom_mouse_cursor(direction_cursor, Input.CURSOR_HSIZE, Vector2(32, 32))
	Input.set_custom_mouse_cursor(speed_cursor, Input.CURSOR_BDIAGSIZE, Vector2(32, 32))
	Input.set_custom_mouse_cursor(can_grab_cursor, Input.CURSOR_DRAG, Vector2(32, 32))
	Input.set_custom_mouse_cursor(grabbing_cursor, Input.CURSOR_POINTING_HAND, Vector2(32, 32))
	#Preload Diologic timeline by starting a blanc timeline
	Dialogic.start("timeline_blanc")

func stop_at_station(station: Station):
	active_station = station
	station.reveal()
	%CameraShaker.target_node = active_station.get_camera_pos()
	var character_info := station.waiting_character
	if character_info:
		%LabelTitre.text = character_info.true_name
		talk(character_info.instrument)
		await Dialogic.timeline_ended
		%MarginContainerStationGrab.visible = true
	else:
		for carriage in Locomotive.instance.carriages:
			var new_button: Button = character_leave_button_scene.instantiate()
			new_button.text = carriage.character.true_name
			new_button.icon = carriage.character.sprite_cadre
			new_button.pressed.connect(_on_character_leave_pressed.bind(carriage))
			%VBoxContainerLeaveButtons.add_child(new_button)
		%PanelStationPut.visible = true

func update_characters_ui():
	for child in %HBoxContainerCharacters.get_children():
		child.queue_free()
	for carriage: Carriage in Locomotive.instance.carriages:
		var new_texture: TextureRect = character_icon_scene.instantiate()
		new_texture.texture = carriage.character.sprite_cadre
		%HBoxContainerCharacters.add_child(new_texture)
		%HBoxContainerCharacters.move_child(new_texture, 0)
	await get_tree().process_frame

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

func set_direction_valid(valid_left: bool, valid_right: bool):
	%CroixLeft.visible = not valid_left
	%CroixRight.visible = not valid_right

func reset_signals():
	for child in %SignalisationLeft.get_children():
		child.queue_free()
	for child in %SignalisationRight.get_children():
		child.queue_free()
	signals_up = false

func talk(npc_name: String):
	if Dialogic.current_timeline == null:
		#Dialogic.timeline_ended.connect(_on_timeline_ended)
		Dialogic.start("timeline_"+npc_name)

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
			camera_pivot_x.rotation_degrees.x = clampf(camera_pivot_x.rotation_degrees.x, -45.0, 10.0)

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

func spawn_dialogue(info: DialogueInfo):
	if ended:
		return
	for child in %VBoxContainerDialogue.get_children():
		if child is QuickDialogue and child.my_info == info:
			return
	var new_dialogue: QuickDialogue = quick_dialogue_scene.instantiate()
	%VBoxContainerDialogue.add_child(new_dialogue)
	new_dialogue.spawn(info)
	%AudioStreamPop.play()

func _on_button_no_one_pressed() -> void:
	close_character_leave()
	leave_station()
	

func _on_character_leave_pressed(carriage: Carriage):
	close_character_leave()
	Locomotive.instance.remove_carriage(carriage)
	active_station.set_character(carriage.character)
	leave_station()


func _on_area_loop_area_entered(area: Area3D) -> void:
	if area.is_in_group("group_locomotive") and not on_end_screen:
		%CameraShaker.target_node = camera_loop_pos


func _on_area_loop_area_exited(area: Area3D) -> void:
	if area.is_in_group("group_locomotive") and not on_end_screen:
		%CameraShaker.target_node = camera_follow_pos

func character_attached(new_character: CharacterInfo):
	%AudioStreamPlayerAttachDetach.play()
	if new_character.track_id != -1:
		%AudioStreamPlayer.setInstrument(new_character.track_id, true)
	Dialogic.VAR.set_variable("has.has_" + new_character.instrument, true)
	
	if Locomotive.instance.carriages.size() >= 9 and not ended:
		game_ended.emit()
		start_end_screen()

func character_detached(char: CharacterInfo):
	%AudioStreamPlayerAttachDetach.play()
	if char.track_id != -1:
		%AudioStreamPlayer.setInstrument(char.track_id, false)
	Dialogic.VAR.set_variable("has.has_" + char.instrument, false)

func _on_h_slider_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(0, value)

#func _on_timeline_ended():
	#Dialogic.timeline_ended.disconnect(_on_timeline_ended)


func _on_button_start_pressed() -> void:
	%ControlStart.visible = false
	%GameUI.visible = true
	%CameraShaker.target_node = camera_follow_pos
	game_started.emit()

func start_end_screen():
	ended = true
	on_end_screen = true
	await get_tree().process_frame
	await get_tree().process_frame
	Locomotive.instance.set_speed_mode(Locomotive.SpeedMode.FAST)
	Locomotive.instance.bypass = true
	%CameraShaker.target_node = camera_end_pos
	%GameUI.visible = false
	%ControlEnd.visible = true
	
	await get_tree().create_timer(2.0).timeout
	%LabelCredits.visible = true
	
	await get_tree().create_timer(3.0).timeout
	%LabelCredits.visible = false
	await get_tree().create_timer(1.0).timeout
	%LabelCredits.text = "A Loopy Game made by 6 friends\nin 96 hours"
	%LabelCredits.visible = true
	
	await get_tree().create_timer(5.0).timeout
	%LabelCredits.visible = false
	await get_tree().create_timer(1.0).timeout
	%LabelCredits.text = "Level Design:\nCryptal"
	%LabelCredits.visible = true
	
	await get_tree().create_timer(3.0).timeout
	%LabelCredits.visible = false
	await get_tree().create_timer(1.0).timeout
	%LabelCredits.text = "Programming:\nSaltyIsaac"
	%LabelCredits.visible = true
	
	await get_tree().create_timer(3.0).timeout
	%LabelCredits.visible = false
	await get_tree().create_timer(1.0).timeout
	%LabelCredits.text = "Music & SFX:\nJananass"
	%LabelCredits.visible = true
	
	await get_tree().create_timer(3.0).timeout
	%LabelCredits.visible = false
	await get_tree().create_timer(1.0).timeout
	%LabelCredits.text = "2D Art:\nPopouleto\nAshrell"
	%LabelCredits.visible = true
	
	await get_tree().create_timer(3.0).timeout
	%LabelCredits.visible = false
	await get_tree().create_timer(1.0).timeout
	%LabelCredits.text = "3D Models:\nPopouleto\nArkatein"
	%LabelCredits.visible = true
	
	await get_tree().create_timer(3.0).timeout
	%LabelCredits.visible = false
	await get_tree().create_timer(1.0).timeout
	%LabelCredits.text = "Environments:\nArkatein"
	%LabelCredits.visible = true
	
	await get_tree().create_timer(3.0).timeout
	%LabelCredits.visible = false
	await get_tree().create_timer(1.0).timeout
	%LabelCredits.text = "Engine integration:\nSaltyIsaac\nArkatein\nJananass"
	%LabelCredits.visible = true
	
	await get_tree().create_timer(3.0).timeout
	%LabelCredits.visible = false
	await get_tree().create_timer(1.0).timeout
	%LabelCredits.text = "Playtesting:\nTakahiruma"
	%LabelCredits.visible = true
	
	await get_tree().create_timer(3.0).timeout
	%LabelCredits.visible = false
	await get_tree().create_timer(1.0).timeout
	%LabelCredits.text = "Cat:\nJin"
	%LabelCredits.visible = true
	
	await get_tree().create_timer(3.0).timeout
	%LabelCredits.visible = false
	await get_tree().create_timer(1.0).timeout
	%LabelCredits.text = "Thanks for playing!"
	%LabelCredits.visible = true
	%AudioStreamFin.play()
	
	await get_tree().create_timer(5.0).timeout
	%LabelCredits.visible = false
	%CameraShaker.target_node = camera_follow_pos
	%GameUI.visible = true
	%ControlEnd.visible = false
	on_end_screen = false
	credits_ended.emit()
	

func rail_outline_beat(extent: float):
	rails_outline_material.set_shader_parameter("extent", extent)

func _on_rhythm_notifier_beat(current_beat: int) -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_method(rail_outline_beat, 0.23, 0.15, 0.66)
	#tween.tween_method(rail_outline_beat, 0.15, 0.27, 0.03)
	#tween.tween_method(rail_outline_beat, 0.27, 0.0, 0.53).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
