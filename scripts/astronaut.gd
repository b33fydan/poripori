class_name Astronaut
extends Node3D

# The little astronaut on its board, built from real cubes in AgentVille's
# farmhand style: a box body, swinging limbs, and a voxel face (now behind a
# visor). Every part is a VoxelPart, so the whole rider can burst later.
#
# Rig space: the board's long axis is +X (nose first, the way it travels),
# the deck's top is y = 0, and the rider faces +Z, side-on like a surfer, so
# its left side (+X) leads. Voxel unit U = 0.05: the rider is 30 voxels tall.

const VoxelPartScript := preload("res://scripts/voxel_part.gd")
const U := 0.05

const SUIT := Color("#f1f0ea")
const SUIT_SHADE := Color("#d9dbe0")
const TRIM := Color("#8d93a3")
const DARK := Color("#3b404c")
const ACCENT := Color("#5e8ec7")  # AgentVille's farmhand blue
const GOLD := Color("#f2cf6b")    # AgentVille's accent yellow
const SKIN := Color("#ffd8aa")
const FACE := Color("#2f241f")
const BLUSH := Color("#f5a9a0")
const DECK := Color("#f6efe2")

var board: Node3D
var board_glow: Node3D
var rider: Node3D
var torso: Node3D
var helmet: Node3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var boot_l: Node3D
var boot_r: Node3D
var antenna_tip: Node3D

# Where the trail leaves the board, in rig space: the tail's underside.
var tail_point := Vector3(-12.5 * U, -1.5 * U, 0.0)


func _init() -> void:
	name = "Astronaut"
	_build_board()
	rider = Node3D.new()
	rider.name = "Rider"
	add_child(rider)
	_build_body()
	pose(0.0, 0.0, 0.0)


func _part(pivot := Vector3.ZERO) -> Node3D:
	return VoxelPartScript.new(U, pivot)


# --- The board -----------------------------------------------------------------

func _board_half_width(x: int) -> int:
	if x >= 11:
		return 0
	if x >= 9:
		return 1
	if x >= 7:
		return 2
	if x <= -12:
		return 2
	return 3


func _build_board() -> void:
	# The board is an odd number of cells wide, so its pivot sits mid-cell.
	board = _part(Vector3(0.0, 0.0, 0.5))
	board.name = "Board"
	board_glow = _part(Vector3(0.0, 0.0, 0.5))
	board_glow.name = "BoardGlow"
	for x in range(-12, 12):
		var hw := _board_half_width(x)
		for z in range(-hw, hw + 1):
			var deck := DECK
			if z == 0 and x > -10 and x < 9:
				deck = ACCENT
			elif absi(z) == hw and hw >= 2:
				deck = GOLD
			board.paint(Vector3i(x, -1, z), deck)
			board_glow.paint(Vector3i(x, -2, z), Color(0.35, 0.9, 0.85), 1.0)
	# A small fin under the tail.
	board.box(Vector3i(-11, -4, 0), Vector3i(-8, -2, 1), ACCENT)
	board.build()
	board_glow.build(2.0)
	add_child(board)
	add_child(board_glow)


# --- The rider -------------------------------------------------------------------

