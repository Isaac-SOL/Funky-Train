shader_type spatial;

uniform float frequency = 1.0;
uniform vec3 color_1: source_color = vec3(1.0, 1.0, 0.0);
uniform vec3 color_2: source_color = vec3(0.0, 0.0, 0.0);

void fragment() {
	vec3 model_vertex = (inverse(MODEL_MATRIX) * INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float sum = model_vertex.x + model_vertex.y + model_vertex.z;
	if (fract(sum * frequency) > 0.5) {
		ALBEDO = color_1;
	} else {
		ALBEDO = color_2;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
