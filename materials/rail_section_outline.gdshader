shader_type spatial;
render_mode unshaded;

uniform float extent = 1.0;
uniform vec3 color: source_color = vec3(1.0, 1.0, 1.0);

void vertex() {
	VERTEX = VERTEX + NORMAL * extent;
	
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = color;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
