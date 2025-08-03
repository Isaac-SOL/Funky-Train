extends Wagon

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _process(delta: float) -> void:
	super._process(delta)
	animation_player.speed_scale = Global.metronome_speed
