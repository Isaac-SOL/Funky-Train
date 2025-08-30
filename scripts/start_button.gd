class_name StartButton extends CenterContainer

signal click_open
signal click_confirm

@export var small_size: Vector2
@export var desc_size: Vector2

var opened: bool = false
var moving: bool = false
var text_tween: Tween
var size_tween: Tween

func _ready() -> void:
	%TopContainer.custom_minimum_size = small_size

func kill_movement():
	if text_tween:
		text_tween.kill()
	if size_tween:
		size_tween.kill()

func open():
	print(name + " open")
	moving = true
	opened = true
	kill_movement()
	%Button.disabled = true
	%LabelTitle.visible = false
	%LabelDesc.visible = true
	%LabelDesc.visible_ratio = 0.0
	text_tween = create_tween()
	text_tween.tween_property(%LabelDesc, "visible_ratio", 1.0, 1.0)
	size_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
	size_tween.tween_property(%TopContainer, "custom_minimum_size", desc_size, 0.8)
	size_tween.tween_callback(func():
		moving = false
		%Button.disabled = false
	)

func close():
	print(name + " close")
	moving = true
	opened = false
	kill_movement()
	%Button.disabled = true
	%LabelDesc.visible = false
	%LabelTitle.visible = true
	%LabelTitle.visible_ratio = 0.0
	text_tween = create_tween()
	text_tween.tween_property(%LabelTitle, "visible_ratio", 1.0, 0.4)
	size_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
	size_tween.tween_property(%TopContainer, "custom_minimum_size", small_size, 0.8)
	size_tween.tween_callback(func():
		moving = false
		%Button.disabled = false
	)

func _on_button_pressed() -> void:
	get_viewport().gui_release_focus()
	if not opened:
		if not moving:
			click_open.emit()
	else:
		click_confirm.emit()
