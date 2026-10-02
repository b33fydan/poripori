shader_type spatial;
render_mode cull_back, specular_disabled, ambient_light_disabled;

// Solid cubes in the print look: the instance colour (linear) is the ink,
// shaded in three flat tones by each face's angle to the key light, the
// darker two as halftone dots of the paper colour. Alpha 1 prints a cube
// flat and bright (lights, glints). Scene lights add nothing: albedo is 0
// and the colour comes out as emission, so the result is exact.

#include "res://shaders/print.gdshaderinc"

uniform float shadow_mix = 0.6;

void fragment() {
	vec3 base = COLOR.rgb;
	vec3 shade = mix(base, paper.rgb, shadow_mix);
	vec3 c = mix(base, shade, halftone(FRAGCOORD.xy, print_coverage(NORMAL, VIEW_MATRIX)));
	ALBEDO = vec3(0.0);
	EMISSION = mix(c, base, COLOR.a);
	ROUGHNESS = 1.0;
}
