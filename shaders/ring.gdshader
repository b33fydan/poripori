shader_type spatial;
render_mode cull_back, specular_disabled, ambient_light_disabled;

// The ring's tiles. Each tile's INSTANCE_CUSTOM holds its radius, its angle,
// the song time the board passed over it (or far in the future), and where
// across the board's track it lay (-1 to 1). From those and song time alone:
// - the swell that travels round the ring lifts the tile;
// - the board presses it down as it passes, and it springs back with a wobble;
// - it takes the trail's rainbow, which fades back into the ring's bands;
// - its bands are Saturn's: tones that change with radius.

#include "res://shaders/print.gdshaderinc"

uniform float tile = 1.4;
uniform float r_in = 200.0;
uniform float r_out = 320.0;
uniform float swell_amp = 0.0;
uniform float swell_count = 24.0;
uniform float swell_phase = 0.0;
uniform float press_depth = 0.32;
uniform float paint_hold = 5.0;
uniform float paint_fade = 7.0;

varying vec3 local_pos;
varying float tone;
varying float paint;
varying vec3 paint_color;

float swell(float r, float theta) {
	float x = clamp((r - r_in) / (r_out - r_in), 0.0, 1.0);
	return swell_amp * sin(3.14159265 * x) * sin(swell_count * theta - swell_phase);
}

void vertex() {
	float r = INSTANCE_CUSTOM.x;
	float theta = INSTANCE_CUSTOM.y;
	float passed = INSTANCE_CUSTOM.z;
	float since = song_time - passed;
	float press = since >= 0.0 ? -press_depth * exp(-since * 5.0) * cos(since * 19.0) : 0.0;
	local_pos = VERTEX;
	VERTEX.y += swell(r, theta) + press;
	paint = since >= 0.0 ? 1.0 - smoothstep(paint_hold, paint_hold + paint_fade, since) : 0.0;
	paint_color = srgb_to_linear(hsv_to_rgb(vec3(fract(passed * 0.16 + INSTANCE_CUSTOM.w * 0.45), 0.6, 1.0)));
	float x = (r - r_in) / (r_out - r_in);
	tone = clamp(0.55 + 0.22 * sin(x * 41.0) + 0.14 * sin(x * 97.0 + 1.3) + 0.1 * sin(x * 13.0 + 0.4), 0.0, 1.0);
}

void fragment() {
	vec3 band = mix(mix(paper.rgb, accent.rgb, 0.16), mix(paper.rgb, accent.rgb, 0.62), tone);
	vec3 base = mix(band, paint_color, paint);
	vec3 shade = mix(base, paper.rgb, 0.6);
	vec3 c = mix(base, shade, halftone(FRAGCOORD.xy, print_coverage(NORMAL, VIEW_MATRIX)));
	// Thin dark seams between tiles, fading out with distance so far
	// tiles don't shimmer.
	vec2 e = abs(local_pos.xz) / (0.5 * tile);
	float edge = max(e.x, e.y);
	float w = fwidth(edge);
	float seam = smoothstep(0.9 - w, 0.9 + w, edge) * (1.0 - smoothstep(12.0, 45.0, length(VERTEX)));
	c = mix(c, paper.rgb, seam * 0.75);
	ALBEDO = vec3(0.0);
	EMISSION = c;
	ROUGHNESS = 1.0;
}
