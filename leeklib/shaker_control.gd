@icon("res://leeklib/icons/ShakerControl.svg")
@tool
## [b]Control[/b] that can [member shake]. [br]
## Can also optionally follow a target [b]Control[/b] using framerate-independent lerp smoothing.
class_name ShakerControl extends Control

## [b]Control[/b] to follow. (optional)
@export var target_node: Control
## Whether this node follows the position of the [member target_node].
@export var follow_position: bool = true
## Whether this node follows the local rotation of the [member target_node].
@export var follow_rotation: bool = false
## Whether the position is followed using global space, if there is a [member target_node]. [br]
## For controls, the rotation is always followed in local space.
@export var follow_global_coordinates: bool = false
## Interval, in seconds, between each impulse when shaking.
@export var shake_interval: float = 0.035
## How far the node goes when shaking.
@export var shake_factor: float = 10
## How agressive the shaking is, and how fast this node follows the [member target_node].
## Should be set between 8 and 25 for best results.
@export var move_speed: float = 20
## How fast this node follows the rotation of the [member target_node].
## Should be set between 8 and 25 for best results.
@export var rotation_speed: float = 20
## Instantly moves this node to the [member target_node], following the rules set by
## [member follow_position], [member follow_rotation], and [member follow_global_coordinates].
@export_tool_button("Move to target") var instant_move_button = move_to_target

var shake_tween: Tween
var current_radius: float

@onready var next_shake: float = shake_interval
@onready var base_pos: Vector2 = position
@onready var base_rot: float = rotation
@onready var target_position: Vector2 = position

func _process(delta):
	if Engine.is_editor_hint():
		return
	# Move to target
	if target_node:
		if follow_global_coordinates:
			base_pos = (get_parent() as Node2D).to_local(target_node.global_position)
		else:
			base_pos = target_node.position
	base_rot = target_node.rotation
	
	# Apply impulsions
	next_shake -= delta
	while next_shake < 0:
		target_position = base_pos + Util.rand_on_circle(current_radius * shake_factor)
		next_shake += shake_interval
	
	# Move object
	if follow_position:
		position = Util.decayv2(position, target_position, move_speed * delta)
	if follow_rotation:
		rotation = Util.decayf(rotation, base_rot, rotation_speed * delta)

## Shakes the node by a certain [param amount], moving back to 0 over [param duration] seconds.
func shake(amount: float, duration: float):
	if amount < current_radius: return
	current_radius = amount
	if shake_tween:
		shake_tween.kill()
	shake_tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	shake_tween.tween_property(self, "current_radius", 0, duration).from_current()

## Instantly moves this node to the [member target_node], following the rules set by
## [member follow_position], [member follow_rotation], and [member follow_global_coordinates].
func move_to_target():
	if target_node:
		if follow_global_coordinates:
			base_pos = (get_parent() as Node2D).to_local(target_node.global_position)
		else:
			base_pos = target_node.position
		base_rot = target_node.rotation
		if follow_position:
			position = target_position
		if follow_rotation:
			rotation = base_rot
