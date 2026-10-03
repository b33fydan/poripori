extends Node3D

# The telescope, and the way out (bars 82-92).
#
# Bars 82-86, the song's peak: on a great floating floor out in the galaxy,
# the crew builds the Arecibo telescope from the ground up in fast motion:
# the dish first, centre outward, then the three towers (one taller, as the
# real ones were), the cables, and the platform hauled up to hang over the
# dish with its dome beneath.
#
# Bars 86-89, as the music falls quiet: the floor round it falls away into
# the void, tile by tile out from the coast, leaving only the shape of
# Puerto Rico, with the telescope where it really stood, inland of the
# north-west coast (data/earth/puerto-rico-mask.json; docs/FACTS.md). The
# land greens, its coastline pulses, and the camera pulls up and back to
# show the whole island.
#
# Bars 89-92: the dish fires a beam of light straight up. Boards appear
# under the crew and they surf up after it, rainbow trails behind, rising
# past the camera.
#
# The telescope is drawn about 150 times too big for the island, so it can
# be seen; the beam is a picture of sending the message, not its direction.

const AstronautScript := preload("res://scripts/astronaut.gd")
const PaletteScript := preload("res://scripts/palette.gd")
const CubeTrailScript := preload("res://scripts/cube_trail.gd")
const Kit := preload("res://scripts/broll_kit.gd")

const MASK_PATH := "res://data/earth/puerto-rico-mask.png"
const META_PATH := "res://data/earth/puerto-rico-mask.json"
const CELL := 0.6             # a floor tile
const PART := 0.3             # a telescope cube
const DISH_R := 3.0
const DISH_DEPTH := 1.0
const TOWER_R := 4.3
const TOWERS := [[90.0, 6.6], [210.0, 5.0], [330.0, 5.0]]  # [angle, height]; the first is the tall one
const PLATFORM_Y := 5.0
const CREW := 8
const TRIMS := ["#e8735a", "#5bbf7a", "#f2cf6b", "#3fc1c9", "#e87ba4", "#5e8ec7", "#9b7be0", "#ffffff"]
const LAND := [Color("#4f9b4c"), Color("#3f8545"), Color("#5aa857")]

var options := {}
var timeline
var camera: Camera3D
var space: Node3D
var start := 0.0
var quiet := 0.0              # bar 86: the floor falls
var fire := 0.0               # bar 89: the beam
var end := 0.0
var _palette: Dictionary
var _scope := Vector3.ZERO    # the telescope's centre on the floor
var _island_centre := Vector3.ZERO
var _floor: MultiMesh
var _tiles: Array = []        # [position, land?, coast?, fall time, colour]
var _parts: MultiMesh
var _pieces: Array = []       # [position, appear time, colour, group, source]
var _platform: Node3D
var _cables: Array = []       # [mesh, tower top]
var _beam: MeshInstance3D
var _crew: Array = []
var _flyers: Array = []
var _trails: Array = []


func setup(song_timeline) -> void:
	timeline = song_timeline
	start = timeline.bar_time(82.0)
	quiet = timeline.bar_time(86.0)
	fire = timeline.bar_time(89.0)
	end = timeline.bar_time(92.0)
	_palette = PaletteScript.colors("telescope")
	PaletteScript.apply(_palette)
	space = Kit.galaxy(self, Vector3(0.3, 0.2, -0.93))
	_build_floor()
	_build_telescope()
	for j in range(CREW):
		var astronaut := AstronautScript.new(Color(str(TRIMS[j])), false)
		var angle := TAU * j / CREW + 0.3
		astronaut.position = _scope + Vector3(cos(angle), 0.0, sin(angle)) * (DISH_R + 0.9 + 0.5 * (j % 2))
		var to := _scope - astronaut.position
		astronaut.rotation.y = atan2(to.x, to.z)
		add_child(astronaut)
		_crew.append(astronaut)
		var flyer := AstronautScript.new(Color(str(TRIMS[j])), true)
		flyer.visible = false
		add_child(flyer)
		_flyers.append(flyer)
		var index := j
		var trail := CubeTrailScript.new(func(t: float) -> Vector3: return _flyer_tail(index, t), func(t: float) -> float: return 1.0 if t > _launch(index) else 0.0, 0.14, 26.0, 1.0)
		add_child(trail)
		_trails.append(trail)
	camera = Kit.camera(self, 50.0)


