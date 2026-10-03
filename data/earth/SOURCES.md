# Earth: sources

`land-mask.png` is a 360 × 180 equirectangular land mask, one pixel per degree. Column 0 is at 180° W and row 0 at 90° N; white means land. `tools/make_land_mask.py` rasterized it on 2026-10-03 from Natural Earth's 1:110m land polygons:

- **Natural Earth, `ne_110m_land.geojson`:** https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_110m_land.geojson
  - The SHA-256 of the file as fetched is `9e0729ee253ca7d7a5c4ae9395fb1902264c5377c52e224d13dd85010e2835d9`.
  - Natural Earth is public domain (https://www.naturalearthdata.com/about/terms-of-use/).

The voxel Earth (`scripts/voxel_earth.gd`) samples the mask for its coastlines. Its other colours are stylized, not data:
- ice above 66.5° latitude and below 60° S;
- shades of green on land;
- procedural clouds.

- **Arecibo's position:** 18.34° N, 66.75° W, used to turn the Caribbean toward the camera. It still needs a cited source in `docs/FACTS.md` before anything about it goes on screen.
