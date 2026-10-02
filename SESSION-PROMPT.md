# Arecibo: a voxel music video

I'm making a music video for an instrumental song. It tells the story of the Arecibo Message, the radio message humanity beamed from Puerto Rico toward the stars in 1974.

The visual language is voxel art from the MEGAVOX pack, which I hold a licence for. Models burst into their individual cubes, hang in the air, and snap back together, or fly apart and land as something else. A prototype of this already exists and is described below; watch it before anything else.

I'll bring the song and more creative direction in this session. I'll also try generating a second song through a music API, so the build must let me swap songs.

## How to start

1. Watch `~/Movies/AgentVille/tree-burst-prototype.mp4` and read `reference/voxel_burst_prototype.gd`.
2. Ask me for the song, my creative direction, the aspect ratio, and where the video will be posted. On X, standard accounts can upload at most 2:20; Premium allows longer.
3. Propose a treatment and a shot list mapped to the song's sections, for my approval.
4. Build one sequence end to end, rendered with the music, before building the rest.

## Where things are

- **Project root:** `/Volumes/beefybackup/arecibo-music-video/`. It's a fresh Godot project, separate from AgentVille.
- **Godot 4.6.3:** `/Users/beefymacmini/Downloads/Godot.app/Contents/MacOS/Godot` (Metal, Forward+, Apple M4).
- **ffmpeg and ffprobe:** `/opt/homebrew/bin/`.
- **The MEGAVOX pack** (licensed): `/Volumes/beefybackup/Downloads_Archive_20260726/uploads_files_7135090_MEGAVOXPACK(1)/`.
  - `01_PLANTS`, `02_TREES`, `03_ROCKS` and `04_ASSETS` each have a GLB folder and an FBX folder, about 380 models in all.
  - Each also has one MagicaVoxel `.vox` file (version 200, with a scene graph) holding the whole category with its palette: 96 plants, 61 trees, 88 rocks and 134 assets.
  - The `.vox` files include the hidden inside voxels; the trees alone have 1.67 million. A burst only needs the visible surface ones.
  - `05_.Blend` holds the Blender sources.
  - Nothing in the pack is a building, vehicle or space object. The dish, the beam, the stars and the message itself will probably be built from voxels in the pack's style.
- **The Ocular Sounds "Vector" kit** (licensed, optional effects): `/Users/beefymacmini/Downloads/Vector-Designed-Construction-Kit-Ocular-Sounds/Vector/`.
- **AgentVille**, for reference only; don't modify it: `/Volumes/beefybackup/AgentVille`. Its story scene renders a film with Movie Maker; see `render_command` and `mp4_args` in `godot/scripts/story/StoryGame.gd`.

## Rules

- **Framework:** render the video from Godot, where the prototype already works, and use ffmpeg for muxing and encoding. Other tools are fine for analysis such as beat detection, or for 2D overlays.
- **Licensed files stay on this machine.** Copy what's needed into a git-ignored `assets/licensed_local/`. Never commit them, and never include them in an exported build. The rendered video itself is mine to publish.
- **Songs** stay out of git unless I say otherwise.
- **The music API:** I'll name the provider.
  - Read the API key from an environment variable; never print it or commit it.
  - Before generating, check the provider's current documentation and its terms for publishing the result.
  - Keep each generation's prompt and settings in the repository.
