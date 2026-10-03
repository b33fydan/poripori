extends Node3D

# The opening, song time 0:00 to 0:40 of Lost in the Void (and on into the
# next phrases once they are written).
#
# The message is a monolith so big that, up close, it is just a wall of
# blocks: each bit is a cube four riders tall. A ring like Saturn's circles
# it, and the ring descends the monolith through the film like a lift, from
# the top row down, so the message is never seen whole until the end. Rows
# light as the ring reaches them, and the ring (and the night) take the
# colour of the chapter it is passing: the numbers' silver first, then the
# elements' violet.
#
# In the quiet intro the ring is calm, the top rows hang dark, and the
# camera drifts from the astronaut's visor round behind it. On the first
# kick (bar 8) the rider springs, the swell rises and the top rows light.
# The descent's pace is set in bars, so chapter changes land on phrases.
#
# The monolith stands still (the owner's call): as the camera circles with
# the rider, it sees it from changing angles. It is turned to face the
# camera at FRONT_AT, so through this stretch it is seen at an angle, never
# edge-on or from behind.
#
# options: camera=follow swaps the wide chase for a close one right behind
# the board; camera=fpv1 and camera=fpv2 are the FPV drone dives down the
# monolith's face during the reach (the rider is away floating, so it and
# its board are hidden).
#
# camera=finale is the last shot (bar 95 to the end): far out, the whole
# monolith at last, every row lit (the last ones in a wave down from the
# ring), pulsing yellow, with Earth behind it. The rider and the mascot have
# flown on.
#
# The drop (bar 48) lands the astronaut back on the board at the human
# figure, with the mascot flying beside it from then on, leaving little
# stars. While the reach plays elsewhere, the ring descends to the human
# figure, and the rider is moved round the ring (bar 40, unseen) so the
# camera meets the monolith's front just after the drop.

const AstronautScript := preload("res://scripts/astronaut.gd")
const SprayScript := preload("res://scripts/spray.gd")
const SpaceScript := preload("res://scripts/space.gd")
const SculptureScript := preload("res://scripts/message_sculpture.gd")
const RingScript := preload("res://scripts/saturn_ring.gd")
const PaletteScript := preload("res://scripts/palette.gd")
const InkShader := preload("res://shaders/ink.gdshader")
const MascotScript := preload("res://scripts/mascot.gd")
const StarTrailScript := preload("res://scripts/star_trail.gd")
const EarthScript := preload("res://scripts/voxel_earth.gd")

const PITCH := 8.0           # a bit is a cube ~6.9 units across: four riders tall
const ROWS := 73
const RING_IN := 104.0       # clears the monolith's half-width (92) as it turns
const RING_OUT := 131.5      # 27.5 wide: half the first ring's width
const RING_GAP := Vector2(120.0, 121.5)
const TILE := 0.55
const TRACK_RADIUS := 112.0
const CARVE := 3.5
const GLIDE := 3.0           # speeds round the ring, units per second
const SURF := 6.5
const SWELL_CALM := 0.25
const SWELL_HIGH := 1.15
const RIDE_HEIGHT := 0.12
const FOV := 56.0
# The descent: [bar, the message row level with the ring]. Chapter edges
# (row 4.5 between numbers and elements, 10.5 before the formulas) fall on
# phrase downbeats: bar 16 and bar 24. Through the reach it drops fast to the
# human figure's feet (row 54.6) for the drop at bar 48, all but stops, then
# eases on into the Solar System's gold by bar 64.
const DESCENT := [[0.0, 1.0], [8.0, 2.6], [16.0, 4.5], [24.0, 10.5], [32.0, 18.0], [40.0, 34.0], [48.0, 54.6], [56.0, 55.6], [64.0, 59.0]]
const JUMP_BAR := 40.0       # the rider is moved round the ring here, unseen
const FRONT_AFTER_DROP := 6.4  # seconds after the drop the camera meets the front
const FRONT_AT := 38.0       # song time when the monolith faces the camera
# The board rides like a surfboard on water: nose up, rolled onto its
# toe-side rail, pivoting on that rail at the tail. The nose is up all the
# time (the owner asked): the swell may tip it by SLOPE_LIMIT at most, so it
# is always 9 to 15 degrees above level.
const NOSE_UP := 12.0
const SLOPE_LIMIT := 0.0524  # 3 degrees
const RAIL := 11.0
# The monolith's rims pulse in one yellow (the owner's call: the rainbow
# didn't blend), flaring on every beat.
const EDGE_YELLOW := Color("#ffd75e")

