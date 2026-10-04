shader_type spatial;
render_mode cull_back, specular_disabled, ambient_light_disabled;

// The monolith's cubes, and the B-roll's: the print look (see
// print.gdshader), plus a thin rim round every face.
// INSTANCE_CUSTOM.r is how much rim a cube has (0 to 1, its "lit" amount).
// INSTANCE_CUSTOM.g picks its kind:
//   0 a steady white border;
//   1 a yellow pulse, shared by every such cube through the global
//     monolith_edge (rgb, linear; a is its strength), so they flare together
//     on the beat; where the global monolith_pattern is on, a pattern of
//     black runs through them like strings of Christmas lights;
//   2 a steady black border.
// INSTANCE_CUSTOM.b and .a are the cube's row and column in the message,
// divided by 100, for the pattern.
//
// The rims' kind is marked in the normal-roughness buffer so the ink pass
// draws outlines to match: roughness 0.2 for the yellow, 0.5 for black.

#include "res://shaders/print.gdshaderinc"

// x: which pattern (0 a diagonal sweep, 1 bands falling down the rows,
// 2 twinkling, 3 rings rippling out from the middle); y: its phase, in
// beats; w: 1 when the pattern runs.
global uniform vec4 monolith_pattern;

uniform float shadow_mix = 0.6;
uniform float rim_width = 0.09;  // of the half-width of the cube
uniform vec3 border = vec3(0.9, 0.92, 1.0);  // the steady white border (linear)
uniform float border_strength = 0.85;

varying vec3 local;
varying float lit;
varying float kind;
varying vec2 cell;

void vertex() {
	local = VERTEX;
	lit = INSTANCE_CUSTOM.r;
	kind = INSTANCE_CUSTOM.g;
	cell = INSTANCE_CUSTOM.ba * 100.0;
}

float twinkle_hash(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

// Is this cube dark in the lights' pattern right now? (row, column)
bool in_pattern(vec2 rc) {
	float row = rc.x;
	float column = rc.y;
	float phase = monolith_pattern.y;
	int which = int(monolith_pattern.x + 0.5);
	if (which == 0) {
		return fract((column + row) / 9.0 - phase * 0.5) < 0.28;
	} else if (which == 1) {
		return fract(row / 6.0 - phase * 0.5) < 0.3;
	} else if (which == 2) {
		return twinkle_hash(vec3(row, column, floor(phase * 2.0))) < 0.3;
	}
	return fract(length(vec2(column - 11.0, (row - 36.0) * 0.6)) / 5.0 - phase * 0.5) < 0.3;
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
	bool yellow = kind > 0.5 && kind < 1.5;
	bool black = kind > 1.5 || (yellow && monolith_pattern.w > 0.5 && in_pattern(cell));
	vec3 rim_color = border;
	float strength = border_strength;
	if (black) {
		rim_color = vec3(0.0);
		strength = 1.0;
	} else if (yellow) {
		rim_color = monolith_edge.rgb;
		strength = monolith_edge.a;
	}
	ALBEDO = vec3(0.0);
	EMISSION = mix(c, rim_color, clamp(rim * lit * strength, 0.0, 1.0));
	ROUGHNESS = 1.0;
	if (lit > 0.5 && black) {
		ROUGHNESS = 0.5;
	} else if (lit > 0.5 && yellow && monolith_edge.a > 0.0) {
		ROUGHNESS = 0.2;
	}
}
