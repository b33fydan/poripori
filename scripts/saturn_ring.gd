class_name SaturnRing
extends Node3D

# A ring of voxel tiles around the sculpture, like Saturn's: banded tones,
# with a gap like the Cassini Division. The astronaut surfs on it.
#
# Ring space: the ring lies flat in the node's XZ plane around its origin;
# +Y is its normal. A point on it is (radius, angle), with angle measured
# from +X toward +Z. Tiles are flat boxes; the shader lifts them on a swell
# that travels round the ring, and presses, wobbles and paints each one from
# the song time the board passed over it (worked out here once, in paint()).

const RingShader := preload("res://shaders/ring.gdshader")
const NEVER := 1.0e9

var r_in := 200.0
var r_out := 320.0
var gap := Vector2(262.0, 270.0)
var tile := 1.4
var thickness := 0.5
var swell_count := 24.0
var multimesh: MultiMesh
var material: ShaderMaterial
var _rows: Array = []  # [radius, first instance, tile count, angle step]


func _init(inner := 200.0, outer := 320.0, gap_band := Vector2(262.0, 270.0), tile_size := 1.4) -> void:
	name = "SaturnRing"
	r_in = inner
	r_out = outer
	gap = gap_band
	tile = tile_size
	var count := 0
	var r := r_in + tile * 0.5
	while r < r_out:
		if r < gap.x or r > gap.y:
			var n := int(floor(TAU * r / tile))
			_rows.append([r, count, n, TAU / n])
			count += n
		r += tile
	var box := BoxMesh.new()
	box.size = Vector3(tile, thickness, tile)
	material = ShaderMaterial.new()
	material.shader = RingShader
	material.set_shader_parameter("tile", tile)
	material.set_shader_parameter("r_in", r_in)
	material.set_shader_parameter("r_out", r_out)
	material.set_shader_parameter("swell_count", swell_count)
	box.material = material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = box
	multimesh.instance_count = count
	for row in _rows:
		var radius: float = row[0]
		var first: int = row[1]
		var n: int = row[2]
		var step: float = row[3]
		# Stretch tiles along the row so neighbours meet exactly.
		var stretch := (TAU * radius / n) / tile
		for j in range(n):
			var angle := j * step
			# The tile's local +Z points out along the radius.
			var basis := Basis(Vector3.UP, PI * 0.5 - angle).scaled(Vector3(stretch, 1.0, 1.0))
			multimesh.set_instance_transform(first + j, Transform3D(basis, Vector3(cos(angle), 0.0, sin(angle)) * radius))
			multimesh.set_instance_custom_data(first + j, Color(radius, angle, NEVER, 0.0))
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	print("[Ring] %d tiles in %d rows" % [count, _rows.size()])


# The swell's height at a point, exactly as ring.gdshader lifts a tile.
func swell(radius: float, angle: float, amplitude: float, phase: float) -> float:
	var x := clampf((radius - r_in) / (r_out - r_in), 0.0, 1.0)
	return amplitude * sin(PI * x) * sin(swell_count * angle - phase)


func set_swell(amplitude: float, phase: float) -> void:
	material.set_shader_parameter("swell_amp", amplitude)
	material.set_shader_parameter("swell_phase", phase)


func tile_top() -> float:
	return thickness * 0.5


# Ring space (radius, angle, height above the ring plane) to a local point.
static func polar(radius: float, angle: float, height := 0.0) -> Vector3:
	return Vector3(cos(angle) * radius, height, sin(angle) * radius)


# Record when the board first crosses each tile. `track` is a function of
# song time returning the board's (radius, angle); tiles within `half_width`
# of its line across the track are painted, with their place across it
# (-1..1) kept for the rainbow.
func paint(track: Callable, from: float, to: float, half_width: float, step := 1.0 / 120.0) -> void:
	var painted := 0
	var t := from
	while t <= to:
		var at: Vector2 = track.call(t)
		for row in _rows:
			var radius: float = row[0]
			var across := radius - at.x
			if absf(across) > half_width:
				continue
			var first: int = row[1]
			var n: int = row[2]
			var angle_step: float = row[3]
			var j := int(round(fposmod(at.y, TAU) / angle_step)) % n
			var index := first + j
			var custom := multimesh.get_instance_custom_data(index)
			if custom.b >= NEVER:
				multimesh.set_instance_custom_data(index, Color(custom.r, custom.g, t, across / half_width))
				painted += 1
		t += step
	print("[Ring] painted %d tiles along the track" % painted)
