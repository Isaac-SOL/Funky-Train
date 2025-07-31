class_name Locomotive extends PathFollow3D

@export var speed: float = 1

var curr_section_length: float

func _ready() -> void:
	curr_section_length = get_parent().curve.get_baked_length()

func _process(delta: float) -> void:
	var temp_progress := progress + delta * speed
	if temp_progress > curr_section_length:
		temp_progress -= curr_section_length
		change_section(get_section().out_sections[0])
	progress = temp_progress
	imgui()

func get_section() -> RailSection:
	return get_parent()

func change_section(new_section: RailSection):
	get_parent().remove_child(self)
	new_section.add_child(self)
	curr_section_length = get_parent().curve.get_baked_length()

func imgui():
	ImGui.Begin("Locomotive")
	if get_parent():
		ImGui.Text("Section : " + str(get_parent().id))
	ImGui.End()
