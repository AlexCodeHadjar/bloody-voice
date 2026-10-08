# 16. Art Direction and Generation Prompts

## 16.1 How to use these prompts in ChatGPT

1. Start **one chat per art set** (map, districts, UI) so the model keeps the style.
2. Attach `docs/assets/map/city_sketch.png` and `docs/assets/map/city_grid.txt` for anything that shows the layout.
3. Paste the **STYLE BLOCK**, then the prompt. Do not shorten the style block.
4. When a result is good, attach it as a **style reference** for the next images ('match the style of the attached image').
5. For state variants always attach the base image and use Prompt D.
6. Save results to `assets/<districts|map|ui>/` with the file names below, then import them with `python tools/import_art.py` (webp into `art/`).

## 16.2 Style bible

> District close-up maps and ground-level scenes use **style v2** (owner, 2026-10-08): realistic painterly
> rainy Victorian night — see `docs/art-prompts/grey-chapels-map/`. Whether the rest of the art follows is an open question.

| Aspect | Rule |
|---|---|
| Palette | Soot black #2B2420, parchment #ECE4D2, brass #B08A4A, steel blue #6E7A8A, blood red #8A1C1C, fog grey #BDBDB8, moon silver #C9CCD8 |
| Rendering | Ink lines + muted watercolour, engraved-map feeling; UI in wood, brass and parchment |
| Light | Warm lamplight vs cold fog; moonlight for church areas; red for Scarlet Row; green for Morrell |
| Architecture | Victorian brick and stone + riveted steel, pipes, lifts, trams, searchlights |
| Monsters | Mostly silhouettes and traces; full reveal only in combat. Wrong proportions rather than gore |
| Avoid | Text in images, modern objects, neon, anime, high saturation, cartoon proportions |

```text
STYLE BLOCK (paste at the start of every prompt):
Dark gaslight-and-steel fantasy, Lovecraftian mysticism. Hand-painted illustration
with ink linework, like an old engraved map coloured with muted watercolour.
Palette: soot black #2B2420, parchment #ECE4D2, tarnished brass #B08A4A,
cold steel blue #6E7A8A, dried blood red #8A1C1C, fog grey #BDBDB8,
sickly moon silver #C9CCD8. Low saturation, strong value contrast,
warm lamplight against cold fog. Late-19th-century architecture fused with
advanced machinery (lifts, pipes, brass, rivets). Ominous, quiet, human-scale details.
No text, no letters, no watermarks, no modern objects, no bright neon, no anime style.
```

## 16.3 City prompts

```text
PROMPT A — Full city map (top-down illustrated map)
[STYLE BLOCK]
Attached: city_sketch.png (district layout) and city_grid.txt (same layout as text).
Paint an illustrated top-down map of the city of Hallowdeep, north is up.
FOLLOW THE ATTACHED SKETCH EXACTLY: same circle, same district borders and sizes,
same positions of the three gates and the numbered landmarks. Do not add or move districts.
The city stands on a giant round metal platform enclosed by a black steel ring wall
(the Ringwall) with three gates: north (Hawk Gate), south-east (Wolf Gate),
south-west (Bear Gate). Outside the wall there is only thick grey fog (the Mistveil).
Districts and their look:
- Centre: Crown Ward — marble citadel, clock towers, glass-domed gardens (highest ground).
- North / north-west: Silverhill — white cathedral with moon rose window, convent, terraced cemetery.
- North-east of centre (small wedge): Vigil Spire Ward — one 300 m honeycomb tower, drill yards.
- East of centre: Lumen Campus — glass labs, coloured chimney smoke, library with brass dome.
- South of centre: Rowan Market — covered market rows, awnings, crate yards.
- West of centre: Morrell Ward — clinics, greenhouses, green lamps.
- Whole west and south-west to the wall: the Numbered Avenues — a dense regular grid of identical streets, tram lines.
- North-east outer ring: Nordhal Quarter — dark brick, forges, runes, a tavern with a hook-shaped sign.
- East outer ring: Grey Chapels — ruined chapels, shanty roofs, fog in alleys.
- South-east: Deepwright Lifts — huge lift shafts, foundries, smoke, ore yards.
- South: Scarlet Lantern Row — narrow alleys under red lanterns.
- At each gate: a small fortified trading post with a totem (eagle north, wolf south-east, bear south-west).
A dashed tram ring separates the inner and outer districts.
Aspect ratio 1:1, high detail, readable district borders, no labels or text.
```

