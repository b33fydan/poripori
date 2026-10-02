shader_type spatial;

// One cube of a VoxelPart, sculpture or trail. The MultiMesh instance colour
// (already linear) is the albedo; its alpha says how much the cube glows.

uniform float glow_energy = 0.0;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.82;
uniform float unshaded_mix : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	ALBEDO = COLOR.rgb * (1.0 - unshaded_mix);
	ROUGHNESS = roughness_value;
	SPECULAR = 0.3;
	EMISSION = COLOR.rgb * (COLOR.a * glow_energy + unshaded_mix);
}
