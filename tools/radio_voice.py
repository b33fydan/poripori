#!/usr/bin/env python3
"""Lay a voice recording over the film as a space transmission.

    python3 tools/radio_voice.py <voice.wav|.m4a|.mp3> [--at 69.0] [--video renders/film.mp4]

The voice is made to sound like astronauts talking over a radio link: cut
to the telephone band (320-3,000 Hz), squeezed hard by a compressor,
roughened a little and given a short metallic slap, with a bed of static
under it and the two Quindar tones NASA used to key its transmissions, a
2,525 Hz beep before and a 2,475 Hz beep after, each a quarter of a second.
The song ducks a few dB under the voice. The song file and the render are
never modified: this writes renders/<video>-voice.mp4 (the picture copied).

The script and its timing are in docs/VOICE.md; the voice starts at --at
seconds of song time (1:09 by default).
"""

import argparse
import subprocess
from pathlib import Path

from media import FFMPEG, FFPROBE

ROOT = Path(__file__).resolve().parent.parent
QUINDAR_IN = 2525.0
QUINDAR_OUT = 2475.0
TONE = 0.25


def duration(path):
    out = subprocess.run([FFPROBE, "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
                         capture_output=True, text=True, check=True)
    return float(out.stdout.strip())


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("voice")
    parser.add_argument("--at", type=float, default=69.0)
    parser.add_argument("--video", default=str(ROOT / "renders" / "film.mp4"))
    args = parser.parse_args()
    video = Path(args.video)
    voice_length = duration(args.voice)
    start = args.at
    end = start + voice_length
    out = video.with_name(video.stem + "-voice.mp4")
    ms = lambda seconds: int(round(seconds * 1000))
    graph = ";".join([
        # The voice, through the radio (padded with silence to the song's end,
        # or the ducking would stop the song when the voice stops).
        f"[1:a]aformat=channel_layouts=mono,highpass=f=320,lowpass=f=3000,"
        f"acompressor=threshold=0.06:ratio=9:attack=4:release=90:makeup=5,"
        f"acrusher=bits=11:mix=0.2,aecho=0.9:0.9:38:0.2,volume=1.3,asoftclip=type=tanh,"
        f"adelay={ms(start)}:all=1,aformat=channel_layouts=stereo,apad[voice]",
        "[voice]asplit=2[voice_mix][voice_key]",
        # Static under it, from just before the first beep to just after the last.
        f"anoisesrc=color=pink:amplitude=0.05:duration={voice_length + 2 * TONE + 0.6:.3f},"
        f"highpass=f=500,lowpass=f=4500,volume=0.12,afade=t=in:d=0.15,"
        f"afade=t=out:st={voice_length + 2 * TONE + 0.45:.3f}:d=0.15,"
        f"adelay={ms(start - TONE - 0.3)}:all=1,aformat=channel_layouts=stereo[static]",
        # The Quindar tones.
        f"sine=f={QUINDAR_IN}:d={TONE},volume=0.18,adelay={ms(start - TONE - 0.1)}:all=1,aformat=channel_layouts=stereo[tone_in]",
        f"sine=f={QUINDAR_OUT}:d={TONE},volume=0.18,adelay={ms(end + 0.1)}:all=1,aformat=channel_layouts=stereo[tone_out]",
        # The song, ducked under the voice.
        "[0:a][voice_key]sidechaincompress=threshold=0.04:ratio=3:attack=30:release=350[song]",
        "[song][voice_mix][static][tone_in][tone_out]amix=inputs=5:duration=first:normalize=0,alimiter=limit=0.95[out]",
    ])
    subprocess.run([FFMPEG, "-v", "error", "-y", "-i", str(video), "-i", args.voice, "-filter_complex", graph,
                    "-map", "0:v", "-map", "[out]", "-c:v", "copy", "-c:a", "aac", "-b:a", "256k",
                    "-movflags", "+faststart", str(out)], check=True)
    print(f"wrote {out}: the voice from {start:.2f} to {end:.2f} s")


if __name__ == "__main__":
    main()