```text
PROMPT B — City cross-section (side view)
[STYLE BLOCK]
Attached: city_cross_section.png (layer order).
A vertical cross-section of the city of Hallowdeep, side view, like an engraved scientific plate.
Top: the Upper City on a thick metal platform with a skyline (a 300 m tower left of centre,
a citadel in the centre), the black Ringwall on both edges, grey fog walls beyond.
Below the platform: the Transition Zone — slums hanging from the underside and on the ground,
supported by giant pillars. Then underground strata: mines of levels 6-5 with miners in black robes,
level 4 with fungal forests and twisted dwellers, level 3 with strange carved halls,
levels 2-1 dark and cracked, then ruins of an ancient capital with huge dragon bones,
and at the very bottom a glowing violet fissure into a dream realm.
Two deep lift shafts run from the platform down through all layers on the right side.
Aspect ratio 16:9, no labels or text.
```

## 16.4 District prompts

Two prompts per district: **C1 — map tile** (top-down piece of the city map) and **C2 — establishing scene** (left picture of the rumor tablet). Save as `<CODE>__tile__normal.webp` and `<CODE>__scene__normal.webp`.

### Crown Ward [CROWN]

```text
PROMPT C1 — [STYLE BLOCK]
District map tile for the city map. Top-down view, north is up, same scale and style as the full city map.
District: Crown Ward (CROWN). Administrative / nobility.
Look: Marble galleries, a citadel of black steel and white stone, clock towers on every square, gas lamps with brass cages, named streets, private gardens under glass domes.
Areas to show: Citadel Square, The Glass Gardens, Gallery Row (noble mansions), Clockmakers' Steps.
Mood: polished, cold, silent luxury hiding rot.
Transparent or parchment background outside the district shape; no labels or text.
```

```text
PROMPT C2 — [STYLE BLOCK]
Establishing illustration for the rumor tablet (left side of the tablet).
Street-level view inside Crown Ward: Marble galleries, a citadel of black steel and white stone, clock towers on every square, gas lamps with brass cages, named streets, private gardens under glass domes.
Time: dusk or night with fog. Show signs of this rumor flavour: a servant 'acting differently'; mirrors covered with cloth; one more guest at the ball than invited.
No monster visible — only traces and atmosphere. Mood: polished, cold, silent luxury hiding rot.
Aspect ratio 4:5, no text.
```

### Silverhill [SILVERHILL]

```text
PROMPT C1 — [STYLE BLOCK]
District map tile for the city map. Top-down view, north is up, same scale and style as the full city map.
District: Silverhill (SILVERHILL). Religious.
Look: White cathedrals with moon-shaped rose windows, silver domes, convent walls, terraced cemetery down to the Ringwall, orphanage courtyards.
Areas to show: Cathedral Close, Convent of St. Aldric, Terraced Cemetery, Orphans' Stair.
Mood: pale, sacred, moonlit, unsettling serenity.
Transparent or parchment background outside the district shape; no labels or text.
```

```text
PROMPT C2 — [STYLE BLOCK]
Establishing illustration for the rumor tablet (left side of the tablet).
Street-level view inside Silverhill: White cathedrals with moon-shaped rose windows, silver domes, convent walls, terraced cemetery down to the Ringwall, orphanage courtyards.
Time: dusk or night with fog. Show signs of this rumor flavour: at full moon; smells of incense and blood; the victim was smiling.
No monster visible — only traces and atmosphere. Mood: pale, sacred, moonlit, unsettling serenity.
Aspect ratio 4:5, no text.
```

### Vigil Spire Ward [VIGIL]

```text
PROMPT C1 — [STYLE BLOCK]
District map tile for the city map. Top-down view, north is up, same scale and style as the full city map.
District: Vigil Spire Ward (VIGIL). Military order.
Look: A 300-metre honeycomb tower with 49 elevators, barracks, drill yards, archive halls, steel banners.
Areas to show: The Spire, Drill Yards, Archive Halls.
Mood: disciplined, vertical, iron and lamplight.
Transparent or parchment background outside the district shape; no labels or text.
```

```text
PROMPT C2 — [STYLE BLOCK]
Establishing illustration for the rumor tablet (left side of the tablet).
Street-level view inside Vigil Spire Ward: A 300-metre honeycomb tower with 49 elevators, barracks, drill yards, archive halls, steel banners.
Time: dusk or night with fog. Show signs of this rumor flavour: armour found empty; orders given by no one; lights in the archive at night.
No monster visible — only traces and atmosphere. Mood: disciplined, vertical, iron and lamplight.
Aspect ratio 4:5, no text.
```

