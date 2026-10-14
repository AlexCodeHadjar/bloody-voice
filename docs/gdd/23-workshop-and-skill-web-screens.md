# 23. Workshop and Skill Web Screens

Layout sketches:
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

### 23.1a Next look — «master's table» (owner 2026-10-14)

`docs/assets/ui/workshop_master_table.png` (not built yet; the current screen is too small and plain): top — a shelf
with the resources large (jar icons and big numbers) and today's two works as craft tokens; left — a wall of pinned
blueprint cards, two per row, each with the item's picture, name and cost (tabs Modules / Mechanisms / Armor, «only
available»); centre — the picked item's blueprint unrolled on the bench: big picture, name, section and cell, tier pips,
effect, cards, owned; under it three big brass levers «Изготовить» / «Улучшить до II» / «Разобрать» with costs; right —
a rack with ready items (tier, installed or spare) and trophies (which blueprint they open).

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

Built (Phase 6 step 2): the Mechanic tab — top bar with level and points, the web (drag, zoom), node card with
«Изучить». Not yet: the attributes column (they live in the «Охотник» panel), the four equipment sub-web buttons, the
legend; the Monster tab comes with step 3.

## 23.3 Art to generate later

The screens work with the existing art (module art, icons, silhouettes) plus the workshop and skill-web pieces
received 2026-10-12: `art/ui/WORKSHOP__*` (background, blueprint sheet, tab, craft button and token, salvage / upgrade
icons, tier pip) and `art/ui/SKILLS__*` (web textures, tabs, start medallions, node frames of both webs, card nodes,
attribute plus, monster button, gauge tube, Voice warning). States, grids, web lines and gauge fills are drawn by code.

Built (Phase 4 step 1): tabs Модули · Механизмы (weapons, armor and consumables later), «только доступные», the list,
the workbench with the item's cards, cost need/have, «Изготовить», the next tier and «Улучшить», «Разобрать» with the
refund, the stash with trophies, «К снаряжению» / «В район». Section and cell filters are not built yet.

## 23.4 Open questions for the owner

- ~~Workshop time~~ — answered 2026-10-12: a workshop day = 2 items (GDD 6.3).
- ~~Reset~~ / ~~shared pool~~ — answered 2026-10-12: one pool, the Mechanic web resets for money (GDD 4.7).
- Are weapons and consumables crafted in the same workshop (the tabs exist), or elsewhere?
- Can items be sold in the workshop, or only in the shop?
