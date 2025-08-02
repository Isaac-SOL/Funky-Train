shader_type spatial;
render_mode unshaded;

// Based on https://www.youtube.com/watch?v=bCGq1_gnnIk

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D DEPTH_TEXTURE: hint_depth_texture, repeat_disable, filter_nearest;
uniform float sobel_max: hint_range(0.0, 1.0);
uniform float sobel_max_depth;
uniform float sobel_min: hint_range(0.0, 1.0);
uniform float sobel_min_depth;
uniform vec3 depth_gradient_color: source_color;
uniform float depth_gradient_start;
uniform float depth_gradient_end;
uniform float depth_gradient_strength: hint_range(0.0, 1.0);

float get_linear_depth(float base_depth, vec2 screen_uv, mat4 inv_proj_matrix) {
	vec3 ndc = vec3(screen_uv * 2.0 - 1.0, (base_depth - 0.5) * 2.0);  // Screen space to NDC (OpenGL)
	vec4 view = inv_proj_matrix * vec4(ndc, 1.0);  // NDC to view space
	return -view.z / view.w;
}

void fragment() {
	vec2 pixel_size = 1.0 / VIEWPORT_SIZE;

	// ==== COLOR SOBEL =====

	vec3 pixels[9];
	// [0, 1, 2]
	// [3, 4, 5]
	// [6, 7, 8]
	for (int i = 0; i < 3; i++) {
		for (int j = 0; j < 3; j++) {
			vec2 uv = SCREEN_UV + vec2(float(j - 1), float(i - 1)) * pixel_size;
			pixels[i * 3 + j] = texture(SCREEN_TEXTURE, uv).rgb;
		}
	}

	// Sobel
	vec3 gx = (
		-pixels[0] + -2.0 * pixels[3] - pixels[6]
		+ pixels[2] + 2.0 * pixels[5] + pixels[8]
	);
	vec3 gy = (
		-pixels[0] + -2.0 * pixels[1] - pixels[2]
		+ pixels[6] + 2.0 * pixels[7] + pixels[8]
	);
	vec3 sobel = sqrt(gx * gx + gy * gy);

	// Shift to black & white
	float sobel_scalar = sobel.r + sobel.g + sobel.b;

	// === DEPTH GRADIENT ===

	float lin_depth = get_linear_depth(texture(DEPTH_TEXTURE, SCREEN_UV).r, SCREEN_UV, INV_PROJECTION_MATRIX);
	float norm_depth = (lin_depth - depth_gradient_start) / (depth_gradient_end - depth_gradient_start);
	norm_depth = clamp(norm_depth, 0.0, 1.0);
	norm_depth *= depth_gradient_strength;

	// === IMAGE COMPOSITION ===

	float norm_depth_sobel = (lin_depth - sobel_max_depth) / (sobel_min_depth - sobel_max_depth);
	norm_depth_sobel = clamp(norm_depth_sobel, 0.0, 1.0);
	sobel_scalar *= mix(sobel_max, sobel_min, norm_depth_sobel);
	sobel_scalar = 1.0 - sobel_scalar;
	sobel_scalar = clamp(sobel_scalar, 0.0, 1.0);

	vec3 final_color = pixels[4];
	final_color = mix(final_color, depth_gradient_color, norm_depth);
	final_color *= sobel_scalar;

	ALBEDO = final_color;
	ALPHA = 1.0;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
