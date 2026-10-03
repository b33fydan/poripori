shader_type spatial;
render_mode cull_back, specular_disabled, ambient_light_disabled;

// The monolith's cubes: the print look (see print.gdshader), plus a thin
// rim of light round every face of a lit cube, in the colour of the global
// monolith_edge (rgb, linear; a is its strength). The whole monolith's rims
// change colour together, on the beat. INSTANCE_CUSTOM.r is how lit the cube
// is (0 to 1).
//
// Lit cubes also mark the normal-roughness buffer (roughness 0.2, which
// nothing else uses) so the ink pass draws their outlines in the same colour.

#include "res://shaders/print.gdshaderinc"

uniform float shadow_mix = 0.6;
uniform float rim_width = 0.09;  // of the half-width of the cube

varying vec3 local;
varying float lit;

void vertex() {
	local = VERTEX;
	lit = INSTANCE_CUSTOM.r;
}

void fragment() {
	vec3 base = COLOR.rgb;
	vec3 shade = mix(base, shadow.rgb, shadow_mix);
	vec3 c = mix(base, shade, halftone(FRAGCOORD.xy, print_coverage(NORMAL, VIEW_MATRIX)));
	c = mix(c, base, COLOR.a);
	// On a face, one of |local| is the half-width; the larger of the other
	// two says how near the face's edge this point is.
	vec3 a = abs(local) / max(max(abs(local.x), abs(local.y)), abs(local.z));
	float near_edge = a.x + a.y + a.z - 1.0 - min(min(a.x, a.y), a.z);
	float w = fwidth(near_edge) * 0.75;
	float rim = smoothstep(1.0 - rim_width - w, 1.0 - rim_width + w, near_edge);
	float glow = rim * lit * monolith_edge.a;
	ALBEDO = vec3(0.0);
	EMISSION = mix(c, monolith_edge.rgb, clamp(glow, 0.0, 1.0));
	ROUGHNESS = lit > 0.5 && monolith_edge.a > 0.0 ? 0.2 : 1.0;
}
