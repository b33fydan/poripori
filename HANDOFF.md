# Handoff

Newest entry first. Each entry covers one working slice: what was decided, how it was checked, and the exact next step.

## 2026-10-03 — The whole story, 0:00 to the end (3:12)

**Owner direction**
- Yes to the placement table, and yes to plants sprouting from the planted cubes.
- **Rims:** the monolith's should pulse in yellow only, since the rainbow didn't blend. In the B-roll, placed cubes pulse yellow too and the others get white borders.
- **The touch:** don't extend the mascot's arm; let them reach and touch. When they touch and spark, cut immediately.
- **The FPV dives:** fly slower.
- **The reach:** don't cut to Astro alone in space. Instead, one continuous shot as he comes up from Earth, the camera fixed in place watching him from below, then turning to follow as he passes. Add a new cut from above and behind the mascot as Astro comes in with the planet far below, then the touch.
- **The rest:** build the whole story now; it can be edited after.

**What changed**
- **Rims:**
  - `shaders/monolith.gdshader`: INSTANCE_CUSTOM.g picks a cube's kind, 1 for the shared yellow pulse (the `monolith_edge` global) and 0 for a steady white border.
  - The opening's rims are one yellow (#ffd75e), flaring on the beat.
  - `print.gdshader` gained `vertex_flat` and `flat_amount`, so plain meshes (props) can print shaded or flat. They read COLOR as white, so they always printed flat before.
- **`scripts/broll_kit.gd`:** what the B-rolls share. The galaxy set (a wide, bright band that wheels round), the camera with its ink pass, rim cubes, floating platforms, props, paths and the message's cells.
- **The reach (`reach.gd`):**
  - `view=rise` (bars 32–36 and 38–42) is one fixed camera. He rises at 0.3/s plus the jump and passes the lens near bar 39.6.
  - `view=over` (44–46) looks from above and behind the mascot.
  - `view=touch` (46–48.1): the mascot keeps its resting arm and faces +Z, tipped down. The gap closes as `GAP * (1-u)^2.2` from bar 44.
  - The sparks' origin is computed for the moment of the touch. It used to be wherever the glove was on the cut's first frame, out of frame now that he rises faster.
  - The cut to the surfing comes 6 frames after the touch.
- **The FPV dives:** about 40 units a second, a third of the distance.
- **`mascot.gd`:** `point()` (arms at rest or out, aimed anywhere) and `hover(phase, trail)`.
- **`astronaut.gd`:** a `sleeping` option (closed eyes).
- **New B-rolls**, each a floating platform in its chapter's night:
  - **`broll_elements.gd`:** the elements' 17 cubes are pulled from a replica top row first and planted. MEGAVOX plants sprout from them, capped at 1.2 units wide by a new `max_width` on `Megavox.stand`.
  - **`broll_formulas.gd`:** the conveyor belt, with trays carrying the 12 formula blocks in reading order, and four workers each setting in a quarter. Behind them, a readout of rows 11–29 and three watchers.
  - **`broll_helix.gd`:** a 3D double helix (rims pulse on the strands, white on the rungs), rising inside a ring of six stations with scrolling screens.
  - **`broll_human.gd`:** the lab, the crew moving on a station every 2 bars, the glass window, the sleeping giant (×3, rolled to show its face), the message's human figure, and a yellow scan line.
  - **`broll_solar.gd`:** an FPV from Pluto to Mercury. Planets are assembled by streams of cubes from their crews and finished 0.9 s before the drone passes; the camera glances toward each. The Sun flares with rays on bar 80, and the ring crew rushes in and hops on the beat.
  - **`broll_telescope.gd`:** the build (dish, rim, towers with the tall one taller, cables, the platform hauled up). On bar 86 the floor falls out from the coast (a breadth-first distance), leaving Puerto Rico; the land greens and the coast pulses. The beam fires on bar 89, and the crew boards and spirals up it with rainbow trails (`scripts/cube_trail.gd`).
  - **`finale.gd`:** Astro and his mascot, then the crew in a V each with its own, boosting away into the galaxy.
- **`opening.gd`:**
  - `camera=finale`: the whole monolith, lit by a wave through the rows the ring never reached, pulsing wide (0.3 to 1.2), with a big Earth (20-unit cubes) behind.
  - The mascot moves to the inner side in `camera=follow`.
  - The descent reaches row 59 at bar 64.
