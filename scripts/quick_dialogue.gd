class_name QuickDialogue extends MarginContainer

signal lifetime_ended

@export var characters_per_second: float = 0.0

var my_info: DialogueInfo
var killed: bool = false

func spawn(dialogue_info: DialogueInfo):
	my_info = dialogue_info
	%TextureRect.texture = dialogue_info.character.sprite_cadre
	%Label.visible_ratio = 0.0 if characters_per_second > 0.0 else 1.0
	%Label.text = dialogue_info.text
	if characters_per_second > 0.0:
		display_loop()
	await get_tree().create_timer(dialogue_info.time).timeout
	killed = true
	lifetime_ended.emit()
	#queue_free()

func display_loop():
	var time_to_display = tr(%Label.text).length() / characters_per_second
	var temp_timer := get_tree().create_timer(time_to_display)
	while temp_timer:
		%Label.visible_ratio = 1.0 - (temp_timer.time_left / time_to_display)
		await get_tree().process_frame
	%Label.visible_ratio = 1.0
