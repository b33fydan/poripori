# Handoff

Newest entry first. Each entry covers one working slice: what was decided, how it was checked, and the exact next step.

---

## 2026-10-02 — Groundwork and the look sample

**What exists now**
- **The project:** a Godot 4.6.3 project at 1280×720, pushed to github.com/b33fydan/poripori (public) on top of its July "first commit".
  - Songs (`songs/`), licensed files (`assets/licensed_local/`) and renders (`renders/`) are git-ignored.
  - Nothing licensed is used yet.
- **The song timeline:** `tools/analyze_song.py <song>` writes `timeline/<song>.json` (beats, bars, sections, cues).
  - Lost in the Void: 192.32 s at a steady **121.0 BPM**. The first beat is at 0.058 s, and the sections fall on 8-bar phrases:
    - intro, 0–8
    - groove_a, 8–32 (first kick 15.93 s)
    - mellow, 32–42; mellow_build, 42–48
    - drop, 48–64 (95.27 s)
    - break, 64–72
    - groove_c, 72–80; groove_c_peak, 80–86
    - outro, 86–92; outro_swell, 92–96
    - tail
  - The owner's cues, in `timeline/lost-in-the-void.cues.json`, snap to bars: **reach at bar 32 (63.53 s)**, **touch at bar 48 (95.27 s)**.
- **The message:** `data/arecibo/bits.txt` holds the 1,679 bits. They're proven by `tools/verify_arecibo.py`; see `data/arecibo/SOURCES.md`.
  - Four sources are identical.
  - The bits match the CC0 Commons picture with 0 mismatched cells.
  - Every decoded value matches its published figure.
- **The regions:** `data/arecibo/sections.json` maps every lit cell to a region and one of 7 chapters.
- **The film code:**
  - `scripts/film.gd` is the Movie Maker runner. It also makes stills, and draws a beat flash with the `beats` argument.
  - `scripts/song_timeline.gd` reads the timeline.
  - `scripts/voxel_part.gd`: models made of real cubes, so anything can burst later.
  - `scripts/astronaut.gd`: the rider and board.
  - `scripts/cube_trail.gd`, `scripts/space.gd` and `scripts/message_sculpture.gd`: the trail, the sky and the sculpture.
  - `scripts/shots/sample.gd` choreographs the sample.
- **Rendering:** `tools/render.sh <name> key=value...` renders and muxes. `tools/check_sync.py` proves sync.
- **The deliverable:** `renders/sample.mp4`, song time 0:06–0:26, 20.0 s, 1280×720, 30 fps, H.264 + AAC.

**Decisions**
- **Direction:** see `docs/DIRECTION.md`. The owner has X Premium, so the full 3:12 song fits.
- **Reading order:** top-down. Chapters light on the sculpture in turn.
- **Orientation:** today's standard picture, with the first bit of each row on the left. The 1970s pictures are mirrored; that's noted in `SOURCES.md`.
- **The astronaut:** AgentVille farmhand proportions in a helmet: AgentVille's blue `#5e8ec7` and yellow `#f2cf6b`, a voxel face behind a glass visor, and a surf stance (side-on, left foot leading).
- **The sculpture:** colours are this film's own, per region. The transmitted message has none.
- **Timing:** every frame is a pure function of song time, from + frame/30. Trail cubes are indexed by birth time and hashed, so any frame re-renders identically.

**How it was checked**
- **Sync:** the beat-flash render passed `check_sync.py`.
  - 600 frames; 41 flashes for 41 beats.
  - Each flash lands 2.6–33.1 ms after its beat, on the first frame at or after it.
  - The kicks in the muxed audio sit a median −1.4 ms from their beats.
  - librosa's and ffmpeg's decodes of the MP3 agree to the sample.
- **Movie Maker:** it recorded one extra frame when `quit()` ran on the frame after the last pose. Fixed by quitting on the last posed frame. `render.sh` now refuses a wrong frame count or size.
- **Look:** checked by eye from stills and a contact sheet of the MP4.

**Next step**
- The owner reviews `renders/sample.mp4` and gives notes on the look: astronaut, trail, sky, sculpture size and placement, camera.
- Then the owner starts telling the story, sequence by sequence. The next build is whichever sequence they choose first.
- Likely early tasks:
  - the voxel Claude mascot;
  - the B-roll format for chapter 1 (the numbers);
  - copying MEGAVOX models into `assets/licensed_local/` once a shot uses them.
