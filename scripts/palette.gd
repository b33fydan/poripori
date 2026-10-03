class_name Palette
extends RefCounted

# The palette journey. Each chapter of the message has its own night: dark
# paper tinted toward the chapter's colour, a light ink of it for outlines
# and stars, and the colour itself as the accent (the ring's bands). The
# colours follow the sculpture's region colours in data/arecibo/sections.json,
# so the ring takes the colour of the part of the message it is passing.
# The intro, before the message lights, is a plain blue night.
#
# Every shader reads the palette from global shader parameters (declared in
# project.godot), set here once a frame.

const PALETTES := {
	"intro": {"paper": "#0a0e2a", "ink": "#aab6ee", "accent": "#7d90e6"},
	# The message's numbers are white; a full white ring blew out the frame,
	# so this chapter's night is a cool silver.
	"numbers": {"paper": "#0c1133", "ink": "#c9d1ee", "accent": "#aeb9e2"},
	"elements": {"paper": "#140d33", "ink": "#d8ccfa", "accent": "#a68cf2"},
	"formulas": {"paper": "#04241b", "ink": "#c4f0d6", "accent": "#5ed98c"},
	"dna": {"paper": "#06183a", "ink": "#cde3fa", "accent": "#4fa3ea"},
	"human": {"paper": "#2b0a14", "ink": "#f6cccc", "accent": "#ee5a5a"},
	"solar_system": {"paper": "#271b05", "ink": "#f6e6bd", "accent": "#efc35c"},
	"telescope": {"paper": "#1d0c33", "ink": "#e6d2fa", "accent": "#b87de8"},
	# The B-roll's daylight: light paper, a navy ink for outlines and a deep
	# shadow tone. The numbers are white, so their day is a blueprint blue.
	"numbers_day": {"paper": "#eef1fa", "ink": "#1b2257", "accent": "#5a73d6", "shadow": "#22307a"},
	# Home: the deep navy night round Earth, for the reach and the touch.
	"home": {"paper": "#060a22", "ink": "#c4d3fa", "accent": "#4f8fe6"},
}

# The first row of each chapter's band of the message, top to bottom (rows
# between chapters are blank; a band starts halfway into the blank row).
const CHAPTER_ROWS := [
	["numbers", 0.0], ["elements", 4.5], ["formulas", 10.5], ["dna", 30.5],
	["human", 45.0], ["solar_system", 55.5], ["telescope", 59.5],
]


static func colors(palette: String) -> Dictionary:
	var out := {}
	var entry: Dictionary = PALETTES[palette]
	for role in ["paper", "ink", "accent"]:
		out[role] = Color(str(entry[role]))
	# Shade falls toward the paper at night; light-paper palettes name a
	# darker shadow instead.
	out["shadow"] = Color(str(entry["shadow"])) if entry.has("shadow") else out["paper"]
	return out


static func blend(a: Dictionary, b: Dictionary, amount: float) -> Dictionary:
	var out := {}
	var u := clampf(amount, 0.0, 1.0)
	for role in a.keys():
		out[role] = (a[role] as Color).lerp(b[role] as Color, u)
	return out


# The palette for a row of the message: its chapter's, crossing to the next
# over `width` rows either side of each boundary.
static func at_row(row: float, width := 0.06) -> Dictionary:
	var current := colors(str(CHAPTER_ROWS[0][0]))
	for i in range(1, CHAPTER_ROWS.size()):
		var start: float = CHAPTER_ROWS[i][1]
		var amount := smoothstep(start - width, start + width, row)
		if amount <= 0.0:
			break
		current = blend(current, colors(str(CHAPTER_ROWS[i][0])), amount)
	return current


static func chapter_at_row(row: float) -> String:
	var name := str(CHAPTER_ROWS[0][0])
	for entry in CHAPTER_ROWS:
		if row >= float(entry[1]):
			name = str(entry[0])
	return name


static func apply(palette: Dictionary) -> void:
	for role in ["paper", "ink", "accent", "shadow"]:
		var c := (palette[role] as Color).srgb_to_linear()
		RenderingServer.global_shader_parameter_set(role, Vector4(c.r, c.g, c.b, 1.0))
