@tool
class_name RailSection extends Path3D

static var ID_COUNT: int = 0

@export var use_tilt: bool = false
@export var in_sections: Array[RailSection] = []
@export var out_sections: Array[RailSection] = []
@export var out_requirements_1: Array[String]
@export var out_requirements_2: Array[String]
@export_group("Toggle mode")
@export var is_toggled: bool = false
@export var current_direction_right: bool = false
@export var toggle_barrier: InterruptorBarrier
@export_category("Editor actions")
@export_tool_button("Rebake") var rebake_button = rebake
@export_tool_button("Align to in") var align_in_button = align_to_in_sections
@export_tool_button("Align to out") var align_out_button = align_to_out_sections
@export_tool_button("Make resources unique") var unique_button = make_unique
@export_tool_button("Flatten to Y=0") var flatten_button = flatten_to_zero
@export_tool_button("Create new section") var create_button = create_new_rail
@export_tool_button("Duplicate (from in_sections)") var duplicate_button = duplicate_from_in
@export_tool_button("Detach from other sections") var detach_button = detach_completely
@export var cut_point_index: int = 1
@export_tool_button("Cut from point index") var cut_button = cut_from_point_index
@export_tool_button("Fuse with next section") var fuse_button = fuse_with_next


var id: int
var interactibles: Array[PathFollow3D] = []
var clear_outline_scheduled: bool = false
var cross_tween: Tween
@onready var section_scene: PackedScene = load("res://objects/rail_section.tscn")

var length: float:
	get:
		return curve.get_baked_length()

func make_unique():
	if curve:
		curve = curve.duplicate()
	in_sections = in_sections.duplicate()
	out_sections = out_sections.duplicate()
	out_requirements_1 = out_requirements_1.duplicate()
	out_requirements_2 = out_requirements_2.duplicate()

func _ready() -> void:
	if Engine.is_editor_hint():
		get_parent().set_editable_instance(self, true)
		set_meta("_edit_group_", true)
	else:
		id = ID_COUNT
		ID_COUNT += 1
		%CrossTween.visible = false
		%CrossTween.scale = Vector3.ZERO
		assert(in_sections.size() > 0)
		assert(out_sections.size() > 0)
		assert(out_sections.size() <= 2)
		await get_tree().process_frame
		%BakedRailsMesh.position.y = randf_range(-0.002, 0.002)
		%BakedRailsMeshMinimap.visible = true
		if is_toggled and toggle_barrier:
			toggle_barrier.switch(current_direction_right, true)

func add_interactible(interactible: PathFollow3D):
	interactibles.append(interactible)

func remove_interactible(interactible: PathFollow3D):
	var idx := interactibles.find(interactible)
	if idx != -1:
		interactibles.remove_at(idx)

func get_next_interactible(prog: float) -> PathFollow3D:
	if interactibles.is_empty():
		return null
	var res: PathFollow3D = null
	for interactible: PathFollow3D in interactibles:
		if interactible.progress > prog and (not res or interactible.progress < res.progress):
			res = interactible
	return res

func toggle():
	if is_toggled:
		current_direction_right = not current_direction_right
		if toggle_barrier:
			toggle_barrier.switch(current_direction_right)

func clear_outline_await():
	clear_outline_scheduled = true
	await get_tree().create_timer(2.0).timeout
	if clear_outline_scheduled:
		clear_outline_scheduled = false
		%OutlineMesh.visible = false
		%BakedRailsMesh.position.y = 0.0
		%OutlineMesh.position.y = -0.005

func set_outline(vis: bool, recurse: bool = true):
	print(name + " call set_outline " + str(vis))
	if %OutlineMesh.visible == vis:
		return
	print(name + " do set_outline " + str(vis))
	%OutlineMesh.visible = vis
	if vis:
		%BakedRailsMesh.position.y = 0.01
		%OutlineMesh.position.y = 0.005
	else:
		%BakedRailsMesh.position.y = randf_range(-0.002, 0.002)
		%OutlineMesh.position.y = -0.005
	clear_outline_scheduled = false
	if recurse and out_sections.size() == 1:
		print(name + " recurse to " + out_sections[0].name)
		out_sections[0].set_outline(vis)

func set_cross(vis: bool):
	if not vis and not %CrossTween.visible:
		return
	if cross_tween:
		cross_tween.kill()
	%CrossTween.visible = true
	cross_tween = create_tween()
	cross_tween.set_ease(Tween.EASE_OUT if vis else Tween.EASE_IN)
	cross_tween.set_trans(Tween.TRANS_QUAD)
	cross_tween.tween_property(%CrossTween, "scale", Vector3.ONE if vis else Vector3.ZERO, 0.3)
	cross_tween.tween_callback(func(): %CrossTween.visible = vis)

func rebake():
	%BakedRailsMesh.rebake()
	%BakedRailsMeshMinimap.rebake()

func get_main_mesh() -> BakedRailsMesh:
	return %BakedRailsMesh

func get_outline_mesh() -> BakedRailsMesh:
	return %OutlineMesh

func get_minimap_mesh() -> BakedRailsMesh:
	return %BakedRailsMeshMinimap

func align_to_in_sections():
	if in_sections and in_sections.size() > 0:
		var in_rail := in_sections[0]
		var in_curve := in_rail.curve
		global_position = in_rail.global_position + in_curve.get_point_position(in_curve.point_count - 1)
		curve.set_point_out(0, -in_curve.get_point_in(in_curve.point_count - 1))
	for in_rail in in_sections:
		if self not in in_rail.out_sections:
			in_rail.out_sections.append(self)