### Lumen Campus [LUMEN]

```text
PROMPT C1 — [STYLE BLOCK]
District map tile for the city map. Top-down view, north is up, same scale and style as the full city map.
District: Lumen Campus (LUMEN). University / science.
Look: Lecture halls, glass laboratories, chimneys with coloured smoke, the Great Library with a brass dome, mechanical department workshops.
Areas to show: Great Library, Alchemy Wing, Mechanical Department, Lecture Quad.
Mood: clinical, curious, brass and glass, knowledge as power.
Transparent or parchment background outside the district shape; no labels or text.
```

```text
PROMPT C2 — [STYLE BLOCK]
Establishing illustration for the rumor tablet (left side of the tablet).
Street-level view inside Lumen Campus: Lecture halls, glass laboratories, chimneys with coloured smoke, the Great Library with a brass dome, mechanical department workshops.
Time: dusk or night with fog. Show signs of this rumor flavour: smell of formalin; glass chiming; the skull opened neatly, like in a lecture.
No monster visible — only traces and atmosphere. Mood: clinical, curious, brass and glass, knowledge as power.
Aspect ratio 4:5, no text.
```

### Rowan Market [MARKET]

```text
PROMPT C1 — [STYLE BLOCK]
District map tile for the city map. Top-down view, north is up, same scale and style as the full city map.
District: Rowan Market (MARKET). Trade.
Look: Covered rows, scales, crates, awnings, a central hall with a rowan tree carved in wood. The hero's shop is a wooden table with cards.
Areas to show: Central Hall, Covered Rows, Crate Yards.
Mood: busy, warm lamplight, haggling, hidden contraband.
Transparent or parchment background outside the district shape; no labels or text.
```

```text
PROMPT C2 — [STYLE BLOCK]
Establishing illustration for the rumor tablet (left side of the tablet).
Street-level view inside Rowan Market: Covered rows, scales, crates, awnings, a central hall with a rowan tree carved in wood. The hero's shop is a wooden table with cards.
Time: dusk or night with fog. Show signs of this rumor flavour: the cargo moved; a trader went mad with greed; roots through the cobbles.
No monster visible — only traces and atmosphere. Mood: busy, warm lamplight, haggling, hidden contraband.
Aspect ratio 4:5, no text.
```

### Rowan Exchange Posts [EXCHANGE]

```text
PROMPT C1 — [STYLE BLOCK]
District map tile for the city map. Top-down view, north is up, same scale and style as the full city map.
District: Rowan Exchange Posts (EXCHANGE). Trade enclaves.
Look: Fortified warehouses at the gates, totem carvings (eagle / wolf / bear), caravan yards, weighing towers.
Areas to show: Hawk Post, Wolf Post, Bear Post.
Mood: fortified, tribal-mercantile, fog at the gates.
Transparent or parchment background outside the district shape; no labels or text.
```

```text
PROMPT C2 — [STYLE BLOCK]
Establishing illustration for the rumor tablet (left side of the tablet).
Street-level view inside Rowan Exchange Posts: Fortified warehouses at the gates, totem carvings (eagle / wolf / bear), caravan yards, weighing towers.
Time: dusk or night with fog. Show signs of this rumor flavour: fog on the cargo; a caravan arrived with one driver too many.
No monster visible — only traces and atmosphere. Mood: fortified, tribal-mercantile, fog at the gates.
Aspect ratio 4:5, no text.
```

### The Numbered Avenues [AVENUES]

```text
PROMPT C1 — [STYLE BLOCK]
District map tile for the city map. Top-down view, north is up, same scale and style as the full city map.
District: The Numbered Avenues (AVENUES). Middle class (largest).
Look: An endless grid of identical streets: '12th Avenue', 'Street K'. Offices, shops, tenement houses, trams.
Areas to show: 4th Avenue, 23rd Avenue, Tram Depot, Letter Streets (A–Z), Laundry Canals.
Mood: grey routine, rain, repetition, lonely windows.
Transparent or parchment background outside the district shape; no labels or text.
```

```text
PROMPT C2 — [STYLE BLOCK]
Establishing illustration for the rumor tablet (left side of the tablet).
Street-level view inside The Numbered Avenues: An endless grid of identical streets: '12th Avenue', 'Street K'. Offices, shops, tenement houses, trams.
Time: dusk or night with fog. Show signs of this rumor flavour: wet handprints on windows; children singing in the drains; the last tram arrived empty.
No monster visible — only traces and atmosphere. Mood: grey routine, rain, repetition, lonely windows.
Aspect ratio 4:5, no text.
```

