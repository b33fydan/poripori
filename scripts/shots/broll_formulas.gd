extends Node3D

# B-roll for the DNA formulas (bars 26.5-31): a conveyor belt runs across a
# floating platform in the galaxy. Trays ride along it, each carrying one of
# the message's formula blocks (5 columns by 4 rows of bits, in reading order
# from rows 11-29). Four of the crew work the belt: as a tray passes each,
# they set in the next quarter of its cubes, and a finished tray pulses. In
# the background three more stand before a big readout of the whole section,
# studying it, one pointing. Fast motion, the camera dollying along the belt.

const AstronautScript := preload("res://scripts/astronaut.gd")
const PaletteScript := preload("res://scripts/palette.gd")
const Kit := preload("res://scripts/broll_kit.gd")

const BELT_Y := 0.62          # the belt's top: waist-high on the crew
const BELT_HALF := 13.0
const SPEED := 2.1            # the belt, units per second (fast motion)
const SPACING := 2.5
const BIT := 0.17             # a formula cube
const BIT_PITCH := 0.2
const WORKERS := [-6.0, -2.0, 2.0, 6.0]
const TRIMS := ["#e8735a", "#f2cf6b", "#3fc1c9", "#9b7be0", "#e87ba4", "#5e8ec7", "#5bbf7a"]
const READOUT_Z := -6.5
const READOUT_PITCH := 0.32

var options := {}
var timeline
var camera: Camera3D
var space: Node3D
var start := 0.0
var end := 0.0
var _palette: Dictionary
var _workers: Array = []
var _watchers: Array = []
var _formulas: Array = []     # each: Array of [column, row] lit within its 5x4 block
var _trays: Array = []        # [tray node, formula index]
var _bits: MultiMesh
var _bit_slots: Array = []    # [tray, cell index]
var _slats: MultiMesh
var _bit_color := Color.WHITE


func setup(song_timeline) -> void:
	timeline = song_timeline
	start = timeline.bar_time(26.5)
	end = timeline.bar_time(31.0)
	_palette = PaletteScript.colors("formulas")
	PaletteScript.apply(_palette)
	space = Kit.galaxy(self)
	Kit.platform(self, 15.5, 9.5, _tone("paper", "accent", 0.55), _tone("paper", "accent", 0.47), _tone("paper", "accent", 0.32), _tone("paper", "accent", 0.2), 11)
	_read_formulas()
	_build_belt()
	_build_trays()
	_build_readout()
	for j in range(WORKERS.size()):
		var worker := AstronautScript.new(Color(str(TRIMS[j])), false)
		worker.position = Vector3(float(WORKERS[j]), 0.0, -1.1)
		add_child(worker)
		_workers.append(worker)
		Kit.shadow_disc(self, worker.position, _tone("paper", "accent", 0.36))
	for j in range(3):
		var watcher := AstronautScript.new(Color(str(TRIMS[4 + j])), false)
		watcher.position = Vector3(-2.2 + j * 2.2, 0.0, READOUT_Z + 2.0)
		watcher.rotation.y = PI + (j - 1) * 0.25
		add_child(watcher)
		_watchers.append(watcher)
		Kit.shadow_disc(self, watcher.position, _tone("paper", "accent", 0.36))
	camera = Kit.camera(self, 48.0)


func _tone(a: String, b: String, amount: float) -> Color:
	return (_palette[a] as Color).lerp(_palette[b] as Color, amount)


# The formula blocks, in reading order: rows 11-14, 16-19, 21-24, 26-29,
# columns 0-4, 6-10, 12-16, 18-22. Empty blocks are skipped.
func _read_formulas() -> void:
	var all := Kit.bits()
	for top in [11, 16, 21, 26]:
		for left in [0, 6, 12, 18]:
			var lit := []
			for row in range(4):
				for column in range(5):
					if all[(top + row) * 23 + left + column] == "1":
						lit.append([column, row])
			if not lit.is_empty():
				_formulas.append(lit)


