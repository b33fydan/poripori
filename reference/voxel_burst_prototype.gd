# Reference copy of the voxel burst prototype from the AgentVille session of
# 2026-10-01, rendered as ~/Movies/AgentVille/tree-burst-prototype.mp4. It ran
# inside the AgentVille Godot project, so its res:// paths (the licensed
# Tree.005.glb under assets/licensed_local/, and StorySound.gd) point there.
# Read it for the technique; it won't run as-is in a new project.

extends SceneTree

# Prototype: a MEGAVOX tree bursts into its voxels (an exploded view), hangs,
# and snaps back together. Local only: it loads the owner's licensed model and
# Ocular sounds, and writes nothing into the repository.
#
# Run under Movie Maker for the clip:
#   Godot --path godot --resolution 1280x720 --fixed-fps 30 \
#     --write-movie <out>.avi --script tree_burst.gd
# or with `-- check` to save the intact model and the voxel rebuild as two
# stills, which should match.

const MODEL_PATH := "res://assets/licensed_local/megavox/trees/Tree.005.glb"
const StorySoundScript := preload("res://scripts/story/StorySound.gd")
const VOXEL := 0.1
const FPS := 30.0
const DURATION := 5.0
const OUT_DIR := "/private/tmp/claude-501/-Volumes-beefybackup-AgentVille/55403d6b-e3b9-4c10-b705-4dc650e6dd45/scratchpad/frames"

# The beats, in seconds.
const T_BURST := 0.7
const D_BURST := 0.55
const T_GATHER := 2.45
const D_GATHER := 0.8
const T_LAND := T_GATHER + D_GATHER
const D_SETTLE := 0.45
const D_CROUCH := 0.18
const CREDITS := "Tree: MEGAVOX  ·  Sounds: Vector by Ocular Sounds"

# The exploded view: positions spread from the trunk's axis and up from the
# base, so no cube sinks into the ground; each cube keeps its size.
const EXPAND_XZ := 1.3
const EXPAND_Y := 0.7
const JITTER := 0.3
const LIFT := 0.2
const DRIFT := 0.12
const SPIN := 2.6
const BURST_STAGGER := 0.2
const GATHER_STAGGER := 0.5

const GRASS := [Color("#a8cf65"), Color("#9cc45e"), Color("#93ba57"), Color("#a5cc66"), Color("#8bb152")]
const SKIRT := [Color("#9a6a45"), Color("#7e5538")]

var _frame := 0
var _check := false
var _pivot: Node3D
var _model: Node3D
var _voxels_node: Node3D
var _camera: Camera3D
var _sound: Node
var _multimeshes: Array = []
# Per voxel: [multimesh index, instance index, home, rand a, rand b, rand c, jitter, spin axis]
var _cells: Array = []
var _height := 1.0
var _last_t := -1.0
var _next_tick := 0.0
var _tick_index := 0


func _initialize() -> void:
	_check = OS.get_cmdline_user_args().has("check")
	_build_stage()
	_build_tree()
	_build_voxels()
	_sound = StorySoundScript.new()
	root.add_child(_sound)
	print("[TreeBurst] %d voxels in %d colours" % [_cells.size(), _multimeshes.size()])
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	if _check:
		_frame += 1
		if _frame == 6:
			_pose(0.0, true)
		elif _frame == 12:
			_save("check-model")
			_pose(0.0, false)
		elif _frame == 18:
			_save("check-voxels")
			quit()
		return
	var t := _frame / FPS
	_pose(t, t < T_BURST or t >= T_LAND)
	_cues(t)
	_frame += 1
	if t >= DURATION:
		quit()


func _save(stem: String) -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var image := root.get_texture().get_image()
	image.save_png("%s/%s.png" % [OUT_DIR, stem])
	print("[TreeBurst] saved %s" % stem)


# --- The stage: the story's light on a little grass platform ------------------

