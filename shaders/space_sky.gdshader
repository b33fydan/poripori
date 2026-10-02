shader_type sky;

// Deep space: a near-black blue, a faint band of galaxy across the sky with
// slow purple and teal clouds, and a scatter of pinprick stars. Nothing here
// reads TIME, so a frame depends only on where the camera looks.

uniform vec3 deep_color : source_color = vec3(0.012, 0.016, 0.045);
uniform vec3 band_color : source_color = vec3(0.10, 0.07, 0.20);
uniform vec3 cloud_a : source_color = vec3(0.26, 0.10, 0.36);
uniform vec3 cloud_b : source_color = vec3(0.05, 0.24, 0.30);
uniform vec3 band_normal = vec3(0.35, 0.82, -0.45);
uniform float band_width = 0.32;
uniform float cloud_strength = 0.55;
uniform float star_density = 0.9975;
uniform float brightness = 1.0;

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
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec3(1.7, 9.2, 3.1);
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float along = abs(dot(d, normalize(band_normal)));
	float band = exp(-pow(along / band_width, 2.0));
	float clouds = fbm(d * 3.0);
	float wisps = fbm(d * 7.0 + vec3(4.0));
	vec3 col = deep_color;
	col += band_color * band;
	col += mix(cloud_a, cloud_b, smoothstep(0.35, 0.65, wisps)) * smoothstep(0.45, 0.85, clouds) * band * cloud_strength;
	// Pinprick stars on a fine grid of directions, denser in the band.
	vec3 cell = floor(d * 420.0);
	float h = hash13(cell);
	float threshold = star_density - band * 0.0025;
	float star = step(threshold, h) * (0.4 + 0.6 * hash13(cell + 7.0));
	col += vec3(0.85, 0.9, 1.0) * star * 0.9;
	COLOR = col * brightness;
}
