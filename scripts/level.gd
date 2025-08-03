extends Node3D


@onready var area_3d_plane: Area3D = $Area3D_plane
@onready var area_3d_desert: Area3D = $Area3D_desert
@onready var area_3d_beach: Area3D = $Area3D_beach

var previous_area : Area3D

func _on_area_3d_plane_area_entered(area: Area3D) -> void:
	if area.is_in_group("group_locomotive"):
		if previous_area != area_3d_plane:
			print("is in plane")
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
