class_name DirectionLever extends TextureRect

@export var distance_to_switch: float = 150.0

var is_dragging: bool = false
var is_right: bool = false
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
			var offset = -drag_pos.x if is_right else drag_pos.x
			if offset > distance_to_switch:
				change_direction(not is_right)
				drag_pos = Vector2.ZERO

func change_direction(right: bool):
	is_right = right
	rotation_degrees = 35 if right else -35
	Locomotive.instance.direction = right
