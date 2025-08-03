class_name DialogicTrigger extends Area3D

@export var requirements: Array[String]
@export var dialogues: Array[DialogueInfo]

func _on_area_entered(area: Area3D) -> void:
	print("test")
	if area.get_parent() and area.get_parent() == Locomotive.instance:
		if Locomotive.instance.check_requirements(requirements):
			for d: DialogueInfo in dialogues:
				Main.instance.spawn_dialogue(d)
				await get_tree().create_timer(2.0).timeout