func _tone(a: String, b: String, amount: float) -> Color:
	return (_palette[a] as Color).lerp(_palette[b] as Color, amount)


# --- The floor, and Puerto Rico in it --------------------------------------------

func _build_floor() -> void:
	var mask := Image.load_from_file(ProjectSettings.globalize_path(MASK_PATH))
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(META_PATH))
	var w := mask.get_width()
	var h := mask.get_height()
	var cell_of := func(c: float, r: float) -> Vector3: return Vector3((c + 0.5 - w * 0.5) * CELL, 0.0, (r + 0.5 - h * 0.5) * CELL)
	var scope: Dictionary = meta["telescope"]
	_scope = cell_of.call(float(scope["column"]), float(scope["row"]))
	var land := []
	var sum := Vector3.ZERO
	var count := 0
	for r in range(h):
		var row := []
		for c in range(w):
			var is_land := mask.get_pixel(c, r).r > 0.5
			row.append(is_land)
			if is_land:
				sum += cell_of.call(float(c), float(r))
				count += 1
		land.append(row)
	_island_centre = sum / maxf(count, 1)
	# How far each sea tile is from land, in tiles (a breadth-first sweep),
	# so the floor falls away from the coast outward.
	var far := []
	var queue := []
	for r in range(h):
		var row := []
		for c in range(w):
			row.append(0 if land[r][c] else -1)
			if land[r][c]:
				queue.append(Vector2i(c, r))
		far.append(row)
	var head := 0
	while head < queue.size():
		var at: Vector2i = queue[head]
		head += 1
		for step in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = at + (step as Vector2i)
			if n.x >= 0 and n.y >= 0 and n.x < w and n.y < h and far[n.y][n.x] < 0:
				far[n.y][n.x] = far[at.y][at.x] + 1
				queue.append(n)
	for r in range(h):
		for c in range(w):
			var is_land: bool = land[r][c]
			var coast := false
			if is_land:
				for step in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var n: Vector2i = Vector2i(c, r) + (step as Vector2i)
					if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h or not land[n.y][n.x]:
						coast = true
			var fall := quiet + 0.15 + 0.06 * float(far[r][c]) + 0.45 * Kit.hash2(c, r)
			var tone := _tone("paper", "accent", 0.5 if (c + r) % 2 == 0 else 0.42)
			_tiles.append([cell_of.call(float(c), float(r)) - Vector3(0.0, CELL * 0.5, 0.0), is_land, coast, fall, tone])
	var cube := BoxMesh.new()
	cube.size = Vector3(CELL, CELL, CELL)
	var material := ShaderMaterial.new()
	material.shader = Kit.MonolithShader
	cube.material = material
	_floor = MultiMesh.new()
	_floor.transform_format = MultiMesh.TRANSFORM_3D
	_floor.use_colors = true
	_floor.use_custom_data = true
	_floor.mesh = cube
	_floor.instance_count = _tiles.size()
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = _floor
	add_child(instance)


func _update_floor(t: float) -> void:
	var green := smoothstep(quiet + 1.4, quiet + 3.0, t)
	for i in range(_tiles.size()):
		var tile: Array = _tiles[i]
		var p: Vector3 = tile[0]
		var color: Color = tile[4]
		var rim := 0.0
		if tile[1]:
			# Land: greening from the telescope outward; the coast pulses.
			var reach := smoothstep(0.0, 1.0, green * 1.6 - (p - _scope).length() / 60.0)
			color = color.lerp(LAND[i % LAND.size()], reach)
			rim = reach if tile[2] else 0.0
			_floor.set_instance_transform(i, Transform3D(Basis(), p))
		else:
			var age := t - float(tile[3])
			if age > 0.0:
				if age > 3.0:
					_floor.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), p))
					continue
				# A shudder, then the drop, tumbling and shrinking away.
				var spin := Basis(Vector3(Kit.hash2(i, 1) - 0.5, 0.3, Kit.hash2(i, 2) - 0.5).normalized(), age * (2.0 + 3.0 * Kit.hash2(i, 3)))
				var drop := Vector3(0.0, -4.5 * age * age, 0.0)
				_floor.set_instance_transform(i, Transform3D(spin.scaled(Vector3.ONE * maxf(1.0 - age / 3.0, 0.0)), p + drop))
			else:
				var shake := Vector3(sin(t * 60.0 + i), 0.0, cos(t * 53.0 + i)) * 0.03 * smoothstep(-0.4, 0.0, age)
				_floor.set_instance_transform(i, Transform3D(Basis(), p + shake))
		var linear := color.srgb_to_linear()
		linear.a = 0.0
		_floor.set_instance_color(i, linear)
		_floor.set_instance_custom_data(i, Color(rim, 1.0, 0.0, 0.0))


