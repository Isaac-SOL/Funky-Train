@tool
class_name RailsMaster extends Node3D

@export_tool_button("Rebake all sections") var rebake_button = rebake_all
@export_tool_button("Flatten all sections to Y=0") var flatten_button = flatten_all
@export_tool_button("Fix discontinuities") var fix_button = fix_discontinuities
@export_tool_button("Recalculate metrics") var metrics_button = calc_metrics

var total_meters: float
var total_primitives: int
var rails: int

func rebake_all():
	for child in get_children():
		if child is RailSection:
			child.rebake()
		elif child is RailsMaster:
			child.rebake_all()

func flatten_all():
	for child in get_children():
		if child is RailSection:
			child.flatten_to_zero()
		elif child is RailsMaster:
			child.flatten_all()

func fix_discontinuities():
	for child in get_children():
		if child is RailSection:
			child.align_to_in_sections()
			child.align_to_out_sections()
		elif child is RailsMaster:
			child.fix_discontinuities()

func calc_metrics():
	rails = 0
	total_meters = 0.0
	total_primitives = 0
	for child in get_children():
		if child is RailSection:
			total_meters += child.curve.get_baked_length()
			var sub_segments := floori(child.curve.get_baked_length() * child.get_main_mesh().vertex_per_meter)
			total_primitives += (sub_segments - 1) * 2
			rails += 1
		elif child is RailsMaster:
			child.calc_metrics()
			total_meters += child.total_meters
			total_primitives += child.total_primitives
			rails += child.rails
	var print_meters: float = floor(total_meters * 10.0) / 10.0
	print(name + ": " + str(rails) + " sections, " + str(print_meters) + "m, " + str(total_primitives) + " primitives")
