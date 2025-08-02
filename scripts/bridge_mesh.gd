@tool
class_name BridgeMesh extends MeshInstance3D

@export var path : Path3D
@export var material : Material
@export var vertex_per_meter : float = 5.0
@export var width : float = 1.2
@export var height : float = 5.0
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
	
	var sample_tr := curve.sample_baked_with_rotation(0, true)
	var right_vec := sample_tr.basis.x.normalized() * width / 2.0
	var right_pt := sample_tr.origin + right_vec
	var left_pt := sample_tr.origin - right_vec
	var b_right_pt := right_pt - Vector3.UP * height
	var b_left_pt := left_pt - Vector3.UP * height
	vertices.push_back(right_pt)
	vertices.push_back(left_pt)
	vertices.push_back(b_left_pt)
	vertices.push_back(b_right_pt)
	indices.append_array(PackedInt32Array([2, 1, 0, 2, 0, 3]))
	
	var b: int = 0
	for vi: int in range(1, vertices_amount):
		var p := (vi / float(vertices_amount - 1)) * curve.get_baked_length()
		sample_tr = curve.sample_baked_with_rotation(p, true)
		right_vec = sample_tr.basis.x.normalized() * width / 2.0
		right_pt = sample_tr.origin + right_vec
		left_pt = sample_tr.origin - right_vec
		b_right_pt = right_pt - Vector3.UP * height
		b_left_pt = left_pt - Vector3.UP * height
		vertices.push_back(right_pt)
		vertices.push_back(left_pt)
		vertices.push_back(b_left_pt)
		vertices.push_back(b_right_pt)
		indices.append_array(PackedInt32Array([
			b, b + 5, b + 4,
			b + 5, b, b + 1,  # Top
			b + 1, b + 6, b + 5,
			b + 6, b + 1, b + 2,  # Left
			b + 2, b + 7, b + 6,
			b + 7, b + 2, b + 3,  # Bottom
			b + 3, b + 4, b + 7,
			b + 4, b + 3, b  # Right
		]))
		b += 4
	
	indices.append_array(PackedInt32Array([
			b, b + 1, b + 2,
			b, b + 2, b + 3
		]))
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	#arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
