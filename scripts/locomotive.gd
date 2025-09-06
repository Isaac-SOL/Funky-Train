class_name Locomotive extends PathFollow3D

enum SpeedMode {
	STOP,
	NORMAL,
	FAST
}

signal speed_mode_changed(new_speed: SpeedMode)
signal character_attached(new_character: CharacterInfo)
signal character_detached(new_character: CharacterInfo)

static var instance: Locomotive

@export var speed_mode: SpeedMode = SpeedMode.STOP
@export var normal_speed: float = 3.0
@export var fast_speed: float = 8.0
@export var startup_time: float = 1.5
@export var stop_time: float = 3.0
@export var length: float = 2
@export var spacing: float = 0.2
@export var carriages: Array[Carriage] = []
@export var bypass: bool = false
@export var show_signals_at_distance: float = 30.0
@export_group("Music Sync")
#@export var beats_per_minute: float = 120.0
@export var beats_per_measure: int = 4
@export var kick_up_effect: float = 1.3

var speed: float = 0.0
var target_speed: float = 0.0
var curr_section_length: float = 0.0
var direction: bool = false
var locked: bool = false
var section_history: Array[RailSection] = []

func _ready() -> void:
	instance = self
	curr_section_length = get_parent().curve.get_baked_length()
	for carriage: Carriage in carriages:
		carriage.locomotive = self
	restart()
	await get_tree().process_frame
	update_characters()
	Main.instance.rhythm_sync.beat.connect(_on_beat)
	RailsColorManager.reconnect()
	section_history.append(get_section())
	
	await Main.instance.game_started
	update_rail_outlines()

func _process(delta: float) -> void:
	# Acceleration / Deceleration
	if locked:
		speed = 0.0
	else:
		if speed < target_speed:
			speed += normal_speed * delta / startup_time
			if speed > target_speed:
				speed = target_speed
		if speed > target_speed:
			var eff_stop_time := stop_time if speed <= 12.0 else (stop_time / 2.0)
			speed -= normal_speed * delta / eff_stop_time
			if speed < target_speed:
				speed = target_speed
	
	# Moving code
	
	var next_interactible = get_section().get_next_interactible(progress)
	var temp_progress := progress + delta * speed
	if speed_mode != SpeedMode.FAST and next_interactible is Station and next_interactible.progress < temp_progress:
		# Stop at stations
		progress = next_interactible.progress
		speed = 0.0
		locked = true
		Main.instance.stop_at_station(next_interactible)
	else:
		if next_interactible and next_interactible.progress < temp_progress:
			# Press interruptors
			if next_interactible is Interruptor:
				if next_interactible.broken:
					if "hub2_hard" in get_properties():
						next_interactible.fix()
				if not next_interactible.broken:
					next_interactible.press()
					update_crosses()
					update_rail_outlines()
			# Take accelerators
			if next_interactible is Accelerator:
				speed = next_interactible.instant_speed
				%AudioAcceleration.play()
			# Apply other interactible effects
			if next_interactible is GenericInteractible:
				next_interactible.interact()
		# Move forward
		if temp_progress > curr_section_length:
			temp_progress -= curr_section_length
			var section_to_change := next_section()
			change_section(section_to_change, get_section().out_sections.find(section_to_change))
		progress = temp_progress
	var carr_pos := calc_carriage_positions()
	for i in range(carriages.size()):
		carriages[i].set_carriage_progress(carr_pos[i].progress, carr_pos[i].section)
	
	# Show signals
	
	if not Main.instance.signals_up and get_distance_to_section_end() < show_signals_at_distance:
		Main.instance.set_signals(get_section().out_requirements_1, get_section().out_requirements_2)
		set_main_directions_valid()
	
	# Animation
	Global.wheel_speed = floori(180 * speed)
	
	#imgui()

func _on_beat(counter: int):
	counter %= 4
	if counter == 0:
		kick_up()
	for i in range(carriages.size()):
		if (i + 1) % beats_per_measure == counter:
			carriages[i].kick_up()

