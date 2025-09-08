class_name SpeedLever extends TextureRect

@export var distance_to_switch: float = 150.0

var is_dragging: bool = false
var speed: Locomotive.SpeedMode = Locomotive.SpeedMode.STOP
var drag_pos: Vector2 = Vector2.ZERO

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
			if drag_pos.x >= 50 and drag_pos.y <= -50 and speed < Locomotive.SpeedMode.FAST:
				change_speed(int(speed) + 1 as Locomotive.SpeedMode)
				drag_pos = Vector2.ZERO
			elif drag_pos.x <= -50 and drag_pos.y >= 50 and speed > Locomotive.SpeedMode.STOP:
				change_speed(int(speed) - 1 as Locomotive.SpeedMode)
				drag_pos = Vector2.ZERO

func change_speed(new_speed: Locomotive.SpeedMode):
	speed = new_speed
	rotation_degrees = -32 + 32 * int(speed)
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
