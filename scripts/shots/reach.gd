extends Node3D

# The reach (song 1:03.5 to the drop at 1:35.3): the astronaut jumps off the
# board and floats up in slow motion, a massive voxel Earth behind, turned so
# the Caribbean (Arecibo, 18.34 N 66.75 W) faces the camera. Seen from:
#   view=side    (bars 32-36): he springs off the board, one fist punched up
#     in triumph, and the camera follows him up as Earth falls away below;
#   view=top     (bars 38-42): looking down from above, he lowers the fist and
#     turns slowly;
#   view=reveal  (bars 44-46): from below, his glove rises until it points up;
#   view=touch   (bars 46-48.5): the mascot, revealed above him, looks down
#     and slides its little arm out toward him; the camera closes slowly on
#     their hands, and they touch exactly on the drop's first kick, throwing
#     sparks and stars.
# His rise is one continuous motion from bar 32, so every view shows the
# same moment. Slow motion: everything drifts.

const AstronautScript := preload("res://scripts/astronaut.gd")
const MascotScript := preload("res://scripts/mascot.gd")
const EarthScript := preload("res://scripts/voxel_earth.gd")
const SpaceScript := preload("res://scripts/space.gd")
const StarTrailScript := preload("res://scripts/star_trail.gd")
const SparksScript := preload("res://scripts/sparks.gd")
const PaletteScript := preload("res://scripts/palette.gd")
const InkShader := preload("res://shaders/ink.gdshader")

const ARECIBO := Vector2(18.34, -66.75)  # latitude, longitude
const RISE := 0.16                         # his steady rise, units per second
const JUMP := 1.6                          # how far the spring off the board carries him
const JUMP_TIME := 0.7                     # seconds: how fast that spring dies away

var options := {}
var timeline
var camera: Camera3D
var astronaut: Node3D
var mascot: Node3D
var earth: Node3D
var space: Node3D
var stars: Node3D
var sparks: Node3D
var _palette: Dictionary
var lift := 0.0    # bar 32: off the board
var touch := 0.0   # bar 48: the drop


func setup(song_timeline) -> void:
	timeline = song_timeline
	lift = timeline.bar_time(32.0)
	touch = timeline.section_start("drop")
	_palette = PaletteScript.colors("home")
	PaletteScript.apply(_palette)
	space = SpaceScript.new()
	add_child(space)
	earth = EarthScript.new(56, 8.0)
	add_child(earth)
	astronaut = AstronautScript.new()
	add_child(astronaut)
	mascot = MascotScript.new()
	add_child(mascot)
	stars = StarTrailScript.new(func(_t: float) -> Vector3: return Vector3.ZERO, func(_t: float) -> float: return 0.0)
	add_child(stars)
	sparks = SparksScript.new()
	add_child(sparks)
	camera = Camera3D.new()
	camera.near = 0.05
	camera.far = 8000.0
	add_child(camera)
	camera.make_current()
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	var material := ShaderMaterial.new()
	material.shader = InkShader
	material.render_priority = 100
	mesh.material = material
	quad.mesh = mesh
	quad.extra_cull_margin = 16384.0
	camera.add_child(quad)


# Where he is: springing off the board at bar 32, the spring dying away
# into a steady rise.
func _body_position(t: float) -> Vector3:
	var since := maxf(t - lift, 0.0)
	return Vector3(0.05 * sin(since * 0.31), RISE * since + JUMP * (1.0 - exp(-since / JUMP_TIME)), 0.04 * sin(since * 0.23))


# Floating in zero g. `up` (0..1) lifts him off the board: from the surf
# stance into loose, slightly spread limbs, blended part by part so nothing
# jumps. `reach` raises the left glove from loose at the side to up and out.
# `fist` punches the right glove up and out in triumph (straight up, it would
# hide beside the big helmet), the body leaning away to lift it higher.
const POSE_PARTS := ["torso", "leg_l", "leg_r", "boot_l", "boot_r", "arm_l", "arm_r", "helmet"]


