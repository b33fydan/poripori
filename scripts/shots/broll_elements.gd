extends Node3D

# B-roll for the elements (bars 18-22): on a floating platform out in the
# galaxy stands a replica of that part of the message, its 17 cubes in their
# places (rows 5-9, columns 9-13 of the picture). A crew of six takes it
# apart in fast motion: one by one, top row first, a cube is pulled out,
# carried, and planted in the deck around them, where it sinks in, pulses,
# and a little plant sprouts from it (the owner's call). The camera glides
# round. A separate incident, it echoes the chapter without explaining it.
#
# The plants are the owner's MEGAVOX models; without the licensed files the
# cubes are planted bare.

const AstronautScript := preload("res://scripts/astronaut.gd")
const PaletteScript := preload("res://scripts/palette.gd")
const MegavoxScript := preload("res://scripts/megavox.gd")
const Kit := preload("res://scripts/broll_kit.gd")

const CREW := 6
const RING := 2.7             # where the crew stands round the replica
const CUBE := 0.9
const PITCH := 1.0
const EVERY := 0.4            # seconds between one cube and the next
const FIRST := 0.55           # the first pull, after the cut
const TRIMS := ["#e8735a", "#5bbf7a", "#f2cf6b", "#3fc1c9", "#e87ba4", "#5e8ec7"]
const PLANTS := ["Plant.003.glb", "Plant.011.glb", "Plant.017.glb", "Plant.024.glb", "Plant.031.glb", "Plant.038.glb",
	"Plant.045.glb", "Plant.052.glb", "Plant.059.glb", "Plant.066.glb", "Plant.073.glb", "Plant.080.glb",
	"Plant.087.glb", "Plant.094.glb", "Plant.008.glb", "Plant.020.glb", "Plant.042.glb"]

var options := {}
var timeline
var camera: Camera3D
var space: Node3D
var start := 0.0
var end := 0.0
var _palette: Dictionary
var _crew: Array = []
var _cells: Array = []        # [row, column], top row first
var _cubes: MultiMesh
var _plants: Array = []       # holder nodes (or null)
var _spots: Array = []        # where each cube is planted
var _cube_color := Color.WHITE


func setup(song_timeline) -> void:
	timeline = song_timeline
	start = timeline.bar_time(18.0)
	end = timeline.bar_time(22.0)
	_palette = PaletteScript.colors("elements")
	PaletteScript.apply(_palette)
	space = Kit.galaxy(self)
	Kit.platform(self, 9.5, 7.5, _tone("paper", "accent", 0.6), _tone("paper", "accent", 0.52), _tone("paper", "accent", 0.34), _tone("paper", "accent", 0.22), 7)
	_cells = Kit.cells(5, 10, 9, 14)
	_cube_color = _tone("accent", "ink", 0.55)
	_cubes = Kit.rim_cubes(self, CUBE, _cells.size())
	for j in range(CREW):
		var astronaut := AstronautScript.new(Color(str(TRIMS[j])), false)
		var angle := _crew_angle(j)
		astronaut.position = Vector3(sin(angle), 0.0, cos(angle)) * RING
		add_child(astronaut)
		_crew.append(astronaut)
		Kit.shadow_disc(self, astronaut.position, _tone("paper", "accent", 0.4))
	for k in range(_cells.size()):
		var j := k % CREW
		var round_index := k / CREW
		var angle := _crew_angle(j) + (0.42 if round_index % 2 == 0 else -0.42) * (1.0 + 0.3 * round_index)
		var radius := 4.1 + 0.9 * round_index
		_spots.append(Vector3(sin(angle) * radius, 0.0, cos(angle) * radius))
		var plant: Node3D = MegavoxScript.load_model("plants", str(PLANTS[k % PLANTS.size()]))
		var holder: Node3D = null
		if plant != null:
			MegavoxScript.print_look(plant, func(c: Color) -> Color: return c)
			holder = MegavoxScript.stand(plant, 1.0 + 0.6 * Kit.hash2(k, 3), 1.2)
			holder.position = _spots[k] + Vector3(0.0, CUBE * 0.5, 0.0)
			holder.rotation.y = Kit.hash2(k, 9) * TAU
			holder.scale = Vector3.ZERO
			add_child(holder)
		_plants.append(holder)
	camera = Kit.camera(self, 46.0)


func _tone(a: String, b: String, amount: float) -> Color:
	return (_palette[a] as Color).lerp(_palette[b] as Color, amount)


# The crew stands round the front and sides, so few are hidden behind it.
func _crew_angle(j: int) -> float:
	return deg_to_rad(-120.0 + j * 48.0)


func _home(k: int) -> Vector3:
	var cell: Array = _cells[k]
	return Vector3((int(cell[1]) - 11) * PITCH, (9 - int(cell[0])) * PITCH + CUBE * 0.5 + 0.05, 0.0)


