shader_type spatial;

render_mode depth_prepass_alpha;

uniform sampler2D color;
uniform vec2 uv_scale = vec2(20.0, 20.0);
uniform vec2 waves_direction = vec2(1.0, 0.0);
uniform float time_scale = 1.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 uv_pos = UV * uv_scale;
	vec2 uv_offset = waves_direction * sin(TIME * time_scale + uv_pos * waves_direction);
	uv_offset /= uv_scale;
	uv_pos += uv_offset;
	ALBEDO = texture(color, uv_pos).rgb;
}

void light() {
	DIFFUSE_LIGHT = ALBEDO * ATTENUATION;
	SPECULAR_LIGHT = vec3(0.0, 0.0, 0.0);
	ALPHA = 1.0;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
