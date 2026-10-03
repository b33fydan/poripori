class_name Megavox
extends RefCounted

# The owner's licensed MEGAVOX models, from the git-ignored
# assets/licensed_local/megavox/ (filled by tools/sync_licensed_assets.sh).
# Every loader returns null when a model isn't there, so scenes still build
# without the licensed files. print_look() swaps a model's surfaces for the
# film's print shader, recoloured into the palette.

const ROOT := "res://assets/licensed_local/megavox"
const PrintShader := preload("res://shaders/print.gdshader")


static func load_model(category: String, file: String) -> Node3D:
	var path := "%s/%s/%s" % [ROOT, category, file]
	if not ResourceLoader.exists(path):
		return null
	var scene := load(path) as PackedScene
	return scene.instantiate() as Node3D if scene else null


# Every surface gets the print shader, its colour passed through `recolor`
# (Color -> Color, sRGB in and out).
static func print_look(node: Node, recolor: Callable) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		for surface in range(mesh_instance.mesh.get_surface_count()):
			var source := mesh_instance.get_active_material(surface)
			var albedo := Color.WHITE
			if source is BaseMaterial3D:
				albedo = (source as BaseMaterial3D).albedo_color
			var material := ShaderMaterial.new()
			material.shader = PrintShader
			var linear: Color = (recolor.call(albedo) as Color).srgb_to_linear()
			material.set_shader_parameter("tint", Vector4(linear.r, linear.g, linear.b, 1.0))
			mesh_instance.set_surface_override_material(surface, material)
	for child in node.get_children():
		print_look(child, recolor)


# The model's bounds in its own space, from every mesh under it.
static func bounds(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mesh_instance in node.find_children("*", "MeshInstance3D", true, false):
		var mi := mesh_instance as MeshInstance3D
		var xf := Transform3D.IDENTITY
		var current: Node = mi
		while current != null and current != node:
			xf = (current as Node3D).transform * xf
			current = current.get_parent()
		var part: AABB = xf * mi.mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box


# Stand a model's base on its parent's origin, centred, `height` units tall.
static func stand(node: Node3D, height: float) -> Node3D:
	var holder := Node3D.new()
	var box := bounds(node)
	var s := height / maxf(box.size.y, 0.001)
	node.scale = Vector3.ONE * s
	node.position = -Vector3(box.get_center().x, box.position.y, box.get_center().z) * s
	holder.add_child(node)
	return holder
