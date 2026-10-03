shader_type spatial;
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled, shadows_disabled;

// Ink outlines over the finished frame, drawn on a quad that covers the
// screen. A line goes wherever depth breaks (silhouettes, steps between
// cubes) or the surface turns sharply (cube edges). Depth is tested with
// its Laplacian, which is zero across any flat surface at any angle, so the
// ring's long grazing plane stays clean.
//
// The lit monolith marks its pixels with roughness 0.2 (shaders/
// monolith.gdshader); its outlines take the colour of monolith_edge.

#include "res://shaders/print.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform sampler2D normal_tex : hint_normal_roughness_texture, filter_nearest;
uniform float width = 1.0;
uniform float depth_edge = 0.05;
uniform float normal_edge = 0.3;
uniform float strength = 0.8;

void vertex() {
	POSITION = vec4(VERTEX.xy * 2.0, 1.0, 1.0);
}

vec3 normal_at(vec2 uv) {
	return normalize(texture(normal_tex, uv).xyz * 2.0 - 1.0);
}

// Roughness as written (Godot 4.6 stores it as is: measured, 0.2 reads 0.2
// and 1.0 reads 1.0).
float roughness_at(vec2 uv) {
	return texture(normal_tex, uv).w;
}

void fragment() {
	vec2 px = width * print_scale / VIEWPORT_SIZE;
	vec2 offsets[4] = vec2[](vec2(-px.x, 0.0), vec2(px.x, 0.0), vec2(0.0, -px.y), vec2(0.0, px.y));
	float dc = texture(depth_tex, SCREEN_UV).r;
	float sum = 0.0;
	float nearest = dc;
	vec2 nearest_uv = SCREEN_UV;
	for (int i = 0; i < 4; i++) {
		float d = texture(depth_tex, SCREEN_UV + offsets[i]).r;
		sum += d;
		if (d > nearest) {
			nearest = d;
			nearest_uv = SCREEN_UV + offsets[i];
		}
	}
	float edge = smoothstep(depth_edge, depth_edge * 2.0, abs(sum - 4.0 * dc) / max(nearest, 1e-7));
	if (dc > 0.0) {
		vec3 nc = normal_at(SCREEN_UV);
		for (int i = 0; i < 4; i++) {
			if (texture(depth_tex, SCREEN_UV + offsets[i]).r > 0.0) {
				float turn = 1.0 - dot(nc, normal_at(SCREEN_UV + offsets[i]));
				edge = max(edge, smoothstep(normal_edge, normal_edge * 1.6, turn));
			}
		}
	}
	vec3 scene = texture(screen_tex, SCREEN_UV).rgb;
	vec3 line = mix(ink.rgb, paper.rgb, 0.25);
	// The line belongs to the nearest surface at it.
	if (monolith_edge.a > 0.0 && nearest > 0.0 && abs(roughness_at(nearest_uv) - 0.2) < 0.08) {
		line = mix(line, monolith_edge.rgb, clamp(monolith_edge.a * 1.4, 0.0, 1.0));
	}
	ALBEDO = mix(scene, line, edge * strength);
}
