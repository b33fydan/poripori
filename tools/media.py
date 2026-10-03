"""Which ffmpeg and ffprobe the tools run: the first that actually starts.

Homebrew's keg-only ffmpeg-full comes first. On 2026-10-03 installing it
upgraded libvpx, and the plain ffmpeg formula, still linked against the old
libvpx, stopped starting; so each candidate is tried rather than assumed.
"""

import subprocess

CANDIDATES = ["/opt/homebrew/opt/ffmpeg-full/bin", "/opt/homebrew/bin", "/usr/local/bin"]


def _first_working(name):
    for folder in CANDIDATES:
        path = f"{folder}/{name}"
        try:
            if subprocess.run([path, "-version"], capture_output=True).returncode == 0:
                return path
        except OSError:
            continue
    raise SystemExit(f"no working {name} in {', '.join(CANDIDATES)}")


FFMPEG = _first_working("ffmpeg")
FFPROBE = _first_working("ffprobe")
