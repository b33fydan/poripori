class_name Mascot
extends Node3D

# The Claude mascot: Claude Code's little orange pixel creature, rebuilt in
# voxels from its pixel layout (no logo, no name; the owner's direction).
#
# The terminal art is 16 pixels wide: a body 12 wide and 4 tall, its eyes two
# dark notches in its second row, a stubby arm two pixels long out of each
# side in its third row, and four one-pixel legs. Here every pixel is a cube
# P units across and the body is 4 cubes deep (any deeper and it reads as a
# loaf from the side; the original is a front-facing sprite). The arms telescope: reach()
# slides each one out of the body, for the moment it touches the astronaut's
# glove.
#
# Mascot space: it faces +Z, its legs' feet at y = 0, centred on x.

const VoxelPartScript := preload("res://scripts/voxel_part.gd")
const P := 0.09
const ORANGE := Color("#d97757")
const EYE := Color("#2b1d16")
const ARM_CUBES := 7  # the longest an arm can reach, in cubes

var body: Node3D
var arm_l: Node3D  # +X side (its left as it faces +Z)
var arm_r: Node3D
var legs: Array = []
var _arm_cubes := {"l": [], "r": []}


func _init() -> void:
	name = "Mascot"
	# Pixel rows, top to bottom: '#' body, 'o' an eye notch, '.' empty.
	var rows := [
		"...############.",
		"...##o######o##.",
		"...############.",
		"...############.",
	]
	body = VoxelPartScript.new(P, Vector3(9.0, 0.0, 2.0))
	for r in range(rows.size()):
		var row: String = rows[r]
		var y := 4 - r  # legs take y = 0
		for c in range(row.length()):
			var ch := row[c]
			if ch == ".":
				continue
			for z in range(4):
				if ch == "o" and z == 3:
					continue  # the notch: open at the front...
				var color := EYE if ch == "o" else ORANGE
				body.paint(Vector3i(c, y, z), color)
	body.build()
	add_child(body)
	# Four legs, one pixel each, in the middle of its depth.
	for c in [4, 6, 11, 13]:
		var leg := VoxelPartScript.new(P, Vector3(9.0, 0.0, 2.0))
		leg.paint(Vector3i(c, 0, 1), ORANGE)
		leg.paint(Vector3i(c, 0, 2), ORANGE)
		leg.build()
		add_child(leg)
		legs.append(leg)
	arm_l = _arm("l", 1.0)
	arm_r = _arm("r", -1.0)
	reach(0.0, 0.0)


# An arm: ARM_CUBES cubes that stack inside one another when short and slide
# out to full length, two cubes long at rest, as in the pixel art.
func _arm(key: String, side: float) -> Node3D:
	var arm := Node3D.new()
	# The arm comes out of the body's side at the third pixel row.
	arm.position = Vector3(side * 6.0 * P, 2.5 * P, 0.0)
	var cube := BoxMesh.new()
	cube.size = Vector3(P, P, 2.0 * P)
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/print.gdshader")
	var linear := ORANGE.srgb_to_linear()
	material.set_shader_parameter("tint", Vector4(linear.r, linear.g, linear.b, 1.0))
	cube.material = material
	for i in range(ARM_CUBES):
		var piece := MeshInstance3D.new()
		piece.mesh = cube
		arm.add_child(piece)
		(_arm_cubes[key] as Array).append(piece)
	arm.set_meta("side", side)
	add_child(arm)
	return arm


# Arm lengths from 0 (the resting two cubes) to 1 (fully out), and where
# each points: raise lifts it from sideways toward up, in radians.
func reach(left: float, right: float, raise_left := 0.0, raise_right := 0.0) -> void:
	_set_arm(arm_l, "l", left, raise_left)
	_set_arm(arm_r, "r", right, raise_right)


func _set_arm(arm: Node3D, key: String, amount: float, raise: float) -> void:
	var side: float = arm.get_meta("side")
	var length := lerpf(2.0, float(ARM_CUBES), clampf(amount, 0.0, 1.0))
	var pieces: Array = _arm_cubes[key]
	for i in range(pieces.size()):
		var piece: MeshInstance3D = pieces[i]
		var along := minf(i + 0.5, length - 0.5)
		piece.position = Vector3(side * along * P, 0.0, 0.0)
	arm.rotation = Vector3(0.0, 0.0, side * raise)


# The glove-touching tip of an arm, in mascot space.
func arm_tip(left: bool) -> Vector3:
	var arm := arm_l if left else arm_r
	var key := "l" if left else "r"
	var pieces: Array = _arm_cubes[key]
	var tip: MeshInstance3D = pieces[pieces.size() - 1]
	return arm.transform * (tip.position + Vector3(float(arm.get_meta("side")) * 0.5 * P, 0.0, 0.0))


# A little hover: legs paddle and the body bobs, from a phase in radians.
func hover(phase: float) -> void:
	body.position.y = 0.03 * sin(phase)
	for i in range(legs.size()):
		var leg: Node3D = legs[i]
		leg.position.y = body.position.y - 0.02 * (0.5 + 0.5 * sin(phase * 2.0 + i * 1.6))
