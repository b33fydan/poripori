extends Node3D

# The look sample, song time 0:06 to 0:26 of Lost in the Void.
#
# In the quiet intro the astronaut glides through the dark, side-on, and the
# camera drifts round from the visor to behind the board. The sculpture hangs
# far ahead, dark. On the first kick (bar 8, the start of groove_a) the rider
# crouches and springs, the trail bursts into colour, and the sculpture lights
# in a wave from its top row down, over two bars. Then they surf up toward it,
# carving on the bars, the rider bobbing on every beat.

const AstronautScript := preload("res://scripts/astronaut.gd")
const TrailScript := preload("res://scripts/cube_trail.gd")
const SpaceScript := preload("res://scripts/space.gd")
const SculptureScript := preload("res://scripts/message_sculpture.gd")

# Speeds in units per second: gliding, then surfing.
const GLIDE := 4.0
const SURF := 9.0
const CLIMB_GLIDE := 0.5
const CLIMB_SURF := 1.4
const SCULPTURE_AT := Vector3(18.0, 115.0, -700.0)
const SCULPTURE_PITCH := 5.6

var timeline
var camera: Camera3D
var astronaut: Node3D
var trail: Node3D
var space: Node3D
var sculpture: Node3D
var kick := 0.0      # the first kick: groove_a's first beat
var bar_length := 2.0


func setup(song_timeline) -> void:
	timeline = song_timeline
	kick = timeline.section_start("groove_a")
	bar_length = timeline.period * timeline.beats_per_bar
	space = SpaceScript.new()
	add_child(space)
	sculpture = SculptureScript.new(SCULPTURE_PITCH)
	sculpture.position = SCULPTURE_AT
	add_child(sculpture)
	astronaut = AstronautScript.new()
	add_child(astronaut)
	trail = TrailScript.new(rig_transform, trail_energy, trail_pulse, astronaut.tail_point)
	add_child(trail)
	camera = Camera3D.new()
	camera.fov = 50.0
	camera.near = 0.05
	camera.far = 3000.0
	add_child(camera)
	camera.make_current()


# --- Where the rig is -------------------------------------------------------------

# The integral of a smoothstep ramp from a to b: 0 before a, then easing into
# t - (a + b) / 2 after b. Speeds that ramp with it give a closed-form path.
func _ramp_integral(t: float, a: float, b: float) -> float:
	if t <= a:
		return 0.0
	if t >= b:
		return t - (a + b) * 0.5
	var u := (t - a) / (b - a)
	return (b - a) * (u * u * u - u * u * u * u * 0.5)


func _surf(t: float) -> float:
	return smoothstep(kick - 0.2, kick + 1.4, t)


func path_position(t: float) -> Vector3:
	var ramp := _ramp_integral(t, kick - 0.2, kick + 1.4)
	var forward := GLIDE * t + (SURF - GLIDE) * ramp
	var up := CLIMB_GLIDE * t + (CLIMB_SURF - CLIMB_GLIDE) * ramp
	# Carves: one slow S over four bars, wider once surfing.
	var carve := lerpf(0.7, 2.6, _surf(t)) * sin(TAU * timeline.bar(t) / 4.0)
	return Vector3(carve, up, -forward)


# The rig's frame: +X along the path, banked into each carve.
func rig_transform(t: float) -> Transform3D:
	var e := 0.02
	var p := path_position(t)
	var ahead := path_position(t + e)
	var behind := path_position(t - e)
	var x := (ahead - behind).normalized()
	var z := x.cross(Vector3.UP).normalized()
	var y := z.cross(x).normalized()
	var accel := (ahead - 2.0 * p + behind) / (e * e)
	var lean := clampf(accel.dot(z) * 0.12, -0.45, 0.45)
	y = (y + z * lean).normalized()
	z = x.cross(y).normalized()
	return Transform3D(Basis(x, y, z), p)


func trail_energy(t: float) -> float:
	return smoothstep(kick - 0.05, kick + 0.25, t)


func trail_pulse(t: float) -> float:
	return timeline.beat_pulse(t, 0.22) if t >= kick else 0.0


# --- Each frame ----------------------------------------------------------------------

func update(t: float) -> void:
	var rig := rig_transform(t)
	astronaut.transform = rig
	_pose_rider(t)
	trail.update(t)
	sculpture.update(t, kick, bar_length * 2.0, timeline.beat_pulse(t, 0.3) if t >= kick else 0.0)
	_place_camera(t, rig)
	space.update(t, camera.global_position, trail_energy(t), timeline.beat_pulse(t, 0.2))


