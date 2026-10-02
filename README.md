# poripori — Arecibo, a voxel music video

A music video for an instrumental song, telling the story of the Arecibo Message: the 1,679-bit picture humanity beamed from Puerto Rico toward the globular cluster M13 on 16 November 1974.

A little voxel astronaut surfs up through the night sky, leaving a trail of coloured cubes, while the message stands behind them as a giant sculpture of cubes. The film is rendered from Godot 4.6 with Movie Maker; ffmpeg muxes in the song untouched.

## Layout

- `scripts/` — the film: a SceneTree script per render, and the pieces it builds (astronaut, trail, sky, sculpture).
- `tools/analyze_song.py` — turns a song into `timeline/<song>.json` (beats, bars, sections, cues). Every frame reads song time from it, so swapping songs means re-running the analysis.
- `timeline/<song>.cues.json` — the owner's cue notes and section names for each song.
- `data/arecibo/` — the message's 1,679 bits and the sources they were checked against.
- `docs/` — treatment, facts and their sources.
- `HANDOFF.md` — what each working slice decided, how it was checked, and the next step.

## Not in this repository

- **Licensed art and sound** (MEGAVOX models, Ocular Sounds) live in the git-ignored `assets/licensed_local/` on the owner's machine only, and never go into an exported build.
- **Songs** live in the git-ignored `songs/`.
- **Renders** go to the git-ignored `renders/`.
