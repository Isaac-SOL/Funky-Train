@tool
class_name BakedRailsMesh extends MeshInstance3D

@export var path : Path3D
@export var material : Material
@export var vertex_per_meter : float = 5.0
@export var width : float = 1.0
@export var rebake_on_ready : bool = true
@export var rebake_with_tilt: bool = false
@export_tool_button("Rebake") var rebake_button = rebake

func _ready() -> void:
	if rebake_on_ready:
		rebake()

func rebake():
	var curve := path.curve
	var vertices_amount := floori(curve.get_baked_length() * vertex_per_meter)
	mesh = ImmediateMesh.new()
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, material)
	mesh.surface_set_normal(Vector3.UP)
	print("Generating ", vertices_amount, " * 2 vertices")
	for vi: int in range(vertices_amount):
		var p := (vi / float(vertices_amount - 1)) * curve.get_baked_length()
		var sample_tr := curve.sample_baked_with_rotation(p, true, rebake_with_tilt)
		var right_vec := sample_tr.basis.x.normalized() * width / 2.0
		var right_pt := sample_tr.origin + right_vec
		var left_pt := sample_tr.origin - right_vec
		mesh.surface_set_uv(Vector2(0.0, 0.0))
		mesh.surface_add_vertex(right_pt)
		mesh.surface_set_uv(Vector2(1.0, 0.0))
		mesh.surface_add_vertex(left_pt)
	mesh.surface_end()
