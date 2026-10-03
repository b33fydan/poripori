#!/usr/bin/env python3
"""Rasterize Natural Earth's land polygons to an equirectangular land mask.

    python3 tools/make_land_mask.py <ne_110m_land.geojson>

Writes data/earth/land-mask.png: 360 x 180, one pixel per degree, column 0
at 180 W and row 0 at 90 N; white is land. The source is public domain; see
data/earth/SOURCES.md. The voxel Earth samples this mask.
"""

import json
import sys
from pathlib import Path

import numpy as np
from matplotlib.path import Path as Polygon
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
W, H = 360, 180


def main():
    data = json.loads(Path(sys.argv[1]).read_text())
    lon = np.linspace(-180 + 0.5, 180 - 0.5, W)
    lat = np.linspace(90 - 0.5, -90 + 0.5, H)
    grid = np.stack(np.meshgrid(lon, lat), axis=-1).reshape(-1, 2)
    land = np.zeros(len(grid), dtype=bool)
    for feature in data["features"]:
        geometry = feature["geometry"]
        polygons = geometry["coordinates"] if geometry["type"] == "MultiPolygon" else [geometry["coordinates"]]
        for polygon in polygons:
            outer = Polygon(np.array(polygon[0]))
            inside = outer.contains_points(grid)
            for hole in polygon[1:]:
                inside &= ~Polygon(np.array(hole)).contains_points(grid)
            land |= inside
    mask = (land.reshape(H, W) * 255).astype(np.uint8)
    out = ROOT / "data" / "earth" / "land-mask.png"
    Image.fromarray(mask).save(out)
    print(f"wrote {out.relative_to(ROOT)}: {land.mean() * 100:.1f}% land")


if __name__ == "__main__":
    main()