func _build_stage() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#efe8dc")
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#b9d4e7")
	sky_material.sky_horizon_color = Color("#f4e9d8")
	sky_material.ground_horizon_color = Color("#e8d9c2")
	sky_material.ground_bottom_color = Color("#c9a27c")
	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.40
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 0.95
	environment.tonemap_white = 1.25
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.06
	environment.adjustment_saturation = 1.03
	var world := WorldEnvironment.new()
	world.environment = environment
	root.add_child(world)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#fff5e8")
	sun.light_energy = 1.18
	sun.shadow_enabled = true
	sun.shadow_blur = 0.9
	sun.shadow_opacity = 0.88
	sun.shadow_bias = 0.03
	sun.shadow_normal_bias = 0.4
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 30.0
	root.add_child(sun)
	sun.basis = Basis.looking_at(-Vector3(6.0, 9.0, 7.0), Vector3.UP)
	var rim := DirectionalLight3D.new()
	rim.light_color = Color("#cfe0f2")
	rim.light_energy = 0.18
	root.add_child(rim)
	rim.basis = Basis.looking_at(-Vector3(-7.0, 6.0, -5.0), Vector3.UP)

	# A 9×9 checker of half-unit grass tiles over two bands of dirt.
	var tile := 0.5
	var count := 9
	var half := tile * count * 0.5
	for i in range(count):
		for j in range(count):
			var color: Color = GRASS[(i * 7 + j * 3 + (i * j) % 5) % GRASS.size()]
			_box(Vector3(tile, 0.2, tile), color, Vector3(-half + (i + 0.5) * tile, -0.1, -half + (j + 0.5) * tile))
	_box(Vector3(tile * count, 0.35, tile * count), SKIRT[0], Vector3(0.0, -0.375, 0.0))
	_box(Vector3(tile * count, 0.3, tile * count), SKIRT[1], Vector3(0.0, -0.7, 0.0))

	_camera = Camera3D.new()
	_camera.fov = 30.0
	_camera.near = 0.1
	_camera.far = 100.0
	root.add_child(_camera)

	# The credits, small in the corner, as the film's footer has them.
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var credits := Label.new()
	credits.text = CREDITS
	credits.add_theme_font_size_override("font_size", 15)
	credits.add_theme_color_override("font_color", Color("#6f6455"))
	credits.anchor_top = 1.0
	credits.anchor_bottom = 1.0
	credits.offset_left = 28.0
	credits.offset_top = -44.0
	credits.offset_bottom = -20.0
	layer.add_child(credits)


func _box(size: Vector3, color: Color, position: Vector3) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	root.add_child(instance)


# --- The tree and its voxels -------------------------------------------------

func _build_tree() -> void:
	_pivot = Node3D.new()
	root.add_child(_pivot)
	_model = (load(MODEL_PATH) as PackedScene).instantiate() as Node3D
	_pivot.add_child(_model)
	var instance := _find_mesh(_model)
	var mesh_xf := _relative_transform(instance, _model)
	var bounds: AABB = mesh_xf * instance.mesh.get_aabb()
	_height = bounds.size.y
	# The base's centre stands on the pivot.
	_model.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	_voxels_node = Node3D.new()
	_voxels_node.transform = _model.transform * mesh_xf
	_voxels_node.visible = false
	_pivot.add_child(_voxels_node)


