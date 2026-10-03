#!/usr/bin/env bash
# Render a shot to PNG frames with Godot, then encode them with the song.
#
#   tools/render.sh <name> shot=opening song=lost-in-the-void from=0 to=40 \
#     [size=1280x720] [dither=1] [beats]
#
# Defaults are the film's: 1920x1080, flat tones (no halftone dither).
#
# Writes renders/<name>.mp4: H.264 from lossless frames, with the song's own
# audio from the same song time (AAC). The song file itself is never
# modified. Checks the frame count and size before encoding, then deletes
# the frames (KEEP_FRAMES=1 keeps them in renders/<name>.frames/).
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
GODOT=${GODOT:-/Users/beefymacmini/Downloads/Godot.app/Contents/MacOS/Godot}
FFMPEG=${FFMPEG:-$(python3 -c "import sys; sys.path.insert(0, '$(dirname "$0")'); from media import FFMPEG; print(FFMPEG)")}
FFPROBE=${FFPROBE:-$(python3 -c "import sys; sys.path.insert(0, '$(dirname "$0")'); from media import FFPROBE; print(FFPROBE)")}
FPS=30

name=${1:?usage: tools/render.sh <name> shot=... song=... from=... to=... [size=WxH] [dither=1] [beats]}
shift
song=lost-in-the-void
from=0
to=""
size=1920x1080
for arg in "$@"; do
  case $arg in
    song=*) song=${arg#song=} ;;
    from=*) from=${arg#from=} ;;
    to=*) to=${arg#to=} ;;
    size=*) size=${arg#size=} ;;
  esac
done
if [[ -z $to ]]; then
  to=$(python3 -c "import json; print(json.load(open('$ROOT/timeline/$song.json'))['duration'])")
fi
audio=$(ls "$ROOT"/songs/"$song".* 2>/dev/null | head -1)
[[ -f $audio ]] || { echo "no audio for $song in songs/" >&2; exit 1; }

mkdir -p "$ROOT/renders"
touch "$ROOT/renders/.gdignore"
frames="$ROOT/renders/$name.frames"
mp4="$ROOT/renders/$name.mp4"
rm -rf "$frames"
mkdir -p "$frames"

echo "[render] $name: $song $from..$to s at $size"
# The window stays 1280x720 so it fits on screen; the film renders at $size.
"$GODOT" --path "$ROOT" --resolution 1280x720 --script res://scripts/film.gd -- frames="$frames" "$@" 2>&1 \
  | grep -v -E '^\s*$' | grep -v -E '^(Godot Engine|Metal|Vulkan|OpenGL)' || true

expected=$(python3 -c "print(round(($to - $from) * $FPS))")
count=$(ls "$frames" | grep -c '^frame[0-9]*\.png$' || true)
got=$("$FFPROBE" -v error -show_entries stream=width,height -of csv=p=0:s=x "$frames/frame000000.png")
echo "[render] $count frames (expected $expected) at $got"
[[ "$got" == "$size" ]] || { echo "wrong frame size" >&2; exit 1; }
[[ "$count" == "$expected" ]] || { echo "wrong frame count" >&2; exit 1; }

"$FFMPEG" -v error -y -framerate "$FPS" -i "$frames/frame%06d.png" -ss "$from" -to "$to" -i "$audio" \
  -map 0:v:0 -map 1:a:0 -c:v libx264 -pix_fmt yuv420p -crf 18 -preset slow \
  -c:a aac -b:a 256k -movflags +faststart -shortest "$mp4"
[[ "${KEEP_FRAMES:-0}" == "1" ]] || rm -rf "$frames"
echo "[render] wrote $mp4 ($(du -h "$mp4" | cut -f1))"
