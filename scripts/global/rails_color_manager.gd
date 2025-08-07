extends Node

@onready var rails_gradient_texture: GradientTexture1D = load("res://materials/rails_gradient.tres")
@onready var rails_outline_material: ShaderMaterial = load("res://materials/rail_section_outline.tres")
var rails_gradient: Gradient

var previous_gradient: Array[Color]
var next_gradient: Array[Color]
var gradient_tween: Tween
var last_carriages: Array[Carriage] = []

func _ready() -> void:
	rails_gradient = rails_gradient_texture.gradient
	previous_gradient = [
		Color.from_hsv(1.0, 0.0, 0.75), Color.from_hsv(1.0, 0.0, 0.65),
		Color.from_hsv(1.0, 0.0, 0.55), Color.from_hsv(1.0, 0.0, 0.45),
		Color.from_hsv(1.0, 0.0, 0.35)
	]
	next_gradient = previous_gradient.duplicate()
	for i in range(5):
		rails_gradient.set_color(i, previous_gradient[i])
	await get_tree().process_frame
	Main.instance.rhythm_sync.beats(4).connect(_on_measure)

# Félicitations btw
func start_transition(new_gradient: Array[Color]):
	if gradient_tween:
		gradient_tween.kill()
	previous_gradient = get_current_gradient()
	next_gradient = new_gradient
	gradient_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	gradient_tween.set_parallel()
	tween_gradient(gradient_tween, 0).set_delay(0.3)
	tween_gradient(gradient_tween, 1).set_delay(0.15)
	tween_gradient(gradient_tween, 2)
	tween_gradient(gradient_tween, 3).set_delay(0.15)
	tween_gradient(gradient_tween, 4).set_delay(0.3)

func get_current_gradient() -> Array[Color]:
	var res: Array[Color] = []
	for i in range(5):
		res.append(rails_gradient.get_color(i))
	return res

func tween_gradient(tween: Tween, pos: int) -> MethodTweener:
	return tween.tween_method(set_gradient_color.bind(pos), previous_gradient[pos], next_gradient[pos], 0.2)

func set_gradient_color(color: Color, pos: int):
	rails_gradient.set_color(pos, color)

func update_gradient():
	start_transition(get_gradient())

func lerp_hsv(col1: Color, col2: Color, t: float):
	var v1 := Vector3(col1.h, col1.s, col1.v)
	var v2 := Vector3(col2.h, col2.s, col2.v)
	if v1.x > v2.x:
		if (v2.x + 1.0) - v1.x < v1.x - v2.x:
			v2.x += 1.0
	else:
		if (v1.x + 1.0) - v2.x < v2.x - v1.x:
			v1.x += 1.0
	var vt: Vector3 = lerp(v1, v2, t)
	if vt.x > 1.0:
		vt.x -= 1.0
	return Color.from_hsv(vt.x, vt.y, vt.z)

func lerp_okhsl(col1: Color, col2: Color, t: float):
	var v1 := Vector3(col1.ok_hsl_h, col1.ok_hsl_s, col1.ok_hsl_l)
	var v2 := Vector3(col2.ok_hsl_h, col2.ok_hsl_s, col2.ok_hsl_l)
	var vt: Vector3 = lerp(v1, v2, t)
	return Color.from_ok_hsl(vt.x, vt.y, vt.z)

func same_as_last_carriages(new_carrianges: Array[Carriage]) -> bool:
	if last_carriages.size() != new_carrianges.size():
		return false
	for i in range(last_carriages.size()):
		if last_carriages[i] != new_carrianges[i]:
			return false
	return true

func get_gradient() -> Array[Color]:
	var carriages: Array[Carriage] = Locomotive.instance.carriages.duplicate()
	if carriages.size() > 0:
		rails_outline_material.set_shader_parameter("color", carriages[0].character.color)
		carriages.remove_at(0)
	else:
		rails_outline_material.set_shader_parameter("color", Color.WHITE)
	if carriages.size() > 3:
		# Avoid color repetition
		var prev_picked: Array[Carriage] = []
		for i in range(3):
			var prev_idx: int = carriages.find(last_carriages[i])
			if prev_idx != -1:
				prev_picked.append(last_carriages[i])
				carriages.remove_at(prev_idx)
		prev_picked.shuffle()
		carriages.shuffle()
		carriages += prev_picked
	var res: Array[Color] = []
	if carriages.size() == 0:
		var col := Color.from_hsv(1.0, 0.0, 0.75)
		for i in range(5):
			res.append(col)
			col.v -= 0.1
	elif carriages.size() == 1:
		var col := carriages[0].character.color
		for i in range(5):
			res.append(col)
			col.v -= 0.1
	elif carriages.size() == 2:
		var col1 := carriages[0].character.color
		var col2 := carriages[1].character.color
		for i in range(5):
			res.append(lerp_hsv(col1, col2, i / 4.0))
	elif carriages.size() >= 3:
		var col1 := carriages[0].character.color
		var col2 := carriages[1].character.color
		var col3 := carriages[2].character.color
		var col12 = lerp_hsv(col1, col2, 0.5)
		var col23 = lerp_hsv(col2, col3, 0.5)
		res.append_array([col1, col12, col2, col23, col3])
	last_carriages = carriages
	return res

func _on_measure(_interval: int):
	if Locomotive.instance.carriages.size() > 3:
		update_gradient()
