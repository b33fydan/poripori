extends SceneTree

# A model sheet: the astronaut from four sides in the print look, for
# checking the model without a shot. Saves one PNG per view.
#
#   Godot --path . --resolution 1280x720 --script res://tools/godot/model_sheet.gd -- out=<dir> [palette=numbers]

const AstronautScript := preload("res://scripts/astronaut.gd")
const SpaceScript := preload("res://scripts/space.gd")
const PaletteScript := preload("res://scripts/palette.gd")
const InkShader := preload("res://shaders/ink.gdshader")

var _camera: Camera3D
var _frame := 0
var _out := ""
var _views := [["front", 0.0], ["three-quarter", 40.0], ["side", 90.0], ["back", 180.0]]


func _initialize() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else "1"
	_out = str(args.get("out", "/tmp"))
	var palette := str(args.get("palette", "intro"))
	PaletteScript.apply(PaletteScript.colors(palette))
	var space := SpaceScript.new()
	root.add_child(space)
	var astronaut := AstronautScript.new()
	root.add_child(astronaut)
	astronaut.pose(0.3, 0.05, 0.0)
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
	var colors := PaletteScript.colors(palette)
	space.update(0.0, Vector3.ZERO, colors["ink"], colors["accent"], 0.0)
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	var index := _frame / 4
	if index >= _views.size():
		quit()
		return
	var view: Array = _views[index]
	if _frame % 4 == 0:
		# The rider faces +Z; an angle of 0 looks at its front.
		var angle := deg_to_rad(float(view[1]))
		_camera.look_at_from_position(Vector3(sin(angle), 0.35, cos(angle)) * 5.0 + Vector3(0, 0.75, 0), Vector3(0, 0.75, 0), Vector3.UP)
	elif _frame % 4 == 3:
		root.get_texture().get_image().save_png("%s/model-%s.png" % [_out, view[0]])
	_frame += 1
