# 20. District View — the Grey Chapels

> Owner decision (2026-10-07): the game **starts confined to one district, the Grey Chapels (slums)**.
> The hero walks a **close-up top-down map of that district**; the neighbouring districts are visible at the
> edges but **darkened and locked**. The map is bigger than the screen and is **dragged with the held left
> mouse button**. Movement: **click a place → the figurine walks along the streets**.

Sketch files are regenerated with `python tools/gen_district_sketch.py`.

Everything for generating the map — steps, prompts, reference images for ChatGPT, labelled sketches for the
owner, examples — is in one folder: [`docs/art-prompts/grey-chapels-map/`](../art-prompts/grey-chapels-map/README.md).
`layout.json` there (contour, landmarks, street graph) becomes the game data.

## 20.1 Two levels of map

| Level | Shows | Used for |
|---|---|---|
| **City map** (exists) | All 12 districts from far away | Choosing a district to travel to. At the start only GREY is lit; the rest are dark with «закрыто» |
| **District map** (new, main play surface) | One district up close: single houses, alleys, bonfires | Walking, entering buildings, rumors, night hunts |

The game opens on the district map of the Grey Chapels. The city map is reached by a button
(«Карта города») and is mostly a view of what is still locked. District unlocks are story events (open
question 20.10).

## 20.2 The district map

- **Size:** 2816 × 3712 px art (3 × 4 tiles of 1024 px with 128 px overlap). One pixel of the city map ≈ 7.3 px
  here: a house that was a 10 px dot on the city map is ~70 px — roofs, chimneys, washing lines are visible.
- **Shape:** the district border follows the black outline of GREY on `HALLOWDEEP__map__normal` exactly
  (traced in `tools/gen_district_sketch.py`, `CONTOUR`). The east side is the **Ringwall**; beyond it, the abyss fog.
- **Borders — no walls between districts:** north — a boundary street, west — the tram embankment, south — a
  railway viaduct (the South Passage is a tunnel under it), east — the Ringwall with the Edge Walk ledge at its foot.
  The Fog Hollow is a sunken gully two storeys deep; the Candle Bridge crosses it at street level; the Old Aqueduct
  is a raised viaduct on arches. Side views: `docs/art-prompts/grey-chapels-map/for-owner/sections.png`.
- **Style (owner, 2026-10-08):** realistic painterly night after rain, desaturated, wet roofs, fog, warm lamp
  points — owner's references in `assets/refs/` (local, not in git).
- **Neighbours:** strips of Nordhal (north), Lumen Campus and Rowan Market (west), Deepwright Lifts and Scarlet
  Lantern Row (south) are inside the art but the game covers them with a dark veil (≈ 70 % black + diagonal
  hatching) and a label «Нордхал — закрыто». They cannot be clicked or walked.
- **View:** strictly top-down, north up, same engraved-watercolour style as the city map, but close.
- **Time of day:** the base art is dusk. Night is a tint + lit windows layer later (Phase 7 overlays).

## 20.3 Camera and controls

| Input | Effect |
|---|---|
| Hold **left button** and move (more than 6 px) | Drag the map. Releasing does not count as a click |
| **Left click** (no drag) on a landmark / street | The hero walks there along the streets |
| Hover a landmark | Its name and action in a tooltip; the building gets a brass outline |
| Mouse wheel | Zoom 0.7 – 1.25 (1.0 = native art; at 0.7 the map is as wide as the screen) |
| Space / double-click the hero | Centre the camera on the hero |
| Buttons «К охотнику» and «Домой» (top bar) | Jump the camera to the hero / to Ash Garret, so the player never gets lost |
| Buttons «К охотнику» and «Домой» (top bar) | Jump the camera to the hero / to Ash Garret, so the player never gets lost |

- The camera is clamped to the map; at the start it centres on the hero's home (Ash Garret).
- While the hero walks the camera follows, unless the player is dragging.
- The viewport (1920 × 1080) shows about 68 % of the width and 29 % of the height — the player must drag to
  see the whole district, which is the point: the slums feel big.