func _float_pose(t: float, up: float, reach: float, fist := 0.0) -> void:
	var since := t - lift
	var drift := sin(since * 0.6)
	var stance := []
	if up < 1.0:
		astronaut.pose(0.42, 0.0, 0.9, Vector4(1.2, 0.35, -0.95, 0.4))
		for part in POSE_PARTS:
			stance.append((astronaut.get(part) as Node3D).transform)
	astronaut.pose(0.15, 0.0, 0.2, Vector4(0.6, 0.1, -0.55, 0.1))
	astronaut.pose_on_foot(0.0, 0.0, 0.0)
	astronaut.leg_l.rotation = Vector3(0.25 + 0.08 * drift, 0.0, 0.18)
	astronaut.leg_r.rotation = Vector3(-0.15 - 0.08 * drift, 0.0, -0.22)
	astronaut.boot_l.rotation = Vector3(-0.3, 0.0, -0.1)
	astronaut.boot_r.rotation = Vector3(0.2, 0.0, 0.1)
	astronaut.arm_r.rotation = Vector3(-0.2, 0.0, -0.55 - 0.1 * drift)
	# Up and out on the diagonal: straight up, the glove would hide beside the
	# big helmet.
	astronaut.arm_l.rotation = Vector3(-0.1 * (1.0 - reach), 0.0, lerpf(0.6 + 0.1 * drift, 2.35, reach))
	astronaut.helmet.rotation = Vector3(lerpf(0.05, -0.35, reach), 0.0, 0.0)
	if up < 1.0:
		var u := smoothstep(0.0, 1.0, up)
		for i in range(POSE_PARTS.size()):
			var node: Node3D = astronaut.get(POSE_PARTS[i])
			node.transform = (stance[i] as Transform3D).interpolate_with(node.transform, u)
	if fist > 0.0:
		astronaut.arm_r.rotation = astronaut.arm_r.rotation.lerp(Vector3(0.15, 0.0, -2.4), fist)
		astronaut.torso.rotation.z -= 0.18 * fist
		astronaut.helmet.rotation.x -= 0.25 * fist


# The board slips out from under him and drifts away below, slowly turning.
func _place_board(t: float) -> void:
	var since := maxf(t - lift, 0.0)
	var away := Vector3(0.0, -0.22 * since - 0.02 * since * since, -0.12 * since)
	var spin := Basis(Vector3(0.3, 0.2, 1.0).normalized(), 0.12 * since)
	for part in [astronaut.board, astronaut.board_glow]:
		(part as Node3D).transform = Transform3D(spin, away - Vector3(0.0, _body_position(t).y, 0.0))


func _hide_board() -> void:
	astronaut.board.visible = false
	astronaut.board_glow.visible = false


# Earth low in the background of the current view: its centre placed down
# and back from the camera, so its limb crosses the lower part of the frame.
func _earth_behind(down: float, distance := 1080.0, offset := Vector3(-420.0, 0.0, 0.0)) -> void:
	var forward := -camera.global_transform.basis.z
	var up := camera.global_transform.basis.y
	earth.position = camera.global_position + (forward * cos(down) - up * sin(down)).normalized() * distance + offset


func _glove() -> Vector3:
	return astronaut.torso.global_transform * (astronaut.arm_l.position + astronaut.arm_l.basis * Vector3(0.0, -0.45, 0.0))


# Turn Earth so Arecibo faces `toward` (a direction from Earth's centre).
func _face_arecibo(toward: Vector3, t: float) -> void:
	var dir := toward.normalized()
	var yaw := atan2(dir.x, dir.z)
	var pitch := asin(clampf(dir.y, -1.0, 1.0))
	earth.basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, deg_to_rad(ARECIBO.x) - pitch) * Basis(Vector3.UP, -deg_to_rad(ARECIBO.y))
	earth.clouds.rotation.y = 0.4 + 0.004 * (t - lift)


func update(t: float) -> void:
	RenderingServer.global_shader_parameter_set("song_time", t)
	PaletteScript.apply(_palette)
	var view := str(options.get("view", "side"))
	var body := _body_position(t)
	astronaut.position = body
	mascot.visible = false
	stars.visible = false
	sparks.visible = false
	var since := t - lift
	if view == "side":
		_place_side(t, body, since)
	elif view == "top":
		# The fist comes down slowly as he turns, floating.
		_float_pose(t, 1.0, 0.0, 1.0 - smoothstep(timeline.bar_time(38.0), timeline.bar_time(40.0), t))
		_hide_board()
		var rise: float = t - timeline.bar_time(38.0)
		astronaut.rotation = Vector3(-0.35, 0.9 + 0.05 * rise, 0.12)
		earth.position = body + Vector3(40.0, -1150.0, 60.0)
		camera.fov = 44.0
		camera.look_at_from_position(body + Vector3(0.6, 9.0 - rise * 0.22, 1.4), body + Vector3(0.0, 0.4, 0.0), Vector3.UP)
	elif view == "reveal":
		# From below: his glove rises, slowly, until it points straight up.
		var reach := smoothstep(timeline.bar_time(44.0), timeline.bar_time(45.8), t)
		_float_pose(t, 1.0, reach)
		_hide_board()
		var drift: float = t - timeline.bar_time(44.0)
		astronaut.rotation = Vector3(0.05, 0.4 + 0.02 * drift, 0.0)
		camera.fov = 36.0
		camera.look_at_from_position(body + Vector3(1.5 - drift * 0.05, -0.9 + drift * 0.04, 3.3), body + Vector3(0.25, 1.05, 0.0), Vector3.UP)
		_earth_behind(0.74)
	else:
		_place_touch(t, body)
	_face_arecibo(camera.global_position - earth.position, t)
	space.update(t, camera.global_position, _palette["ink"], _palette["accent"], 0.0)


