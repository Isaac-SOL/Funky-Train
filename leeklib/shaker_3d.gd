@icon("res://leeklib/icons/Shaker3D.svg")
@tool
## [b]Node3D[/b] that can [member shake]. [br]
## Can also optionally follow a target [b]Node3D[/b] using framerate-independent lerp smoothing.
class_name Shaker3D extends Node3D

enum ShakeAxis { FORWARD, UP, RIGHT, ALL }

## [b]Node3D[/b] to follow. (optional)
@export var target_node: Node3D:
	set(new_node):
		target_node = new_node
		update_configuration_warnings()
## Whether this node follows the position of the [member target_node].
@export var follow_position: bool = true
## Whether this node follows the rotation of the [member target_node].
@export var follow_rotation: bool = false
## Whether the position and rotation are followed using global space, if there is a [member target_node].
@export var follow_global_coordinates: bool = false:
	set(new_param):
		follow_global_coordinates = new_param
		update_configuration_warnings()
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
## Which axis, in local space, this node will shake around.
@export var shake_around_axis: ShakeAxis = ShakeAxis.FORWARD
## Instantly moves this node to the [member target_node], following the rules set by
## [member follow_position], [member follow_rotation], and [member follow_global_coordinates].
@export_tool_button("Move to target")var instant_move_button = move_to_target

var shake_tween: Tween
var current_radius: float

@onready var next_shake: float = shake_interval
@onready var base_pos: Vector3 = position
@onready var base_rot: Quaternion = quaternion
@onready var target_position: Vector3 = position

func _ready() -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()

func _process(delta):
	if Engine.is_editor_hint():
		return
	# Move target
	if target_node:
		if follow_global_coordinates:
			base_pos = get_parent_node_3d().to_local(target_node.global_position)
			base_rot = get_parent_node_3d().global_basis.get_rotation_quaternion().inverse() * target_node.global_basis.get_rotation_quaternion()
		else:
			base_pos = target_node.position
			base_rot = target_node.quaternion
	
	# Apply impulsions
	next_shake -= delta
	while next_shake < 0:
		if shake_around_axis == ShakeAxis.ALL:
			target_position = base_pos + Util.rand_on_sphere(current_radius * shake_factor)
		else:
			var rand_pos := Util.rand_on_circle(current_radius * shake_factor)
			match shake_around_axis:
				ShakeAxis.FORWARD:
					target_position = base_pos + basis * Vector3(rand_pos.x, rand_pos.y, 0)
				ShakeAxis.UP:
					target_position = base_pos + basis * Vector3(rand_pos.x, 0, rand_pos.y)
				ShakeAxis.RIGHT:
					target_position = base_pos + basis * Vector3(0, rand_pos.x, rand_pos.y)
		next_shake += shake_interval
	
	# Move object
	if follow_position:
		position = Util.decayv3(position, target_position, move_speed * delta)
	if follow_rotation:
		quaternion = Util.decayq_closest(quaternion, base_rot, rotation_speed * delta)

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
			base_pos = get_parent_node_3d().to_local(target_node.global_position)
			base_rot = get_parent_node_3d().global_basis.get_rotation_quaternion().inverse() * target_node.global_basis.get_rotation_quaternion()
		else:
			base_pos = target_node.position
			base_rot = target_node.quaternion
		if follow_position:
			position = base_pos
		if follow_rotation:
			quaternion = base_rot

func _get_configuration_warnings() -> PackedStringArray:
	update_configuration_warnings()
	if target_node and follow_global_coordinates:
		if get_parent_node_3d() == null:
			return ["No parent Node3D found, cannot follow global coordinates."]
	return []
