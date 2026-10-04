class_name BrollKit
extends RefCounted

# What the B-roll shots share: the galaxy they float in, the ink pass, cubes
# with rims (yellow pulsing, or a steady white border), floating platforms,
# and camera paths. Every B-roll is a hyperlapse on a floating platform out
# in the galaxy (the owner's direction), and every frame is still a pure
# function of song time.

const SpaceScript := preload("res://scripts/space.gd")
const VoxelPartScript := preload("res://scripts/voxel_part.gd")
const InkShader := preload("res://shaders/ink.gdshader")
const MonolithShader := preload("res://shaders/monolith.gdshader")
const PrintShader := preload("res://shaders/print.gdshader")

const YELLOW := Color("#ffd75e")  # the pulse on placed cubes, as on the monolith


static func hash2(x: int, y: int) -> float:
	var h := (x * 374761393 + y * 668265263) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h % 10000) / 10000.0


# The galaxy as the set: stars, and a wide bright band laid across the view
# along `band_normal` (in world space).
static func galaxy(parent: Node, band_normal := Vector3(0.7, -0.7, -0.14)) -> Node3D:
	var space: Node3D = SpaceScript.new()
	parent.add_child(space)
	space.sky_material.set_shader_parameter("band_width", 0.34)
	space.sky_material.set_shader_parameter("band_glow", 0.55)
	space.sky_material.set_shader_parameter("band_cover", 0.8)
	space.set_meta("across", Basis(Quaternion(SpaceScript.BAND_NORMAL.normalized(), band_normal.normalized())))
	return space


# The sky wheels round over the shot: the hyperlapse's clock runs ahead.
static func update_galaxy(space: Node3D, t: float, since: float, camera: Camera3D, palette: Dictionary, turn_rate := 0.07) -> void:
	var across: Basis = space.get_meta("across")
	var turn := Basis(Vector3(0.2, 1.0, 0.35).normalized(), since * turn_rate) * across
	space.sky_material.set_shader_parameter("drift", Vector3(since * 0.12, 0.0, since * 0.05))
	space.update(t, camera.global_position, palette["ink"], palette["accent"], 0.0, turn)


static func camera(parent: Node, fov := 48.0) -> Camera3D:
	var cam := Camera3D.new()
	cam.fov = fov
	cam.near = 0.05
	cam.far = 6000.0
	parent.add_child(cam)
	cam.make_current()
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	var material := ShaderMaterial.new()
	material.shader = InkShader
	material.render_priority = 100
	mesh.material = material
	quad.mesh = mesh
	quad.extra_cull_margin = 16384.0
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cam.add_child(quad)
	return cam


# Placed cubes pulse yellow together, flaring on each beat.
static func edge_glow(timeline, t: float, strength := 1.0) -> void:
	var flare: float = timeline.beat_pulse(t, 0.35)
	var color := YELLOW.srgb_to_linear()
	RenderingServer.global_shader_parameter_set("monolith_edge", Vector4(color.r, color.g, color.b, (0.55 + 0.45 * flare) * strength))


# A MultiMesh of `count` cubes `size` across, with rims (see set_cube).
static func rim_cubes(parent: Node, size: float, count: int) -> MultiMesh:
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * size
	var material := ShaderMaterial.new()
	material.shader = MonolithShader
	cube.material = material
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = cube
	mm.instance_count = count
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = mm
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return mm


# One cube: `color` (sRGB), `pulse` true for a yellow pulsing rim (a placed
# cube), false for a steady white border; `flat` prints it flat and bright.
static func set_cube(mm: MultiMesh, i: int, xf: Transform3D, color: Color, pulse: bool, flat := false) -> void:
	_put_cube(mm, i, xf, color, 1.0 if pulse else 0.0, flat)


# One cube with a steady black border (the planets).
static func set_cube_black(mm: MultiMesh, i: int, xf: Transform3D, color: Color, flat := false) -> void:
	_put_cube(mm, i, xf, color, 2.0, flat)


