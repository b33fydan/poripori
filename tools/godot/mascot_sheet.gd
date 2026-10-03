extends SceneTree

# A model sheet for the mascot next to the astronaut: front, three-quarter,
# side and top, then the moment of reaching (its arm out, the astronaut's
# glove up to meet it).
#
#   Godot --path . --resolution 1280x720 --script res://tools/godot/mascot_sheet.gd -- out=<dir>

const MascotScript := preload("res://scripts/mascot.gd")
const AstronautScript := preload("res://scripts/astronaut.gd")
const SpaceScript := preload("res://scripts/space.gd")
const PaletteScript := preload("res://scripts/palette.gd")
const InkShader := preload("res://shaders/ink.gdshader")

var _camera: Camera3D
var _mascot: Node3D
var _astronaut: Node3D
var _frame := 0
var _out := ""
var _views := [["front", 0.0, 0.25, false], ["three-quarter", 40.0, 0.35, false], ["side", 90.0, 0.25, false], ["top", 20.0, 2.4, false], ["reach", 25.0, 0.4, true]]


func _initialize() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else "1"
	_out = str(args.get("out", "/tmp"))
	var colors := PaletteScript.colors("intro")
	PaletteScript.apply(colors)
	var space := SpaceScript.new()
	root.add_child(space)
	space.update(0.0, Vector3.ZERO, colors["ink"], colors["accent"], 0.0)
	_astronaut = AstronautScript.new(Color("#5e8ec7"), false)
	_astronaut.position = Vector3(-0.85, 0.0, 0.0)
	root.add_child(_astronaut)
	_astronaut.pose_on_foot(0.0, 0.0, 0.0)
	_mascot = MascotScript.new()
	_mascot.position = Vector3(0.55, 0.55, 0.0)
	root.add_child(_mascot)
	_camera = Camera3D.new()
	_camera.fov = 30.0
	root.add_child(_camera)
	_camera.make_current()
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	var material := ShaderMaterial.new()
	material.shader = InkShader
	material.render_priority = 100
	mesh.material = material
	quad.mesh = mesh
	quad.extra_cull_margin = 16384.0
	_camera.add_child(quad)
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	var index := _frame / 4
	if index >= _views.size():
		quit()
		return
	var view: Array = _views[index]
	if _frame % 4 == 0:
		var reaching: bool = view[3]
		# Reaching: the mascot's +X arm slides out and up toward the glove.
		_mascot.reach(1.0 if reaching else 0.0, 0.0, 0.5 if reaching else 0.0, 0.0)
		_mascot.rotation.y = deg_to_rad(-90.0) if reaching else 0.0
		_mascot.position = Vector3(0.75, 1.1, 0.0) if reaching else Vector3(0.55, 0.55, 0.0)
		var arms := Vector4(0.0, 0.0, 0.0, 0.0)
		_astronaut.pose_on_foot(0.0, 0.0, 0.0)
		if reaching:
			_astronaut.arm_l.rotation = Vector3(0.0, 0.0, 2.3)
		var angle := deg_to_rad(float(view[1]))
		var lift: float = view[2]
		var centre := Vector3(0.0, 0.7, 0.0)
		var offset := Vector3(sin(angle), lift, cos(angle)).normalized() * 5.2
		_camera.look_at_from_position(centre + offset, centre, Vector3.UP)
	elif _frame % 4 == 3:
		root.get_texture().get_image().save_png("%s/mascot-%s.png" % [_out, view[0]])
	_frame += 1
