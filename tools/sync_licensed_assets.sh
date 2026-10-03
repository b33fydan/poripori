#!/usr/bin/env bash
# Copy the owner's licensed MEGAVOX models into the git-ignored
# assets/licensed_local/megavox/. They stay on this machine: never commit
# them, and never put them in an exported build. Scenes that use them check
# they exist and carry on without them.
#
#   MEGAVOX_SRC=/path/to/MEGAVOXPACK tools/sync_licensed_assets.sh
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SRC=${MEGAVOX_SRC:-"/Volumes/beefybackup/Downloads_Archive_20260726/uploads_files_7135090_MEGAVOXPACK(1)"}
DEST="$ROOT/assets/licensed_local/megavox"
[[ -d $SRC ]] || { echo "MEGAVOX pack not found at $SRC" >&2; exit 1; }
copy() {
  mkdir -p "$DEST/$2"
  find "$SRC/$1" -maxdepth 1 -name '*.glb' ! -name '._*' -exec cp {} "$DEST/$2/" \;
  echo "$2: $(ls "$DEST/$2" | grep -c '\.glb$') models"
}
copy "01_PLANTS/PLANTS-glb" plants
copy "02_TREES/TREES_glb" trees
copy "03_ROCKS/ROCKS-glb" rocks
copy "04_ASSETS/ASSET-glb" assets
