# Art Prompts — Workshop, Mechanic web, Monster web

Hand-written (not generated). One file for all three screens. Design: [GDD §23](../gdd/23-workshop-and-skill-web-screens.md);
sketches `docs/assets/ui/workshop_layout.png`, `skills_mechanic_layout.png`, `skills_monster_layout.png`
(`python tools/gen_screen_sketches.py`).

## What the game draws itself (no images needed)

| Thing | How |
|---|---|
| Cell grid of a module on the bench | Drawn by code from the module's shape (`data/gear/shapes.json`) |
| Rings and lines of the skill webs, links between nodes | Drawn by code in the web colour (they move and zoom with the web) |
| Node states: owned / available / locked; selected rows, pressed buttons, spent tokens, empty tier pips | One image per piece, the state is a tint, glow or darkening applied by code |
| Liquid in the XP bar and the Voice gauge, the «можно купить» glow | Coloured fill / shader inside the tube images |
| Missing resource | The number turns red |
| Top bar, side panels, plain buttons («В район», «Разобрать», «К снаряжению») | `COMBAT__plate` from [combat-ui.md](combat-ui.md) (9-slice) |

## Already exists — do not generate

| Need | Existing art |
|---|---|
| Module pictures in lists, bench, stash | `art/gear/modules/*` (20 modules) |
| Resources, lock, attributes, armor pieces, directions (incl. «к снаряжению»), factions, XP, skill point, Voice | `art/ui/icons/RESOURCE__*`, `UI__lock`, `ATTRIBUTE__*`, `ARMOR__*`, `DIRECTION__*`, `FACTION__*`, `STAT__xp`, `STAT__skill_point`, `STAT__voice` |
| Icons in the middle of skill nodes | `art/ui/icons/SKILL__*` (passive, blueprint, socket, keystone) |
| Blood samples | `art/monsters/*__silhouette__leaflet` + count and «чист.» as text |

Shared with the combat screen — generate them from [combat-ui.md](combat-ui.md), not here: `COMBAT__plate`,
the card frames `COMBAT__card_frame__*` (mini-cards in «Что даст в колоде») and `COMBAT__hunter_portrait`.

## How to use

1. **Three chats**, one per part below (A Workshop, B Mechanic web, C Monster web). Inside a chat the style holds.
2. At the start of each chat paste the STYLE BLOCK and attach the screen's sketch with this sentence:
   «The attached sketch is only a composition guide for the screen these pieces belong to. Do not reproduce its
   text, numbers or labels.»
3. A **background or texture**: STYLE BLOCK + the prompt. Every other piece: STYLE BLOCK + UI BLOCK + the prompt.
4. **Canvas:** ChatGPT makes only 1024×1024 (square), 1536×1024 (wide) or 1024×1536 (tall). Each row names the
   canvas to ask for. Long thin pieces are drawn across the whole width of a wide canvas with empty margins
   above and below — the import crops them. The game scales everything; exact pixel sizes do not matter.
5. Rows marked «with A2 / B2 / C2 attached» must be made with that image attached as the style reference, so a
   family (all node frames of one web, both tabs…) looks like one set.
6. Save into `assets/ui/` with the exact file name, then run `python tools/import_art.py`: it cuts out the magenta
   background (corners must be magenta) and trims empty margins.

```text
STYLE BLOCK:
Dark gaslight-and-steel fantasy, Lovecraftian mysticism. Hand-painted illustration
with ink linework, like an old engraved plate coloured with muted watercolour.
Palette: soot black #2B2420, parchment #ECE4D2, tarnished brass #B08A4A,
cold steel blue #6E7A8A, dried blood red #8A1C1C, fog grey #BDBDB8,
sickly moon silver #C9CCD8. Low saturation, strong value contrast,
warm lamplight against cold fog. Late-19th-century craftsmanship fused with
advanced machinery (brass, rivets, glass, pipes). Ominous, quiet, human-scale details.
No text, no letters, no numbers, no watermarks, no modern objects, no neon, no anime style.
```

```text
UI BLOCK:
A single game interface element, front view, centred on a flat pure magenta (#FF00FF)
background that fills the whole canvas and all four corners (it will be cut out).
The element is fully opaque with hard clean edges: no glow, no soft shadow, no smoke,
no transparent glass bleeding into the background. Nothing else in the image.
Engraved, hand-painted look matching the style block. Even soft light from the top-left.
No text, no letters, no numbers.
```

