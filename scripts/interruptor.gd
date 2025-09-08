class_name Interruptor extends PathFollow3D

signal pressed
signal fixed

@export var rail_to_toggle: RailSection
@export var broken: bool = false
@export var material_normal: Material
@export var material_broken: Material

func _ready() -> void:
	get_section().add_interactible(self)
	await get_tree().process_frame
	assert(rail_to_toggle.is_toggled)
	if rail_to_toggle.toggle_barrier:
		%DirectionIndicator.look_at(rail_to_toggle.toggle_barrier.global_position)
	if broken:
		%Button.set_surface_override_material(0, material_broken)
		%BrokenParticles.emitting = true
	else:
		%BrokenParticles.queue_free()

func get_section() -> RailSection:
	return get_parent()

func fix():
	broken = false
	%Button.set_surface_override_material(0, material_normal)
	%BrokenParticles.emitting = false
	%AudioBzzt.play()
	fixed.emit()
	await %BrokenParticles.finished
	%BrokenParticles.queue_free()

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
	signal_animation()
	
	pressed.emit()

func signal_animation():
	if not rail_to_toggle.toggle_barrier:
		return
	%Signal.position = Vector3.ZERO
	%Signal.visible = true
	var tween_pos := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_pos.tween_property(%Signal, "global_position", rail_to_toggle.toggle_barrier.global_position, 1.0)
	tween_pos.tween_callback(func(): %Signal.visible = false)
	var tween_height := create_tween().set_trans(Tween.TRANS_QUAD)
	tween_height.tween_property(%Signal, "global_position:y", global_position.y + 5.0, 0.5).set_ease(Tween.EASE_IN_OUT)
	tween_height.tween_property(%Signal, "global_position:y", rail_to_toggle.toggle_barrier.top.y, 0.5).set_ease(Tween.EASE_IN)
