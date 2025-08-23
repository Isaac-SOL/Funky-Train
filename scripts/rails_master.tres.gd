@tool
class_name RailsMaster extends Node3D

@export_tool_button("Rebake all sections") var rebake_button = rebake_all

func rebake_all():
	for child in get_children():
		if child is RailSection:
			child.rebake()
		elif child is RailsMaster:
			child.rebake_all()