static func _put_cube(mm: MultiMesh, i: int, xf: Transform3D, color: Color, kind: float, flat: bool) -> void:
	mm.set_instance_transform(i, xf)
	var c := color.srgb_to_linear()
	c.a = 1.0 if flat else 0.0
	mm.set_instance_color(i, c)
	mm.set_instance_custom_data(i, Color(1.0, kind, 0.0, 0.0))


static func hide_cube(mm: MultiMesh, i: int) -> void:
	mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))


# A floating platform of 1-unit voxels: a ragged oval deck in two tones,
# checkered, with rock hanging beneath, thickest in the middle. Returns the
# part (already added).
static func platform(parent: Node, half_x: float, half_z: float, deck: Color, deck_alt: Color, dirt: Color, rock: Color, seed := 0, voxel := 1.0) -> Node3D:
	var part: Node3D = VoxelPartScript.new(voxel, Vector3.ZERO)
	var nx := int(ceil(half_x))
	var nz := int(ceil(half_z))
	for x in range(-nx, nx):
		for z in range(-nz, nz):
			var r := pow((x + 0.5) / half_x, 2.0) + pow((z + 0.5) / half_z, 2.0) + (hash2(x + seed, z) - 0.5) * 0.12
			if r > 1.0:
				continue
			var depth := 1 + int(floor((1.0 - r) * 4.0)) + (1 if hash2(z, x + seed) > 0.85 else 0)
			if hash2(x * 3 + seed, z * 7) > 0.93:
				depth += 2 + int(hash2(x, z * 5 + seed) * 3.0)
			part.paint(Vector3i(x, -1, z), deck if (x + z) % 2 == 0 else deck_alt)
			for y in range(2, depth + 2):
				part.paint(Vector3i(x, -y, z), dirt if y <= 2 else rock)
	part.build()
	parent.add_child(part)
	return part


# A flat, opaque disc of shade under a standing figure.
static func shadow_disc(parent: Node, at: Vector3, tone: Color, radius := 0.42) -> void:
	var disc := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.01
	mesh.radial_segments = 24
	var material := ShaderMaterial.new()
	material.shader = PrintShader
	var linear := tone.srgb_to_linear()
	material.set_shader_parameter("tint", Vector4(linear.r, linear.g, linear.b, 1.0))
	mesh.material = material
	disc.mesh = mesh
	disc.position = at + Vector3(0.0, 0.006, 0.0)
	parent.add_child(disc)


# A box of one flat colour in the print look (props: consoles, belts, glass frames).
static func block(parent: Node, size: Vector3, at: Vector3, color: Color, flat := false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := ShaderMaterial.new()
	material.shader = PrintShader
	var linear := color.srgb_to_linear()
	material.set_shader_parameter("tint", Vector4(linear.r, linear.g, linear.b, 1.0))
	material.set_shader_parameter("vertex_flat", false)
	material.set_shader_parameter("flat_amount", 1.0 if flat else 0.0)  # flat and bright: screens, lamps
	mesh.material = material
	node.mesh = mesh
	node.position = at
	parent.add_child(node)
	return node


# A smooth path through `keys` (Catmull-Rom), u from 0 to 1.
static func path(keys: Array, u: float) -> Vector3:
	var f := clampf(u, 0.0, 1.0) * (keys.size() - 1)
	var i := mini(int(floor(f)), keys.size() - 2)
	var s := f - i
	var p0: Vector3 = keys[maxi(i - 1, 0)]
	var p1: Vector3 = keys[i]
	var p2: Vector3 = keys[i + 1]
	var p3: Vector3 = keys[mini(i + 2, keys.size() - 1)]
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * s + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * s * s + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * s * s * s)


# The message's bits, row by row ("1" lit), from data/arecibo/bits.txt.
static func bits() -> String:
	return FileAccess.get_file_as_string("res://data/arecibo/bits.txt").strip_edges()


# The lit cells of rows [r0, r1) as [row, column] pairs.
static func cells(r0: int, r1: int, c0 := 0, c1 := 23) -> Array:
	var all := bits()
	var out := []
	for row in range(r0, r1):
		for column in range(c0, c1):
			if all[row * 23 + column] == "1":
				out.append([row, column])
	return out
