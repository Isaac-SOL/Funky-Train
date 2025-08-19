
float get_linear_depth(float base_depth, vec2 screen_uv, mat4 inv_proj_matrix) {
	vec3 ndc = vec3(screen_uv * 2.0 - 1.0, (base_depth - 0.5) * 2.0);  // Screen space to NDC (OpenGL)
	vec4 view = inv_proj_matrix * vec4(ndc, 1.0);  // NDC to view space
	return -view.z / view.w;
}