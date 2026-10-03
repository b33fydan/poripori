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
- **The ring's colour:** the ring and the night take the colour of the chapter the ring is passing.
- **The camera:** third person from behind the astronaut, toward the monolith. It rides just outside the ring, looking in past the astronaut's back, and the board slides across the frame. A close follow (`camera=follow`) rides low behind the board's tail for short punchy cuts.
- **The monolith stays static (owner's call, 2026-10-03),** for realism. The camera sees it from changing angles. Its facing is set so key moments happen from the front: through the opening it's front-on at 0:38 and never edge-on or from behind.
- **The board rides like a real surfboard:** about 1.55 units long, close to the rider's height. It's rolled about 11° onto its toe-side rail, pivoting on that rail at the tail.
- **The nose is up all the time (owner's call, 2026-10-03):** 12° up, and the swell may tip it by 3° at most, so it's always 9–15° above level. The ring's descent no longer tips it (it used to point the nose down as much as 50° while the ring dropped fast).
- **The rider's stance (owner's call, 2026-10-03):** from the very first frame he holds the groove's stance, arms open and low and knees bent, breathing with the bar in the intro. Standing upright with arms down looked stiff. The kick still springs him and the drop still lands him.
- **The monolith's rims (owner's call, 2026-10-03):** once a row is lit, every cube wears a thin rim of light round each face, and its outlines take the same colour. The whole monolith changes colour together, stepping through the rainbow one colour a beat and flaring on the beat (`shaders/monolith.gdshader`, the `monolith_edge` global).
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
  - **Bars 32–36:** he jumps off the board and punches one fist up in triumph (owner's direction, 2026-10-03). The camera follows him up as Earth falls away below and shrinks (`scripts/voxel_earth.gd`, coastlines from Natural Earth, the Caribbean turned to the camera). The fist goes up and out on the diagonal, since the helmet is taller than his arm.
  - **Bars 36–38:** FPV dive 1, from above the top rows plunging down the face and through the ring's hole. Both dives are smooth and locked in (owner's call, 2026-10-03): one straight line at a fixed pitch, no roll, no turns.
  - **Bars 38–42:** top view, looking down on him over Earth; he lowers the fist.
  - **Bars 42–44:** FPV dive 2, down through the DNA rows to the still-dark human figure.
  - **Bars 44–46:** the reveal. From below, his glove rises on the diagonal; straight up, it would hide beside the big helmet.
  - **Bars 46–48.5:** the touch (owner's direction, 2026-10-03). The mascot is revealed above him, looking down, and slides its arm out toward him. The camera closes slowly on their hands, and the gap closes exactly on the drop's first kick: sparks and stars fly (`scripts/sparks.gd`).
  - **The board:** he leaves it to float and lands back on it at the drop (owner's call).
- **1:36, the touch:** the drop (bar 48, 95.27 s). The astronaut and the mascot touch hands as the beat kicks back in.
  - **Where the ring is:** while the reach plays, the ring descends to the human figure's feet (row 54.6). The rider is moved round the ring unseen, so the drop meets the monolith's front.
  - **From bar 48.5:** back on the ring in the human chapter's red, with the lit human figure towering, and the mascot flying beside him leaving little stars.
- **The voice (from the touch onward):** "Gervis", the owner's voice character, speaks in the background like a PA or a radio transmission. The owner will write the inspiring words. Only then does text appear on screen: the spoken words, as captions.

## The rest of the story (owner's outline, 2026-10-03)

Each chapter of the message gets a hyperlapse B-roll on a floating platform in the galaxy. They stay separate incidents that keep the mystery. Where each goes in the song is still to be confirmed, and each is built and approved one at a time.

- **Numbers:** built (the bucket brigade).
- **Elements (atomic numbers):** many astronauts take apart a replica of that part of the message, pulling its squares out of the sculpture in the middle one by one and planting them in the ground around them.
- **The DNA formulas:** astronauts at a conveyor belt work on parts of it as they come down the belt, while others in the background examine the sequences.
- **The DNA helix:** astronauts at computer stations, as the double helix materialises from the ground up in the middle.
- **The human:** astronauts in a lab, switching stations. In front of them is a huge glass window, and behind it a large astronaut, apparently asleep, beside the message's human figure, as if they were studying the figure and comparing it with the large astronaut.
- **The Solar System:** an FPV flight, flying horizontally and dodging between the planets as astronauts assemble each one. It starts from the last planet and ends at the Sun, which shines bright; all the astronauts gather round it, jumping for joy.
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
