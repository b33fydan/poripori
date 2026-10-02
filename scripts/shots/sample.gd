extends Node3D

# The look sample, song time 0:06 to 0:26 of Lost in the Void, in the print
# style the owner chose from the FALL-LINIE reference.
#
# A ring of voxel tiles circles the message like Saturn's, passing just
# under the human figure. The astronaut surfs round it, riding the face of a
# swell that travels with him, painting a rainbow track on the tiles as it
# passes and kicking up cubes. In the quiet intro the ring is calm and the
# camera drifts from the visor round to behind; on the first kick (bar 8)
# the rider springs, the swell rises, the palette turns from the intro's
# night to the first chapter's, and the sculpture lights from the top down.

const AstronautScript := preload("res://scripts/astronaut.gd")
const SprayScript := preload("res://scripts/spray.gd")
const SpaceScript := preload("res://scripts/space.gd")
const SculptureScript := preload("res://scripts/message_sculpture.gd")
const RingScript := preload("res://scripts/saturn_ring.gd")
const PaletteScript := preload("res://scripts/palette.gd")
const InkShader := preload("res://shaders/ink.gdshader")

const PITCH := 1.2           # sculpture cube spacing: 88 units tall, ~58 riders
const RING_ROW := 55.0       # the ring passes through this (empty) row of the message
const RING_IN := 80.0
const RING_OUT := 135.0
const RING_GAP := Vector2(112.0, 115.0)
const TILE := 0.55
const TRACK_RADIUS := 98.0   # the rider's line round the ring
const CARVE := 4.0           # how far it weaves across the ring
const GLIDE := 3.0           # speeds along the ring, units per second
const SURF := 6.5
const SWELL_CALM := 0.25
const SWELL_HIGH := 1.15
const RIDE_HEIGHT := 0.12    # the board's deck above the tile tops
const FOV := 56.0

var options := {}
var timeline
var camera: Camera3D
var astronaut: Node3D
var spray: Node3D
var space: Node3D
var sculpture: Node3D
var ring: Node3D
var kick := 0.0
var bar_length := 2.0
var _palette_from := "intro"
var _palette_to := "numbers"


func setup(song_timeline) -> void:
	timeline = song_timeline
	kick = timeline.section_start("groove_a")
	bar_length = timeline.period * timeline.beats_per_bar
	if options.has("palette"):
		_palette_from = str(options["palette"])
		_palette_to = _palette_from
	space = SpaceScript.new()
	add_child(space)
	# The ring lies in the world's XZ plane at y = 0, round the y axis; the
	# sculpture stands on that axis with row RING_ROW at the ring's height.
	ring = RingScript.new(RING_IN, RING_OUT, RING_GAP, TILE)
	add_child(ring)
	sculpture = SculptureScript.new(PITCH)
	sculpture.position = Vector3(0.0, (RING_ROW - 36.0) * PITCH, 0.0)
	add_child(sculpture)
	astronaut = AstronautScript.new()
	add_child(astronaut)
	spray = SprayScript.new(rig_transform, spray_amount, ink_now, astronaut.tail_point, Vector3.UP)
	add_child(spray)
	camera = Camera3D.new()
	camera.fov = 58.0
	camera.near = 0.05
	camera.far = 6000.0
	add_child(camera)
	camera.make_current()
	_build_ink_pass()
	ring.paint(track, 0.0, float(options.get("to", "30")), 1.7)


# The ink outlines: a quad over the whole screen, drawn after everything.
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


# The board's place on the ring as (radius, angle): it weaves across the
# ring over four bars, and goes round at the gliding, then surfing, speed.
func track(t: float) -> Vector2:
	var distance := GLIDE * t + (SURF - GLIDE) * _ramp_integral(t, kick - 0.2, kick + 1.4)
	var radius := TRACK_RADIUS + lerpf(0.35, 1.0, _surf(t)) * CARVE * sin(TAU * timeline.bar(t) / 4.0)
	return Vector2(radius, distance / TRACK_RADIUS)


func swell_amplitude(t: float) -> float:
	return lerpf(SWELL_CALM, SWELL_HIGH, smoothstep(kick - 0.1, kick + timeline.period, t))


# The swell travels with the rider, who rides its face: a little up the face
# and down again over each two bars.
func swell_phase(t: float) -> float:
	var ride := -0.55 + 0.4 * sin(TAU * timeline.bar(t) / 2.0)
	return ring.swell_count * track(t).y - ride


func surface_point(t: float, radius: float, angle: float) -> Vector3:
	var h: float = ring.swell(radius, angle, swell_amplitude(t), swell_phase(t))
	return RingScript.polar(radius, angle, ring.tile_top() + h + RIDE_HEIGHT)


func board_position(t: float) -> Vector3:
	var at := track(t)
	return surface_point(t, at.x, at.y)


