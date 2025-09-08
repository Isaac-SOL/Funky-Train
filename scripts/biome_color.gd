class_name BiomeColor extends Resource

@export var sun_color: Color = Color.WHITE
@export_range(0.0, 16.0) var sun_energy: float = 0.5
@export var depth_gradient_color: Color = Color.WHITE
@export_range(0.0, 1.0) var depth_gradient_strength: float = 0.55
@export_range(0.0, 1.0) var deep_depth_gradient_strength: float = 0.0
@export var sky_top_color: Color = Color.WHITE
@export var sky_bottom_color: Color = Color.WHITE
@export var sun_sprite_modulate: Color = Color.WHITE