## A. Workshop «Ржавая Шестерня» (9 images)

Mood: a cramped slum workshop — soot, oil, brass shavings, one hanging lamp, sparks.

| # | File | Canvas | Use (zone) | Prompt |
|---|---|---|---|---|
| A1 | `WORKSHOP__background.png` | wide | Behind the panels (low priority: panels cover most of it) | **Background, no UI BLOCK.** Interior of a cramped workshop in a slum, seen slightly from above: a heavy workbench under one hanging oil lamp, vices, gear wheels, rifle parts, scrap piles in the corners, a forge glowing at the back left, tools on a pegboard, soot on brick walls. The centre is calm and darker so panels can sit on top. |
| A2 | `WORKSHOP__blueprint_sheet.png` | wide | Workbench (zone 5) | An unrolled sheet of aged blueprint parchment pinned flat with four brass tacks, faint blue millimetre grid only near the edges, the middle completely plain and empty, oil and coffee stains at the corners, slightly curled corners. The sheet fills most of the canvas. |
| A3 | `WORKSHOP__list_row.png` | wide | Blueprint row (zone 4), stash item (zone 8); selected = brighter tint | A long horizontal plate of dark oiled wood with a thin brass edge and two small rivets at each end, empty. Draw it across the whole width of the canvas, about one quarter of the canvas tall, plain magenta above and below. Uniform border so it can be stretched. |
| A4 | `WORKSHOP__tab.png` | square | Blueprint tabs (zone 2); idle = darker tint | Small tab of brass sheet with a bent top edge, empty. Wide shape (about 3 times wider than tall) in the middle of the canvas. With A3 attached. |
| A5 | `WORKSHOP__craft_button.png` | wide | «Изготовить» (zone 7) | A large heavy brass stamping-press button: a round domed plunger on a riveted rectangular base plate with an empty area for a word. With A3 attached. |
| A6 | `WORKSHOP__craft_token.png` | square | «Изготовлений сегодня» (zone 1); spent = dark tint | A brass gear-shaped token with an amber enamel centre, like a work ticket. |
| A7 | `WORKSHOP__tier_pip.png` | square | Tier I–III marks; not reached = dark tint | One round polished brass rivet head, filling the middle third of the canvas. |
| A8 | `WORKSHOP__icon_upgrade.png` | square | «Улучшить» (zone 9) | Icon: a brass gear with a riveted upward arrow plate on it. Same icon style as the attached `art/ui/icons/DIRECTION__equipment.webp`. |
| A9 | `WORKSHOP__icon_salvage.png` | square | «Разобрать» (zone 9) | Icon: pliers taking a small module apart, two gears and screws falling out. Same icon style as A8. |

## B. Mechanic web «Ветка Механика» (11 images)

Mood: an engineer's precise schematic — brass, blueprint paper, cold steel and warm brass.

