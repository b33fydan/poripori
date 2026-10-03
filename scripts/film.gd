extends SceneTree

# Renders a shot of the film to PNG frames. Frame n of a video shows song
# time start + n / FPS (start defaults to from), so any moment can be
# re-rendered exactly, and a segment of a longer edit (from..to) renders
# just its own frames, numbered on the whole video's clock. The audio is
# muxed in afterwards by tools/render.sh, untouched; this renders picture only.
#
#   Godot --path . --resolution 1280x720 --script res://scripts/film.gd -- \
#     shot=opening song=lost-in-the-void from=0 to=40 frames=<dir> \
#     [start=0] [size=1280x720] [dither=1] [blur=6 shutter=0.5] [beats] [any shot option=value]
#
# The shot renders into an offscreen viewport of `size` (default 1920x1080),
# and each frame is saved the moment it has been drawn. The window only
# shows a preview, so it can stay small: Movie Maker records the window
# itself, and a 1080p window gets maximized and misframed on this Mac's
# 1920x1080 screen. Halftone dots and ink lines scale with `size`.
#
# The film uses flat, solid tones; `dither=1` brings back the halftone dots.
#
# `blur=N` renders N moments spread across a `shutter` (a fraction of the
# frame: 0.5 is a film camera's 180 degrees) centred on each frame's song
# time, saved as sub%08d.png (frame n's are n*N to n*N+N-1); the render tools
# average each group into the frame, which is motion blur. `beats` draws a
# flash on every beat (red on the bar's first) for checking sync.
# `stills=7.5,16,22 out=<dir>` saves PNG stills at those song times instead.

const SongTimelineScript := preload("res://scripts/song_timeline.gd")
const FPS := 30.0
const WARM_UP := 3  # frames drawn before the first one is kept

var _timeline
var _shot: Node
var _viewport: SubViewport
var _size := Vector2i(1920, 1080)
var _start := 0.0
var _from := 0.0
var _to := 0.0
var _end_index := 0
var _frame := 0
var _blur := 1
var _shutter := 0.5
var _sub := 0
var _warm := 0
var _pending := ""  # where the frame being drawn should be saved
var _stills: Array = []
var _frames_dir := ""
var _out_dir := ""
var _flash: ColorRect
var _label: Label


func _initialize() -> void:
	var args := _args()
	if args.has("size"):
		var wh := str(args["size"]).split("x")
		_size = Vector2i(int(wh[0]), int(wh[1]))
	RenderingServer.global_shader_parameter_set("print_scale", _size.y / 720.0)
	_blur = maxi(1, int(args.get("blur", "1")))
	_shutter = float(args.get("shutter", "0.5"))
	RenderingServer.global_shader_parameter_set("dither", 1.0 if str(args.get("dither", "0")) == "1" else 0.0)
	_timeline = SongTimelineScript.load_song(str(args.get("song", "lost-in-the-void")))
	if _timeline == null:
		quit(1)
		return
	_from = float(args.get("from", "0"))
	_to = float(args.get("to", str(_timeline.duration)))
	_start = float(args.get("start", str(_from)))
	# The segment's frames: every n whose song time start + n / FPS falls
	# in [from, to).
	_frame = int(ceil((_from - _start) * FPS - 0.0001))
	_end_index = int(ceil((_to - _start) * FPS - 0.0001))
	_build_viewport()
	var shot_path := "res://scripts/shots/%s.gd" % str(args.get("shot", "opening"))
	var shot_script := load(shot_path) as GDScript
	if shot_script == null or not shot_script.can_instantiate():
		push_error("[Film] can't load %s" % shot_path)
		quit(1)
		return
	_shot = shot_script.new()
	_viewport.add_child(_shot)
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
		_out_dir = ProjectSettings.globalize_path(str(args.get("out", "res://renders/stills")))
		DirAccess.make_dir_recursive_absolute(_out_dir)
	else:
		_frames_dir = ProjectSettings.globalize_path(str(args.get("frames", "res://renders/frames")))
		DirAccess.make_dir_recursive_absolute(_frames_dir)
	print("[Film] %s, song %s, %.3f to %.3f s (frames %d to %d) at %dx%d" % [shot_path, _timeline.song_id, _from, _to, _frame, _end_index - 1, _size.x, _size.y])
	process_frame.connect(_on_frame)
	RenderingServer.frame_post_draw.connect(_on_drawn)


func _args() -> Dictionary:
	var out := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.split("=", true, 1)
		out[parts[0]] = parts[1] if parts.size() > 1 else "1"
	return out


# The film renders offscreen at full size; the window shows it scaled down.
func _build_viewport() -> void:
	_viewport = SubViewport.new()
	_viewport.size = _size
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_2X
	_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)
	var preview := TextureRect.new()
	preview.texture = _viewport.get_texture()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(preview)


# Pose a frame before it's drawn; _on_drawn saves it once the GPU has drawn it.
func _on_frame() -> void:
	if not _pending.is_empty():
		return
	if not _stills.is_empty():
		if _frame >= _stills.size():
			quit()
			return
		var t: float = _stills[_frame]
		_pose(t)
		if _warm >= WARM_UP:
			_pending = "%s/still-%06.2f.png" % [_out_dir, t]
		_warm += 1
		return
	if _frame >= _end_index:
		quit()
		return
	var t := _start + _frame / FPS
	if _blur > 1:
		t += ((_sub + 0.5) / _blur - 0.5) * _shutter / FPS
	_pose(t)
	if _warm >= WARM_UP:
		if _blur > 1:
			_pending = "%s/sub%08d.png" % [_frames_dir, _frame * _blur + _sub]
		else:
			_pending = "%s/frame%06d.png" % [_frames_dir, _frame]
	_warm += 1


func _on_drawn() -> void:
	if _pending.is_empty():
		return
	_viewport.get_texture().get_image().save_png(_pending)
	if not _stills.is_empty():
		print("[Film] saved %s" % _pending)
		_warm = 0
	_pending = ""
	if not _stills.is_empty() or _blur <= 1:
		_frame += 1
		return
	_sub += 1
	if _sub >= _blur:
		_sub = 0
		_frame += 1


func _pose(t: float) -> void:
	_shot.update(t)
	if _flash:
		var on_bar: bool = _timeline.since_bar(t) < _timeline.period * 0.5
		var pulse: float = _timeline.beat_pulse(t, 0.1)
		_flash.color = Color(1.0, 0.2, 0.2, pulse) if on_bar else Color(1.0, 1.0, 1.0, pulse)
		_label.text = "bar %d · beat %d · %.3f s" % [int(floor(_timeline.bar(t))), int(floor(fposmod(_timeline.beat(t), 4.0))) + 1, t]


# Drawn in the film's own viewport so it's in the saved frames; laid out on a
# 1280x720 grid and scaled to the render size.
func _build_beat_flash() -> void:
	var scale := _size.y / 720.0
	var layer := CanvasLayer.new()
	_viewport.add_child(layer)
	_flash = ColorRect.new()
	_flash.position = Vector2(1180, 20) * scale
	_flash.size = Vector2(80, 80) * scale
	layer.add_child(_flash)
	_label = Label.new()
	_label.position = Vector2(20, 20) * scale
	_label.add_theme_font_size_override("font_size", int(22 * scale))
	layer.add_child(_label)
