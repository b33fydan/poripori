class_name Space
extends Node3D

# The night, printed: the sky shader lays down paper and a galaxy band;
# voxel stars ride with the camera like the sky does, and dust streams past
# to show speed and depth. There are no scene lights: every
# surface takes its tones from the print shaders and the global palette.

const SkyShader := preload("res://shaders/print_sky.gdshader")
const PrintShader := preload("res://shaders/print.gdshader")
const FAR_STARS := 1800
const FAR_RADIUS := 2400.0
const DUST := 330          # 300, plus 10% more at half size for depth
const SMALL_DUST_FROM := 300
const DUST_BOX := Vector3(70.0, 50.0, 90.0)

var environment: Environment
var sky_material: ShaderMaterial
var _stars: MultiMesh
var _star_data: Array = []  # [direction, size, twinkle rate, phase, tint]
var _stars_node: Node3D
var _dust: MultiMesh
var _dust_home: Array = []


func _init() -> void:
	name = "Space"
	_build_environment()
	_build_far_stars()
	_build_dust()


func _build_environment() -> void:
	sky_material = ShaderMaterial.new()
	sky_material.shader = SkyShader
	var sky := Sky.new()
	sky.sky_material = sky_material
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	# Linear and untouched, so the printed colours come out exactly.
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.glow_enabled = false
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)


func _flat_cubes(count: int, size: float) -> MultiMesh:
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * size
	var material := ShaderMaterial.new()
	material.shader = PrintShader
	cube.material = material
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = cube
	mm.instance_count = count
	return mm


func _build_far_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1974
	_stars = _flat_cubes(FAR_STARS, 1.0)
	for i in range(FAR_STARS):
		var direction := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
		while direction.length() > 1.0 or direction.length() < 0.1:
			direction = Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
		var size := pow(rng.randf(), 3.5) * 12.0 + 2.2
		_star_data.append([direction.normalized(), size, rng.randf_range(0.6, 2.2), rng.randf() * TAU, rng.randf()])
	_stars_node = Node3D.new()
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = _stars
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_stars_node.add_child(instance)
	add_child(_stars_node)


func _build_dust() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1679
	_dust = _flat_cubes(DUST, 0.08)
	for i in range(DUST):
		_dust_home.append(Vector3(rng.randf() * DUST_BOX.x, rng.randf() * DUST_BOX.y, rng.randf() * DUST_BOX.z))
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = _dust
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


# ink and accent: the current palette's. pulse: 0..1 on the beat.
func update(t: float, camera_position: Vector3, ink: Color, accent: Color, pulse: float) -> void:
	_stars_node.position = camera_position
	for i in range(FAR_STARS):
		var star: Array = _star_data[i]
		var twinkle := 0.8 + 0.2 * sin(t * float(star[2]) + float(star[3]))
		var beat := 1.0 + pulse * (0.5 if i % 3 == 0 else 0.1)
		var direction: Vector3 = star[0]
		var spin := Basis(Vector3(0.3, 1.0, 0.2).normalized(), float(star[3]))
		_stars.set_instance_transform(i, Transform3D(spin.scaled(Vector3.ONE * float(star[1]) * twinkle * beat), direction * FAR_RADIUS))
		var color := ink.lerp(accent, float(star[4]) * 0.5).srgb_to_linear()
		color.a = 1.0
		_stars.set_instance_color(i, color)
	var dust_color := ink.srgb_to_linear()
	dust_color.a = 1.0
	var corner := camera_position - DUST_BOX * 0.5
	for i in range(DUST):
		var home: Vector3 = _dust_home[i]
		var p := Vector3(
			fposmod(home.x - corner.x, DUST_BOX.x),
			fposmod(home.y - corner.y, DUST_BOX.y),
			fposmod(home.z - corner.z, DUST_BOX.z)) + corner
		var spin := Basis(Vector3(home.y, home.z, home.x).normalized(), home.x + t * 0.3)
		if i >= SMALL_DUST_FROM:
			spin = spin.scaled(Vector3.ONE * 0.5)
		_dust.set_instance_transform(i, Transform3D(spin, p))
		_dust.set_instance_color(i, dust_color)
