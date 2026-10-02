extends SceneTree

# Renders a shot of the film. Every frame shows one song time, from + n / FPS,
# so any moment can be re-rendered exactly. The audio is muxed in afterwards
# by tools/render.sh, untouched; this renders picture only.
#
#   Godot --path . --resolution 1280x720 --fixed-fps 30 \
#     --write-movie renders/<name>.avi --script res://scripts/film.gd -- \
#     shot=sample song=lost-in-the-void from=6 to=26 [beats]
#
# `beats` draws a flash on every beat (bigger and red on the bar's first) for
# checking sync. `stills=7.5,16,22 out=<dir>` saves PNG stills at those song
# times instead, then quits; no Movie Maker needed.

const SongTimelineScript := preload("res://scripts/song_timeline.gd")
const FPS := 30.0

var _timeline
var _shot: Node
var _from := 0.0
var _to := 0.0
var _frame := 0
var _stills: Array = []
var _out_dir := ""
var _flash: ColorRect
var _label: Label


func _initialize() -> void:
	var args := _args()
	_timeline = SongTimelineScript.load_song(str(args.get("song", "lost-in-the-void")))
	if _timeline == null:
		quit(1)
		return
	_from = float(args.get("from", "0"))
	_to = float(args.get("to", str(_timeline.duration)))
	var shot_path := "res://scripts/shots/%s.gd" % str(args.get("shot", "sample"))
	var shot_script := load(shot_path) as GDScript
	if shot_script == null or not shot_script.can_instantiate():
		push_error("[Film] can't load %s" % shot_path)
		quit(1)
		return
	_shot = shot_script.new()
	root.add_child(_shot)
	# The shot sees the same key=value arguments, and how far it must reach.
	var reach := _to
	if args.has("stills"):
		reach = 0.0
		for value in str(args["stills"]).split(","):
			reach = maxf(reach, float(value))
	args["to"] = str(reach)
	_shot.options = args
	_shot.setup(_timeline)
	if args.has("beats"):
		_build_beat_flash()
	if args.has("stills"):
		for value in str(args["stills"]).split(","):
			_stills.append(float(value))
		_out_dir = str(args.get("out", "res://renders/stills"))
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	print("[Film] %s, song %s, %.3f to %.3f s (%d frames)" % [shot_path, _timeline.song_id, _from, _to, int(round((_to - _from) * FPS))])
	process_frame.connect(_on_frame)


func _args() -> Dictionary:
	var out := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.split("=", true, 1)
		out[parts[0]] = parts[1] if parts.size() > 1 else "1"
	return out


func _on_frame() -> void:
	if not _stills.is_empty():
		_on_still_frame()
		return
	# The frame that calls quit() still renders and is recorded, so quit on
	# the frame that poses the last moment, not the one after it.
	_pose(_from + _frame / FPS)
	_frame += 1
	if _frame >= int(round((_to - _from) * FPS)):
		quit()


# A still is posed, given three frames to render, then saved.
func _on_still_frame() -> void:
	var index := _frame / 4
	var step := _frame % 4
	if index >= _stills.size():
		quit()
		return
	var t: float = _stills[index]
	if step == 0:
		_pose(t)
	elif step == 3:
		var path := "%s/still-%06.2f.png" % [ProjectSettings.globalize_path(_out_dir), t]
		root.get_texture().get_image().save_png(path)
		print("[Film] saved %s" % path)
	_frame += 1


func _pose(t: float) -> void:
	_shot.update(t)
	if _flash:
		var on_bar: bool = _timeline.since_bar(t) < _timeline.period * 0.5
		var pulse: float = _timeline.beat_pulse(t, 0.1)
		_flash.color = Color(1.0, 0.2, 0.2, pulse) if on_bar else Color(1.0, 1.0, 1.0, pulse)
		_label.text = "bar %d · beat %d · %.3f s" % [int(floor(_timeline.bar(t))), int(floor(fposmod(_timeline.beat(t), 4.0))) + 1, t]


func _build_beat_flash() -> void:
	var layer := CanvasLayer.new()
	root.add_child(layer)
	_flash = ColorRect.new()
	_flash.position = Vector2(1180, 20)
	_flash.size = Vector2(80, 80)
	layer.add_child(_flash)
	_label = Label.new()
	_label.position = Vector2(20, 20)
	_label.add_theme_font_size_override("font_size", 22)
	layer.add_child(_label)
