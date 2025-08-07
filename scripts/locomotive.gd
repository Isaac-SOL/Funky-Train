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
var last_section: RailSection

func _ready() -> void:
	instance = self
	curr_section_length = get_parent().curve.get_baked_length()
	for carriage: Carriage in carriages:
		carriage.locomotive = self
	restart()
	await get_tree().process_frame
	update_characters()
	Main.instance.rhythm_sync.beat.connect(_on_beat)
	
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
			speed -= normal_speed * delta / stop_time
			if speed < target_speed:
				speed = target_speed
	
	# Stop at stations
	
	var next_station = get_section().get_next_station(progress)
	var temp_progress := progress + delta * speed
	if speed_mode != SpeedMode.FAST and next_station and next_station.progress < temp_progress:
		progress = next_station.progress
		speed = 0.0
		locked = true
		Main.instance.stop_at_station(next_station)
	else:
		if temp_progress > curr_section_length:
			temp_progress -= curr_section_length
			change_section(next_section())
		progress = temp_progress
	var next_carriage_end := progress - (length / 2.0) - spacing
	for carriage: Carriage in carriages:
		carriage.set_carriage_progress(next_carriage_end - (carriage.length / 2.0), get_section())
		next_carriage_end -= carriage.length + spacing
	
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
				return false
		else:
			if req not in props:
				return false
	return true

func check_direction_valid() -> bool:
	if direction:
		return check_requirements(get_section().out_requirements_2)
	else:
		return check_requirements(get_section().out_requirements_1)

func set_main_directions_valid():
	Main.instance.set_direction_valid(
		check_requirements(get_section().out_requirements_1),
		check_requirements(get_section().out_requirements_2)
	)

func next_section() -> RailSection:
	var out_sections := get_section().out_sections
	if out_sections.size() == 1:
		return out_sections[0]
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

func change_direction(new_direction: bool):
	direction = new_direction
	update_rail_outlines()
	update_crosses()

func change_section(new_section: RailSection):
	# Leave current section
	get_section().clear_outline_await()
	get_section().set_cross(false)
	for section: RailSection in get_section().out_sections:
		section.set_cross(false)
	last_section = get_section()
	
	# Change section
	get_parent().remove_child(self)
	new_section.add_child(self)
	curr_section_length = get_parent().curve.get_baked_length()
	Main.instance.reset_signals()
	Main.instance.set_direction_valid(true, true)
	update_rail_outlines()
	update_crosses()

func add_character(new_character: CharacterInfo):
	var new_carriage: Carriage = new_character.carriage.instantiate()
	new_carriage.character = new_character
	carriages.append(new_carriage)
	var last_carriage := carriages[carriages.size() - 1]
	if last_carriage.get_section() != get_section() \
			or last_carriage.progress - (last_carriage.length / 2) - (new_carriage.length / 2) < 0.0:
		last_section.add_child(new_carriage)
	else:
		get_section().add_child(new_carriage)
	update_characters()
	update_rail_outlines()
	update_crosses()
	Main.instance.character_attached(new_character)

func remove_carriage(carriage: Carriage):
	carriages.remove_at(carriages.find(carriage))
	carriage.queue_free()
	update_characters()
	update_rail_outlines()
	update_crosses()
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
