# 20. District View — the Grey Chapels

> Owner decision (2026-10-07): the game **starts confined to one district, the Grey Chapels (slums)**.
> The hero walks a **close-up top-down map of that district**; the neighbouring districts are visible at the
> edges but **darkened and locked**. The map is bigger than the screen and is **dragged with the held left
> mouse button**. Movement: **click a place → the figurine walks along the streets**.

**Status (2026-10-12):** the playable map is the owner's retouched art (`art/city/district_maps/GREY__map.webp`,
4000 × 6000). **The district screen is built** (`scenes/district_map/`): street graph, landmark spots, zones and contour
were re-traced on the final art into `data/city/district_maps/GREY.json` (the old `layout.json` plan does not match the
art and is no longer used by the game). Check the calibration with F3 in the game (debug builds) or
`python tools/check_district_map.py GREY`. Owner decisions for this step — see §20.11.

## 20.1 Two levels of map

| Level | Shows | Used for |
|---|---|---|
| **City map** (exists) | All 12 districts from far away | Choosing a district to travel to. At the start only GREY is lit; the rest are dark with «закрыто» |
| **District map** (new, main play surface) | One district up close: single houses, alleys, bonfires | Walking, entering buildings, rumors, night hunts |

The game opens on the district map of the Grey Chapels. The city map is reached by a button
(«Карта города») and is mostly a view of what is still locked. District unlocks are story events (open
question 20.10).

## 20.2 The district map

- **Size:** 4000 × 6000 px art (owner's retouched map). Houses are ~150–200 px — roofs, chimneys, washing lines are
  visible; painted people are ~22 px.
- **Shape:** the district border follows the black outline of GREY on `HALLOWDEEP__map__normal` exactly
  (`data/city/district_maps/GREY.json → contour`). The east side is the **Ringwall**; beyond it, the abyss fog.
- **Borders — no walls between districts:** north — a boundary street, west — the tram embankment (the line ends
  in the Tram Depot, landmark 21), south — a brick road viaduct without rails (the South Passage is a tunnel under it),
  east — the Ringwall, a fortress wall three houses thick with towers, the Edge Walk ledge at its foot.
  The Fog Hollow is a sunken gully two storeys deep; the Candle Bridge crosses it at street level; the Old Aqueduct
  is a raised viaduct on arches.
- **Style (owner, 2026-10-08):** realistic painterly night after rain, desaturated, wet roofs, fog, warm lamp
  points — owner's references in `assets/refs/` (local, not in git).
- **Neighbours:** strips of Nordhal (north), Lumen Campus and Rowan Market (west), Deepwright Lifts and Scarlet
  Lantern Row (south) are inside the art but the game covers them with a dark veil (≈ 70 % black + diagonal
  hatching) and a label «Нордхал — закрыто». They cannot be clicked or walked. Beyond the Ringwall (east) is open
  fog, not a district: no veil there (`fog_side` polygon in the map data, owner 2026-10-14).
- **View:** strictly top-down, north up, same engraved-watercolour style as the city map, but close.
- **Time of day:** the base art is dusk. Night is a tint + lit windows layer later (Phase 7 overlays).

## 20.3 Camera and controls

| Input | Effect |
|---|---|
| Hold **left button** and move (more than 6 px) | Drag the map. Releasing does not count as a click |
| **Left click** (no drag) on a landmark / street | The hero walks there along the streets (a click on a house counts as its nearest street point — owner 2026-10-14); a warm ring of light spreads and fades where he is going (`click_ripple.gd`, owner 2026-10-14) |
| Hover a landmark | Its name and action in a tooltip; the building gets a brass ring and its signboard glows |
| Mouse wheel | Zoom from "the map is as wide as the screen" (≈ 0.48) to 1.25 (1.0 = native art); start 0.8. At the farthest zoom three more notches out rise to the city map (a hint counts them; owner 2026-10-14) |
| Space / double-click the hero | Centre the camera on the hero |
| Top bar (owner 2026-10-14) | Icons only, names as tooltips: the hunter (progress), the book (bestiary), the bag (equipment), the menu. No camera or city-map buttons |
| F3 (debug builds) | Markup editor (§20.12) |

- The camera is free (owner 2026-10-14): it never follows the hero; the middle of the view may go to any point of
  the district outline's bounding box, so the edges can be centred too, but not past the outline (not into the fog
  beyond the Ringwall). At the start it centres on the hero's home (Ash Garret).
- **Signboards** (owner 2026-10-14): every place with an action (home, workshop, tavern, shop, infirmary,
  Scriptorium, rumor post) has a small wrought plate with the action's icon hanging over it, always shown; under the
  mouse it grows, glows brass and shows the place's name (`scenes/district_map/place_signs.gd`). Closed places have none.
