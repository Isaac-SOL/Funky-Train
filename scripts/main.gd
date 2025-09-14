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
@export var puzzle_map: bool = false
@export var two_options: bool = true
@export var fallback_if_web: bool = true
@export var other_map: PackedScene
@export_group("Cursor")
@export var direction_cursor: Texture
@export var speed_cursor: Texture
@export var can_grab_cursor: Texture
@export var grabbing_cursor: Texture

var active_station: Station
var signals_up: bool = false
@onready var camera: Camera3D = %MainCamera
var dragging_camera: bool = false
var ended: bool = false
var on_end_screen: bool = false
var cursor_start_drag_pos: Vector2 = Vector2.ZERO
var camera_speed_tween: Tween
var biome_color_tween: Tween
var on_menu: bool = true
var sky_mat: ProceduralSkyMaterial

func _ready() -> void:
	instance = self
	Input.set_custom_mouse_cursor(direction_cursor, Input.CURSOR_HSIZE, Vector2(32, 32))
	Input.set_custom_mouse_cursor(speed_cursor, Input.CURSOR_BDIAGSIZE, Vector2(32, 32))
	Input.set_custom_mouse_cursor(can_grab_cursor, Input.CURSOR_DRAG, Vector2(32, 32))
	Input.set_custom_mouse_cursor(grabbing_cursor, Input.CURSOR_POINTING_HAND, Vector2(32, 32))
	sky_mat = $WorldEnvironment.environment.sky.sky_material
	#Preload Diologic timeline by starting a blanc timeline
	Dialogic.start("timeline_blanc")
	Dialogic.VAR.set_variable("puzzle_mode", puzzle_map)
	if fallback_if_web and Util.on_web():
		two_options = false
	%VBoxContainerTwoOptions.visible = two_options
	%ButtonStart.visible = not two_options
	%LanguageButtonOneOption.visible = not two_options
	
	if not TranslationServer.get_locale().begins_with("fr"):
		TranslationServer.set_locale("en")
	
	await get_tree().process_frame
	%CameraShakerMap.target_node = Locomotive.instance.get_minimap_pos()
	Locomotive.instance.tb_powered.connect(_on_tb_powered)
	if not puzzle_map:
		%AudioStreamPlayer.setVocoderState(true)

func stop_at_station(station: Station):
	active_station = station
	station.reveal()
	%CameraShaker.target_node = active_station.get_camera_pos()
	var character_info := station.waiting_character
	if character_info:
		%LabelTitre.text = character_info.true_name
		%LabelTitre.label_settings.font_color = character_info.color
		talk(character_info.instrument)
		await Dialogic.timeline_ended
		%MarginContainerStationGrab.visible = true
	else:
		for carriage in Locomotive.instance.carriages:
			var new_button: Button = character_leave_button_scene.instantiate()
			new_button.text = carriage.character.true_name
			new_button.icon = carriage.character.sprite_cadre
			new_button.pressed.connect(_on_character_leave_pressed.bind(carriage))
			new_button.add_theme_color_override("font_color", carriage.character.color)
			new_button.add_theme_color_override("font_focus_color", carriage.character.color)
			new_button.add_theme_color_override("font_pressed_color", carriage.character.color)
			new_button.add_theme_color_override("font_hover_color", carriage.character.color)
			new_button.add_theme_color_override("font_hover_pressed_color", carriage.character.color)
			new_button.add_theme_color_override("font_disabled_color", carriage.character.color)
			%VBoxContainerLeaveButtons.add_child(new_button)
		%PanelStationPut.visible = true

func update_characters_ui():
	var carriages := Locomotive.instance.carriages
	for i: int in range(%HBoxContainerCharacters2.get_child_count()):
		if i < carriages.size():
			%HBoxContainerCharacters2.get_child(i).load_character(carriages[i].character)
		else:
			%HBoxContainerCharacters2.get_child(i).reset_character()
	
	#for child in %HBoxContainerCharacters.get_children():
		#child.queue_free()
	#for carriage: Carriage in Locomotive.instance.carriages:
		#var new_texture: TextureRect = character_icon_scene.instantiate()
		#new_texture.texture = carriage.character.sprite_cadre
		#%HBoxContainerCharacters.add_child(new_texture)
		#%HBoxContainerCharacters.move_child(new_texture, 0)
	#await get_tree().process_frame

func leave_station():
	Locomotive.instance.restart()
	active_station = null
	%CameraShaker.target_node = Locomotive.instance.get_camera_follow_pos()

func get_character(character_name: String) -> CharacterInfo:
	for char: CharacterInfo in character_list:
		if char.name == character_name:
			return char
	return null

