extends Node3D

# B-roll for the Solar System (bars 72-82): an FPV flight out in the galaxy,
# flying level and weaving between the planets from the outermost in, as
# the message has them (it was sent in 1974, so Pluto is there): Pluto,
# Neptune, Uranus, Saturn, Jupiter, Mars, Earth, Venus, Mercury, then the
# Sun. At each planet a little crew on a floating slab is assembling it,
# cubes streaming from their hands into its shell, so each is finished just
# as the drone passes. On bar 80 (the song's peak) the Sun flares, and the
# crew round it rush in and jump for joy. The flight is smooth: one long
# gentle sway, the view turning slowly, never a snap. The planets' cubes
# wear black borders.
#
# The planets are stylized (sizes and colours to be recognised, not to
# scale); only their order is the real one.

const AstronautScript := preload("res://scripts/astronaut.gd")
const PaletteScript := preload("res://scripts/palette.gd")
const Kit := preload("res://scripts/broll_kit.gd")

const CUBE := 0.56
const PITCH := 0.6
# [radius in cubes, colour, band colour (or ""), side of the path, height]
const PLANETS := [
	[2, "#c9b7a0", "", 1.0, 0.6],        # Pluto
	[4, "#3f6fe0", "#5a86ee", -1.0, -0.4],  # Neptune
	[4, "#7fd6e0", "", 1.0, 0.8],        # Uranus
	[5, "#e6c27a", "#cfa65c", -1.0, 0.2],   # Saturn (ringed)
	[6, "#d9a066", "#efd2a8", 1.0, -0.6],   # Jupiter
	[3, "#d9653b", "", -1.0, 0.5],       # Mars
	[3, "#3f86d9", "#4f9b4c", 1.0, -0.2],   # Earth (green land)
	[3, "#e8d08a", "", -1.0, 0.4],       # Venus
	[2, "#a8a29a", "", 1.0, -0.3],       # Mercury
]
const SUN_RADIUS := 9
const SATURN := 3
const PASS_FIRST := 0.9       # seconds into the shot the drone passes Pluto
const PASS_EVERY := 1.48
const SPEED := 9.5            # units a second, while flying
const BUILD_FOR := 3.2        # seconds a planet takes to assemble
const DONE_BEFORE := 0.9      # finished this long before the drone passes
const RING_CREW := 10
const TRIMS := ["#e8735a", "#5bbf7a", "#f2cf6b", "#3fc1c9", "#e87ba4", "#5e8ec7", "#9b7be0"]

var options := {}
var timeline
var camera: Camera3D
var space: Node3D
var start := 0.0
var flare := 0.0              # bar 80
var end := 0.0
var _palette: Dictionary
var _cubes: MultiMesh
var _cells: Array = []        # [position, appear time, colour, planet index (-1 the sun), source]
var _centres: Array = []
var _crews: Array = []        # [astronaut, planet index]
var _ring_crew: Array = []
var _rays: Array = []
var _sun_centre := Vector3.ZERO
var _stop_x := 0.0


func setup(song_timeline) -> void:
	timeline = song_timeline
	start = timeline.bar_time(72.0)
	flare = timeline.bar_time(80.0)
	end = timeline.bar_time(82.0)
	_palette = PaletteScript.colors("solar_system")
	PaletteScript.apply(_palette)
	space = Kit.galaxy(self, Vector3(0.2, 0.3, -0.93))
	_stop_x = _drone_x(flare)
	_sun_centre = Vector3(_stop_x - 15.0, 1.5, 0.0)
	for i in range(PLANETS.size()):
		var planet: Array = PLANETS[i]
		var r: int = planet[0]
		var pass_time := start + PASS_FIRST + i * PASS_EVERY
		var centre := Vector3(_drone_x(pass_time), float(planet[4]), float(planet[3]) * (r * PITCH + 3.6))
		_centres.append(centre)
		_add_crew(i, centre, r)
		_add_sphere(i, centre, r, pass_time - DONE_BEFORE - BUILD_FOR, pass_time - DONE_BEFORE)
		if i == SATURN:
			_add_ring(i, centre, r, pass_time - DONE_BEFORE - BUILD_FOR * 0.6, pass_time - DONE_BEFORE)
	_add_sun()
	_cubes = Kit.rim_cubes(self, CUBE, _cells.size())
	camera = Kit.camera(self, 70.0)


