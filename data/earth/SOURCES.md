# Earth: sources

`land-mask.png` is a 360 × 180 equirectangular land mask, one pixel per degree. Column 0 is at 180° W and row 0 at 90° N; white means land. `tools/make_land_mask.py` rasterized it on 2026-10-03 from Natural Earth's 1:110m land polygons:

- **Natural Earth, `ne_110m_land.geojson`:** https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_110m_land.geojson
  - The SHA-256 of the file as fetched is `9e0729ee253ca7d7a5c4ae9395fb1902264c5377c52e224d13dd85010e2835d9`.
  - Natural Earth is public domain (https://www.naturalearthdata.com/about/terms-of-use/).

The voxel Earth (`scripts/voxel_earth.gd`) samples the mask for its coastlines. Its other colours are stylized, not data:
- ice above 66.5° latitude and below 60° S;
- shades of green on land;
- procedural clouds.

- **Arecibo's position:** 18.3442° N, 66.7528° W, used to turn the Caribbean toward the camera and to place the telescope on Puerto Rico. Its sources are in `docs/FACTS.md`.

`puerto-rico-mask.png` (127 × 48 cells, white is land) and `puerto-rico-mask.json` (its extent and the telescope's cell) were rasterized by `tools/make_pr_mask.py` on 2026-10-03 from Natural Earth's 1:10m land polygons:

- **Natural Earth, `ne_10m_land.geojson`:** https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_10m_land.geojson
  - Downloaded with the owner's permission on 2026-10-03 (10,157,965 bytes). The SHA-256 of the file as fetched is `1ac90796408bc6ad6911d69448485d3c4dbf2190370080368a09976e1c9f7416`.
  - Natural Earth is public domain (https://www.naturalearthdata.com/about/terms-of-use/).
- **Kept:** every land polygon inside 67.36°–65.16° W, 17.82°–18.62° N: the main island (236 points), Vieques and Culebra. Mona Island, further west, is outside the frame.
- **Cells** are square on the ground: 0.0165° of latitude (about 1.8 km) by 0.0174° of longitude.