func set_single_signal(reqs: Array[String], parent_node: Control):
	return
	for r: String in reqs:
		var char_name: String = r
		var forbidden: bool = false
		if r.begins_with("-"):
			char_name = r.substr(1)
			forbidden = true
		var new_signal: CharacterSignalisation = character_signalisation_scene.instantiate()
		parent_node.add_child(new_signal)
		var char := get_character(char_name)
		if char:
			new_signal.load_character(char)
		new_signal.set_forbidden(forbidden)

func set_signals(reqs_left: Array[String], reqs_right: Array[String]):
	return # Removed function
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
	var pivot_x := Locomotive.instance.get_camera_pivot_x()
	var pivot_y := Locomotive.instance.get_camera_pivot_y()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			dragging_camera = true
			cursor_start_drag_pos = event.position * Util.current_viewport_factor(self)
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			dragging_camera = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			await get_tree().process_frame
			if cursor_start_drag_pos != Vector2.ZERO:
				Input.warp_mouse(cursor_start_drag_pos)
				cursor_start_drag_pos = Vector2.ZERO
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			pivot_x.target_position.z += zoom_sensitivity
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			pivot_x.target_position.z -= zoom_sensitivity
		pivot_x.target_position.z = clampf(pivot_x.target_position.z, 2.5, 10.0)
	elif event is InputEventMouseMotion:
		if dragging_camera:
			pivot_y.rotate_y(-event.relative.x * camera_sensitivity.y)
			pivot_x.rotate_x(-event.relative.y * camera_sensitivity.x)
			pivot_x.rotation_degrees.x = clampf(pivot_x.rotation_degrees.x, -45.0, 10.0)

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
	%CharacterMessages.spawn_dialogue(info)
	#if ended:
		#return
	#for child in %VBoxContainerDialogue.get_children():
		#if child is QuickDialogue and child.my_info == info:
			#return
	#var new_dialogue: QuickDialogue = quick_dialogue_scene.instantiate()
	#%VBoxContainerDialogue.add_child(new_dialogue)
	#new_dialogue.spawn(info)
	#%AudioStreamPop.play()

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
		%CameraShaker.target_node = Locomotive.instance.get_camera_loop_pos()
		if camera_speed_tween:
			camera_speed_tween.kill()
		camera_speed_tween = create_tween().set_parallel()
		camera_speed_tween.tween_property(%CameraShaker, "move_speed", 30.0, 0.5)
		camera_speed_tween.tween_property(%CameraShaker, "rotation_speed", 30.0, 0.5)


func _on_area_loop_area_exited(area: Area3D) -> void:
	if area.is_in_group("group_locomotive") and not on_end_screen:
		%CameraShaker.move_speed = 8.0
		%CameraShaker.rotation_speed = 8.0
		%CameraShaker.target_node = Locomotive.instance.get_camera_follow_pos()

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
	%CameraShaker.target_node = Locomotive.instance.get_camera_follow_pos()
	on_menu = false
	game_started.emit()

func switch_biome_color(info: BiomeColor):
	if biome_color_tween:
		biome_color_tween.kill()
	biome_color_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	biome_color_tween.set_parallel()
	biome_color_tween.tween_property(%Sun, "light_color", info.sun_color, 5.0)
	biome_color_tween.tween_property(%Sun, "light_energy", info.sun_energy, 5.0)
	biome_color_tween.tween_property(%ScreenEffect, "mesh:material:shader_parameter/depth_gradient_color",
									 info.depth_gradient_color, 5.0)
	biome_color_tween.tween_property(%ScreenEffect, "mesh:material:shader_parameter/depth_gradient_strength",
									 info.depth_gradient_strength, 5.0)
	biome_color_tween.tween_property(%ScreenEffect, "mesh:material:shader_parameter/cloud_gradient_strength",
									 info.deep_depth_gradient_strength, 5.0)
	biome_color_tween.tween_property(self, "sky_mat:sky_top_color", info.sky_top_color, 5.0)
	biome_color_tween.tween_property(self, "sky_mat:sky_horizon_color", info.sky_bottom_color, 5.0)
	biome_color_tween.tween_property(self, "sky_mat:ground_horizon_color", info.sky_bottom_color, 5.0)
	var sun_sprite: Sprite3D = $"../Sky/Node3DClouds/Node3D/Sprite3D"
	biome_color_tween.tween_property(sun_sprite, "modulate", info.sun_sprite_modulate, 5.0)
	

