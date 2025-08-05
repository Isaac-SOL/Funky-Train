@tool
class_name BakedRailsMesh extends MeshInstance3D

@export var path : Path3D
@export var material : Material
@export var vertex_per_meter : float = 5.0
@export var width : float = 1.0
@export var rebake_on_ready : bool = false
@export var rebake_with_tilt: bool = false
@export_tool_button("Rebake") var rebake_button = rebake

func _ready() -> void:
	if rebake_on_ready:
		rebake()
	if not Engine.is_editor_hint():
		%OutlineMesh.mesh = mesh

func rebake():
	var curve := path.curve
	var vertices_amount := floori(curve.get_baked_length() * vertex_per_meter)
	mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	
	print("Generating ", vertices_amount, " * 2 vertices")
	for vi: int in range(vertices_amount):
		var p := (vi / float(vertices_amount - 1)) * curve.get_baked_length()
		var sample_tr := curve.sample_baked_with_rotation(p, true, rebake_with_tilt)
		var right_normal := sample_tr.basis.x.normalized()
		var right_vec := right_normal * width / 2.0
		var right_pt := sample_tr.origin + right_vec
		var left_pt := sample_tr.origin - right_vec
		vertices.push_back(right_pt)
		normals.push_back(right_normal)
		uvs.push_back(Vector2(0.0, 0.0))
		vertices.push_back(left_pt)
		normals.push_back(-right_normal)
		uvs.push_back(Vector2(1.0, 0.0))
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arrays)
	mesh.surface_set_material(0, material)
	
	var res_name := "res://meshes/rails/" + get_parent().name + ".tres"
	var save := ResourceSaver.save(mesh, res_name, ResourceSaver.FLAG_CHANGE_PATH)
	mesh = load(res_name)
	if save != OK:
		printerr(save)
