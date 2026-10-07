# 21. Combat Screen v2 — Layout and Look

> Owner feedback (2026-10-07): the current combat screen does not look good — **layout, card look, flat panels
> and the creature presentation** all need work. This section is the new target. Sketches
> (`python tools/gen_ui_sketches.py`): `docs/assets/ui/combat_layout.png`, `card_anatomy.png`.

## 21.1 Principles

1. **The creature is the scene.** It stands large in the centre on the darkened district background, not in a box.
   Everything about it (intents, body parts, HP) sits *on or next to its body*.
2. **Things of the world, not boxes.** Every panel is an object: brass plates, parchment, wood, glass vials,
   lamps. No flat brown rectangles.
3. **The hand is the hero's.** Cards fan along the bottom, the hunter's state is bottom-left, the turn controls
   bottom-right — the eye moves top (threat) → bottom (answer).
4. **Numbers are readable at a glance.** Big digits on intents and costs; text only on hover.
5. **All text in Russian** (GDD §22).

## 21.2 Zones (numbers as on the sketch)

| # | Zone | Position (1920 × 1080) | Content |
|---|---|---|---|
| 1 | Top bar | full width, 56 px | Contract and target, turn number, night hour; menu and settings on the right |
| 2 | Creature stage | centre, 880 × 570 | Creature art ~560 px tall, slow idle "breathing" (scale 1.00–1.02), hit flash and shake, floating damage numbers |
| 3 | Intents | above the creature's head | Round brass medallions: intent icon + big number (damage, sanity, block); "next" intents (foresight) smaller and paler to the right; hover = full text |
| 4 | Body parts | on the creature's body | Target rings at the part's spot on the art, ring = part HP; lit and clickable while aiming a card that can hit parts; broken = cracked ring |
| 5 | Creature plate | under the creature | Name + rank seal; HP bar with phase notches; block shield badge on the left; status icons with numbers; on capture contracts a brass capture-chance dial on the right |
| 6 | Log | right edge | Collapsed into a «Журнал» tab; opens as a parchment scroll |
| 7 | Hunter | bottom-left | Portrait medallion; two glass vials: HP (blood) and Sanity (violet); block shield; status icons |
| 8 | Action points | above the hand, left | Three brass gas lamps — lit = available |
| 9 | Weapon | above the hunter | Rifle plate with a revolving chamber: one bullet per ammo; reload card glows when empty |
| 10 | Hand | bottom centre | Cards in a fan; hovered card rises and grows ×1.25; dragged/clicked card shows an aiming line to the target |
| 11 | Draw pile | bottom-left corner | Card backs with a count; click = list of cards (sorted) |
| 12 | Discard / Exhaust | bottom-right corner | Two piles with counts; click = list |
| 13 | End turn | right of the hand | Brass lever button; pulses when no playable card is left |
| 14 | Prompt line | above the hand | «Выберите цель», errors, the result of the last card |

## 21.3 Card look (`card_anatomy.png`)

| Part | Rule |
|---|---|
| Frame | Parchment on a thin brass frame; frame colour by type (attack blood red, support steel, consumable green, capture brass, rage dark red, curse violet-black) |
| Cost | Brass cog top-left with the AP number |
| Name | Ribbon across the top |
| Art window | Upper 40 %: an engraving of the action (card art comes later; until then the card type icon large and faded) |
| Type | Icon + word under the art |
| Text | Built from effects (`EffectText`), Russian |
| Ammo | Bullet icons bottom-left if the card shoots |
| Source | Small text bottom-right: the module or weapon that gives the card |
| Size | 200 × 290 in hand, 250 × 362 hovered |

## 21.4 Data needed

- `monsters/*.json → parts[].spot: [x, y]` — where the part's target ring sits on the combat art (0–1 of the image).
- Card art ids later (`cards[].art`), optional.

## 21.5 Art to generate

Prompts and the full file list: [`docs/art-prompts/combat-ui.md`](../art-prompts/combat-ui.md). Main files (`assets/ui/`):

| File | Use |
|---|---|
| `COMBAT__card_frame__<type>.png` (6) | Card frames per type (9-slice friendly) |
| `COMBAT__card_back.png` | Draw pile |
| `COMBAT__intent_medallion.png` | Intent medallion base |
| `COMBAT__part_ring__normal.png`, `__broken.png` | Body part target rings |
| `COMBAT__vial__hp.png`, `__sanity.png`, `COMBAT__vial__glass.png` | Hunter's gauges |
| `COMBAT__ap_lamp__lit.png`, `__dark.png` | Action points |
| `COMBAT__weapon_plate.png`, `COMBAT__chamber.png` | Weapon and ammo |
| `COMBAT__end_turn_lever.png` | End turn |
| `COMBAT__plate.png` | Creature plate and hunter frame (9-slice) |
| `COMBAT__log_scroll.png` | Log |
| `COMBAT__hunter_portrait.png` | Hunter medallion |

## 21.6 Implementation plan

| Step | What |
|---|---|
| 0 | Data: `parts[].spot` for all creatures + validator (0–1) |
| 0 | Data: `parts[].spot` for all creatures + validator (0–1) |
| 1 | New layout with the existing art and drawn placeholders (no new art needed): stage, medallions, rings on the body (spots in data), vials, lamps, fan hand, piles, lever, log tab |
| 2 | Animations: card hover/fan, play → fly to target, damage numbers, hit flash, lamps going out |
| 3 | Swap placeholders for the generated art as it arrives (`tools/import_art.py`) |
| 4 | Dev shots updated; design-critic pass on 05–08 |
