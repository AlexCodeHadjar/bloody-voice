# Art Prompts — Combat screen v2

Hand-written (not generated). Design: [GDD §21](../gdd/21-combat-screen-layout.md); sketches
`docs/assets/ui/combat_layout.png`, `card_anatomy.png` (`python tools/gen_ui_sketches.py`).

## How to use

1. One chat for all combat UI pieces. Paste the STYLE BLOCK (from [district-grey-chapels.md](district-grey-chapels.md)
   or GDD §16.2) and the UI BLOCK, then one prompt. Attach `combat_layout.png` once at the start so the model sees the screen.
2. When one piece is good, attach it as a style reference for the next.
3. Save into `assets/ui/` with the exact file name and run `python tools/import_art.py` (it will cut out the
   magenta background — added together with the combat screen v2 code).

```text
UI BLOCK:
A single game interface element, front view, centred on a flat pure magenta (#FF00FF)
background (it will be cut out), nothing else in the image. Materials of the world: tarnished brass with rivets,
dark oiled wood, aged parchment, smoked glass. Engraved, hand-painted look matching the
style block. Even soft light from the top-left. No text, no letters, no numbers.
```

| File | Prompt (after STYLE BLOCK + UI BLOCK) |
|---|---|
| `COMBAT__card_frame__attack.png` | A playing card frame, portrait 2:3: thin tarnished brass border with small corner rivets around a parchment face; the border is tinted dried blood red; a round empty socket top-left for a cost cog; an empty ribbon across the top; an empty rectangular art window in the upper 40 %; an empty text area below. 800x1200 |
| `COMBAT__card_frame__support.png` | Same card frame as the attached attack frame, border tinted cold steel blue |
| `COMBAT__card_frame__consumable.png` | Same card frame, border tinted muted bottle green |
| `COMBAT__card_frame__capture.png` | Same card frame, border of bright polished brass with a chain motif |
| `COMBAT__card_frame__rage.png` | Same card frame, border dark red with scratch marks like claws |
| `COMBAT__card_frame__curse.png` | Same card frame, border violet-black with grey fog stains on the parchment |
| `COMBAT__card_back.png` | The back of a playing card, portrait 2:3: dark wood inlaid with a brass emblem of a hook and a lantern, rivets on the corners. 800x1200 |
| `COMBAT__cost_cog.png` | A small brass cog with an empty flat centre for a number, 1:1, 256x256 |
| `COMBAT__intent_medallion.png` | A round brass medallion with a raised rim and an empty dark enamel centre, slight wear, 1:1, 512x512 |
| `COMBAT__part_ring__normal.png` | A thin glowing red-orange target ring like a hunter's chalk circle, top view, 1:1, 256x256 |
| `COMBAT__part_ring__broken.png` | The same target ring, cracked and broken into three pieces, dull red, 1:1 |
| `COMBAT__vial__glass.png` | A tall narrow glass vial in a brass cage frame, empty and transparent inside, standing, 1:3, 256x768 |
| `COMBAT__vial__hp.png` | Only the liquid of the attached vial: thick dark blood red liquid filling the vial shape, transparent elsewhere, 1:3 |
| `COMBAT__vial__sanity.png` | Only the liquid of the attached vial: glowing pale violet liquid with faint swirls, transparent elsewhere, 1:3 |
| `COMBAT__ap_lamp__lit.png` | A small brass gas lamp with a glass chimney, the flame burning warm orange, 1:1, 256x256 |
| `COMBAT__ap_lamp__dark.png` | The same lamp as attached, flame out, glass smoked, 1:1 |
| `COMBAT__weapon_plate.png` | A horizontal brass name plate for a weapon with a revolving cylinder chamber on its right end showing six empty bullet slots, 4:1, 1024x256 |
| `COMBAT__bullet.png` | A single brass rifle cartridge standing upright, 1:3, 128x384 |
| `COMBAT__end_turn_lever.png` | A heavy brass lever on a wooden base plate, the handle up, a round dial behind it, 3:2, 768x512 |
| `COMBAT__plate.png` | A horizontal frame plate: dark wood with a brass border and corner rivets, empty, for UI text, 9-slice friendly (uniform borders), 3:1, 1200x400 |
| `COMBAT__log_scroll.png` | A vertical parchment scroll partly unrolled, wooden rollers top and bottom, empty, 1:2, 512x1024 |
| `COMBAT__hunter_portrait.png` | Round medallion portrait of a monster hunter: weathered face, wide-brimmed hat, high collar, scar, looking slightly to the side, inside a brass rim, 1:1, 512x512 |
| `COMBAT__shield_badge.png` | A small iron round shield badge with rivets, empty centre for a number, 1:1, 256x256 |
