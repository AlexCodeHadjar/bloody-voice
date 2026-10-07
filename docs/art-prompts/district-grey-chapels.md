# Art Prompts — Grey Chapels close-up map

Hand-written (not generated). Design: [GDD §20](../gdd/20-district-view-grey-chapels.md).
References: `docs/assets/districts/GREY/` — run `python tools/gen_district_sketch.py` first.

## How to use

1. Open **one chat** for the whole district so the style stays the same.
2. Paste the STYLE BLOCK and the CLOSE-UP BLOCK, then prompt **D0** with `sketch.png` and `location.png` attached.
   Repeat until the overview is good — it fixes the look of every landmark.
3. Then the 12 tiles, **row by row, left to right** (r0c0, r0c1, r0c2, r1c0 …). For each tile attach:
   its `tile_refs/GREY_tile_r{r}c{c}_ref.png`, the good overview (D0), and the tile to the **left** and the tile
   **above** if they exist. Paste prompt **D1** with the tile's line from the table. If the neighbours exist, also attach the seam canvas
   from `python tools/gen_district_sketch.py --canvas r{r}c{c}` (`assets/district_maps/canvas/`).
4. Save as `assets/district_maps/GREY__map__r{r}c{c}.png` (exactly 1024 × 1024), run `python tools/import_art.py`.
5. If a seam is visible, regenerate that tile with both neighbours attached and ask to "match the left 128 px to the
   attached left tile and the top 128 px to the attached top tile".

```text
STYLE BLOCK:
Dark gaslight-and-steel fantasy, Lovecraftian mysticism. Hand-painted illustration
with ink linework, like an old engraved map coloured with muted watercolour.
Palette: soot black #2B2420, parchment #ECE4D2, tarnished brass #B08A4A,
cold steel blue #6E7A8A, dried blood red #8A1C1C, fog grey #BDBDB8,
sickly moon silver #C9CCD8. Low saturation, strong value contrast,
warm lamplight against cold fog. Late-19th-century architecture fused with
advanced machinery (lifts, pipes, brass, rivets). Ominous, quiet, human-scale details.
No text, no letters, no watermarks, no modern objects, no bright neon, no anime style.
```

```text
CLOSE-UP BLOCK:
Strict top-down orthographic view, north is up, like a detailed city plan seen from a balloon.
Close scale: every single house is clearly visible with its own roof, chimneys, skylights,
washing lines between windows, barrels and crates in yards, bonfires, cobbles in the streets,
tiny lamps along the streets. Streets are clearly readable paths between the houses.
Dusk, grey fog lying in low places, warm windows. Same palette and ink-and-watercolour
technique as the city overview map, but the camera looks straight down: we see roofs, not facades.
No people larger than a fingernail, no text, no labels, no map frame, no compass.
```

## D0 — Overview of the district

```text
[STYLE BLOCK] [CLOSE-UP BLOCK]
Portrait 3:4 image of one city district: Grey Chapels, the slums at the east edge of a giant city
platform. Follow the attached plan (sketch.png): the district outline, which landmarks are connected
by streets and where every numbered landmark is. The plan's straight street lines are schematic —
paint organic, winding slum streets. Ignore all words, numbers and the legend; do not copy any text. The attached location.png shows where the district
sits in the whole city; keep the same shapes as in that overview.
Edges: on the east a massive curved city wall (the Ringwall) with the abyss fog beyond it.
Outside the district outline (north, west, south) show a little of the neighbouring districts
in their own style (warm forges in the north, a tram line and green-lit glass roofs in the west,
industrial lifts and red lanterns in the south) — they will be darkened in the game.
Inside, the landmarks (numbers from the plan):
1 a large ruined Gothic chapel of grey stone, cross-shaped, one tall broken spire, half the roof
  collapsed showing timber ribs, grey candles glowing inside, a walled yard with toppled saints;
2 a very tall thin bell tower with no bell, scaffolding and a lantern on top;
3 an iron gate in a brick arch, chained, a brazier;
4 a market square of patched canvas stalls around three bonfires;
5 a crooked shop with a scrap cart and hanging bones and lamps;
6 a wide low tavern with a big iron lantern and a hunter's hook over the door, warm windows, barrels outside;
7 a narrow tenement with one lit garret window and an iron outside stair (the hero's home);
8 a brick workshop with a huge rusty cog over its gate, sparks from the chimney, scrap piles;
9 a small square with a big bonfire and a tall post covered with pinned paper leaflets;
10 an old stone arch bridge over a fog-filled gully, hundreds of candles on its parapets;
11 sunken, half-flooded cellar entrances with stairs going down into grey fog;
12 a crypt entrance beside the chapel with a reading lamp and stacks of books;
13 a huge face-like relief carved into the inner face of the Ringwall, candles and offerings below;
14 a narrow railed walkway along the wall, lamps on chains, fog pouring over the edge;
15 a long brick aqueduct on high arches crossing the district diagonally, a path on top;
16 an infirmary house with white sheets in the windows and a red lamp;
17 a walled paupers' graveyard with crooked wooden markers and open graves;
18 a collapsed iron lift tower leaning over the edge, snapped cables;
19 a tunnel under a viaduct closed by a wooden barricade;
20 a level crossing over tram rails with a lowered barrier and a signal lamp.
Between the landmarks: dense shacks, tenements and shanties on rooftops linked by rope bridges
(north-east), fog in the gully (centre-west), yards and sheds (south).
```