# --- The telescope ------------------------------------------------------------------

func _build_telescope() -> void:
	var dish := Color("#cfd5e6")
	var concrete := Color("#bdb6c8")
	# The dish: a bowl of cubes, built from the centre outward.
	var bowl := []
	var n := int(DISH_R / PART)
	for x in range(-n, n + 1):
		for z in range(-n, n + 1):
			var r := Vector2(x, z).length() * PART
			if r <= DISH_R:
				bowl.append(Vector3(x * PART, 0.2 + DISH_DEPTH * (r / DISH_R) * (r / DISH_R), z * PART))
	bowl.sort_custom(func(a: Vector3, b: Vector3) -> bool: return Vector2(a.x, a.z).length() < Vector2(b.x, b.z).length())
	for k in range(bowl.size()):
		_pieces.append([_scope + bowl[k], lerpf(start + 0.2, start + 3.2, float(k) / bowl.size()), dish if k % 7 else dish.darkened(0.12), 0, k % CREW])
	# The rim: a low wall round the bowl.
	for k in range(72):
		var a := TAU * k / 72.0
		for y in range(2):
			_pieces.append([_scope + Vector3(cos(a) * (DISH_R + 0.25), 0.15 + y * PART, sin(a) * (DISH_R + 0.25)), start + 2.6 + 0.6 * k / 72.0, concrete, 0, k % CREW])
	# The towers, stacked from the ground up.
	for tower in TOWERS:
		var a := deg_to_rad(float(tower[0]))
		var base := _scope + Vector3(cos(a), 0.0, sin(a)) * TOWER_R
		var levels := int(float(tower[1]) / 0.5)
		for y in range(levels):
			for corner in [Vector2(-0.12, -0.12), Vector2(0.12, -0.12), Vector2(-0.12, 0.12), Vector2(0.12, 0.12)]:
				_pieces.append([base + Vector3(corner.x, 0.25 + y * 0.5, corner.y), lerpf(start + 2.4, start + 4.8, float(y) / levels), concrete, 1, 0])
	_parts = Kit.rim_cubes(self, PART, _pieces.size())
	# The platform: a triangle frame and its dome, hauled up on the cables.
	_platform = Node3D.new()
	add_child(_platform)
	var steel := _tone("ink", "accent", 0.35)
	for k in range(3):
		var a := deg_to_rad(float(TOWERS[k][0]))
		var b := deg_to_rad(float(TOWERS[(k + 1) % 3][0]))
		var pa := Vector3(cos(a), 0.0, sin(a)) * 1.3
		var pb := Vector3(cos(b), 0.0, sin(b)) * 1.3
		var bar := Kit.block(_platform, Vector3(0.22, 0.22, pa.distance_to(pb)), (pa + pb) * 0.5, steel)
		bar.look_at_from_position((pa + pb) * 0.5, pb, Vector3.UP)
	var dome := Kit.block(_platform, Vector3(0.9, 0.7, 0.9), Vector3(0.0, -0.6, 0.0), Color("#e7e1f0"))
	dome.rotation.y = 0.4
	Kit.block(_platform, Vector3(1.9, 0.12, 0.25), Vector3(0.0, -0.15, 0.0), steel)
	for tower in TOWERS:
		var a := deg_to_rad(float(tower[0]))
		var top := _scope + Vector3(cos(a), 0.0, sin(a)) * TOWER_R + Vector3(0.0, float(tower[1]), 0.0)
		var cable := Kit.block(self, Vector3(0.05, 0.05, 1.0), top, Color("#2a2340"))
		_cables.append([cable, top, Vector3(cos(a), 0.0, sin(a)) * 1.3])
	_beam = Kit.block(self, Vector3(1.0, 1.0, 1.0), _scope, Color("#fff4c8"), true)
	_beam.visible = false


func _platform_height(t: float) -> float:
	return lerpf(0.9, PLATFORM_Y, smoothstep(start + 5.4, start + 7.2, t))


