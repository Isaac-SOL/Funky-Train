@tool
class_name InterruptorBarrier extends Node3D

enum BarrierPreviewMode { NONE, LEFT, RIGHT }

@export_range(-180.0, 180.0) var degrees_left: float
@export_range(-180.0, 180.0) var degrees_right: float
@export_category("Editor actions")
@export var barrier_preview: BarrierPreviewMode

var current_y: float
var y_tween: Tween
var top: Vector3:
	get():
		return %Top.global_position

func _ready() -> void:
	%BarrierPivot.rotation_degrees.y = degrees_left
	current_y = degrees_left

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		match barrier_preview:
			BarrierPreviewMode.LEFT:
				%BarrierPivot.rotation_degrees.y = degrees_left
			BarrierPreviewMode.RIGHT:
				%BarrierPivot.rotation_degrees.y = degrees_right
	else:
		%BarrierPivot.rotation_degrees.y = current_y

func switch(right: bool, hidden: bool = false):
	# Reversed: we go towards the blocked path
	var y_target := degrees_left if right else degrees_right
	if y_tween:
		y_tween.kill()
	y_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
	y_tween.tween_property(self, "current_y", y_target, 0.5)
	
	if hidden:
		return
	
	var circle_tween := create_tween()
	for i: int in range(4):
		for b: bool in [true, false]:
			circle_tween.tween_callback(func(): %MinimapCircle.visible = b)
			circle_tween.tween_interval(0.3)
