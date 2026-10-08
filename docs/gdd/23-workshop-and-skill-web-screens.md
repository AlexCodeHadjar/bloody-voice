# 23. Workshop and Skill Web Screens

Layout sketches (`python tools/gen_screen_sketches.py`, uses the real imported art):
`docs/assets/ui/workshop_layout.png`, `skills_mechanic_layout.png`, `skills_monster_layout.png`.
Rules behind the screens: workshop — GDD §6, hunter progression and webs — GDD §4. All text in Russian (GDD §22).

## 23.1 Workshop («Ржавая Шестерня», Grey Chapels)

| # | Zone | Content |
|---|---|---|
| 1 | Top bar | Workshop name; the six resources with counts (icons `RESOURCE__*`); «Изготовлений сегодня: 2 / 2»; exit to the district |
| 2 | Blueprint tabs | Модули · Механизмы · Оружие · Броня · Расходники |
| 3 | Filters | Section (приклад … ствол), cell type (шестерня / искра / кровь), «только доступные» |
| 4 | Blueprint list | Module art, name, tier I–III, cost as icons + numbers; a missing resource is red; a blueprint not yet owned is dim with a lock and says where it comes from (Mechanic web, shop, faction) |
| 5 | Workbench | The selected blueprint large: art on its cell grid, section and cell type, tier, effect text |
| 6 | Deck preview | Mini-cards the item adds or replaces (links like Coil + Harpoon included) and passive bonuses — the player sees the deck change before crafting |
| 7 | Cost and button | Need / have per resource; «Изготовить» (uses 1 of today's crafts); the upgrade path I » II » III with the next tier's effect and cost |
| 8 | Stash | Own modules and mechanisms: installed / spare, tier |
| 9 | Stash actions | For the selected stash item: «Улучшить» (next tier; uses 1 of today's crafts, GDD §6.2), «Разобрать» (returns 50 % of resources, preview shown), «К снаряжению» (opens the equipment screen) |

Flow: pick a blueprint → see what it does to the deck → «Изготовить» → the item appears in the stash as spare and
can be fitted at once via «К снаряжению». No craft is wasted: salvage returns half (GDD §6.2).

## 23.2 Skill webs («Развитие охотника»)

| # | Zone | Content |
|---|---|---|
| 1 | Top bar | Level and XP bar; free skill points and attribute points; «В район» exit button |
| 2 | Web tabs | «Ветка Механика» (brass) · «Ветка Твари — Голос» (blood red) |
| 3 | The web | Graph growing from «Старт» in four directions: Снаряжение (top, four sub-webs Шлем / Нагрудник / Наручи / Поножи), Оружие (right), Модули (bottom), Механизмы (left). Drag with the left button, wheel zoom — like the district map |
| 4 | Attributes | Воля, Ловкость, Хитрость: value, «+» while attribute points are free, one line of what each affects (GDD §4.1) |
| 5 | Equipment sub-webs | Four buttons that scroll the web to the armor piece's part; owned / total nodes |
| 6 | Node card | Name, type, effect, cost (1 point), requirements (a connected owned node; on the Monster web a blood sample), «Изучить»; blueprints say «Откроет в мастерской» |
| 7 | Web specifics | Mechanic: faction blueprints found. Monster: the Voice gauge with stage marks Шёпот / Голод / Зверь at 10 / 20 / 30 + 3 per Will point (GDD §4.2) and the blood samples owned (silhouette, count, «чист.» for pure samples) |
| 8 | Legend | Circle — passive, square — blueprint, hexagon — socket, diamond — keystone; gold ring — can be bought now; red dot — needs a blood sample |

Node states: owned (filled with the web colour, bright line to its parent), available (pulsing gold ring),
locked (dark). One image per node shape; states, web rings and links are drawn by code (tint, glow, `Line2D`). Keystones sit on the outer ring. The Monster web shows the Voice cost on every node card
and warns before a node would cross a Voice stage.

## 23.3 Art to generate later

The screens work with the existing art (module art, icons, silhouettes) and drawn frames. The missing pieces —
30 images for the three screens (background, web textures, list row, tabs, craft button and token, node frames of
both webs, cards, buttons, the gauge tube); states, grids, web lines and gauge fills are drawn by code — are in one ChatGPT file: [`docs/art-prompts/workshop-and-skills-ui.md`](../art-prompts/workshop-and-skills-ui.md).

## 23.4 Open questions for the owner

- Workshop time: does entering the workshop spend the whole day for 2 crafts (GDD §6.2), or does each craft take half a day?
- Can skill points be reset (for money / at a story moment), or are choices final?
- Do the two webs share one pool of skill points (as GDD §4.3 reads now), or does each web have its own points?
  With one pool, investing in the Voice costs Mechanic progress — should the tabs warn about that?
- Are weapons and consumables crafted in the same workshop (the tabs exist), or elsewhere?
- Can items be sold in the workshop, or only in the shop?
