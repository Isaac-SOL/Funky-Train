class_name Locomotive extends PathFollow3D

static var instance: Locomotive

@export var speed: float = 1
@export var length: float = 2
@export var spacing: float = 0.2
@export var carriages: Array[Carriage] = []

var curr_section_length: float
var direction: bool

func _ready() -> void:
	instance = self
	curr_section_length = get_parent().curve.get_baked_length()
	for carriage: Carriage in carriages:
		carriage.locomotive = self

func _process(delta: float) -> void:
	var next_station = get_section().get_next_station(progress)
	var temp_progress := progress + delta * speed
	if next_station and next_station.progress < temp_progress:
		progress = next_station.progress
		speed = 0.0
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
	imgui()

func next_section() -> RailSection:
	if not direction:
		return get_section().out_sections[0]
	else:
		return get_section().out_sections[get_section().out_sections.size() - 1]

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

func remove_carriage(carriage: Carriage):
	carriages.remove_at(carriages.find(carriage))
	carriage.queue_free()

func restart():
	var tween := get_tree().create_tween()
	tween.tween_property(self, "speed", 2.0, 1.5)

func get_properties() -> Array[String]:
	var props: Array[String] = []
	for carriage in carriages:
		props.append(carriage.character.name)
	return props

func imgui():
	ImGui.Begin("Locomotive")
	if get_parent():
		ImGui.Text("Section : " + str(get_parent().id))
	var v: Array = [speed]
	if ImGui.InputFloat("Speed", v):
		print(v)
		speed = v[0]
	if ImGui.Button("Direction"):
		direction = not direction
	ImGui.Text("Right" if direction else "Left")
	var next_station := get_section().get_next_station(progress)
	ImGui.Text("Next station : " + str((next_station.progress - progress) if next_station else "None"))
	if ImGui.CollapsingHeader("Carriages"):
		for carriage in carriages:
			ImGui.Text("Section : " + str(carriage.get_section().id))
	ImGui.End()
