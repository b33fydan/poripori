shader_type sky;

// The night as a printed page: flat paper and a galaxy band laid down in
// halftone dots of the chapter's accent (soft clouds with dither off).
// Nothing here reads TIME.

#include "res://shaders/print.gdshaderinc"

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
	COLOR = col;
}
