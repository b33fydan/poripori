shader_type spatial;
render_mode cull_back, specular_disabled, ambient_light_disabled;

// Solid cubes in the print look: the instance colour (linear) is the ink,
// shaded in three flat tones by each face's angle to the key light, the
// darker two as halftone dots of the paper colour. Alpha 1 prints a cube
// flat and bright (lights, glints). Scene lights add nothing: albedo is 0
// and the colour comes out as emission, so the result is exact.

#include "res://shaders/print.gdshaderinc"

uniform float shadow_mix = 0.6;
// Multiplies the colour: white for MultiMesh cubes (their colour is per
// instance), a model surface's own colour for imported models (MEGAVOX).
uniform vec4 tint = vec4(1.0);
// Plain meshes have no vertex colours (COLOR reads white, so they'd always
// print flat); they set this false and choose with `flat_amount` instead.
uniform bool vertex_flat = true;
uniform float flat_amount = 0.0;
// 0.5 asks the ink pass for black outlines (shaders/ink.gdshader).
uniform float outline_mark = 1.0;

void fragment() {
	vec3 base = COLOR.rgb * tint.rgb;
	vec3 shade = mix(base, shadow.rgb, shadow_mix);
	vec3 c = mix(base, shade, halftone(FRAGCOORD.xy, print_coverage(NORMAL, VIEW_MATRIX)));
	ALBEDO = vec3(0.0);
	EMISSION = mix(c, base, vertex_flat ? COLOR.a : flat_amount);
	ROUGHNESS = outline_mark;
}
