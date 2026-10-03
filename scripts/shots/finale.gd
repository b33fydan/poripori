extends Node3D

# The way home (bars 92-95, the outro's swell): Astro surfs up through the
# open galaxy with the mascot at his shoulder. The camera rides beside them,
# then falls back and finds the crew following in a wide V, each with a
# mascot of its own; it slows and lets them go, and they all shrink away
# into the galaxy, rainbow trails converging.

const AstronautScript := preload("res://scripts/astronaut.gd")
const MascotScript := preload("res://scripts/mascot.gd")
const StarTrailScript := preload("res://scripts/star_trail.gd")
const CubeTrailScript := preload("res://scripts/cube_trail.gd")
const PaletteScript := preload("res://scripts/palette.gd")
const Kit := preload("res://scripts/broll_kit.gd")

const SPEED := 9.0
const HEADING := Vector3(0.0, 0.32, -1.0)
const TRIMS := ["#5e8ec7", "#e8735a", "#5bbf7a", "#f2cf6b", "#3fc1c9", "#e87ba4", "#9b7be0", "#ffffff", "#ff9f43"]

var options := {}
var timeline
var camera: Camera3D
var space: Node3D
var start := 0.0
var end := 0.0
var _palette: Dictionary
var _riders: Array = []
var _mascots: Array = []
var _offsets: Array = []
var _trails: Array = []
var _stars: Array = []


func setup(song_timeline) -> void:
	timeline = song_timeline
	start = timeline.bar_time(92.0)
	end = timeline.bar_time(95.0)
	_palette = PaletteScript.colors("home")
	PaletteScript.apply(_palette)
	space = Kit.galaxy(self, Vector3(0.0, 0.95, 0.3))
	# Astro leads; the crew fans out behind in a V.
	_offsets.append(Vector3.ZERO)
	for k in range(1, 5):
		for side in [-1.0, 1.0]:
			_offsets.append(Vector3(side * 1.9 * k, -0.35 * k + 0.2 * Kit.hash2(k, int(side)), 2.6 * k))
	for i in range(_offsets.size()):
		var rider := AstronautScript.new(Color(str(TRIMS[i])), true)
		add_child(rider)
		_riders.append(rider)
		var mascot := MascotScript.new()
		add_child(mascot)
		_mascots.append(mascot)
		var index := i
		var trail := CubeTrailScript.new(func(t: float) -> Vector3: return _rider_xf(index, t) * Vector3(-0.8, -0.05, 0.0), func(_t: float) -> float: return 1.0, 0.12, 26.0, 1.2)
		add_child(trail)
		_trails.append(trail)
		var stars := StarTrailScript.new(func(t: float) -> Vector3: return _mascot_xf(index, t).origin - _forward() * 0.45, func(_t: float) -> float: return 1.0 if index == 0 else 0.5)
		add_child(stars)
		_stars.append(stars)
	camera = Kit.camera(self, 52.0)


func _forward() -> Vector3:
	return HEADING.normalized()


# Level speed, then a boost away into the distance over the last seconds.
func _travel(t: float) -> Vector3:
	var since := t - start
	var boost_at := (end - start) * 0.55
	var boost := maxf(since - boost_at, 0.0)
	return _forward() * (SPEED * since + 0.5 * 14.0 * boost * boost)


# Rider i's board: nose (+X) along the heading, rider facing +Z (its side),
# bobbing on its own phase.
func _rider_xf(i: int, t: float) -> Transform3D:
	var x := _forward()
	var y := (Vector3.UP - x * x.dot(Vector3.UP)).normalized()
	var basis := Basis(x, y, x.cross(y))
	var bob := Vector3.UP * 0.12 * sin(TAU * timeline.beat(t) * 0.5 + i * 0.9)
	var sway := Vector3.RIGHT * 0.15 * sin((t - start) * 1.3 + i * 1.7)
	return Transform3D(basis * Basis(Vector3.BACK, deg_to_rad(12.0)), _travel(t) + (_offsets[i] as Vector3) + bob + sway)


# Its mascot at its shoulder, on the camera's side, flying forward.
func _mascot_xf(i: int, t: float) -> Transform3D:
	var rider := _rider_xf(i, t)
	var forward := _forward()
	var right := forward.cross(Vector3.UP).normalized()
	# Astro's flies on his far side, clear of the camera beside him; the
	# crew's on their outer sides.
	var side := -1.0 if i == 0 else (1.0 if (_offsets[i] as Vector3).x > 0.0 else -1.0)
	var at := rider.origin + right * 0.75 * side - forward * 0.6 + Vector3.UP * (1.3 + 0.08 * sin(TAU * timeline.beat(t) * 0.5 + i))
	var facing := (forward * 0.8 + right * 0.6 * side).normalized()
	var basis := Basis.looking_at(-facing, Vector3.UP) * Basis(Vector3.RIGHT, 0.42)
	return Transform3D(basis, at)


func update(t: float) -> void:
	RenderingServer.global_shader_parameter_set("song_time", t)
	PaletteScript.apply(_palette)
	var since := t - start
	for i in range(_riders.size()):
		var rider: Node3D = _riders[i]
		rider.transform = _rider_xf(i, t)
		var arms := Vector4(1.2, 0.35, -0.95, 0.4)
		arms.x += 0.12 * sin(TAU * timeline.beat(t) / 2.0 + i)
		rider.pose(0.42 + 0.15 * timeline.beat_pulse(t, 0.32), 0.16, 0.9, arms)
		rider.antenna_tip.scale = Vector3.ONE * (1.0 + 0.6 * timeline.beat_pulse(t, 0.2))
		var mascot: Node3D = _mascots[i]
		mascot.transform = _mascot_xf(i, t)
		mascot.hover(TAU * timeline.beat(t) * 0.5 + i, 0.55)
		mascot.point(true, 0.15, Vector3(1.0, -0.15, -0.75))
		mascot.point(false, 0.15, Vector3(-1.0, -0.15, -0.75))
		_trails[i].update(t)
		_stars[i].update(t)
	_place_camera(t)
	Kit.update_galaxy(space, t, since, camera, _palette, 0.02)


# Beside Astro and the mascot first; then falling back and up to find the
# crew behind; then slowing to a stop, letting them all go.
func _place_camera(t: float) -> void:
	var u := clampf((t - start) / (end - start), 0.0, 1.0)
	# The camera travels with them, then brakes (its distance flown).
	var brake := 0.45
	var flown: float
	if u < brake:
		flown = u
	else:
		var v := (u - brake) / (1.0 - brake)
		flown = brake + (1.0 - brake) * (v - v * v * 0.5)
	var rig := _forward() * SPEED * (end - start) * flown
	# Ahead of the V at Astro's side, so the crew is out of sight at first;
	# then up over them and back.
	var beside := Vector3(3.6, 1.5, -1.2)
	var above := Vector3(1.5, 6.5, 6.0)
	var behind := Vector3(1.0, 5.0, 17.0)
	var lift := smoothstep(0.15, 0.6, u)
	var eye := rig + beside.lerp(above, lift).lerp(above.lerp(behind, lift), lift)
	var leader := _rider_xf(0, t).origin + Vector3(0.0, 0.7, 0.0)
	var crew_centre := leader + Vector3(0.0, -0.6, 4.5)
	var target := leader.lerp(crew_centre, smoothstep(0.2, 0.55, u))
	target = target.lerp(leader + _forward() * 6.0, smoothstep(0.6, 1.0, u))
	camera.look_at_from_position(eye, target, Vector3.UP)
