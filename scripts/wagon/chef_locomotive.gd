extends Wagon

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	super._ready()
	await get_tree().process_frame
	animation_player.speed_scale = Global.metronome_speed
