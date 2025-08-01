class_name Locomotive extends PathFollow3D

static var instance: Locomotive

@export var normal_speed: float = 3.0
@export var startup_time: float = 1.5
@export var stop_time: float = 3.0
@export var length: float = 2
@export var spacing: float = 0.2
@export var carriages: Array[Carriage] = []
@export var rails_gradient: GradientTexture1D
@export var bypass: bool = false
@export var show_signals_at_distance: float = 30.0
@export_group("Music Sync")
@export var beats_per_minute: float = 120.0
@export var beats_per_measure: int = 4
@export var kick_up_effect: float = 1.3

var speed: float = 0.0
var target_speed: float = 0.0
var curr_section_length: float = 0.0
var direction: bool = false
var bpm_timer: float = 1.0
var bpm_counter: int = 0
var locked: bool = false
var stop_at_stations: bool = true

func _ready() -> void:
	target_speed = normal_speed
	instance = self
	curr_section_length = get_parent().curve.get_baked_length()
	for carriage: Carriage in carriages:
		carriage.locomotive = self
	restart()
	await get_tree().process_frame
	update_characters()

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
	if stop_at_stations and next_station and next_station.progress < temp_progress:
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
		Main.instance.set_direction_valid(check_direction_valid())
	
	# Animation
	
	bpm_timer -= delta * beats_per_minute / 60
	if bpm_timer <= 0:
		bpm_timer += 1.0
		bpm_counter += 1
		if bpm_counter >= beats_per_measure:
			bpm_counter -= beats_per_measure
			kick_up()
		for i in range(carriages.size()):
			if i % beats_per_measure == bpm_counter - 1:
				carriages[i].kick_up()
	
	#imgui()

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

func change_section(new_section: RailSection):
	get_parent().remove_child(self)
	new_section.add_child(self)
	curr_section_length = get_parent().curve.get_baked_length()
	Main.instance.reset_signals()
	Main.instance.set_direction_valid(true)

func add_character(new_character: CharacterInfo):
	var new_carriage: Carriage = new_character.carriage.instantiate()
	new_carriage.character = new_character
	carriages.append(new_carriage)
	get_section().add_child(new_carriage)
	update_characters()

func remove_carriage(carriage: Carriage):
	carriages.remove_at(carriages.find(carriage))
	carriage.queue_free()
	update_characters()

func update_characters():
	Main.instance.update_characters_ui()
	set_rails_gradient(get_gradient())
	if get_distance_to_section_end() < show_signals_at_distance:
		Main.instance.set_direction_valid(check_direction_valid())

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

func lerp_hsv(col1: Color, col2: Color, t: float):
	var v1 := Vector3(col1.h, col1.s, col1.v)
	var v2 := Vector3(col2.h, col2.s, col2.v)
	var vt: Vector3 = lerp(v1, v2, t)
	return Color.from_hsv(vt.x, vt.y, vt.z)

func get_gradient() -> Array[Color]:
	var res: Array[Color] = []
	if carriages.size() == 0:
		var col := Color.from_hsv(1.0, 0.0, 0.75)
		for i in range(5):
			res.append(col)
			col.v -= 0.1
	elif carriages.size() == 1:
		var col := carriages[0].character.color
		for i in range(5):
			res.append(col)
			col.v -= 0.1
	elif carriages.size() == 2:
		var col1 := carriages[0].character.color
		var col2 := carriages[1].character.color
		for i in range(5):
			res.append(lerp_hsv(col1, col2, i / 4.0))
	elif carriages.size() == 3:
		var col1 := carriages[0].character.color
		var col2 := carriages[1].character.color
		var col3 := carriages[2].character.color
		var col12 = lerp_hsv(col1, col2, 0.5)
		var col23 = lerp_hsv(col2, col3, 0.5)
		res.append_array([col1, col12, col2, col23, col3])
	elif carriages.size() == 4:
		var lead2 := carriages[0].character.color
		lead2.v -= 0.3
		res.append_array([
			carriages[0].character.color,
			lead2,
			carriages[1].character.color,
			carriages[2].character.color,
			carriages[3].character.color,
		])
	else:
		for carriage: Carriage in carriages:
			res.append(carriage.character.color)
	return res

func set_rails_gradient(colors: Array[Color]):
	var gradient := rails_gradient.gradient
	while(gradient.get_point_count() > 1):
		gradient.remove_point(0)
	gradient.set_offset(0, 0.0)
	gradient.set_color(0, colors[0])
	for i in range(1, colors.size()):
		gradient.add_point(float(i) / colors.size(), colors[i])

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
