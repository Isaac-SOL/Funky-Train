class_name DialogicTrigger extends Area3D

signal dialogue_triggered(dialogue_info: DialogueInfo)

@export var trigger_once: bool = false
@export var requirements: Array[String]
@export var dialogues: Array[DialogueInfo]

var triggered: bool = false

func _on_area_entered(area: Area3D) -> void:
	if area.get_parent() and area.get_parent() == Locomotive.instance:
		if Locomotive.instance.check_requirements(requirements):
			if trigger_once and triggered:
				return
			triggered = true
			for d: DialogueInfo in dialogues:
				Main.instance.spawn_dialogue(d)
				dialogue_triggered.emit(d)
				await get_tree().create_timer(2.0).timeout