var options := {}
var timeline
var camera: Camera3D
var astronaut: Node3D
var spray: Node3D
var space: Node3D
var sculpture: Node3D
var ring: Node3D
var kick := 0.0
var drop := 0.0
var bar_length := 2.0
var mascot: Node3D
var stars: Node3D
var _row_lit := PackedFloat64Array()
var _angle_jump := 0.0
var _descent_slopes := PackedFloat64Array()
var earth: Node3D
var _finale := 0.0            # bar 95: the last shot


func setup(song_timeline) -> void:
	timeline = song_timeline
	kick = timeline.section_start("groove_a")
	drop = timeline.section_start("drop")
	bar_length = timeline.period * timeline.beats_per_bar
	_descent_slopes = _monotone_slopes()
	space = SpaceScript.new()
	add_child(space)
	sculpture = SculptureScript.new(PITCH)
	add_child(sculpture)
	ring = RingScript.new(RING_IN, RING_OUT, RING_GAP, TILE)
	add_child(ring)
	astronaut = AstronautScript.new()
	add_child(astronaut)
	spray = SprayScript.new(rig_transform, spray_amount, ink_now, ring_height, astronaut.tail_point, Vector3.UP)
	add_child(spray)
	mascot = MascotScript.new()
	add_child(mascot)
	stars = StarTrailScript.new(_star_source, _star_amount)
	add_child(stars)
	camera = Camera3D.new()
	camera.fov = FOV
	camera.near = 0.05
	camera.far = 6000.0
	add_child(camera)
	camera.make_current()
	_build_ink_pass()
	# Static: front toward where the camera rides at FRONT_AT (just outside
	# the rider's line).
	var front := track(FRONT_AT).y
	sculpture.rotation = Vector3(0.0, atan2(cos(front), sin(front)), 0.0)
	# After the jump the camera (trailing the rider) meets that front again
	# FRONT_AFTER_DROP seconds after the drop.
	var meet := drop + FRONT_AFTER_DROP
	_angle_jump = wrapf(front + 2.4 / TRACK_RADIUS - track(meet).y, -PI, PI)
	ring.paint(track, 0.0, float(options.get("to", "40")), 1.7)
	_row_lit = _row_light_times(float(options.get("to", "40")) + 30.0)
	_finale = timeline.bar_time(95.0)
	if str(options.get("camera", "")) == "finale":
		# The rows the ring never reached light in a wave as the shot opens.
		var first_dark := ROWS
		for row in range(ROWS):
			if _row_lit[row] > _finale:
				first_dark = mini(first_dark, row)
		for row in range(first_dark, ROWS):
			_row_lit[row] = _finale + 0.3 + 0.05 * (row - first_dark)
		# A big Earth, far behind the monolith (cubes 20 units across).
		earth = EarthScript.new(56, 20.0)
		add_child(earth)


func _build_ink_pass() -> void:
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.0, 1.0)
	var material := ShaderMaterial.new()
	material.shader = InkShader
	material.render_priority = 100
	mesh.material = material
	quad.mesh = mesh
	quad.extra_cull_margin = 16384.0
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	camera.add_child(quad)


# --- The descent ------------------------------------------------------------------

# The row level with the ring at song time t: a monotone cubic through
# DESCENT's keys (Fritsch-Carlson), so the lift never stops dead at a key
# and never overshoots one, even where it slows sharply (the drop).
func ring_row(t: float) -> float:
	var bar: float = timeline.bar(t)
	var keys := DESCENT
	var n := keys.size()
	if bar <= float(keys[0][0]):
		return float(keys[0][1])
	if bar >= float(keys[n - 1][0]):
		return float(keys[n - 1][1]) + (bar - float(keys[n - 1][0])) * _descent_slopes[n - 1]
	var i := 0
	while float(keys[i + 1][0]) < bar:
		i += 1
	var x0: float = keys[i][0]
	var x1: float = keys[i + 1][0]
	var y0: float = keys[i][1]
	var y1: float = keys[i + 1][1]
	var h := x1 - x0
	var u := (bar - x0) / h
	var u2 := u * u
	var u3 := u2 * u
	return (2.0 * u3 - 3.0 * u2 + 1.0) * y0 + (u3 - 2.0 * u2 + u) * h * _descent_slopes[i] + (-2.0 * u3 + 3.0 * u2) * y1 + (u3 - u2) * h * _descent_slopes[i + 1]


