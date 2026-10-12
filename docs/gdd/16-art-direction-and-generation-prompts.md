# 16. Art Direction and Generation Prompts

## 16.1 How to use these prompts in ChatGPT

1. Start **one chat per art set** (map, districts, UI) so the model keeps the style.
2. Attach `docs/assets/map/city_sketch.png` for anything that shows the layout.
3. Paste the **STYLE BLOCK**, then the prompt. Do not shorten the style block.
4. When a result is good, attach it as a **style reference** for the next images ('match the style of the attached image').
5. For state variants always attach the base image and use Prompt D.
6. Save results to `assets/<districts|map|ui>/` with the file names below, then import them with `python tools/import_art.py` (webp into `art/`).

## 16.2 Style bible

> District close-up maps and ground-level scenes use **style v2** (owner, 2026-10-08): realistic painterly
> rainy Victorian night — see `art/city/district_maps/GREY__map.webp`. Whether the rest of the art follows is an open question.

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

## 16.3–16.4 City and district prompts

Removed 2026-10-12: the city map and all 12 district tiles and scenes are generated and in the game (`art/city/`).

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
