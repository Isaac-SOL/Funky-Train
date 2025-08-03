class_name QuickDialogue extends MarginContainer

var my_info: DialogueInfo

func spawn(dialogue_info: DialogueInfo):
	my_info = dialogue_info
	%TextureRect.texture = dialogue_info.character.sprite_cadre
	%Label.text = dialogue_info.text
	await get_tree().create_timer(dialogue_info.time).timeout
	queue_free()