func _build_body() -> void:
	# Legs hang from the hips; each boot hangs from its ankle and stays flat.
	leg_l = _leg(1)
	leg_r = _leg(-1)
	# The torso's origin is the hip line's centre.
	torso = _part(Vector3(0.0, 0.0, 0.0))
	torso.name = "Torso"
	torso.box(Vector3i(-5, 0, -3), Vector3i(5, 9, 3), SUIT)
	torso.box(Vector3i(-5, 0, -3), Vector3i(5, 1, 3), TRIM)          # belt
	torso.box(Vector3i(-4, 9, -3), Vector3i(4, 10, 3), TRIM)         # neck ring
	torso.box(Vector3i(-2, 4, 2), Vector3i(2, 7, 3), Color("#5a6070"))  # chest panel
	torso.paint(Vector3i(-2, 6, 2), Color(1.0, 0.36, 0.30), 1.0)
	torso.paint(Vector3i(-1, 6, 2), Color(1.0, 0.82, 0.25), 1.0)
	torso.paint(Vector3i(0, 6, 2), Color(0.25, 0.85, 0.78), 1.0)
	torso.paint(Vector3i(1, 4, 2), ACCENT)
	torso.box(Vector3i(-5, 7, -3), Vector3i(-4, 9, 3), ACCENT)       # shoulder trim
	torso.box(Vector3i(4, 7, -3), Vector3i(5, 9, 3), ACCENT)
	# Backpack with two little thrusters.
	torso.box(Vector3i(-4, 1, -6), Vector3i(4, 9, -3), SUIT_SHADE)
	torso.box(Vector3i(-4, 8, -6), Vector3i(4, 9, -3), TRIM)
	torso.box(Vector3i(-3, 0, -5), Vector3i(-1, 1, -4), DARK)
	torso.box(Vector3i(1, 0, -5), Vector3i(3, 1, -4), DARK)
	torso.build(1.5)
	rider.add_child(torso)
	rider.add_child(leg_l)
	rider.add_child(leg_r)
	arm_l = _arm(1)
	arm_r = _arm(-1)
	torso.add_child(arm_l)
	torso.add_child(arm_r)
	_build_helmet()


func _leg(side: int) -> Node3D:
	var leg := _part(Vector3(0.0, 0.0, 0.0))
	leg.name = "LegL" if side > 0 else "LegR"
	leg.box(Vector3i(-2, -6, -2), Vector3i(2, 0, 2), SUIT)
	leg.box(Vector3i(-2, -4, -2), Vector3i(2, -3, 2), SUIT_SHADE)    # knee band
	leg.build()
	var boot := _part(Vector3(0.0, 0.0, 0.0))
	boot.name = "Boot"
	boot.box(Vector3i(-2, -3, -2), Vector3i(2, 0, 3), TRIM)
	boot.box(Vector3i(-2, -3, -2), Vector3i(2, -2, 3), DARK)         # sole
	boot.build()
	boot.position = Vector3(0.0, -6.0 * U, 0.0)
	leg.add_child(boot)
	if side > 0:
		boot_l = boot
	else:
		boot_r = boot
	return leg


func _arm(side: int) -> Node3D:
	var arm := _part(Vector3(0.0, 0.0, 0.0))
	arm.name = "ArmL" if side > 0 else "ArmR"
	arm.box(Vector3i(-1, -7, -1), Vector3i(2, 0, 2), SUIT)
	arm.box(Vector3i(-1, -6, -1), Vector3i(2, -5, 2), ACCENT)        # cuff
	arm.box(Vector3i(-1, -9, -1), Vector3i(2, -7, 2), TRIM)          # glove
	arm.build()
	# Shoulders sit just outside the torso, near its top.
	arm.position = Vector3(side * 5.5 * U, 8.5 * U, 0.0)
	return arm