# The jump: he springs off the board and, at the top of the spring, punches
# one fist up overhead. The camera rides up with him, a beat behind at
# first so he shoots up the frame, while Earth falls away below and shrinks.
# He turns his front, and the raised fist, toward the camera.
func _place_side(t: float, body: Vector3, since: float) -> void:
	var up := smoothstep(0.0, 1.2, since)
	# The punch: up fast, a little past, and settling.
	var punch := maxf(since - 0.35, 0.0)
	var fist := 1.0 - exp(-punch * 4.0) * cos(punch * 7.0)
	astronaut.rotation = Vector3(0.1 * up, 1.75 + 0.025 * since, -0.06 * up)
	_float_pose(t, up, 0.0, fist)
	_place_board(t)
	camera.fov = 42.0
	var s := maxf(since, 0.0)
	var follow := Vector3(0.0, RISE * s + JUMP * (1.0 - exp(-s / (JUMP_TIME * 2.2))), 0.0)
	var eye := follow + Vector3(5.6, 2.4 + 0.05 * s, 1.6)
	camera.look_at_from_position(eye, follow + Vector3(0.0, 0.45, 0.0), Vector3.UP)
	# Earth falls away: further and lower in the frame as he climbs.
	var away := 1.0 - exp(-s * 0.32)
	_earth_behind(lerpf(0.72, 0.62, away), lerpf(980.0, 1700.0, away), Vector3.ZERO)


# The touch. The mascot hangs above him, looking down, and slides its right
# arm out along a line from the upper right toward his raised glove. The gap
# closes fast at first and then ever more slowly, to nothing exactly at the
# drop, while the camera closes slowly from the pair to their hands. Then
# sparks and stars fly.
func _place_touch(t: float, body: Vector3) -> void:
	_float_pose(t, 1.0, 1.0)
	_hide_board()
	astronaut.rotation = Vector3(0.05, 0.46, 0.0)
	var glove := _glove()
	var line := Vector3(0.9, 0.75, 0.0).normalized()  # from the glove up to the mascot
	var start: float = timeline.bar_time(46.3)
	var u := clampf((t - start) / (touch - start), 0.0, 1.0)
	var s := 1.0 - pow(1.0 - u, 2.4)
	var full := float(MascotScript.ARM_CUBES) * MascotScript.P
	var root := glove + line * (full + (1.0 - s) * 1.6)
	var mascot_at := root + line * 0.35 + Vector3.UP * 0.25  # its body, near enough
	# The camera: below and in front, looking up; from the pair (his helmet
	# low left, the mascot up right) in to their hands, the mascot's face
	# still in the top of the frame.
	var cut: float = timeline.bar_time(46.0)
	var close := smoothstep(cut + 0.4, touch, t)
	close = close * close * (3.0 - 2.0 * close)
	var after := maxf(t - touch, 0.0)
	var helmet: Vector3 = astronaut.helmet.global_position + Vector3(0.0, 0.3, 0.0)
	var wide := helmet.lerp(mascot_at, 0.55)
	var target := wide.lerp(glove.lerp(mascot_at, 0.2), close)
	var eye := target + Vector3(-0.25, -1.0, 4.2).lerp(Vector3(0.6, -0.6, 2.4), close)
	eye += Vector3(0.0, 0.0, -0.12) * after
	var shake := Vector3(sin(t * 53.0), sin(t * 41.0), 0.0) * 0.008 * exp(-after * 6.0) * float(t >= touch)
	camera.fov = lerpf(38.0, 30.0, close)
	camera.look_at_from_position(eye + shake, target, Vector3.UP)
	# The mascot looks down at him, its face turned to the camera below.
	mascot.visible = true
	var to_camera := (eye - mascot_at).normalized()
	var to_helmet := (helmet - mascot_at).normalized()
	var facing := (to_camera * 0.6 + to_helmet * 0.4).normalized()
	mascot.basis = Basis.looking_at(-facing, Vector3.UP)
	# Its right arm points down the line at the glove, sliding out.
	mascot.point(false, s, mascot.basis.inverse() * -line)
	mascot.position = root - mascot.basis * mascot.arm_r.position
	mascot.hover(t * 2.0)
	# Sparks and the burst of stars, on the drop.
	if not stars.has_meta("burst"):
		stars.burst(touch, glove + line * 0.03, 40, 1.8)
		stars.set_meta("burst", true)
		sparks.burst(touch, glove + line * 0.03, 110, 3.4, 0.9)
	stars.visible = true
	sparks.visible = true
	stars.update(t)
	sparks.update(t)
	_earth_behind(0.76)
