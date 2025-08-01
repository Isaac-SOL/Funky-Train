extends Wagon

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _process(delta: float) -> void:
	animation_player.speed_scale = Global.metronome_speed
