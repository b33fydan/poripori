extends Node3D

# B-roll for the DNA helix (bars 54-58): a ring of computer stations on a
# floating platform in the galaxy, a crew member at each, typing, looking up.
# In the middle a double helix of cubes materialises from the deck up: two
# strands winding round, joined by rungs, each cube popping in as the build
# climbs; the strands pulse in yellow once placed, the rungs wear white
# borders. Their screens scroll with patterns. The camera rises with it.

const AstronautScript := preload("res://scripts/astronaut.gd")
const PaletteScript := preload("res://scripts/palette.gd")
const Kit := preload("res://scripts/broll_kit.gd")

const STATIONS := 6
const STATION_RING := 5.0
const HEIGHT := 7.6           # the finished helix
const RADIUS := 1.15
const STEP := 0.26            # strand cubes, every STEP up
const TURN := 3.4             # height of one full turn
const RUNG_EVERY := 3         # a rung every third strand step
const CUBE := 0.3
const BUILD_FROM := 0.35      # seconds into the shot
const BUILD_FOR := 6.4
const TRIMS := ["#e8735a", "#5bbf7a", "#f2cf6b", "#9b7be0", "#e87ba4", "#3fc1c9"]
const SCREEN_COLUMNS := 5
const SCREEN_ROWS := 4

var options := {}
var timeline
var camera: Camera3D
var space: Node3D
var start := 0.0
var end := 0.0
var _palette: Dictionary
var _crew: Array = []
var _helix: MultiMesh
var _pieces: Array = []       # [position, appear time, strand?]
var _screens: MultiMesh
var _screen_frames: Array = []  # each station's screen transform
var _bits := ""
var _strand_color := Color.WHITE
var _rung_color := Color.WHITE


func setup(song_timeline) -> void:
	timeline = song_timeline
	start = timeline.bar_time(54.0)
	end = timeline.bar_time(58.0)
	_palette = PaletteScript.colors("dna")
	PaletteScript.apply(_palette)
	space = Kit.galaxy(self)
	Kit.platform(self, 9.0, 9.0, _tone("paper", "accent", 0.55), _tone("paper", "accent", 0.47), _tone("paper", "accent", 0.32), _tone("paper", "accent", 0.2), 23)
	_bits = Kit.bits()
	_strand_color = Color("#5ab4ff").lerp(_palette["ink"], 0.25)
	_rung_color = _tone("accent", "ink", 0.6)
	_plan_helix()
	_helix = Kit.rim_cubes(self, CUBE, _pieces.size())
	# A low plinth the helix grows from.
	Kit.block(self, Vector3(3.4, 0.16, 3.4), Vector3(0.0, 0.08, 0.0), _tone("paper", "accent", 0.3))
	_build_stations()
	camera = Kit.camera(self, 50.0)


func _tone(a: String, b: String, amount: float) -> Color:
	return (_palette[a] as Color).lerp(_palette[b] as Color, amount)


func _plan_helix() -> void:
	var steps := int(HEIGHT / STEP)
	for i in range(steps):
		var y := 0.3 + i * STEP
		var angle := TAU * y / TURN
		var appear := start + BUILD_FROM + BUILD_FOR * (y / HEIGHT)
		for strand in range(2):
			var a := angle + PI * strand
			_pieces.append([Vector3(cos(a) * RADIUS, y, sin(a) * RADIUS), appear, true])
		if i % RUNG_EVERY == 1:
			for r in range(1, 5):
				var f := r / 5.0
				var p := Vector3(cos(angle), 0.0, sin(angle)) * RADIUS * (1.0 - 2.0 * f)
				_pieces.append([p + Vector3(0.0, y, 0.0), appear + 0.12 + 0.04 * r, false])


func _build_stations() -> void:
	var desk := _tone("paper", "accent", 0.3)
	var frame := _tone("paper", "accent", 0.16)
	for j in range(STATIONS):
		var angle := TAU * (j + 0.5) / STATIONS + PI * 0.5
		var out := Vector3(cos(angle), 0.0, sin(angle))
		var facing := atan2(-out.x, -out.z)
		var holder := Node3D.new()
		holder.position = out * STATION_RING
		holder.rotation.y = facing
		add_child(holder)
		# The desk, in front of the crew member (toward the helix), and its
		# screen tipped back toward them.
		Kit.block(holder, Vector3(1.3, 0.72, 0.6), Vector3(0.0, 0.36, 0.55), desk)
		var screen := Kit.block(holder, Vector3(1.0, 0.7, 0.06), Vector3(0.0, 1.15, 0.72), frame)
		screen.rotation.x = -0.25
		_screen_frames.append(holder.transform * screen.transform)
		var astronaut := AstronautScript.new(Color(str(TRIMS[j])), false)
		astronaut.position = out * (STATION_RING + 0.25)
		astronaut.rotation.y = facing
		add_child(astronaut)
		_crew.append(astronaut)
		Kit.shadow_disc(self, astronaut.position, _tone("paper", "accent", 0.36))
	_screens = Kit.rim_cubes(self, 0.13, STATIONS * SCREEN_COLUMNS * SCREEN_ROWS)


