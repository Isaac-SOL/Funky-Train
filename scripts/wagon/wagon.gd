extends Node3D
class_name Wagon


@export var wheel_1: MeshInstance3D
@export var wheel_2: MeshInstance3D
@export var wheel_3: MeshInstance3D
@export var wheel_4: MeshInstance3D
@export var wheel_5: MeshInstance3D
@export var wheel_6: MeshInstance3D
@export var wheel_7: MeshInstance3D
@export var wheel_8: MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.




func _process(delta):
	spin_wheel(wheel_1, delta)
	spin_wheel(wheel_2, delta)
	spin_wheel(wheel_3, delta)
	spin_wheel(wheel_4, delta)
	spin_wheel(wheel_5, delta)
	spin_wheel(wheel_6, delta)
	spin_wheel(wheel_7, delta)
	spin_wheel(wheel_8, delta)


func spin_wheel(wheel: MeshInstance3D, delta):
	if wheel:
		wheel.rotate_z(deg_to_rad(-Global.wheel_speed * delta))
