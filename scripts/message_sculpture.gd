class_name MessageSculpture
extends Node3D

# The Arecibo Message as a giant sculpture: one cube for every 1 among its
# 1,679 bits, 73 rows by 23 columns, row 0 at the top and column 0 on the
# left as today's standard picture shows it, facing +Z. Each region of the
# picture has its own colour (the message itself is monochrome; the colours
# only help the eye, as the commonly shown coloured version does), and
# regions group into the seven chapters the story reads top to bottom.
#
# Bits and section rows come from data/arecibo/, checked against sources
# listed in data/arecibo/SOURCES.md.

const MonolithShader := preload("res://shaders/monolith.gdshader")
const ROWS := 73
const COLUMNS := 23
const BITS_PATH := "res://data/arecibo/bits.txt"
const SECTIONS_PATH := "res://data/arecibo/sections.json"

var pitch := 3.0
var multimesh: MultiMesh
var regions: Array = []
var chapters: Array = []
var _cubes: Array = []  # [row, column, chapter index, colour]


func _init(cube_pitch := 3.0) -> void:
	name = "MessageSculpture"
	pitch = cube_pitch
	var bits := FileAccess.get_file_as_string(BITS_PATH).strip_edges()
	if bits.length() != ROWS * COLUMNS:
		push_error("[Sculpture] expected %d bits in %s, found %d" % [ROWS * COLUMNS, BITS_PATH, bits.length()])
		return
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SECTIONS_PATH))
	regions = layout["regions"]
	for chapter in layout["chapters"]:
		chapters.append(str(chapter["key"]))
	for row in range(ROWS):
		for column in range(COLUMNS):
			if bits[row * COLUMNS + column] == "1":
				var region := _region_of(row, column)
				_cubes.append([row, column, chapters.find(str(region["chapter"])), Color(str(region["color"]))])
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * pitch * 0.86
	var material := ShaderMaterial.new()
	material.shader = MonolithShader
	cube.material = material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.use_custom_data = true
	multimesh.mesh = cube
	multimesh.instance_count = _cubes.size()
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	print("[Sculpture] %d lit bits of %d, %d regions in %d chapters" % [_cubes.size(), ROWS * COLUMNS, regions.size(), chapters.size()])


# The first region holding the cell; tools/verify_arecibo.py checks every lit
# cell has one.
func _region_of(row: int, column: int) -> Dictionary:
	for region in regions:
		var rows: Array = region["rows"]
		var columns: Array = region["columns"]
		if row >= int(rows[0]) and row < int(rows[1]) and column >= int(columns[0]) and column < int(columns[1]):
			return region
	push_error("[Sculpture] no region for row %d column %d" % [row, column])
	return regions[regions.size() - 1]


# Centred on the node: column 0 at -x, row 0 at the top.
func home(row: int, column: int) -> Vector3:
	return Vector3((column - (COLUMNS - 1) * 0.5) * pitch, ((ROWS - 1) * 0.5 - row) * pitch, 0.0)


func height() -> float:
	return ROWS * pitch


# Each row lights at its own time, `row_lit[row]`; each cube pops a little
# and prints flat and bright for a moment as it lights. Before that cubes
# hang as `unlit`, a shade of the night. Lit cubes are toned a touch toward
# `paper` so white rows don't blow out. `pulse` swells the cubes on the beat.
# Lit cubes wear rims of light in the global monolith_edge colour (set by the
# shot), all changing together.
func update(t: float, row_lit: PackedFloat64Array, pulse: float, unlit: Color, paper: Color) -> void:
	for i in range(_cubes.size()):
		var cube: Array = _cubes[i]
		var row: int = cube[0]
		var lit_time := row_lit[row]
		var since := t - lit_time
		var on := smoothstep(0.0, 0.18, since)
		var flash := exp(-maxf(since, 0.0) * 5.0) * on
		var pop := 1.0 + 0.35 * flash - 0.12 * (1.0 - on) + 0.06 * pulse * on
		multimesh.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * pop), home(row, cube[1])))
		var base: Color = cube[3]
		var color := unlit.lerp(base.lerp(paper, 0.24), on).srgb_to_linear()
		color.a = 1.0 if flash > 0.35 else 0.0
		multimesh.set_instance_color(i, color)
		multimesh.set_instance_custom_data(i, Color(on, 0.0, 0.0, 0.0))
