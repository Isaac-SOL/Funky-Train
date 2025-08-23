
float get_linear_depth(float base_depth, vec2 screen_uv, mat4 inv_proj_matrix) {
	vec3 ndc = vec3(screen_uv * 2.0 - 1.0, (base_depth - 0.5) * 2.0);  // Screen space to NDC (OpenGL)
	vec4 view = inv_proj_matrix * vec4(ndc, 1.0);  // NDC to view space
	return -view.z / view.w;
}

float inv_mix(float a, float b, float value) {
	return (value - a) / (b - a);
}

vec2 inv_mix(float a, float b, vec2 value) {
	return (value - a) / (b - a);
}

vec3 inv_mix(float a, float b, vec3 value) {
	return (value - a) / (b - a);
}

vec4 inv_mix(float a, float b, vec4 value) {
	return (value - a) / (b - a);
}

float inv_mix_clamped(float a, float b, float value) {
	return clamp(inv_mix(a, b, value), 0, 1);
}

vec2 inv_mix_clamped(float a, float b, vec2 value) {
	return clamp(inv_mix(a, b, value), vec2(0), vec2(1));
}

vec3 inv_mix_clamped(float a, float b, vec3 value) {
	return clamp(inv_mix(a, b, value), vec3(0), vec3(1));
}

vec4 inv_mix_clamped(float a, float b, vec4 value) {
	return clamp(inv_mix(a, b, value), vec4(0), vec4(1));
}