func _build_helmet() -> void:
	# The helmet's origin is the neck ring's top centre; its front faces +Z.
	helmet = Node3D.new()
	helmet.name = "Helmet"
	helmet.position = Vector3(0.0, 10.0 * U, 0.0)
	torso.add_child(helmet)
	var shell := _part(Vector3(0.0, 0.0, 0.0))
	shell.name = "Shell"
	shell.box(Vector3i(-6, 0, -5), Vector3i(6, 11, 6), SUIT)
	shell.carve(Vector3i(-5, 1, -4), Vector3i(5, 10, 5))
	# The visor's frame, and its opening through the front.
	shell.box(Vector3i(-5, 2, 5), Vector3i(5, 10, 6), ACCENT)
	shell.carve(Vector3i(-4, 3, 5), Vector3i(4, 9, 6))
	# Ear discs and an antenna with a glowing tip.
	shell.box(Vector3i(-7, 4, -1), Vector3i(-6, 8, 3), ACCENT)
	shell.box(Vector3i(6, 4, -1), Vector3i(7, 8, 3), ACCENT)
	shell.box(Vector3i(3, 11, 0), Vector3i(4, 13, 1), TRIM)
	# A stripe over the crown and down the back, so the helmet reads from behind.
	shell.box(Vector3i(-1, 10, -5), Vector3i(1, 11, 6), ACCENT)
	shell.box(Vector3i(-1, 2, -5), Vector3i(1, 11, -4), ACCENT)
	shell.build()
	helmet.add_child(shell)
	antenna_tip = _part(Vector3(0.0, 0.0, 0.0))
	antenna_tip.paint(Vector3i(3, 13, 0), GOLD, 1.0)
	antenna_tip.build(3.0)
	helmet.add_child(antenna_tip)
	# The farmhand's face inside, right behind the glass.
	var head := _part(Vector3(0.0, 0.0, 0.0))
	head.name = "Head"
	head.box(Vector3i(-4, 2, -3), Vector3i(4, 9, 4), SKIN)
	head.box(Vector3i(-4, 8, -3), Vector3i(4, 9, 4), Color("#6b4a35"))   # hair line
	head.box(Vector3i(-3, 5, 3), Vector3i(-2, 7, 4), FACE)              # eyes
	head.box(Vector3i(2, 5, 3), Vector3i(3, 7, 4), FACE)
	head.paint(Vector3i(-4, 4, 3), BLUSH)
	head.paint(Vector3i(3, 4, 3), BLUSH)
	head.box(Vector3i(-1, 3, 3), Vector3i(1, 4, 4), FACE)               # mouth
	head.build()
	helmet.add_child(head)
	# The glass: one pane (cubes would show seams through each other).
	var glass := MeshInstance3D.new()
	glass.name = "Visor"
	var pane := BoxMesh.new()
	pane.size = Vector3(8.0 * U, 6.0 * U, 0.6 * U)
	var glass_material := StandardMaterial3D.new()
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.albedo_color = Color(0.45, 0.7, 1.0, 0.28)
	glass_material.metallic = 0.2
	glass_material.roughness = 0.04
	glass_material.rim_enabled = true
	glass_material.rim = 0.6
	pane.material = glass_material
	glass.mesh = pane
	glass.position = Vector3(0.0, 6.0 * U, 4.7 * U)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	helmet.add_child(glass)
	# A glint across the glass's upper corner.
	var glint := _part(Vector3(0.0, 0.0, 0.0))
	glint.paint(Vector3i(-3, 8, 5), Color.WHITE, 0.6)
	glint.paint(Vector3i(-2, 7, 5), Color.WHITE, 0.6)
	glint.build(1.0)
	glint.scale = Vector3(0.6, 0.6, 0.2)
	glint.position = Vector3(-1.2 * U, 2.6 * U, 3.9 * U)
	helmet.add_child(glint)


# --- Posing ------------------------------------------------------------------------

# crouch: 0 standing tall, 1 deep crouch. lean: forward lean in radians.
# look: how far the head turns from the rider's front toward travel (0..1).
func pose(crouch: float, lean: float, look: float, arms := Vector4(1.15, 0.3, -0.9, 0.35)) -> void:
	# Wider legs lower the hips: a surfer's stance.
	var splay := deg_to_rad(lerpf(18.0, 38.0, crouch))
	var hip_height := (6.0 * cos(splay) + 3.0) * U
	torso.position = Vector3(0.0, hip_height, 0.0)
	torso.rotation = Vector3(lean, deg_to_rad(18.0) * look, 0.0)
	leg_l.position = Vector3(2.0 * U, hip_height, 0.0)
	leg_r.position = Vector3(-2.0 * U, hip_height, 0.0)
	leg_l.rotation = Vector3(0.0, 0.0, splay)
	leg_r.rotation = Vector3(0.0, 0.0, -splay)
	boot_l.rotation = Vector3(0.0, 0.0, -splay)
	boot_r.rotation = Vector3(0.0, 0.0, splay)
	helmet.rotation = Vector3(-lean * 0.6, deg_to_rad(62.0) * look, 0.0)
	# arms: x = lead arm out, y = lead arm forward, z = rear arm out, w = rear arm back.
	arm_l.rotation = Vector3(-arms.y, 0.0, arms.x)
	arm_r.rotation = Vector3(-arms.w, 0.0, arms.z)