- **Credits on the end card:** MEGAVOX (I'm asking its creator for their name and preferred wording), the music, and Ocular Sounds if used.
- **Facts on screen must be right.** Check each one against a reliable source before it goes in, and keep the sources in the repository.
- **Backups:** this drive has no backup. Set up git, commit often, and push to a remote I'll name.
- **HANDOFF.md:** write an entry after every working slice, with the decisions, how it was checked, and the exact next step.

## What the prototype taught

1. **How the models are built:** each MEGAVOX GLB is one mesh of 2–4 single-colour surfaces (StandardMaterial3D), made of 0.1-unit voxels.
   - Neighbouring cube faces are merged into larger flat faces, so the individual cubes have to be recovered from the mesh.
   - The `.vox` files may be a better source: they hold the exact grid and palette, including hidden inside voxels.
2. **Recovering cubes from a GLB:**
   - Rasterize each axis-aligned triangle on the 0.1 grid. The solid voxel sits half a voxel behind the face.
   - Use the mesh's `NORMAL` array to tell which side that is. Godot winds front faces clockwise, so a cross product of the edges points inward. That bug put every cube one layer outside the tree.
   - Some models, such as `Tree.021`, sit half a voxel off the grid, so detect the offset per model.
   - Nudge cell centres a hair, so a quad's diagonal gives each centre to exactly one triangle.
3. **Prove the rebuild:** render the original model and the cubes from the same camera and compare them. The prototype measured 68 dB PSNR, effectively identical, so swapping between them can't be seen.
4. **The motion that felt right:**
   - a crouch before the burst;
   - a burst easing out (cubic), with a small stagger per cube;
   - cubes spreading out from the trunk's axis and upward from the base, so none sinks into the ground;
   - a slow drift while the cubes hang;
   - a magnetic gather easing in (cubic), bottom first, so it reads as regrowth;
   - spin proportional to how far a cube is from home, so cubes land aligned;
   - a squash-and-wobble on landing;
   - the camera pulling back just ahead of the burst, and holding the wide shot until the last cube lands.
   - Each cube's randomness comes from a hash of its cell, so every frame is reproducible.
5. **Performance:** moving each cube from GDScript is fine for about 1,400 cubes, one tree. Many models at once need a MultiMesh moved by a shader, with each cube's home position and seed in `INSTANCE_CUSTOM` and the animation phase in uniforms.
6. **Rendering:**
   - Movie Maker (`--write-movie out.avi --fixed-fps 30`) works with a `--script` SceneTree.
   - It records at the window's size. On this Mac's 1920×1080 screen, a 1080p window gets maximized and every frame is misframed. Check the output size with ffprobe; 1600×900 is known to work.
   - Encode with `-c:v libx264 -pix_fmt yuv420p -crf 18 -preset slow`, AAC audio, and `-movflags +faststart`.

## Syncing to the music

- **Song time drives everything:** each frame on screen depends only on song time (frame ÷ fps), so any moment can be re-rendered or scrubbed exactly.
- **One timeline file per song:** beats, downbeats, sections and my cue notes, generated from the audio. All choreography reads from it, so swapping in the generated song means re-running the analysis, not rewriting scenes.
- **Audio:** render silently from Godot and mux my original audio file in with ffmpeg, untouched.
- **Checking sync:** use a debug render that flashes on every beat.

## The story: facts to check before use

- **When and where:** sent 16 November 1974 from the Arecibo Observatory in Puerto Rico, at a ceremony reopening the upgraded telescope.
- **Target:** the globular cluster M13 in Hercules, about 25,000 light-years away.
- **Format:** 1,679 binary digits. 1,679 is 73 × 23, both prime, so the bits form a picture 73 rows tall and 23 columns wide.
- **Authors:** written by Frank Drake with help from Carl Sagan and others.
- **Transmission:** about three minutes, at 2,380 MHz.
- **The picture, top to bottom:**
  - the numbers 1 to 10;
  - the atomic numbers of hydrogen, carbon, nitrogen, oxygen and phosphorus;
  - the formulas of DNA's sugars and bases;
  - the number of nucleotides, and the double helix;
  - a human figure, with its height and the world population;
  - the Solar System;
  - the Arecibo telescope and its size.
- **Afterwards:** the telescope collapsed on 1 December 2020. The message is still travelling: about 52 light-years out in 2026, a tiny fraction of the way to M13.
- **The bit string:** get the exact 1,679 bits from a reliable source. Prove them by rendering the 23 × 73 grid and comparing it with the published picture.

## Seed ideas, mine to keep or replace

- **The message as voxels:** cubes lift off MEGAVOX trees and rocks and assemble the 1,679-bit picture in the sky, one section per musical phrase.
- **The scene:** the dish built from voxels, the beam as a stream of cubes, and M13 as a cluster of voxel stars.
- **The emotional turn:** the 2020 collapse. The dish bursts apart, and the message keeps travelling.
