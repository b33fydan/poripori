# The voice

## The Gervis transmission, 1:09–1:29

The owner's two questions, answered in a line that hands over to the owner's own words (the answers drafted by Claude and approved by the owner on 2026-10-03). The owner records the voice and adds it in post.

> What is a message? Why do we want to be heard?
> A message is a piece of us, sent into the dark, trusting someone will catch it.
> We want to be heard because being heard means we are not alone.
> So here is ours.

The owner's draft read "Why do we want to heard?"; it is taken as "be heard".

**Timing** (song time; the captions use these, and the voice can follow them or the captions can be moved to fit the voice):

| From | To | Line |
|---|---|---|
| 1:09.2 | 1:11.6 | What is a message? |
| 1:11.9 | 1:14.5 | Why do we want to be heard? |
| 1:15.0 | 1:20.4 | A message is a piece of us, sent into the dark, trusting someone will catch it. |
| 1:20.9 | 1:26.2 | We want to be heard because being heard means we are not alone. |
| 1:26.8 | 1:29.0 | So here is ours. |

About 44 words in 20 seconds, a calm radio pace with a breath between lines. It plays over the reach: the rising take, FPV dive 1, the rising take again, FPV dive 2, and the start of the view over the mascot.

## Captions (not used)

The owner tried captions and took them out on 2026-10-04: the film has no text. The file is kept in case they come back. `edits/film.captions.ass`, in the style of a transmission readout: Menlo bold, upper case, pale cream with a black outline, low on the left, each line typing itself in word by word. `python3 tools/burn_captions.py` burns them into a copy (`renders/film-captioned.mp4`); `film.mp4` stays clean, so the captions can be retimed to the recording without rendering again.

## Making it sound like space

`python3 tools/radio_voice.py <recording> [--at 69.0]` lays a recording over the film as a transmission between astronauts:
- cut to the telephone band (320–3,000 Hz), compressed hard, roughened a little (a light bit-crush) and given a short metallic slap;
- a bed of static under it;
- the two Quindar tones NASA used to key its transmissions: a 2,525 Hz beep a quarter of a second long just before, and a 2,475 Hz beep just after;
- the song ducked a few dB under the voice, and a limiter at the end so nothing clips.

It writes `renders/<video>-voice.mp4`, the picture copied; the song file and the render are never modified. Run it on `renders/film.mp4`.