- The map, residents and smoke draw under every panel and window (the map world has z −10).
- The contracts list sits at the right edge as one panel (title «Заказы», a row per contract: name, days left,
  region icon; no silhouette); the place card opens at the left (owner 2026-10-14).
- People on the map stand at one height whatever the size of their picture (`scales.figure_height`, art px; children
  — walker kind `scale` 0.75); animals keep the common scale (owner 2026-10-14).
- The closed neighbours lie under a dark, half-clear fog (the fog texture over a dark veil) with a soft, blurred edge
  along the district — no hatching (owner 2026-10-14).
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
| Edge Walk | Дорожка над Бездной | A railing path along the inner face of the Ringwall, lamps on chains, the abyss beyond the parapet | dizzying | voices from below the edge | things climbing up — **zone removed 2026-10-14 (owner)**: its strip went to the neighbouring zones |

## 20.6 Landmarks

| # | Name (game, RU) | English (prompts) | Zone | Game role | What it looks like (for art) |
|---|---|---|---|---|---|
| 1 | Старая Серая Часовня | The Old Grey Chapel | Chapel Close | Story hub of the Grey Communion; first story contract | A large Gothic chapel of grey stone, cross-shaped plan, one tall broken spire, roof half collapsed with timber ribs showing, lit grey candles inside visible through holes, walled yard with toppled saints |
| 2 | Безмолвная колокольня | The Silent Belfry | Shanty Roofs | Lookout: reveals rumors nearby (later); landmark on the Nordhal border | Very tall narrow bell tower without a bell, scaffolding and a ladder to the top, a lantern at the top |
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
| 13 | Бог в стене | The God in the Wall | Fog Hollow | Shrine of the forbidden faith; Voice events | A huge face-like relief carved into the inner Ringwall, candles and offerings at its base, grey cloth strips |
| 14 | Дорожка над Бездной | Edge Walk | Shanty Roofs | Path along the edge; rare events | Narrow railed walkway along the wall, lamps on chains, fog pouring over the edge |
| 15 | Старый акведук | The Old Aqueduct | Fog Hollow | Walkway across the district on top of the arches | Long brick aqueduct on high arches crossing diagonally, a path along its top, ivy and dripping water |
| 16 | Лазарет Пепельных сестёр | Ash Sisters' Infirmary | Lower Yards | Heal HP and Sanity for money | Former chapel house with white sheets in windows, a red lamp, beds visible in a yard, nuns in grey |
| 17 | Безымянное кладбище | The Nameless Yard | Lower Yards | Paupers' graves; ichor, ghoul contracts | Walled graveyard with crooked wooden markers, open fresh graves, a gravedigger's hut, crows |
| 18 | Сломанный подъёмник | The Broken Hoist | Lower Yards | Sealed way down to the under-slums (Chapter II) | Collapsed iron lift tower leaning over the edge, snapped cables, boarded cage, warning signs without text |
| 19 | Южный проход | South Passage | border | Exit to Deepwright Lifts — **locked** | Tunnel under a viaduct closed with a wooden barricade and a chain |
| 20 | Западный переезд | West Crossing | border | Rail crossing to Lumen / Rowan Market — **locked** | Level crossing over the tram rails with a lowered barrier and a signal lamp |
| 21 | Трамвайное депо | The Tram Depot | Lower Yards | End of the tram line; later the way to other districts | Three long engine sheds, tracks fanning in, a small turntable, a coal heap, an old tram car |

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

## 20.9 Implementation

Done 2026-10-12 — see §20.11 and CLAUDE.md («Район»).

## 20.10 Open questions for the owner

(Answered so far: tavern name stays «Фонарь и Крюк» by default; walking is free; no mini-map — see
`docs/reference/decisions.md`.)

- When and how do other districts unlock (story contract per district, or a rank, or a key item)?
- Should walking inside the district really be free, or cost a little time (e.g. crossing the whole district = 1 hour)?
- Tavern name: «Фонарь и Крюк» (as in GDD §2, §7 — chosen by default) or a new slum tavern?
- Mini-map of the district, or are dragging and the «К охотнику» / «Домой» buttons enough?

## 20.11 The screen as built (step 1, owner decisions 2026-10-12)