func _monotone_slopes() -> PackedFloat64Array:
	var keys := DESCENT
	var n := keys.size()
	var d := PackedFloat64Array()
	for k in range(n - 1):
		d.append((float(keys[k + 1][1]) - float(keys[k][1])) / (float(keys[k + 1][0]) - float(keys[k][0])))
	var m := PackedFloat64Array()
	m.resize(n)
	m[0] = d[0]
	m[n - 1] = d[n - 2]
	for k in range(1, n - 1):
		m[k] = 0.0 if d[k - 1] * d[k] <= 0.0 else (d[k - 1] + d[k]) * 0.5
	for k in range(n - 1):
		if d[k] == 0.0:
			m[k] = 0.0
			m[k + 1] = 0.0
			continue
		var a := m[k] / d[k]
		var b := m[k + 1] / d[k]
		if a * a + b * b > 9.0:
			var tau := 3.0 / sqrt(a * a + b * b)
			m[k] = tau * a * d[k]
			m[k + 1] = tau * b * d[k]
	return m


func row_height(row: float) -> float:
	return ((ROWS - 1) * 0.5 - row) * PITCH


func ring_height(t: float) -> float:
	return row_height(ring_row(t))


# When each row lights: the rows above the ring at the kick light in a wave
# from the top as it lands; every row after that lights as the ring comes
# level with it (half a row early, so it is lit as it arrives).
func _row_light_times(until: float) -> PackedFloat64Array:
	var times := PackedFloat64Array()
	times.resize(ROWS)
	var at_kick := ring_row(kick)
	for row in range(ROWS):
		if row <= at_kick:
			times[row] = kick + 0.09 * row
		else:
			times[row] = 1.0e9
			var t := kick
			while t < until:
				if ring_row(t) >= row - 0.5:
					times[row] = t
					break
				t += 1.0 / 60.0
	return times


# --- Where the rider is -------------------------------------------------------------

func _ramp_integral(t: float, a: float, b: float) -> float:
	if t <= a:
		return 0.0
	if t >= b:
		return t - (a + b) * 0.5
	var u := (t - a) / (b - a)
	return (b - a) * (u * u * u - u * u * u * u * 0.5)


func _surf(t: float) -> float:
	return smoothstep(kick - 0.2, kick + 1.4, t)


# The board's place in the ring as (radius, angle). At JUMP_BAR, while the
# reach plays elsewhere, it is moved round the ring by _angle_jump.
func track(t: float) -> Vector2:
	var distance := GLIDE * t + (SURF - GLIDE) * _ramp_integral(t, kick - 0.2, kick + 1.4)
	var radius := TRACK_RADIUS + lerpf(0.35, 1.0, _surf(t)) * CARVE * sin(TAU * timeline.bar(t) / 4.0)
	var jump := _angle_jump if timeline.bar(t) >= JUMP_BAR else 0.0
	return Vector2(radius, distance / TRACK_RADIUS + jump)


func swell_amplitude(t: float) -> float:
	return lerpf(SWELL_CALM, SWELL_HIGH, smoothstep(kick - 0.1, kick + timeline.period, t))


func swell_phase(t: float) -> float:
	var ride := -0.55 + 0.4 * sin(TAU * timeline.bar(t) / 2.0)
	return ring.swell_count * track(t).y - ride


func surface_point(t: float, radius: float, angle: float) -> Vector3:
	var h: float = ring.swell(radius, angle, swell_amplitude(t), swell_phase(t))
	return RingScript.polar(radius, angle, ring_height(t) + ring.tile_top() + h + RIDE_HEIGHT)


func board_position(t: float) -> Vector3:
	var at := track(t)
	return surface_point(t, at.x, at.y)


