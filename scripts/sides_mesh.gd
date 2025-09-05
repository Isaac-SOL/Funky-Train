@tool
class_name SidesMesh extends MeshInstance3D

@export var path : Path3D
@export var material : Material
@export var vertex_per_meter : float = 5.0
@export var width : float = 1.2
@export var height : float = 1.2
@export var rebake_with_tilt: bool = false
@export var skip_first: int = 0
@export var skip_last: int = 0
@export_tool_button("Rebake") var rebake_button = rebake

func rebake():
	var curve := path.curve
	var vertices_amount := floori(curve.get_baked_length() * vertex_per_meter)
	mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	var uvs = PackedVector2Array()
	
	var b: int = 0
	for vi: int in range(skip_first, vertices_amount - skip_last):
		var p := (vi / float(vertices_amount - 1)) * curve.get_baked_length()
		var sample_tr := curve.sample_baked_with_rotation(p, true, rebake_with_tilt)
		var right_vec := sample_tr.basis.x.normalized() * width / 2.0
		var up_vec := sample_tr.basis.y.normalized() * height
		var right_pt := sample_tr.origin + right_vec
		var left_pt := sample_tr.origin - right_vec
		var b_right_pt := right_pt - up_vec
		var b_left_pt := left_pt - up_vec
		vertices.push_back(right_pt)
		vertices.push_back(left_pt)
		vertices.push_back(b_left_pt)
		vertices.push_back(b_right_pt)
		uvs.push_back(Vector2(0.0, 0.0))
		uvs.push_back(Vector2(0.0, 0.0))
		uvs.push_back(Vector2(1.0, 0.0))
		uvs.push_back(Vector2(1.0, 0.0))
		if vi > skip_first:
			indices.append_array(PackedInt32Array([
				b + 1, b + 6, b + 5,
				b + 6, b + 1, b + 2,  # Left
				b + 2, b + 7, b + 6,
				b + 7, b + 2, b + 3,  # Bottom
				b + 3, b + 4, b + 7,
				b + 4, b + 3, b  # Right
			]))
			b += 4
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	#arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material)
