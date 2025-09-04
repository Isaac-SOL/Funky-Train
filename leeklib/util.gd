## Miscellaneous useful functions for various common game-related mechanics.
class_name Util

## Framerate-independent lerp smoothing. [br]
## [param d] Should be a value between 8 and 25
## multiplied by the frame [code]delta[/code] for best results.
static func decay(a, b, d: float):
	return b + (a - b) * exp(-d)

## Framerate-independent lerp smoothing for [b]float[/b]s. [br]
## [param d] Should be a value between 8 and 25
## multiplied by the frame [code]delta[/code] for best results.
static func decayf(a: float, b: float, d: float) -> float:
	return b + (a - b) * exp(-d)

## Framerate-independent lerp smoothing for [b]Vector2[/b]s. [br]
## [param d] Should be a value between 8 and 25
## multiplied by the frame [code]delta[/code] for best results.
static func decayv2(a: Vector2, b: Vector2, d: float) -> Vector2:
	return b + (a - b) * exp(-d)

## Framerate-independent lerp smoothing for [b]Vector3[/b]s. [br]
## [param d] Should be a value between 8 and 25
## multiplied by the frame [code]delta[/code] for best results.
static func decayv3(a: Vector3, b: Vector3, d: float) -> Vector3:
	return b + (a - b) * exp(-d)

## Framerate-independent lerp smoothing for [b]Quaternion[/b]s. [br]
## [param d] Should be a value between 8 and 25
## multiplied by the frame [code]delta[/code] for best results. [br]
## Note that if one of the parameters is a member of a running [b]Node3D[/b],
## the quaternion's sign may flip at any point, causing the rotation to go in the wrong direction.
## If this happens, use [member decayq_closest] instead.
static func decayq(a: Quaternion, b: Quaternion, d: float) -> Quaternion:
	return b + (a - b) * exp(-d)

## Framerate-independent lerp smoothing for [b]Quaternion[/b]s. [br]
## [param d] Should be a value between 8 and 25
## multiplied by the frame [code]delta[/code] for best results. [br]
## This function is useful if [param b] comes from a running [b]Node3D[/b].
## If you are managing the quaternions yourself, use [member decayq] instead.
static func decayq_closest(a: Quaternion, b: Quaternion, d: float) -> Quaternion:
	var res1 := b + (a - b) * exp(-d)
	var res2 := -b + (a + b) * exp(-d)
	if ((b - res1).length_squared() > (-b - res2).length_squared()):
		return res2
	return res1

## Normalizes a 2D angle in an interval of length [code]2 * PI[/code], or [code]TAU[/code].[br]
## If [param custom_center] is left as default, that interval will be [code][-PI; PI][/code].
## Otherwise, it will be [code][custom_center - PI; custom_center + PI][/code].
static func clamp_angle(angle: float, custom_center: float = 0) -> float:
	angle -= custom_center
	if angle > PI:
		angle = fmod(angle + PI, TAU) - PI
	elif angle < -PI:
		angle = fmod(angle - PI, TAU) + PI
	return angle + custom_center

## Returns a random point on the circle of a given [param radius].
## The distribution is uniform.
static func rand_on_circle(radius: float = 1) -> Vector2:
	var angle: float = randf_range(0, TAU)
	return Vector2(sin(angle), cos(angle)) * radius

## Returns a random point between the circles of the given [param min_radius] and [param max_radius].[br]
## Note that the distribution is not uniform (clumped closer to [code](0,0)[/code]).
## If you want an uniform distribution, use [member rand_in_circle_uniform] instead.
static func rand_in_circle(min_radius: float = 0, max_radius: float = 1) -> Vector2:
	var r: float = randf_range(min_radius, max_radius)
	return rand_on_circle(r)

## Returns a random point between the circles of the given [param min_radius] and [param max_radius].[br]
## Guaranteed to be uniform, but uses random shots, which gets more expensive on average
## when [param min_radius] and [param max_radius] are close.
## In that case, it is advised to use [member rand_in_circle] instead.
static func rand_in_circle_uniform(min_radius: float = 0, max_radius: float = 1) -> Vector2:
	var res := Vector2.ONE * max_radius * 2
	while res.length() > max_radius or min_radius > res.length():
		res = Vector2(randf_range(-1, 1), randf_range(-1, 1))
	return res

## Returns a random point on the sphere of a given [param radius].
## The distribution is uniform.
static func rand_on_sphere(radius: float = 1) -> Vector3:
	var res := Vector3(randfn(0, 1), randfn(0, 1), randfn(0, 1))
	if res == Vector3.ZERO:
		return Vector3.UP
	return res.normalized() * radius

## Returns a random point between the spheres of the given [param min_radius] and [param max_radius].[br]
## Note that the distribution is not uniform (clumped closer to [code](0,0,0)[/code]).
## If you want an uniform distribution, use [member rand_in_sphere_uniform] instead.
static func rand_in_sphere(min_radius: float = 0, max_radius: float = 1) -> Vector3:
	var r := randf_range(min_radius, max_radius)
	return rand_on_sphere(r)

## Returns a random point between the spheres of the given [param min_radius] and [param max_radius].[br]
## Guaranteed to be uniform, but uses random shots, which gets more expensive on average
## when [param min_radius] and [param max_radius] are close.
## In that case, it is advised to use [member rand_in_sphere] instead.
static func rand_in_sphere_uniform(min_radius: float = 0, max_radius: float = 1) -> Vector3:
	var res := Vector3.ONE * max_radius * 2
	while res.length() > max_radius or min_radius > res.length():
		res = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
	return res

## Slows down the [code]Engine.time_scale[/code] for [param secs] seconds.
## A [param source] node must be provided to access the scene tree. [br]
## Afterwards, restores the previous [code]time_scale[/code]. Note that this may
## not work properly if multiple objects are tampering with the [code]time_scale[/code] simultaneously.
static func hitstop(source: Node, secs: float, factor: float = 0.1):
	var prev_scale := Engine.time_scale
	Engine.time_scale = factor
	await source.get_tree().create_timer(secs, true, false, true).timeout
	if Engine.time_scale == factor:
		Engine.time_scale = prev_scale

## Gets the size of the viewport relative to the default settings of the project. [br]
## A [param source] node must be provided to access the scene tree. [br]
## Useful when the [code]stretch_mode[/code] is [code]canvas_items[/code],
## As some values may need to be converted if the window has been resized.
static func current_viewport_factor(source: Node) -> Vector2:
	var viewport := source.get_viewport() as Window
	if viewport:
		var base_size := viewport.get_visible_rect().size
		var curr_size := Vector2(viewport.size)
		return curr_size / base_size
	return Vector2.ONE

## Checks if the game is running on a mobile device, including if it is running in a mobile browser.
static func on_mobile() -> bool:
	return OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("android") or OS.has_feature("ios")

## Checks if the game is running in a browser.
static func on_web() -> bool:
	return OS.has_feature("web")
