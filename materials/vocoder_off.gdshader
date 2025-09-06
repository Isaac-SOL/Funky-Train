shader_type spatial;

uniform vec3 color_1: source_color = vec3(0.0, 0.0, 0.0);
uniform vec3 color_2: source_color = vec3(1.0, 0.0, 0.0);
uniform float period = 1.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float sin_time = sin(TIME * PI / period);
	sin_time = (sin_time + 1.0) / 2.0;
	ALBEDO = mix(color_1, color_2, sin_time);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
