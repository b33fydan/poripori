# Direction

The owner's creative direction, as confirmed on 2026-10-02. The story is being built step by step, so each sequence is proposed and approved before it's built; nothing here is a full shot list yet.

## The look

- **The hero:** a little voxel astronaut, built like AgentVille's farmhands (box body, swinging limbs, a voxel face in an open visor). It surfs on a board that leaves a trail of colours behind it.
- **The sky:** night. Deep space, a faint galaxy band, voxel stars.
- **The message:** a monolith so big that, up close, the viewer doesn't know what they're looking at. Each bit is a cube about four riders tall (pitch 8 units), so the whole message is 584 units tall.
- **The ring (owner's idea, 2026-10-02):** a giant ring like Saturn's circles the monolith, and the astronaut surfs on it.
  - The ring is made of voxel tiles, banded like Saturn's rings, with a gap like the Cassini Division.
  - Narrowed by half to 27.5 units wide (the owner's call).
  - A swell travels round the ring with the astronaut, who rides its face.
  - The trail paints the tiles in rainbow colours. Tiles dip under the board and wobble back, and cubes spray up behind it.
- **The descent (owner's direction):** the film starts at the top of the monolith. The ring carries the astronaut down it, chapter by chapter, like a lift.
  - Rows light as the ring reaches them.
  - The monolith is revealed whole only at the end.
  - The pace is set in bars (`DESCENT` in `scripts/shots/opening.gd`), so chapter changes land on phrase downbeats.
- **The ring's colour:** the ring takes the colour of the chapter it is passing.
- **The sky stays black in every scene (owner's call, 2026-10-03, polishing):** tinted nights flooded the whole frame with each chapter's hue. The galaxy band is a neutral grey, the stars keep their own faint warm and cool whites, and shade falls toward a neutral near-black. Only the objects (the ring, the floors, the cubes) carry the chapter's colour.
- **The camera:** third person from behind the astronaut, toward the monolith. It rides just outside the ring, looking in past the astronaut's back, and the board slides across the frame. A close follow (`camera=follow`) rides low behind the board's tail for short punchy cuts.
- **The monolith stays static (owner's call, 2026-10-03),** for realism. The camera sees it from changing angles. Its facing is set so key moments happen from the front: through the opening it's front-on at 0:38 and never edge-on or from behind.
- **The board rides like a real surfboard:** about 1.55 units long, close to the rider's height. It's rolled about 11° onto its toe-side rail, pivoting on that rail at the tail.
- **The nose is up all the time (owner's call, 2026-10-03):** 12° up, and the swell may tip it by 3° at most, so it's always 9–15° above level. The ring's descent no longer tips it (it used to point the nose down as much as 50° while the ring dropped fast).
- **The rider's stance (owner's call, 2026-10-03):** from the very first frame he holds the groove's stance, arms open and low and knees bent, breathing with the bar in the intro. Standing upright with arms down looked stiff. The kick still springs him and the drop still lands him.
- **The monolith's rims (owner's call, 2026-10-03):** once a row is lit, every cube wears a thin rim of light round each face, and its outlines take the same colour. The whole monolith pulses together in one yellow, flaring on every beat (`shaders/monolith.gdshader`, the `monolith_edge` global). A rainbow stepping one colour a beat was tried first and dropped: the colours didn't blend.
- **Rims in the B-roll (owner's call, 2026-10-03):** a cube once placed pulses in the same yellow; a cube not yet placed (in a pile, in flight, in a replica) wears a steady white border, so none looks bland.
- **The lights (owner's idea, 2026-10-03):** through the monolith's yellow runs a pattern of black borders, like strings of Christmas lights, changing every phrase (4 bars): a diagonal sweep, bands falling down the rows, twinkling, rings rippling out from the middle (`monolith_pattern` global, `shaders/monolith.gdshader`).
- **Black borders (owner's call, 2026-10-03):** the numbers B-roll's pale trees, and the planets' cubes. The ink pass draws black outlines for any surface marked with roughness 0.5: full black at the silhouette, softer along inner creases so dense voxel work doesn't fill in.
- **The sky:** no moon (removed 2026-10-02). About 1,800 voxel stars, and floating dust for parallax, 10% of it smaller.

## The style reference

- **What:** FALL-LINIE, a snowboarding game by Grotesk. The owner's clip is at `~/Downloads/surfing.mp4`; a playable remux is at `~/Downloads/surfing-fixed.mp4`.
- **Taken from it:** the visual grammar only, never its branding or font:
  - a printed look: flat colours, halftone shading, ink outlines;
  - one giant landmark at the vanishing point (the reference's sun disc was tried as a moon, then dropped);
  - a low chase camera;
  - a track and spray behind the board;
  - a palette that changes from run to run.
- **The palette journey:** each chapter of the message gets its own night, tinted with that chapter's colour from the coloured version of the message (`scripts/palette.gd`):
  - numbers, silver;
  - elements, violet;
  - formulas, green;
  - DNA, blue;
  - human, red;
  - Solar System, gold;
  - telescope, purple.
  The intro, before the message begins, is a plain blue night.
- **The B-roll is out in the galaxy (owner's call, 2026-10-03):** not an enclosed room or a daytime sky, but floating platforms in open space, with the galaxy band wide and bright behind and the sky wheeling round in the hyperlapses.
- **On-screen text:** no numbers or words for now.
- **Aspect and size, locked 2026-10-02:** 16:9, 1920×1080, 30 fps.
- **Shading, locked 2026-10-02:** flat, solid tones with no halftone dither. `dither=1` still brings the dots back.
- **Exposure:** no pure whites. The first chapter's palette is a cool silver, and the suit is off-white. Lit message cubes and the rainbow track are toned down a step, so the frame doesn't blow out.
- **Where it's posted:** X. The owner has Premium, so the full 3:12 song fits.

## The structure

- **Reading order:** top to bottom, as the message is read. It starts with the numbers 1 to 10 and ends with the telescope that sent it. Each chapter lights up on the sculpture in its turn. The seven chapters are in `data/arecibo/sections.json`.
- **The cuts:** each chapter of the message gets a B-roll, then the film cuts back to the astronaut.
  - **The B-roll keeps the mystery (owner's call, 2026-10-03).** Each is a separate incident that echoes its chapter without explaining it, with action to reset the viewer's attention. Nothing names the message before the reveal.
  - **Hyperlapse:** the B-roll runs the world in fast motion while the camera glides, and every frame is still a function of song time. Speed ramps can snap back to real time on a downbeat.
  - **The numbers B-roll (`scripts/shots/broll_numbers.gd`):**
    - Nine astronauts, each with their own trim colour, build the message's top four rows on a floating MEGAVOX island out in the galaxy, in the numbers' silver night (moved from blueprint-blue daylight, 2026-10-03).
    - They work as a bucket brigade, and every block lands on an eighth-note.
- **The edit:** `edits/opening.json` lists the cuts in bars, and `tools/render_edit.py` renders them into one video.
- **1:04, the reach (built 2026-10-03, `scripts/shots/reach.gd`, cuts in `edits/film.json`):**
  - **Bars 32–36 and 38–42, one continuous take (owner's direction, 2026-10-03):** a camera fixed in space above him. He springs off the board and punches a fist up and out in triumph (straight up, it would hide beside the big helmet), and comes up from Earth toward the lens (`scripts/voxel_earth.gd`, coastlines from Natural Earth, the Caribbean turned to the camera). He passes it and keeps rising, the camera turning in place to follow. The take resumes on the same clock after FPV dive 1, so it plays as one shot.
  - **Bars 36–38:** FPV dive 1, from above the top rows plunging down the face. Both dives are smooth and locked in (owner's call, 2026-10-03): one straight line at a fixed pitch, no roll, no turns, and slow enough to read, about 40 units a second.
  - **Bars 42–44:** FPV dive 2, down through the DNA rows to the still-dark human figure; he lowers the fist meanwhile.
  - **Bars 44–46:** third person from above and behind the mascot, which hangs in space looking down; he comes up toward it, glove raised, Earth far below (owner's direction).
  - **Bars 46–48.1:** the touch. Facing them, the camera closes slowly on their hands. No telescoping arm (the owner's call): they reach and touch, exactly on the drop's first kick. Sparks and stars fly (`scripts/sparks.gd`) and the film cuts away six frames later, without hanging.
  - **The board:** he leaves it to float and lands back on it at the drop (owner's call).
- **1:36, the touch:** the drop (bar 48, 95.27 s). The astronaut and the mascot touch hands as the beat kicks back in.
  - **Where the ring is:** while the reach plays, the ring descends to the human figure's feet (row 54.6). The rider is moved round the ring unseen, so the drop meets the monolith's front.
  - **From bar 48.5:** back on the ring in the human chapter's red, with the lit human figure towering, and the mascot flying beside him leaving little stars.
- **The voice:** "Gervis", the owner's voice character, speaks like a radio transmission between astronauts. The first transmission, 1:09–1:29, is written and approved (`docs/VOICE.md`); the owner records and adds the voice in post (`tools/radio_voice.py` gives it the space-radio sound). Its words appear as captions, typing themselves in like a transmission readout (`edits/film.captions.ass`, burned onto a copy by `tools/burn_captions.py`).

## The rest of the story (owner's outline, 2026-10-03; built the same day)

Each chapter of the message gets a hyperlapse B-roll on a floating platform in the galaxy. They stay separate incidents that keep the mystery. The owner approved the placement below and asked for the whole story to be built at once, to be edited after (`edits/film.json`):

| Song time | Bars | What plays |
|---|---|---|
| 0:22–0:32 | 11–16 | Numbers (`broll_numbers.gd`) |
| 0:36–0:44 | 18–22 | Elements (`broll_elements.gd`): the replica taken apart, its cubes planted; little MEGAVOX plants sprout from them (the owner's yes) |
| 0:53–1:02 | 26.5–31 | DNA formulas (`broll_formulas.gd`): the belt, the readout |
| 1:03–1:36 | 32–48.1 | The reach and the touch |
| 1:36–1:47 | 48.1–54 | Surfing with the mascot |
| 1:47–1:55 | 54–58 | DNA helix (`broll_helix.gd`) |
| 1:55–2:07 | 58–64 | Surfing, into the Solar System's gold (the ring reaches row 59 at bar 64) |
| 2:07–2:23 | 64–72 | Human lab (`broll_human.gd`), in the calm break |
| 2:23–2:43 | 72–82 | Solar System FPV (`broll_solar.gd`); the Sun flares on the peak at 2:39 |
| 2:43–3:02 | 82–92 | The telescope (`broll_telescope.gd`): built on the peak, the floor falls to Puerto Rico as the music drops at 2:51, the beam at 2:57 |
| 3:02–3:08 | 92–95 | The crew surfs away with their mascots (`finale.gd`), on the outro's swell |
| 3:08–3:12 | 95–end | The whole monolith, lit and pulsing, Earth behind (`opening.gd camera=finale`) |

The last shot starts at bar 95 rather than 96 as first proposed: from bar 96 the song is only 1.8 s of near silence.

- **Numbers:** built (the bucket brigade).
- **Elements (atomic numbers):** many astronauts take apart a replica of that part of the message, pulling its squares out of the sculpture in the middle one by one and planting them in the ground around them.
- **The DNA formulas:** astronauts at a conveyor belt work on parts of it as they come down the belt, while others in the background examine the sequences.
- **The DNA helix:** astronauts at computer stations, as the double helix materialises from the ground up in the middle.
- **The human:** astronauts in a lab, switching stations. In front of them is a huge glass window, and behind it a large astronaut, apparently asleep, beside the message's human figure, as if they were studying the figure and comparing it with the large astronaut.
- **The Solar System:** an FPV flight, flying horizontally and dodging between the planets as astronauts assemble each one. It starts from the last planet and ends at the Sun, which shines bright; all the astronauts gather round it, jumping for joy. As built: Pluto in, as the 1974 message has it. The first weave turned up to 186° a second and was hard on the eyes (owner's note); it is now one long gentle sway, turning at most 20° a second, with no bank.
- **The telescope, and the end:**
  - astronauts build the telescope from the ground up;
  - the floor round it falls away, revealing the shape of Puerto Rico, and the camera zooms out: the telescope was built on Puerto Rico;
  - the telescope shoots a beam of light up, and every astronaut grabs a board and flies up after it;
  - Astro appears, surfing up through the galaxy with the mascot. The astronauts follow behind, each with its own mascot, and they all vanish into the horizon.
- **The last shot:** the monolith floating, pulsing with bright colours, with Earth in the background.

## The mascot

- **Who:** the orange character from Claude Code, rebuilt in voxels (`scripts/mascot.gd`).
- **Shape:** after a 3D figure the owner chose (2026-10-03):
  - a near-cube body (12 × 9 × 9 voxels of 0.07 units), about a third wider than tall;
  - raised black square eyes set wide in its top quarter;
  - a flat block of an arm at mid-height on each side;
  - two pairs of slim legs, a third of the body's height.
- **Size and arms:** it's about half the astronaut's height, and its arms telescope out for the touch.
- **After the touch:** the mascot flies beside the astronaut, leaving little stars, rather than riding the board. Sitting on a shoulder would look odd with the blocky shapes (the owner's call).
- **It flies forward (owner's call, 2026-10-03):** at the rider's shoulder, facing the way they travel and turned just enough that its eyes show, tipped forward into the flight with its arms swept back and its legs trailing.
- **No branding:** no Anthropic logo or name anywhere in the film, so it never reads as official.

## Credits

- **The song:** "Lost in the Void" by beefydan. The owner made it with Suno on a Pro subscription and distributes it through DistroKid, so publishing it is cleared.
- **Still to come:** MEGAVOX credit wording (once its creator replies), and Ocular Sounds if used.
