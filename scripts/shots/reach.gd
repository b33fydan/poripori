extends Node3D

# The reach (song 1:03.5 to the drop at 1:35.3): the astronaut jumps off the
# board and floats up in slow motion from a massive voxel Earth, turned so
# the Caribbean (Arecibo, 18.34 N 66.75 W) faces the camera. Seen from:
#   view=rise    (bars 32-36 and 38-42, one continuous take either side of
#     FPV dive 1): a camera fixed in space above him. He springs off the
#     board, punches a fist up, and comes up from Earth toward the lens;
#     he passes it and keeps rising, the camera turning in place to follow.
#   view=over    (bars 44-46): third person from above and behind the
#     mascot, which hangs in space looking down; he comes up toward it,
#     glove raised, Earth far below.
#   view=touch   (bars 46-48.1): facing them both, the camera closes slowly on
#     their hands as the last of the gap closes: no telescoping arm, they
#     simply reach and touch, exactly on the drop's first kick. Sparks and
#     stars fly, and the film cuts away at once.
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
const RISE := 0.3                          # his steady rise, units per second
const JUMP := 1.6                          # how far the spring off the board carries him
const JUMP_TIME := 0.7                     # seconds: how fast that spring dies away
const RISE_CAMERA := Vector3(2.1, 6.1, 1.4)  # where the fixed camera hangs; he passes it near bar 39.6
const EARTH_BELOW := Vector3(-250.0, -1250.0, -350.0)  # Earth's centre in the rise view
const LINE := Vector3(0.9, 0.75, 0.0)       # from his glove up to the mascot
const GAP := 2.4                           # glove to the mascot's arm tip at bar 44

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
	var view := str(options.get("view", "rise"))
	var body := _body_position(t)
	astronaut.position = body
	mascot.visible = false
	stars.visible = false
	sparks.visible = false
	var since := t - lift
	if view == "rise":
		_place_rise(t, body, since)
	elif view == "over":
		_place_over(t)
	else:
		_place_touch(t)
	_face_arecibo(camera.global_position - earth.position, t)
	space.update(t, camera.global_position, _palette["ink"], _palette["accent"], 0.0)


# The fist: punched up at the top of the spring, up fast, a little past and
# settling; lowered while the second dive plays, before he reaches.
func _fist(t: float) -> float:
	var punch := maxf(t - lift - 0.35, 0.0)
	var up := 1.0 - exp(-punch * 4.0) * cos(punch * 7.0)
	return up * (1.0 - smoothstep(timeline.bar_time(42.0), timeline.bar_time(43.5), t))


# His left glove rises toward the mascot.
func _reach(t: float) -> float:
	return smoothstep(timeline.bar_time(43.5), timeline.bar_time(45.5), t)


# One fixed camera. He comes up from Earth toward it, turned to it and
# looking up; he passes it and keeps rising, and it turns in place to follow.
func _place_rise(t: float, body: Vector3, since: float) -> void:
	var s := maxf(since, 0.0)
	var up := smoothstep(0.0, 1.2, s)
	var near := smoothstep(16.0, 4.0, s)  # looking up at the lens as he comes
	astronaut.rotation = Vector3(-0.25 * near * up, 0.75 + 0.02 * s, 0.05 * up)
	_float_pose(t, up, 0.0, _fist(t))
	astronaut.helmet.rotation.x -= 0.3 * near * up
	_place_board(t)
	earth.position = EARTH_BELOW
	camera.fov = 46.0
	camera.look_at_from_position(RISE_CAMERA, body + Vector3(0.0, 0.8, 0.0), Vector3.UP)


