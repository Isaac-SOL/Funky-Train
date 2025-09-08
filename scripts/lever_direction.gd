class_name DirectionLever extends TextureRect

@export var distance_to_switch: float = 150.0

var is_dragging: bool = false
var is_right: bool = false
var drag_pos: Vector2 = Vector2.ZERO
var hover_tween: Tween
var move_tween: Tween
var is_mouse_on_top: bool = false

func _process(delta: float) -> void:
	if not is_dragging and not Main.instance.on_menu:
		if Input.is_action_just_pressed("left") and is_right:
			change_direction(false)
		elif Input.is_action_just_pressed("right") and not is_right:
			change_direction(true)

func mouse_down(_event: InputEventMouseButton):
	is_dragging = true
	drag_pos = Vector2.ZERO
	move_to_target_rotation(true)

func mouse_up():
	is_dragging = false
	move_to_target_rotation()
	if not is_mouse_on_top:
		eff_mouse_exited()

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
				if Locomotive.instance.get_distance_to_section_end() <= Locomotive.instance.show_signals_at_distance:
					Locomotive.instance.set_main_directions_valid()
				drag_pos = Vector2.ZERO

func change_direction(right: bool):
	is_right = right
	move_to_target_rotation()
	Locomotive.instance.change_direction(right)
	%AudioStreamLever.play()

func get_target_rotation_degrees() -> float:
	var angle: float = 15.0 if is_right else -15.0
	return angle

func move_to_target_rotation(first_drag: bool = false):
	var degrees := get_target_rotation_degrees()
	if first_drag:
		degrees *= 0.75
	if move_tween:
		move_tween.kill()
	move_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	move_tween.tween_property(get_parent(), "rotation_degrees", degrees, 0.1)

func _on_mouse_entered() -> void:
	is_mouse_on_top = true
	if not is_dragging and not %LeverSpeed.is_dragging and not %WhistleControl.is_dragging:
		eff_mouse_entered()

func _on_mouse_exited() -> void:
	is_mouse_on_top = false
	if not is_dragging:
		eff_mouse_exited()

func eff_mouse_entered():
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	hover_tween.tween_property(self, "position", Vector2(-61.5, -250.0), 0.25)

func eff_mouse_exited():
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	hover_tween.tween_property(self, "position", Vector2(-61.5, -225.0), 0.25)
