class_name FruitInteractible extends GenericInteractible

var fully_grown: bool = true

func _ready() -> void:
	super._ready()
	await get_tree().process_frame
	Main.instance.rhythm_sync.beat.connect(func(_b):
		if fully_grown:
			%FruitRoot.scale = Vector3(1.2, 1.2, 1.2)
			var tween := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
			tween.tween_property(%FruitRoot, "scale", Vector3.ONE, 0.5)
	)

func interact():
	fully_grown = false
	%AudioCroc.play()
	var tween := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(%FruitRoot, "scale", Vector3.ZERO, 0.6)
	tween.tween_interval(3.4)
	tween.tween_property(%FruitRoot, "scale", Vector3.ONE, 1.5)
	tween.tween_callback(func(): fully_grown = true)


func _on_collision_area_entered(area: Area3D) -> void:
	%AudioBonk.play()
	var bonk_tween := create_tween()
	bonk_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	bonk_tween.tween_property(%Branche, "rotation_degrees:x", -15.0, 0.05)
	bonk_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	bonk_tween.tween_property(%Branche, "rotation_degrees:x", 13.1, 1.0)