func _build_belt() -> void:
	var dark := _tone("paper", "accent", 0.22)
	Kit.block(self, Vector3(BELT_HALF * 2.0, 0.12, 1.1), Vector3(0.0, BELT_Y - 0.06, 0.0), dark)
	Kit.block(self, Vector3(BELT_HALF * 2.0, 0.2, 0.12), Vector3(0.0, BELT_Y - 0.1, 0.6), _tone("accent", "ink", 0.25))
	Kit.block(self, Vector3(BELT_HALF * 2.0, 0.2, 0.12), Vector3(0.0, BELT_Y - 0.1, -0.6), _tone("accent", "ink", 0.25))
	for x in range(-12, 13, 3):
		Kit.block(self, Vector3(0.18, BELT_Y - 0.12, 0.9), Vector3(x, (BELT_Y - 0.12) * 0.5, 0.0), _tone("paper", "accent", 0.3))
	# Slats that run with the belt, so it reads as moving.
	var slat := BoxMesh.new()
	slat.size = Vector3(0.08, 0.02, 1.0)
	var material := ShaderMaterial.new()
	material.shader = Kit.PrintShader
	slat.material = material
	_slats = MultiMesh.new()
	_slats.transform_format = MultiMesh.TRANSFORM_3D
	_slats.use_colors = true
	_slats.mesh = slat
	_slats.instance_count = 52
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = _slats
	add_child(instance)


func _build_trays() -> void:
	var count := int(ceil(BELT_HALF * 2.0 / SPACING)) + 4
	var total := 0
	for i in range(count):
		var f := i % _formulas.size()
		var tray := Kit.block(self, Vector3(1.25, 0.06, 0.6), Vector3.ZERO, _tone("accent", "ink", 0.2))
		_trays.append([tray, f])
		for c in range((_formulas[f] as Array).size()):
			_bit_slots.append([i, c])
		total += (_formulas[f] as Array).size()
	_bit_color = _tone("accent", "ink", 0.45)
	_bits = Kit.rim_cubes(self, BIT, total)


# The readout: the whole formula section as flat bright cells on a dark
# board, with the crew's "notes" (a few cells pulsing yellow) moving over it.
var _readout: MultiMesh
var _readout_cells: Array = []


func _build_readout() -> void:
	Kit.block(self, Vector3(23.0 * READOUT_PITCH + 0.6, 19.0 * READOUT_PITCH + 0.6, 0.15), Vector3(0.0, 4.1, READOUT_Z - 0.1), _tone("paper", "accent", 0.12))
	Kit.block(self, Vector3(0.25, 4.1, 0.25), Vector3(-3.2, 1.0, READOUT_Z - 0.1), _tone("paper", "accent", 0.3))
	Kit.block(self, Vector3(0.25, 4.1, 0.25), Vector3(3.2, 1.0, READOUT_Z - 0.1), _tone("paper", "accent", 0.3))
	_readout_cells = Kit.cells(11, 30)
	_readout = Kit.rim_cubes(self, READOUT_PITCH * 0.8, _readout_cells.size())


func _tray_x(i: int, t: float) -> float:
	var span := float(_trays.size()) * SPACING
	return fposmod((t - start) * SPEED - i * SPACING + span * 0.5, span) - span * 0.5