func set_speed_mode(new_speed: SpeedMode):
	speed_mode = new_speed
	if speed_mode == SpeedMode.STOP:
		target_speed = 0.0
	elif speed_mode == SpeedMode.NORMAL:
		target_speed = normal_speed
	elif speed_mode == SpeedMode.FAST:
		if "F" in get_properties():
			target_speed = 12
		else:
			target_speed = fast_speed
	speed_mode_changed.emit(speed_mode)

func check_requirements(req_list: Array[String]) -> bool:
	if bypass:
		return true
	var props := get_properties()
	for req in req_list:
		if req.begins_with("-"):
			var rev_req := req.substr(1)
			if rev_req in props:
				# Saxophone
				if rev_req == "start" and "cat" in props:
					continue
				return false
		else:
			if req not in props:
				return false
	return true

func check_direction_valid() -> bool:
	if get_section().is_toggled:
		return direction == get_section().current_direction_right
	else:
		if direction:
			return check_requirements(get_section().out_requirements_2)
		else:
			return check_requirements(get_section().out_requirements_1)

func set_main_directions_valid():
	if get_section().is_toggled:
		Main.instance.set_direction_valid(
			not get_section().current_direction_right,
			get_section().current_direction_right
		)
	else:
		Main.instance.set_direction_valid(
			check_requirements(get_section().out_requirements_1),
			check_requirements(get_section().out_requirements_2)
		)

func next_section() -> RailSection:
	var out_sections := get_section().out_sections
	if out_sections.size() == 1:
		return out_sections[0]
	if get_section().is_toggled:
		return out_sections[1 if get_section().current_direction_right else 0]
	var eff_out_sections: Array[RailSection] = []
	if check_requirements(get_section().out_requirements_1):
		eff_out_sections.append(out_sections[0])
	if check_requirements(get_section().out_requirements_2):
		eff_out_sections.append(out_sections[1])
	if not direction:
		return eff_out_sections[0]
	else:
		return eff_out_sections[eff_out_sections.size() - 1]

func get_section() -> RailSection:
	return get_parent()

func add_section_history(section: RailSection):
	section_history.insert(0, section)
	if section_history.size() > 10:
		section_history = section_history.slice(0, 10)

func change_direction(new_direction: bool):
	direction = new_direction
	update_rail_outlines()
	update_crosses()

func change_section(new_section: RailSection, out_idx: int):
	assert(out_idx != -1)
	# Remove potential effects
	var req_ref := get_section().out_requirements_1 if out_idx == 0 else get_section().out_requirements_2
	var props := get_properties()
	if "-start" in req_ref and "cat" in props: # Cat eats mice
		req_ref.remove_at(req_ref.find("-start"))
	if "hub2_hard" in req_ref: # Fix broken rails
		req_ref.remove_at(req_ref.find("hub2_hard"))
	if "hub2" in req_ref: # Break rocks
		req_ref.remove_at(req_ref.find("hub2"))
	
	# Leave current section
	print("--- Change Section (leaving " + get_section().name + ") ---")
	print("Current history (recent first): " + str(section_history))
	if section_history.size() >= 2:
		section_history[1].set_outline(false, false)
	get_section().set_cross(false)
	for section: RailSection in get_section().out_sections:
		section.set_cross(false)
	
	# Change section
	print("--- Change Section (changing to " + new_section.name + ") ---")
	get_parent().remove_child(self)
	new_section.add_child(self)
	curr_section_length = get_parent().curve.get_baked_length()
	add_section_history(get_section())
	Main.instance.reset_signals()
	Main.instance.set_direction_valid(true, true)
	update_rail_outlines()
	update_crosses()

func calc_carriage_positions() -> Array[CarriagePosition]:
	var res: Array[CarriagePosition] = []
	var curr_progress = progress - (length / 2.0) - spacing
	var curr_section_idx = 0
	for carriage: Carriage in carriages:
		var new_pos := CarriagePosition.new()
		curr_progress -= carriage.length / 2.0
		new_pos.progress = curr_progress
		while curr_progress < 0.0:
			curr_section_idx += 1
			curr_progress += section_history[curr_section_idx].length
		new_pos.section = section_history[curr_section_idx]
		curr_progress -= (carriage.length / 2.0) + spacing
		res.append(new_pos)
	return res

