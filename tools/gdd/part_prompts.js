// Part 3 — art direction and ChatGPT prompts for the city
const { H1, H2, H3, P, Bul, Num, Note, Code, Tbl } = require("./lib");
const { DISTRICTS } = require("./data_city");

const STYLE = `STYLE BLOCK (paste at the start of every prompt):
Dark gaslight-and-steel fantasy, Lovecraftian mysticism. Hand-painted illustration
with ink linework, like an old engraved map coloured with muted watercolour.
Palette: soot black #2B2420, parchment #ECE4D2, tarnished brass #B08A4A,
cold steel blue #6E7A8A, dried blood red #8A1C1C, fog grey #BDBDB8,
sickly moon silver #C9CCD8. Low saturation, strong value contrast,
warm lamplight against cold fog. Late-19th-century architecture fused with
advanced machinery (lifts, pipes, brass, rivets). Ominous, quiet, human-scale details.
No text, no letters, no watermarks, no modern objects, no bright neon, no anime style.`;

const mapPrompt = `PROMPT A — Full city map (top-down illustrated map)
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
Aspect ratio 1:1, high detail, readable district borders, no labels or text.`;

const crossPrompt = `PROMPT B — City cross-section (side view)
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
Aspect ratio 16:9, no labels or text.`;

const districtTile = (d) => `[STYLE BLOCK]
District map tile for the city map. Top-down view, north is up, same scale and style as the full city map.
District: ${d.name} (${d.code}). ${d.cls}.
Look: ${d.look}
Areas to show: ${d.areas.join(", ")}.
Mood: ${d.mood}.
Transparent or parchment background outside the district shape; no labels or text.`;

const districtScene = (d) => `[STYLE BLOCK]
Establishing illustration for the rumor tablet (left side of the tablet).
Street-level view inside ${d.name}: ${d.look}
Time: dusk or night with fog. Show signs of this rumor flavour: ${d.tags}.
No monster visible — only traces and atmosphere. Mood: ${d.mood}.
Aspect ratio 4:5, no text.`;

const variantPrompt = `PROMPT D — State variant of an existing district image
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
State to apply: <STATE>. No text.`;

const uiPrompts = [
  ["Tavern contract board", "A wooden wall in a tavern covered with pinned paper leaflets, each with a black creature silhouette and a reward coin drawing, candle and lamp light, some leaflets stamped with a red wax seal. Front view, 16:9, no readable text (use scribble lines instead of letters)."],
  ["Contract tablet", "An empty clipboard-like tablet of dark wood and brass with a parchment sheet, an empty frame for a creature silhouette at the top, ruled lines, a round empty area for a seal. Front view, 3:4, no text."],
  ["Wax seal stamp", "A red wax seal with a hook-and-lantern emblem, top view, isolated on transparent background, 1:1."],
  ["Shop table", "A rough wooden table seen from above, with space for cards laid out in rows, a brass scale and coin pouches on the edges, warm lamp light, 16:9."],
  ["Hero figurine", "A small carved stone figurine of a monster hunter in a long coat and wide-brimmed hat with a rifle on the back, standing on a round stone pedestal. Make 4 views: front, back, left, right. Isolated, transparent background."],
  ["Rumor diamond icon", "A diamond-shaped icon of aged brass with a small inner glow (blue), slightly worn, isolated, 1:1, three versions: idle, hovered (brighter), investigated (dim, crossed)."],
  ["Search ring", "A soft blue circular aura spreading on a map surface, ink-like edges, transparent background, 1:1."],
  ["Weapon tablet", "A side view of a hunting rifle on a parchment schematic with five clearly separated sections (scope, magazine, stock, frame, barrel) and empty square cells drawn over each section. Engineering drawing style, 16:9, no text."],
  ["Resource icons", "Set of 6 icons in one row, same style: brass gear, pile of scrap metal, small circuit board, drop of dark red blood, a monster fang, a gold coin. Transparent background."],
];

module.exports = () => [
  H1("16. Art Direction and Generation Prompts"),
  H2("16.1 How to use these prompts in ChatGPT"),
  Num([
    "Start **one chat per art set** (map, districts, UI) so the model keeps the style.",
    "Attach `docs/assets/map/city_sketch.png` and `docs/assets/map/city_grid.txt` for anything that shows the layout.",
    "Paste the **STYLE BLOCK**, then the prompt. Do not shorten the style block.",
    "When a result is good, attach it as a **style reference** for the next images ('match the style of the attached image').",
    "For state variants always attach the base image and use Prompt D.",
    "Save results to `docs/assets/art/<set>/` with the file names below, then import them with `tools/import_art.py` (resize, webp, copy to `art/`).",
  ]),
  H2("16.2 Style bible"),
  Tbl(["Aspect", "Rule"], [
    ["Palette", "Soot black #2B2420, parchment #ECE4D2, brass #B08A4A, steel blue #6E7A8A, blood red #8A1C1C, fog grey #BDBDB8, moon silver #C9CCD8"],
    ["Rendering", "Ink lines + muted watercolour, engraved-map feeling; UI in wood, brass and parchment"],
    ["Light", "Warm lamplight vs cold fog; moonlight for church areas; red for Scarlet Row; green for Morrell"],
    ["Architecture", "Victorian brick and stone + riveted steel, pipes, lifts, trams, searchlights"],
    ["Monsters", "Mostly silhouettes and traces; full reveal only in combat. Wrong proportions rather than gore"],
    ["Avoid", "Text in images, modern objects, neon, anime, high saturation, cartoon proportions"],
  ], [1, 4]),
  Code(STYLE, 16),
  H2("16.3 City prompts"),
  Code(mapPrompt, 15),
  Code(crossPrompt, 15),
  H2("16.4 District prompts"),
  P("Two prompts per district: **C1 — map tile** (top-down piece of the city map) and **C2 — establishing scene** (left picture of the rumor tablet). Save as `<CODE>__tile__normal.webp` and `<CODE>__scene__normal.webp`."),
  ...DISTRICTS.filter((d) => d.code !== "WALL").flatMap((d) => [
    H3(`${d.name} [${d.code}]`),
    Code("PROMPT C1 — " + districtTile(d), 15),
    Code("PROMPT C2 — " + districtScene(d), 15),
  ]),
  H2("16.5 District state variants"),
  Code(variantPrompt, 15),
  H2("16.6 UI and props"),
  Tbl(["Asset", "Prompt (after the STYLE BLOCK)"], uiPrompts, [1, 4]),
  H2("16.7 Monster silhouettes"),
  Code(`[STYLE BLOCK]
A pure black silhouette of <MONSTER> on a parchment background, as drawn on a
hunters' contract leaflet. Readable shape at small size, slightly wrong proportions,
no inner details, no text. Make a second version: the same silhouette 'cracked',
revealing a glimpse of its true form inside (for the phase change). 1:1.`, 15),
  Note("Generated art is a starting point. Keep the source images in docs/assets (not imported by Godot) and only the processed webp files in art/."),
];
