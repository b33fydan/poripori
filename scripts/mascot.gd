class_name Mascot
extends Node3D

# The Claude mascot: Claude Code's little orange creature in voxels (no logo,
# no name; the owner's direction), shaped after the 3D figure the owner
# chose as reference: a near-cube body a third wider than tall, two raised
# black square eyes set wide in its top quarter, a flat block of an arm at
# mid-height on each side, and four slim legs in two pairs, a third of the
# body's height.
#
# Every voxel is P units. The arms telescope: reach() slides one out of the
# body, for the moment it touches the astronaut's glove, and point() aims
# one anywhere. hover(phase, trail) bobs it, the legs paddling, swung back
# by `trail` when it flies.
#
# Mascot space: it faces +Z, its feet at y = 0, centred on x and z.

const VoxelPartScript := preload("res://scripts/voxel_part.gd")
const PrintShader := preload("res://shaders/print.gdshader")
const P := 0.07
const W := 12        # body, in voxels: 0.84 x 0.63 x 0.63 units
const H := 9
const D := 9
const LEG := 3       # leg height
const ORANGE := Color("#d97757")
const EYE := Color("#1d1714")
const ARM_CUBES := 8  # the longest an arm can reach, in cubes

var body: Node3D
var arm_l: Node3D  # +X side (its left as it faces +Z)
var arm_r: Node3D
var legs: Array = []
var _arm_cubes := {"l": [], "r": []}


func _init() -> void:
	name = "Mascot"
	body = VoxelPartScript.new(P, Vector3(W * 0.5, 0.0, D * 0.5))
	body.box(Vector3i(0, LEG, 0), Vector3i(W, LEG + H, D), ORANGE)
	body.build()
	add_child(body)
	# Raised square eyes: thin black plates standing proud of the face.
	for column in [2, W - 4]:
		var eye := MeshInstance3D.new()
		var plate := BoxMesh.new()
		plate.size = Vector3(2.0 * P, 2.0 * P, 0.5 * P)
		var material := ShaderMaterial.new()
		material.shader = PrintShader
		var linear := EYE.srgb_to_linear()
		material.set_shader_parameter("tint", Vector4(linear.r, linear.g, linear.b, 1.0))
		plate.material = material
		eye.mesh = plate
		eye.position = Vector3((column + 1.0 - W * 0.5) * P, (LEG + H - 3.0) * P, (D * 0.5 + 0.25) * P)
		body.add_child(eye)
	# Two pairs of slim legs under the outer thirds, set back from the face.
	for column in [1, 3, W - 4, W - 2]:
		var leg := VoxelPartScript.new(P, Vector3(W * 0.5, 0.0, D * 0.5))
		leg.box(Vector3i(column, 0, 3), Vector3i(column + 1, LEG, 6), ORANGE)
		leg.build()
		add_child(leg)
		legs.append(leg)
	arm_l = _arm("l", 1.0)
	arm_r = _arm("r", -1.0)
	reach(0.0, 0.0)


# An arm: a flat block (3 voxels tall, 3 deep) two voxels long at rest,
# made of ARM_CUBES slices that stack inside each other and slide out.
func _arm(key: String, side: float) -> Node3D:
	var arm := Node3D.new()
	arm.position = Vector3(side * W * 0.5 * P, (LEG + H * 0.5) * P, 0.0)
	var slice := BoxMesh.new()
	slice.size = Vector3(P, 3.0 * P, 3.0 * P)
	var material := ShaderMaterial.new()
	material.shader = PrintShader
	var linear := ORANGE.srgb_to_linear()
	material.set_shader_parameter("tint", Vector4(linear.r, linear.g, linear.b, 1.0))
	slice.material = material
	for i in range(ARM_CUBES):
		var piece := MeshInstance3D.new()
		piece.mesh = slice
		arm.add_child(piece)
		(_arm_cubes[key] as Array).append(piece)
	arm.set_meta("side", side)
	add_child(arm)
	return arm


# Arm lengths from 0 (the resting two voxels) to 1 (fully out), and where
# each points: raise lifts it from sideways toward up, in radians.
func reach(left: float, right: float, raise_left := 0.0, raise_right := 0.0) -> void:
	_set_arm(arm_l, "l", left, Basis(Vector3.BACK, raise_left))
	_set_arm(arm_r, "r", right, Basis(Vector3.BACK, -raise_right))


# One arm out by `amount` (0 to 1), pointing along `direction` in mascot
# space (it should lean to the arm's own side, or the arm crosses the body).
func point(left: bool, amount: float, direction: Vector3) -> void:
	var arm := arm_l if left else arm_r
	var side: float = arm.get_meta("side")
	var from := Vector3(side, 0.0, 0.0)
	var to := direction.normalized()
	var axis := from.cross(to)
	var basis := Basis.IDENTITY
	if axis.length() > 1e-5:
		basis = Basis(axis.normalized(), from.angle_to(to))
	_set_arm(arm, "l" if left else "r", amount, basis)


func _set_arm(arm: Node3D, key: String, amount: float, basis: Basis) -> void:
	var side: float = arm.get_meta("side")
	var length := lerpf(2.0, float(ARM_CUBES), clampf(amount, 0.0, 1.0))
	var pieces: Array = _arm_cubes[key]
	for i in range(pieces.size()):
		var piece: MeshInstance3D = pieces[i]
		piece.position = Vector3(side * minf(i + 0.5, length - 0.5) * P, 0.0, 0.0)
	arm.basis = basis


# The tip of an arm, in mascot space.
func arm_tip(left: bool) -> Vector3:
	var arm := arm_l if left else arm_r
	var key := "l" if left else "r"
	var pieces: Array = _arm_cubes[key]
	var tip: MeshInstance3D = pieces[pieces.size() - 1]
	return arm.transform * (tip.position + Vector3(float(arm.get_meta("side")) * 0.5 * P, 0.0, 0.0))


func height() -> float:
	return (LEG + H) * P


# A little hover: the body bobs and the legs paddle, from a phase in
# radians. `trail` swings the legs back from the hips (radians), for flying.
func hover(phase: float, trail := 0.0) -> void:
	body.position.y = 0.025 * sin(phase)
	var hip := Vector3(0.0, LEG * P, 0.0)
	for i in range(legs.size()):
		var leg: Node3D = legs[i]
		var swing := Basis(Vector3.RIGHT, trail + 0.12 * sin(phase * 2.0 + i * 1.6) * minf(trail * 3.0, 1.0))
		var lift := Vector3(0.0, body.position.y + 0.012 * sin(phase * 2.0 + i * 1.6), 0.0)
		leg.transform = Transform3D(swing, hip - swing * hip + lift)