func _tone(a: String, b: String, amount: float) -> Color:
	return (_palette[a] as Color).lerp(_palette[b] as Color, amount)


# The drone's distance along the flight: level speed, easing to a stop at
# the flare in front of the Sun.
func _drone_x(t: float) -> float:
	var fly := clampf(t - start, 0.0, flare - start)
	var brake := 2.2
	var cruise := flare - start - brake
	var d := SPEED * minf(fly, cruise)
	if fly > cruise:
		var u := (fly - cruise) / brake
		d += SPEED * brake * (u - u * u * 0.5)
	return 150.0 - d


func _add_crew(i: int, centre: Vector3, r: int) -> void:
	# A small slab below and beside the planet, toward the path, with two of
	# the crew on it reaching up.
	var side: float = PLANETS[i][3]
	var slab_at := centre + Vector3(0.0, -r * PITCH - 1.3, -side * (r * PITCH * 0.6))
	Kit.block(self, Vector3(2.6, 0.3, 1.4), slab_at, _tone("paper", "accent", 0.45))
	for k in range(2):
		var astronaut := AstronautScript.new(Color(str(TRIMS[(i * 2 + k) % TRIMS.size()])), false)
		astronaut.position = slab_at + Vector3(-0.6 + k * 1.2, 0.15, 0.0)
		var to := centre - astronaut.position
		astronaut.rotation.y = atan2(to.x, to.z)
		add_child(astronaut)
		_crews.append([astronaut, i])


func _band(i: int, cell: Vector3i) -> Color:
	var planet: Array = PLANETS[i]
	var base := Color(str(planet[1]))
	var band := str(planet[2])
	if band == "":
		return base
	if i == 6:  # Earth: patches of land
		return Color(band) if Kit.hash2(cell.x * 7 + cell.y, cell.z * 3) > 0.62 else base
	return Color(band) if posmod(cell.y + 100, 3) == 0 else base


# A planet's shell of cubes, assembled from the bottom up between t0 and t1,
# each cube flying from one of its crew's hands.
func _add_sphere(i: int, centre: Vector3, r: int, t0: float, t1: float) -> void:
	var shell := []
	for x in range(-r, r + 1):
		for y in range(-r, r + 1):
			for z in range(-r, r + 1):
				var d := Vector3(x, y, z).length()
				if d <= r + 0.45 and d > r - 0.6:
					shell.append(Vector3i(x, y, z))
	shell.sort_custom(func(a: Vector3i, b: Vector3i) -> bool: return a.y < b.y or (a.y == b.y and Kit.hash2(a.x, a.z) < Kit.hash2(b.x, b.z)))
	for k in range(shell.size()):
		var cell: Vector3i = shell[k]
		var appear := lerpf(t0, t1, float(k) / shell.size())
		_cells.append([centre + Vector3(cell) * PITCH, appear, _band(i, cell), i, k % 2])


func _add_ring(i: int, centre: Vector3, r: int, t0: float, t1: float) -> void:
	var tilt := Basis(Vector3(0.3, 0.0, 1.0).normalized(), 0.35)
	var ring := []
	for x in range(-int(r * 2.3), int(r * 2.3) + 1):
		for z in range(-int(r * 2.3), int(r * 2.3) + 1):
			var d := Vector2(x, z).length()
			if d > r * 1.45 and d < r * 2.25:
				ring.append(Vector3(x, 0, z))
	for k in range(ring.size()):
		_cells.append([centre + tilt * (ring[k] * PITCH * 0.8), lerpf(t0, t1, Kit.hash2(k, 77)), Color("#e8d6a8"), i, k % 2])


