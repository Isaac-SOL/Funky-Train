class_name DialogInteractible extends GenericInteractible

signal dialogue_triggered(dialogue_info: DialogueInfo)

@export var trigger_once: bool = false
@export var requirements: Array[String]
@export var dialogues: Array[DialogueInfo]

var triggered: bool = false
var triggerable: bool = true

func interact():
	if Locomotive.instance.bypass:
		return
	if triggerable and Locomotive.instance.check_requirements(requirements):
		if trigger_once and triggered:
			return
		triggered = true
		for d: DialogueInfo in dialogues:
			Main.instance.spawn_dialogue(d)
			dialogue_triggered.emit(d)
			await get_tree().create_timer(2.0).timeout

func deactivate():
	triggerable = false
