@tool
class_name RailSection extends Path3D

static var ID_COUNT: int = 0

@export var use_tilt: bool = false
@export var in_sections: Array[RailSection] = []
@export var out_sections: Array[RailSection] = []
@export var out_requirements_1: Array[String]
@export var out_requirements_2: Array[String]
@export_tool_button("Rebake") var rebake_button = rebake
@export_tool_button("Align to in") var align_in_button = align_to_in_sections
@export_tool_button("Align to out") var align_out_button = align_to_out_sections

var id: int
var stations: Array[Station] = []

func _ready() -> void:
	if Engine.is_editor_hint():
		get_parent().set_editable_instance(self, true)
		if curve:
			curve = curve.duplicate()
		in_sections = in_sections.duplicate()
		out_sections = out_sections.duplicate()
		out_requirements_1 = out_requirements_1.duplicate()
		out_requirements_2 = out_requirements_2.duplicate()
	else:
		id = ID_COUNT
		ID_COUNT += 1
		assert(in_sections.size() > 0)
		assert(out_sections.size() > 0)
		assert(out_sections.size() <= 2)

func add_station(station: Station):
	stations.append(station)

func get_next_station(prog: float) -> Station:
	if stations.is_empty():
		return null
	var res: Station = null
	for station: Station in stations:
		if station.progress > prog and (not res or station.progress < res.progress):
			res = station
	return res

func rebake():
	%BakedRailsMesh.rebake()

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