func rig_transform(t: float) -> Transform3D:
	var e := 0.02
	var p := board_position(t)
	# The way it heads, along the water as it is now: the ring's descent
	# carries the water down, and must not tip the nose down with it.
	var at := track(t)
	var at_ahead := track(t + e)
	var at_behind := track(t - e)
	var ahead := surface_point(t, at_ahead.x, at_ahead.y)
	var behind := surface_point(t, at_behind.x, at_behind.y)
	var x := (ahead - behind).normalized()
	# It rides the swell only a little, so the nose stays up all the time.
	var level := Vector3(x.x, 0.0, x.z).normalized()
	var slope := clampf(asin(clampf(x.y, -1.0, 1.0)) * 0.35, -SLOPE_LIMIT, SLOPE_LIMIT)
	x = level * cos(slope) + Vector3.UP * sin(slope)
	var d := 0.3
	var dr := surface_point(t, at.x + d, at.y) - surface_point(t, at.x - d, at.y)
	var da := surface_point(t, at.x, at.y + d / at.x) - surface_point(t, at.x, at.y - d / at.x)
	var normal := da.cross(dr).normalized()
	if normal.y < 0.0:
		normal = -normal
	var y := (normal - x * normal.dot(x)).normalized()
	var z := x.cross(y).normalized()
	var accel := (ahead - 2.0 * p + behind) / (e * e)
	var lean := clampf(accel.dot(z) * 0.1, -0.4, 0.4)
	y = (y + z * lean).normalized()
	z = x.cross(y).normalized()
	var xf := Transform3D(Basis(x, y, z), p)
	# Nose up and onto the rail, more of both once surfing; the tail's
	# inside rail stays where it was, on the water.
	var surf := _surf(t)
	var tilt := Basis(Vector3.BACK, deg_to_rad(NOSE_UP)) * Basis(Vector3.RIGHT, deg_to_rad(RAIL * lerpf(0.5, 1.0, surf)))
	var pivot: Vector3 = astronaut.rail_pivot
	return xf * Transform3D(tilt, pivot - tilt * pivot)


func spray_amount(t: float) -> float:
	return lerpf(0.25, 1.0, smoothstep(kick - 0.05, kick + 0.2, t))


# --- The palette ----------------------------------------------------------------------

# The intro's blue night until the kick; then the chapter the ring is passing.
func palette_at(t: float) -> Dictionary:
	var lit := smoothstep(kick - 0.05, kick + timeline.period, t)
	return PaletteScript.blend(PaletteScript.colors("intro"), PaletteScript.at_row(ring_row(t)), lit)


func ink_now(t: float) -> Color:
	return palette_at(t)["ink"]


# --- Each frame -----------------------------------------------------------------------

func update(t: float) -> void:
	RenderingServer.global_shader_parameter_set("song_time", t)
	var palette := palette_at(t)
	PaletteScript.apply(palette)
	ring.position = Vector3(0.0, ring_height(t), 0.0)
	ring.set_swell(swell_amplitude(t), swell_phase(t))
	var rig := rig_transform(t)
	astronaut.transform = rig
	_pose_rider(t)
	spray.update(t)
	var paper: Color = palette["paper"]
	var ink: Color = palette["ink"]
	var pulse: float = timeline.beat_pulse(t, 0.3) if t >= kick else 0.0
	sculpture.update(t, _row_lit, pulse, paper.lerp(ink, 0.2), paper)
	_set_edge_glow(t)
	var mode := str(options.get("camera", ""))
	var diving := mode.begins_with("fpv")
	var away := diving or mode == "finale"
	astronaut.visible = not away
	spray.visible = not away
	mascot.visible = not away and t >= drop
	stars.visible = mascot.visible
	if mascot.visible:
		mascot.transform = _mascot_transform(t)
		_pose_mascot(t)
		stars.update(t)
	if mode == "follow":
		_place_follow_camera(t, rig)
	elif diving:
		_place_fpv_camera(t, 1 if mode == "fpv1" else 2)
	elif mode == "finale":
		_place_finale_camera(t)
	else:
		_place_camera(t, rig)
	space.update(t, camera.global_position, ink, palette["accent"], timeline.beat_pulse(t, 0.2) if t >= kick else 0.0)