func start_end_screen():
	ended = true
	on_end_screen = true
	await get_tree().process_frame
	await get_tree().process_frame
	Locomotive.instance.set_speed_mode(Locomotive.SpeedMode.FAST)
	Locomotive.instance.bypass = true
	%CameraShaker.target_node = Locomotive.instance.get_end_pos()
	%GameUI.visible = false
	%ControlEnd.visible = true
	
	await get_tree().create_timer(2.0).timeout
	%LabelCredits.visible = true
	
	await get_tree().create_timer(3.0).timeout
	%LabelCredits.visible = false
	await get_tree().create_timer(1.0).timeout
	%LabelCredits.text = "A Loopy Game made by 6 friends\n(mostly) in 96 hours"
	%LabelCredits.visible = true
	
	await get_tree().create_timer(5.0).timeout
	%LabelCredits.visible = false
	await get_tree().create_timer(1.0).timeout
	%LabelCredits.text = "Level Design:\nCryptal\nSaltyIsaac"
	%LabelCredits.visible = true
	
	await get_tree().create_timer(3.0).timeout
	%LabelCredits.visible = false
	await get_tree().create_timer(1.0).timeout
	%LabelCredits.text = "Programming & Shaders:\nSaltyIsaac"
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
	%LabelCredits.text = "Terrain & Environments:\nArkatein\nSaltyIsaac"
	%LabelCredits.visible = true
	
	await get_tree().create_timer(3.0).timeout
	%LabelCredits.visible = false
	await get_tree().create_timer(1.0).timeout
	%LabelCredits.text = "Engine integration:\nSaltyIsaac\nArkatein\nJananass"
	%LabelCredits.visible = true
	
	await get_tree().create_timer(3.0).timeout
	%LabelCredits.visible = false
	await get_tree().create_timer(1.0).timeout
	%LabelCredits.text = "Additional Models (poly.pizza):\nCreativeTrio\n4444ESOUSA\nQuaternius\njeremy\nsirkitree\niPoly3D"
	%LabelCredits.visible = true
	
	await get_tree().create_timer(3.0).timeout
	%LabelCredits.visible = false
	await get_tree().create_timer(1.0).timeout
	%LabelCredits.text = "Additional SFX (freesound.org):\nandersmmg\nshyguy014\ndanielpodlovics\nadr1911"
	%LabelCredits.visible = true
	
	await get_tree().create_timer(3.0).timeout
	%LabelCredits.visible = false
	await get_tree().create_timer(1.0).timeout
	%LabelCredits.text = "Additional Icons (flaticon.com):\nVictoruler\nsonnycandra\nFreepik\nrsetiawan\nKiranshastry"
	%LabelCredits.visible = true
	
	await get_tree().create_timer(3.0).timeout
	%LabelCredits.visible = false
	await get_tree().create_timer(1.0).timeout
	%LabelCredits.text = "Playtesting:\nTakahiruma\nMalisa\nDironiil"
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
	%CameraShaker.target_node = Locomotive.instance.get_camera_follow_pos()
	%GameUI.visible = true
	%ControlEnd.visible = false
	on_end_screen = false
	credits_ended.emit()
	

func rail_outline_beat(extent: float):
	rails_outline_material.set_shader_parameter("extent", extent)

func _on_rhythm_notifier_beat(current_beat: int) -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_method(rail_outline_beat, 0.27, 0.2, 0.66)
	#tween.tween_method(rail_outline_beat, 0.15, 0.27, 0.03)
	#tween.tween_method(rail_outline_beat, 0.27, 0.0, 0.53).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

func _on_tb_powered():
	for child in %HBoxContainerCharacters2.get_children():
		if child is CharacterPortrait:
			child.power_tb()
	%AudioStreamPlayer.setVocoderState(true)
	%AudioStreamPlayer.setInstrument(MainMusicController.Track.VOCODER, true)
	await get_tree().create_timer(1.5).timeout
	var tb_dialogue := DialogueInfo.new()
	tb_dialogue.character = get_character("hub3")
	tb_dialogue.text = "PUZZ_TB_STARTUP"
	tb_dialogue.time = 5.0
	tb_dialogue.indentation = 0
	spawn_dialogue(tb_dialogue)

func _on_start_button_puzzle_click_open() -> void:
	%StartButtonPuzzle.open()
	if %StartButtonJam.opened:
		%StartButtonJam.close()


func _on_start_button_puzzle_click_confirm() -> void:
	if puzzle_map:
		_on_button_start_pressed()
	else:
		# Open other scene
		%AudioStreamPlayer.remove_filter()
		get_tree().change_scene_to_packed(other_map)


func _on_start_button_jam_click_open() -> void:
	%StartButtonJam.open()
	if %StartButtonPuzzle.opened:
		%StartButtonPuzzle.close()


func _on_start_button_jam_click_confirm() -> void:
	if not puzzle_map:
		_on_button_start_pressed()
	else:
		# Open other scene
		%AudioStreamPlayer.remove_filter()
		get_tree().change_scene_to_packed(other_map)


func _on_language_button_pressed() -> void:
	if TranslationServer.get_locale().begins_with("fr"):
		TranslationServer.set_locale("en")
	else:
		TranslationServer.set_locale("fr")