## 20.4 Movement

- Streets are a graph (`layout.json → nodes, streets`). Every landmark has a node where the hero stands.
- Click → shortest path over the graph → the figurine walks (~350 px/s on the art) and turns to face its
  direction (4 views of the hero figurine already exist: `art/ui/HERO__figurine__*.webp`).
- **Walking inside the district costs no time.** Actions inside buildings cost time as in GDD §3.
  (Default — the owner may change it.)
- Locked exits (North Gate, South Passage, West Crossing) are walkable up to the gate; clicking says why it is closed.

## 20.5 Zones

| Zone | Russian | Look (for art) | Mood | Rumor tags | Typical trouble |
|---|---|---|---|---|---|
| Ash Quarter | Пепельный квартал | Tight lanes of soot-black brick tenements, patched tin roofs, washing lines, bonfires in barrels, the hunter's corner of the slums | poor but alive | smoke, footsteps on roofs | thieves, rat swarms |
| Shanty Roofs | Хибары на крышах | Shacks built on top of older roofs, rope bridges and ladders between them, pigeon lofts, chimney forests | precarious, windy | shapes on the roofs, missing children | Gutter Choir, Moth Matron |
| Chapel Close | Часовенный двор | The ruined Old Grey Chapel and its walled yard, broken saints, grey candles, cult chalk signs | sacred and wrong | prayers to the god in the wall, grey eyes | cult summonings, Clay Saint |
| Fog Hollow | Туманный лог | A sunken gully where the platform sagged: flooded cellars, grey fog lying like water, the Candle Bridge above it | cold, silent | grey fog in the cellar, wet footprints | fog corruption, Lamplighter |
| Lower Yards | Нижние дворы | Yards, sheds and graves along the aqueduct down to the south edge; the broken hoist leaning over the abyss | abandoned, hungry | digging sounds, opened graves | ghouls, Burrow Wyrm (rare) |
| Edge Walk | Дорожка над Бездной | A railing path along the inner face of the Ringwall, lamps on chains, the abyss beyond the parapet | dizzying | voices from below the edge | things climbing up |

## 20.6 Landmarks (numbers as on `sketch.png`)

