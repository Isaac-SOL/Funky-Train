shader_type spatial;

render_mode depth_test_disabled;

uniform sampler2D screen_depth: hint_depth_texture;

uniform vec3 albedo: source_color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	if (FRAGCOORD.z < texture(screen_depth, SCREEN_UV).r) {
		discard;
	}
	ALBEDO = albedo;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
