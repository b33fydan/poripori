class_name Palette
extends RefCounted

# The palette journey. Each chapter of the message has its own night: dark
# paper tinted toward the chapter's colour, a light ink of it for outlines
# and stars, and the colour itself as the accent (the moon, the ring's
# bands). The colours are the sculpture's region colours in
# data/arecibo/sections.json, so the world matches the part being told.
# The intro, before the message begins, is a plain blue night.
#
# Every shader reads the palette from global shader parameters (declared in
# project.godot), set here once a frame.

const PALETTES := {
	"intro": {"paper": "#0a0e2a", "ink": "#b8c4ff", "accent": "#8ea2ff"},
	"numbers": {"paper": "#0c1133", "ink": "#eef1ff", "accent": "#f4f6ff"},
	"elements": {"paper": "#140d33", "ink": "#e3d9ff", "accent": "#b59cff"},
	"formulas": {"paper": "#04241b", "ink": "#d2fae3", "accent": "#6ef09c"},
	"dna": {"paper": "#06183a", "ink": "#d6ebff", "accent": "#5ab4ff"},
	"human": {"paper": "#2b0a14", "ink": "#ffd9d9", "accent": "#ff6464"},
	"solar_system": {"paper": "#271b05", "ink": "#fff1cc", "accent": "#ffd36b"},
	"telescope": {"paper": "#1d0c33", "ink": "#efdcff", "accent": "#c98bff"},
}


static func color(palette: String, role: String) -> Color:
	return Color(str(PALETTES[palette][role]))


# Blend from one palette to the next by `amount` (0..1) and set the globals.
static func apply(from: String, to: String, amount: float) -> void:
	for role in ["paper", "ink", "accent"]:
		var c := color(from, role).lerp(color(to, role), clampf(amount, 0.0, 1.0)).srgb_to_linear()
		RenderingServer.global_shader_parameter_set(role, Vector4(c.r, c.g, c.b, 1.0))


static func current(from: String, to: String, amount: float, role: String) -> Color:
	return color(from, role).lerp(color(to, role), clampf(amount, 0.0, 1.0))
