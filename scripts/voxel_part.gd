class_name VoxelPart
extends Node3D

# A model made of real cubes: cells on an integer grid, each with a colour,
# drawn as one MultiMesh. Being real cubes (not merged faces), any part can
# later burst into its voxels and gather back, as the MEGAVOX prototype did.
#
# Author a part by filling and carving boxes of cells, then call build().
# Cells are in voxel units; `pivot` (also in voxel units) sits at the node's
# origin, so a limb can rotate about its joint.

const PrintShader := preload("res://shaders/print.gdshader")

var unit := 0.05
var pivot := Vector3.ZERO
var cells := {}  # Vector3i -> Color (sRGB)
var glows := {}  # Vector3i -> > 0 for the few cubes that print flat and bright
var multimesh: MultiMesh
var material: ShaderMaterial
var _order: Array = []  # cells in instance order, after build()


func _init(voxel_unit := 0.05, part_pivot := Vector3.ZERO) -> void:
	unit = voxel_unit
	pivot = part_pivot


# Fill the cells from `from` up to but not including `to`.
func box(from: Vector3i, to: Vector3i, color: Color, glow := 0.0) -> VoxelPart:
	for x in range(from.x, to.x):
		for y in range(from.y, to.y):
			for z in range(from.z, to.z):
				paint(Vector3i(x, y, z), color, glow)
	return self


func carve(from: Vector3i, to: Vector3i) -> VoxelPart:
	for x in range(from.x, to.x):
		for y in range(from.y, to.y):
			for z in range(from.z, to.z):
				cells.erase(Vector3i(x, y, z))
				glows.erase(Vector3i(x, y, z))
	return self


func paint(cell: Vector3i, color: Color, glow := 0.0) -> VoxelPart:
	cells[cell] = color
	if glow > 0.0:
		glows[cell] = glow
	else:
		glows.erase(cell)
	return self


# Only cells with an open face are drawn; hidden insides would never show.
func build() -> VoxelPart:
	_order.clear()
	for cell in cells.keys():
		var c: Vector3i = cell
		for d in [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP, Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK]:
			if not cells.has(c + d):
				_order.append(c)
				break
	_order.sort()
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * unit
	material = ShaderMaterial.new()
	material.shader = PrintShader
	cube.material = material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = cube
	multimesh.instance_count = _order.size()
	for i in range(_order.size()):
		var c: Vector3i = _order[i]
		multimesh.set_instance_transform(i, Transform3D(Basis(), home(c)))
		multimesh.set_instance_color(i, _shade(c, cells[c], float(glows.get(c, 0.0))))
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	add_child(instance)
	return self


func home(cell: Vector3i) -> Vector3:
	return (Vector3(cell) + Vector3.ONE * 0.5 - pivot) * unit


func cube_count() -> int:
	return _order.size()


# A hair of per-cube variation (from a hash of the cell, so every render is
# identical) keeps big flat panels from reading as plastic.
func _shade(cell: Vector3i, color: Color, glow: float) -> Color:
	var h := absi(cell.x * 73856093 ^ cell.y * 19349663 ^ cell.z * 83492791) % 1000
	var shift := (float(h) / 1000.0 - 0.5) * 0.05
	var shaded := Color(color.r + shift, color.g + shift, color.b + shift).clamp()
	var linear := shaded.srgb_to_linear()
	linear.a = 1.0 if glow > 0.0 else 0.0
	return linear