func _build_voxels() -> void:
	var instance := _find_mesh(_model)
	var mesh := instance.mesh
	# The grid's offset from the origin: Tree.021 sits half a voxel off.
	var first: Vector3 = (mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array)[0]
	var grid := Vector3(fposmod(first.x, VOXEL), fposmod(first.y, VOXEL), fposmod(first.z, VOXEL))
	var owner := {}
	for surface in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(surface)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals = arrays[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var count := indices.size() if indices.size() > 0 else verts.size()
		for t in range(0, count, 3):
			var ia := indices[t] if indices.size() > 0 else t
			var a := verts[ia] - grid
			var b := verts[indices[t + 1] if indices.size() > 0 else t + 1] - grid
			var c := verts[indices[t + 2] if indices.size() > 0 else t + 2] - grid
			# Godot winds front faces clockwise, so the cross product points in;
			# the mesh's own normal says which side the solid voxel is on.
			var normal := -(b - a).cross(c - a)
			if normal.length() < 0.000001:
				continue
			normal = normal.normalized()
			if normals != null and (normals as PackedVector3Array).size() > ia:
				normal = (normals as PackedVector3Array)[ia]
			var axis := normal.abs().max_axis_index()
			if absf(normal[axis]) < 0.999:
				continue
			_rasterize(a, b, c, axis, signf(normal[axis]), owner, surface)
	# One multimesh of cubes per colour, drawn with the model's own material.
	var by_surface := {}
	for cell in owner.keys():
		var surface: int = owner[cell]
		if not by_surface.has(surface):
			by_surface[surface] = []
		by_surface[surface].append(cell)
	var min_y := INF
	for cell in owner.keys():
		min_y = minf(min_y, (cell as Vector3i).y)
	# Offsets are worked out on the pivot, whose origin is the base's centre.
	var to_pivot := _voxels_node.transform
	for surface in by_surface.keys():
		var cells: Array = by_surface[surface]
		var cube := BoxMesh.new()
		cube.size = Vector3.ONE * VOXEL
		cube.material = mesh.surface_get_material(surface)
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = cube
		multimesh.instance_count = cells.size()
		var node := MultiMeshInstance3D.new()
		node.multimesh = multimesh
		_voxels_node.add_child(node)
		var mesh_index := _multimeshes.size()
		_multimeshes.append(multimesh)
		for index in range(cells.size()):
			var cell: Vector3i = cells[index]
			var home := (Vector3(cell) + Vector3.ONE * 0.5) * VOXEL + grid
			var seed := cell.x * 73856093 ^ cell.y * 19349663 ^ cell.z * 83492791
			var rng := RandomNumberGenerator.new()
			rng.seed = seed
			var jitter := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.3, 1.0), rng.randf_range(-1.0, 1.0)).normalized()
			var axis := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)).normalized()
			var rise := ((cell.y - min_y) * VOXEL) / maxf(_height, 0.001)
			_cells.append([mesh_index, index, home, rng.randf(), rng.randf(), rise, jitter, axis, to_pivot * home])
			multimesh.set_instance_transform(index, Transform3D(Basis(), home))


# Each axis-aligned triangle is rasterized on the voxel grid; the solid voxel
# sits half a voxel behind the face. Cell centres are nudged a hair so a quad's
# diagonal, which runs through some centres, gives each to exactly one half.
func _rasterize(a: Vector3, b: Vector3, c: Vector3, axis: int, side: float, owner: Dictionary, surface: int) -> void:
	var u := (axis + 1) % 3
	var v := (axis + 2) % 3
	var a2 := Vector2(a[u], a[v])
	var b2 := Vector2(b[u], b[v])
	var c2 := Vector2(c[u], c[v])
	var lo := Vector2(minf(a2.x, minf(b2.x, c2.x)), minf(a2.y, minf(b2.y, c2.y)))
	var hi := Vector2(maxf(a2.x, maxf(b2.x, c2.x)), maxf(a2.y, maxf(b2.y, c2.y)))
	var plane := roundi(a[axis] / VOXEL)
	var i := floori(lo.x / VOXEL + 0.001)
	while (i + 0.5) * VOXEL < hi.x:
		var j := floori(lo.y / VOXEL + 0.001)
		while (j + 0.5) * VOXEL < hi.y:
			var p := Vector2((i + 0.5) * VOXEL + 0.00013, (j + 0.5) * VOXEL + 0.00007)
			if Geometry2D.point_is_inside_triangle(p, a2, b2, c2):
				var cell := Vector3i.ZERO
				cell[u] = i
				cell[v] = j
				cell[axis] = plane - (1 if side > 0.0 else 0)
				if not owner.has(cell):
					owner[cell] = surface
			j += 1
		i += 1


# --- The motion ----------------------------------------------------------------

