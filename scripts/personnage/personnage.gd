extends Node3D
class_name Personnage

@export var squeeze_amount = 0.3
@export var sprite_3d: Sprite3D
@onready var squeeze_max = sprite_3d.scale.y + sprite_3d.scale.y* squeeze_amount
@onready var squeeze_min = sprite_3d.scale.y - sprite_3d.scale.y* squeeze_amount
var is_scaling_up = true
var dance_speed = Global.dance_speed

func _process(delta: float) -> void:
	squeeze(delta)
	

func squeeze(delta):
	if is_scaling_up:
		if sprite_3d.scale.y < squeeze_max:
			sprite_3d.scale.y += delta*(dance_speed/100)
			sprite_3d.position.y += delta*(dance_speed/29)
		else:
			is_scaling_up = false
	else:
		if sprite_3d.scale.y > squeeze_min:
			sprite_3d.scale.y -= delta*(dance_speed/100)
			sprite_3d.position.y -= delta*(dance_speed/29)
		else:
			is_scaling_up = true
