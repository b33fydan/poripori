#!/usr/bin/env python3
"""Rasterize Puerto Rico from Natural Earth's 1:10m land polygons.

    python3 tools/make_pr_mask.py <ne_10m_land.geojson>

Writes data/earth/puerto-rico-mask.png (white is land) and
data/earth/puerto-rico-mask.json (its extent, cell size, and the cell of the
Arecibo telescope). Cells are square on the ground: a cell spans CELL_LAT
degrees of latitude and CELL_LAT / cos(18.2 deg) of longitude. The main
island, Vieques and Culebra are kept (every polygon inside the extent).
Sources: data/earth/SOURCES.md and docs/FACTS.md.
"""

import json
import math
import sys
from pathlib import Path

import numpy as np
from matplotlib.path import Path as Polygon
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
WEST, EAST, SOUTH, NORTH = -67.36, -65.16, 17.82, 18.62
CELL_LAT = 0.0165
CELL_LON = CELL_LAT / math.cos(math.radians(18.2))
TELESCOPE = (18.3442, -66.7528)  # latitude, longitude: docs/FACTS.md


def main():
    data = json.loads(Path(sys.argv[1]).read_text())
    w = int(round((EAST - WEST) / CELL_LON))
    h = int(round((NORTH - SOUTH) / CELL_LAT))
    lon = WEST + (np.arange(w) + 0.5) * CELL_LON
    lat = NORTH - (np.arange(h) + 0.5) * CELL_LAT
    grid = np.stack(np.meshgrid(lon, lat), axis=-1).reshape(-1, 2)
    land = np.zeros(len(grid), dtype=bool)
    kept = 0
    for feature in data["features"]:
        geometry = feature["geometry"]
        polygons = geometry["coordinates"] if geometry["type"] == "MultiPolygon" else [geometry["coordinates"]]
        for polygon in polygons:
            ring = np.array(polygon[0])
            if ring[:, 0].min() < WEST or ring[:, 0].max() > EAST or ring[:, 1].min() < SOUTH or ring[:, 1].max() > NORTH:
                continue
            inside = Polygon(ring).contains_points(grid)
            for hole in polygon[1:]:
                inside &= ~Polygon(np.array(hole)).contains_points(grid)
            land |= inside
            kept += 1
    mask = land.reshape(h, w)
    Image.fromarray((mask * 255).astype(np.uint8)).save(ROOT / "data" / "earth" / "puerto-rico-mask.png")
    column = int((TELESCOPE[1] - WEST) / CELL_LON)
    row = int((NORTH - TELESCOPE[0]) / CELL_LAT)
    meta = {
        "about": "Puerto Rico land mask from Natural Earth ne_10m_land (public domain); see data/earth/SOURCES.md. Row 0 is the north edge, column 0 the west edge.",
        "west": WEST, "east": EAST, "south": SOUTH, "north": NORTH,
        "cell_lat_deg": CELL_LAT, "cell_lon_deg": round(CELL_LON, 6),
        "width": w, "height": h, "polygons": kept,
        "telescope": {"latitude": TELESCOPE[0], "longitude": TELESCOPE[1], "column": column, "row": row,
                      "on_land": bool(mask[row, column])},
    }
    (ROOT / "data" / "earth" / "puerto-rico-mask.json").write_text(json.dumps(meta, indent=1) + "\n")
    print(f"{w} x {h} cells, {mask.sum()} land, {kept} polygons; telescope at column {column}, row {row}, on land: {meta['telescope']['on_land']}")
    for r in range(h):
        print("".join("#" if (r, c) == (row, column) and False else ("T" if (r, c) == (row, column) else ("o" if mask[r, c] else ".")) for c in range(w)))


if __name__ == "__main__":
    main()
