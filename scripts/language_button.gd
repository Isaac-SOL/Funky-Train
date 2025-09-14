class_name LanguageButton extends CenterContainer

signal pressed

var locked = false

func _on_button_pressed() -> void:
	get_viewport().gui_release_focus()
	if not locked:
		pressed.emit()
		locked = true
		%TopContainer.custom_minimum_size.x = 280.0
		var tween := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(%TopContainer, "custom_minimum_size:x", 250.0, 0.5)
		await tween.finished
		locked = false