func update(t: float) -> void:
	RenderingServer.global_shader_parameter_set("song_time", t)
	PaletteScript.apply(_palette)
	Kit.edge_glow(timeline, t)
	var since := t - start
	var slat_color := _tone("accent", "ink", 0.35).srgb_to_linear()
	slat_color.a = 0.0
	for i in range(52):
		var x := fposmod(since * SPEED + i * 0.5, 26.0) - 13.0
		_slats.set_instance_transform(i, Transform3D(Basis(), Vector3(x, BELT_Y + 0.005, 0.0)))
		_slats.set_instance_color(i, slat_color)
	var tray_xs := []
	for i in range(_trays.size()):
		var x := _tray_x(i, t)
		tray_xs.append(x)
		(_trays[i][0] as Node3D).position = Vector3(x, BELT_Y + 0.03, 0.0)
	for s in range(_bit_slots.size()):
		var i: int = _bit_slots[s][0]
		var c: int = _bit_slots[s][1]
		var x: float = tray_xs[i]
		var lit: Array = _formulas[_trays[i][1]]
		var cell: Array = lit[c]
		# Each worker sets in a quarter of the cubes as the tray passes.
		var quarter := int(floor(c * 4.0 / lit.size()))
		var set_at := float(WORKERS[quarter]) + 0.25
		var since_set := (x - set_at) / SPEED
		if since_set < 0.0 or absf(x) > BELT_HALF - 0.4:
			Kit.hide_cube(_bits, s)
			continue
		var pop := 1.0 + 0.4 * exp(-since_set * 10.0) * cos(since_set * 25.0)
		var done := x > float(WORKERS[3]) + 0.6
		var p := Vector3(x + (int(cell[0]) - 2) * BIT_PITCH, BELT_Y + 0.12 + (3 - int(cell[1])) * BIT_PITCH, 0.0)
		Kit.set_cube(_bits, s, Transform3D(Basis().scaled(Vector3.ONE * pop), p), _bit_color, done, done and x < float(WORKERS[3]) + 0.75)
	_place_readout(t)
	_pose_workers(t, tray_xs)
	_pose_watchers(t)
	_place_camera(t)
	Kit.update_galaxy(space, t, since, camera, _palette)


func _place_readout(t: float) -> void:
	var color := _tone("ink", "accent", 0.3)
	# A band of rows the crew is "reading", moving down the board.
	var reading := fposmod((t - start) * 4.0, 22.0) - 1.5
	for i in range(_readout_cells.size()):
		var cell: Array = _readout_cells[i]
		var row := int(cell[0]) - 11
		var p := Vector3((int(cell[1]) - 11) * READOUT_PITCH, 4.1 + (9 - row) * READOUT_PITCH, READOUT_Z)
		Kit.set_cube(_readout, i, Transform3D(Basis(), p), color, absf(row - reading) < 1.5, true)


func _pose_workers(t: float, tray_xs: Array) -> void:
	for j in range(_workers.size()):
		var me: Node3D = _workers[j]
		var reach := 0.0
		var turn := 0.0
		for x in tray_xs:
			var d: float = float(x) - float(WORKERS[j])
			if absf(d) < 0.9:
				reach = maxf(reach, 1.0 - smoothstep(0.3, 0.9, absf(d)))
				turn = clampf(-d * 0.6, -0.5, 0.5)
		me.pose_on_foot(TAU * timeline.beat(t) * 0.5 + j, 0.06, reach, turn, 0.3 * reach)
		me.antenna_tip.scale = Vector3.ONE * (1.0 + 0.6 * timeline.beat_pulse(t, 0.2))


# Studying the readout: heads turning, shifting weight; the middle one points.
func _pose_watchers(t: float) -> void:
	for j in range(_watchers.size()):
		var me: Node3D = _watchers[j]
		var look := 0.35 * sin((t - start) * 1.7 + j * 2.0)
		me.pose_on_foot(0.0, 0.0, 0.0, look * 0.5, 0.0)
		me.helmet.rotation = Vector3(-0.35, look, 0.0)
		if j == 1:
			me.arm_r.rotation = Vector3(-2.3 + 0.2 * sin((t - start) * 3.0), 0.0, -0.2)
		me.antenna_tip.scale = Vector3.ONE * (1.0 + 0.6 * timeline.beat_pulse(t, 0.2))


# The hyperlapse move: along the belt, low and in front, the readout behind.
func _place_camera(t: float) -> void:
	var u := clampf((t - start) / (end - start), 0.0, 1.0)
	u = lerpf(u, smoothstep(0.0, 1.0, u), 0.3)
	var eye := Vector3(lerpf(-9.0, 6.0, u), lerpf(3.3, 3.9, u), lerpf(7.0, 6.2, u))
	camera.look_at_from_position(eye, Vector3(lerpf(-4.0, 3.0, u), 1.4, -1.8), Vector3.UP)
