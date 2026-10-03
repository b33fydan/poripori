extends Node3D

# B-roll for the human (bars 64-72, the song's calm break): a lab on a
# floating platform in the galaxy. A crew works a row of stations, moving
# along to the next one every two bars. In front of them a huge glass
# window; beyond it a giant astronaut lies asleep on a slab, breathing
# slowly, and beside it stands the message's human figure in cubes. A scan
# line sweeps up and down over both, as if the crew were comparing the
# figure with the sleeper. The camera drifts along behind the crew.

const AstronautScript := preload("res://scripts/astronaut.gd")
const PaletteScript := preload("res://scripts/palette.gd")
const Kit := preload("res://scripts/broll_kit.gd")

const STATIONS := [-5.0, -2.5, 0.0, 2.5, 5.0]
const CREW := 4
const DESK_Z := -2.6
const GLASS_Z := -4.2
const GIANT := 3.0            # the sleeper's scale
const FIGURE_CUBE := 0.42
const SWITCH_BARS := 2.0
const TRIMS := ["#5e8ec7", "#5bbf7a", "#f2cf6b", "#3fc1c9"]

var options := {}
var timeline
var camera: Camera3D
var space: Node3D
var start := 0.0
var end := 0.0
var _palette: Dictionary
var _crew: Array = []
var _giant: Node3D
var _figure: MultiMesh
var _figure_cells: Array = []
var _scan: MeshInstance3D
var _screens: MultiMesh
var _bits := ""
var _figure_color := Color.WHITE


func setup(song_timeline) -> void:
	timeline = song_timeline
	start = timeline.bar_time(64.0)
	end = timeline.bar_time(72.0)
	_palette = PaletteScript.colors("human")
	PaletteScript.apply(_palette)
	space = Kit.galaxy(self)
	Kit.platform(self, 11.0, 9.5, _tone("paper", "accent", 0.5), _tone("paper", "accent", 0.43), _tone("paper", "accent", 0.3), _tone("paper", "accent", 0.18), 31)
	_bits = Kit.bits()
	_build_lab()
	_build_beyond()
	for j in range(CREW):
		var astronaut := AstronautScript.new(Color(str(TRIMS[j])), false)
		astronaut.rotation.y = PI
		add_child(astronaut)
		_crew.append(astronaut)
	camera = Kit.camera(self, 44.0)


func _tone(a: String, b: String, amount: float) -> Color:
	return (_palette[a] as Color).lerp(_palette[b] as Color, amount)


func _build_lab() -> void:
	var desk := _tone("paper", "accent", 0.28)
	var frame := _tone("paper", "accent", 0.14)
	for x in STATIONS:
		Kit.block(self, Vector3(1.5, 0.72, 0.6), Vector3(x, 0.36, DESK_Z), desk)
		var screen := Kit.block(self, Vector3(1.1, 0.72, 0.06), Vector3(x, 1.12, DESK_Z - 0.12), frame)
		screen.rotation.x = 0.22
	_screens = Kit.rim_cubes(self, 0.13, STATIONS.size() * 20)
	# The window: a frame of heavy bars round a faint pane, with glints.
	var bar := _tone("accent", "ink", 0.3)
	Kit.block(self, Vector3(15.0, 0.3, 0.3), Vector3(0.0, 5.2, GLASS_Z), bar)
	Kit.block(self, Vector3(15.0, 0.3, 0.3), Vector3(0.0, 0.15, GLASS_Z), bar)
	for x in [-7.35, -2.45, 2.45, 7.35]:
		Kit.block(self, Vector3(0.3, 5.35, 0.3), Vector3(x, 2.65, GLASS_Z), bar)
	var pane := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(14.7, 5.0)
	var glass := StandardMaterial3D.new()
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(_palette["ink"], 0.08)
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	quad.material = glass
	pane.mesh = quad
	pane.position = Vector3(0.0, 2.65, GLASS_Z)
	add_child(pane)
	for g in range(5):
		var glint := Kit.block(self, Vector3(0.08, 1.6, 0.02), Vector3(-6.0 + g * 3.1, 3.4, GLASS_Z + 0.17), _tone("ink", "paper", 0.15), true)
		glint.rotation.z = 0.6


# Beyond the glass: the sleeper on its slab, the figure, the scan line.
func _build_beyond() -> void:
	Kit.block(self, Vector3(5.2, 0.8, 2.4), Vector3(-2.6, 0.4, -7.6), _tone("accent", "ink", 0.2))
	_giant = AstronautScript.new(Color("#ee5a5a"), false, true)
	# Lying on its back along the slab, head to the left, rolled toward the
	# window so its sleeping face shows; its backpack rests on the slab.
	_giant.basis = (Basis(Vector3.RIGHT, 0.85) * Basis(Vector3.UP, PI * 0.5) * Basis(Vector3.RIGHT, -PI * 0.5)).scaled(Vector3.ONE * GIANT)
	_giant.position = Vector3(-0.3, 0.8 + 5.5 * AstronautScript.U * GIANT, -7.9)
	add_child(_giant)
	_giant.pose_on_foot(0.0, 0.0, 0.0)
	_figure_cells = Kit.cells(45, 55, 5, 16)
	_figure_color = Color("#ff6464").lerp(_palette["ink"], 0.2)
	_figure = Kit.rim_cubes(self, FIGURE_CUBE * 0.9, _figure_cells.size())
	for i in range(_figure_cells.size()):
		var cell: Array = _figure_cells[i]
		var p := Vector3(3.6 + (int(cell[1]) - 10) * FIGURE_CUBE, (54 - int(cell[0])) * FIGURE_CUBE + FIGURE_CUBE * 0.5, -7.6)
		Kit.set_cube(_figure, i, Transform3D(Basis(), p), _figure_color, false)
	_scan = Kit.block(self, Vector3(10.5, 0.05, 2.8), Vector3(0.6, 1.0, -7.6), Color("#ffd75e"), true)