func _pose_rider(t: float) -> void:
	# The rider holds the groove's stance from the very start, arms open and
	# low, knees bent (the owner's call: upright with arms down looked
	# stiff). The kick springs it; the drop lands it back on the board.
	var before := t - (drop if t >= drop else kick)
	var surf_arms := Vector4(1.2, 0.35, -0.95, 0.4)
	# In the intro it breathes with the bar; from the kick it dips on the beat.
	var crouch := 0.42 + 0.06 * sin(TAU * timeline.bar(t) / 2.0)
	var lean := 0.16
	var look := lerpf(0.55, 0.9, smoothstep(6.0, kick - 0.5, t))
	var arms := surf_arms
	arms.x += 0.1 * sin(TAU * timeline.bar(t) / 2.0)
	arms.z -= 0.08 * sin(TAU * timeline.bar(t) / 2.0 + 1.0)
	var stretch := 1.0
	if before > -0.4 and before < 0.0:
		# Anticipation: a deep crouch, arms tucked, just before the kick.
		var u := smoothstep(-0.4, -0.05, before)
		crouch = lerpf(crouch, 1.0, u)
		lean = lerpf(lean, 0.38, u)
		arms = arms.lerp(Vector4(0.25, 0.5, -0.2, 0.1), u)
		stretch = 1.0 - 0.07 * u
	elif before >= 0.0:
		# The spring, then the groove: a dip on every beat.
		var spring := exp(-before * 6.0)
		var settle := smoothstep(0.0, 0.5, before)
		crouch = lerpf(0.0, 0.42, settle) + 0.2 * timeline.beat_pulse(t, 0.32)
		lean = lerpf(0.0, 0.16, settle)
		look = lerpf(0.55, 0.9, settle) if t < drop else 0.9
		arms = Vector4(1.5, 0.45, -1.35, 0.55).lerp(surf_arms, settle)
		arms.x += 0.12 * sin(TAU * timeline.beat(t) / 2.0)
		stretch = 1.0 + 0.09 * spring * cos(before * 22.0)
	astronaut.pose(crouch, lean, look, arms)
	astronaut.rider.scale = Vector3(1.0 / sqrt(stretch), stretch, 1.0 / sqrt(stretch))
	var blink: float = timeline.bar_pulse(t, 0.4) if before < 0.0 else timeline.beat_pulse(t, 0.2)
	astronaut.antenna_tip.scale = Vector3.ONE * (1.0 + 0.6 * blink)


# From behind the rider: the camera rides just outside the ring, looking in
# past the astronaut's back at the monolith. The board slides across the
# frame (toward the left) and its rainbow track streams away to the right.
# The monolith turns to keep facing the camera, so it always reads right.
#
# In the intro the camera starts in front of the visor (inside the ring,
# looking out) and swings round behind the rider, finding the dark wall of
# blocks just before the kick lights its top rows.
func _place_camera(t: float, rig: Transform3D) -> void:
	var at := track(t)
	var after := t - kick
	var into := smoothstep(6.0, kick - 0.15, t)
	var trail_angle := at.y - into * 2.4 / TRACK_RADIUS
	var outward := Vector3(cos(trail_angle), 0.0, sin(trail_angle))
	var forward := Vector3(-sin(trail_angle), 0.0, cos(trail_angle))
	var steady := RingScript.polar(lerpf(TRACK_RADIUS, at.x, 0.5), trail_angle, rig.origin.y)
	# Round the rider: 180 degrees is inside the ring facing the visor, 0 outside behind.
	var swing := deg_to_rad(lerpf(178.0, 0.0, into))
	var distance := lerpf(3.4, 7.0, into)
	var height := lerpf(0.7, 1.7, into)
	if after >= 0.0:
		distance = 7.0 - 0.3 * _hit(timeline.since_bar(t), 0.08, 0.6)
		height = 1.7 + 0.25 * sin(TAU * timeline.bar(t) / 8.0)
	var offset := (outward * cos(swing) + forward * sin(swing)) * distance + Vector3.UP * height
	var eye := steady + offset
	# The framing: aim along the line to the monolith's axis, pitched so the
	# rider sits low in frame with the wall of blocks rising behind.
	var to_axis := Vector3(-eye.x, 0.0, -eye.z).normalized()
	var rider_drop := atan2((rig.origin.y + 0.8) - eye.y, Vector2(rig.origin.x - eye.x, rig.origin.z - eye.z).length())
	var pitch := rider_drop + deg_to_rad(FOV * 0.28)
	var framed := eye + (to_axis * cos(pitch) + Vector3.UP * sin(pitch)) * 50.0
	var at_rider := rig.origin + Vector3.UP * 0.75
	var target := at_rider.lerp(framed, smoothstep(kick - 2.0, kick + 0.2, t))
	# The kick's punch rises over three frames rather than jumping in one
	# (a one-frame jump reads as a cut), then eases away.
	var punch := (_hit(after, 0.1, 1.0) if after >= 0.0 else 0.0) + _hit(t - drop, 0.1, 1.0)
	var shake := Vector3(sin(t * 61.0), sin(t * 47.0 + 1.3), 0.0) * 0.04 * punch
	camera.fov = FOV + 5.0 * punch
	camera.look_at_from_position(eye + shake, target, Vector3.UP)