func _update_telescope(t: float) -> void:
	for i in range(_pieces.size()):
		var piece: Array = _pieces[i]
		var age := t - float(piece[1])
		if age < 0.0:
			Kit.hide_cube(_parts, i)
			continue
		var p: Vector3 = piece[0]
		if int(piece[3]) == 0 and age < 0.35:
			var hands := _hands(int(piece[4]))
			var u := age / 0.35
			p = hands.lerp(p, u) + Vector3.UP * 1.0 * 4.0 * u * (1.0 - u)
		var pop := 1.0 + 0.35 * exp(-maxf(age - 0.35, 0.0) * 10.0) * float(age >= 0.35)
		Kit.set_cube(_parts, i, Transform3D(Basis().scaled(Vector3.ONE * pop), p), piece[2], age >= 0.35)
	var lifted := _platform_height(t)
	var assembled := smoothstep(start + 4.4, start + 5.0, t)
	_platform.visible = assembled > 0.0
	_platform.position = _scope + Vector3(0.0, lifted, 0.0)
	_platform.scale = Vector3.ONE * maxf(assembled, 0.01)
	var cabled := smoothstep(start + 4.9, start + 5.5, t)
	for entry in _cables:
		var cable: MeshInstance3D = entry[0]
		var top: Vector3 = entry[1]
		var corner: Vector3 = _platform.position + (entry[2] as Vector3)
		var tip := top.lerp(corner, cabled)
		cable.visible = cabled > 0.0
		if cable.visible:
			var length := maxf(top.distance_to(tip), 0.01)
			cable.transform = Transform3D(Basis.looking_at((tip - top).normalized() if length > 0.02 else Vector3.DOWN, Vector3.UP if absf((tip - top).normalized().y) < 0.99 else Vector3.FORWARD) * Basis.from_scale(Vector3(1.0, 1.0, length)), (top + tip) * 0.5)


func _hands(j: int) -> Vector3:
	var me: Node3D = _crew[j]
	return me.transform * me.hands_point(PART)


# --- The beam and the flight ----------------------------------------------------------

func _launch(j: int) -> float:
	return fire + 1.0 + 0.16 * j


# Each flyer spirals up round the beam, faster and faster, the last of them
# passing the camera as the shot ends.
func _climb(j: int, t: float) -> float:
	var age := maxf(t - _launch(j), 0.0)
	return 0.5 * 6.0 * age * age if age < 2.2 else 0.5 * 6.0 * 2.2 * 2.2 + 13.2 * (age - 2.2)


func _flyer_place(j: int, t: float) -> Transform3D:
	var crew_at: Vector3 = (_crew[j] as Node3D).position
	var age := maxf(t - _launch(j), 0.0)
	var climb := _climb(j, t)
	var start_angle := atan2(crew_at.z - _scope.z, crew_at.x - _scope.x)
	var radius := lerpf(Vector2(crew_at.x - _scope.x, crew_at.z - _scope.z).length(), 1.6 + 0.35 * (j % 3), smoothstep(0.0, 1.2, age))
	var angle := start_angle + climb * 0.12
	var p := _scope + Vector3(cos(angle) * radius, 0.2 + climb, sin(angle) * radius)
	# The board's nose (+X) along the spiral, tipped up into the climb.
	var heading := Vector3(-sin(angle), 0.0, cos(angle))
	var tilt := clampf(age * 0.8, 0.0, 0.9)
	var x := (heading * cos(tilt) + Vector3.UP * sin(tilt)).normalized()
	var y := (Vector3.UP - x * x.dot(Vector3.UP)).normalized()
	return Transform3D(Basis(x, y, x.cross(y)), p)


func _flyer_tail(j: int, t: float) -> Vector3:
	return _flyer_place(j, t) * Vector3(-0.8, -0.05, 0.0)


