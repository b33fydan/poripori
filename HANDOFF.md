# Handoff

Newest entry first. Each entry covers one working slice: what was decided, how it was checked, and the exact next step.

## 2026-10-02 — The ring, the print look and the palette journey

**What changed**
- **Owner direction:**
  - Use FALL-LINIE (Grotesk) as the style reference.
  - Take a palette journey through the message's own colours.
  - Add a giant Saturn-like ring round the sculpture that the astronaut surfs on.
  - No on-screen numbers or words until the voice ("Gervis") arrives at the touch.
  - Recorded in `docs/DIRECTION.md`.
- **The print look:**
  - `shaders/print.gdshaderinc`, `print.gdshader`, `ring.gdshader`, `print_sky.gdshader` and `ink.gdshader`.
  - Three flat tones per face from a key direction, with the darker two as a halftone dot screen, laid over paper.
  - Ink outlines come from a full-screen quad that reads depth (its Laplacian, which is zero on flat surfaces at any angle) and normals.
  - No scene lights: colour comes out as emission through a linear tonemap, so the palette prints exactly.
- **The palette:** global shader parameters (`paper`, `ink`, `accent`, `key_dir`, `halftone_px`, `song_time`) are declared in `project.godot` and set by `scripts/palette.gd` from one palette per chapter.
- **The ring:** `scripts/saturn_ring.gd`, 114,978 tiles from radius 80 to 135, with a gap at 112–115.
  - `paint()` records once, from the shot's track function, when the board crosses each tile.
  - From that and song time, the shader presses and wobbles each tile, paints it rainbow and fades it back. It also lifts every tile on the swell.
- **The shot:** `scripts/shots/sample.gd` was rebuilt for the ring.
  - The sculpture is 88 units tall (pitch 1.2), with row 55 at the ring's height.
  - The rider orbits at radius 98, weaving ±4.
  - The camera rides outside the ring looking in. In the intro it starts in front of the visor and swings round to reveal the sculpture just before the kick.
  - The palette turns from intro to numbers on the kick.
  - The sculpture yaws to face the camera.
- **Also:**
  - `scripts/spray.gd` replaces the old cube trail.
  - The visor is open, because the ink pass draws over the finished opaque frame and glass would vanish. The face prints flat so it always reads.
  - `film.gd` passes its arguments to the shot (`options`), including a forced `palette=` for stills, and quits if a shot fails to load.
  - `tools/godot/model_sheet.gd` renders the astronaut from four sides.

**How it was checked**
- **Composition:** iterated from still sheets:
  - first pass: tiles too big, sculpture pushed off frame by a chase from behind;
  - then the reframe outside the ring;
  - then fixes to a face hidden by the camera trailing during the intro, the moon's direction, spray density and ring tone.
- **Palettes:** a still of the same frame in all seven chapter palettes.
- **Sync:** the beat-flash render still passes `check_sync.py`: 41 flashes for 41 beats, each 2.6–33.1 ms after its beat, and the muxed audio's kicks a median −1.4 ms from them.
- **Flicker:** eight consecutive frames show none in the tiles, the halftone or the ink lines.
- **Renders:** `renders/sample.mp4` (v2). The first version is kept as `renders/sample-v1-glow.mp4` for comparison.

**Next step**
- The owner reviews v2 and the palette strip.
- Then the next part of the story: likely the Claude mascot's look as a model sheet, or the B-roll format on light paper for the numbers chapter.

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
