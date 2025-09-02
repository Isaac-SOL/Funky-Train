shader_type spatial;
render_mode unshaded, depth_draw_never, skip_vertex_transform;

#include "res://leeklib/shader_util.gdshaderinc"

// Based on https://www.youtube.com/watch?v=bCGq1_gnnIk

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D DEPTH_TEXTURE: hint_depth_texture, repeat_disable, filter_nearest;
uniform float sobel_max: hint_range(0.0, 1.0);
uniform float sobel_max_depth;
uniform float sobel_min: hint_range(0.0, 1.0);
uniform float sobel_min_depth;
uniform float sobel_threshold: hint_range(0.0, 10.0);
uniform vec3 depth_gradient_color: source_color;
uniform float depth_gradient_start;
uniform float depth_gradient_end;
uniform float depth_gradient_strength: hint_range(0.0, 1.0);
uniform bool stick_to_camera = false;

void vertex() {
	if (stick_to_camera) {
		VERTEX.z = -0.1;
	} else {
		VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
		NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
		BINORMAL = normalize((MODELVIEW_MATRIX * vec4(BINORMAL, 0.0)).xyz);
		TANGENT = normalize((MODELVIEW_MATRIX * vec4(TANGENT, 0.0)).xyz);
	}
}

void fragment() {
	vec2 pixel_size = 1.0 / VIEWPORT_SIZE;

	// ==== COLOR SOBEL =====

	vec3 pixels[9];
	for (int i = 0; i < 3; i++) {
		for (int j = 0; j < 3; j++) {
			vec2 uv = SCREEN_UV + vec2(float(j - 1), float(i - 1)) * pixel_size;
			pixels[i * 3 + j] = texture(SCREEN_TEXTURE, uv).rgb;
		}
	}

	// Sobel
	// [0, 1, 2]
	// [3, 4, 5]
	// [6, 7, 8]
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
	if (sobel_scalar < sobel_threshold) sobel_scalar = 0.0;

	// === DEPTH GRADIENT ===

	vec3 world_pos = get_world_pos(texture(DEPTH_TEXTURE, SCREEN_UV).r, SCREEN_UV, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX);
	float lin_depth = length(CAMERA_POSITION_WORLD - world_pos);
	//float lin_depth = get_linear_depth(texture(DEPTH_TEXTURE, SCREEN_UV).r, SCREEN_UV, INV_PROJECTION_MATRIX);
	float norm_depth = (lin_depth - depth_gradient_start) / (depth_gradient_end - depth_gradient_start);
	norm_depth = clamp(norm_depth, 0.0, 1.0);
	norm_depth *= depth_gradient_strength;
	bool pure_black = pixels[0].r == 0.0 && pixels[0].g == 0.0 && pixels[0].b == 0.0;
	if (lin_depth > 250.0 || pure_black) {
		norm_depth = 0.0;
	}

	// === IMAGE COMPOSITION ===

	float norm_depth_sobel = (lin_depth - sobel_max_depth) / (sobel_min_depth - sobel_max_depth);
	norm_depth_sobel = clamp(norm_depth_sobel, 0.0, 1.0);
	if (lin_depth <= 250.0) {
		sobel_scalar *= mix(sobel_max, sobel_min, norm_depth_sobel);
	}
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