# The rig's frame: +X along the board's travel (up and down the swell), +Y
# the swell's surface normal, banked into each carve. The rider faces +Z,
# which points in toward the sculpture.
func rig_transform(t: float) -> Transform3D:
	var e := 0.02
	var p := board_position(t)
	var ahead := board_position(t + e)
	var behind := board_position(t - e)
	var x := (ahead - behind).normalized()
	var at := track(t)
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
	return Transform3D(Basis(x, y, z), p)


func spray_amount(t: float) -> float:
	return lerpf(0.25, 1.0, smoothstep(kick - 0.05, kick + 0.2, t))


func _palette_mix(t: float) -> float:
	if options.has("palette"):
		return 1.0
	return smoothstep(kick - 0.05, kick + timeline.period, t)


func ink_now(t: float) -> Color:
	return PaletteScript.current(_palette_from, _palette_to, _palette_mix(t), "ink")


# --- Each frame -----------------------------------------------------------------------

func update(t: float) -> void:
	RenderingServer.global_shader_parameter_set("song_time", t)
	PaletteScript.apply(_palette_from, _palette_to, _palette_mix(t))
	ring.set_swell(swell_amplitude(t), swell_phase(t))
	var rig := rig_transform(t)
	astronaut.transform = rig
	_pose_rider(t)
	spray.update(t)
	var paper := PaletteScript.current(_palette_from, _palette_to, _palette_mix(t), "paper")
	var ink := ink_now(t)
	var accent := PaletteScript.current(_palette_from, _palette_to, _palette_mix(t), "accent")
	var lit_at := kick if not options.has("palette") else -100.0
	sculpture.update(t, lit_at, bar_length * 2.0, timeline.beat_pulse(t, 0.3) if t >= kick else 0.0, paper.lerp(ink, 0.22))
	_place_camera(t, rig)
	space.update(t, camera.global_position, ink, accent, timeline.beat_pulse(t, 0.2) if t >= kick else 0.0)


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
	var blink: float = timeline.bar_pulse(t, 0.4) if before < 0.0 else timeline.beat_pulse(t, 0.2)
	astronaut.antenna_tip.scale = Vector3.ONE * (1.0 + 0.6 * blink)


# From behind the rider: the camera rides just outside the ring, looking in
# past the astronaut's back at the sculpture, as a surf shot looks past a
# surfer at the wave. The board slides across the frame (toward the left)
# and its rainbow track streams away to the right, round the ring.
# The sculpture turns to keep facing the camera, so it always reads right.
#
# In the intro the camera starts in front of the visor (inside the ring,
# looking out) and swings round behind the rider, revealing the sculpture
# just before the kick lights it.
func _place_camera(t: float, rig: Transform3D) -> void:
	var at := track(t)
	var after := t - kick
	# Trail the rider a little round the ring, so it sits left of centre
	# with open space behind it for the trail.
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
		distance = 7.0 - 0.3 * timeline.bar_pulse(t, 0.6)
		height = 1.7 + 0.25 * sin(TAU * timeline.bar(t) / 8.0)
	var offset := (outward * cos(swing) + forward * sin(swing)) * distance + Vector3.UP * height
	var eye := steady + offset
	# The framing: aim along the line to the sculpture's axis, pitched so the
	# rider sits low in frame and the sculpture's top just clears the top.
	var to_axis := Vector3(-eye.x, 0.0, -eye.z).normalized()
	var rider_drop := atan2((rig.origin.y + 0.8) - eye.y, Vector2(rig.origin.x - eye.x, rig.origin.z - eye.z).length())
	var pitch := rider_drop + deg_to_rad(FOV * 0.28)
	var framed := eye + (to_axis * cos(pitch) + Vector3.UP * sin(pitch)) * 50.0
	var at_rider := rig.origin + Vector3.UP * 0.75
	var target := at_rider.lerp(framed, smoothstep(kick - 2.0, kick + 0.2, t))
	var punch := exp(-maxf(after, 0.0) * 3.0) if after >= 0.0 else 0.0
	var shake := Vector3(sin(t * 61.0), sin(t * 47.0 + 1.3), 0.0) * 0.04 * punch
	camera.fov = FOV + 7.0 * punch
	camera.look_at_from_position(eye + shake, target, Vector3.UP)
	# The sculpture faces the camera; the moon hangs behind its upper part.
	var facing := atan2(eye.x, eye.z)
	sculpture.rotation = Vector3(0.0, facing, 0.0)
	# Aim at the message's upper rows (row 8), then nudge right of it: screen
	# right is against the direction of travel.
	var upper: Vector3 = sculpture.position + Vector3.UP * (36.0 - 8.0) * PITCH
	space.set_moon((upper - camera.global_position).normalized() - forward * 0.2 + Vector3.UP * 0.03, 0.1)
