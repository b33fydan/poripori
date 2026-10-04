#!/usr/bin/env python3
"""Burn the film's captions into a copy of a render.

    python3 tools/burn_captions.py [renders/film.mp4] [edits/film.captions.ass]

Writes renders/<name>-captioned.mp4 (H.264 CRF 18, the audio copied). The
render itself stays clean, so the captions can be changed, or timed to the
voice once it's recorded, without rendering again.
"""

import subprocess
import sys
from pathlib import Path

from media import FFMPEG

ROOT = Path(__file__).resolve().parent.parent


def main():
    video = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "renders" / "film.mp4"
    captions = Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "edits" / "film.captions.ass"
    out = video.with_name(video.stem + "-captioned.mp4")
    # The ass filter wants its path escaped for the filter graph.
    path = str(captions.resolve()).replace("\\", "\\\\").replace(":", "\\:").replace("'", "\\'")
    subprocess.run([FFMPEG, "-v", "error", "-y", "-i", str(video), "-vf", f"ass='{path}'",
                    "-c:v", "libx264", "-crf", "18", "-preset", "slow", "-pix_fmt", "yuv420p",
                    "-c:a", "copy", "-movflags", "+faststart", str(out)], check=True)
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
