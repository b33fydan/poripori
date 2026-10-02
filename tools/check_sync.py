#!/usr/bin/env python3
"""Check a beat-flash render against the timeline and its own audio.

    python3 tools/check_sync.py renders/<name>.mp4 <song-id> <from>

A render made with `beats` flashes a square in the top-right corner on every
beat. This finds the frames where the flash switches on and checks:

1. Picture vs timeline: each flash lands on the first frame at or after its
   beat (song time = from + frame / 30), so it is never early and never more
   than a frame late.
2. Picture vs sound: the kicks in the muxed audio track line up with the
   flashes, which proves the mux started the song at the right time.
"""

import json
import subprocess
import sys
from pathlib import Path

import librosa
import numpy as np

ROOT = Path(__file__).resolve().parent.parent
FFMPEG = "/opt/homebrew/bin/ffmpeg"
FPS = 30.0
W, H = 1280, 720
BOX = (1180, 20, 80, 80)  # x, y, w, h of the flash, as scripts/film.gd draws it


def flash_frames(video):
    x, y, w, h = BOX
    raw = subprocess.run([FFMPEG, "-v", "error", "-i", str(video), "-vf", f"crop={w - 20}:{h - 20}:{x + 10}:{y + 10},scale=1:1:flags=area",
                          "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], capture_output=True, check=True).stdout
    # The brightest channel, so the red bar flashes count as much as white beats.
    level = np.frombuffer(raw, dtype=np.uint8).reshape(-1, 3).max(axis=1).astype(float)
    on = level > 128
    starts = [i for i in range(len(on)) if on[i] and (i == 0 or not on[i - 1])]
    return starts, len(level)


def audio_kicks(video):
    raw = subprocess.run([FFMPEG, "-v", "error", "-i", str(video), "-vn", "-ac", "1", "-ar", "44100", "-f", "f32le", "-"],
                         capture_output=True, check=True).stdout
    y = np.frombuffer(raw, dtype=np.float32)
    S = np.abs(librosa.stft(y, n_fft=2048, hop_length=128))
    freqs = librosa.fft_frequencies(sr=44100, n_fft=2048)
    low = np.log1p(S[(freqs > 30) & (freqs < 120)]).sum(axis=0)
    flux = np.maximum(0.0, np.diff(low, prepend=low[0]))
    times = librosa.times_like(flux, sr=44100, hop_length=128)
    peaks = librosa.util.peak_pick(flux, pre_max=20, post_max=20, pre_avg=40, post_avg=40, delta=np.percentile(flux, 95) * 0.5, wait=100)
    return times[peaks]


def main():
    video, song, start = Path(sys.argv[1]), sys.argv[2], float(sys.argv[3])
    timeline = json.loads((ROOT / "timeline" / f"{song}.json").read_text())
    beats = np.array(timeline["beats"])
    starts, total = flash_frames(video)
    end = start + total / FPS
    expected = beats[(beats >= start) & (beats < end - 1 / FPS)]
    print(f"{video.name}: {total} frames, {len(starts)} flashes, {len(expected)} beats in {start:.3f}..{end:.3f} s")

    ok = len(starts) == len(expected)
    lags = []
    for frame in starts:
        t = start + frame / FPS
        nearest = beats[np.argmin(np.abs(beats - t))]
        lags.append(t - nearest)
    lags = np.array(lags)
    late_ok = bool(np.all(lags >= -1e-6) and np.all(lags < 1 / FPS + 1e-6))
    ok &= late_ok
    print(f"{'PASS' if late_ok and len(starts) == len(expected) else 'FAIL'}  picture vs timeline: every beat flashes, "
          f"{lags.min() * 1000:.1f} to {lags.max() * 1000:.1f} ms after its beat (allowed 0 to {1000 / FPS:.1f})")

    kicks = audio_kicks(video)
    # Compare each flash with the nearest kick in the muxed sound, where there are kicks.
    offsets = []
    for frame in starts:
        t = frame / FPS
        if len(kicks):
            k = kicks[np.argmin(np.abs(kicks - t))]
            if abs(k - t) < 0.1:
                offsets.append(k - (t - lags[starts.index(frame)]))
    offsets = np.array(offsets)
    if len(offsets) >= 8:
        median = float(np.median(offsets)) * 1000
        sound_ok = abs(median) < 15
        ok &= sound_ok
        print(f"{'PASS' if sound_ok else 'FAIL'}  sound vs picture: {len(offsets)} kicks in the muxed audio sit a median {median:+.1f} ms "
              f"from their beats (spread {np.percentile(offsets, 10) * 1000:+.1f} to {np.percentile(offsets, 90) * 1000:+.1f} ms)")
    else:
        print(f"SKIP  sound vs picture: only {len(offsets)} kicks near flashes")
    print("in sync" if ok else "OUT OF SYNC")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
