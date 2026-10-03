extends Node3D

# Look development for the reach (song 1:03-1:36): the astronaut floating up
# in space with a massive Earth behind, seen from the side and from above,
# and the touch, where the mascot reaches its little arm down to the glove.
# Earth turns the Caribbean (Arecibo, 18.34 N 66.75 W) toward the camera.
#
# options: view=side|top|touch. Timing to the song comes once the look is
# approved.

const AstronautScript := preload("res://scripts/astronaut.gd")
const MascotScript := preload("res://scripts/mascot.gd")
const EarthScript := preload("res://scripts/voxel_earth.gd")
const SpaceScript := preload("res://scripts/space.gd")
const PaletteScript := preload("res://scripts/palette.gd")
const InkShader := preload("res://shaders/ink.gdshader")

const ARECIBO := Vector2(18.34, -66.75)  # latitude, longitude

var options := {}
var timeline
var camera: Camera3D
var astronaut: Node3D
var mascot: Node3D
var earth: Node3D
var space: Node3D
var _palette: Dictionary


func setup(song_timeline) -> void:
	timeline = song_timeline
	_palette = PaletteScript.colors("home")
	PaletteScript.apply(_palette)
	space = SpaceScript.new()
	add_child(space)
	earth = EarthScript.new(56, 8.0)
	add_child(earth)
	astronaut = AstronautScript.new(Color("#5e8ec7"), false)
	add_child(astronaut)
	mascot = MascotScript.new()
	add_child(mascot)
	camera = Camera3D.new()
	camera.near = 0.05
	camera.far = 8000.0
	add_child(camera)
	camera.make_current()
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	var material := ShaderMaterial.new()
	material.shader = InkShader
	material.render_priority = 100
	mesh.material = material
	quad.mesh = mesh
	quad.extra_cull_margin = 16384.0
	camera.add_child(quad)


# Floating in zero g: limbs loose and a little spread, drifting slowly.
func _float_pose(t: float, reach_up: float) -> void:
	astronaut.pose_on_foot(0.0, 0.0, 0.0)
	var drift := sin(t * 0.7)
	astronaut.leg_l.rotation = Vector3(0.25 + 0.08 * drift, 0.0, 0.18)
	astronaut.leg_r.rotation = Vector3(-0.15 - 0.08 * drift, 0.0, -0.22)
	astronaut.boot_l.rotation = Vector3(-0.3, 0.0, -0.1)
	astronaut.boot_r.rotation = Vector3(0.2, 0.0, 0.1)
	astronaut.arm_r.rotation = Vector3(-0.2, 0.0, -0.55 - 0.1 * drift)
	# The left glove rises from loose at the side to straight up.
	astronaut.arm_l.rotation = Vector3(-0.1 * (1.0 - reach_up), 0.0, lerpf(0.6 + 0.1 * drift, 2.85, reach_up))
	astronaut.helmet.rotation = Vector3(lerpf(0.05, -0.35, reach_up), 0.0, 0.0)


# Turn Earth so Arecibo faces `toward` (a direction from Earth's centre).
func _face_arecibo(toward: Vector3) -> void:
	var dir := toward.normalized()
	var yaw := atan2(dir.x, dir.z)
	var pitch := asin(clampf(dir.y, -1.0, 1.0))
	earth.basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -(deg_to_rad(ARECIBO.x) - pitch) * -1.0) * Basis(Vector3.UP, -deg_to_rad(ARECIBO.y))
	earth.clouds.rotation.y = 0.4


func update(t: float) -> void:
	RenderingServer.global_shader_parameter_set("song_time", t)
	PaletteScript.apply(_palette)
	var view := str(options.get("view", "side"))
	astronaut.position = Vector3.ZERO
	astronaut.rotation = Vector3(0.15, 0.6, -0.1)
	mascot.visible = false
	if view == "side":
		_float_pose(t, 0.0)
		# Looking down on him, Earth's face fills the frame behind him with
		# its limb high over his head: he floats in front of the planet.
		earth.position = Vector3(-600.0, -700.0, -60.0)
		camera.fov = 40.0
		camera.look_at_from_position(Vector3(6.0, 4.5, 1.0), Vector3(0.0, 0.1, 0.0), Vector3.UP)
	elif view == "top":
		_float_pose(t, 0.0)
		astronaut.rotation = Vector3(-0.35, 0.9, 0.12)
		earth.position = Vector3(40.0, -1150.0, 60.0)
		camera.fov = 44.0
		camera.look_at_from_position(Vector3(0.6, 8.5, 1.4), Vector3(0.0, 0.4, 0.0), Vector3.UP)
	else:
		_float_pose(t, 1.0)
		astronaut.rotation = Vector3(0.05, 0.4, 0.0)
		earth.position = Vector3(-520.0, -470.0, -760.0)
		var glove: Vector3 = astronaut.torso.global_transform * (astronaut.arm_l.position + astronaut.arm_l.basis * Vector3(0.0, -0.45, 0.0))
		mascot.visible = true
		# Up and to the right of the glove, its right arm (pointing -X)
		# slid out and angled down to meet it.
		mascot.position = glove + Vector3(1.05, 0.62, 0.0)
		mascot.rotation = Vector3.ZERO
		var root: Vector3 = mascot.transform * mascot.arm_r.position
		var to_glove := glove - root
		mascot.reach(0.0, 1.0, 0.0, -atan2(-to_glove.y, -to_glove.x))
		mascot.hover(t * 3.0)
		camera.fov = 34.0
		camera.look_at_from_position(glove + Vector3(1.4, 1.2, 6.0), glove + Vector3(0.15, -0.55, 0.0), Vector3.UP)
	_face_arecibo(camera.global_position - earth.position)
	space.update(t, camera.global_position, _palette["ink"], _palette["accent"], 0.0)
