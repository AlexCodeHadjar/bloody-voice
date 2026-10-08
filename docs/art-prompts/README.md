# Art Prompts — Modules, Creatures, Icons

Prompts for ChatGPT image generation, **generated from the game data** — do not edit by hand,
change the data and run `python tools/gen_art_prompts.py`. City, districts, district states and UI props:
see [GDD §16](../gdd/16-art-direction-and-generation-prompts.md).

| Page | Content |
|---|---|
| [modules.md](modules.md) | 20 weapon modules in 11 cell shapes |
| [creatures.md](creatures.md) | 8 creatures × 4 images (combat art, phase 2, leaflet silhouette, cracked) |
| [icons.md](icons.md) | 152 icons in 22 sets — one image per set |
| [district-grey-chapels.md](district-grey-chapels.md) | Hand-written: close-up map of the Grey Chapels (overview + 12 tiles) |
| [combat-ui.md](combat-ui.md) | Hand-written: combat screen v2 pieces (card frames, medallions, vials, lamps…) |
| [workshop-and-skills-ui.md](workshop-and-skills-ui.md) | Hand-written: workshop, Mechanic web and Monster web pieces (one file) |

## How to use

1. One chat per set: one for all modules, one per creature, one per icon style. The model keeps the style inside a chat.
2. Paste the STYLE BLOCK first (plus the MODULE STYLE or ICON STYLE the prompt names), then the prompt.
3. Attach the files the prompt names: templates from `docs/assets/templates/` (`python tools/gen_art_templates.py`),
   references from `art/ui/` (resource icons: `art/ui/icons/RESOURCE__*.webp`).
4. When a result is good, attach it as a style reference for the next one.
5. Save with the exact file name into `assets/modules/`, `assets/monsters/` or `assets/icons/`, then run
   `python tools/import_art.py` (modules are cut to their cell shape, icon sets into single icons).

```text
STYLE BLOCK (paste at the start of every prompt):
Dark gaslight-and-steel fantasy, Lovecraftian mysticism. Hand-painted illustration
with ink linework, like an old engraved plate coloured with muted watercolour.
Palette: soot black #2B2420, parchment #ECE4D2, tarnished brass #B08A4A,
cold steel blue #6E7A8A, dried blood red #8A1C1C, fog grey #BDBDB8,
sickly moon silver #C9CCD8. Low saturation, strong value contrast.
Late-19th-century craftsmanship fused with advanced machinery (brass, rivets, glass).
No text, no letters, no numbers, no watermarks, no modern objects, no neon, no anime style.
```

## Quality checklist

| Check | Modules | Creatures | Icons |
|---|---|---|---|
| Transparent background, no text / grid / frames | yes | yes | yes |
| Fills the template | dark shape edge to edge | safe area, feet on the ground line | grid as in the layout guide |
| Readable small | 64 px per cell | silhouette at 96 px | symbols at 32 px |
| Consistency | cell type readable by material | phase 2 and silhouettes match the first combat art | one accent colour; rank badges empty |

If ChatGPT keeps adding a background, add: "The background must be fully transparent (alpha 0)."
