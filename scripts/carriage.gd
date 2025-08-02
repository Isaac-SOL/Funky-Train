@tool
class_name Carriage extends PathFollow3D

@export var length: float = 2
@export var kick: float = 1.2

var curr_section_length: float
var direction: bool
var locomotive: Locomotive
var character: CharacterInfo

func _ready() -> void:
	curr_section_length = get_parent().curve.get_baked_length()

func set_carriage_progress(prog_relative: float, new_section: RailSection):
	if prog_relative < 0.0:
		prog_relative += get_section().curve.get_baked_length()
	elif new_section != get_section():
		change_section(new_section)
	progress = prog_relative

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

func kick_up():
	for child in get_children():
		if child is Node3D:
			child.scale = Vector3(1.0, kick, 1.0)
			var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
			tween.tween_property(child, "scale", Vector3.ONE, 0.5)
