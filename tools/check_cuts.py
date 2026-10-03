#!/usr/bin/env python3
"""Check that an edit's cuts land where they were planned.

    python3 tools/check_cuts.py renders/<name>.mp4

Finds every hard cut in the video (a frame that differs sharply from the one
before it, far beyond the motion around it) and compares them with the cuts
tools/render_edit.py planned, in renders/<name>.cuts.json: each cut should
show on exactly its planned first frame, the first frame at or after its bar.
"""

import json
import subprocess
import sys
from pathlib import Path

import numpy as np

from media import FFMPEG, FFPROBE  # the first ffmpeg that starts (tools/media.py)


def main():
    video = Path(sys.argv[1])
    planned = json.loads(video.with_suffix(".cuts.json").read_text())
    raw = subprocess.run([FFMPEG, "-v", "error", "-i", str(video), "-vf", "scale=160:90", "-f", "rawvideo", "-pix_fmt", "gray", "-"],
                         capture_output=True, check=True).stdout
    frames = np.frombuffer(raw, dtype=np.uint8).reshape(-1, 90, 160).astype(float)
    diff = np.abs(np.diff(frames, axis=0)).mean(axis=(1, 2))  # diff[i] is frame i+1 against frame i
    # A cut stands far above the motion around it.
    found = []
    for i in range(len(diff)):
        around = np.concatenate([diff[max(0, i - 8):i], diff[i + 1:i + 9]])
        if diff[i] > 12.0 and diff[i] > 4.0 * np.median(around):
            found.append(i + 1)
    expected = [c["first_frame"] for c in planned[1:]]
    print(f"{video.name}: {len(frames)} frames; cuts planned at {expected}; found at {found}")
    ok = found == expected
    for c in planned[1:]:
        hit = c["first_frame"] in found
        print(f"  {'PASS' if hit else 'FAIL'}  {c['shot']} {' '.join(c['options'][1:])} at {c['at']:.3f} s -> frame {c['first_frame']}")
    extra = [f for f in found if f not in expected]
    if extra:
        print(f"  FAIL  cuts nobody planned at frames {extra}")
    print("cuts on time" if ok else "CUTS OFF")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