- **Puerto Rico:**
  - The owner approved downloading Natural Earth's `ne_10m_land.geojson` (10.2 MB) to scratch.
  - `tools/make_pr_mask.py` writes `data/earth/puerto-rico-mask.png` and `.json` (127 × 48 cells, the main island, Vieques and Culebra). The telescope lands on land 7 cells (about 13 km) inland, which matches the NSF's "some 10 miles inland".
  - Sources are in `data/earth/SOURCES.md` and the new `docs/FACTS.md`: Wikipedia and NSF 17-538 for the location and the structure.
- **ffmpeg:** at 17:40 something outside this session installed Homebrew's `ffmpeg-full` (9.0.2), whose libvpx upgrade broke the plain `ffmpeg` 8.0.1. Homebrew was left alone. `tools/media.py` now picks the first ffmpeg/ffprobe that starts (ffmpeg-full first), and all tools use it.
- **`edits/film.json`:** the whole song, 23 cuts, 0 to 192.32 s.

**How it was checked**
- Stills of every new shot, with fixes from them:
  - **the touch:** the mascot's body hid the hands, so it now faces the camera and reaches sideways;
  - **the over view:** reframed twice;
  - **the elements:** some plants were huge bushes;
  - **the formulas:** the belt hid the workers;
  - **the Solar System:** planets were half built as they passed, at the frame's edge;
  - **the telescope:** the flyers left frame too early;
  - **the finale:** the camera started inside the V;
  - **the follow cut:** the mascot blocked the lens.
- **Full render:** `renders/film.mp4`, 5,770 frames, blur 4 × 0.5, about 75 min. `check_cuts.py`: all 22 cuts on their planned frames, no others.
- **The touch:** sparks start on frame 2858, the drop's own frame, and the cut comes at 2864.
- **Exposure** (share of pixels with luma > 0.95):
  - none above 0.2% except the telescope's beam, at 4.7%: the light itself, meant to be the brightest thing.
  - The Sun's flare reaches 18% above 0.85 but doesn't clip.
  - The suit in the touch close-up is luma 0.86.
