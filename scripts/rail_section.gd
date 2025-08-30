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

var id: int
var interactibles: Array[PathFollow3D] = []
var clear_outline_scheduled: bool = false
var cross_tween: Tween

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
	else:
		id = ID_COUNT
		ID_COUNT += 1
		%CrossTween.visible = false
		%CrossTween.scale = Vector3.ZERO
		assert(in_sections.size() > 0)
		assert(out_sections.size() > 0)
		assert(out_sections.size() <= 2)
		await get_tree().process_frame
		%BakedRailsMeshMinimap.visible = true
		if is_toggled and toggle_barrier:
			toggle_barrier.switch(current_direction_right)

func add_interactible(interactible: PathFollow3D):
	interactibles.append(interactible)

func get_next_interactible(prog: float) -> PathFollow3D:
	if interactibles.is_empty():
		return null
	var res: PathFollow3D = null
	for interactible: PathFollow3D in interactibles:
		if interactible.progress > prog and (not res or interactible.progress < res.progress):
			res = interactible
	return res

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
		%BakedRailsMesh.position.y = 0.0
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

func toggle():
	if is_toggled:
		current_direction_right = not current_direction_right
		if toggle_barrier:
			toggle_barrier.switch(current_direction_right)