| # | Name (game, RU) | English (prompts) | Zone | Game role | What it looks like (for art) |
|---|---|---|---|---|---|
| 1 | Старая Серая Часовня | The Old Grey Chapel | Chapel Close | Story hub of the Grey Communion; first story contract | A large Gothic chapel of grey stone, cross-shaped plan, one tall broken spire, roof half collapsed with timber ribs showing, lit grey candles inside visible through holes, walled yard with toppled saints |
| 2 | Безмолвная колокольня | The Silent Belfry | Ash Quarter (north) | Lookout: reveals rumors nearby (later); landmark on the Nordhal border | Very tall narrow bell tower without a bell, scaffolding and a ladder to the top, a lantern at the top |
| 3 | Северные ворота | North Gate | border | Exit to Nordhal — **locked** at the start | Iron gate in a brick arch, chained shut, a guard brazier, Nordhal's warm lights beyond |
| 4 | Пепельный рынок | Ash Market | Ash Quarter | Daily trade, food, gossip; market events | Square of patched canvas stalls around 3 bonfires, carts, crates, crowd shapes |
| 5 | Лавка старьёвщика | Rag-and-Bone Shop | Ash Quarter | **SHOP**: weapons, modules, consumables | Crooked two-storey shop with a cart full of scrap outside, hanging bones and old lamps, sign shaped like a bone |
| 6 | Таверна «Фонарь и Крюк» | The Lantern & Hook | Ash Quarter | **TAVERN** (GDD §7): contract board, shifts, gossip | Wide low tavern with a big iron lantern and a hunter's hook over the door, warm light from every window, people outside, barrels |
| 7 | Пепельный чердак | Ash Garret | Ash Quarter | **HOME**: rest, rent, stash; start point | Narrow tenement with a garret window under the roof, one lamp lit, laundry line, iron stair outside |
| 8 | Мастерская «Ржавая Шестерня» | The Rusty Cog | Ash Quarter | **WORKSHOP**: craft and fit modules | Brick workshop with a big rusty cog over the gate, a chimney with sparks, scrap piles, a workbench in an open yard |
| 9 | Костровая площадь | Bonfire Square | Ash Quarter | **Leaflet post**: rumors are pinned here; night start of hunts | Small square with a big bonfire and a tall post covered in pinned paper leaflets |
| 10 | Мост Свечей | Candle Bridge | Fog Hollow | Crossing over the hollow; votive candles mark the dead | Old stone arch bridge over fog, hundreds of small candles on its parapets, glowing arches |
| 11 | Туманные подвалы | The Fog Cellars | Fog Hollow | Night hunts; fog creatures; secret cult rooms | Sunken half-flooded cellar entrances, stairs going down into grey fog, broken doors |
| 12 | Склеп-скрипторий | Crypt Scriptorium | Chapel Close | **LIBRARY**: bestiary research, old texts | Crypt entrance beside the chapel with a reading lamp, stacks of books under a vault, a scribe's desk |
| 13 | Бог в стене | The God in the Wall | Edge Walk | Shrine of the forbidden faith; Voice events | A huge face-like relief carved into the inner Ringwall, candles and offerings at its base, grey cloth strips |
| 14 | Дорожка над Бездной | Edge Walk | Edge Walk | Path along the edge; rare events | Narrow railed walkway along the wall, lamps on chains, fog pouring over the edge |
| 15 | Старый акведук | The Old Aqueduct | Lower Yards | Walkway across the district on top of the arches | Long brick aqueduct on high arches crossing diagonally, a path along its top, ivy and dripping water |
| 16 | Лазарет Пепельных сестёр | Ash Sisters' Infirmary | Lower Yards | Heal HP and Sanity for money | Former chapel house with white sheets in windows, a red lamp, beds visible in a yard, nuns in grey |
| 17 | Безымянное кладбище | The Nameless Yard | Lower Yards | Paupers' graves; ichor, ghoul contracts | Walled graveyard with crooked wooden markers, open fresh graves, a gravedigger's hut, crows |
| 18 | Сломанный подъёмник | The Broken Hoist | Lower Yards | Sealed way down to the under-slums (Chapter II) | Collapsed iron lift tower leaning over the edge, snapped cables, boarded cage, warning signs without text |
| 19 | Южный проход | South Passage | border | Exit to Deepwright Lifts — **locked** | Tunnel under a viaduct closed with a wooden barricade and a chain |
| 20 | Западный переезд | West Crossing | border | Rail crossing to Lumen / Rowan Market — **locked** | Level crossing over the tram rails with a lowered barrier and a signal lamp |

The hunter's buildings moved here from Nordhal: home, tavern, workshop, shop, library are all in the Ash
Quarter and Chapel Close, a short walk apart, so the first week is learned inside one district.

## 20.7 Streets

| Street | Russian | Connects | Width |
|---|---|---|---|
| Ash Street | Пепельная улица | North Gate → Ash Market → Bonfire Square → Old Grey Chapel | main |
| Hook Lane | Крюков переулок | Ash Market → Rag-and-Bone → Tavern → Ash Garret | street |
| Tinker's Row | Жестянщицкий ряд | Tavern → Rusty Cog → Bonfire Square | street |
| Belfry Steps | Ступени колокольни | North Gate → Silent Belfry → Ash Market | alley |
| Rope Bridges | Верёвочные мосты | Bonfire Square → Shanty Roofs → Edge Walk (north) | rope bridges |
| Bridge Lane | Мостовой переулок | Ash Garret → over the Candle Bridge → Bonfire Square | street |
| Rail Track Lane | Путейский проулок | Ash Garret → West Crossing | alley |
| Hollow Stair | Лестница в лог | Candle Bridge → Fog Cellars → Aqueduct | alley |
| Cloister Path | Монастырская тропа | Chapel → Crypt Scriptorium → God in the Wall | street |
| Railing Path | Тропа у перил | north edge → God in the Wall → south edge → Broken Hoist | alley |
| Aqueduct Walk | Тропа по акведуку | Aqueduct (west end) → Edge Walk (south) | alley |
| Gutter Road | Сточная дорога | Fog Cellars → Infirmary → Nameless Yard → South Passage | street |
| Grave Path | Кладбищенская тропа | Nameless Yard → Broken Hoist | alley |

