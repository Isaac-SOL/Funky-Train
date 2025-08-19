class_name CharacterMessages extends Control

@export var quick_dialogue_scene: PackedScene

var spawned_dialogues: Array[QuickDialogue] = []
var x_tweens: Array[Tween] = []
var y_tweens: Array[Tween] = []

func spawn_dialogue(info: DialogueInfo):
	if Main.instance.ended:
		return
	for dialogue: QuickDialogue in spawned_dialogues:
		if dialogue.my_info == info:
			return
	var new_dialogue: QuickDialogue = quick_dialogue_scene.instantiate()
	spawned_dialogues.append(new_dialogue)
	x_tweens.append(new_dialogue.create_tween())
	y_tweens.append(null)
	new_dialogue.modulate = Color.TRANSPARENT
	add_child(new_dialogue)
	new_dialogue.spawn(info)
	var y_offset: float = 0.0
	for d: QuickDialogue in spawned_dialogues:
		if d != new_dialogue and not d.killed:
			y_offset += d.size.y + 10.0
	new_dialogue.position = Vector2(-300.0, y_offset)
	new_dialogue.lifetime_ended.connect(remove_dialogue.bind(new_dialogue))
	%AudioStreamPop.play()
	var new_x_tween := x_tweens[x_tweens.size() - 1]
	new_x_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel()
	new_x_tween.tween_method(func(val: float):
			new_dialogue.position.x = val,
		new_dialogue.position.x, 0.0 + 20.0 * info.indentation, 0.5)
	new_x_tween.tween_property(new_dialogue, "modulate", Color.WHITE, 0.5)
	await get_tree().process_frame
	new_dialogue.size = Vector2(300.0 - 20.0 * info.indentation, 10.0)

func remove_dialogue(dialogue: QuickDialogue):
	var idx: int = spawned_dialogues.find(dialogue)
	if x_tweens[idx]:
		x_tweens[idx].kill()
	x_tweens[idx] = dialogue.create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	x_tweens[idx].set_parallel()
	x_tweens[idx].tween_method(func(val: float):
			dialogue.position.x = val,
		dialogue.position.x, -350.0, 1.0)
	x_tweens[idx].tween_property(dialogue, "modulate", Color.TRANSPARENT, 1.0)
	x_tweens[idx].chain().tween_callback(func(): kill_dialogue(dialogue))
	move_all_y()

func move_all_y():
	var y_offset: float = 0.0
	for i in range(spawned_dialogues.size()):
		if spawned_dialogues[i].killed:
			continue
		if y_tweens[i]:
			y_tweens[i].kill()
		y_tweens[i] = spawned_dialogues[i].create_tween()
		y_tweens[i].set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		y_tweens[i].tween_method(func(val: float):
				spawned_dialogues[i].position.y = val,
			spawned_dialogues[i].position.y, y_offset, 0.5)
		y_offset += spawned_dialogues[i].size.y + 10.0

func kill_dialogue(dialogue: QuickDialogue):
	assert(dialogue in spawned_dialogues)
	var idx: int = spawned_dialogues.find(dialogue)
	if x_tweens[idx]:
		x_tweens[idx].kill()
	x_tweens.remove_at(idx)
	if y_tweens[idx]:
		y_tweens[idx].kill()
	y_tweens.remove_at(idx)
	spawned_dialogues.remove_at(idx)
	dialogue.queue_free()