func add_character(new_character: CharacterInfo):
	var new_carriage: Carriage = new_character.carriage.instantiate()
	new_carriage.character = new_character
	carriages.append(new_carriage)
	var carr_pos := calc_carriage_positions()[-1]
	carr_pos.section.add_child(new_carriage)
	update_characters()
	update_rail_outlines()
	update_crosses()
	if new_character.name == "hub2":
		%chef_locomotive2.set_ruddy(true)
	Main.instance.character_attached(new_character)

func remove_carriage(carriage: Carriage):
	carriages.remove_at(carriages.find(carriage))
	carriage.queue_free()
	update_characters()
	update_rail_outlines()
	update_crosses()
	if carriage.character.name == "hub2":
		%chef_locomotive2.set_ruddy(false)
	Main.instance.character_detached(carriage.character)

func update_characters():
	Main.instance.update_characters_ui()
	RailsColorManager.update_gradient()
	if get_distance_to_section_end() < show_signals_at_distance:
		set_main_directions_valid()

func restart():
	locked = false

func get_properties() -> Array[String]:
	var props: Array[String] = []
	for carriage in carriages:
		props.append(carriage.character.name)
	return props

func get_distance_to_section_end() -> float:
	return curr_section_length - progress

func kick_up():
	%MeshInstance3D.scale = Vector3(1.0, kick_up_effect, 1.0)
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(%MeshInstance3D, "scale", Vector3.ONE, 0.5)

func update_rail_outlines():
	print("=> Calling update_rail_outlines")
	var next := next_section()
	for section in get_section().out_sections:
		section.set_outline(section == next)
	get_section().set_outline(true)

func update_crosses():
	get_section().set_cross(false)
	if get_section().out_sections.size() == 1:
		get_section().out_sections[0].set_cross(false)
	else:
		if direction:
			get_section().out_sections[0].set_cross(false)
			get_section().out_sections[1].set_cross(not check_direction_valid())
		else:
			get_section().out_sections[1].set_cross(false)
			get_section().out_sections[0].set_cross(not check_direction_valid())

func get_visible_center() -> Vector3:
	return %VisibleCenter.global_position

func get_visible_extent() -> Vector3:
	return %VisibleExtent.global_position

func get_camera_pivot_x() -> Node3D:
	return %CameraPivotX

func get_camera_pivot_y() -> Node3D:
	return %CameraPivotY

func get_camera_follow_pos() -> Node3D:
	return %CameraFollowPos

func get_camera_loop_pos() -> Node3D:
	return %CameraLoopPos

func get_minimap_pos() -> Node3D:
	return %MinimapPos

func get_end_pos() -> Node3D:
	return %EndPos

#func imgui():
	#ImGui.Begin("Locomotive")
	#if get_parent():
		#ImGui.Text("Section : " + str(get_parent().id))
	#var v: Array = [speed]
	#if ImGui.InputFloat("Speed", v):
		#speed = v[0]
	#var v2: Array = [target_speed]
	#if ImGui.InputFloat("Target Speed", v2):
		#target_speed = v2[0]
	#var v3: Array = [locked]
	#if ImGui.Checkbox("Locked", v3):
		#locked = v3[0]
	#ImGui.Text("Direction : " + ("Right" if direction else "Left"))
	#var v4: Array = [bypass]
	#if ImGui.Checkbox("Bypass", v4):
		#bypass = v4[0]
	#var next_station := get_section().get_next_station(progress)
	#ImGui.Text("Next station : " + (str(next_station.progress - progress) if next_station else "None"))
	#if ImGui.CollapsingHeader("Carriages"):
		#ImGui.TreePush("carriage_tree")
		#for carriage in carriages:
			#ImGui.Text("Section : " + str(carriage.get_section().id))
		#ImGui.TreePop()
	#ImGui.End()