# The touch's geometry, shared by the last two views so they agree: the
# mascot hangs on the line up from his glove, its right arm (at rest, not
# extended) pointing down the line, the gap from that arm's tip to the
# glove closing from GAP at bar 44 to nothing exactly at the drop, slowing
# all the way. It faces +Z, where the touch's camera is, tipped to look down
# at him, so its arm reaches out sideways and down and their hands meet
# clear of its body. Returns its body's centre.
func _place_mascot(t: float) -> Vector3:
	var glove := _glove()
	var line := LINE.normalized()
	var start: float = timeline.bar_time(44.0)
	var u := clampf((t - start) / (touch - start), 0.0, 1.0)
	var gap := GAP * pow(1.0 - u, 2.2)
	var tip := 2.0 * MascotScript.P
	var root := glove + line * (tip + gap)
	var centre := root + line * 0.4 + Vector3.UP * 0.1
	var helmet: Vector3 = astronaut.helmet.global_position + Vector3(0.0, 0.3, 0.0)
	var facing := ((helmet - centre).normalized() * 0.3 + Vector3(0.0, -0.25, 1.0).normalized() * 0.7).normalized()
	mascot.visible = true
	mascot.basis = Basis.looking_at(-facing, Vector3.UP)
	mascot.point(false, 0.0, mascot.basis.inverse() * -line)
	mascot.point(true, 0.0, Vector3(1.0, -0.3, 0.2))
	mascot.position = root - mascot.basis * mascot.arm_r.position
	mascot.hover(t * 2.0)
	return mascot.position + mascot.basis * Vector3(0.0, MascotScript.LEG * MascotScript.P + 0.3, 0.0)


# Floating, reaching up with his left glove; the board long gone.
func _pose_reaching(t: float) -> void:
	_float_pose(t, 1.0, _reach(t), _fist(t))
	_hide_board()
	astronaut.rotation = Vector3(0.05, 0.46, 0.0)


# Above and behind the mascot, looking down past it: he comes up toward it,
# glove raised, Earth far below.
func _place_over(t: float) -> void:
	_pose_reaching(t)
	var centre := _place_mascot(t)
	var helmet: Vector3 = astronaut.helmet.global_position
	var drift: float = t - timeline.bar_time(44.0)
	var eye := centre + Vector3(0.5, 1.8 - 0.04 * drift, -1.6 + 0.05 * drift)
	camera.fov = 50.0
	camera.look_at_from_position(eye, centre.lerp(helmet, 0.75), Vector3.UP)
	_earth_behind(0.42, 2300.0, Vector3.ZERO)


# The touch: facing them, from below, the camera closing from the pair to
# their hands by the drop. Sparks and stars fly on it; the cut comes a few
# frames later.
func _place_touch(t: float) -> void:
	_pose_reaching(t)
	var glove := _glove()
	var centre := _place_mascot(t)
	var cut: float = timeline.bar_time(46.0)
	var close := smoothstep(cut + 0.3, touch, t)
	close = close * close * (3.0 - 2.0 * close)
	var after := maxf(t - touch, 0.0)
	var helmet: Vector3 = astronaut.helmet.global_position + Vector3(0.0, 0.3, 0.0)
	var wide := helmet.lerp(centre, 0.5)
	var target := wide.lerp(glove.lerp(centre, 0.25), close)
	var eye := target + Vector3(-0.25, -0.9, 4.0).lerp(Vector3(-0.2, -0.85, 2.2), close)
	var shake := Vector3(sin(t * 53.0), sin(t * 41.0), 0.0) * 0.01 * exp(-after * 6.0) * float(t >= touch)
	camera.fov = lerpf(38.0, 30.0, close)
	camera.look_at_from_position(eye + shake, target, Vector3.UP)
	if not stars.has_meta("burst"):
		# Where the hands meet at the drop: here, carried up by his rise (his
		# pose no longer changes once the glove is up).
		var at := glove + LINE.normalized() * 0.03 + _body_position(touch) - _body_position(t)
		stars.burst(touch, at, 40, 1.8)
		sparks.burst(touch, at, 110, 3.4, 0.9)
		stars.set_meta("burst", true)
	stars.visible = true
	sparks.visible = true
	stars.update(t)
	sparks.update(t)
	_earth_behind(0.76)