func _pull_time(k: int) -> float:
	return start + FIRST + k * EVERY


func _hands(j: int) -> Vector3:
	var me: Node3D = _crew[j]
	return me.transform * me.hands_point(CUBE)


# Cube k: in the replica, pulled to its carrier's hands, held while they
# turn, tossed to its spot, sunk halfway into the deck. Returns
# [position, planted for how long (-1 before), spin].
func _cube_at(k: int, t: float) -> Array:
	var t0 := _pull_time(k)
	var j := k % CREW
	if t < t0:
		return [_home(k), -1.0, 0.0]
	var hands := _hands(j)
	if t < t0 + 0.3:
		var u := (t - t0) / 0.3
		return [_home(k).lerp(hands, u) + Vector3.UP * 0.6 * 4.0 * u * (1.0 - u), -1.0, u * 2.0]
	if t < t0 + 0.5:
		return [hands, -1.0, 0.0]
	var spot: Vector3 = _spots[k] + Vector3(0.0, CUBE * 0.05, 0.0)
	if t < t0 + 0.85:
		var u := (t - t0 - 0.5) / 0.35
		return [hands.lerp(spot, u) + Vector3.UP * 0.9 * 4.0 * u * (1.0 - u), -1.0, u * 3.0]
	return [spot, t - t0 - 0.85, 0.0]


func update(t: float) -> void:
	RenderingServer.global_shader_parameter_set("song_time", t)
	PaletteScript.apply(_palette)
	Kit.edge_glow(timeline, t)
	var since := t - start
	_pose_crew(t)
	for k in range(_cells.size()):
		var at: Array = _cube_at(k, t)
		var planted: float = at[1]
		var scale := 1.0
		if planted >= 0.0:
			scale = 1.0 - 0.3 * exp(-planted * 9.0) * cos(planted * 30.0)
		var spin := Basis(Vector3(0.3, 1.0, 0.2).normalized(), float(at[2]))
		var xf := Transform3D(spin.scaled(Vector3(1.0 / sqrt(scale), scale, 1.0 / sqrt(scale))), at[0])
		Kit.set_cube(_cubes, k, xf, _cube_color, planted >= 0.0, planted >= 0.0 and planted < 0.1)
		# The sprout: up out of the planted cube, overshooting, settling.
		var plant: Node3D = _plants[k]
		if plant != null:
			var grow := maxf(planted - 0.08, 0.0)
			var size := 0.0 if planted < 0.0 else 1.0 - exp(-grow * 7.0) * cos(grow * 9.0)
			plant.scale = Vector3.ONE * maxf(size, 0.0)
	_place_camera(t)
	Kit.update_galaxy(space, t, since, camera, _palette)


# Each of the crew faces the replica, reaches in for a cube, then turns to
# its spot and tosses it; between cubes they shuffle to the beat.
func _pose_crew(t: float) -> void:
	for j in range(CREW):
		var me: Node3D = _crew[j]
		var centre_yaw := atan2(-me.position.x, -me.position.z)
		var yaw := centre_yaw
		var reach := 0.0
		var bob := 0.0
		for k in range(j, _cells.size(), CREW):
			var rel := t - _pull_time(k)
			if rel > -0.2 and rel < 1.0:
				var to_spot: Vector3 = _spots[k] - me.position
				var spot_yaw := atan2(to_spot.x, to_spot.z)
				var turn := smoothstep(0.3, 0.55, rel) * (1.0 - smoothstep(0.85, 1.0, rel))
				yaw = lerp_angle(centre_yaw, spot_yaw, turn)
				reach = smoothstep(-0.2, 0.05, rel) * (1.0 - smoothstep(0.8, 0.95, rel))
				bob = 1.0 * exp(-maxf(rel - 0.3, 0.0) * 12.0) * smoothstep(0.25, 0.3, rel)
		me.rotation.y = yaw
		me.pose_on_foot(TAU * timeline.beat(t) * 0.5 + j, 0.14, reach, 0.0, bob)
		me.antenna_tip.scale = Vector3.ONE * (1.0 + 0.6 * timeline.beat_pulse(t, 0.2))


# The hyperlapse move: a slow arc round the front, rising a little.
func _place_camera(t: float) -> void:
	var u := clampf((t - start) / (end - start), 0.0, 1.0)
	u = lerpf(u, smoothstep(0.0, 1.0, u), 0.3)
	var angle := deg_to_rad(lerpf(-34.0, 30.0, u))
	var radius := lerpf(11.5, 10.5, u)
	var eye := Vector3(sin(angle) * radius, lerpf(3.6, 5.6, u), cos(angle) * radius)
	camera.look_at_from_position(eye, Vector3(0.0, lerpf(1.6, 0.9, u), 0.0), Vector3.UP)
