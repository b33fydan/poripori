class_name SongTimeline
extends RefCounted

# One song's timeline, written by tools/analyze_song.py: a steady beat grid,
# bars, sections and the owner's cues. Everything on screen reads song time
# through this, so a frame depends only on its song time.

var data: Dictionary
var song_id := ""
var period := 0.5
var first_beat := 0.0
var bar_zero := 0.0
var beats_per_bar := 4
var duration := 0.0


static func load_song(id: String) -> SongTimeline:
	var path := "res://timeline/%s.json" % id
	var text := FileAccess.get_file_as_string(path)
	if text == "":
		push_error("[Timeline] missing %s; run tools/analyze_song.py %s" % [path, id])
		return null
	var timeline := SongTimeline.new()
	timeline.data = JSON.parse_string(text)
	timeline.song_id = id
	timeline.period = float(timeline.data["beat_period"])
	timeline.first_beat = float(timeline.data["first_beat"])
	timeline.bar_zero = float(timeline.data["bar_zero"])
	timeline.beats_per_bar = int(timeline.data["beats_per_bar"])
	timeline.duration = float(timeline.data["duration"])
	return timeline


func audio_path() -> String:
	return ProjectSettings.globalize_path("res://" + str(data["audio"]))


# The beat count since the first beat, fractional: 3.25 is a quarter past beat 3.
func beat(t: float) -> float:
	return (t - first_beat) / period


# The bar count since bar 0, fractional.
func bar(t: float) -> float:
	return (t - bar_zero) / (period * beats_per_bar)


func bar_time(bar_number: float) -> float:
	return bar_zero + bar_number * period * beats_per_bar


func beat_time(beat_number: float) -> float:
	return first_beat + beat_number * period


# Seconds since the most recent beat (or bar) at or before t.
func since_beat(t: float) -> float:
	return fposmod(t - first_beat, period)


func since_bar(t: float) -> float:
	return fposmod(t - bar_zero, period * beats_per_bar)


func section_at(t: float) -> Dictionary:
	for section in data["sections"]:
		if t >= float(section["start"]) and t < float(section["end"]):
			return section
	return {}


func section_start(section_name: String) -> float:
	for section in data["sections"]:
		if str(section["name"]) == section_name:
			return float(section["start"])
	push_error("[Timeline] no section named %s" % section_name)
	return 0.0


func cue(cue_name: String) -> float:
	for entry in data["cues"]:
		if str(entry["name"]) == cue_name:
			return float(entry["t"])
	push_error("[Timeline] no cue named %s" % cue_name)
	return 0.0


# A decaying pulse on every beat: 1 on the beat, falling to 0 over `length`.
func beat_pulse(t: float, length := 0.25) -> float:
	var since := since_beat(t)
	return clampf(1.0 - since / length, 0.0, 1.0)


func bar_pulse(t: float, length := 0.5) -> float:
	var since := since_bar(t)
	return clampf(1.0 - since / length, 0.0, 1.0)