func _pose_rider(t: float) -> void:
	var before := t - kick
	var glide_arms := Vector4(0.55, 0.15, -0.45, 0.15)
	var surf_arms := Vector4(1.2, 0.35, -0.95, 0.4)
	var crouch := 0.3 + 0.06 * sin(TAU * timeline.bar(t) / 2.0)
	var lean := 0.05
	var look := 0.55
	var arms := glide_arms
	var stretch := 1.0
	if before > -0.4 and before < 0.0:
		# Anticipation: a deep crouch, arms tucked, just before the kick.
		var u := smoothstep(-0.4, -0.05, before)
		crouch = lerpf(crouch, 1.0, u)
		lean = lerpf(lean, 0.38, u)
		arms = glide_arms.lerp(Vector4(0.25, 0.5, -0.2, 0.1), u)
		stretch = 1.0 - 0.07 * u
	elif before >= 0.0:
		# The spring, then the groove: a dip on every beat.
		var spring := exp(-before * 6.0)
		var settle := smoothstep(0.0, 0.5, before)
		crouch = lerpf(0.0, 0.42, settle) + 0.2 * timeline.beat_pulse(t, 0.32)
		lean = lerpf(0.0, 0.16, settle)
		look = lerpf(0.55, 0.9, settle)
		arms = Vector4(1.5, 0.45, -1.35, 0.55).lerp(surf_arms, settle)
		arms.x += 0.12 * sin(TAU * timeline.beat(t) / 2.0)
		stretch = 1.0 + 0.09 * spring * cos(before * 22.0)
	astronaut.pose(crouch, lean, look, arms)
	astronaut.rider.scale = Vector3(1.0 / sqrt(stretch), stretch, 1.0 / sqrt(stretch))
	# The antenna tip blinks on the bar in the intro, on the beat once surfing.
	var blink: float = timeline.bar_pulse(t, 0.4) if before < 0.0 else timeline.beat_pulse(t, 0.2)
	astronaut.antenna_tip.scale = Vector3.ONE * (1.0 + 0.6 * blink)


# The camera follows the path's general line, not each carve, so the rider
# carves left and right inside a steady frame.
func _place_camera(t: float, rig: Transform3D) -> void:
	var p := rig.origin
	# The path's level heading: the climb shows in the stars and the
	# sculpture sinking in frame, not in a camera that tilts up with it.
	var line := path_position(t + 0.3) - path_position(t - 0.3)
	line.x = 0.0
	line.y = 0.0
	var forward := line.normalized()
	var side := forward.cross(Vector3.UP).normalized()  # the rider's front
	var centre := Vector3(p.x * 0.55, p.y, p.z)
	var start := 6.0
	var into := smoothstep(start, kick - 0.3, t)
	var after := t - kick
	# The orbit: from in front of the visor round to just behind the rider's back.
	var angle := deg_to_rad(lerpf(118.0, 22.0, into))
	var distance := lerpf(3.6, 5.6, into)
	var height := lerpf(0.55, 1.4, into)
	if after >= 0.0:
		# A three-quarter chase from the rider's back side, so the trail
		# streams diagonally away across the frame instead of end-on.
		var swing := smoothstep(0.0, bar_length * 1.5, after)
		angle = deg_to_rad(lerpf(22.0, -24.0, swing) + 5.0 * sin(TAU * timeline.bar(t) / 8.0))
		distance = lerpf(5.6, 6.8, swing) - 0.25 * timeline.bar_pulse(t, 0.6)
		height = lerpf(1.4, 1.0, swing)
	var offset := (-cos(angle) * forward + sin(angle) * side) * distance + Vector3.UP * height
	var eye := centre + offset
	# Look at the rider early on; then ahead and up, past it to the sculpture.
	var at_rider := p + Vector3.UP * 0.75
	# Low and looking up past the rider: the sculpture towers over them.
	var ahead := centre + forward * 30.0 + side * 2.2 + Vector3.UP * 5.5
	var target := at_rider.lerp(ahead, smoothstep(kick - 2.5, kick + bar_length, t) * 0.85)
	# The kick lands with a small kick of the camera: a punch of FOV and a shake.
	var punch := exp(-maxf(after, 0.0) * 3.0) if after >= 0.0 else 0.0
	var shake := Vector3(sin(t * 61.0), sin(t * 47.0 + 1.3), 0.0) * 0.05 * punch
	camera.fov = 48.0 + 9.0 * punch + 2.0 * smoothstep(kick, kick + bar_length, t)
	camera.look_at_from_position(eye + shake, target, Vector3.UP)
