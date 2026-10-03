// The film's print look, shared by every shader: flat inks laid down as
// halftone dots, like a screen-printed page. The palette (paper, ink,
// accent) is global and changes with each chapter of the message.

global uniform vec4 paper;
global uniform vec4 ink;
global uniform vec4 accent;
global uniform vec4 shadow;        // the tone shade is mixed toward: the paper at night, a deep ink by day
global uniform vec3 key_dir;
global uniform float halftone_px;
global uniform float song_time;
global uniform float dither;       // 1: halftone dots; 0: flat, solid tones
global uniform float print_scale;  // output height / 720, so dots and lines keep their size in frame

// A 45-degree dot screen fixed to the frame; each dot covers `coverage`
// (0 to 1) of its cell. Returns 1 inside a dot. With dither off it returns
// the coverage itself, so callers mix in a flat, solid tone instead.
float halftone(vec2 frag, float coverage) {
	if (dither < 0.5) {
		return clamp(coverage, 0.0, 1.0);
	}
	vec2 p = mat2(vec2(0.70710678, 0.70710678), vec2(-0.70710678, 0.70710678)) * frag / (halftone_px * print_scale);
	vec2 f = fract(p) - 0.5;
	float radius = sqrt(clamp(coverage, 0.0, 1.0) / 3.14159265) * 1.05;
	float d = length(f);
	float aa = max(fwidth(d), 0.02);
	return (coverage <= 0.0) ? 0.0 : 1.0 - smoothstep(radius - aa, radius + aa, d);
}

// How much of a face's colour goes to halftone shade: lit faces none, side
// faces some, faces turned from the light most. `view_normal` in view space.
float print_coverage(vec3 view_normal, mat4 view_matrix) {
	vec3 to_light = normalize((view_matrix * vec4(-key_dir, 0.0)).xyz);
	float ndl = dot(view_normal, to_light);
	return ndl > 0.45 ? 0.0 : (ndl > -0.1 ? 0.36 : 0.74);
}

vec3 srgb_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

vec3 hsv_to_rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}
