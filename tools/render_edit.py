#!/usr/bin/env python3
"""Render an edit (a list of cuts between shots) to one video with the song.

    python3 tools/render_edit.py edits/<edit>.json [name] [--blur N] [--shutter 0.5]
                                 [--only 2,4] [key=value ...]

Each cut renders its own frames with scripts/film.gd, numbered on the whole
video's clock, into renders/<name>.frames/; then the frames are encoded once
with the song's own audio from the edit's start to its end (AAC; the song
file is never modified). Cuts given in bars (at_bar) land on the first frame
at or after that bar. Writes renders/<name>.mp4 and renders/<name>.cuts.json
(each cut's first frame, for tools/check_cuts.py). Defaults: 1920x1080, flat
tones, no blur.

--blur N renders N moments across the shutter for every frame and averages
them (motion blur), N times the render time. Each cut's moments are averaged
as soon as it's done, so only finished frames are kept.

The frames stay in renders/<name>.frames/, so --only re-renders just the
listed cuts (counting from 0) and splices them in: every frame depends only
on its song time, so a re-rendered cut meets its neighbours exactly. A change
to something several cuts share means re-rendering each of them.
"""

import argparse
import json
import math
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GODOT = "/Users/beefymacmini/Downloads/Godot.app/Contents/MacOS/Godot"
FFMPEG = "/opt/homebrew/bin/ffmpeg"
FFPROBE = "/opt/homebrew/bin/ffprobe"
FPS = 30


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("edit")
    parser.add_argument("name", nargs="?")
    parser.add_argument("--blur", type=int, default=1)
    parser.add_argument("--shutter", type=float, default=0.5)
    parser.add_argument("--only", default="")
    args, extra = parser.parse_known_args()
    edit_path = Path(args.edit)
    edit = json.loads(edit_path.read_text())
    name = args.name or edit_path.stem
    song = edit["song"]
    timeline = json.loads((ROOT / "timeline" / f"{song}.json").read_text())
    bar_time = lambda bar: timeline["bar_zero"] + bar * timeline["beat_period"] * timeline["beats_per_bar"]
    start, end = float(edit["start"]), float(edit["end"])
    times = [float(c["at"]) if "at" in c else bar_time(float(c["at_bar"])) for c in edit["cuts"]]
    bounds = list(zip(times, times[1:] + [end]))
    frames = ROOT / "renders" / f"{name}.frames"
    only = {int(i) for i in args.only.split(",") if i != ""}
    if not only:
        shutil.rmtree(frames, ignore_errors=True)
    frames.mkdir(parents=True, exist_ok=True)
    (ROOT / "renders" / ".gdignore").touch()
    record = []
    for index, (cut, (a, b)) in enumerate(zip(edit["cuts"], bounds)):
        options = [f"{k}={v}" for k, v in cut.items() if k not in ("at", "at_bar")]
        first = math.ceil((a - start) * FPS - 1e-4)
        last = math.ceil((b - start) * FPS - 1e-4)
        record.append({"shot": cut["shot"], "at": round(a, 4), "first_frame": first, "options": options})
        if only and index not in only:
            continue
        print(f"[edit] cut {index}: {cut['shot']:<16} {a:7.3f}..{b:7.3f} s  frames {first}-{last - 1}  {' '.join(options)}", flush=True)
        for n in range(first, last):
            (frames / f"frame{n:06d}.png").unlink(missing_ok=True)
        target = frames if args.blur <= 1 else frames / f"cut{index}.sub"
        target.mkdir(exist_ok=True)
        godot = [GODOT, "--path", str(ROOT), "--resolution", "1280x720", "--script", "res://scripts/film.gd", "--",
                 f"song={song}", f"start={start}", f"from={a}", f"to={b}", f"frames={target}",
                 f"blur={args.blur}", f"shutter={args.shutter}"] + options + extra
        out = subprocess.run(godot, capture_output=True, text=True)
        errors = [l for l in (out.stdout + out.stderr).splitlines() if "ERROR" in l]
        if errors:
            print("\n".join(errors[:10]))
        if args.blur > 1:
            # Frame n is the average of its N moments: tmix averages the last
            # N, and select keeps the one that closes each frame's group.
            n_blur = args.blur
            subprocess.run([FFMPEG, "-v", "error", "-y", "-framerate", str(FPS * n_blur), "-start_number", str(first * n_blur),
                            "-i", str(target / "sub%08d.png"),
                            "-vf", f"tmix=frames={n_blur},select='eq(mod(n\\,{n_blur})\\,{n_blur - 1})'",
                            "-fps_mode", "passthrough", "-start_number", str(first), str(frames / "frame%06d.png")], check=True)
            shutil.rmtree(target)
    expected = math.ceil((end - start) * FPS - 1e-4)
    count = len(list(frames.glob("frame*.png")))
    size = subprocess.run([FFPROBE, "-v", "error", "-show_entries", "stream=width,height", "-of", "csv=p=0:s=x",
                           str(frames / "frame000000.png")], capture_output=True, text=True).stdout.strip()
    print(f"[edit] {count} frames (expected {expected}) at {size}{f', motion blur {args.blur} x {args.shutter}' if args.blur > 1 else ''}")
    if count != expected:
        sys.exit("wrong frame count")
    audio = next(p for p in (ROOT / "songs").glob(f"{song}.*") if p.suffix in (".mp3", ".wav", ".aiff", ".flac", ".m4a"))
    mp4 = ROOT / "renders" / f"{name}.mp4"
    subprocess.run([FFMPEG, "-v", "error", "-y", "-framerate", str(FPS), "-i", str(frames / "frame%06d.png"),
                    "-ss", str(start), "-to", str(end), "-i", str(audio), "-map", "0:v:0", "-map", "1:a:0",
                    "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", "-preset", "slow",
                    "-c:a", "aac", "-b:a", "256k", "-movflags", "+faststart", "-shortest", str(mp4)], check=True)
    (ROOT / "renders" / f"{name}.cuts.json").write_text(json.dumps(record, indent=1) + "\n")
    print(f"[edit] wrote {mp4.relative_to(ROOT)} (frames kept in {frames.relative_to(ROOT)} for --only)")


if __name__ == "__main__":
    main()
