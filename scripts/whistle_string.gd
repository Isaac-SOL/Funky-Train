class_name WhistleString extends Control

@export var distance_to_toot: float = 125.0
@export var initial_position: float = -153.0
const BASE_STRING_LENGTH: float = 285.0

var is_dragging: bool = false
var drag_pos: Vector2 = Vector2.ZERO
var is_tooting: bool = false

func mouse_down(_event: InputEventMouseButton):
	is_dragging = true
	drag_pos = Vector2(0,BASE_STRING_LENGTH)
	update_string()
	$TextureRect.mouse_default_cursor_shape = Input.CURSOR_POINTING_HAND

func mouse_up():
	is_dragging = false
	is_tooting = false
	%AudioStreamPlayer.turn_whistle_on(false)
	drag_pos = Vector2.ZERO
	update_string()
	$TextureRect.mouse_default_cursor_shape = Input.CURSOR_DRAG

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.button_mask == 1:
				mouse_down(event)
			else:
				mouse_up()
	elif event is InputEventMouseMotion:
		var mouse_pos = event.position - pivot_offset
		#print(mouse_pos)
		if is_dragging:
			#drag_pos += event.screen_relative
			print(event.screen_relative)
			drag_pos += event.screen_relative
			update_string()
			var string_length = sqrt(pow(drag_pos.x,2) + pow(drag_pos.y,2))
			if string_length >= (distance_to_toot+BASE_STRING_LENGTH) and not is_tooting:
				%AudioStreamPlayer.turn_whistle_on(true)
				is_tooting = true
			elif string_length < (distance_to_toot+BASE_STRING_LENGTH) and is_tooting:
				%AudioStreamPlayer.turn_whistle_on(false)
				is_tooting = false

func update_string():
	var texture = get_child(0)
	var string_length = sqrt(pow(drag_pos.x,2) + pow(drag_pos.y,2))
	var newScaleY = string_length / BASE_STRING_LENGTH
	if newScaleY > 2:
		newScaleY = 2
	if newScaleY < 1:
		newScaleY = 1
	var move_y = abs(initial_position) * (newScaleY-1)
	texture.position.y = initial_position + move_y
	texture.pivot_offset.y = abs(initial_position) - move_y
	texture.rotation = -atan2(drag_pos.x,drag_pos.y)
	
