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
- **The camera:** third person from behind the astronaut, toward the monolith. It rides just outside the ring, looking in past the astronaut's back, and the board slides across the frame. The monolith turns to face the camera, so it always reads correctly.
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
- **The cuts:** each chapter of the message gets a sped-up B-roll that explains it visually, then the film cuts back to the astronaut.
- **1:04, the reach:** the song turns mellow (bar 32, 63.53 s). In slow motion the astronaut reaches up with one hand, and the Claude mascot is revealed bit by bit. Short B-roll cuts fly the camera low over the human figure in the middle of the message as the build-up rises.
- **1:36, the touch:** the drop (bar 48, 95.27 s). The astronaut and the mascot touch hands as the beat kicks back in. From then on the mascot rides at the board's tip, pointing forward.
- **The voice (from the touch onward):** "Gervis", the owner's voice character, speaks in the background like a PA or a radio transmission. The owner will write the inspiring words. Only then does text appear on screen: the spoken words, as captions.

## The mascot

- **Who:** the orange pixel character from Claude Code, rebuilt in voxels.
- **No branding:** no Anthropic logo or name anywhere in the film, so it never reads as official.

## Credits

- **The song:** "Lost in the Void" by beefydan. The owner made it with Suno on a Pro subscription and distributes it through DistroKid, so publishing it is cleared.
- **Still to come:** MEGAVOX credit wording (once its creator replies), and Ocular Sounds if used.