# The lit monolith's rims and outlines: every cube's together, in yellow,
# flaring on the beat and easing to a glow. Nothing is lit before the kick.
func _set_edge_glow(t: float) -> void:
	var flare: float = timeline.beat_pulse(t, 0.35)
	var color := EDGE_YELLOW.srgb_to_linear()
	var strength := (0.55 + 0.45 * flare) * smoothstep(kick - 0.05, kick + 0.3, t)
	if t >= _finale and str(options.get("camera", "")) == "finale":
		strength = 0.3 + 0.9 * flare  # the widest pulse at the end, the colours showing between
	RenderingServer.global_shader_parameter_set("monolith_edge", Vector4(color.r, color.g, color.b, strength))


# A hit that rises over `attack` seconds and dies away over about `decay`.
func _hit(since: float, attack: float, decay: float) -> float:
	if since < 0.0:
		return 0.0
	return smoothstep(0.0, attack, since) * exp(-maxf(since - attack, 0.0) * 3.0 / decay)


# The close follow: tight behind the board's tail and a little outside it,
# over the astronaut's back shoulder, looking along the ring ahead with the
# monolith towering on the inside of the curve. It sits high enough that the
# spray passes below the lens, and banks a little with the board.
func _place_follow_camera(t: float, rig: Transform3D) -> void:
	var at := track(t)
	var forward := Vector3(-sin(at.y), 0.0, cos(at.y))
	var outward := Vector3(cos(at.y), 0.0, sin(at.y))
	var steady := RingScript.polar(lerpf(TRACK_RADIUS, at.x, 0.7), at.y, rig.origin.y)
	var eye := steady - forward * 3.9 + outward * 1.9 + Vector3.UP * (1.8 + 0.12 * sin(TAU * timeline.beat(t) / 2.0))
	var target := steady + forward * 9.0 - outward * 0.5 + Vector3.UP * 0.7
	camera.fov = 60.0
	var bank := rig.basis.y.dot(-outward) * 0.35
	camera.look_at_from_position(eye, target, (Vector3.UP + outward * bank).normalized())


# --- The mascot, after the drop -----------------------------------------------------

# Beside the rider, at its shoulder and above, on the camera's side. It
# flies forward (the owner asked): facing ahead, turned toward the camera
# just enough that its eyes show (they are on its front face), tipped forward
# into the flight with its arms swept back and its legs trailing. It bobs
# with the beat and banks gently.
func _mascot_frame(t: float) -> Array:
	var at := track(t)
	var forward := Vector3(-sin(at.y), 0.0, cos(at.y))
	var outward := Vector3(cos(at.y), 0.0, sin(at.y))
	var origin := board_position(t)
	var bob: float = 0.08 * sin(TAU * timeline.beat(t) * 0.5)
	if str(options.get("camera", "")) == "follow":
		# The follow camera rides behind the tail: there the mascot flies on
		# the inner side, a little ahead, clear of the lens.
		return [origin + forward * 0.5 - outward * 1.0 + Vector3.UP * (1.45 + bob), forward, -outward]
	return [origin - forward * 1.5 + outward * 0.5 + Vector3.UP * (1.35 + bob), forward, outward]


func _mascot_transform(t: float) -> Transform3D:
	var frame := _mascot_frame(t)
	var forward: Vector3 = frame[1]
	var facing := (forward * 0.75 + (frame[2] as Vector3) * 0.66).normalized()
	var basis := Basis.looking_at(-facing, Vector3.UP)
	# Bank into the curve, rocking with the phrase, then tip forward.
	basis = Basis(forward, 0.12 + 0.1 * sin(TAU * timeline.bar(t) / 4.0)) * basis
	basis = basis * Basis(Vector3.RIGHT, 0.42)
	return Transform3D(basis, frame[0])


