@tool
class_name RailsMaster extends Node3D

@export_tool_button("Rebake all sections") var rebake_button = rebake_all
@export_tool_button("Flatten all sections to Y=0") var flatten_button = flatten_all
@export_tool_button("Fix Discontinuities") var fix_button = fix_discontinuities

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