### Morrell Ward [MORRELL]

```text
PROMPT C1 — [STYLE BLOCK]
District map tile for the city map. Top-down view, north is up, same scale and style as the full city map.
District: Morrell Ward (MORRELL). Medical.
Look: Clinics, apothecaries, greenhouses with herbs, a morgue with green lamps.
Areas to show: Apothecarium, Greenhouses, The Morgue.
Mood: sterile green light, herbs, quiet suffering.
Transparent or parchment background outside the district shape; no labels or text.
```

```text
PROMPT C2 — [STYLE BLOCK]
Establishing illustration for the rumor tablet (left side of the tablet).
Street-level view inside Morrell Ward: Clinics, apothecaries, greenhouses with herbs, a morgue with green lamps.
Time: dusk or night with fog. Show signs of this rumor flavour: the corpse was warm a week later; bitter herbal smell; nurses refuse the night shift.
No monster visible — only traces and atmosphere. Mood: sterile green light, herbs, quiet suffering.
Aspect ratio 4:5, no text.
```

### Nordhal Quarter [NORDHAL]

```text
PROMPT C1 — [STYLE BLOCK]
District map tile for the city map. Top-down view, north is up, same scale and style as the full city map.
District: Nordhal Quarter (NORDHAL). Hunters / working class — HOME.
Look: Dark brick, Nordhal runes on doors, forges, fighting pits, steam from bathhouses.
Areas to show: Tavern Street, Forge Row, The Pits, Old Rune Yard.
Mood: rough, warm firelight, brotherhood and dread.
Transparent or parchment background outside the district shape; no labels or text.
```

```text
PROMPT C2 — [STYLE BLOCK]
Establishing illustration for the rumor tablet (left side of the tablet).
Street-level view inside Nordhal Quarter: Dark brick, Nordhal runes on doors, forges, fighting pits, steam from bathhouses.
Time: dusk or night with fog. Show signs of this rumor flavour: a howl; human footprints turning into paws; smell of blood and medicine.
No monster visible — only traces and atmosphere. Mood: rough, warm firelight, brotherhood and dread.
Aspect ratio 4:5, no text.
```

### Grey Chapels [GREY]

```text
PROMPT C1 — [STYLE BLOCK]
District map tile for the city map. Top-down view, north is up, same scale and style as the full city map.
District: Grey Chapels (GREY). Slums at the platform edge.
Look: Ruined chapels of a forgotten faith, shanty roofs, grey fog in cellars, bonfires.
Areas to show: The Old Grey Chapel, Shanty Roofs, Edge Walk (railing over the abyss).
Mood: poverty, ash and fog, forbidden faith.
Transparent or parchment background outside the district shape; no labels or text.
```

```text
PROMPT C2 — [STYLE BLOCK]
Establishing illustration for the rumor tablet (left side of the tablet).
Street-level view inside Grey Chapels: Ruined chapels of a forgotten faith, shanty roofs, grey fog in cellars, bonfires.
Time: dusk or night with fog. Show signs of this rumor flavour: grey fog in the cellar; prayers to the god in the wall; people with grey eyes.
No monster visible — only traces and atmosphere. Mood: poverty, ash and fog, forbidden faith.
Aspect ratio 4:5, no text.
```

### Deepwright Lifts [DEEPWRIGHT]

```text
PROMPT C1 — [STYLE BLOCK]
District map tile for the city map. Top-down view, north is up, same scale and style as the full city map.
District: Deepwright Lifts (DEEPWRIGHT). Industrial.
Look: Giant mine lifts going down through the platform, foundries, ore yards, machines roaring, workers in masks.
Areas to show: Main Lifts, Foundry Line, Ore Yards, Shaft 7 (sealed).
Mood: industrial hell, sparks, steam, deep shafts.
Transparent or parchment background outside the district shape; no labels or text.
```

```text
PROMPT C2 — [STYLE BLOCK]
Establishing illustration for the rumor tablet (left side of the tablet).
Street-level view inside Deepwright Lifts: Giant mine lifts going down through the platform, foundries, ore yards, machines roaring, workers in masks.
Time: dusk or night with fog. Show signs of this rumor flavour: walls eaten through; the floor collapsed; workers heard knocking from below.
No monster visible — only traces and atmosphere. Mood: industrial hell, sparks, steam, deep shafts.
Aspect ratio 4:5, no text.
```

### Scarlet Lantern Row [SCARLET]