## D1 — One tile (repeat for each)

```text
[STYLE BLOCK] [CLOSE-UP BLOCK]
Square 1024x1024 tile of the large Grey Chapels district map, tile {TILE} of a 3x4 grid.
The left half of the attached reference is the plan of exactly this tile (streets, numbered
landmarks, the district border, hatched = neighbouring district) — ignore the numbers, do not draw
them. The right half is the same area on the old city overview: use it only for mood and colours,
NOT for the camera angle — the camera looks straight down at roofs. Match the attached overview
image of the whole district for every landmark's look.
If a seam canvas is attached: keep its left and top strips exactly as they are and paint only the
flat grey part so that roofs and streets continue across the strips.
This tile contains: {CONTENT}
```

| Tile | {CONTENT} |
|---|---|
| r0c0 | North-west corner: a strip of the neighbouring Nordhal district (warm forges, brick) in the top-left; the district border; the first tenements of the Ash Quarter; the corner of the Rag-and-Bone Shop (5) at the right edge |
| r0c1 | North Gate (3) in the district border, the Silent Belfry (2), Ash Market (4) with bonfires, Rag-and-Bone Shop (5), Ash Street going south |
| r0c2 | North-east: the Ringwall curving down the right side, a strip of Nordhal at the top, the Shanty Roofs — shacks on roofs linked by rope bridges |
| r1c0 | West: the tram line and a strip of Lumen Campus (glass roofs, green light) on the left; the Lantern & Hook tavern (6); Ash Garret, the hero's home (7); West Crossing (20) on the left edge |
| r1c1 | Centre: the Rusty Cog workshop (8), Bonfire Square with the leaflet post (9), the west end of the Candle Bridge (10), the west half of the Old Grey Chapel (1) |
| r1c2 | East: the east half of the Old Grey Chapel (1) and its walled yard, Shanty Roofs to the north, the God in the Wall (13) carved into the Ringwall on the right |
| r2c0 | South-west: the tram line and Rowan Market strip on the left; fog-filled gully; the Ash Sisters' Infirmary (16) |
| r2c1 | The Fog Hollow full of grey fog, the Fog Cellars (11), the west end of the Old Aqueduct (15) |
| r2c2 | Crypt Scriptorium (12) south of the chapel, the Old Aqueduct (15) reaching the wall, the Edge Walk (14) along the Ringwall, God in the Wall (13) at the top |
| r3c0 | South-west corner: mostly the neighbouring Rowan Market / Deepwright strip (industry, smoke), the district border, a few sheds |
| r3c1 | The Nameless Yard graveyard (17), the South Passage tunnel (19) in the border, a strip of Deepwright Lifts / Scarlet Lantern Row (red lanterns) at the bottom |
| r3c2 | South-east: the Broken Hoist (18) leaning over the edge, the end of the Edge Walk, the Ringwall, a strip of Scarlet Lantern Row at the bottom |

## Other images for the district view

The darkening veil and its hatching are drawn by the game (shader), no image needed.
ChatGPT does not make reliable transparency: ask for a flat pure magenta (#FF00FF) background; the import tool
cuts it out (planned with the combat UI import).

| File (`assets/ui/`) | Prompt (after STYLE BLOCK) |
|---|---|
| `DISTRICT__landmark_ring.png` | A thin brass ring with small rivets, top view, on a flat pure magenta background, 1:1 — outlines a hovered building |
| `DISTRICT__lock_badge.png` | A small iron padlock on a round brass plate, top view, on a flat pure magenta background, 1:1 |