func update(t: float) -> void:
	RenderingServer.global_shader_parameter_set("song_time", t)
	PaletteScript.apply(_palette)
	Kit.edge_glow(timeline, t)
	var since := t - start
	_update_floor(t)
	_update_telescope(t)
	_pose_crew(t)
	# The beam: up out of the dish, the whole sky's height, swelling on the beat.
	var beam_age := t - fire
	_beam.visible = beam_age > 0.0
	if _beam.visible:
		var height := 600.0 * smoothstep(0.0, 0.7, beam_age)
		var width: float = (1.1 + 0.25 * timeline.beat_pulse(t, 0.3)) * (1.0 + 1.5 * exp(-beam_age * 5.0))
		_beam.transform = Transform3D(Basis.from_scale(Vector3(width, height, width)), _scope + Vector3(0.0, 0.5 + height * 0.5, 0.0))
	for j in range(CREW):
		var flyer: Node3D = _flyers[j]
		var boarding := t > fire + 0.5 + 0.1 * j
		flyer.visible = boarding
		(_crew[j] as Node3D).visible = not boarding
		if boarding:
			if t < _launch(j):
				# The board pops in under them; they crouch to spring.
				var crew_node: Node3D = _crew[j]
				flyer.transform = Transform3D(Basis(Vector3.UP, crew_node.rotation.y - PI * 0.5), crew_node.position + Vector3(0.0, 0.1, 0.0))
				var pop := smoothstep(fire + 0.5 + 0.1 * j, fire + 0.75 + 0.1 * j, t)
				flyer.board.scale = Vector3.ONE * pop
				flyer.board_glow.scale = Vector3.ONE * pop
				flyer.pose(0.9, 0.3, 0.6, Vector4(0.3, 0.5, -0.3, 0.2))
			else:
				flyer.transform = _flyer_place(j, t)
				flyer.pose(0.42, 0.16, 0.9, Vector4(1.3, 0.4, -1.1, 0.45))
		(_trails[j] as Node3D).visible = t > _launch(j)
		_trails[j].update(t)
	_place_camera(t)
	Kit.update_galaxy(space, t, since, camera, _palette, 0.05)


func _pose_crew(t: float) -> void:
	for j in range(CREW):
		var me: Node3D = _crew[j]
		var working := 1.0 - smoothstep(start + 6.5, start + 7.0, t)
		var toss := 0.5 + 0.5 * sin(t * 18.0 + j)
		var look_up := smoothstep(fire - 0.2, fire + 0.3, t)
		me.pose_on_foot(TAU * timeline.beat(t) * 0.5 + j, 0.08 * working, (0.7 + 0.3 * toss) * working, 0.0, 0.0)
		me.helmet.rotation.x = -0.5 * look_up
		me.antenna_tip.scale = Vector3.ONE * (1.0 + 0.6 * timeline.beat_pulse(t, 0.2))


# Round the telescope while it is built; up and back over the island as the
# floor falls; then over to the beam as they fly up it, past the lens.
func _place_camera(t: float) -> void:
	var keys := []
	var target := Vector3.ZERO
	if t < quiet:
		var u := (t - start) / (quiet - start)
		var angle := deg_to_rad(lerpf(25.0, 95.0, u))
		var radius := lerpf(13.0, 11.0, u)
		var eye := _scope + Vector3(cos(angle) * radius, lerpf(4.5, 6.5, u), sin(angle) * radius)
		camera.fov = 50.0
		camera.look_at_from_position(eye, _scope + Vector3(0.0, 2.4, 0.0), Vector3.UP)
		return
	var built_eye := _scope + Vector3(cos(deg_to_rad(95.0)) * 11.0, 6.5, sin(deg_to_rad(95.0)) * 11.0)
	var high_eye := _island_centre + Vector3(0.0, 46.0, 30.0)
	var beam_eye := _scope + Vector3(9.0, 40.0, 16.0)
	if t < fire:
		var u := smoothstep(quiet + 0.2, fire - 0.2, t)
		var eye := BrollKitPath.arc(built_eye, _scope + Vector3(4.0, 22.0, 26.0), high_eye, u)
		target = (_scope + Vector3(0.0, 2.4, 0.0)).lerp(_island_centre, smoothstep(0.0, 0.8, u))
		camera.fov = lerpf(50.0, 46.0, u)
		camera.look_at_from_position(eye, target, Vector3.UP)
		return
	var u := smoothstep(fire, end, t)
	var eye := high_eye.lerp(beam_eye, u)
	# Looking down the beam at first, then up it with the flyers as they come.
	var climbing := 0.0
	for j in range(CREW):
		climbing += _climb(j, t) / CREW
	target = _island_centre.lerp(_scope + Vector3(0.0, climbing, 0.0), smoothstep(0.0, 0.5, u))
	camera.fov = 46.0
	camera.look_at_from_position(eye, target, Vector3.UP)


class BrollKitPath:
	# A smooth arc from a through b to c (a quadratic Bezier).
	static func arc(a: Vector3, b: Vector3, c: Vector3, u: float) -> Vector3:
		return a.lerp(b, u).lerp(b.lerp(c, u), u)
