shader_type sky;

// The night as a printed page: flat paper, a galaxy band laid down in
// halftone dots of the chapter's accent, and a big moon disc that the shot
// keeps behind the sculpture, as the reference keeps its sun behind the
// floating mountain. Nothing here reads TIME.

#include "res://shaders/print.gdshaderinc"

uniform vec3 moon_dir = vec3(0.0, 0.3, -1.0);
uniform float moon_radius = 0.12;
uniform vec3 band_normal = vec3(0.35, 0.82, -0.45);

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash13(i), hash13(i + vec3(1, 0, 0)), f.x),
	               mix(hash13(i + vec3(0, 1, 0)), hash13(i + vec3(1, 1, 0)), f.x), f.y),
	           mix(mix(hash13(i + vec3(0, 0, 1)), hash13(i + vec3(1, 0, 1)), f.x),
	               mix(hash13(i + vec3(0, 1, 1)), hash13(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec3(1.7, 9.2, 3.1);
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 d = normalize(EYEDIR);
	vec3 col = paper.rgb;
	float along = abs(dot(d, normalize(band_normal)));
	float band = exp(-pow(along / 0.22, 2.0));
	float clouds = smoothstep(0.42, 0.78, fbm(d * 3.2));
	float cover = clamp(band * (0.03 + 0.4 * clouds), 0.0, 0.45);
	col = mix(col, mix(paper.rgb, accent.rgb, 0.32), halftone(FRAGCOORD.xy, cover));
	// The moon: a flat disc, its lower half shaded in halftone.
	vec3 m = normalize(moon_dir);
	float angle = acos(clamp(dot(d, m), -1.0, 1.0));
	float aa = fwidth(angle);
	float disc = 1.0 - smoothstep(moon_radius - aa, moon_radius + aa, angle);
	vec3 up = normalize(vec3(0.0, 1.0, 0.0) - m * m.y);
	float low = clamp(0.5 - dot(d - m, up) / moon_radius * 0.5, 0.0, 1.0);
	vec3 face = mix(accent.rgb, paper.rgb, 0.22);
	vec3 moon = mix(face, mix(face, paper.rgb, 0.45), halftone(FRAGCOORD.xy, smoothstep(0.55, 1.0, low) * 0.5));
	COLOR = mix(col, moon, disc);
}
