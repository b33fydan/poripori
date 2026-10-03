extends Node3D

# B-roll for the first chapter: a crew of astronauts builds the message's top
# layer (its first four rows, the numbers) on a floating island out in the
# galaxy (the owner asked for open space, not a sky), in fast motion. It's
# one of the film's separate incidents: it echoes the chapter without
# explaining it, so the mystery holds.
#
# The crew works as a bucket brigade. Blocks leap from a pile to the first
# astronaut and are tossed from hand to hand down the line, and the last one
# throws each up into its slot in the wall, where it snaps in with a squash.
# Every block lands on an eighth-note of the beat, bottom row first. The
# camera glides along the line to the wall over the ten seconds while the
# stars and the galaxy wheel overhead: a hyperlapse, with every frame still a
# function of song time.
#
# The island's trees and rocks are the owner's MEGAVOX models, recoloured
# into the silver night like the reference's runs; without the licensed
# files the island is simply bare.

const AstronautScript := preload("res://scripts/astronaut.gd")
const PaletteScript := preload("res://scripts/palette.gd")
const MegavoxScript := preload("res://scripts/megavox.gd")
const VoxelPartScript := preload("res://scripts/voxel_part.gd")
const InkShader := preload("res://shaders/ink.gdshader")
const SpaceScript := preload("res://scripts/space.gd")
const PrintShader := preload("res://shaders/print.gdshader")

const BITS_PATH := "res://data/arecibo/bits.txt"
const COLUMNS := 23
const ROWS_BUILT := 4         # rows 0-3: the numbers
const BLOCK := 0.6            # a wall block: astronauts carry them at the chest
const PITCH := 0.68
const WALL_Z := -6.0
const CREW := 9
const HOP := 0.2              # seconds a block flies between two of the crew
const HOLD := 0.04            # seconds each holds it
const LAST_HOP := 0.38        # the throw up into the wall
const PILE_AT := Vector3(-13.0, 0.0, 3.6)
const PALETTE := "numbers_space"
const SKY_TURN := 0.07        # radians a second the sky wheels round
const TRIMS := ["#5e8ec7", "#e8735a", "#5bbf7a", "#9b7be0", "#f2cf6b", "#3fc1c9", "#e87ba4", "#5e8ec7", "#e8735a"]
# Trees and rocks round the island's rim: [category, file, height, position].
const PROPS := [
	["trees", "Tree.022.glb", 4.6, Vector3(-17.5, 0, -7.5)], ["trees", "Tree.016.glb", 6.2, Vector3(-12.0, 0, -10.0)],
	["trees", "Tree.034.glb", 4.2, Vector3(15.5, 0, -10.0)], ["trees", "Tree.006.glb", 5.0, Vector3(19.5, 0, -4.5)],
	["trees", "Tree.019.glb", 5.6, Vector3(18.5, 0, 2.5)], ["trees", "Tree.035.glb", 3.8, Vector3(-19.0, 0, 1.0)],
	["trees", "Tree.005.glb", 4.4, Vector3(6.0, 0, -11.0)], ["trees", "Tree.023.glb", 3.4, Vector3(15.0, 0, 8.0)],
	["rocks", "Rock.002.glb", 1.3, Vector3(-9.5, 0, -8.5)], ["rocks", "Rock.032.glb", 1.1, Vector3(9.0, 0, -8.0)],
	["rocks", "Rock.012.glb", 1.6, Vector3(16.0, 0, -2.0)], ["rocks", "Rock.003.glb", 0.9, Vector3(-18.0, 0, 5.5)],
	["rocks", "Rock.018.glb", 1.4, Vector3(-4.0, 0, -10.5)], ["rocks", "Rock.033.glb", 1.0, Vector3(11.5, 0, 6.5)],
]

var options := {}
var timeline
var camera: Camera3D
var start := 0.0
var end := 0.0
var _palette: Dictionary
var space: Node3D
var _crew: Array = []        # Astronaut nodes
var _toward_prev: Array = [] # the torso turn (radians) that faces the one before
var _toward_next: Array = []
var _slots: Array = []       # [row, column] in landing order
var _land := PackedFloat64Array()
var _blocks: MultiMesh
var _block_color := Color.WHITE


