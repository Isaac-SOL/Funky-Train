class_name Locomotive extends PathFollow3D

static var instance: Locomotive

@export var normal_speed: float = 2.0
@export var startup_time: float = 1.5
@export var stop_time: float = 3.0
@export var length: float = 2
@export var spacing: float = 0.2
@export var carriages: Array[Carriage] = []
@export_group("Music Sync")
@export var beats_per_minute: float = 120.0
@export var beats_per_measure: int = 4

var speed: float = 0.0
var target_speed: float
var curr_section_length: float
var direction: bool
var bpm_timer: float = 1.0
var bpm_counter: int = 0
var locked: bool = false

func _ready() -> void:
	target_speed = normal_speed
	instance = self
	curr_section_length = get_parent().curve.get_baked_length()
	for carriage: Carriage in carriages:
		carriage.locomotive = self
	restart()

func _process(delta: float) -> void:
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
	
	var next_station = get_section().get_next_station(progress)
	var temp_progress := progress + delta * speed
	if next_station and next_station.progress < temp_progress:
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
	
	imgui()

func check_requirements(req_list: Array[String]) -> bool:
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

func add_character(new_character: CharacterInfo):
	var new_carriage: Carriage = new_character.carriage.instantiate()
	new_carriage.character = new_character
	carriages.append(new_carriage)
	get_section().add_child(new_carriage)
	Main.instance.update_characters_ui()

func remove_carriage(carriage: Carriage):
	carriages.remove_at(carriages.find(carriage))
	carriage.queue_free()
	Main.instance.update_characters_ui()

func restart():
	locked = false

func get_properties() -> Array[String]:
	var props: Array[String] = []
	for carriage in carriages:
		props.append(carriage.character.name)
	return props

func kick_up():
	%MeshInstance3D.scale = Vector3(1.0, 1.5, 1.0)
	var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(%MeshInstance3D, "scale", Vector3.ONE, 0.5)

func imgui():
	ImGui.Begin("Locomotive")
	if get_parent():
		ImGui.Text("Section : " + str(get_parent().id))
	var v: Array = [speed]
	if ImGui.InputFloat("Speed", v):
		speed = v[0]
	var v2: Array = [target_speed]
	if ImGui.InputFloat("Target Speed", v2):
		target_speed = v2[0]
	var v3: Array = [locked]
	if ImGui.Checkbox("Locked", v3):
		locked = v3[0]
	if ImGui.Button("Direction"):
		direction = not direction
	ImGui.Text("Right" if direction else "Left")
	var next_station := get_section().get_next_station(progress)
	ImGui.Text("Next station : " + str((next_station.progress - progress) if next_station else "None"))
	if ImGui.CollapsingHeader("Carriages"):
		ImGui.TreePush("carriage_tree")
		for carriage in carriages:
			ImGui.Text("Section : " + str(carriage.get_section().id))
		ImGui.TreePop()
	ImGui.End()