# The Sun, already built when the drone arrives: its crew finishes it. It
# flares on bar 80.
func _add_sun() -> void:
	var r := SUN_RADIUS
	for x in range(-r, r + 1):
		for y in range(-r, r + 1):
			for z in range(-r, r + 1):
				var d := Vector3(x, y, z).length()
				if d <= r + 0.45 and d > r - 0.6:
					var c := Color("#ffc94a") if Kit.hash2(x * 5 + z, y) > 0.3 else Color("#ffad33")
					_cells.append([_sun_centre + Vector3(x, y, z) * PITCH, start, c, -1, 0])
	# A round deck below it, the ring crew round its rim.
	Kit.platform(self, 9.0, 9.0, _tone("paper", "accent", 0.5), _tone("paper", "accent", 0.42), _tone("paper", "accent", 0.3), _tone("paper", "accent", 0.18), 41)
	var deck := get_child(get_child_count() - 1) as Node3D
	deck.position = _sun_centre + Vector3(0.0, -r * PITCH - 2.2, 0.0)
	for j in range(RING_CREW):
		var astronaut := AstronautScript.new(Color(str(TRIMS[j % TRIMS.size()])), false)
		add_child(astronaut)
		_ring_crew.append(astronaut)
	# Rays for the flare: long flat bars round the Sun's face.
	for k in range(16):
		var ray := Kit.block(self, Vector3(0.35, 1.0, 0.1), _sun_centre, Color("#fff1b8"), true)
		ray.visible = false
		_rays.append(ray)


func update(t: float) -> void:
	RenderingServer.global_shader_parameter_set("song_time", t)
	PaletteScript.apply(_palette)
	Kit.edge_glow(timeline, t)
	var since := t - start
	var after := t - flare
	var flash := 0.0 if after < 0.0 else exp(-after * 2.5)
	for c in range(_cells.size()):
		var cell: Array = _cells[c]
		var planet: int = cell[3]
		var appear: float = cell[1]
		var age := t - appear
		if age < 0.0:
			Kit.hide_cube(_cubes, c)
			continue
		var p: Vector3 = cell[0]
		if planet < 0:
			# The Sun: flat and bright, swelling at the flare, beating after.
			var grow: float = 1.0 + 0.12 * flash + (0.04 * timeline.beat_pulse(t, 0.3) if after >= 0.0 else 0.0)
			p = _sun_centre + (p - _sun_centre) * grow
			Kit.set_cube(_cubes, c, Transform3D(Basis(), p), (cell[2] as Color).lerp(Color("#fff6d0"), flash * 0.7), after >= 0.0, true)
			continue
		var fly := 0.35
		if age < fly:
			var hands := _crew_hands(planet, int(cell[4]))
			var u := age / fly
			p = hands.lerp(p, u) + Vector3.UP * 1.2 * 4.0 * u * (1.0 - u)
		var pop := 1.0 + 0.3 * exp(-maxf(age - fly, 0.0) * 10.0) * float(age >= fly)
		Kit.set_cube_black(_cubes, c, Transform3D(Basis().scaled(Vector3.ONE * pop), p), cell[2])
	_pose_crews(t)
	_pose_ring_crew(t)
	_place_rays(t, after)
	_place_camera(t)
	Kit.update_galaxy(space, t, since, camera, _palette, 0.04)


func _crew_hands(planet: int, which: int) -> Vector3:
	var me: Node3D = _crews[planet * 2 + which][0]
	return me.transform * me.hands_point(CUBE)


func _pose_crews(t: float) -> void:
	for entry in _crews:
		var me: Node3D = entry[0]
		var i: int = entry[1]
		var pass_time := start + PASS_FIRST + i * PASS_EVERY
		var working := smoothstep(pass_time - DONE_BEFORE - BUILD_FOR - 0.4, pass_time - DONE_BEFORE - BUILD_FOR, t) * (1.0 - smoothstep(pass_time - DONE_BEFORE, pass_time - DONE_BEFORE + 0.3, t))
		var toss := 0.5 + 0.5 * sin(t * 20.0 + i)
		me.pose_on_foot(TAU * timeline.beat(t) * 0.5, 0.06, lerpf(0.0, 0.7 + 0.3 * toss, working), 0.0, 0.0)
		me.antenna_tip.scale = Vector3.ONE * (1.0 + 0.6 * timeline.beat_pulse(t, 0.2))