func setup(song_timeline) -> void:
	timeline = song_timeline
	start = float(options.get("from", str(timeline.bar_time(11.0))))
	end = float(options.get("to", str(timeline.bar_time(16.0))))
	if options.has("stills"):
		start = timeline.bar_time(11.0)
		end = timeline.bar_time(16.0)
	_palette = PaletteScript.colors(PALETTE)
	PaletteScript.apply(_palette)
	_build_sky()
	_build_island()
	_build_props()
	_plan_wall()
	_build_crew()
	camera = Camera3D.new()
	camera.fov = 48.0
	camera.near = 0.05
	camera.far = 6000.0
	add_child(camera)
	camera.make_current()
	_build_ink_pass()


func _tone(a: String, b: String, amount: float) -> Color:
	return (_palette[a] as Color).lerp(_palette[b] as Color, amount)


func _build_sky() -> void:
	space = SpaceScript.new()
	add_child(space)
	# The galaxy is the set here, so its band is wider and brighter.
	space.sky_material.set_shader_parameter("band_width", 0.34)
	space.sky_material.set_shader_parameter("band_glow", 0.55)
	space.sky_material.set_shader_parameter("band_cover", 0.8)


func _build_ink_pass() -> void:
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	var material := ShaderMaterial.new()
	material.shader = InkShader
	material.render_priority = 100
	mesh.material = material
	quad.mesh = mesh
	quad.extra_cull_margin = 16384.0
	camera.add_child(quad)


static func _hash(x: int, y: int) -> float:
	var h := (x * 374761393 + y * 668265263) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h % 10000) / 10000.0


# A floating island of 1-unit voxels: a ragged oval of ground, thickest in
# the middle, with rock hanging beneath.
func _build_island() -> void:
	var island := VoxelPartScript.new(1.0, Vector3.ZERO)
	var grass := _tone("paper", "accent", 0.62)
	var grass_alt := _tone("paper", "accent", 0.54)
	var dirt := _tone("paper", "accent", 0.36)
	var rock := _tone("paper", "accent", 0.24)
	for x in range(-22, 22):
		for z in range(-14, 12):
			var r := pow((x + 0.5) / 21.5, 2.0) + pow((z + 1.0) / 12.5, 2.0) + (_hash(x, z) - 0.5) * 0.12
			if r > 1.0:
				continue
			var depth := 1 + int(floor((1.0 - r) * 4.0)) + (1 if _hash(z, x) > 0.85 else 0)
			if _hash(x * 3, z * 7) > 0.93:
				depth += 2 + int(_hash(x, z * 5) * 3.0)
			island.paint(Vector3i(x, -1, z), grass if (x + z) % 2 == 0 else grass_alt)
			for y in range(2, depth + 2):
				island.paint(Vector3i(x, -y, z), dirt if y <= 2 else rock)
	island.build()
	add_child(island)


func _recolor(c: Color) -> Color:
	var l := c.get_luminance()
	if l < 0.4:
		return _tone("paper", "accent", 0.3 + 0.5 * l / 0.4)
	return _tone("accent", "ink", (l - 0.4) / 0.6 * 0.7)


func _build_props() -> void:
	for prop in PROPS:
		var model: Node3D = MegavoxScript.load_model(str(prop[0]), str(prop[1]))
		if model == null:
			continue
		MegavoxScript.print_look(model, _recolor)
		var holder: Node3D = MegavoxScript.stand(model, float(prop[2]))
		holder.position = prop[3]
		holder.rotation.y = _hash(int(holder.position.x * 10.0), int(holder.position.z * 10.0)) * TAU
		add_child(holder)


# The wall: the 1s of the first four rows, bottom row first, left to right,
# each landing on an eighth-note from the fourth one in.
func _plan_wall() -> void:
	var bits := FileAccess.get_file_as_string(BITS_PATH).strip_edges()
	for row in range(ROWS_BUILT - 1, -1, -1):
		for column in range(COLUMNS):
			if bits[row * COLUMNS + column] == "1":
				_slots.append([row, column])
	var eighth: float = timeline.period * 0.5
	var count := _slots.size()
	_land.resize(count)
	for k in range(count):
		_land[k] = start + eighth * (4.0 + round(k * 31.0 / (count - 1)))
	_block_color = _tone("accent", "ink", 0.85)
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * BLOCK
	var material := ShaderMaterial.new()
	material.shader = PrintShader
	cube.material = material
	_blocks = MultiMesh.new()
	_blocks.transform_format = MultiMesh.TRANSFORM_3D
	_blocks.use_colors = true
	_blocks.mesh = cube
	_blocks.instance_count = count
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = _blocks
	add_child(instance)