| # | File | Canvas | Use (zone) | Prompt |
|---|---|---|---|---|
| B1 | `SKILLS__texture_mechanic.png` | square | Paper under the web (zone 3), tiled | **Texture, no UI BLOCK.** Seamless tileable texture of dark navy-grey drafting paper with a faint fibre grain and very subtle ink smudges. No circles, no lines from a centre, no marks, no grid, no numbers — evenly the same everywhere so it tiles. |
| B2 | `SKILLS__node_mech__passive.png` | square | Passive node (circle) | A round brass node: a polished brass disc in a riveted ring, the centre a plain dark recess (an icon is placed there by the game). Fills the middle half of the canvas. |
| B3 | `SKILLS__node_mech__blueprint.png` | square | Blueprint node (square) | A square brass frame with folded-paper corners, like a tiny framed blueprint, plain dark centre. With B2 attached — same rim thickness and light. |
| B4 | `SKILLS__node_mech__socket.png` | square | Socket node (hexagon) | A hexagonal brass ring like a heavy nut, plain dark centre. With B2 attached. |
| B5 | `SKILLS__node_mech__keystone.png` | square | Keystone node (diamond) | A large diamond-shaped brass plate with ornate engraved edges and four rivets, plain dark centre, richer than the other nodes. With B2 attached. |
| B6 | `SKILLS__start_mechanic.png` | square | «Старт» in the centre | A large round brass medallion with a central gear and four short spokes pointing up, right, down and left. With B2 attached. |
| B7 | `SKILLS__tab__mechanic.png` | wide | Web tab (zone 2); inactive = dark tint | A wide brass name plate with a small gear emblem at the left end, empty space for a word, across the canvas width, magenta above and below. |
| B8 | `SKILLS__node_card__mechanic.png` | tall | Node card (zone 6) | A tall parchment card in a thin brass frame with corner rivets, a faint blueprint grid on the paper, empty. Uniform border so it can be stretched. |
| B9 | `SKILLS__button__mechanic.png` | wide | «Изучить» (zone 6) | A brass push-button plate with a raised rim and an empty face for a word. With B7 attached. |
| B10 | `SKILLS__tube.png` | wide | XP bar (zone 1) and, tinted, the Voice gauge frame (zone 7, Monster) | A long thin horizontal tube holder of blackened brass with end caps and three small notches, the inside a plain solid dark slot (the game fills it). Across the canvas width, magenta above and below. |
| B11 | `SKILLS__attribute_plus.png` | square | «+» next to attributes (zone 4) — **shared by both webs** | A small round brass knob with a raised plus-shaped cross, filling the middle third of the canvas. |

## C. Monster web «Ветка Твари — Голос» (10 images)

Mood: the same web, but alive — bone, sinew, dried blood, veins. Unsettling, not gory.

| # | File | Canvas | Use (zone) | Prompt |
|---|---|---|---|---|
| C1 | `SKILLS__texture_monster.png` | square | Surface under the web (zone 3), tiled | **Texture, no UI BLOCK.** Seamless tileable texture of dark reddish-black dried leather or old hide with a few very thin dark veins, evenly spread. No centre, no rings, no radiating lines, no marks — evenly the same everywhere so it tiles. |
| C2 | `SKILLS__node_beast__passive.png` | square | Passive node (circle) | A round node of polished bone with a dark red rim, a plain dark centre (an icon is placed there by the game). Fills the middle half of the canvas. Same size and framing as the attached B2. |
| C3 | `SKILLS__node_beast__blueprint.png` | square | Formula node (square) | A square frame of bone splinters bound with sinew, plain dark centre. With C2 attached. |
| C4 | `SKILLS__node_beast__socket.png` | square | Blood socket (hexagon) | A hexagonal socket of dark bone, the centre a plain dark recess. With C2 attached. |
| C5 | `SKILLS__node_beast__keystone.png` | square | Keystone (diamond) | A large diamond-shaped plate of fused bone and dark red chitin, cracked, plain dark centre, ominous. With C2 attached. |
| C6 | `SKILLS__start_monster.png` | square | «Старт» in the centre | A round bone medallion with a dark red heart-like gem in the middle and four short veins going up, right, down and left. With C2 attached. |
| C7 | `SKILLS__tab__monster.png` | wide | Web tab (zone 2); inactive = dark tint | A wide plate of dark bone and leather with a small fang emblem at the left end, empty space for a word, across the canvas width, magenta above and below. Same shape as the attached B7. |
| C8 | `SKILLS__node_card__monster.png` | tall | Node card (zone 6) | A tall parchment card in a thin dark-red bone frame, faint brown stains on the paper, empty. Same shape as the attached B8. |
| C9 | `SKILLS__button__monster.png` | wide | «Изучить» (zone 6) | A push-button plate of dark bone with a dried-blood red face, raised rim, empty face for a word. Same shape as the attached B9. |
| C10 | `SKILLS__voice_warning.png` | square | Warning before a Voice stage | A dark red wax seal with a howling beast mark, slightly cracked, filling the middle half of the canvas. |

## Checklist after generation

- File names exactly as in the tables; save to `assets/ui/`.
- Textures B1, C1 and background A1: no magenta, full image; textures must tile (check by placing two side by side).
- Everything else: magenta in all four corners, one opaque element, no text.
- Node frames of one web (B2–B6, C2–C6) look like one family: same rim thickness, same light, same size.
- Send the results to Claude for import and fitting into the screens.