func align_to_out_sections():
	if out_sections and out_sections.size() > 0:
		var out_rail := out_sections[0]
		var out_curve := out_rail.curve
		curve.set_point_position(curve.point_count - 1, to_local(out_rail.global_position))
		curve.set_point_in(curve.point_count - 1, -out_curve.get_point_out(0))
	for out_rail in out_sections:
		if self not in out_rail.in_sections:
			out_rail.in_sections.append(self)

func flatten_to_zero():
	position.y = 0
	var flattener := Vector3(1.0, 0.0, 1.0)
	for p: int in curve.point_count:
		curve.set_point_position(p, curve.get_point_position(p) * flattener)
		if p > 0:
			curve.set_point_in(p, curve.get_point_in(p) * flattener)
		if p < curve.point_count - 1:
			curve.set_point_out(p, curve.get_point_out(p) * flattener)

func check_overflow():
	if out_sections.size() > 2:
		printerr(name + " has " + str(out_sections.size()) + " out_sections (warning)")

func create_new_rail():
	var new_rail: RailSection = section_scene.instantiate()
	new_rail.name = name + "_s"
	add_sibling(new_rail)
	new_rail.owner = owner
	new_rail.in_sections = [self]
	out_sections.append(new_rail)
	check_overflow()
	new_rail.align_to_in_sections()

func duplicate_from_in():
	var new_rail: RailSection = section_scene.instantiate()
	new_rail.name = name + "_d"
	add_sibling(new_rail)
	new_rail.owner = owner
	new_rail.in_sections = in_sections.duplicate()
	for in_section: RailSection in in_sections:
		in_section.out_sections.append(new_rail)
		in_section.check_overflow()
	new_rail.curve = curve.duplicate()
	new_rail.align_to_in_sections()

func detach_completely():
	for in_section: RailSection in in_sections:
		var idx := in_section.out_sections.find(self)
		if idx >= 0:
			in_section.out_sections.remove_at(idx)
	for out_section: RailSection in out_sections:
		var idx := out_section.in_sections.find(self)
		if idx >= 0:
			out_section.in_sections.remove_at(idx)
	in_sections = []
	out_sections = []
	out_requirements_1 = []
	out_requirements_2 = []

func cut_from_point_index():
	if curve.point_count < 3 or cut_point_index < 1 or cut_point_index >= curve.point_count - 1:
		printerr("Cut point index must not be an end point")
		return
	
	var my_new_curve: Curve3D = curve.duplicate()
	while my_new_curve.point_count > cut_point_index + 1:
		my_new_curve.remove_point(cut_point_index + 1)
	var next_new_curve: Curve3D = curve.duplicate()
	for i in range(cut_point_index):
		next_new_curve.remove_point(0)
	var next_curve_base_pos := curve.get_point_position(cut_point_index)
	for i in range(next_new_curve.point_count):
		next_new_curve.set_point_position(i, next_new_curve.get_point_position(i) - next_curve_base_pos)
	curve = my_new_curve
	
	var new_rail: RailSection = section_scene.instantiate()
	new_rail.name = name + "_c"
	new_rail.curve = next_new_curve
	add_sibling(new_rail)
	new_rail.owner = owner
	new_rail.in_sections = [self]
	new_rail.out_sections = out_sections.duplicate()
	new_rail.out_requirements_1 = out_requirements_1
	new_rail.out_requirements_2 = out_requirements_2
	new_rail.is_toggled = is_toggled
	new_rail.current_direction_right = current_direction_right
	new_rail.toggle_barrier = toggle_barrier
	out_requirements_1 = []
	out_requirements_2 = []
	is_toggled = false
	toggle_barrier = null
	for out_section: RailSection in out_sections:
		var idx := out_section.in_sections.find(self)
		if idx >= 0:
			out_section.in_sections[idx] = new_rail
	out_sections = [new_rail]
	new_rail.align_to_in_sections()

func fuse_with_next():
	if out_sections.size() != 1:
		print("There is not exactly one out_section to fuse with")
		return
	if out_sections[0].in_sections.size() != 1 or out_sections[0].in_sections[0] != self:
		print("out_section does not have this section as its only in_section")
		return
	
	var next_points_base_pos := curve.get_point_position(curve.point_count - 1)
	var my_new_curve: Curve3D = curve.duplicate()
	var next_curve = out_sections[0].curve
	for idx in range(1, next_curve.point_count):
		my_new_curve.add_point(next_curve.get_point_position(idx) + next_points_base_pos)
	my_new_curve.set_point_out(curve.point_count - 1, -curve.get_point_in(curve.point_count - 1))
	for idx in range(1, next_curve.point_count):
		my_new_curve.set_point_in(curve.point_count + idx - 1, next_curve.get_point_in(idx))
		if idx < next_curve.point_count - 1:
			my_new_curve.set_point_out(curve.point_count + idx - 1, next_curve.get_point_out(idx))
	curve = my_new_curve
	
	var old_next_section := out_sections[0]
	out_sections = old_next_section.out_sections
	for out_section: RailSection in out_sections:
		var idx := out_section.in_sections.find(old_next_section)
		if idx >= 0:
			out_section.in_sections[idx] = self
	out_requirements_1 = old_next_section.out_requirements_1
	out_requirements_2 = old_next_section.out_requirements_2
	is_toggled = old_next_section.is_toggled
	current_direction_right = old_next_section.current_direction_right
	toggle_barrier = old_next_section.toggle_barrier
	old_next_section.queue_free()
