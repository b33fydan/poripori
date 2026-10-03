extends SceneTree

# A contact sheet of MEGAVOX models in their own colours, numbered, for
# choosing models by eye. Local only: it reads the licensed files.
#
#   Godot --path . --resolution 1280x720 --script res://tools/godot/megavox_sheet.gd -- \
#     category=trees prefix=Tree first=1 count=40 out=<png>

const MegavoxScript := preload("res://scripts/megavox.gd")
const PaletteScript := preload("res://scripts/palette.gd")

var _frame := 0
var _out := ""


func _initialize() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else "1"
	_out = str(args.get("out", "/tmp/sheet.png"))
	var category := str(args.get("category", "trees"))
	var prefix := str(args.get("prefix", "Tree"))
	var first := int(args.get("first", "1"))
	var count := int(args.get("count", "40"))
	PaletteScript.apply(PaletteScript.colors("numbers_day"))
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#eceef6")
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world := WorldEnvironment.new()
	world.environment = env
	root.add_child(world)
	var columns := 10
	for i in range(count):
		var number := first + i
		var model: Node3D = MegavoxScript.load_model(category, "%s.%03d.glb" % [prefix, number])
		if model == null:
			continue
		MegavoxScript.print_look(model, func(c: Color) -> Color: return c)
		var holder := MegavoxScript.stand(model, 0.8)
		holder.position = Vector3((i % columns) * 1.2, -(i / columns) * 1.25, 0.0)
		root.add_child(holder)
		var label := Label3D.new()
		label.text = str(number)
		label.font_size = 28
		label.pixel_size = 0.004
		label.modulate = Color("#232a5e")
		label.position = holder.position + Vector3(0.0, -0.12, 0.3)
		root.add_child(label)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.6
	root.add_child(camera)
	var rows := int(ceil(count / float(columns)))
	camera.look_at_from_position(Vector3(5.4, -(rows - 1) * 0.62 + 0.4 + 3.0, 8.0), Vector3(5.4, -(rows - 1) * 0.62 + 0.4, 0.0), Vector3.UP)
	camera.make_current()
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_frame += 1
	if _frame == 4:
		root.get_texture().get_image().save_png(_out)
		quit()
