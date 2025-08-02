class_name SpeedLever extends TextureRect

enum SpeedMode { STOP = 0, NORMAL, DOUBLE }

@export var distance_to_switch: float = 150.0

var is_dragging: bool = false
var speed: SpeedMode = SpeedMode.STOP
var drag_pos: Vector2 = Vector2.ZERO

func mouse_down(_event: InputEventMouseButton):
	is_dragging = true
	drag_pos = Vector2.ZERO

func mouse_up():
	is_dragging = false

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.button_mask == 1:
				mouse_down(event)
			else:
				mouse_up()
	elif event is InputEventMouseMotion:
		if is_dragging:
			drag_pos += event.screen_relative
			if drag_pos.x >= 50 and drag_pos.y <= -50 and speed < SpeedMode.DOUBLE:
				change_speed(int(speed) + 1 as SpeedMode)
				drag_pos = Vector2.ZERO
			elif drag_pos.x <= -50 and drag_pos.y >= 50 and speed > SpeedMode.STOP:
				change_speed(int(speed) - 1 as SpeedMode)
				drag_pos = Vector2.ZERO

func change_speed(new_speed: SpeedMode):
	speed = new_speed
	rotation_degrees = -70 + 25 * int(speed)
	Locomotive.instance.target_speed = int(speed) * Locomotive.instance.normal_speed
	%AudioStreamPlayer.changeCarSpeed(new_speed)