# The ring crew: round the Sun's deck finishing it, then on the flare they
# rush in toward it and jump for joy on every beat, arms up.
func _pose_ring_crew(t: float) -> void:
	var deck_y := _sun_centre.y - SUN_RADIUS * PITCH - 2.2
	var rush := smoothstep(flare - 0.3, flare + 0.9, t)
	for j in range(_ring_crew.size()):
		var me: Node3D = _ring_crew[j]
		var angle := TAU * j / _ring_crew.size() + 0.2
		var radius := lerpf(8.0, 6.0, rush)
		var hop := 0.0
		if t >= flare + 0.5:
			var phase: float = fposmod(timeline.beat(t) + j * 0.13, 1.0)
			hop = 0.9 * 4.0 * phase * (1.0 - phase)
		me.position = Vector3(_sun_centre.x + cos(angle) * radius, deck_y + hop, _sun_centre.z + sin(angle) * radius)
		var to := _sun_centre - me.position
		me.rotation.y = atan2(to.x, to.z)
		if t < flare + 0.5:
			me.pose_on_foot(rush * 14.0 + j, 0.4 * rush, 0.6 * (1.0 - rush), 0.0, 0.0)
		else:
			me.pose_on_foot(0.0, 0.0, 0.0, 0.0, 0.0)
			# Arms up, waving.
			var wave := 0.25 * sin(t * 12.0 + j)
			me.arm_l.rotation = Vector3(0.0, 0.0, 2.5 + wave)
			me.arm_r.rotation = Vector3(0.0, 0.0, -2.5 - wave)
			me.helmet.rotation.x = -0.35
		me.antenna_tip.scale = Vector3.ONE * (1.0 + 0.6 * timeline.beat_pulse(t, 0.2))


func _place_rays(t: float, after: float) -> void:
	var grow := 0.0 if after < 0.0 else 1.0 - exp(-after * 6.0) * cos(after * 9.0)
	var to_camera := (camera.global_position - _sun_centre).normalized()
	var face := Basis.looking_at(-to_camera, Vector3.UP)
	for k in range(_rays.size()):
		var ray: MeshInstance3D = _rays[k]
		ray.visible = after >= 0.0
		if not ray.visible:
			continue
		var angle := TAU * k / _rays.size() + after * 0.25
		var length: float = (3.5 + 1.5 * (k % 2)) * grow * (1.0 + 0.15 * timeline.beat_pulse(t, 0.3))
		var out := face * Vector3(cos(angle), sin(angle), 0.0)
		var reach: float = SUN_RADIUS * PITCH + 0.8 + length * 0.5
		ray.transform = Transform3D(face * Basis(Vector3.BACK, angle - PI * 0.5) * Basis.from_scale(Vector3(1.0, maxf(length, 0.01), 1.0)), _sun_centre + out * reach)


# The FPV: level, weaving between the planets on smooth curves with a light
# bank, braking to a stop before the Sun at the flare; then it holds,
# rising a little, the crew in the foreground.
func _drone(t: float) -> Vector3:
	var x := _drone_x(t)
	# One long, gentle sway, away from each planet as it passes (they sit on
	# alternate sides): its heading never turns more than about 12 degrees.
	# Gaussian swerves round each planet, and glancing at it, turned too
	# sharply (the owner found it hard on the eyes).
	var spacing := SPEED * PASS_EVERY
	var first: Vector3 = _centres[0]
	var sway := cos(PI * (first.x - x) / spacing)
	var z := -float(PLANETS[0][3]) * 1.0 * sway
	var y := 0.4 + 0.25 * sin(PI * (first.x - x) / (spacing * 2.0))
	var hold := smoothstep(flare - 2.0, end, t)
	return Vector3(x, lerpf(y, 2.0, hold), lerpf(z, 0.0, hold))


# The camera looks along its own path, measured over more than a second so
# the view turns slowly; no bank. Braking, it turns to the Sun.
func _place_camera(t: float) -> void:
	var p := _drone(t)
	var forward := _drone(t + 0.9) - _drone(t - 0.3)
	if forward.length() < 0.5:
		forward = Vector3.LEFT
	forward = forward.normalized()
	var settle := smoothstep(flare - 2.4, flare, t)
	settle = settle * settle * (3.0 - 2.0 * settle)
	var look := forward.lerp((_sun_centre - p).normalized(), settle).normalized()
	camera.fov = lerpf(80.0, 64.0, settle)
	camera.look_at_from_position(p, p + look * 10.0, Vector3.UP)