func update(t: float) -> void:
	RenderingServer.global_shader_parameter_set("song_time", t)
	PaletteScript.apply(_palette)
	Kit.edge_glow(timeline, t)
	var since := t - start
	var spin := Basis(Vector3.UP, since * 0.35)
	for i in range(_pieces.size()):
		var piece: Array = _pieces[i]
		var age := t - float(piece[1])
		if age < 0.0:
			Kit.hide_cube(_helix, i)
			continue
		var pop := 1.0 - exp(-age * 9.0) * cos(age * 20.0) * 0.9
		var drop := Vector3.UP * 0.35 * exp(-age * 12.0)
		var xf := Transform3D(Basis().scaled(Vector3.ONE * maxf(pop, 0.05)), spin * (piece[0] as Vector3) + drop)
		var strand: bool = piece[2]
		Kit.set_cube(_helix, i, xf, _strand_color if strand else _rung_color, strand, age < 0.08)
	_place_screens(t)
	_pose_crew(t)
	_place_camera(t)
	Kit.update_galaxy(space, t, since, camera, _palette)


# Each screen scrolls with busy rows of cells (sampled from the whole
# message, so they are dense enough to read as data), printed flat and bright.
func _place_screens(t: float) -> void:
	var cell_color := _tone("ink", "accent", 0.2)
	var n := 0
	for j in range(STATIONS):
		var frame: Transform3D = _screen_frames[j]
		var scroll := int(floor((t - start) * 6.0)) + j * 5
		for r in range(SCREEN_ROWS):
			var row := posmod(scroll + r, 73)
			for c in range(SCREEN_COLUMNS):
				var lit := _bits[row * 23 + ((j * 4 + c) % 23)] == "1" or Kit.hash2(scroll + r, c + j * 11) > 0.6
				if not lit:
					Kit.hide_cube(_screens, n)
				else:
					var local := Vector3((c - 2) * 0.17, (1.5 - r) * 0.15, -0.05)
					Kit.set_cube(_screens, n, Transform3D(frame.basis.scaled(Vector3(1.0, 1.0, 0.25)), frame * local), cell_color, false, true)
				n += 1


# Typing: gloves forward, tapping fast; every so often looking up at the
# helix as it climbs.
func _pose_crew(t: float) -> void:
	for j in range(_crew.size()):
		var me: Node3D = _crew[j]
		var tap := sin((t - start) * 26.0 + j * 1.7)
		me.pose_on_foot(0.0, 0.0, 0.62, 0.0, 0.5)
		me.arm_l.rotation.x += 0.08 * tap
		me.arm_r.rotation.x -= 0.08 * tap
		var look_up := smoothstep(0.6, 0.9, sin((t - start) * 1.3 + j * 1.1))
		me.helmet.rotation = Vector3(0.25 - 0.75 * look_up, 0.15 * sin(t * 0.7 + j), 0.0)
		me.antenna_tip.scale = Vector3.ONE * (1.0 + 0.6 * timeline.beat_pulse(t, 0.2))


# The hyperlapse move: from behind two stations, rising and drifting round
# as the helix climbs, ending on its top.
func _place_camera(t: float) -> void:
	var u := clampf((t - start) / (end - start), 0.0, 1.0)
	u = lerpf(u, smoothstep(0.0, 1.0, u), 0.35)
	var angle := deg_to_rad(lerpf(70.0, 120.0, u))
	var radius := lerpf(10.5, 9.0, u)
	var eye := Vector3(cos(angle) * radius, lerpf(2.6, 6.8, u), sin(angle) * radius)
	var build := clampf((t - start - BUILD_FROM) / BUILD_FOR, 0.0, 1.0)
	camera.look_at_from_position(eye, Vector3(0.0, lerpf(1.6, 4.0, build), 0.0), Vector3.UP)
