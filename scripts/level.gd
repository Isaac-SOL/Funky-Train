extends Node3D

@export var custom_detail_shader: Shader
@export var see_through_layers: PackedInt32Array

@onready var area_3d_plane: Area3D = $Area3D_plane
@onready var area_3d_desert: Area3D = $Area3D_desert
@onready var area_3d_beach: Area3D = $Area3D_beach

var previous_area : Area3D
var detail_materials: Array[ShaderMaterial] = []

func _ready() -> void:
	await get_tree().process_frame
	for child: Node in %HTerrain.get_children():
		var mat: Material = child.get("_material") as ShaderMaterial
		if mat and mat.shader == custom_detail_shader:
			var layer_index = child.get("layer_index")
			if layer_index != null and layer_index is int and layer_index in see_through_layers:
				detail_materials.append(child._material)
			else:
				child._material.set_shader_parameter("locomotive_data_screenspace", Vector4(0.0, 0.0, 0.0, 100.0))

func _process(delta: float) -> void:
	var loco_pos := Main.instance.camera.unproject_position(Locomotive.instance.get_visible_center())
	var loco_extent_pos := Main.instance.camera.unproject_position(Locomotive.instance.get_visible_extent())
	var loco_radius := (loco_extent_pos - loco_pos).length()
	var loco_dist := (Locomotive.instance.get_visible_center() - Main.instance.camera.global_position).length()
	var loco_data := Vector4(loco_pos.x, loco_pos.y, loco_radius, loco_dist)
	for mat: ShaderMaterial in detail_materials:
		mat.set_shader_parameter("locomotive_data_screenspace", loco_data)

func _on_area_3d_plane_area_entered(area: Area3D) -> void:
	if area.is_in_group("group_locomotive"):
		if previous_area != area_3d_plane:
			print("is in plains")
			previous_area = area_3d_plane
			NodeAudio.playAudio_stream1(&"Ambiant plane")


func _on_area_3d_desert_area_entered(area: Area3D) -> void:
	if area.is_in_group("group_locomotive"):
		if previous_area != area_3d_desert:
			print("is in desert")
			previous_area = area_3d_desert
			NodeAudio.playAudio_stream1(&"Ambiant desert")


func _on_area_3d_beach_area_entered(area: Area3D) -> void:
	if area.is_in_group("group_locomotive"):
		if previous_area != area_3d_beach:
			print("is in beach")
			previous_area = area_3d_beach
			NodeAudio.playAudio_stream1(&"Ambiant beach")