- **Previews:** `renders/film-preview.mp4` (720p, 61 MB) and `renders/film-phone.mp4` (540p, 27 MB, under the phone app's 30 MB limit).

**Next step**
- The owner reviews the whole film and gives notes.
- Then the Gervis voice lines and their captions (the owner is writing them).
- Then the end-card credits (MEGAVOX wording from its creator, the music, Ocular Sounds if used).

---

## 2026-10-03 — Notes on the first 1:47, and the outline of the rest

**Owner direction**
- The FPV dives must be smooth and locked in: no sudden turns or rotation.
- The jump to the planet: follow him up, leaving Earth behind, as he raises one fist overhead in triumph.
- The touch: reveal the mascot looking down and extending its arm, zoom slowly to their hands, then they touch and sparks fly.
- The mascot beside him should look like it's flying forward.
- He looks stiff when he starts surfing: hold the stance from just after the beat starts (arms open, lowered a bit) all the time.
- The lit monolith looks bland: make its white edges pulse in different colours, in unison.
- The board's front nose should be inclined slightly upward all the time.
- The B-roll timelapses belong out in the galaxy, on floating platforms, not in an enclosed room.
- Then the outline for every remaining chapter and the ending (recorded in `docs/DIRECTION.md`, "The rest of the story").

**What changed**
- **The board (`opening.gd` `rig_transform`):** heading comes from the water at the current moment, so the ring's descent no longer tips the nose down. A probe showed the old nose went down as far as 52° during the fast descent and 11° at the kick. Now 12° up, plus at most ±3° from the swell, so always 9–15° above level.
- **The stance (`_pose_rider`):** the groove pose (crouch 0.42, lean 0.16, arms open) from frame one, breathing with the bar. The anticipation crouch, the kick's spring and the drop's landing are kept.
- **The monolith's rims:**
  - `shaders/monolith.gdshader` draws a rim round every face of a lit cube (lit amount in INSTANCE_CUSTOM), in the colour of a new global `monolith_edge`.
  - Lit cubes write roughness 0.2, and `ink.gdshader` colours outlines on those pixels the same.
  - Godot 4.6 stores roughness as is (measured: 0.2 reads 0.2), not the 127/255 packing older docs describe.
  - `opening.gd` steps the colour through 8 rainbow hues, one a beat, flaring on the beat, from the kick.
- **The mascot:** flies at the rider's shoulder (1.5 behind, 0.5 out, 1.35 up), facing ahead turned 41° toward the camera so its eyes show, tipped forward 0.42 rad, banking, with legs trailing (`hover(phase, trail)`) and arms swept back (new `point()` in `mascot.gd`).
- **The FPV dives:** each is one straight line at a fixed pitch, with up always world-up: no roll, no turns. Dive 2 eases off and tips gently (slerp, last half) toward the human figure.
- **The reach (`reach.gd`):**
  - **The jump:** a jump impulse added to his rise (1.6 units, dying over 0.7 s). The camera follows a beat behind, and Earth recedes from 980 to 1,700 units and sinks.
  - **The fist:** goes up and out on the diagonal with a punch overshoot (the helmet is taller than the arm, so straight up would hide it), and he leans away.
  - **The float pose** now blends part by part from the surf stance. It used to snap when `up` reached 1.
- **The touch:** moved to start at bar 46 (the reveal is now bars 44–46).
  - It opens on the mascot above, looking down at him and toward the camera, its right arm pointed down the line at his glove and sliding out.
  - The camera closes from the pair to their hands by the drop.
  - `scripts/sparks.gd`: 110 streaks, stretched along their travel, with drag. They fire with the star burst on the drop.
- **The numbers B-roll:**
  - Now on its island out in the galaxy, in a new silver night palette `numbers_space`, with `Space` for the stars.
  - The sky wheels round (`Space.update(..., turn)`), and the galaxy band is laid across the view, wider and brighter (new `band_glow` and `band_cover` uniforms in `print_sky.gdshader`).
- **`edits/film.json`:** touch at bar 46.

**How it was checked**
- Stills of every changed shot; fixes from those:
  - the mascot read as a box from behind, then covered the rider, before settling at the shoulder;
  - the fist hid beside the helmet;
  - the touch close-up was too tight;
  - the galaxy band was too faint.
- **Full render:** `renders/film.mp4`, 3,216 frames, blur 4 × 0.5. `check_cuts.py`: all 11 cuts on their planned frames, no others.
- **The FPV dives:** frame differences rise and fall smoothly with speed, with no single-frame spikes.
- **The touch:** the sparks begin on frame 2858, the drop's own frame (its blurred moments straddle 95.266 s).
- **Exposure:** near-clipped pixels (luma > 0.95) at most 0.6%, in the touch.
  - The touch's 0.85 count reaches 8.9%, because the off-white suit (luma 0.86) fills the close-up; it isn't blown out.
  - Every other cut peaks at or under 2.8%.
- **The preview:** `renders/film-preview.mp4` (720p, 40 MB).

**Next step**
- The owner reviews the new 0:00–1:47.
- Confirm where each new B-roll sits in the song (proposal: elements and formulas in the first minute as the ring passes their colours; DNA helix, human, Solar System and the telescope ending after the drop).
- Then build them one at a time, in story order, starting with the elements.
- Before the Puerto Rico reveal: a cited source for its outline (Natural Earth 10 m, public domain) and for the telescope's location, in `docs/FACTS.md`.

---

## 2026-10-03 — The reach and the touch (song 1:03–1:47)

**Owner direction**
- He leaves the board to float and lands back on it at the drop.
- The mascot should be less wide and a bit taller, after a reference photo of a 3D-printed figure.
- The shot list was proposed as approved, with the FPV dive.

**What changed**
- **The mascot (`scripts/mascot.gd`)** was rebuilt after the reference:
  - a body of 12 × 9 × 9 voxels (P = 0.07);
  - raised black plate eyes;
  - flat arm blocks (3 × 3) that telescope to 8 slices;
  - four slim legs in two pairs, 3 voxels tall.
- **`scripts/star_trail.gd`:** three-armed star crosses, born behind the mascot, plus `burst()` for the touch. Time-indexed like the spray.
- **`scripts/shots/reach.gd`** is now the timed sequence: side, top, reveal, touch.
  - His rise is continuous from bar 32. The board drifts away in the side view.
  - Earth is placed per view behind him (`_earth_behind`) with Arecibo toward the camera.
  - The touch closes the gap along a line, with the arm sliding out on an ease that slows to nothing at the drop. The star burst comes on the drop.
- **`scripts/shots/opening.gd`:**
  - **The descent:** now monotone (Fritsch–Carlson), so it never overshoots a key. New keys take it to row 34 at bar 40, 54.6 at bar 48 and 55.6 at bar 56. This replaces Catmull-Rom; the earlier keys are unchanged, but the curve between them differs very slightly, and the first minute was re-rendered with it.
  - **The rider is moved round the ring at bar 40, unseen** (`_angle_jump`), so the camera meets the monolith's front 6.4 s after the drop.
  - **The FPV dives:** `camera=fpv1` and `fpv2` follow paths in the monolith's frame, with FOV 100° and banking roll. They hide the rider.
  - **The drop:** the rider lands back on the board, with a camera punch, and the mascot flies beside him from then on with its stars.
- **`edits/film.json`** is the master edit, song 0:00–1:47.18 (bar 54).

**How it was checked**
- **Stills of every new shot,** with fixes:
  - the reveal was too small and missed Earth;
  - the touch was cramped, with the glove hidden beside the helmet, fixed by a diagonal reach and a medium shot;
  - Earth's limb at his boots looked as if he stood on it, so Earth was moved lower;
  - the mascot after the drop was moved closer, and the stars made bigger.
- **Render:** `renders/film.mp4`, 3,216 frames, 1080p, motion blur 4 × 0.5, 19 min for a full render. `tools/check_cuts.py` passes: all 11 cuts on their planned frames, and no others.
  - The first render showed a false "cut" one frame into FPV dive 2. Its derivatives were sampled with the path clamped at u = 0, which gave a huge bogus bank for 3 frames.
  - Fixed by extrapolating the path. Only cuts 6 and 8 were re-rendered (`--only 6,8`, 2.4 min).
- **The touch:** frame by frame, the glove and arm meet and the star burst starts on frame 2859, right after the drop's frame 2858 (95.266 s). Stills and film frames match at 94.4 s and 95.0 s.
- **Exposure:** Earth's white clouds and ice peaked at 8% of pixels above 0.85 luma. They were toned to soft grey-whites and only the 4 Earth cuts were re-rendered. The night shots now peak at 3.4% (the star burst) with a mean of 0.5%.

**Next step**
- The owner reviews 0:00–1:47.
- Then the drop section onward (bars 48–64), the break at 2:07 (the telescope chapter? the 2020 collapse?), and the B-roll incidents for the other chapters.

---

## 2026-10-03 — Motion blur, the mascot and Earth (look development for the reach)

**Owner direction**
- Can I add a bit of motion blur?
- Plan for 1:03 onward:
  - the astronaut floats upward in space with a massive Earth behind, in side and top views, in slow motion;
  - as the climax ends, a slow reveal of the reach, then the mascot's little arm extends and their hands touch;
  - then the mascot flies beside him leaving little stars.
- The board's nose should point up.
- Can parts be re-rendered surgically? Answered: yes, cut by cut.
- Add an FPV drone dive down beside the monolith.

**What changed**
- **Motion blur:** `film.gd blur=N shutter=S` renders N moments spread across the shutter, centred on each frame's time. `tools/render_edit.py --blur N` averages each cut's moments with ffmpeg `tmix` and `select`, so only finished frames are kept.
  - The test (`renders/blur-compare.mp4`, song 46–53 s, sharp left, blur 6 × 0.5 right) took about 5× the render time.
  - Each blurred frame matches its own sharp frame best (difference 4–5 against 15–17 for neighbours), so the blur is centred.
  - Cuts are still on their frames.
- **Surgical re-renders:** `render_edit.py` keeps `renders/<name>.frames/`, and `--only 2,4` re-renders just those cuts and re-encodes.
- **The board's nose** is now up 14° (75% of that while gliding).
- **The mascot (`scripts/mascot.gd`):** pixel-exact from Claude Code's terminal art, no logo or name. `reach()` telescopes an arm out and angles it, `arm_tip()` gives its tip, and `hover()` bobs it. `tools/godot/mascot_sheet.gd` renders model sheets (`renders/mascot-sheet.png`).
- **Earth (`scripts/voxel_earth.gd`):**
  - About 78,600 ground cubes on a 56-cell radius: ocean, continents raised one cell, polar ice.
  - About 5,400 cloud cubes on their own shell.
  - Coastlines come from `data/earth/land-mask.png`, rasterized by `tools/make_land_mask.py` from Natural Earth (public domain; `data/earth/SOURCES.md`).
- **The `home` palette** is added for the reach.
- **`scripts/shots/reach.gd`** is look development, with `view=side|top|touch`, Earth turning the Caribbean toward the camera (`renders/reach-looks.png`).
  - The side view was reframed twice: Earth's limb at his boots made him look as if he stood on it. He now floats in front of Earth's face, with its limb high behind.

**Next step**
- The owner approves the mascot's look, the Earth looks, and the shot list for bars 32–48 (with the FPV dive).
- Then: build the timed reach sequence, the mascot's star trail and the flight beside him after the touch, and render 1:00 onward.

---

## 2026-10-03 — One minute: B-roll, close follow, static monolith, real board

**Owner direction**
- B-roll should be separate incidents that keep the mystery.
- Can I make hyperlapses? Answered: yes, by running the world's time faster than the song's.
- The monolith should stay static.
- The board should tilt like a real one and be slightly longer.
- Then: add 20 seconds; a 10 s B-roll of astronauts building the top layer somewhere else; and a 5 s close follow behind the surfer.

**What changed**
- **The edit:** `edits/opening.json` runs song 0:00–1:00 with cuts on bars:
  - ring, bars 0–11;
  - B-roll, bars 11–16 (9.9 s);
  - ring, bars 16–24, cutting back as the ring turns violet on the phrase;
  - close follow, bars 24–26.5 (5 s), landing as the formulas section turns the ring green;
  - ring to 1:00.
- **`tools/render_edit.py`** renders each cut with `film.gd`, which now takes `start=` and numbers frames on the whole video's clock, into one folder. It encodes once with the song and writes `renders/<name>.cuts.json`. `tools/check_cuts.py` finds the hard cuts by frame difference and checks each one lands on its planned frame.
- **The B-roll (`scripts/shots/broll_numbers.gd`):**
  - A ragged floating island of 1-unit voxels with MEGAVOX trees and rocks, recoloured by luminance into a blueprint `numbers_day` palette.
  - Nine astronauts (`Astronaut.new(trim, false)`: no board, their own trim colour) stand in a bucket-brigade line.
  - Each of the 27 blocks (the 1s of rows 0–3, bottom row first) leaps from a pile and is tossed hand to hand, then thrown up into its slot. It lands on an eighth-note and snaps in with a squash.
  - The hyperlapse camera glides along the line to the wall while the sky's clouds race (`drift`).
  - Everything is a function of song time.
- **MEGAVOX:** `tools/sync_licensed_assets.sh` copies the pack into the git-ignored `assets/licensed_local/megavox/`. `scripts/megavox.gd` loads models (null when the files are missing) and recolours them into the print shader (`tint` uniform). `tools/godot/megavox_sheet.gd` renders contact sheets for choosing.
- **The print shader** has a `shadow` global (paper at night, deep ink by day) and a `tint` uniform. The sky has a cloud `drift`.
- **The opening:**
  - The monolith is static, facing the camera at 0:38.
  - The board is 31 voxels long and tilted onto its rail with the nose up, pivoting at the tail's inside rail (`Astronaut.rail_pivot`).
  - `camera=follow` adds the close chase.
- **The astronaut:** a longer board, a `trim` colour per astronaut, and `pose_on_foot()` for builders, who carry blocks at the chest because the helmet is too big to lift one overhead.

**How it was checked**
- **Look:** still sheets of the B-roll and the ring through each change. The B-roll camera was moved off the island's edge, the palette pushed to blueprint blue for contrast, and the trees moved off the finished wall.
- **Cuts:** `tools/check_cuts.py` passes on `renders/opening-60.mp4` (1,800 frames, 60.0 s): cuts at frames 657, 954, 1430 and 1579, exactly as planned, and no others.
  - The first run found an unplanned "cut" at frame 478, the kick. The camera's FOV punch jumped 7° in one frame and read as a jump cut, and the per-bar distance pulse popped the same way.
  - Both now rise over about three frames (`_hit()`), and the punch is 5°.
- **The close follow:** a first version had the spray rushing into the lens and hiding the rider while the static monolith's end loomed overhead. The camera is now higher and over the back shoulder, and the spray is a step darker.
- **Exposure:** the ring shots peak at 0.93% of pixels above 0.85 luma. The B-roll averages 41%, because it's light paper by design.

**Next step**
- The owner reviews the minute.
- Then: the mellow section from bar 32 (the reach and the mascot), more B-roll incidents, and where in the orbit the key moments fall.

---

## 2026-10-02 — The descending opening, 0:00–0:40

**Owner direction**
- Lock 1080p with flat tones (no dither).
- The highlights were overblown after the kick.
- Remove the moon.
- Make the message much bigger, so the viewer doesn't know what it is at first.
- Start at the top and surf down round the monolith until it's revealed.
- The ring takes the colour of the section it's passing.
- Make the ring 50% narrower.
- More stars, and about 10% more floating particles, smaller.
- Make a 40-second video.

**What changed**
- **`scripts/shots/opening.gd`** (renamed from `sample.gd`) is the film's opening.
  - **The monolith:** pitch 8, so each cube is about four riders tall and the message is 584 units tall.
  - **The ring:** 104–131.5 (27.5 wide), gap 120–121.5, about 63,000 tiles. It descends with `ring_row(t)`, a Catmull-Rom curve through `DESCENT` keys set in bars:
    - row 1.0 at bar 0;
    - row 2.6 at the kick;
    - row 4.5 at bar 16 (the numbers/elements edge);
    - row 10.5 at bar 24 (the elements/formulas edge);
    - row 18 at bar 32.
  - **Row lighting:** rows above the ring at the kick light in a top-down wave as it lands. Later rows light as the ring comes level with them.
- **`scripts/palette.gd`** gained `at_row()`: the palette follows the ring's row, crossing chapters over about a beat. The intro stays a blue night until the kick.
- **`scripts/spray.gd`:** spray cubes ride in the ring's frame, so they descend with it.
- **The sky:** the moon is removed from the sky shader. Stars went from 700 to 1,800. Dust went from 300 to 330, the extra 30 at half size.
- **The exposure fix:**
  - The numbers palette is now silver, not white.
  - Ring bands are capped lower.
  - Ink lines are softened.
  - Lit message cubes are toned 24% toward the paper.
  - The suit is off-white (#dedcd4).
  - The rainbow and spray are at value 0.84.
- **Defaults:** `film.gd` and `render.sh` now default to 1920×1080 and flat tones. `dither=1` and `size=` still override.

**How it was checked**
- **Exposure, by luma share above 0.85:**
  - Before: 18–20% of the frame after the kick in the 1080p flat sample.
  - After: 0.1–0.4% in stills from across the 40 seconds, with none above 0.95.
- **Look:** checked against still sheets at 3, 10, 14.5, 16.5, 22, 30, 35 and 39.5 s.
  - The top rows read as an unrecognisable wall of blocks.
  - They hang dark before the kick and light on it.
  - The elements rows rise into view in violet as the ring and night turn violet.
- **Render:** `renders/opening.mp4`, song 0:00–0:40.

**Next step**
- The owner reviews the opening.
- Then the next phrases of the descent: the formulas from bar 24, and the reach at bar 32.

---

## 2026-10-02 — 1080p, and a version without the halftone dither

**What changed**
- **The owner asked:** can the film be 1080p, and can I see it with no dither (halftone dots)?
- **Rendering without Movie Maker:**
  - `scripts/film.gd` now renders the shot into an offscreen SubViewport of `size=WxH` (default 1280×720).
  - It saves each frame as a PNG when `RenderingServer.frame_post_draw` fires, after 3 warm-up draws before the first frame.
  - The 1280×720 window only shows a scaled preview.
  - Why: Movie Maker records the window itself. A test with the root viewport's content scale set to 1920×1080 still wrote 1280×720 PNGs, and a 1080p window can't fit on this Mac's 1920×1080 screen.
  - Frames are lossless too, where the old AVI path was MJPEG.
- **`tools/render.sh`:**
  - Encodes the PNG frames (`frame%06d.png`) with the song.
  - Takes `size=` and `dither=`.
  - Checks the frame count and size, then deletes the frames (`KEEP_FRAMES=1` keeps them).
- **Two new global shader parameters:**
  - `print_scale` (output height ÷ 720) keeps halftone dots and ink lines the same size in frame at any resolution.
  - `dither` (1 or 0). At 0, `halftone()` returns the coverage itself, so every shade becomes a flat, solid tone and the sky's galaxy band goes soft.
- **`tools/check_sync.py`** scales the flash box to the video's width.

**How it was checked**
- **Sync on the new pipeline:** the beat-flash render passes `check_sync.py`, identical to Movie Maker's result.
  - 600 frames; 41 flashes for 41 beats.
  - Each flash lands 2.6–33.1 ms after its beat.
  - The kicks in the muxed audio sit a median −1.4 ms from their beats.
- **1080p:** a 1080p still measured 1920×1080. Side-by-side crops with and without dither looked as intended.
- **Deliverables:** `renders/sample-1080.mp4` and `renders/sample-1080-nodither.mp4`, both 0:06–0:26.

**Next step**
- The owner picks 720p or 1080p, and dither or flat.
- Then the next part of the story.

---

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
