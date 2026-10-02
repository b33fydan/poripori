#!/usr/bin/env bash
# Render a shot with Godot's Movie Maker, then mux the song in with ffmpeg.
#
#   tools/render.sh <name> shot=sample song=lost-in-the-void from=6 to=26 [beats]
#
# Writes renders/<name>.avi (picture only, silent) and renders/<name>.mp4
# (H.264 + the song's own audio from the same song time, AAC). The song file
# itself is never modified. Checks the frame size and count before muxing.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
GODOT=${GODOT:-/Users/beefymacmini/Downloads/Godot.app/Contents/MacOS/Godot}
FFMPEG=${FFMPEG:-/opt/homebrew/bin/ffmpeg}
FFPROBE=${FFPROBE:-/opt/homebrew/bin/ffprobe}
FPS=30
SIZE=1280x720

name=${1:?usage: tools/render.sh <name> shot=... song=... from=... to=... [beats]}
shift
song=lost-in-the-void
from=0
to=""
for arg in "$@"; do
  case $arg in
    song=*) song=${arg#song=} ;;
    from=*) from=${arg#from=} ;;
    to=*) to=${arg#to=} ;;
  esac
done
if [[ -z $to ]]; then
  to=$(python3 -c "import json; print(json.load(open('$ROOT/timeline/$song.json'))['duration'])")
fi
audio=$(ls "$ROOT"/songs/"$song".* 2>/dev/null | head -1)
[[ -f $audio ]] || { echo "no audio for $song in songs/" >&2; exit 1; }

mkdir -p "$ROOT/renders"
touch "$ROOT/renders/.gdignore"
avi="$ROOT/renders/$name.avi"
mp4="$ROOT/renders/$name.mp4"

echo "[render] $name: $song $from..$to s"
"$GODOT" --path "$ROOT" --resolution "$SIZE" --fixed-fps "$FPS" --write-movie "$avi" \
  --script res://scripts/film.gd -- "$@" 2>&1 | grep -v -E '^\s*$' | grep -v -E '^(Godot Engine|Metal|Vulkan|OpenGL)' || true

# Movie Maker records at the window's size; a maximized window misframes
# every frame, so refuse anything but the size asked for.
got=$("$FFPROBE" -v error -select_streams v:0 -count_frames -show_entries stream=width,height,nb_read_frames -of csv=p=0 "$avi")
width=$(echo "$got" | cut -d, -f1)
height=$(echo "$got" | cut -d, -f2)
frames=$(echo "$got" | cut -d, -f3)
expected=$(python3 -c "print(round(($to - $from) * $FPS))")
echo "[render] $avi: ${width}x${height}, $frames frames (expected $expected)"
[[ "${width}x${height}" == "$SIZE" ]] || { echo "wrong frame size" >&2; exit 1; }
[[ "$frames" == "$expected" ]] || { echo "wrong frame count" >&2; exit 1; }

"$FFMPEG" -v error -y -i "$avi" -ss "$from" -to "$to" -i "$audio" \
  -map 0:v:0 -map 1:a:0 -c:v libx264 -pix_fmt yuv420p -crf 18 -preset slow \
  -c:a aac -b:a 256k -movflags +faststart -shortest "$mp4"
echo "[render] wrote $mp4"