## 20.8 Generating the art (ChatGPT)

Full prompts: [`docs/art-prompts/grey-chapels-map/`](../art-prompts/grey-chapels-map/README.md).

1. **Overview** (one image, 3:4) — the whole district from the plan, to lock the look of every landmark.
2. **12 tiles** (1024 × 1024 each, rows r0–r3, columns c0–c2), row by row. Each gets its `tile_refs/` image
   (plan with numbers only — no words to copy) and the overview as style reference. For the seam, generate a
   **seam canvas** first: `python tools/gen_district_sketch.py --canvas r1c1` pastes the left / top 128 px strips of
   the already generated neighbours onto a grey 1024 canvas; ChatGPT is asked to keep the strips and paint the grey.
   The tiles that are mostly neighbours or wall (r0c2, r3c0, r3c2) are generated last; they are darkened anyway.
3. Save as `assets/district_maps/GREY__map__r{row}c{col}.png`. The import tool resizes each to exactly 1024,
   stitches them with a soft blend in the overlap into `art/city/district_maps/GREY__map.webp` (2816 × 3712) and
   reports seams whose overlap strips differ too much (then that tile is regenerated).
4. **Calibration.** ChatGPT never repeats the plan pixel for pixel. After stitching, a debug overlay draws the street
   graph, landmark spots and the contour over the art; nodes, landmark spots and contour in the data are moved by
   hand onto the painted streets and buildings. Only the calibrated data is used by the game.
5. **Fallback** if the 12 tiles do not join well: one large overview (D0 at the biggest size) upscaled to
   2816 × 3712, with close-up detail added in the game as separate building sprites over it (each landmark its own
   generated image).
6. Until the art exists, the game uses the plan of `sketch.png` as placeholder art — same size and coordinates.

## 20.9 Implementation plan (code)

| Step | What | Where |
|---|---|---|
| 1 | Data: `data/city/district_maps/GREY.json` from `layout.json` (contour, landmarks with actions, nodes, streets, neighbour labels); validator: nodes connected, landmarks on nodes, all inside the contour | `core/content/defs/district_map_def.gd`, validator |
| 2 | Rules: shortest path over the street graph; landmark → action | `core/rules/city/district_map_rules.gd` (pure, tested) |
| 3 | State: `RunState.hero_node` (save v3 + migration: home node); `GameState.walk_to(node)`; start district GREY in `balance.json` | `core/state`, `autoload/GameState` |
| 4 | Screen: map view with drag/zoom camera, neighbour veil (polygon mask), landmark hotspots + tooltips, walking figurine, «Карта города» button | `scenes/district_map/` |
| 5 | City map: only unlocked districts lit; others dark «закрыто» | `scenes/city_map/` |
| 6 | Import: resize + stitch `GREY__map__r*c*.png` tiles, seam report | `tools/import_art.py` |
| 6b | Calibration overlay (debug key): graph, spots, contour over the art; fix the data | `scenes/district_map/` |
| 7 | Tests + dev shots (`11_district_map`, `12_district_walk`) | `tests/`, `core/dev/dev_shots.gd` |

## 20.10 Open questions for the owner

- When and how do other districts unlock (story contract per district, or a rank, or a key item)?
- Should walking inside the district really be free, or cost a little time (e.g. crossing the whole district = 1 hour)?
- Tavern name: «Фонарь и Крюк» (as in GDD §2, §7 — chosen by default) or a new slum tavern?
- Mini-map of the district, or are dragging and the «К охотнику» / «Домой» buttons enough?