```text
PROMPT C1 — [STYLE BLOCK]
District map tile for the city map. Top-down view, north is up, same scale and style as the full city map.
District: Scarlet Lantern Row (SCARLET). Red-light / black market.
Look: Narrow alleys under red lanterns, brothels, gambling dens, underground auction houses, black magicians' parlours.
Areas to show: Lantern Alley, The Auction House, Velvet Steps.
Mood: red light, perfume and blood, seductive danger.
Transparent or parchment background outside the district shape; no labels or text.
```

```text
PROMPT C2 — [STYLE BLOCK]
Establishing illustration for the rumor tablet (left side of the tablet).
Street-level view inside Scarlet Lantern Row: Narrow alleys under red lanterns, brothels, gambling dens, underground auction houses, black magicians' parlours.
Time: dusk or night with fog. Show signs of this rumor flavour: a client left without a face; whispering in an unknown tongue; blood on the mirror.
No monster visible — only traces and atmosphere. Mood: red light, perfume and blood, seductive danger.
Aspect ratio 4:5, no text.
```

## 16.5 District state variants

```text
PROMPT D — State variant of an existing district image
[STYLE BLOCK]
Attached: <CODE>__normal.webp (the base image).
Repaint THE SAME IMAGE: keep exactly the same composition, camera angle, buildings,
silhouettes and borders. Change only what the state requires:
- flooded:     shallow dark water in low streets, boats, sandbags, rain, reflections of lamps
- fog_breach:  thick grey fog pouring over the wall, dimmed lamps, cracks of violet light
- burning:     fires in several buildings, orange glow, smoke columns
- burned:      black ruins and ash where the fires were, no flames, cold light
- rebuilt:     new buildings in a slightly different style where the ruins were, scaffolding remains
- quarantine:  barricades, chalk marks on doors, plague-doctor masks, yellow warning cloth
- riot:        barricades, smoke, broken windows, torches, scattered crates
- martial_law: patrols in iron armour, steel banners, checkpoints
- festival:    garlands, bonfires, paper lanterns, crowds
- eclipse:     black-silver sky, moonlight inverted, eerie silver glow on white stone
- collapsed:   a section of the platform has fallen, a hole showing the slums far below
- cleansed:    warmer light, people back on streets, repaired lamps
State to apply: <STATE>. No text.
```

## 16.6 UI and props

| Asset | Prompt (after the STYLE BLOCK) |
|---|---|
| Tavern contract board | A wooden wall in a tavern covered with pinned paper leaflets, each with a black creature silhouette and a reward coin drawing, candle and lamp light, some leaflets stamped with a red wax seal. Front view, 16:9, no readable text (use scribble lines instead of letters). |
| Contract tablet | An empty clipboard-like tablet of dark wood and brass with a parchment sheet, an empty frame for a creature silhouette at the top, ruled lines, a round empty area for a seal. Front view, 3:4, no text. |
| Wax seal stamp | A red wax seal with a hook-and-lantern emblem, top view, isolated on transparent background, 1:1. |
| Shop table | A rough wooden table seen from above, with space for cards laid out in rows, a brass scale and coin pouches on the edges, warm lamp light, 16:9. |
| Hero figurine | A small carved stone figurine of a monster hunter in a long coat and wide-brimmed hat with a rifle on the back, standing on a round stone pedestal. Make 4 views: front, back, left, right. Isolated, transparent background. |
| Rumor diamond icon | A diamond-shaped icon of aged brass with a small inner glow (blue), slightly worn, isolated, 1:1, three versions: idle, hovered (brighter), investigated (dim, crossed). |
| Search ring | A soft blue circular aura spreading on a map surface, ink-like edges, transparent background, 1:1. |
| Weapon tablet | A side view of a hunting rifle on a parchment schematic with five clearly separated sections (scope, magazine, stock, frame, barrel) and empty square cells drawn over each section. Engineering drawing style, 16:9, no text. |
| Resource icons | Set of 6 icons in one row, same style: brass gear, pile of scrap metal, small circuit board, drop of dark red blood, a monster fang, a gold coin. Transparent background. |

## 16.7 Monster silhouettes

```text
[STYLE BLOCK]
A pure black silhouette of <MONSTER> on a parchment background, as drawn on a
hunters' contract leaflet. Readable shape at small size, slightly wrong proportions,
no inner details, no text. Make a second version: the same silhouette 'cracked',
revealing a glimpse of its true form inside (for the phase change). 1:1.
```

> **Note:** Generated art is a starting point. Keep the source images in docs/assets (not imported by Godot) and only the processed webp files in art/.
