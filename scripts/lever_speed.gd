class_name SpeedLever extends TextureRect

@export var distance_to_switch: float = 50.0

var is_dragging: bool = false
var speed: Locomotive.SpeedMode = Locomotive.SpeedMode.STOP
var drag_pos: Vector2 = Vector2.ZERO
var hover_tween: Tween
var move_tween: Tween
var is_mouse_on_top: bool = false

func _ready() -> void:
	await get_tree().process_frame
	Main.instance.rhythm_sync.beat.connect(func(_b):
		%TextureKimSuperspeed.scale = Vector2(1.2, 1.2)
		var tween := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(%TextureKimSuperspeed, "scale", Vector2.ONE, 0.5)
	)
	Locomotive.instance.character_attached.connect(locomotive_character_attached)
	Locomotive.instance.character_detached.connect(locomotive_character_detached)

func _process(delta: float) -> void:
	if not is_dragging and not Main.instance.on_menu:
		if Input.is_action_just_pressed("faster") and speed < Locomotive.SpeedMode.FAST:
			change_speed(speed + 1)
		elif Input.is_action_just_pressed("slower") and speed > Locomotive.SpeedMode.STOP:
			change_speed(speed - 1)

func mouse_down(_event: InputEventMouseButton):
	is_dragging = true
	drag_pos = Vector2.ZERO

func mouse_up():
	is_dragging = false
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
			var eff_dist := distance_to_switch * Util.current_viewport_factor(self)
			if drag_pos.x >= eff_dist.x and drag_pos.y <= -eff_dist.y and speed < Locomotive.SpeedMode.FAST:
				change_speed(int(speed) + 1 as Locomotive.SpeedMode)
				drag_pos = Vector2.ZERO
			elif drag_pos.x <= -eff_dist.x and drag_pos.y >= eff_dist.y and speed > Locomotive.SpeedMode.STOP:
				change_speed(int(speed) - 1 as Locomotive.SpeedMode)
				drag_pos = Vector2.ZERO

func change_speed(new_speed: Locomotive.SpeedMode):
	speed = new_speed
	move_to_target_rotation()
	Locomotive.instance.set_speed_mode(new_speed)
	%AudioStreamLeverSpeed.pitch_scale = 0.9 + 0.1 * int(new_speed)
	await get_tree().process_frame
	%AudioStreamLeverSpeed.play()

func locomotive_character_attached(character: CharacterInfo):
	print(character.name + " attached")
	if character.name == "hub1":
		%TextureKimSuperspeed.visible = true

func locomotive_character_detached(character: CharacterInfo):
	print(character.name + " detached")
	if character.name == "hub1":
		%TextureKimSuperspeed.visible = false

func get_target_rotation_degrees() -> float:
	match speed:
		Locomotive.SpeedMode.STOP:
			return -32.0
		Locomotive.SpeedMode.NORMAL:
			return 0.0
		Locomotive.SpeedMode.FAST:
			return 32.0
	return 0.0

func move_to_target_rotation(first_drag: bool = false):
	var degrees := get_target_rotation_degrees()
	if move_tween:
		move_tween.kill()
	move_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	move_tween.tween_property(self, "rotation_degrees", degrees, 0.1)


func _on_mouse_entered() -> void:
	is_mouse_on_top = true
	if not is_dragging and not %LeverDirection.is_dragging and not %WhistleControl.is_dragging:
		eff_mouse_entered()

func _on_mouse_exited() -> void:
	is_mouse_on_top = false
	if not is_dragging:
		eff_mouse_exited()

func eff_mouse_entered():
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	hover_tween.tween_property(%LeverSpeedHead, "position", Vector2(-15.0, -15.0), 0.25)

func eff_mouse_exited():
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	hover_tween.tween_property(%LeverSpeedHead, "position", Vector2.ZERO, 0.25)