func _pose(t: float, show_model: bool) -> void:
	_model.visible = show_model
	_voxels_node.visible = not show_model
	var burst := clampf((t - T_BURST) / D_BURST, 0.0, 1.0)
	var drift := clampf((t - T_BURST - D_BURST) / (T_GATHER - T_BURST - D_BURST), 0.0, 1.0) * DRIFT
	var gather := clampf((t - T_GATHER) / D_GATHER, 0.0, 1.0)
	if not show_model:
		var to_local := _voxels_node.transform.basis.inverse()
		for entry in _cells:
			var home: Vector3 = entry[2]
			var radial: Vector3 = entry[8]
			var rand_a: float = entry[3]
			var rand_b: float = entry[4]
			var rise: float = entry[5]
			var local_burst := clampf((burst - BURST_STAGGER * rand_a) / (1.0 - BURST_STAGGER), 0.0, 1.0)
			# The trunk returns first and the crown last, like regrowing.
			var local_gather := clampf((gather - GATHER_STAGGER * rise - 0.08 * rand_b) / (1.0 - GATHER_STAGGER - 0.08), 0.0, 1.0)
			var out := (1.0 - pow(1.0 - local_burst, 3.0)) * (1.0 + drift * (0.6 + rand_b))
			# Pulled in like a magnet: slow, then fast, landing hard.
			var amount := out * (1.0 - pow(local_gather, 3.0))
			var offset := Vector3(radial.x * EXPAND_XZ, radial.y * EXPAND_Y, radial.z * EXPAND_XZ) * amount
			offset += (entry[6] as Vector3) * JITTER * amount + Vector3(0.0, LIFT * amount, 0.0)
			var basis := Basis(entry[7] as Vector3, SPIN * (0.4 + rand_a) * amount)
			(_multimeshes[int(entry[0])] as MultiMesh).set_instance_transform(int(entry[1]), Transform3D(basis, home + to_local * offset))
	# Anticipation: the tree crouches just before it bursts, and springs up.
	var stretch := 1.0
	var crouch := (t - (T_BURST - D_CROUCH)) / D_CROUCH
	if crouch >= 0.0 and crouch < 1.0:
		stretch = 1.0 - 0.06 * sin(crouch * PI * 0.5)
	elif t >= T_BURST and t < T_BURST + 0.15:
		stretch = 0.94 + 0.06 * (t - T_BURST) / 0.15
	# Landing: a squash, then a little wobble that settles.
	var since := t - T_LAND
	if since >= 0.0 and since < D_SETTLE:
		stretch = 1.0 - 0.07 * exp(-7.0 * since) * cos(since * 26.0)
	_pivot.scale = Vector3(1.0 / sqrt(stretch), stretch, 1.0 / sqrt(stretch))
	# The camera eases back ahead of the burst to hold it, and orbits slowly.
	var lead := clampf((t - T_BURST + 0.12) / (D_BURST + 0.12), 0.0, 1.0)
	# The crown lands last, so the wide shot holds until it does, then the
	# camera eases back in on the rebuilt tree.
	var back := clampf((t - T_LAND + 0.1) / 0.7, 0.0, 1.0)
	var envelope := (1.0 - pow(1.0 - lead, 2.0)) * (1.0 - smoothstep(0.0, 1.0, back))
	var distance := lerpf(7.2, 13.2, envelope)
	var look := Vector3(0.0, lerpf(1.2, 2.35, envelope), 0.0)
	var yaw := deg_to_rad(lerpf(-24.0, 14.0, t / DURATION))
	var pitch := deg_to_rad(18.0)
	_camera.position = look + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * distance
	_camera.look_at(look, Vector3.UP)


func _cues(t: float) -> void:
	if _crossed(t, T_BURST):
		_sound.call("play", "transition", 1.1)
		_sound.call("play", "materialize_pop_2", 0.9)
	if _crossed(t, T_GATHER):
		_sound.call("play", "assemble", 1.0)
		_next_tick = T_GATHER + 0.25
	# A rising ripple of ticks as the cubes land, trunk first.
	if t >= _next_tick and t > T_GATHER and t < T_LAND:
		var progress := (t - T_GATHER) / D_GATHER
		_sound.call("play", "materialize_tile_%d" % (_tick_index % 4 + 1), 0.85 + 0.6 * progress, -4.0)
		_tick_index += 1
		_next_tick = t + 0.066
	if _crossed(t, T_LAND):
		_sound.call("play", "build_complete", 1.0)
	_last_t = t


func _crossed(t: float, mark: float) -> bool:
	return _last_t < mark and t >= mark


func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found := _find_mesh(child)
		if found:
			return found
	return null


func _relative_transform(node: Node3D, ancestor: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var current: Node = node
	while current != null and current != ancestor:
		xf = (current as Node3D).transform * xf
		current = current.get_parent()
	return xf
