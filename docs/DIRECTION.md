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
- **The board rides like a real surfboard:** about 1.55 units long, close to the rider's height, with the nose up about 6°. It's rolled about 11° onto its toe-side rail, pivoting on that rail at the tail.
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
  The intro, before the message begins, is a plain blue night. The B-roll cut-aways will use light paper in the same chapter colours.
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
    - Nine astronauts, each with their own trim colour, build the message's top four rows on a floating MEGAVOX island in blueprint-blue daylight.
    - They work as a bucket brigade, and every block lands on an eighth-note.
- **The edit:** `edits/opening.json` lists the cuts in bars, and `tools/render_edit.py` renders them into one video.
- **1:04, the reach:** the song turns mellow (bar 32, 63.53 s).
  - The astronaut floats upward in space, in slow motion, with a massive Earth behind (`scripts/voxel_earth.gd`, coastlines from Natural Earth). Side and top views.
  - As the build ends, a slow reveal shows the astronaut reaching up, and the mascot extending its little arm.
  - An FPV drone dive down beside the monolith is intercut.
  - The detailed shot list is pending the owner's approval.
- **1:36, the touch:** the drop (bar 48, 95.27 s). The astronaut and the mascot touch hands as the beat kicks back in. From then on the mascot rides at the board's tip, pointing forward.
- **The voice (from the touch onward):** "Gervis", the owner's voice character, speaks in the background like a PA or a radio transmission. The owner will write the inspiring words. Only then does text appear on screen: the spoken words, as captions.

## The mascot

- **Who:** the orange pixel character from Claude Code, rebuilt in voxels (`scripts/mascot.gd`).
  - It follows the terminal art exactly: a 12×4 body with two eye notches, a two-pixel arm each side and four one-pixel legs.
  - Each pixel is a 0.09-unit cube, and the body is 4 cubes deep.
  - Its arms telescope out, for the touch.
- **After the touch:** the mascot flies beside the astronaut, leaving little stars, rather than riding the board. Sitting on a shoulder would look odd with the blocky shapes (the owner's call).
- **No branding:** no Anthropic logo or name anywhere in the film, so it never reads as official.

## Credits

- **The song:** "Lost in the Void" by beefydan. The owner made it with Suno on a Pro subscription and distributes it through DistroKid, so publishing it is cleared.
- **Still to come:** MEGAVOX credit wording (once its creator replies), and Ocular Sounds if used.