| Topic | What the game does |
|---|---|
| Flow | New game / Continue / back from a fight or the equipment screen → the district screen. «Карта города» opens the city map; only open districts (`RunState.open_districts`, start `["GREY"]`) are lit, the rest are dark «закрыто»; «К району» returns |
| Places | Click a place → the hero walks there → a card: name, zone, a line about it. **Ash Garret** — «Отдохнуть до утра» (ends the day); **Rusty Cog** — «Снаряжение»; **the Lantern & Hook** — «Доска заказов» (GDD 7.4); **Bonfire Square** — «Столб со слухами» (GDD 8.4; rumor diamonds stand on the streets); gates (North Gate, South Passage, West Crossing) — «Закрыто»; the rest — «Откроется позже» |
| Hover | A brass ring round the place and a tooltip: name + what it does |
| Streets | A click on a street (≤ 110 px from it) sends the hero there; the hero's node is saved (`RunState.hero_node`, save v3). Old v2 saves are moved to GREY and every other district is locked — on purpose (the game starts confined to GREY) |
| Hero | The stone figurine (four views), 350 px/s, footsteps; the camera does not follow (owner 2026-10-14) |
| Neighbours | A dark half-clear fog with a soft edge outside the contour, except the open fog beyond the Ringwall; «Нордхал — закрыто» labels |
| Time of day | Always evening for now (the art is a night scene); real day / night comes with hours (phase 7) |
| Residents | About 40 people + animals, scenes at places, living decor (no laundry, banners, card players, street circus, leaflet readers, roof repair, fortune teller, night-watch fire or market crowd — owner 2026-10-14: they only got in the way) (`data/city/district_life/GREY.json`, `scenes/district_map/life/`): they walk, look around, chat with an emote, work at their spots, step aside for the hero. Only atmosphere; the little stories of map-life-people.md part D are the next step |
| Sound | Music «Deep Humidity» + rain; a second layer by the place under the camera: cellars in the Fog Hollow (the wind of the Edge Walk zone went with it, 2026-10-14), fire by the tavern, the market and Bonfire Square (`sound_spots` / zone `ambience` in the map data) |

## 20.12 Markup editing (debug builds, owner 2026-10-12/14)

F3 on the district screen opens the markup editor (`scenes/district_map/map_markup_*.gd`). A legend at the bottom left
says what everything means and is a **filter** (owner 2026-10-14): a tick per layer shows or hides it, and hidden
points cannot be picked — streets and nodes (cyan lines, red dots; orange — rope crossings), node names, places (white
rings), residents standing or working in one spot (violet dots), the district outline (pink; the dark veil is
outside), the open fog beyond the wall (blue; no veil); «Показать всё» / «Скрыть всё». **Every zone has its own
colour** — a light fill, a border, corner squares and its name in the middle — and its own tick in the legend.
A yellow ring is the picked point; the line with its name and coordinates sits at the top centre.

- **Click** picks a point; **Ctrl + the held left button** anywhere moves the picked point (no jump); a plain drag
  moves the map. A corner shared by several zones / the outline / the fog side moves in all of them.
- **Right click** on empty ground: create a street node, a place (pick its action), a zone corner, an outline corner,
  a fog corner (each corner goes on the nearest edge, into every polygon sharing it), or a resident (a copy of a
  standing or working one). On a point: «Соединить цепочкой» (nodes), «Переименовать», «Удалить»; on a link:
  «Удалить связь».
- **Zones are a mosaic** (owner 2026-10-14, `zone_mosaic.gd`): they always cover the whole district without holes or
  overlaps. After a zone or outline corner is moved, added or deleted, every zone is cut to the outline, overlaps are
  cut away (the zone just edited keeps its shape) and every hole goes to the neighbour that borders it most; places
  take the zone they stand in. A dragged corner **sticks** to a nearby corner or border of another zone.
- **New zone**: right click → «Новая зона (обвести кликами)», click its corners along the quarter (they stick to the
  neighbours), right click or Enter closes it, Esc drops it. It is carved out of the zones under it, takes the sound
  and the rumor pictures and signs of the zone it mostly lies in (`rumors.json` gets a copy) and asks for its Russian
  name. **Delete a zone**: right click inside it → «Удалить зону» — its ground goes to the neighbours; the last zone
  and a zone the story sends the hunter to cannot be deleted. «Переименовать зону» changes its Russian name. A new
  zone has no fight backdrop of its own yet (the district scene is used).
- **Chain mode** («Соединить цепочкой»): each click on a node links the last node to it; a click on empty ground makes
  a new node there and links it; right click or Esc ends. A chain is one new street (kind `street`).
- **Names** come automatically (`node_N`, `place_N`, `path_N`, `<resident>_N`) and can be changed: a node or a
  resident takes a latin id (every reference — streets, places, home, walkers — follows), a place its Russian name.
  The hero's home node, the only place with an action and a walker's second-to-last node cannot be deleted.
- **Ctrl+S** writes `data/city/district_maps/<ID>.json`, `data/city/district_life/<ID>.json` and the zones of
  `data/rumors/rumors.json` in their own layout
  (`core/dev/json_layout.gd`; untouched fields stay) and the Russian names of new places and streets into
  `locale/strings.csv`. First it runs the map and residents checks the way the game does at boot: a markup the game
  would not start with is not written (owner 2026-10-14 — a lone node once locked him out of the game); the changes
  stay in memory to be fixed.
  «Создать узел улицы» starts the chain from the new node at once.
  An exported build writes `user://district_maps/`. Residents are rebuilt at once after a change.
