class_name Interruptor extends PathFollow3D

signal pressed

@export var rail_to_toggle: RailSection

func _ready() -> void:
	get_section().add_interruptor(self)
	await get_tree().process_frame
	assert(rail_to_toggle.is_toggled)
	if rail_to_toggle.toggle_barrier:
		%DirectionIndicator.look_at(rail_to_toggle.toggle_barrier.global_position)

func get_section() -> RailSection:
	return get_parent()

func press():
	rail_to_toggle.toggle()
	%AudioPressed.play()
	
	%PressSprite.scale = Vector3(2.0, 2.0, 2.0)
	%PressSprite.modulate = Color.WHITE
	%PressSprite.visible = true
	var tween := create_tween().set_parallel()
	tween.tween_property(%PressSprite, "modulate", Color.TRANSPARENT, 1.0)
	var scale_tweener := tween.tween_property(%PressSprite, "scale", Vector3(3.0, 3.0, 3.0), 1.0)
	scale_tweener.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.chain().tween_callback(func(): %PressSprite.visible = false)
	
	pressed.emit()
