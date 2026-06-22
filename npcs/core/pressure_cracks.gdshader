shader_type spatial;

uniform sampler2D noise;


void vertex() {

}

void fragment() {
	ALBEDO = texture(noise, SCREEN_UV).rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