func _slot_position(k: int) -> Vector3:
	var slot: Array = _slots[k]
	return Vector3((int(slot[1]) - (COLUMNS - 1) * 0.5) * PITCH, (ROWS_BUILT - 1 - int(slot[0])) * PITCH + BLOCK * 0.5 + 0.08, WALL_Z)


func _pile_position(k: int) -> Vector3:
	var place := _slots.size() - 1 - k  # the top of the pile goes first
	return PILE_AT + Vector3((place % 3 - 1) * 0.66, (place / 9) * 0.64 + BLOCK * 0.5, ((place / 3) % 3 - 1) * 0.66)


func _bezier(u: float) -> Vector3:
	var a := Vector3(-10.6, 0.0, 3.6)
	var b := Vector3(-5.2, 0.0, 4.6)
	var c := Vector3(-0.4, 0.0, -2.3)
	return a.lerp(b, u).lerp(b.lerp(c, u), u)


func _build_crew() -> void:
	for j in range(CREW):
		var astronaut := AstronautScript.new(Color(str(TRIMS[j])), false)
		var p := _bezier(j / float(CREW - 1))
		astronaut.position = p
		# Face out of the line toward the camera's side; the last faces the wall.
		var along := (_bezier(minf(1.0, j / float(CREW - 1) + 0.02)) - _bezier(maxf(0.0, j / float(CREW - 1) - 0.02))).normalized()
		var facing := along.cross(Vector3.UP).normalized()
		if facing.z < 0.0:
			facing = -facing
		if j == CREW - 1:
			facing = Vector3.FORWARD
		astronaut.rotation.y = atan2(facing.x, facing.z)
		add_child(astronaut)
		_crew.append(astronaut)
		_add_shadow(p)
	# The torso turn toward each neighbour, in each one's own frame.
	for j in range(CREW):
		var me: Node3D = _crew[j]
		var from_pos: Vector3 = PILE_AT if j == 0 else (_crew[j - 1] as Node3D).position
		var to_pos: Vector3 = Vector3(0.0, 0.0, WALL_Z) if j == CREW - 1 else (_crew[j + 1] as Node3D).position
		_toward_prev.append(clampf(_local_angle(me, from_pos), -1.1, 1.1))
		_toward_next.append(clampf(_local_angle(me, to_pos), -1.1, 1.1))


func _local_angle(node: Node3D, target: Vector3) -> float:
	var local := node.transform.affine_inverse() * target
	return atan2(local.x, local.z)


# A flat, opaque disc of shade under each of the crew, so they stand on the
# ground (the ink pass would paint over a transparent one).
func _add_shadow(at: Vector3) -> void:
	var disc := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.42
	mesh.bottom_radius = 0.42
	mesh.height = 0.01
	mesh.radial_segments = 24
	var material := ShaderMaterial.new()
	material.shader = PrintShader
	var tone := _tone("paper", "accent", 0.4).srgb_to_linear()
	material.set_shader_parameter("tint", Vector4(tone.r, tone.g, tone.b, 1.0))
	mesh.material = material
	disc.mesh = mesh
	disc.position = at + Vector3(0.0, 0.006, 0.0)
	add_child(disc)


# --- Timing of the brigade -------------------------------------------------------

# When crew member j catches block k (it throws it HOLD later).
func _catch(k: int, j: int) -> float:
	return _land[k] - LAST_HOP - HOLD - (CREW - 1 - j) * (HOLD + HOP)


func _hands(j: int, turn: float) -> Vector3:
	var me: Node3D = _crew[j]
	var local: Vector3 = Basis(Vector3.UP, turn) * me.hands_point(BLOCK)
	return me.transform * local


# Where block k is at time t, and how far into its landing it is (-1 before).
func _block_at(k: int, t: float) -> Array:
	var leave := _catch(k, 0) - HOP
	if t < leave:
		return [_pile_position(k), -1.0]
	if t >= _land[k]:
		return [_slot_position(k), t - _land[k]]
	# In the air between two holders, or held.
	for j in range(CREW + 1):
		var arrive := _catch(k, j) if j < CREW else _land[k]
		var depart := (_catch(k, j - 1) + HOLD) if j > 0 else leave
		var from_pos: Vector3 = _pile_position(k) if j == 0 else _hands(j - 1, _toward_next[j - 1])
		var to_pos: Vector3 = _slot_position(k) if j == CREW else _hands(j, _toward_prev[j])
		if t < arrive:
			if t < depart:
				return [from_pos, -1.0]
			var u := (t - depart) / (arrive - depart)
			var apex := 1.3 if j == CREW else 0.45
			return [from_pos.lerp(to_pos, u) + Vector3.UP * apex * 4.0 * u * (1.0 - u), -1.0]
		if j < CREW and t < arrive + HOLD:
			return [to_pos, -1.0]
	return [_slot_position(k), 0.0]


