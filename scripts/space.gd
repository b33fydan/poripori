class_name Space
extends Node3D

# The night: a shader sky (deep blue, a faint galaxy band, pinprick stars),
# far voxel stars that ride with the camera like the sky does, and near dust
# cubes that stream past to show speed. Lights for the rider live here too.

const SkyShader := preload("res://shaders/space_sky.gdshader")
const VoxelShader := preload("res://shaders/voxel.gdshader")
const FAR_STARS := 700
const FAR_RADIUS := 900.0
const DUST := 420
const DUST_BOX := Vector3(70.0, 50.0, 90.0)

var environment: Environment
var key: DirectionalLight3D
var rim: DirectionalLight3D
var fill: DirectionalLight3D
var _stars: MultiMesh
var _star_data: Array = []  # [direction, size, colour, twinkle rate, phase]
var _stars_node: Node3D
var _dust: MultiMesh
var _dust_home: Array = []


func _init() -> void:
	name = "Space"
	_build_environment()
	_build_lights()
	_build_far_stars()
	_build_dust()


func _build_environment() -> void:
	var sky_material := ShaderMaterial.new()
	sky_material.shader = SkyShader
	var sky := Sky.new()
	sky.sky_material = sky_material
	sky.process_mode = Sky.PROCESS_MODE_QUALITY
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#2a3160")
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	environment.tonemap_white = 4.0
	environment.glow_enabled = true
	environment.glow_intensity = 0.75
	environment.glow_strength = 1.0
	environment.glow_bloom = 0.04
	environment.glow_hdr_threshold = 0.85
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	for level in range(7):
		environment.set_glow_level(level, 1.0 if level in [1, 2, 3, 4] else 0.0)
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.06
	environment.adjustment_saturation = 1.08
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)


func _build_lights() -> void:
	# A soft warm key from over the camera's shoulder, and a cool rim from
	# ahead, the sculpture's side, to cut the rider out of the dark.
	key = DirectionalLight3D.new()
	key.light_color = Color("#ffe6cf")
	key.light_energy = 1.05
	key.shadow_enabled = true
	key.shadow_blur = 1.0
	key.directional_shadow_max_distance = 25.0
	add_child(key)
	key.basis = Basis.looking_at(Vector3(0.45, -0.55, -0.7), Vector3.UP)
	rim = DirectionalLight3D.new()
	rim.light_color = Color("#86d9ff")
	rim.light_energy = 1.2
	add_child(rim)
	rim.basis = Basis.looking_at(Vector3(-0.3, -0.25, 1.0), Vector3.UP)
	# A soft lavender fill on the rider's front and nose side, which the
	# key misses: the side the camera sees when it's in front of the visor.
	fill = DirectionalLight3D.new()
	fill.light_color = Color("#d4ceff")
	fill.light_energy = 0.75
	add_child(fill)
	fill.basis = Basis.looking_at(Vector3(-0.6, -0.35, 0.6), Vector3.UP)


func _material(unshaded: float, glow: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = VoxelShader
	material.set_shader_parameter("unshaded_mix", unshaded)
	material.set_shader_parameter("glow_energy", glow)
	return material


func _build_far_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1974
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE
	cube.material = _material(1.0, 1.4)
	_stars = MultiMesh.new()
	_stars.transform_format = MultiMesh.TRANSFORM_3D
	_stars.use_colors = true
	_stars.mesh = cube
	_stars.instance_count = FAR_STARS
	var palette := [Color("#ffffff"), Color("#cfe0ff"), Color("#9fc3ff"), Color("#ffe3b0"), Color("#ffc6e6")]
	for i in range(FAR_STARS):
		var direction := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
		while direction.length() > 1.0 or direction.length() < 0.1:
			direction = Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
		var size := pow(rng.randf(), 3.0) * 4.5 + 1.0
		_star_data.append([direction.normalized(), size, palette[rng.randi() % palette.size()], rng.randf_range(0.6, 2.2), rng.randf() * TAU])
	_stars_node = Node3D.new()
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = _stars
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_stars_node.add_child(instance)
	add_child(_stars_node)


func _build_dust() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1679
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * 0.08
	cube.material = _material(1.0, 0.6)
	_dust = MultiMesh.new()
	_dust.transform_format = MultiMesh.TRANSFORM_3D
	_dust.use_colors = true
	_dust.mesh = cube
	_dust.instance_count = DUST
	for i in range(DUST):
		_dust_home.append(Vector3(rng.randf() * DUST_BOX.x, rng.randf() * DUST_BOX.y, rng.randf() * DUST_BOX.z))
		var tint := Color("#7f93d8").lerp(Color("#c7a6ff"), rng.randf())
		var linear := tint.srgb_to_linear()
		linear.a = rng.randf_range(0.15, 0.6)
		_dust.set_instance_color(i, linear)
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = _dust
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


# shimmer: 0 still, 1 the stars breathe on the beat (pulse).
func update(t: float, camera_position: Vector3, shimmer: float, pulse: float) -> void:
	_stars_node.position = camera_position
	for i in range(FAR_STARS):
		var star: Array = _star_data[i]
		var twinkle := 0.75 + 0.25 * sin(t * float(star[3]) + float(star[4]))
		var beat := 1.0 + shimmer * pulse * (0.6 if i % 3 == 0 else 0.15)
		var size: float = float(star[1]) * twinkle * beat
		var direction: Vector3 = star[0]
		# Each star faces the camera's way a little differently; cubes, not dots.
		var spin := Basis(Vector3(0.3, 1.0, 0.2).normalized(), float(star[4]))
		_stars.set_instance_transform(i, Transform3D(spin.scaled(Vector3.ONE * size), direction * FAR_RADIUS))
		var color: Color = (star[2] as Color).srgb_to_linear()
		color.a = twinkle * beat
		_stars.set_instance_color(i, color)
	# Dust wraps around the camera in a box, so it never runs out.
	var corner := camera_position - DUST_BOX * 0.5
	for i in range(DUST):
		var home: Vector3 = _dust_home[i]
		var p := Vector3(
			fposmod(home.x - corner.x, DUST_BOX.x),
			fposmod(home.y - corner.y, DUST_BOX.y),
			fposmod(home.z - corner.z, DUST_BOX.z)) + corner
		var spin := Basis(Vector3(home.y, home.z, home.x).normalized(), home.x + t * 0.3)
		_dust.set_instance_transform(i, Transform3D(spin, p))
