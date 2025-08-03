class_name WhistleString extends TextureRect

@export var distance_to_toot: float = 125.0

var is_dragging: bool = false
var drag_pos: Vector2 = Vector2.ZERO
var is_tooting: bool = false

func mouse_down(_event: InputEventMouseButton):
	is_dragging = true
	drag_pos = Vector2.ZERO
	update_string()

func mouse_up():
	is_dragging = false
	is_tooting = false
	%AudioStreamPlayer.turn_whistle_on(false)
	drag_pos = Vector2.ZERO
	update_string()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.button_mask == 1:
				mouse_down(event)
			else:
				mouse_up()
	elif event is InputEventMouseMotion:
		if is_dragging:
			drag_pos += event.screen_relative
			update_string()
			if drag_pos.y >= distance_to_toot and not is_tooting:
				%AudioStreamPlayer.turn_whistle_on(true)
				is_tooting = true

func update_string():
	var newScaleY = 0.009 * drag_pos.y
	if newScaleY > 1.6:
		newScaleY = 1.6
	if newScaleY < 1:
		newScaleY = 1
	scale.y = newScaleY