# --- Each frame ------------------------------------------------------------------

func update(t: float) -> void:
	RenderingServer.global_shader_parameter_set("song_time", t)
	PaletteScript.apply(_palette)
	var since := t - start
	_pose_crew(t)
	for k in range(_slots.size()):
		var at: Array = _block_at(k, t)
		var landed: float = at[1]
		var scale := 1.0
		var flash := 0.0
		if landed >= 0.0:
			scale = 1.0 - 0.28 * exp(-landed * 9.0) * cos(landed * 30.0)
			flash = 1.0 if landed < 0.12 else 0.0
		var spin := Basis.IDENTITY
		if landed < 0.0 and t >= _catch(k, 0) - HOP:
			spin = Basis(Vector3(0.3, 1.0, 0.2).normalized(), (t - _land[k]) * 3.0)
		_blocks.set_instance_transform(k, Transform3D(spin.scaled(Vector3(1.0 / sqrt(scale), scale, 1.0 / sqrt(scale))), at[0]))
		var color := _block_color.srgb_to_linear()
		color.a = flash
		_blocks.set_instance_color(k, color)
	_place_camera(t)
	# The sky wheels round: the hyperlapse's clock runs well ahead of the music's.
	# The galaxy's band laid diagonally across the sky the camera looks at.
	var across := Basis(Quaternion(SpaceScript.BAND_NORMAL.normalized(), Vector3(0.7, -0.7, -0.14).normalized()))
	var turn := Basis(Vector3(0.2, 1.0, 0.35).normalized(), since * SKY_TURN) * across
	space.sky_material.set_shader_parameter("drift", Vector3(since * 0.12, 0.0, since * 0.05))
	space.update(t, camera.global_position, _palette["ink"], _palette["accent"], 0.0, turn)


func _pose_crew(t: float) -> void:
	for j in range(CREW):
		var me: Node3D = _crew[j]
		var reach := 0.0
		var turn: float = _toward_prev[j]
		var bob := 0.0
		for k in range(_slots.size()):
			var c := _catch(k, j)
			var rel := t - c
			if rel > -0.16 and rel < HOLD + 0.14:
				# Up to catch, hold, swing round to toss it on.
				reach = maxf(reach, smoothstep(-0.16, -0.02, rel) * (1.0 - smoothstep(HOLD + 0.02, HOLD + 0.14, rel)))
				turn = lerpf(_toward_prev[j], _toward_next[j], smoothstep(-0.02, HOLD + 0.06, rel))
				bob = maxf(bob, 1.2 * exp(-maxf(rel, 0.0) * 14.0) * smoothstep(-0.04, 0.0, rel))
		var shuffle: float = TAU * timeline.beat(t) * 0.5 + j * 0.7
		me.pose_on_foot(shuffle, 0.12, reach, turn * 0.8, bob)
		me.antenna_tip.scale = Vector3.ONE * (1.0 + 0.6 * timeline.beat_pulse(t, 0.2))


# The hyperlapse move: a steady glide from beside the pile, along the line,
# up and round to the finished wall, easing only at its very ends.
func _place_camera(t: float) -> void:
	var u := clampf((t - start) / (end - start), 0.0, 1.0)
	u = lerpf(u, smoothstep(0.0, 1.0, u), 0.3)
	var keys := [Vector3(-15.5, 2.6, 9.4), Vector3(-8.5, 2.7, 10.0), Vector3(-2.0, 3.1, 8.6), Vector3(1.5, 3.0, 5.0)]
	var f := u * (keys.size() - 1)
	var i := mini(int(floor(f)), keys.size() - 2)
	var s := f - i
	var p0: Vector3 = keys[maxi(i - 1, 0)]
	var p1: Vector3 = keys[i]
	var p2: Vector3 = keys[i + 1]
	var p3: Vector3 = keys[mini(i + 2, keys.size() - 1)]
	var eye := 0.5 * ((2.0 * p1) + (-p0 + p2) * s + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * s * s + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * s * s * s)
	var target := Vector3(-9.0, 0.9, 3.0).lerp(Vector3(0.0, 1.3, WALL_Z), smoothstep(0.0, 1.0, u))
	camera.look_at_from_position(eye, target, Vector3.UP)