# Where crew member j stands at song time t: at a station, or walking to the
# next. Every SWITCH_BARS they all move on one; the one at the end walks
# round behind the others back to the first.
func _crew_place(j: int, t: float) -> Array:
	var period: float = SWITCH_BARS * timeline.period * timeline.beats_per_bar
	var since := t - start
	var n := int(floor(since / period))
	var into := since - n * period
	var a: int = posmod(j + n, STATIONS.size())
	var b: int = posmod(j + n + 1, STATIONS.size())
	var stand_z := DESK_Z + 0.75
	var from := Vector3(float(STATIONS[a]), 0.0, stand_z)
	var to := Vector3(float(STATIONS[b]), 0.0, stand_z)
	var walk := smoothstep(period - 1.3, period - 0.1, into)
	if walk <= 0.0:
		return [from, false, 0.0, 0.0]
	var p := from.lerp(to, walk)
	if b < a:
		# Round the back of the line.
		p.z += 1.4 * sin(PI * walk)
	return [p, true, walk, signf(to.x - from.x)]


func update(t: float) -> void:
	RenderingServer.global_shader_parameter_set("song_time", t)
	PaletteScript.apply(_palette)
	Kit.edge_glow(timeline, t)
	var since := t - start
	for j in range(CREW):
		var me: Node3D = _crew[j]
		var at: Array = _crew_place(j, t)
		me.position = at[0]
		if at[1]:
			me.rotation.y = PI * 0.5 * float(at[3])
			me.pose_on_foot(float(at[2]) * 18.0, 0.5, 0.0, 0.0, 0.0)
		else:
			me.rotation.y = PI
			var tap := sin(since * 24.0 + j * 1.9)
			me.pose_on_foot(0.0, 0.0, 0.55, 0.0, 0.4)
			me.arm_l.rotation.x += 0.07 * tap
			me.arm_r.rotation.x -= 0.07 * tap
			var look := smoothstep(0.5, 0.9, sin(since * 0.9 + j * 1.4))
			me.helmet.rotation = Vector3(0.2 - 0.45 * look, 0.0, 0.0)
		me.antenna_tip.scale = Vector3.ONE * (1.0 + 0.6 * timeline.beat_pulse(t, 0.2))
	# The sleeper breathes.
	_giant.torso.scale = Vector3(1.0, 1.0, 1.0 + 0.04 * sin(since * 1.6))
	# The scan sweeps up and down over both, every two bars.
	var sweep: float = 0.5 - 0.5 * cos(TAU * timeline.bar(t) / 4.0)
	_scan.position.y = lerpf(0.9, 4.7, sweep)
	for i in range(_figure_cells.size()):
		var cell: Array = _figure_cells[i]
		var y := (54 - int(cell[0])) * FIGURE_CUBE + FIGURE_CUBE * 0.5
		var p := Vector3(3.6 + (int(cell[1]) - 10) * FIGURE_CUBE, y, -7.6)
		Kit.set_cube(_figure, i, Transform3D(Basis(), p), _figure_color, absf(y - _scan.position.y) < 0.5)
	_place_screens(t)
	_place_camera(t)
	Kit.update_galaxy(space, t, since, camera, _palette, 0.03)


func _place_screens(t: float) -> void:
	var cell_color := _tone("ink", "accent", 0.2)
	var n := 0
	for s in range(STATIONS.size()):
		var scroll := int(floor((t - start) * 3.0)) + s * 7
		for r in range(4):
			for c in range(5):
				var lit := _bits[posmod(scroll + r + 45, 73) * 23 + (s * 3 + c) % 23] == "1" or Kit.hash2(scroll + r, c + s * 13) > 0.62
				if lit:
					var p := Vector3(float(STATIONS[s]) + (c - 2) * 0.18, 1.12 + (1.5 - r) * 0.15, DESK_Z - 0.07)
					Kit.set_cube(_screens, n, Transform3D(Basis(Vector3.RIGHT, 0.22).scaled(Vector3(1.0, 1.0, 0.25)), p), cell_color, false, true)
				else:
					Kit.hide_cube(_screens, n)
				n += 1


# A slow drift along behind the crew, looking through the glass.
func _place_camera(t: float) -> void:
	var u := clampf((t - start) / (end - start), 0.0, 1.0)
	u = smoothstep(0.0, 1.0, u)
	var eye := Vector3(lerpf(-5.5, 5.0, u), lerpf(3.0, 3.4, u), 5.6)
	camera.look_at_from_position(eye, Vector3(lerpf(-2.0, 2.2, u), 2.0, -5.5), Vector3.UP)