func _pose_mascot(t: float) -> void:
	var beat: float = timeline.beat(t)
	mascot.hover(TAU * beat * 0.5, 0.55)
	var flap := 0.12 * sin(TAU * beat)
	mascot.point(true, 0.15, Vector3(1.0, -0.15 + flap, -0.75))
	mascot.point(false, 0.15, Vector3(-1.0, -0.15 + flap, -0.75))


func _star_source(t: float) -> Vector3:
	var frame := _mascot_frame(t)
	return (frame[0] as Vector3) - (frame[1] as Vector3) * 0.45 + Vector3.UP * 0.3


func _star_amount(t: float) -> float:
	return 1.0 if t >= drop else 0.0


# --- The FPV dives ----------------------------------------------------------------------

# An FPV drone diving down the monolith's face, smooth and locked in (the
# owner asked): it flies one straight line at a steady pitch, never rolls
# and never turns. The path is in the monolith's own frame (x along its rows
# toward the viewer's right, y up, z out of its face), so it follows the
# face however the monolith stands. Both pass down through the ring's hole.
# 1 (bars 36-38): from above the top rows, plunging down the face, gathering
#    speed.
# 2 (bars 42-44): closer, down past the rows to the human figure, easing
#    off at the end as it tips gently toward it (dark: the ring hasn't
#    reached it yet).
func _place_fpv_camera(t: float, dive: int) -> void:
	var a: float = timeline.bar_time(36.0 if dive == 1 else 42.0)
	var b: float = timeline.bar_time(38.0 if dive == 1 else 44.0)
	# Slow enough to read (the owner asked): about 40 units a second.
	var from := Vector3(-24.0, 315.0, 42.0) if dive == 1 else Vector3(12.0, 4.0, 26.0)
	var to := Vector3(-16.0, 160.0, 26.0) if dive == 1 else Vector3(-6.0, -84.0, 19.0)
	var u := clampf((t - a) / (b - a), 0.0, 1.0)
	# Speed: dive 1 gathers it from a running start; dive 2 sheds it at the end.
	u = lerpf(u, u * u, 0.3) if dive == 1 else lerpf(u, 1.0 - (1.0 - u) * (1.0 - u), 0.6)
	var face: Vector3 = sculpture.basis.z.normalized()
	var right: Vector3 = sculpture.basis.x.normalized()
	var to_world := func(q: Vector3) -> Vector3: return sculpture.position + right * q.x + Vector3.UP * q.y + face * q.z
	var eye: Vector3 = to_world.call(from.lerp(to, u))
	# One fixed pitch for the whole dive: down along the line of flight and
	# in toward the face, so the rows stream up the frame.
	var line: Vector3 = (to_world.call(to) - to_world.call(from)).normalized()
	var look := (line - face * 0.7).normalized()
	if dive == 2:
		# The gentle tip toward the human figure, over the last part.
		var human: Vector3 = to_world.call(Vector3(-16.0, -112.0, 0.0))
		look = look.slerp((human - eye).normalized(), 0.6 * smoothstep(0.5, 1.0, u))
	camera.fov = 100.0
	camera.look_at_from_position(eye, eye + look * 10.0, Vector3.UP)


# --- The last shot -------------------------------------------------------------------

# Far out in front of the monolith, pulling slowly back: the whole message
# stands there at last, the ring round it, Earth huge behind and below,
# turned so Arecibo faces us.
func _place_finale_camera(t: float) -> void:
	var u := clampf((t - _finale) / 4.0, 0.0, 1.0)
	var face: Vector3 = sculpture.basis.z.normalized()
	var right: Vector3 = sculpture.basis.x.normalized()
	var centre := Vector3(0.0, -10.0, 0.0)
	var eye := centre + face * lerpf(640.0, 790.0, smoothstep(0.0, 1.0, u)) + right * 60.0 + Vector3.UP * lerpf(-40.0, 10.0, u)
	camera.fov = 52.0
	camera.far = 9000.0
	camera.look_at_from_position(eye, centre, Vector3.UP)
	earth.position = centre - face * 2900.0 + right * 1350.0 - Vector3.UP * 1450.0
	var toward := (eye - earth.position).normalized()
	var yaw := atan2(toward.x, toward.z)
	var pitch := asin(clampf(toward.y, -1.0, 1.0))
	earth.basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, deg_to_rad(18.34) - pitch) * Basis(Vector3.UP, deg_to_rad(66.75))
	earth.clouds.rotation.y = 0.4 + 0.01 * (t - _finale)

